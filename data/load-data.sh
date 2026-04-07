#!/bin/sh
set -e

OS_URL="https://opensearch-node1:9200"
AUTH="admin:${OPENSEARCH_PASSWORD}"
CURL="curl -sf -k -u ${AUTH}"

log()  { printf '\n── %s ──\n' "$1"; }
ok()   { printf '✅ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1"; }

# ──────────────────────────────────────────────
#  Wait for OpenSearch
# ──────────────────────────────────────────────
printf '⏳ Waiting for OpenSearch ...'
until $CURL "${OS_URL}/_cluster/health" 2>/dev/null | grep -q '"status":"green"\|"status":"yellow"'; do
  printf '.'
  sleep 3
done
ok "OpenSearch is ready."

# ──────────────────────────────────────────────
#  Helper: send bulk file in chunks
#  Usage: send_bulk <file> [extra_curl_args]
# ──────────────────────────────────────────────
send_bulk() {
  _file="$1"; shift
  _chunk_lines="${BULK_CHUNK_LINES:-2000}"
  _total=$(wc -l < "$_file")
  _sent=0

  split -l "$_chunk_lines" -a 4 "$_file" /tmp/_bulk_chunk_

  for _chunk in /tmp/_bulk_chunk_*; do
    # ensure file ends with newline (required by _bulk)
    [ -n "$(tail -c1 "$_chunk")" ] && printf '\n' >> "$_chunk"

    $CURL -X POST "${OS_URL}/_bulk" "$@" \
      -H 'Content-Type: application/x-ndjson' \
      --data-binary "@${_chunk}" > /dev/null

    _chunk_count=$(wc -l < "$_chunk")
    _sent=$((_sent + _chunk_count))
    printf '\r   %d / %d lines sent' "$_sent" "$_total"
    rm -f "$_chunk"
  done
  printf '\n'
}

# ══════════════════════════════════════════════
#  APACHE LOGS
# ══════════════════════════════════════════════
APACHE_FILE="/data/apache_logs"

if [ ! -f "$APACHE_FILE" ]; then
  warn "$APACHE_FILE not found – skipping."
else
  log "Apache Logs – Ingest Pipeline"

  $CURL -X PUT "${OS_URL}/_ingest/pipeline/apache-combined-log" \
    -H 'Content-Type: application/json' \
    -d '{
    "description": "Parse Combined Apache Log Format",
    "processors": [
      { "grok":       { "field": "message", "patterns": ["%{COMBINEDAPACHELOG}"] } },
      { "date":       { "field": "timestamp", "formats": ["dd/MMM/yyyy:HH:mm:ss Z"], "target_field": "@timestamp" } },
      { "convert":    { "field": "response", "type": "integer", "ignore_failure": true } },
      { "convert":    { "field": "bytes",    "type": "long",    "ignore_failure": true } },
      { "user_agent": { "field": "agent",    "target_field": "user_agent", "ignore_failure": true } },
      { "remove":     { "field": ["message", "timestamp"], "ignore_missing": true } }
    ],
    "on_failure": [
      { "set": { "field": "_ingest_error", "value": "{{ _ingest.on_failure_message }}" } }
    ]
  }' > /dev/null
  ok "Pipeline apache-combined-log created."

  log "Apache Logs – Index"

  $CURL -X PUT "${OS_URL}/apache-logs" \
    -H 'Content-Type: application/json' \
    -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "default_pipeline": "apache-combined-log"
    },
    "mappings": {
      "properties": {
        "@timestamp":  { "type": "date" },
        "clientip":    { "type": "ip" },
        "ident":       { "type": "keyword" },
        "auth":        { "type": "keyword" },
        "verb":        { "type": "keyword" },
        "request":     { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
        "httpversion": { "type": "keyword" },
        "response":    { "type": "integer" },
        "bytes":       { "type": "long" },
        "referrer":    { "type": "text",    "fields": { "keyword": { "type": "keyword" } } },
        "agent":       { "type": "text" },
        "user_agent":  { "type": "object" }
      }
    }
  }' > /dev/null
  ok "Index apache-logs created."

  log "Apache Logs – Loading data"

  TOTAL=$(wc -l < "$APACHE_FILE")
  printf '   Converting %d log lines to NDJSON ...\n' "$TOTAL"

  awk '{
    gsub(/\\/, "\\\\")
    gsub(/"/, "\\\"")
    print "{\"index\":{\"_index\":\"apache-logs\"}}"
    print "{\"message\":\"" $0 "\"}"
  }' "$APACHE_FILE" > /tmp/apache_bulk.ndjson

  BULK_CHUNK_LINES=2000 send_bulk /tmp/apache_bulk.ndjson
  rm -f /tmp/apache_bulk.ndjson
  ok "Apache logs: $TOTAL documents loaded."
fi

# ══════════════════════════════════════════════
#  RECIPE DATA
# ══════════════════════════════════════════════
RECIPE_FILE="/data/gfu-bulk-endpoint.jsonl"

if [ ! -f "$RECIPE_FILE" ]; then
  warn "$RECIPE_FILE not found – skipping."
else
  log "Rezepte – Index"

  $CURL -X PUT "${OS_URL}/rezepte" \
    -H 'Content-Type: application/json' \
    -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "Name":         { "type": "text", "analyzer": "german", "fields": { "keyword": { "type": "keyword" } } },
        "Instructions": { "type": "text", "analyzer": "german" },
        "Ingredients":  { "type": "text", "analyzer": "german", "fields": { "keyword": { "type": "keyword" } } },
        "Url":          { "type": "keyword" },
        "Day":          { "type": "integer" },
        "Year":         { "type": "keyword" },
        "Month":        { "type": "keyword" },
        "Weekday":      { "type": "keyword" }
      }
    }
  }' > /dev/null
  ok "Index rezepte created."

  log "Rezepte – Loading data"

  TOTAL_LINES=$(wc -l < "$RECIPE_FILE")
  TOTAL_DOCS=$((TOTAL_LINES / 2))
  printf '   %d recipes to load ...\n' "$TOTAL_DOCS"

  sed 's/"_index": "gfu-bulk-endpoint"/"_index": "rezepte"/g' "$RECIPE_FILE" \
    > /tmp/rezepte_bulk.ndjson

  BULK_CHUNK_LINES=2000 send_bulk /tmp/rezepte_bulk.ndjson
  rm -f /tmp/rezepte_bulk.ndjson
  ok "Recipes: $TOTAL_DOCS documents loaded."
fi

# ══════════════════════════════════════════════
#  Summary
# ══════════════════════════════════════════════
log "Index Summary"
$CURL "${OS_URL}/_cat/indices?v&h=index,health,docs.count,store.size&s=index" 2>/dev/null \
  | grep -E "^index|apache|rezept" || true
printf '\n🎉 Data loading complete.\n'

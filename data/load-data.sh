#!/bin/sh
set -e

OS_URL="https://opensearch-node1:9200"
AUTH="admin:${OPENSEARCH_PASSWORD}"
CURL="curl -sf -k -u ${AUTH}"
# ohne --fail: fuer Aufrufe, deren HTTP-Fehler wir selbst auswerten wollen
CURL_RAW="curl -s -k -u ${AUTH}"

log()  { printf '\n── %s ──\n' "$1"; }
ok()   { printf '✅ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1"; }

# ──────────────────────────────────────────────
#  Helper: Dokumentanzahl eines Index
#  Gibt nichts aus, wenn der Index nicht existiert.
# ──────────────────────────────────────────────
index_doc_count() {
  $CURL_RAW "${OS_URL}/${1}/_count" 2>/dev/null \
    | sed -n 's/.*"count":\([0-9]*\).*/\1/p'
}

# ──────────────────────────────────────────────
#  Helper: Index anlegen, falls noetig
#  Usage: ensure_index <name> <erwartete_dokumente> <mapping-json>
#  Rueckgabe 0 = Daten muessen geladen werden, 1 = nichts zu tun
# ──────────────────────────────────────────────
ensure_index() {
  _idx="$1"; _expected="$2"; _body="$3"
  _count=$(index_doc_count "$_idx")

  if [ -n "$_count" ]; then
    if [ "$_count" = "$_expected" ]; then
      ok "Index $_idx enthaelt bereits $_count Dokumente - wird uebersprungen."
      return 1
    fi
    warn "Index $_idx enthaelt $_count von $_expected Dokumenten - wird neu aufgebaut."
    $CURL_RAW -X DELETE "${OS_URL}/${_idx}" > /dev/null
  fi

  $CURL -X PUT "${OS_URL}/${_idx}" \
    -H 'Content-Type: application/json' \
    -d "$_body" > /dev/null
  ok "Index $_idx created."
  return 0
}

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
  _failed=0

  rm -f /tmp/_bulk_chunk_*
  split -l "$_chunk_lines" -a 4 "$_file" /tmp/_bulk_chunk_

  for _chunk in /tmp/_bulk_chunk_*; do
    # ensure file ends with newline (required by _bulk)
    [ -n "$(tail -c1 "$_chunk")" ] && printf '\n' >> "$_chunk"

    $CURL -X POST "${OS_URL}/_bulk" "$@" \
      -H 'Content-Type: application/x-ndjson' \
      --data-binary "@${_chunk}" -o /tmp/_bulk_response.json

    # Bulk antwortet auch bei fehlgeschlagenen Einzeldokumenten mit HTTP 200,
    # deshalb die Items selbst pruefen - sonst gehen Dokumente still verloren.
    _chunk_failed=$(grep -o '"status":[45][0-9][0-9]' /tmp/_bulk_response.json | wc -l | tr -d ' ')
    if [ "$_chunk_failed" -gt 0 ]; then
      _failed=$((_failed + _chunk_failed))
      printf '\n'
      warn "$_chunk_failed Dokumente aus $(basename "$_chunk") abgelehnt. Erste Ursache:"
      grep -o '"reason":"[^"]*"' /tmp/_bulk_response.json | head -1
    fi

    _chunk_count=$(wc -l < "$_chunk")
    _sent=$((_sent + _chunk_count))
    printf '\r   %d / %d lines sent' "$_sent" "$_total"
    rm -f "$_chunk"
  done
  printf '\n'
  rm -f /tmp/_bulk_response.json

  if [ "$_failed" -gt 0 ]; then
    warn "Insgesamt $_failed Dokumente wurden abgelehnt."
  fi
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

  APACHE_TOTAL=$(wc -l < "$APACHE_FILE" | tr -d ' ')

  APACHE_MAPPING='{
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
  }'

  if ensure_index "apache-logs" "$APACHE_TOTAL" "$APACHE_MAPPING"; then
    log "Apache Logs – Loading data"

    printf '   Converting %d log lines to NDJSON ...\n' "$APACHE_TOTAL"

    # Escaping bewusst mit sed: gsub(/\\/, "\\\\") verhaelt sich je nach awk
    # unterschiedlich und laesst in busybox awk Sequenzen wie \x22 unmaskiert
    # stehen. Das ergibt ungueltiges JSON, und mit default_pipeline verliert
    # OpenSearch dann den ganzen Bulk-Chunk statt nur der kaputten Zeile.
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' "$APACHE_FILE" \
      | sed -e 's|^|{"message":"|' -e 's|$|"}|' \
      | awk '{ print "{\"index\":{\"_index\":\"apache-logs\"}}"; print }' \
      > /tmp/apache_bulk.ndjson

    BULK_CHUNK_LINES=2000 send_bulk /tmp/apache_bulk.ndjson
    rm -f /tmp/apache_bulk.ndjson
    $CURL_RAW -X POST "${OS_URL}/apache-logs/_refresh" > /dev/null
    ok "Apache logs: $APACHE_TOTAL documents loaded."
  fi
fi

# ══════════════════════════════════════════════
#  RECIPE DATA
# ══════════════════════════════════════════════
RECIPE_FILE="/data/gfu-bulk-endpoint.jsonl"

if [ ! -f "$RECIPE_FILE" ]; then
  warn "$RECIPE_FILE not found – skipping."
else
  log "Rezepte – Index"

  TOTAL_LINES=$(wc -l < "$RECIPE_FILE" | tr -d ' ')
  TOTAL_DOCS=$((TOTAL_LINES / 2))

  RECIPE_MAPPING='{
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
  }'

  if ensure_index "rezepte" "$TOTAL_DOCS" "$RECIPE_MAPPING"; then
    log "Rezepte – Loading data"

    printf '   %d recipes to load ...\n' "$TOTAL_DOCS"

    sed 's/"_index": "gfu-bulk-endpoint"/"_index": "rezepte"/g' "$RECIPE_FILE" \
      > /tmp/rezepte_bulk.ndjson

    BULK_CHUNK_LINES=2000 send_bulk /tmp/rezepte_bulk.ndjson
    rm -f /tmp/rezepte_bulk.ndjson
    $CURL_RAW -X POST "${OS_URL}/rezepte/_refresh" > /dev/null
    ok "Recipes: $TOTAL_DOCS documents loaded."
  fi
fi

# ══════════════════════════════════════════════
#  Summary
# ══════════════════════════════════════════════
log "Index Summary"
$CURL "${OS_URL}/_cat/indices?v&h=index,health,docs.count,store.size&s=index" 2>/dev/null \
  | grep -E "^index|apache|rezept" || true
printf '\n🎉 Data loading complete.\n'

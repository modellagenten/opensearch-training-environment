#!/usr/bin/env bash
#
# Log-Generator für die Alerting-Live-Demo.
#
# Legt eine Ingest-Pipeline an, die "@timestamp" auf den Ingest-Zeitpunkt setzt,
# erzeugt den Demo-Index und schreibt danach fortlaufend Log-Events hinein,
# solange das Skript läuft. Monitor und Slack-Action werden bewusst nicht
# angelegt - die baut der Trainer in der Demo selbst.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

INDEX="${INDEX:-demo-logs}"
PIPELINE="${PIPELINE:-demo-logs-now}"

INTERVAL="${INTERVAL:-5}"                 # Sekunden zwischen zwei Bulk-Requests
EVENTS_PER_CYCLE="${EVENTS_PER_CYCLE:-20}" # Events pro Bulk-Request
ERROR_RATE="${ERROR_RATE:-5}"             # Anteil level=error in Prozent
BURST_SIZE="${BURST_SIZE:-150}"           # Events beim Kommando "burst"

SERVICES="checkout-service payment-service auth-service search-service"
HOSTS="web-01 web-02 web-03"

INFO_MSGS="Request completed|User session created|Cache hit for product lookup|Order accepted for processing|Search query executed"
WARN_MSGS="Slow downstream response|Retrying request after timeout|Connection pool almost exhausted|Deprecated API version used"
ERROR_MSGS="Upstream service unavailable|Database connection refused|Payment gateway returned 503|Unhandled exception in request handler|Read timeout after 30000ms"

TOTAL_SENT=0
TOTAL_ERRORS=0
LAST_ERRORS=0
TMP_FILE=""

# ──────────────────────────────────────────────
#  Hilfsfunktionen
# ──────────────────────────────────────────────
log()  { printf '\n── %s ──\n' "$1"; }
ok()   { printf '✅ %s\n' "$1"; }
warn() { printf '⚠️  %s\n' "$1"; }
die()  { printf '❌ %s\n' "$1" >&2; exit 1; }

usage() {
  cat <<EOF
Verwendung: ./alerting-demo.sh [KOMMANDO]

Kommandos:
  run      Setup ausführen und fortlaufend Log-Events schreiben (Standard).
           Beenden mit Strg+C.
  setup    Nur Ingest-Pipeline und Index anlegen.
  burst    Einmalig $BURST_SIZE Fehler-Events einspielen (Fehler-Spitze für den Trigger).
           Anzahl optional als zweites Argument: ./alerting-demo.sh burst 300
  info     Verteilung der letzten 5 Minuten anzeigen und Monitor-Query ausgeben.
  reset    Index löschen und neu anlegen.
  help     Diese Hilfe.

Konfiguration über Umgebungsvariablen (Standardwerte in Klammern):
  INDEX ($INDEX), PIPELINE ($PIPELINE), INTERVAL ($INTERVAL),
  EVENTS_PER_CYCLE ($EVENTS_PER_CYCLE), ERROR_RATE ($ERROR_RATE), BURST_SIZE ($BURST_SIZE)

Beispiele:
  ./alerting-demo.sh                          # Grundrauschen mit 5 % Fehlern
  ERROR_RATE=40 ./alerting-demo.sh            # dauerhaft hohe Fehlerquote
  INTERVAL=2 EVENTS_PER_CYCLE=50 ./alerting-demo.sh run
  ./alerting-demo.sh burst 300                # in einem zweiten Terminal
EOF
}

# Liest einen Wert aus der .env, ohne die Datei zu sourcen.
read_env() {
  [ -f "$ENV_FILE" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$ENV_FILE" \
    | tail -1 \
    | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//"
}

# Wählt zufällig ein Element aus einer per Leerzeichen getrennten Liste.
pick() {
  local -a items=($1)
  echo "${items[$((RANDOM % ${#items[@]}))]}"
}

# Wählt zufällig ein Element aus einer per | getrennten Liste.
pick_msg() {
  local IFS='|'
  local -a items=($1)
  echo "${items[$((RANDOM % ${#items[@]}))]}"
}

os_curl() {
  curl -sS -k -u "$OS_USER:$OS_PASSWORD" --connect-timeout 5 --max-time 30 "$@"
}

# ──────────────────────────────────────────────
#  Verbindung
# ──────────────────────────────────────────────
OS_URL="${OPENSEARCH_HOST:-$(read_env OPENSEARCH_HOST)}"
OS_USER="${OPENSEARCH_USER:-$(read_env OPENSEARCH_USER)}"
OS_PASSWORD="${OPENSEARCH_PASSWORD:-$(read_env OPENSEARCH_PASSWORD)}"

OS_URL="${OS_URL:-https://localhost:9200}"
OS_USER="${OS_USER:-admin}"
OS_URL="${OS_URL%/}"

[ -n "$OS_PASSWORD" ] || die "Kein OPENSEARCH_PASSWORD gefunden (weder als Umgebungsvariable noch in $ENV_FILE)."

wait_for_cluster() {
  printf '⏳ Warte auf OpenSearch auf %s ' "$OS_URL"
  local i=0
  while [ "$i" -lt 60 ]; do
    if os_curl "$OS_URL/_cluster/health" 2>/dev/null | grep -q '"status":"green"\|"status":"yellow"'; then
      printf '\n'
      ok "OpenSearch ist erreichbar."
      return 0
    fi
    printf '.'
    sleep 2
    i=$((i + 1))
  done
  printf '\n'
  die "OpenSearch unter $OS_URL nicht erreichbar. Läuft die Umgebung (docker compose up -d)?"
}

# ──────────────────────────────────────────────
#  Setup: Ingest-Pipeline und Index
# ──────────────────────────────────────────────
create_pipeline() {
  os_curl -X PUT "$OS_URL/_ingest/pipeline/$PIPELINE" \
    -H 'Content-Type: application/json' \
    -d '{
    "description": "Setzt @timestamp auf den Zeitpunkt der Indexierung",
    "processors": [
      { "set":  { "field": "@timestamp", "value": "{{{_ingest.timestamp}}}", "override": false } },
      { "set":  { "field": "level", "value": "info", "override": false } },
      { "date": { "field": "@timestamp", "target_field": "@timestamp",
                  "formats": ["ISO8601"], "ignore_failure": true } }
    ]
  }' > /dev/null || die "Pipeline $PIPELINE konnte nicht angelegt werden."
  ok "Ingest-Pipeline $PIPELINE angelegt (@timestamp = Ingest-Zeitpunkt)."
}

create_index() {
  if os_curl -o /dev/null -w '%{http_code}' -I "$OS_URL/$INDEX" 2>/dev/null | grep -q '^200$'; then
    ok "Index $INDEX ist schon vorhanden."
    return 0
  fi

  os_curl -X PUT "$OS_URL/$INDEX" \
    -H 'Content-Type: application/json' \
    -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.refresh_interval": "1s",
      "index.default_pipeline": "'"$PIPELINE"'"
    },
    "mappings": {
      "properties": {
        "@timestamp":       { "type": "date" },
        "level":            { "type": "keyword" },
        "service":          { "type": "keyword" },
        "host":             { "type": "keyword" },
        "status":           { "type": "integer" },
        "response_time_ms": { "type": "integer" },
        "message":          { "type": "text" }
      }
    }
  }' > /dev/null || die "Index $INDEX konnte nicht angelegt werden."
  ok "Index $INDEX angelegt."
}

setup() {
  log "Setup"
  create_pipeline
  create_index
}

# ──────────────────────────────────────────────
#  Events erzeugen
# ──────────────────────────────────────────────
# build_events <anzahl> <fehlerquote_prozent> <zieldatei>
build_events() {
  local count="$1" err_rate="$2" out_file="$3"
  local i level service host status rt msg
  LAST_ERRORS=0
  : > "$out_file"

  for i in $(seq 1 "$count"); do
    service="$(pick "$SERVICES")"
    host="$(pick "$HOSTS")"

    if [ "$((RANDOM % 100))" -lt "$err_rate" ]; then
      level="error"
      msg="$(pick_msg "$ERROR_MSGS")"
      if [ "$((RANDOM % 2))" -eq 0 ]; then status=500; else status=503; fi
      rt=$((1500 + RANDOM % 4000))
      LAST_ERRORS=$((LAST_ERRORS + 1))
    elif [ "$((RANDOM % 100))" -lt 10 ]; then
      level="warn"
      msg="$(pick_msg "$WARN_MSGS")"
      if [ "$((RANDOM % 2))" -eq 0 ]; then status=404; else status=200; fi
      rt=$((400 + RANDOM % 1200))
    else
      level="info"
      msg="$(pick_msg "$INFO_MSGS")"
      if [ "$((RANDOM % 10))" -eq 0 ]; then status=201; else status=200; fi
      rt=$((20 + RANDOM % 300))
    fi

    printf '{"index":{}}\n' >> "$out_file"
    printf '{"level":"%s","service":"%s","host":"%s","status":%d,"response_time_ms":%d,"message":"%s"}\n' \
      "$level" "$service" "$host" "$status" "$rt" "$msg" >> "$out_file"
  done
}

# send_bulk <datei> [refresh]
send_bulk() {
  local file="$1" refresh="${2:-false}" response
  response="$(os_curl -X POST "$OS_URL/$INDEX/_bulk?refresh=$refresh" \
    -H 'Content-Type: application/x-ndjson' \
    --data-binary "@$file" 2>&1)"

  if [ -z "$response" ]; then
    warn "Keine Antwort von OpenSearch - Cluster gerade nicht erreichbar?"
    return 1
  fi
  if printf '%s' "$response" | grep -q '"errors":true'; then
    warn "Bulk teilweise fehlgeschlagen: $(printf '%s' "$response" | head -c 300)"
    return 1
  fi
  return 0
}

# ──────────────────────────────────────────────
#  Kommandos
# ──────────────────────────────────────────────
summary() {
  printf '\n'
  log "Beendet"
  printf '   Gesendete Events: %d (davon %d mit level=error)\n' "$TOTAL_SENT" "$TOTAL_ERRORS"
  printf '   Index: %s\n\n' "$INDEX"
  exit 0
}

run() {
  TMP_FILE="$(mktemp -t alerting-demo)" || die "Temporäre Datei konnte nicht erstellt werden."
  trap 'rm -f "${TMP_FILE:-}"' EXIT
  trap summary INT TERM

  log "Log-Generator läuft"
  printf '   Index:     %s\n' "$INDEX"
  printf '   Takt:      %d Events alle %d Sekunden\n' "$EVENTS_PER_CYCLE" "$INTERVAL"
  printf '   Fehlerrate: %d %%\n' "$ERROR_RATE"
  printf '   Beenden mit Strg+C\n\n'

  while true; do
    build_events "$EVENTS_PER_CYCLE" "$ERROR_RATE" "$TMP_FILE"
    if send_bulk "$TMP_FILE" false; then
      TOTAL_SENT=$((TOTAL_SENT + EVENTS_PER_CYCLE))
      TOTAL_ERRORS=$((TOTAL_ERRORS + LAST_ERRORS))
      printf '%s  %3d Events gesendet (davon %2d error) - gesamt %d\n' \
        "$(date '+%H:%M:%S')" "$EVENTS_PER_CYCLE" "$LAST_ERRORS" "$TOTAL_SENT"
    fi
    sleep "$INTERVAL"
  done
}

burst() {
  local count="${1:-$BURST_SIZE}"
  TMP_FILE="$(mktemp -t alerting-demo)" || die "Temporäre Datei konnte nicht erstellt werden."
  trap 'rm -f "${TMP_FILE:-}"' EXIT

  log "Fehler-Spitze"
  build_events "$count" 100 "$TMP_FILE"
  if send_bulk "$TMP_FILE" true; then
    ok "$count Events mit level=error eingespielt (sofort sichtbar)."
    printf '   Jetzt den Monitor auslösen, ohne auf den Zeitplan zu warten:\n'
    printf '   POST _plugins/_alerting/monitors/<monitor_id>/_execute\n\n'
  else
    die "Fehler-Spitze konnte nicht eingespielt werden."
  fi
}

# agg_terms <feld> - Terms-Aggregation über die letzten 5 Minuten, formatiert
agg_terms() {
  os_curl -X POST "$OS_URL/$INDEX/_search?pretty" \
    -H 'Content-Type: application/json' \
    -d '{
    "size": 0,
    "query": { "range": { "@timestamp": { "gte": "now-5m" } } },
    "aggs": { "gruppen": { "terms": { "field": "'"$1"'", "size": 10 } } }
  }' | awk '
    /"key"/       { gsub(/[",]/, ""); key = $3 }
    /"doc_count"/ { gsub(/[",]/, ""); if (key != "") { printf "   %-18s %6d\n", key, $3; key = "" } }'
}

info() {
  log "Verteilung der letzten 5 Minuten"
  local total
  total="$(os_curl -X POST "$OS_URL/$INDEX/_count" \
    -H 'Content-Type: application/json' \
    -d '{ "query": { "range": { "@timestamp": { "gte": "now-5m" } } } }' \
    | sed -n 's/.*"count":\([0-9]*\).*/\1/p')"
  printf '   Events gesamt:     %6s\n\n' "${total:-0}"
  printf '   nach level:\n'
  agg_terms level
  printf '\n   nach service:\n'
  agg_terms service

  log "Query für den Monitor (Extraction Query Editor)"
  cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "term":  { "level": "error" } },
        { "range": { "@timestamp": { "gte": "{{period_end}}||-5m", "lte": "{{period_end}}", "format": "epoch_millis" } } }
      ]
    }
  }
}
EOF
  printf '\nTrigger-Bedingung: ctx.results[0].hits.total.value > 50\n'
  printf 'Index für den Monitor: %s\n\n' "$INDEX"
}

reset_index() {
  log "Reset"
  os_curl -X DELETE "$OS_URL/$INDEX" > /dev/null 2>&1
  ok "Index $INDEX gelöscht."
  create_pipeline
  create_index
}

# ──────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────
case "${1:-run}" in
  run)
    wait_for_cluster
    setup
    run
    ;;
  setup)
    wait_for_cluster
    setup
    ;;
  burst)
    burst "${2:-$BURST_SIZE}"
    ;;
  info)
    info
    ;;
  reset)
    wait_for_cluster
    reset_index
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac

#!/bin/bash
# Hilfsskript zum schnellen Aktivieren des Virtual Environments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/install/venv"

if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Virtual Environment nicht gefunden!"
    echo "Bitte führen Sie zuerst das Setup aus:"
    echo "  cd install && ./setup.sh"
    exit 1
fi

echo "✅ Aktiviere Virtual Environment..."
source "$VENV_PATH/bin/activate"

echo ""
echo "🐍 Python Virtual Environment ist aktiv!"
echo "   Python: $(python --version)"
echo "   Pfad: $VENV_PATH"
echo ""
echo "📝 Verfügbare Befehle:"
echo "   python src/test_elasticsearch.py  - Elasticsearch testen"
echo "   python src/test_opensearch.py     - OpenSearch testen"
echo "   deactivate                        - Virtual Environment verlassen"
echo ""


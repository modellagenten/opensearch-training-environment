#!/bin/bash

echo "========================================"
echo "Elasticsearch/OpenSearch Python Setup"
echo "Linux/macOS Schulungsumgebung"
echo "========================================"
echo

# Erkennung des Betriebssystems
OS="$(uname)"
echo "Betriebssystem: $OS"
echo

# Funktion zur Prüfung ob Python installiert ist
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
        PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
        
        # Prüfe auf Python 3.14+
        if [ "$PYTHON_MAJOR" -gt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 14 ]); then
            echo "✓ Python ist installiert:"
            python3 --version
            return 0
        else
            echo "✗ Python ist zu alt (Version $PYTHON_VERSION). Python 3.14+ wird benötigt."
            return 1
        fi
    else
        echo "✗ Python3 ist nicht installiert"
        return 1
    fi
}

# Funktion zur Installation von Python auf macOS
install_python_macos() {
    echo
    echo "Installiere Python über Homebrew..."
    
    # Prüfe ob Homebrew installiert ist
    if ! command -v brew &> /dev/null; then
        echo "Homebrew ist nicht installiert."
        echo "Installiere Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Homebrew PATH hinzufügen (für Apple Silicon)
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    # Installiere Python
    brew install python3
    
    # PATH aktualisieren
    if [ -f "/opt/homebrew/bin/python3" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
}

# Funktion zur Installation von Python auf Linux
install_python_linux() {
    echo
    echo "Installiere Python..."
    
    # Erkennung der Linux-Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            echo "Ubuntu/Debian erkannt - verwende apt"
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        fedora|rhel|centos)
            echo "Fedora/RHEL/CentOS erkannt - verwende dnf/yum"
            if command -v dnf &> /dev/null; then
                sudo dnf install -y python3 python3-pip
            else
                sudo yum install -y python3 python3-pip
            fi
            ;;
        arch|manjaro)
            echo "Arch/Manjaro erkannt - verwende pacman"
            sudo pacman -S --noconfirm python python-pip
            ;;
        *)
            echo "✗ Unbekannte Linux-Distribution: $DISTRO"
            echo "Bitte installieren Sie Python 3.14+ manuell:"
            echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip"
            echo "  Fedora/RHEL:   sudo dnf install python3 python3-pip"
            echo "  Arch:          sudo pacman -S python python-pip"
            exit 1
            ;;
    esac
}

# Python Installation prüfen und ggf. installieren
if ! check_python; then
    echo
    echo "Python 3.14+ wird installiert..."
    
    case "$OS" in
        Darwin)
            install_python_macos
            ;;
        Linux)
            install_python_linux
            ;;
        *)
            echo "✗ Nicht unterstütztes Betriebssystem: $OS"
            echo "Bitte installieren Sie Python 3.14+ manuell."
            exit 1
            ;;
    esac
    
    # Prüfe erneut nach Installation
    echo
    if ! check_python; then
        echo "✗ Python-Installation fehlgeschlagen!"
        echo "Bitte installieren Sie Python 3.14+ manuell und führen Sie das Script erneut aus."
        exit 1
    fi
else
    echo
fi

# pip Prüfung
if ! command -v pip3 &> /dev/null; then
    echo "pip3 ist nicht verfügbar, installiere..."
    python3 -m ensurepip --upgrade
fi

echo "✓ pip ist verfügbar:"
pip3 --version
echo

# Wechsle ins Projekt-Verzeichnis
cd "$(dirname "$0")" || exit 1

# Erstelle Virtual Environment
echo "========================================"
echo "Erstelle Virtual Environment..."
echo "========================================"
echo

VENV_DIR="./venv"

if [ -d "$VENV_DIR" ]; then
    echo "⚠️  Virtual Environment existiert bereits in $VENV_DIR"
    read -p "Möchten Sie es neu erstellen? (j/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        echo "Entferne altes Virtual Environment..."
        rm -rf "$VENV_DIR"
    else
        echo "Verwende existierendes Virtual Environment."
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "Erstelle neues Virtual Environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    echo "✓ Virtual Environment erstellt"
fi

# Aktiviere Virtual Environment
echo
echo "Aktiviere Virtual Environment..."
source "$VENV_DIR/bin/activate"
echo "✓ Virtual Environment aktiv"
echo

# pip im venv aktualisieren
echo "Aktualisiere pip im Virtual Environment..."
pip install --upgrade pip
echo

# Python Libraries installieren
echo "========================================"
echo "Installiere Python Libraries im venv..."
echo "========================================"
echo

# Installiere Requirements
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "Installation abgeschlossen!"
    echo "========================================"
    echo
    echo "Python Version:"
    python --version
    echo
    echo "pip Version:"
    pip --version
    echo
    echo "Virtual Environment:"
    echo "   Pfad: $(pwd)/venv"
    echo
    echo "✅ Nächste Schritte:"
    echo
    echo "1. Virtual Environment aktivieren:"
    echo "   source install/venv/bin/activate"
    echo
    echo "2. .env Datei kopieren und anpassen:"
    echo "   cp env/env_example.txt env/.env"
    echo
    echo "3. Elasticsearch/OpenSearch starten:"
    echo "   docker-compose -f docker-compose-es.yml up -d"
    echo
    echo "4. Test-Skripte ausführen:"
    echo "   python src/test_elasticsearch.py"
    echo "   python src/test_opensearch.py"
    echo
    echo "5. Nach der Schulung Virtual Environment deaktivieren:"
    echo "   deactivate"
    echo
    echo "6. Virtual Environment komplett entfernen (optional):"
    echo "   rm -rf install/venv"
    echo
else
    echo
    echo "✗ pip install fehlgeschlagen!"
    echo "Bitte prüfen Sie die Fehlermeldungen oben."
    exit 1
fi


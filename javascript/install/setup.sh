#!/bin/bash

echo "========================================"
echo "Elasticsearch/OpenSearch JavaScript Setup"
echo "Linux/macOS Schulungsumgebung"
echo "========================================"
echo

# Erkennung des Betriebssystems
OS="$(uname)"
echo "Betriebssystem: $OS"
echo

# Funktion zur Prüfung ob Node.js installiert ist
check_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 22 ]; then
            echo "✓ Node.js ist installiert:"
            node -v
            return 0
        else
            echo "✗ Node.js ist zu alt (Version $NODE_VERSION). Node.js 22+ wird benötigt."
            return 1
        fi
    else
        echo "✗ Node.js ist nicht installiert"
        return 1
    fi
}

# Funktion zur Installation von Node.js auf macOS
install_nodejs_macos() {
    echo
    echo "Installiere Node.js über Homebrew..."
    
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
    
    # Installiere Node.js
    brew install node
    
    # PATH aktualisieren
    if [ -f "/opt/homebrew/bin/node" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
}

# Funktion zur Installation von Node.js auf Linux
install_nodejs_linux() {
    echo
    echo "Installiere Node.js..."
    
    # Erkennung der Linux-Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            echo "Ubuntu/Debian erkannt - verwende apt"
            # NodeSource Repository für aktuelle Node.js Version
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        fedora|rhel|centos)
            echo "Fedora/RHEL/CentOS erkannt - verwende dnf/yum"
            # NodeSource Repository
            curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
            if command -v dnf &> /dev/null; then
                sudo dnf install -y nodejs
            else
                sudo yum install -y nodejs
            fi
            ;;
        arch|manjaro)
            echo "Arch/Manjaro erkannt - verwende pacman"
            sudo pacman -S --noconfirm nodejs npm
            ;;
        *)
            echo "✗ Unbekannte Linux-Distribution: $DISTRO"
            echo "Bitte installieren Sie Node.js 22+ manuell:"
            echo "  Ubuntu/Debian: https://nodejs.org/en/download/package-manager"
            echo "  Fedora/RHEL:   https://nodejs.org/en/download/package-manager"
            echo "  Arch:          sudo pacman -S nodejs npm"
            exit 1
            ;;
    esac
}

# Node.js Installation prüfen und ggf. installieren
if ! check_nodejs; then
    echo
    echo "Node.js 22+ wird installiert..."
    
    case "$OS" in
        Darwin)
            install_nodejs_macos
            ;;
        Linux)
            install_nodejs_linux
            ;;
        *)
            echo "✗ Nicht unterstütztes Betriebssystem: $OS"
            echo "Bitte installieren Sie Node.js 22+ manuell."
            exit 1
            ;;
    esac
    
    # Prüfe erneut nach Installation
    echo
    if ! check_nodejs; then
        echo "✗ Node.js-Installation fehlgeschlagen!"
        echo "Bitte installieren Sie Node.js 22+ manuell und führen Sie das Script erneut aus."
        exit 1
    fi
else
    echo
fi

# npm Prüfung
if ! command -v npm &> /dev/null; then
    echo "✗ npm ist nicht verfügbar!"
    echo "npm sollte automatisch mit Node.js installiert werden."
    exit 1
fi

echo "✓ npm ist verfügbar:"
npm -v
echo

# npm Dependencies installieren
echo "========================================"
echo "Installiere JavaScript Dependencies..."
echo "========================================"
echo

# Wechsle ins Projekt-Verzeichnis
cd "$(dirname "$0")/.." || exit 1

# Installiere npm packages
npm install

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "Installation abgeschlossen!"
    echo "========================================"
    echo
    echo "Node.js Version:"
    node -v
    echo
    echo "npm Version:"
    npm -v
    echo
    echo "Nächste Schritte:"
    echo "1. Kopieren Sie die .env Datei:"
    echo "   cp env/env_example.txt env/.env"
    echo "2. Passen Sie die .env Datei an Ihre Umgebung an"
    echo "3. Starten Sie Elasticsearch/OpenSearch mit Docker Compose"
    echo "4. Führen Sie die Test-Skripte aus:"
    echo "   - npm run test:elasticsearch (Elasticsearch Test)"
    echo "   - npm run test:opensearch (OpenSearch Test)"
    echo
else
    echo
    echo "✗ npm install fehlgeschlagen!"
    echo "Bitte prüfen Sie die Fehlermeldungen oben."
    exit 1
fi


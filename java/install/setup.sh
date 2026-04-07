#!/bin/bash

echo "========================================"
echo "Elasticsearch/OpenSearch Java Setup"
echo "Linux/macOS Schulungsumgebung"
echo "========================================"
echo

# Erkennung des Betriebssystems
OS="$(uname)"
echo "Betriebssystem: $OS"
echo

# Funktion zur Prüfung ob Java installiert ist
check_java() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
        if [ "$JAVA_VERSION" -ge 25 ]; then
            echo "✓ Java ist installiert:"
            java -version
            return 0
        else
            echo "✗ Java ist zu alt (Version $JAVA_VERSION). Java 25+ wird benötigt."
            return 1
        fi
    else
        echo "✗ Java ist nicht installiert"
        return 1
    fi
}

# Funktion zur Installation von Java auf macOS
install_java_macos() {
    echo
    echo "Installiere Java 25 über Homebrew..."
    
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
    
    # Installiere Java
    brew install openjdk@25
    
    # Symlink für Java erstellen (falls nicht vorhanden)
    if [ ! -L "/usr/local/bin/java" ]; then
        sudo ln -sfn $(brew --prefix)/opt/openjdk@25/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-25.jdk 2>/dev/null || true
    fi
    
    # PATH aktualisieren
    echo 'export PATH="/opt/homebrew/opt/openjdk@25/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
    echo 'export PATH="/usr/local/opt/openjdk@25/bin:$PATH"' >> ~/.bash_profile 2>/dev/null || true
    
    export PATH="/opt/homebrew/opt/openjdk@25/bin:$PATH"
    export PATH="/usr/local/opt/openjdk@25/bin:$PATH"
}

# Funktion zur Installation von Java auf Linux
install_java_linux() {
    echo
    echo "Installiere Java 25..."
    
    # Erkennung der Linux-Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            echo "Ubuntu/Debian erkannt - verwende apt"
            sudo apt-get update
            sudo apt-get install -y openjdk-25-jdk
            ;;
        fedora|rhel|centos)
            echo "Fedora/RHEL/CentOS erkannt - verwende dnf/yum"
            if command -v dnf &> /dev/null; then
                sudo dnf install -y java-25-openjdk-devel
            else
                sudo yum install -y java-25-openjdk-devel
            fi
            ;;
        arch|manjaro)
            echo "Arch/Manjaro erkannt - verwende pacman"
            sudo pacman -S --noconfirm jdk25-openjdk
            ;;
        *)
            echo "✗ Unbekannte Linux-Distribution: $DISTRO"
            echo "Bitte installieren Sie Java 25 manuell:"
            echo "  Ubuntu/Debian: sudo apt-get install openjdk-25-jdk"
            echo "  Fedora/RHEL:   sudo dnf install java-25-openjdk-devel"
            echo "  Arch:          sudo pacman -S jdk25-openjdk"
            exit 1
            ;;
    esac
}

# Java Installation prüfen und ggf. installieren
if ! check_java; then
    echo
    echo "Java 25 wird installiert..."
    
    case "$OS" in
        Darwin)
            install_java_macos
            ;;
        Linux)
            install_java_linux
            ;;
        *)
            echo "✗ Nicht unterstütztes Betriebssystem: $OS"
            echo "Bitte installieren Sie Java 25 manuell."
            exit 1
            ;;
    esac
    
    # Prüfe erneut nach Installation
    echo
    if ! check_java; then
        echo "✗ Java-Installation fehlgeschlagen!"
        echo "Bitte installieren Sie Java 25 manuell und führen Sie das Script erneut aus."
        exit 1
    fi
else
    echo
fi

# Gradle Build ausführen
echo "========================================"
echo "Baue Java-Projekt mit Gradle..."
echo "========================================"
echo

# Wechsle ins Projekt-Verzeichnis
cd "$(dirname "$0")/.." || exit 1

# Prüfe ob gradlew existiert und ausführbar ist
if [ ! -x "./gradlew" ]; then
    chmod +x ./gradlew
fi

# Führe Gradle Build aus
./gradlew build

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "Installation abgeschlossen!"
    echo "========================================"
    echo
    echo "Java Version:"
    java -version
    echo
    echo "Nächste Schritte:"
    echo "1. Kopieren Sie die .env Datei:"
    echo "   cp env/env_example.txt env/.env"
    echo "2. Passen Sie die .env Datei an Ihre Umgebung an"
    echo "3. Starten Sie Elasticsearch/OpenSearch mit Docker Compose"
    echo "4. Führen Sie die Test-Programme aus:"
    echo "   - ./gradlew run (Elasticsearch Test)"
    echo "   - ./gradlew run -PmainClass=com.example.OpenSearchConnectionTest (OpenSearch Test)"
    echo
else
    echo
    echo "✗ Build fehlgeschlagen!"
    echo "Bitte prüfen Sie die Fehlermeldungen oben."
    exit 1
fi


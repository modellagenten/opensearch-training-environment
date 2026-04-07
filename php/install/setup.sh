#!/bin/bash

echo "========================================"
echo "Elasticsearch/OpenSearch PHP Setup"
echo "Linux/macOS Schulungsumgebung"
echo "========================================"
echo

# Erkennung des Betriebssystems
OS="$(uname)"
echo "Betriebssystem: $OS"
echo

# Funktion zur Prüfung ob PHP installiert ist
check_php() {
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
        PHP_MAJOR=$(php -r "echo PHP_MAJOR_VERSION;")
        PHP_MINOR=$(php -r "echo PHP_MINOR_VERSION;")
        
        # Prüfe auf PHP 8.4+
        if [ "$PHP_MAJOR" -gt 8 ] || ([ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 4 ]); then
            echo "✓ PHP ist installiert:"
            php --version | head -n 1
            return 0
        else
            echo "✗ PHP ist zu alt (Version $PHP_VERSION). PHP 8.4+ wird benötigt."
            return 1
        fi
    else
        echo "✗ PHP ist nicht installiert"
        return 1
    fi
}

# Funktion zur Prüfung ob Composer installiert ist
check_composer() {
    if command -v composer &> /dev/null; then
        echo "✓ Composer ist installiert:"
        composer --version | head -n 1
        return 0
    else
        echo "✗ Composer ist nicht installiert"
        return 1
    fi
}

# Funktion zur Installation von PHP auf macOS
install_php_macos() {
    echo
    echo "Installiere PHP über Homebrew..."
    
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
    
    # Installiere PHP
    brew install php
    
    # PATH aktualisieren
    if [ -f "/opt/homebrew/bin/php" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
}

# Funktion zur Installation von PHP auf Linux
install_php_linux() {
    echo
    echo "Installiere PHP..."
    
    # Erkennung der Linux-Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            echo "Ubuntu/Debian erkannt - verwende apt"
            sudo apt-get update
            sudo apt-get install -y php php-cli php-curl php-mbstring php-xml php-zip
            ;;
        fedora|rhel|centos)
            echo "Fedora/RHEL/CentOS erkannt - verwende dnf/yum"
            if command -v dnf &> /dev/null; then
                sudo dnf install -y php php-cli php-curl php-mbstring php-xml
            else
                sudo yum install -y php php-cli php-curl php-mbstring php-xml
            fi
            ;;
        arch|manjaro)
            echo "Arch/Manjaro erkannt - verwende pacman"
            sudo pacman -S --noconfirm php php-curl php-intl
            ;;
        *)
            echo "✗ Unbekannte Linux-Distribution: $DISTRO"
            echo "Bitte installieren Sie PHP 8.4+ manuell:"
            echo "  Ubuntu/Debian: sudo apt-get install php php-cli php-curl php-mbstring php-xml"
            echo "  Fedora/RHEL:   sudo dnf install php php-cli"
            echo "  Arch:          sudo pacman -S php"
            exit 1
            ;;
    esac
}

# Funktion zur Installation von Composer auf macOS
install_composer_macos() {
    echo
    echo "Installiere Composer über Homebrew..."
    brew install composer
}

# Funktion zur Installation von Composer auf Linux
install_composer_linux() {
    echo
    echo "Installiere Composer..."
    
    # Download Composer Installer
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo "✗ Composer Installer checksum ist ungültig"
        rm composer-setup.php
        exit 1
    fi

    # Installiere Composer global
    php composer-setup.php --quiet
    rm composer-setup.php
    
    # Verschiebe nach /usr/local/bin
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
}

# PHP Installation prüfen und ggf. installieren
if ! check_php; then
    echo
    echo "PHP 8.4+ wird installiert..."
    
    case "$OS" in
        Darwin)
            install_php_macos
            ;;
        Linux)
            install_php_linux
            ;;
        *)
            echo "✗ Nicht unterstütztes Betriebssystem: $OS"
            echo "Bitte installieren Sie PHP 8.4+ manuell."
            exit 1
            ;;
    esac
    
    # Prüfe erneut nach Installation
    echo
    if ! check_php; then
        echo "✗ PHP-Installation fehlgeschlagen!"
        echo "Bitte installieren Sie PHP 8.4+ manuell und führen Sie das Script erneut aus."
        exit 1
    fi
else
    echo
fi

# Composer Installation prüfen und ggf. installieren
if ! check_composer; then
    echo
    echo "Composer wird installiert..."
    
    case "$OS" in
        Darwin)
            install_composer_macos
            ;;
        Linux)
            install_composer_linux
            ;;
        *)
            echo "✗ Nicht unterstütztes Betriebssystem: $OS"
            echo "Bitte installieren Sie Composer manuell."
            exit 1
            ;;
    esac
    
    # Prüfe erneut nach Installation
    echo
    if ! check_composer; then
        echo "✗ Composer-Installation fehlgeschlagen!"
        echo "Bitte installieren Sie Composer manuell und führen Sie das Script erneut aus."
        exit 1
    fi
else
    echo
fi

# Composer Dependencies installieren
echo "========================================"
echo "Installiere PHP Dependencies..."
echo "========================================"
echo

# Wechsle ins Projekt-Verzeichnis
cd "$(dirname "$0")" || exit 1

# Installiere Composer packages
composer install

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "Installation abgeschlossen!"
    echo "========================================"
    echo
    echo "PHP Version:"
    php --version | head -n 1
    echo
    echo "Composer Version:"
    composer --version
    echo
    echo "Nächste Schritte:"
    echo "1. Kopieren Sie die .env Datei:"
    echo "   cp env/env_example.txt env/.env"
    echo "2. Passen Sie die .env Datei an Ihre Umgebung an"
    echo "3. Starten Sie Elasticsearch/OpenSearch mit Docker Compose"
    echo "4. Führen Sie die Test-Skripte aus:"
    echo "   - php src/test_elasticsearch.php"
    echo "   - php src/test_opensearch.php"
    echo
else
    echo
    echo "✗ composer install fehlgeschlagen!"
    echo "Bitte prüfen Sie die Fehlermeldungen oben."
    exit 1
fi


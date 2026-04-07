#!/bin/bash

echo "========================================"
echo "PHP Schulungsumgebung Deinstallation"
echo "========================================"
echo
echo "Dieses Script entfernt:"
echo "  - Composer vendor/ Verzeichnis"
echo "  - Composer autoload Dateien"
echo "  - composer.lock"
echo
echo "NICHT entfernt werden:"
echo "  - PHP (bleibt installiert)"
echo "  - Composer (bleibt installiert)"
echo
read -p "Möchten Sie fortfahren? (j/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo
echo "Entferne Composer Dependencies..."

# Entferne vendor Verzeichnis
if [ -d "install/vendor" ]; then
    rm -rf install/vendor
    echo "✓ install/vendor/ entfernt"
else
    echo "ℹ️  install/vendor/ existiert nicht"
fi

# Entferne composer.lock
if [ -f "install/composer.lock" ]; then
    rm -f install/composer.lock
    echo "✓ install/composer.lock entfernt"
else
    echo "ℹ️  install/composer.lock existiert nicht"
fi

echo
echo "========================================"
echo "Deinstallation abgeschlossen!"
echo "========================================"
echo
echo "📝 Hinweise:"
echo
echo "Die PHP-Pakete wurden entfernt."
echo
echo "Falls Sie PHP und Composer komplett deinstallieren möchten:"
echo
echo "macOS (Homebrew):"
echo "  brew uninstall php composer"
echo
echo "Linux Ubuntu/Debian:"
echo "  sudo apt-get remove php php-cli php-curl php-mbstring php-xml composer"
echo "  sudo apt-get autoremove"
echo
echo "Linux Fedora/RHEL:"
echo "  sudo dnf remove php php-cli composer"
echo
echo "Windows (Chocolatey):"
echo "  choco uninstall php composer"
echo


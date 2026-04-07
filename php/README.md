# Elasticsearch/OpenSearch PHP Schulungsumgebung

Diese plattformübergreifende PHP-Schulungsumgebung ermöglicht es, Elasticsearch und OpenSearch mit PHP auf **Windows, Linux und macOS** zu verwenden.

## 📁 Ordnerstruktur

```
php/
├── install/
│   ├── setup.bat          # Windows Installation Script
│   ├── setup.sh           # Linux/macOS Installation Script
│   ├── composer.json      # PHP Dependencies
│   └── vendor/            # Composer Dependencies (nach Installation)
├── env/
│   └── env_example.txt    # Beispiel für .env Konfiguration
├── src/
│   ├── test_elasticsearch.php  # Elasticsearch Verbindungstest
│   └── test_opensearch.php     # OpenSearch Verbindungstest
├── uninstall.sh           # Deinstallations-Script (Linux/macOS)
├── uninstall.bat          # Deinstallations-Script (Windows)
└── README.md
```

## 🚀 Installation

### Windows

#### Voraussetzungen
- PowerShell als Administrator für Chocolatey-Installation
- Windows 10/11

#### Automatische Installation

1. **Chocolatey installieren** (falls nicht vorhanden):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

2. **Setup-Script ausführen**:
   ```cmd
   cd php\install
   setup.bat
   ```

Das Script installiert automatisch:
- PHP über Chocolatey (falls nicht vorhanden)
- Composer für Dependency Management
- Alle benötigten PHP Libraries über Composer

#### Manuelle Installation (Windows)
```cmd
# PHP installieren
choco install php -y

# Composer installieren
choco install composer -y

# PHP Libraries installieren
cd php\install
composer install
```

### macOS

#### Automatische Installation

```bash
cd php/install
chmod +x setup.sh
./setup.sh
```

Das Script installiert automatisch:
- Homebrew (falls nicht vorhanden)
- PHP über Homebrew
- Composer über Homebrew
- Alle benötigten PHP Libraries über Composer

#### Manuelle Installation (macOS)

```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PHP und Composer installieren
brew install php composer

# Dependencies installieren
cd php/install
composer install
```

### Linux

#### Ubuntu/Debian

```bash
# PHP installieren
sudo apt-get update
sudo apt-get install -y php php-cli php-curl php-mbstring php-xml php-zip

# Composer installieren
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Setup-Script ausführen
cd php/install
chmod +x setup.sh
./setup.sh
```

#### Fedora/RHEL/CentOS

```bash
# PHP installieren
sudo dnf install -y php php-cli php-curl php-mbstring php-xml

# Composer installieren
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Setup-Script ausführen
cd php/install
chmod +x setup.sh
./setup.sh
```

#### Arch/Manjaro

```bash
# PHP installieren
sudo pacman -S php php-curl php-intl

# Composer installieren
sudo pacman -S composer

# Setup-Script ausführen
cd php/install
chmod +x setup.sh
./setup.sh
```

## ⚙️ Konfiguration

### 1. .env Datei erstellen

Kopieren Sie die Beispieldatei und passen Sie die Werte an:

**Linux/macOS:**
```bash
cp ../env.example ../.env
```

**Windows:**
```cmd
copy ../env.example ../.env
```

### 2. Docker Compose starten

**Elasticsearch starten:**
```bash
docker-compose -f docker-compose-es.yml up -d
```

**OpenSearch starten:**
```bash
docker-compose -f docker-compose-os.yml up -d
```

## 💻 Verwendung

### Elasticsearch testen

**Direkte Ausführung:**
```bash
php src/test_elasticsearch.php
```

**Mit Composer Script:**
```bash
cd install
composer test-es
```

### OpenSearch testen

**Direkte Ausführung:**
```bash
php src/test_opensearch.php
```

**Mit Composer Script:**
```bash
cd install
composer test-os
```

### Beide Tests ausführen

```bash
cd install
composer test
```

## 📦 Dependencies

Das Projekt verwendet folgende Hauptdependencies:

### Elasticsearch/OpenSearch
- `elasticsearch/elasticsearch: ^8.0` - Elasticsearch PHP Client (kompatibel mit OpenSearch)
- `vlucas/phpdotenv: ^5.0` - Environment Variables Management

### Development
- `phpunit/phpunit: ^10.0` - Testing Framework (optional)

## ✨ Features

- **PHP 8.4+**: Moderne PHP-Features und Typisierung
- **Plattformübergreifend**: Läuft auf Windows, Linux und macOS
- **Composer**: Dependency Management mit Composer
- **Deutsche Ausgaben**: Alle Skripte verwenden deutsche Kommentare und Meldungen

## 🔧 Troubleshooting

### PHP nicht gefunden

**Windows:**
```cmd
# Prüfen ob PHP installiert ist
php --version

# Falls nicht installiert
choco install php -y
```

**macOS:**
```bash
# Prüfen ob PHP installiert ist
php --version

# Falls nicht installiert
brew install php
```

**Linux:**
```bash
# Prüfen ob PHP installiert ist
php --version

# Falls nicht installiert (Ubuntu/Debian)
sudo apt-get install php php-cli php-curl php-mbstring php-xml
```

### Composer nicht gefunden

**Windows:**
```cmd
choco install composer -y
```

**macOS:**
```bash
brew install composer
```

**Linux:**
```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

### Fehlende PHP Extensions

**Ubuntu/Debian:**
```bash
sudo apt-get install php-curl php-mbstring php-xml php-zip
```

**macOS:**
```bash
# Extensions sind normalerweise mit PHP enthalten
# Bei Bedarf: brew reinstall php
```

**Fedora/RHEL:**
```bash
sudo dnf install php-curl php-mbstring php-xml
```

### Verbindungsfehler

1. Prüfen Sie, ob Docker Container laufen:
   ```bash
   docker ps
   ```

2. Warten Sie 1-2 Minuten nach dem Start der Container

3. Prüfen Sie die `.env` Datei Konfiguration

4. Prüfen Sie die Firewall-Einstellungen

### Composer Autoload Fehler

```bash
# Autoloader neu generieren
cd install
composer dump-autoload
```

## 🎯 Nächste Schritte

Nach erfolgreichem Verbindungstest können Sie:
1. Indices erstellen und Daten importieren
2. Suchabfragen durchführen
3. Aggregationen verwenden
4. Bulk-Operationen implementieren
5. Weitere PHP-Skripte entwickeln

## 📚 PHP Elasticsearch Client Features

Der verwendete `elasticsearch-php` Client bietet:
- **Vollständige API-Unterstützung**: Alle Elasticsearch/OpenSearch APIs
- **Automatische Retry-Logik**: Bei Verbindungsfehlern
- **Connection Pooling**: Effiziente Verbindungsverwaltung
- **PSR-7 Response Interface**: Standard HTTP Message Interface
- **ArrayAccess**: Einfache Datenmanipulation mit Array-Syntax
- **Bulk-Operationen**: Effiziente Massen-Indizierung

## 🛠️ Entwicklungsumgebung

### IDE Setup

**PHPStorm:**
- Öffnen Sie das Projekt
- PHPStorm erkennt automatisch Composer und lädt die Dependencies

**VS Code:**
- Installieren Sie die "PHP Extension Pack"
- Installieren Sie "PHP Intelephense" für bessere Code-Vervollständigung

**Eclipse:**
- Installieren Sie PDT (PHP Development Tools)
- Importieren Sie als PHP-Projekt

### Code-Struktur

- `test_elasticsearch.php` - Testet Elasticsearch-Verbindung und Bulk-Import
- `test_opensearch.php` - Testet OpenSearch-Verbindung mit erweiterten Features
- Beide Skripte verwenden deutsche Kommentare und Ausgaben

### Composer Scripts

In `composer.json` definiert:
```json
{
  "scripts": {
    "test": "php src/test_elasticsearch.php && php src/test_opensearch.php",
    "test-es": "php src/test_elasticsearch.php",
    "test-os": "php src/test_opensearch.php"
  }
}
```

## 🔗 Weitere Ressourcen

- [Elasticsearch PHP Client Dokumentation](https://www.elastic.co/guide/en/elasticsearch/client/php-api/current/index.html)
- [OpenSearch Dokumentation](https://opensearch.org/docs/latest/)
- [Composer Dokumentation](https://getcomposer.org/doc/)
- [PHP Dotenv Dokumentation](https://github.com/vlucas/phpdotenv)
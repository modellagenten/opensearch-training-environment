# Elasticsearch/OpenSearch JavaScript Schulungsumgebung

Diese plattformübergreifende JavaScript/Node.js-Schulungsumgebung ermöglicht es, Elasticsearch und OpenSearch mit JavaScript auf **Windows, Linux und macOS** zu verwenden.

## 📁 Ordnerstruktur

```
javascript/
├── install/
│   ├── setup.bat              # Windows Installation Script
│   └── setup.sh               # Linux/macOS Installation Script
├── env/
│   └── env_example.txt        # Beispiel für .env Konfiguration
├── src/
│   ├── test-elasticsearch.js  # Elasticsearch Verbindungstest
│   └── test-opensearch.js     # OpenSearch Verbindungstest
├── package.json               # Node.js Dependencies und Scripts
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
   cd javascript\install
   setup.bat
   ```

Das Script installiert automatisch:
- Node.js 22 über Chocolatey (falls nicht vorhanden)
- npm (Node Package Manager)
- Alle benötigten JavaScript Dependencies via npm

#### Manuelle Installation (Windows)
```cmd
# Node.js installieren
choco install nodejs -y

# Dependencies installieren
npm install
```

### macOS

#### Automatische Installation

```bash
cd javascript/install
chmod +x setup.sh
./setup.sh
```

Das Script installiert automatisch:
- Homebrew (falls nicht vorhanden)
- Node.js über Homebrew
- Alle benötigten JavaScript Dependencies via npm

#### Manuelle Installation (macOS)

```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js installieren
brew install node

# Dependencies installieren
cd javascript
npm install
```

### Linux

#### Ubuntu/Debian

```bash
# Node.js installieren (NodeSource Repository für aktuelle Version)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Setup-Script ausführen
cd javascript/install
chmod +x setup.sh
./setup.sh
```

#### Fedora/RHEL/CentOS

```bash
# Node.js installieren
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs

# Setup-Script ausführen
cd javascript/install
chmod +x setup.sh
./setup.sh
```

#### Arch/Manjaro

```bash
# Node.js installieren
sudo pacman -S nodejs npm

# Setup-Script ausführen
cd javascript/install
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

### Dependencies installieren

```bash
npm install
```

### Elasticsearch testen

**npm Script:**
```bash
npm run test:elasticsearch
```

**Direkte Ausführung:**
```bash
node src/test-elasticsearch.js
```

### OpenSearch testen

**npm Script:**
```bash
npm run test:opensearch
```

**Direkte Ausführung:**
```bash
node src/test-opensearch.js
```

### Verfügbare npm Scripts

```bash
npm run test:elasticsearch    # Elasticsearch Verbindungstest
npm run test:opensearch       # OpenSearch Verbindungstest
npm run install:deps          # Dependencies installieren
npm start                     # Startet Elasticsearch Test
```

## 📦 Dependencies

Das Projekt verwendet folgende Hauptdependencies:

### Elasticsearch
- `@elastic/elasticsearch: ^9.1.1` - Elasticsearch JavaScript Client

### OpenSearch
- `@opensearch-project/opensearch: ^3.5.1` - OpenSearch JavaScript Client

### Utilities
- `dotenv: ^16.4.5` - Environment Variables Management
- `axios: ^1.7.2` - HTTP Client (optional)

### Development
- `nodemon: ^3.1.0` - Development Tool für automatisches Neustarten

## ✨ Features

- **ES Modules**: Verwendet moderne JavaScript ES Modules (import/export)
- **Node.js 22+**: Kompatibel mit Node.js 22 und höher
- **Plattformübergreifend**: Läuft auf Windows, Linux und macOS
- **TypeScript Ready**: Kann einfach zu TypeScript migriert werden
- **Deutsche Ausgaben**: Alle Programme verwenden deutsche Kommentare und Meldungen

## 🔧 Troubleshooting

### Node.js nicht gefunden

**Windows:**
```cmd
# Prüfen ob Node.js installiert ist
node --version

# Falls nicht installiert
choco install nodejs -y
```

**macOS:**
```bash
# Prüfen ob Node.js installiert ist
node --version

# Falls nicht installiert
brew install node
```

**Linux:**
```bash
# Prüfen ob Node.js installiert ist
node --version

# Falls nicht installiert (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### npm nicht gefunden

- npm kommt automatisch mit Node.js mit
- Falls npm fehlt: Node.js neu installieren

### Module nicht gefunden

```bash
# Dependencies installieren
npm install

# Bei Problemen: node_modules löschen und neu installieren
rm -rf node_modules package-lock.json
npm install
```

### Verbindungsfehler

1. Prüfen Sie, ob Docker Container laufen:
   ```bash
   docker ps
   ```

2. Warten Sie 1-2 Minuten nach dem Start der Container

3. Prüfen Sie die `.env` Datei Konfiguration

4. Prüfen Sie die Firewall-Einstellungen

### ES Module Fehler

- Das Projekt verwendet ES Modules (`"type": "module"` in package.json)
- Verwenden Sie `import` statt `require()`
- Dateiendung sollte `.js` sein (nicht `.mjs` erforderlich)

## 🎯 Nächste Schritte

Nach erfolgreichem Verbindungstest können Sie:
1. Indices erstellen und Daten importieren
2. Suchabfragen implementieren
3. Aggregationen verwenden
4. Bulk-Operationen durchführen
5. Weitere JavaScript-Programme entwickeln
6. Zu TypeScript migrieren

## 🛠️ IDE Setup

### VS Code
- Installieren Sie die "JavaScript Extension Pack"
- Öffnen Sie den Ordner
- VS Code erkennt automatisch Node.js

### WebStorm
- Öffnen Sie das Projekt als Node.js-Projekt
- WebStorm lädt automatisch alle Dependencies

### Sublime Text
- Installieren Sie das Node.js Package
- Konfigurieren Sie den Build

## 📚 ES Modules vs CommonJS

Das Projekt verwendet ES Modules. Unterschiede:

```javascript
// CommonJS (nicht in diesem Projekt)
const { Client } = require('@elastic/elasticsearch');
const dotenv = require('dotenv');

// ES Modules (verwendet in diesem Projekt)
import { Client } from '@elastic/elasticsearch';
import dotenv from 'dotenv';
```

## 🔄 TypeScript Migration

Um zu TypeScript zu migrieren:

```bash
# TypeScript Dependencies installieren
npm install -D typescript @types/node

# tsconfig.json erstellen
npx tsc --init

# Dateien zu .ts umbenennen und TypeScript nutzen
```

## 📝 Code-Struktur

- `test-elasticsearch.js` - Testet Elasticsearch-Verbindung
- `test-opensearch.js` - Testet OpenSearch-Verbindung
- Beide Programme verwenden deutsche Kommentare und Ausgaben
- Moderne JavaScript-Features (async/await, ES Modules)

## 🔗 Weitere Ressourcen

- [Elasticsearch JavaScript Client Dokumentation](https://www.elastic.co/guide/en/elasticsearch/client/javascript-api/current/index.html)
- [OpenSearch JavaScript Client Dokumentation](https://opensearch.org/docs/latest/clients/javascript/)
- [Node.js Dokumentation](https://nodejs.org/docs/)
- [ES Modules Dokumentation](https://nodejs.org/api/esm.html)

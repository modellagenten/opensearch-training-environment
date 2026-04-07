# Elasticsearch/OpenSearch Python Schulungsumgebung

Diese plattformübergreifende Python-Schulungsumgebung ermöglicht es, Elasticsearch und OpenSearch mit Python auf **Windows, Linux und macOS** zu verwenden.

## 📁 Ordnerstruktur

```
python/
├── install/
│   ├── setup.bat          # Windows Installation Script
│   ├── setup.sh           # Linux/macOS Installation Script
│   └── requirements.txt   # Python Dependencies
├── env/
│   └── env_example.txt    # Beispiel für .env Konfiguration
├── src/
│   ├── test_elasticsearch.py  # Elasticsearch Verbindungstest
│   └── test_opensearch.py     # OpenSearch Verbindungstest
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
   cd python\install
   setup.bat
   ```

Das Script installiert automatisch:
- Python über Chocolatey (falls nicht vorhanden)
- pip (Python Package Installer)
- Ein isoliertes Virtual Environment
- Alle benötigten Python Libraries im Virtual Environment

#### Manuelle Installation (Windows)
```cmd
# Python installieren
choco install python -y

# Libraries installieren
pip install -r install\requirements.txt
```

### macOS

#### Automatische Installation

```bash
cd python/install
chmod +x setup.sh
./setup.sh
```

Das Script installiert automatisch:
- Homebrew (falls nicht vorhanden)
- Python 3 über Homebrew
- pip (Python Package Installer)
- Ein isoliertes Virtual Environment
- Alle benötigten Python Libraries im Virtual Environment

#### Manuelle Installation (macOS)

```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Python 3 installieren
brew install python3

# Libraries installieren
cd python
pip3 install -r install/requirements.txt
```

### Linux

#### Ubuntu/Debian

```bash
# Python 3 installieren
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Setup-Script ausführen
cd python/install
chmod +x setup.sh
./setup.sh
```

#### Fedora/RHEL/CentOS

```bash
# Python 3 installieren
sudo dnf install -y python3 python3-pip

# Setup-Script ausführen
cd python/install
chmod +x setup.sh
./setup.sh
```

#### Arch/Manjaro

```bash
# Python 3 installieren
sudo pacman -S python python-pip

# Setup-Script ausführen
cd python/install
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

```bash
# Virtual Environment muss aktiv sein (venv)
python src/test_elasticsearch.py
```

### OpenSearch testen

```bash
# Virtual Environment muss aktiv sein (venv)
python src/test_opensearch.py
```

## 📦 Dependencies

Das Projekt verwendet folgende Python-Bibliotheken (siehe `requirements.txt`):

### Elasticsearch/OpenSearch
- `elasticsearch==9.1.1` - Elasticsearch Python Client
- `opensearch-py==2.5.0` - OpenSearch Python Client

### Utilities
- `python-dotenv==1.1.1` - Environment Variables Management
- `requests==2.31.0` - HTTP Library
- `urllib3==1.26.18` - HTTP Client

## ✨ Features

- **Python 3.14+**: Moderne Python Syntax und Features
- **Plattformübergreifend**: Läuft auf Windows, Linux und macOS
- **Type Hints**: Verwendet Python Type Hints für bessere Code-Qualität
- **SSL-Support**: Vollständige SSL-Unterstützung für lokale Entwicklung
- **Deutsche Ausgaben**: Alle Skripte verwenden deutsche Kommentare und Meldungen
- **Flexible .env Suche**: Automatische Suche in verschiedenen Verzeichnissen mit `pathlib`

## 🔧 Troubleshooting

### Python nicht gefunden

**Windows:**
```cmd
# Prüfen ob Python installiert ist
python --version

# Falls nicht installiert
choco install python -y
```

**macOS:**
```bash
# Prüfen ob Python installiert ist
python3 --version

# Falls nicht installiert
brew install python3
```

**Linux:**
```bash
# Prüfen ob Python installiert ist
python3 --version

# Falls nicht installiert (Ubuntu/Debian)
sudo apt-get install python3 python3-pip
```

### pip nicht gefunden

**Alle Systeme:**
```bash
# pip installieren/aktualisieren
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip
```

### Module nicht gefunden

```bash
# Requirements neu installieren
pip3 install -r install/requirements.txt

# Bei Problemen: mit --user Flag
pip3 install --user -r install/requirements.txt
```

### Verbindungsfehler

1. Prüfen Sie, ob Docker Container laufen:
   ```bash
   docker ps
   ```

2. Warten Sie 1-2 Minuten nach dem Start der Container

3. Prüfen Sie die `.env` Datei Konfiguration

4. Prüfen Sie die Firewall-Einstellungen


### Import-Fehler

```bash
# Prüfen ob alle Pakete installiert sind
pip3 list | grep -E "elasticsearch|opensearch|dotenv"

# Falls fehlend, neu installieren
pip3 install -r install/requirements.txt
```

## 🎯 Nächste Schritte

Nach erfolgreichem Verbindungstest können Sie:
1. Indices erstellen und Daten importieren
2. Suchabfragen mit der Python-API durchführen
3. Aggregationen verwenden
4. Bulk-Operationen implementieren
5. Weitere Python-Skripte entwickeln
6. Datenanalyse mit Pandas kombinieren

## 📚 Python Elasticsearch/OpenSearch Client Features

### Elasticsearch Client
- **Vollständige API-Unterstützung**: Alle Elasticsearch REST APIs
- **Asynchrone Unterstützung**: Async/await mit `AsyncElasticsearch`
- **Connection Pooling**: Automatische Verbindungsverwaltung
- **Retry-Mechanismus**: Automatische Wiederholungen bei Fehlern
- **Helpers**: Bulk, Scan, Reindex und mehr

### OpenSearch Client
- **Kompatibel mit Elasticsearch**: Ähnliche API
- **OpenSearch-spezifische Features**: Alle OpenSearch-Funktionen
- **Plugin-Unterstützung**: Anomaly Detection, SQL, etc.

## 🛠️ Entwicklungsumgebung

### IDE Setup

**PyCharm:**
- Öffnen Sie das Projekt
- PyCharm erkennt automatisch die Python-Umgebung
- Konfigurieren Sie den Python-Interpreter

**VS Code:**
- Installieren Sie die "Python" Extension
- Wählen Sie den Python-Interpreter (Cmd/Ctrl+Shift+P → "Python: Select Interpreter")
- VS Code erkennt automatisch die Requirements

**Jupyter Notebook:**
```bash
pip3 install jupyter
jupyter notebook
```
### Code-Struktur

- `test_elasticsearch.py` - Testet Elasticsearch-Verbindung
- `test_opensearch.py` - Testet OpenSearch-Verbindung
- Beide Skripte verwenden deutsche Kommentare und Ausgaben
- Type Hints für bessere Code-Dokumentation

### Erweiterte Verwendung

**Standard-Workflow:**
```bash
# 1. Virtual Environment aktivieren
source install/venv/bin/activate  # Linux/macOS
# ODER
install\venv\Scripts\activate.bat  # Windows

# 2. Skripte ausführen
python src/test_elasticsearch.py
python src/test_opensearch.py

# 3. Nach der Arbeit deaktivieren
deactivate
```

## 🔗 Weitere Ressourcen

- [Elasticsearch Python Client Dokumentation](https://elasticsearch-py.readthedocs.io/)
- [OpenSearch Python Client Dokumentation](https://opensearch.org/docs/latest/clients/python/)
- [Python-dotenv Dokumentation](https://github.com/theskumar/python-dotenv)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)

## 📝 Hinweise

- **Python Version**: Python 3.14+ wird empfohlen
- **Virtual Environment**: Wird automatisch vom Setup-Script erstellt und verwendet
- **Async Support**: Beide Clients unterstützen asynchrone Operationen mit `AsyncElasticsearch` / `AsyncOpenSearch`
- **Error Handling**: Die Skripte enthalten grundlegendes Error Handling, erweitern Sie dies für Produktionsumgebungen
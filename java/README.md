# Elasticsearch/OpenSearch Java Schulungsumgebung

Diese plattformübergreifende Java-Schulungsumgebung mit Gradle ermöglicht es, Elasticsearch und OpenSearch mit Java auf **Windows, Linux und macOS** zu verwenden.

## 📁 Ordnerstruktur

```
java/
├── install/
│   ├── setup.bat              # Windows Installation Script
│   └── setup.sh               # Linux/macOS Installation Script  
├── env/
│   └── env_example.txt        # Beispiel für .env Konfiguration
├── src/main/java/com/example/
│   ├── ElasticsearchConnectionTest.java  # Elasticsearch Verbindungstest
│   └── OpenSearchConnectionTest.java     # OpenSearch Verbindungstest
├── gradle/wrapper/
│   └── gradle-wrapper.properties        # Gradle Wrapper Konfiguration
├── build.gradle                          # Gradle Build-Konfiguration
├── gradlew                               # Gradle Wrapper für Linux/macOS
├── gradlew.bat                           # Gradle Wrapper für Windows
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
   cd java\install
   setup.bat
   ```

Das Script installiert automatisch:
- Java 25 über Chocolatey (falls nicht vorhanden)
- Alle benötigten Java Dependencies via Gradle

#### Manuelle Installation (Windows)
```cmd
# Java 25 installieren
choco install openjdk25 -y

# Projekt bauen
gradlew.bat build
```

### macOS

#### Automatische Installation

```bash
cd java/install
chmod +x setup.sh
./setup.sh
```

Das Script installiert automatisch:
- Homebrew (falls nicht vorhanden)
- Java 25 über Homebrew
- Alle benötigten Java Dependencies via Gradle

#### Manuelle Installation (macOS)

```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Java 25 installieren
brew install openjdk@25

# PATH aktualisieren
echo 'export PATH="/opt/homebrew/opt/openjdk@25/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Projekt bauen
cd java
./gradlew build
```

### Linux

#### Ubuntu/Debian

```bash
# Java 25 installieren
sudo apt-get update
sudo apt-get install -y openjdk-25-jdk

# Setup-Script ausführen
cd java/install
chmod +x setup.sh
./setup.sh
```

#### Fedora/RHEL/CentOS

```bash
# Java 25 installieren
sudo dnf install -y java-25-openjdk-devel

# Setup-Script ausführen
cd java/install
chmod +x setup.sh
./setup.sh
```

#### Arch/Manjaro

```bash
# Java 25 installieren
sudo pacman -S jdk25-openjdk

# Setup-Script ausführen
cd java/install
chmod +x setup.sh
./setup.sh
```

## ⚙️ Konfiguration

### 1. .env Datei erstellen

Kopieren Sie die Beispieldatei `env.example` und passen Sie die Werte an:

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

### Projekt bauen

**Windows:**
```cmd
gradlew.bat build
```

**Linux/macOS:**
```bash
./gradlew build
```

### Elasticsearch testen (Standard)

**Windows:**
```cmd
gradlew.bat run
```

**Linux/macOS:**
```bash
./gradlew run
```
### OpenSearch testen

Kommentieren Sie die Zeile `mainClass = 'com.example.ElasticsearchConnectionTest';` in der `build.gradle` Datei aus und aktivieren Sie die Zeile `mainClass = 'com.example.OpenSearchConnectionTest';`.
Anschlißend können Sie das Programm wie folgt ausführen:

**Windows:**
```cmd
gradlew.bat run
```

**Linux/macOS:**
```bash
./gradlew run
```

### Gradle Tasks anzeigen

**Windows:**
```cmd
gradlew.bat tasks
```

**Linux/macOS:**
```bash
./gradlew tasks
```

## 📦 Dependencies

Das Projekt verwendet folgende Hauptdependencies:

### Elasticsearch
- `co.elastic.clients:elasticsearch-java:9.1.4` - Elasticsearch Java Client
- `jakarta.json:jakarta.json-api:2.1.3` - JSON Processing
- `org.eclipse.parsson:parsson:1.1.6` - JSON Implementation

### OpenSearch
- `org.opensearch.client:opensearch-java:3.0.0` - OpenSearch Java Client

### HTTP & SSL
- `org.apache.httpcomponents.client5:httpclient5:5.2.1` - HTTP Client
- `org.apache.httpcomponents.core5:httpcore5:5.3.5` - HTTP Core

### Utilities
- `io.github.cdimascio:dotenv-java:3.0.0` - Environment Variables
- `com.fasterxml.jackson.core:jackson-*:2.18.2` - JSON Processing
- `org.slf4j:slf4j-simple:2.0.13` - Logging

## 🔧 Troubleshooting

### Java nicht gefunden

**Windows:**
```cmd
# Prüfen ob Java installiert ist
java -version

# Falls nicht installiert
choco install openjdk25 -y
```

**macOS:**
```bash
# Prüfen ob Java installiert ist
java -version

# Falls nicht installiert
brew install openjdk@25
```

**Linux:**
```bash
# Prüfen ob Java installiert ist
java -version

# Falls nicht installiert (Ubuntu/Debian)
sudo apt-get install openjdk-25-jdk
```

### Gradle nicht gefunden

Das Projekt verwendet den **Gradle Wrapper**, daher ist keine separate Gradle-Installation erforderlich:
- Windows: Verwenden Sie `gradlew.bat`
- Linux/macOS: Verwenden Sie `./gradlew`

### Build-Fehler

```bash
# Prüfen Sie die Java-Version (sollte 25+ sein)
java -version

# Cache löschen und neu bauen (Windows)
gradlew.bat clean build

# Cache löschen und neu bauen (Linux/macOS)
./gradlew clean build
```

### Verbindungsfehler

1. Prüfen Sie, ob Docker Container laufen:
   ```bash
   docker ps
   ```

2. Warten Sie 1-2 Minuten nach dem Start der Container

3. Prüfen Sie die `.env` Datei Konfiguration

4. Prüfen Sie die Firewall-Einstellungen

## 🎯 Nächste Schritte

Nach erfolgreichem Verbindungstest können Sie:
1. Indices erstellen und Daten importieren
2. Suchabfragen implementieren
3. Aggregationen verwenden
4. Bulk-Operationen durchführen
5. Weitere Java-Programme entwickeln

## 🛠️ IDE Setup

### IntelliJ IDEA
1. Öffnen Sie das Projekt als Gradle-Projekt
2. IntelliJ lädt automatisch alle Dependencies

### Eclipse
1. Importieren Sie als Gradle-Projekt
2. Eclipse lädt automatisch alle Dependencies

### VS Code
1. Installieren Sie die "Extension Pack for Java"
2. Öffnen Sie den Ordner
3. VS Code erkennt automatisch das Gradle-Projekt

## 📝 Hinweise

- Das Projekt verwendet den **Gradle Wrapper** - keine separate Gradle-Installation erforderlich
- Die Java-Dateien sind **plattformübergreifend** und enthalten deutsche Kommentare
- Die `.env` Datei wird im Projektverzeichnis gesucht

## 🔗 Weitere Ressourcen

- [Elasticsearch Java Client Dokumentation](https://www.elastic.co/guide/en/elasticsearch/client/java-api-client/current/index.html)
- [OpenSearch Java Client Dokumentation](https://opensearch.org/docs/latest/clients/java/)
- [Gradle Dokumentation](https://docs.gradle.org/)

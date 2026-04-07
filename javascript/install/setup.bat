@echo off
echo ========================================
echo Elasticsearch/OpenSearch JavaScript Setup
echo Windows 11 Schulungsumgebung
echo ========================================
echo.

REM Prüfe ob Chocolatey installiert ist
choco --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Chocolatey ist nicht installiert!
    echo Bitte installieren Sie Chocolatey von https://chocolatey.org/install
    echo.
    pause
    exit /b 1
)

echo Chocolatey ist installiert:
choco --version
echo.

REM Prüfe ob Node.js bereits installiert ist
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Node.js ist nicht installiert. Installiere Node.js 22 über Chocolatey...
    echo.
    choco install nodejs-lts -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    node --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei Node.js Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo Node.js ist installiert:
node --version
echo.

REM Prüfe ob npm verfügbar ist
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo npm ist nicht verfügbar!
    echo Bitte installieren Sie Node.js erneut oder starten Sie die Eingabeaufforderung neu.
    echo.
    pause
    exit /b 1
)

echo npm ist verfügbar:
npm --version
echo.

REM Wechsle ins Projekt-Verzeichnis und installiere Dependencies
echo Installiere JavaScript Dependencies...
cd /d "%~dp0.."
npm install
echo.

echo ========================================
echo Installation abgeschlossen!
echo ========================================
echo.
echo Node.js Version:
node --version
echo.
echo npm Version:
npm --version
echo.
echo Nächste Schritte:
echo 1. Kopieren Sie die .env Datei in den env/ Ordner
echo 2. Starten Sie Elasticsearch/OpenSearch mit Docker Compose
echo 3. Führen Sie die Test-Skripte aus:
echo    - npm run test:elasticsearch (Elasticsearch Test)
echo    - npm run test:opensearch (OpenSearch Test)
echo.
echo (!) Nach der Node.js Installation muss evtl. der Computer neu gestartet werden
echo.
pause


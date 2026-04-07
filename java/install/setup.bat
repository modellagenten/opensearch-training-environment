@echo off
echo ========================================
echo Elasticsearch/OpenSearch Java Setup
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

REM Prüfe ob Java bereits installiert ist
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo Java ist nicht installiert. Installiere OpenJDK 25 über Chocolatey...
    echo.
    choco install openjdk25 -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    java -version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei Java Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo Java ist installiert:
java -version
echo.

REM Prüfe ob Gradle bereits installiert ist
gradle --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Gradle ist nicht installiert. Installiere Gradle über Chocolatey...
    echo.
    choco install gradle -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    gradle --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei Gradle Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo Gradle ist installiert:
gradle --version
echo.

REM Wechsle ins Projekt-Verzeichnis und führe Gradle Build aus
echo Baue Java-Projekt...
cd /d "%~dp0.."
gradlew.bat build
echo.

echo ========================================
echo Installation abgeschlossen!
echo ========================================
echo.
echo Java Version:
java -version
echo.
echo Gradle Version:
gradle --version
echo.
echo Nächste Schritte:
echo 1. Kopieren Sie die .env Datei in den env/ Ordner
echo 2. Starten Sie Elasticsearch/OpenSearch mit Docker Compose
echo 3. Führen Sie die Test-Programme aus:
echo    - gradlew.bat run (Elasticsearch Test)
echo    - gradlew.bat run -PmainClass=com.example.OpenSearchConnectionTest (OpenSearch Test)
echo.
echo (!) Nach der Java/Gradle Installation muss evtl. der Computer neu gestartet werden
echo.
pause

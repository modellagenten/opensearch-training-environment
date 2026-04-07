@echo off
echo ========================================
echo Elasticsearch/OpenSearch PHP Setup
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

REM Prüfe ob PHP bereits installiert ist
php --version >nul 2>&1
if %errorlevel% neq 0 (
    echo PHP ist nicht installiert. Installiere PHP über Chocolatey...
    echo.
    choco install php -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    php --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei PHP Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo PHP ist installiert:
php --version
echo.

REM Prüfe ob Composer installiert ist
composer --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Composer ist nicht installiert. Installiere Composer über Chocolatey...
    echo.
    choco install composer -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    composer --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei Composer Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo Composer ist installiert:
composer --version
echo.

echo Installiere PHP Libraries...
cd /d "%~dp0.."
composer install
echo.

echo ========================================
echo Installation abgeschlossen!
echo ========================================
echo.
echo Nächste Schritte:
echo 1. Kopieren Sie die .env Datei in den env/ Ordner
echo 2. Starten Sie Elasticsearch/OpenSearch mit Docker Compose
echo 3. Führen Sie die Test-Skripte in src/ aus
echo.
pause

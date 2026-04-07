@echo off
echo ========================================
echo Elasticsearch/OpenSearch Python Setup
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

REM Prüfe ob Python bereits installiert ist
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python ist nicht installiert. Installiere Python über Chocolatey...
    echo.
    choco install python -y
    echo.
    echo Aktualisiere PATH Umgebungsvariable...
    refreshenv
    echo.
    
    REM Prüfe nochmals nach Installation
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Fehler bei Python Installation!
        echo Bitte starten Sie die Eingabeaufforderung neu und führen Sie das Script erneut aus.
        echo.
        pause
        exit /b 1
    )
)

echo Python ist installiert:
python --version
echo.

REM Installiere pip falls nicht vorhanden
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installiere pip...
    python -m ensurepip --upgrade
)

REM Wechsle ins install Verzeichnis
cd /d "%~dp0"

echo ========================================
echo Erstelle Virtual Environment...
echo ========================================
echo.

set VENV_DIR=venv

if exist "%VENV_DIR%" (
    echo Virtual Environment existiert bereits
    choice /C JN /M "Moechten Sie es neu erstellen"
    if errorlevel 2 (
        echo Verwende existierendes Virtual Environment.
    ) else (
        echo Entferne altes Virtual Environment...
        rmdir /s /q "%VENV_DIR%"
        echo Erstelle neues Virtual Environment...
        python -m venv "%VENV_DIR%"
    )
) else (
    echo Erstelle neues Virtual Environment...
    python -m venv "%VENV_DIR%"
)

echo.
echo Aktiviere Virtual Environment...
call "%VENV_DIR%\Scripts\activate.bat"
echo.

echo Aktualisiere pip im Virtual Environment...
python -m pip install --upgrade pip
echo.

echo ========================================
echo Installiere Python Libraries im venv...
echo ========================================
echo.

python -m pip install -r requirements.txt
echo.

echo ========================================
echo Installation abgeschlossen!
echo ========================================
echo.
echo Python Version:
python --version
echo.
echo pip Version:
pip --version
echo.
echo Virtual Environment:
echo    Pfad: %~dp0venv
echo.
echo Naechste Schritte:
echo.
echo 1. Virtual Environment aktivieren:
echo    install\venv\Scripts\activate.bat
echo.
echo 2. .env Datei kopieren und anpassen
echo.
echo 3. Test-Skripte ausfuehren:
echo    python src\test_elasticsearch.py
echo.
echo 4. Nach der Schulung deaktivieren:
echo    deactivate
echo.
echo 5. Virtual Environment entfernen (optional):
echo    rmdir /s /q install\venv
echo.
pause

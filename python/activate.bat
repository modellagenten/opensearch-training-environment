@echo off
REM Hilfsskript zum schnellen Aktivieren des Virtual Environments

set VENV_PATH=%~dp0install\venv

if not exist "%VENV_PATH%" (
    echo Fehler: Virtual Environment nicht gefunden!
    echo Bitte fuehren Sie zuerst das Setup aus:
    echo   cd install
    echo   setup.bat
    pause
    exit /b 1
)

echo Aktiviere Virtual Environment...
call "%VENV_PATH%\Scripts\activate.bat"

echo.
echo Python Virtual Environment ist aktiv!
echo    Python: 
python --version
echo    Pfad: %VENV_PATH%
echo.
echo Verfuegbare Befehle:
echo    python src\test_elasticsearch.py  - Elasticsearch testen
echo    python src\test_opensearch.py     - OpenSearch testen
echo    deactivate                        - Virtual Environment verlassen
echo.


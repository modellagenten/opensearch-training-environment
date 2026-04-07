@echo off
echo ========================================
echo PHP Schulungsumgebung Deinstallation
echo ========================================
echo.
echo Dieses Script entfernt:
echo   - Composer vendor\ Verzeichnis
echo   - Composer autoload Dateien
echo   - composer.lock
echo.
echo NICHT entfernt werden:
echo   - PHP (bleibt installiert)
echo   - Composer (bleibt installiert)
echo.
choice /C JN /M "Moechten Sie fortfahren"
if errorlevel 2 (
    echo Abgebrochen.
    exit /b 0
)

echo.
echo Entferne Composer Dependencies...

REM Wechsle ins Script-Verzeichnis
cd /d "%~dp0"

REM Entferne vendor Verzeichnis
if exist "install\vendor" (
    rmdir /s /q "install\vendor"
    echo Entfernt: install\vendor\
) else (
    echo Existiert nicht: install\vendor\
)

REM Entferne composer.lock
if exist "install\composer.lock" (
    del /q "install\composer.lock"
    echo Entfernt: install\composer.lock
) else (
    echo Existiert nicht: install\composer.lock
)

echo.
echo ========================================
echo Deinstallation abgeschlossen!
echo ========================================
echo.
echo Hinweise:
echo.
echo Die PHP-Pakete wurden entfernt.
echo.
echo Falls Sie PHP und Composer komplett deinstallieren moechten:
echo.
echo Windows (Chocolatey):
echo   choco uninstall php composer
echo.
pause


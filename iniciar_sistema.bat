@echo off
title sistema - PSJ (Localhost)
chcp 65001 >nul

cd /d "%~dp0"

if not defined PGHOST set "PGHOST=localhost"
if not defined PGPORT set "PGPORT=5432"
if not defined PGDATABASE set "PGDATABASE=db_asesoria"
if not defined PGUSER set "PGUSER=postgres"
if not defined PORT set "PORT=8000"

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] No se encontro el entorno virtual en .venv\Scripts\python.exe
    echo Ejecuta primero:
    echo   python -m venv .venv
    echo   .venv\Scripts\python.exe -m pip install psycopg2-binary
    pause
    exit /b 1
)

echo ==============================================================
echo  Iniciando sistema - PSJ en http://localhost:%PORT%
echo  Base de datos: %PGDATABASE%@%PGHOST%:%PGPORT% (Usuario: %PGUSER%)
echo ==============================================================
echo.

REM Abre el navegador automaticamente despues de 2 segundos
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:%PORT%"

".venv\Scripts\python.exe" "python_backend\app.py"
pause

@echo off
setlocal EnableDelayedExpansion
title sistema - PSJ (Localhost)

cd /d "%~dp0"

REM Cargar configuracion local .env si existe (sin sobrescribir variables ya definidas)
if exist ".env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in (".env") do (
        if not "%%~A"=="" (
            if not defined %%~A set "%%~A=%%~B"
        )
    )
)

if not defined PGHOST set "PGHOST=localhost"
if not defined PGPORT set "PGPORT=5432"
if not defined PGDATABASE set "PGDATABASE=db_asesoria"
if not defined PGUSER set "PGUSER=postgres"
if not defined PGPASSWORD set "PGPASSWORD=postgres"
if not defined PORT set "PORT=8000"
set "PGCLIENTENCODING=utf-8"

REM ==================================================================
REM 1. Verificar o reconstruir el entorno virtual .venv automaticamente
REM ==================================================================
".venv\Scripts\python.exe" --version >nul 2>&1
if errorlevel 1 (
    if exist ".venv" (
        echo [INFO] Entorno virtual .venv incompatible o danado. Reconstruyendo...
        rmdir /s /q ".venv"
    ) else (
        echo [INFO] Configurando el sistema por primera vez...
    )

    set "PY_CMD="
    python --version >nul 2>&1
    if not errorlevel 1 (
        set "PY_CMD=python"
    ) else (
        py --version >nul 2>&1
        if not errorlevel 1 (
            set "PY_CMD=py"
        )
    )

    if not defined PY_CMD (
        echo.
        echo [ERROR] No se detecto Python instalado en esta computadora.
        echo Por favor descarga e instala Python desde https://www.python.org/downloads/
        echo IMPORTANTE: Marca la casilla "Add python.exe to PATH" durante la instalacion.
        echo.
        pause
        exit /b 1
    )

    echo [INFO] Creando entorno virtual con !PY_CMD!...
    !PY_CMD! -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Fallo al crear el entorno virtual .venv.
        pause
        exit /b 1
    )
    echo [OK] Entorno virtual creado.
)

REM ==================================================================
REM 2. Verificar o instalar psycopg2-binary automaticamente
REM ==================================================================
".venv\Scripts\python.exe" -c "import psycopg2" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Instalando conector de base de datos ^(psycopg2-binary^)...
    ".venv\Scripts\python.exe" -m pip install --disable-pip-version-check psycopg2-binary
    ".venv\Scripts\python.exe" -c "import psycopg2" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [ERROR] No se pudo instalar psycopg2-binary.
        echo Verifica tu conexion a internet e intentalo nuevamente.
        echo.
        pause
        exit /b 1
    )
    echo [OK] Conector PostgreSQL instalado.
)

REM ==================================================================
REM 3. Verificar y migrar base de datos automaticamente
REM ==================================================================
if exist "database\verificar_y_migrar_bd.py" (
    echo [INFO] Comprobando base de datos PostgreSQL ^(!PGDATABASE!@!PGHOST!:!PGPORT!^)...
    ".venv\Scripts\python.exe" "database\verificar_y_migrar_bd.py"
    set "DB_ERR=!errorlevel!"

    if "!DB_ERR!"=="2" (
        echo.
        echo [AVISO] La contrasena configurada para el usuario '!PGUSER!' no funciono.
        set "NEW_PASS="
        set /p "NEW_PASS=Ingresa tu contrasena de PostgreSQL para '!PGUSER!' (o Enter para omitir): "
        if defined NEW_PASS (
            set "PGPASSWORD=!NEW_PASS!"
            (
                echo PGHOST=!PGHOST!
                echo PGPORT=!PGPORT!
                echo PGDATABASE=!PGDATABASE!
                echo PGUSER=!PGUSER!
                echo PGPASSWORD=!PGPASSWORD!
                echo PORT=!PORT!
            ) > ".env"
            echo [INFO] Configuracion guardada en .env. Reintentando conexion...
            ".venv\Scripts\python.exe" "database\verificar_y_migrar_bd.py"
        )
    ) else if "!DB_ERR!"=="3" (
        echo.
        echo [AVISO] PostgreSQL no parece estar encendido en !PGHOST!:!PGPORT!.
        echo         Asegurate de que el servicio de PostgreSQL este iniciado.
        echo         El panel web abrira igualmente para que puedas probar la conexion luego.
    )
    echo.
)

echo ==============================================================
echo  Iniciando sistema - PSJ en http://localhost:!PORT!
echo  Base de datos: !PGDATABASE!@!PGHOST!:!PGPORT! (Usuario: !PGUSER!)
echo ==============================================================
echo.

REM Abre el navegador automaticamente despues de 2 segundos
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:!PORT!"

".venv\Scripts\python.exe" "python_backend\app.py"
pause

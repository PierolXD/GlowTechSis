$ErrorActionPreference = 'Stop'
if (-not $env:PGHOST)     { $env:PGHOST = 'localhost' }
if (-not $env:PGPORT)     { $env:PGPORT = '5432' }
if (-not $env:PGDATABASE) { $env:PGDATABASE = 'db_asesoria' }
if (-not $env:PGUSER)     { $env:PGUSER = 'postgres' }
if (-not $env:PORT)       { $env:PORT = '8000' }

$venvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
$appScript  = Join-Path $PSScriptRoot 'python_backend\app.py'

if (-not (Test-Path $venvPython)) {
    Write-Host "[ERROR] No se encontró el entorno virtual en: $venvPython" -ForegroundColor Red
    Write-Host "Créalo con: python -m venv .venv ; .\.venv\Scripts\python.exe -m pip install psycopg2-binary" -ForegroundColor Yellow
    exit 1
}

Write-Host "Iniciando GlowTechSis en http://localhost:$($env:PORT) (BD: $($env:PGDATABASE)@$($env:PGHOST):$($env:PGPORT))..." -ForegroundColor Cyan
& $venvPython $appScript

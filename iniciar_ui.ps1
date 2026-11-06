$ErrorActionPreference = 'Stop'
$env:PGHOST = 'localhost'
$env:PGPORT = '5432'
$env:PGDATABASE = 'db_asesoria'
$env:PGUSER = 'postgres'
$env:PORT = '8000'
& (Join-Path $PSScriptRoot '.venv\Scripts\python.exe') (Join-Path $PSScriptRoot 'python_backend\app.py')
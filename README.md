# GlowTechSis — Sistema de Asesoramiento Técnico (PostgreSQL + Python Nativo)

Sistema de base de datos y aplicativo web para el proceso consultivo de **Atención y Asesoramiento Técnico** de **Glowtech** (UCSM — Ingeniería de Sistemas).

- **Base de datos:** PostgreSQL 14+ (`db_asesoria`) — 9 tablas en 3FN, 9 índices, **27 Stored Procedures PL/pgSQL**, **5 Triggers de validación** y catálogo de 211 productos (15 categorías, 26 marcas).
- **Backend:** Python 3 nativo (`python_backend/app.py` con `http.server` y `psycopg2`, cero frameworks).
- **Frontend:** HTML5 / CSS3 / JavaScript Vanilla (`python_backend/index.html` con `fetch()`).
- **Simulador opcional:** Separado y optimizado en `simulador_react/` (React en memoria, no requerido para el sistema real).

---

## Estructura del Proyecto

```text
├── database/
│   ├── script_completo_glowtech.sql   # Script maestro todo-en-uno (psql y pgAdmin 4)
│   ├── solucion_postgresql.sql        # Índices, 27 Stored Procedures y 5 Triggers
│   ├── reportes.sql                   # 10 Consultas de INIFORMACION.docx + 10 Reportes Gerenciales
│   ├── schema_original.sql            # Dump original pg_dump de referencia
│   └── verificar_y_migrar_bd.py       # Crea/actualiza db_asesoria automáticamente
├── python_backend/
│   ├── app.py                         # Servidor nativo Python (http.server + psycopg2)
│   └── index.html                     # Panel web completo (Asesoría 3 etapas, CRUD 9 tablas, 20 consultas)
├── public/
│   └── index_standalone.html          # Copia sincronizada de index.html
├── tests/
│   └── test_sistema.py                # Pruebas automatizadas end-to-end
├── docs/
│   ├── MEMORIA_TECNICA.md             # Memoria técnica del proyecto
│   └── DOCUMENTACION_SCRIPTS_Y_CODIGOS.md  # Documentación de scripts, códigos y verificación de manuales
├── simulador_react/                   # Simulador React opcional (separado)
├── .env.example                       # Variables de conexión a PostgreSQL
└── iniciar_ui.ps1                     # Script de arranque en Windows
```

---

## Instalación y Puesta en Marcha

### 1. Crear y cargar la Base de Datos (`db_asesoria`)

Opción recomendada (con `psql` o pgAdmin 4 Query Tool):
```powershell
psql -U postgres -c "CREATE DATABASE db_asesoria;"
psql -U postgres -d db_asesoria -f database/script_completo_glowtech.sql
```

O automáticamente con Python (crea `db_asesoria` si no existe y aplica el script maestro):
```powershell
$env:PGPASSWORD = "tu_contraseña"
.\.venv\Scripts\python.exe database\verificar_y_migrar_bd.py
```

### 2. Preparar entorno Python (si no existe `.venv`)
```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install psycopg2-binary
```

### 3. Iniciar el Sistema
```powershell
$env:PGPASSWORD = "tu_contraseña"
.\iniciar_ui.ps1
```
Abre en tu navegador: **http://localhost:8000**

### 4. Ejecutar Pruebas Automatizadas (CRUD 9 tablas, 27 SPs, 5 Triggers y 20 Consultas)
```powershell
$env:PGPASSWORD = "tu_contraseña"
.\.venv\Scripts\python.exe tests\test_sistema.py
```

---

## Documentación Entregable
- **Memoria Técnica:** `docs/MEMORIA_TECNICA.md`
- **Documentación de Scripts, Códigos y Verificación del Manual:** `docs/DOCUMENTACION_SCRIPTS_Y_CODIGOS.md`
- **Manuales de Usuario:** `Manual_Completo_GlowTechSis.pdf` y `Guia_Rapida_GlowTechSis.pdf` (en la carpeta raíz del proyecto)

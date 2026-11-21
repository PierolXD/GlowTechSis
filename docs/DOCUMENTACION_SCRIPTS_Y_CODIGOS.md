# Documentación de Scripts SQL, Códigos Fuente y Verificación del Manual de Usuario

Este documento acompaña a [MEMORIA_TECNICA.md](MEMORIA_TECNICA.md) y cubre los entregables de **scripts**, **códigos** y la **verificación de los manuales de usuario** existentes (`Manual_Completo_GlowTechSis.pdf` y `Guia_Rapida_GlowTechSis.pdf`).

---

## 1. Estructura Final del Proyecto

```text
postgresql-suite-&-native-python-hub (1)/
├── database/
│   ├── script_completo_glowtech.sql   # Script maestro todo-en-uno (DDL + 211 productos + 27 SPs + 5 Triggers)
│   ├── schema_original.sql            # Respaldo pg_dump original (conservado como referencia)
│   ├── solucion_postgresql.sql        # Índices + 27 Stored Procedures + 5 Triggers (idempotente)
│   ├── reportes.sql                   # 10 Consultas de INIFORMACION.docx + 10 Reportes Gerenciales
│   └── verificar_y_migrar_bd.py       # Script Python que crea/actualiza db_asesoria y verifica integridad
├── python_backend/
│   ├── app.py                         # Servidor HTTP nativo (http.server + psycopg2, 0 frameworks)
│   └── index.html                     # Panel web nativo (HTML5 + CSS3 + Vanilla JS)
├── public/
│   └── index_standalone.html          # Copia sincronizada de python_backend/index.html
├── tests/
│   └── test_sistema.py                # Suite automatizada: conexión, 20 consultas, CRUD 9 tablas y 5 triggers
├── docs/
│   ├── MEMORIA_TECNICA.md             # Memoria técnica del sistema
│   └── DOCUMENTACION_SCRIPTS_Y_CODIGOS.md  # Este documento
├── simulador_react/                   # Simulador React en memoria (separado y optimizado)
│   ├── src/
│   ├── index.html
│   ├── package.json                   # Dependencias depuradas (solo react, react-dom, lucide-react)
│   ├── tsconfig.json
│   └── vite.config.ts
├── .env.example                       # Plantilla real de variables PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD
├── iniciar_ui.ps1                     # Script PowerShell de arranque para Windows
└── README.md                          # Guía raíz actualizada
```

---

## 2. Documentación de Scripts SQL (`database/`)

### 2.1 `database/script_completo_glowtech.sql` (Script Maestro Recomendado)
- **Propósito:** Desplegar toda la base de datos desde cero o completarla de forma idempotente en **una sola ejecución**.
- **Compatibilidad:** 100% SQL estándar compatible con `psql` y **pgAdmin 4 Query Tool** (elimina directivas problemáticas de `pg_dump 18.3` como `\restrict`, `transaction_timeout` y `COPY ... FROM stdin`).
- **Secciones:**
  1. `CREATE TABLE IF NOT EXISTS` para las 9 tablas con PKs, FKs y `CHECK (nivel_compatibilidad BETWEEN 0 AND 100)`.
  2. `INSERT INTO ... ON CONFLICT DO NOTHING` con las 15 categorías, 26 marcas, 211 productos (`PROD0001`–`PROD0211`), 1 asesor, 1 cliente (`12345678`), 1 perfil, 1 matriz, 3 evaluaciones y 1 recomendación.
  3. `SELECT setval(...)` para sincronizar las 6 secuencias `GENERATED ALWAYS AS IDENTITY`.
  4. Los 9 índices, 27 Stored Procedures y 5 Triggers.

### 2.2 `database/solucion_postgresql.sql`
Contiene toda la lógica programable en PL/pgSQL (repetible sin errores):
- **Índices:** 9 índices `IF NOT EXISTS` sobre llaves foráneas y columnas de filtro (`precio_referencial`, `fecha_registro`).
- **27 Stored Procedures (CRUD completo de 9 entidades):**
  - `cliente`: `sp_insertar_cliente`, `sp_modificar_cliente`, `sp_eliminar_cliente`
  - `producto_catalogo`: `sp_insertar_producto`, `sp_modificar_producto`, `sp_eliminar_producto`
  - `perfil_de_necesidad`: `sp_insertar_perfil_necesidad` (retorna `INOUT p_id_perfil`), `sp_modificar_perfil_necesidad`, `sp_eliminar_perfil_necesidad`
  - `categoria`: `sp_insertar_categoria` (`INOUT`), `sp_modificar_categoria`, `sp_eliminar_categoria`
  - `marca`: `sp_insertar_marca` (`INOUT`), `sp_modificar_marca`, `sp_eliminar_marca`
  - `asesor_tecnico`: `sp_insertar_asesor` (`INOUT`), `sp_modificar_asesor`, `sp_eliminar_asesor`
  - `matriz_de_comparativa`: `sp_insertar_matriz` (`INOUT`), `sp_modificar_matriz`, `sp_eliminar_matriz`
  - `detalle_evaluacion`: `sp_insertar_detalle_evaluacion`, `sp_modificar_detalle_evaluacion`, `sp_eliminar_detalle_evaluacion`
  - `recomendacion_final`: `sp_insertar_recomendacion` (`INOUT`), `sp_modificar_recomendacion`, `sp_eliminar_recomendacion`
- **5 Triggers de Validación:**
  - `trg_validar_perfil` (`fn_validar_perfil_necesidad`)
  - `trg_validar_cliente` (`fn_validar_cliente`)
  - `trg_validar_producto` (`fn_validar_producto`)
  - `trg_validar_asesor` (`fn_validar_asesor`)
  - `trg_validar_recomendacion` (`fn_validar_recomendacion`)

### 2.3 `database/reportes.sql`
- **Sección A:** Las 10 consultas operativas exactas de `INIFORMACION.docx` (Figuras 26 a 35).
- **Sección B:** Los 10 reportes gerenciales (8 con `JOIN` y agregaciones + 2 consultas analíticas directas).

### 2.4 `database/verificar_y_migrar_bd.py`
Script auxiliar en Python que se conecta a PostgreSQL, crea la base `db_asesoria` si aún no existe, aplica `script_completo_glowtech.sql` y muestra un resumen de tablas, conteo de registros, procedimientos y triggers activos.

---

## 3. Documentación de Códigos Fuente

### 3.1 `python_backend/app.py`
Servidor HTTP multihilo (`ThreadingHTTPServer`) basado únicamente en `http.server` y `psycopg2`:
- **Carga de configuración:** Lee variables de entorno (`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PORT`) con soporte automático de archivo `.env` local. Por defecto apunta a `db_asesoria` en `localhost:5432`.
- **Rutas de Diagnóstico:**
  - `GET /api/health` — Estado de servidor + PostgreSQL + conteo de tablas, SPs y triggers.
  - `GET /api/test-db` — Auditoría detallada de conexión, versión, conteo por tabla y listado de SPs/triggers.
- **Rutas de Consultas y Asesoría:**
  - `GET /api/reports/list` y `GET /api/reports?id=1..10` — 10 Reportes Gerenciales.
  - `GET /api/consultas-doc/list` y `GET /api/consultas-doc?id=1..10&...` — 10 Consultas parametrizadas de `INIFORMACION.docx`.
  - `GET /api/asesoria/candidatos?id_perfil=X&categoria=Y` — Algoritmo de mapeo y sugerencia de compatibilidad.
- **Rutas de Listado (`GET /api/data/*`):** `categorias`, `marcas`, `asesores`, `clientes`, `productos`, `perfiles`, `matrices`, `detalles`, `recomendaciones`.
- **Rutas CRUD vía Stored Procedures:**
  - `POST /api/sp/insert_{cliente,producto,perfil,categoria,marca,asesor,matriz,detalle,recomendacion}`
  - `PUT /api/sp/update_{cliente,producto,perfil,categoria,marca,asesor,matriz,detalle,recomendacion}`
  - `DELETE /api/sp/delete_{cliente,producto,perfil,categoria,marca,asesor,matriz,detalle,recomendacion}`

### 3.2 `python_backend/index.html` (y `public/index_standalone.html`)
Interfaz web nativa en un solo archivo sin dependencias externas:
- **Barra de estado real:** Distingue entre servidor Python activo y conexión efectiva a PostgreSQL, con botón **Probar Conexión BD**.
- **5 Pestañas principales:**
  1. *Flujo de Asesoría (3 Etapas)*
  2. *10 Consultas del Documento* (parametrizables + CSV)
  3. *10 Reportes Gerenciales* (+ CSV)
  4. *Gestión CRUD (9 Tablas)* con selectores `<select>` poblados en tiempo real y botón **Editar** en cada fila
  5. *5 Triggers (Pruebas en Vivo)*

### 3.3 `tests/test_sistema.py`
Suite de verificación de extremo a extremo que levanta un servidor HTTP temporal en puerto `8099` y prueba contra PostgreSQL real:
1. Conexión e integridad de las 9 tablas, 211+ productos, 27+ SPs y 5+ triggers.
2. Ejecución de los 10 Reportes Gerenciales.
3. Ejecución de las 10 Consultas de `INIFORMACION.docx`.
4. Ejecución del Algoritmo de Mapeo (`/api/asesoria/candidatos`).
5. Ciclo CRUD completo (`POST -> PUT -> DELETE`) en las 9 tablas sin dejar registros basura.
6. Rechazo real (HTTP 400) de los 5 Triggers ante datos inválidos.

---

## 4. Verificación de los Manuales de Usuario Existentes

Se revisaron ambos manuales PDF proporcionados en la raíz del proyecto:
- `Guia_Rapida_GlowTechSis.pdf` (5 páginas)
- `Manual_Completo_GlowTechSis.pdf` (26 páginas)

### Resultado de la Verificación
1. **Compatibilidad 100% preservada:** Todas las rutas API (las 13 originales), los 9 nombres de tablas, las 6 variables de entorno, el puerto `8000`, la base `db_asesoria`, los 10 reportes y las firmas de los 9 procedimientos iniciales documentados en ambos manuales **siguen funcionando exactamente igual**.
2. **Limitaciones del manual que fueron resueltas en esta versión:**

| Limitación documentada en el Manual (págs. 8, 17, 24) | Estado Actual (Resuelto) |
| :--- | :--- |
| "La web cubre solo clientes y productos; perfiles, matrices, evaluaciones y recomendaciones se manejan por psql" | **Resuelto:** La web ahora incluye CRUD completo para las **9 tablas** + Flujo guiado de Asesoría en 3 etapas. |
| "La lista de productos no tiene botón Editar y marca/categoría se escriben como número" | **Resuelto:** Productos ahora tiene `<select>` dinámicos de Marca y Categoría, buscador y botón **Editar** en cada fila. |
| "Reporte 3 en la web no muestra `restriccion_tecnica`; `reportes.sql` sí" | **Resuelto:** Reporte 3 en `app.py` ahora incluye `pn.restriccion_tecnica` igual que `reportes.sql`. |
| "`insert_perfil` no devuelve el número del perfil creado" | **Resuelto:** `POST /api/sp/insert_perfil` ahora lee el parámetro `INOUT` y devuelve `id_perfil`. |
| "Archivos duplicados en `public/python_backend/app.py`, `public/README.md` y `public/assets/aistudio/`" | **Resuelto:** Eliminados los duplicados obsoletos; solo se conserva `public/index_standalone.html` sincronizado. |
| "El README de la raíz omite `schema_original.sql` y usa la base `postgres`" | **Resuelto:** `README.md` y `app.py` ahora usan `db_asesoria` por defecto e indican `script_completo_glowtech.sql`. |
| "`schema_original.sql` muestra avisos de `transaction_timeout` y `\restrict` en PostgreSQL < 17" | **Resuelto:** Se creó `database/script_completo_glowtech.sql` 100% estándar, idempotente y compatible con pgAdmin 4. |
| "`.env.example` es una plantilla de AI Studio que el servidor no usa" | **Resuelto:** `.env.example` ahora contiene las variables de PostgreSQL y `app.py` carga `.env` automáticamente si existe. |

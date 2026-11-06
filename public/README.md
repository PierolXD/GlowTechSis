# Guía de Ejecución: PostgreSQL Suite & Servidor Nativo Python

Esta solución responde con rigor a los 5 requisitos solicitados:

1. **Stored Procedures en PL/pgSQL:** Inserción, Modificación y Borrado (`sp_insertar_cliente`, `sp_modificar_cliente`, `sp_eliminar_cliente`, `sp_insertar_producto`, `sp_modificar_producto`, `sp_eliminar_producto`, `sp_insertar_perfil_necesidad`, etc.).
2. **Triggers:**
   - `trg_validar_perfil` (BEFORE INSERT/UPDATE): Validación de reglas de negocio (presupuesto > 0, fechas no futuras).
   - `trg_auditar_productos` (AFTER INSERT/UPDATE/DELETE): Auditoría completa en tabla `auditoria_cambios` con `JSONB` y usuario DB.
   - `trg_validar_cliente` (BEFORE INSERT/UPDATE): Validación estricta de DNI (8 dígitos) y sanitización.
3. **10 Consultas SQL para Reportes:** 8 con `JOINs` (catálogo, comparativa de precios, perfiles y asesores, matrices técnicas, recomendaciones con compatibilidad, ahorro financiero, etc.) y 2 analíticas directas.
4. **`app.py`:** Servidor HTTP nativo en Python usando únicamente `http.server` y `psycopg2` (sin Flask, sin Express, sin frameworks).
5. **`index.html`:** Interfaz web nativa con JavaScript puro (`fetch`) para enviar datos al servidor y mostrar los reportes en tablas dinámicas.

---

## Estructura de Archivos Generados

```text
├── database/
│   ├── solucion_postgresql.sql    # Stored Procedures, Triggers y Tabla de Auditoría
│   └── reportes.sql               # Las 10 consultas SQL para reportes
├── python_backend/
│   ├── app.py                     # Servidor nativo con http.server y psycopg2
│   └── index.html                 # Frontend nativo para despliegue junto al servidor
├── public/
│   ├── index_standalone.html      # Copia independiente para doble clic o host estático
│   └── assets/aistudio/...        # Esquema original subido
└── README.md                      # Esta documentación
```

---

## Paso 1: Configurar la Base de Datos PostgreSQL

1. Abre tu terminal o pgAdmin y conéctate a tu PostgreSQL:
   ```bash
   psql -U postgres -d postgres
   ```

2. Si aún no has cargado el esquema inicial, cárgalo:
   ```bash
   psql -U postgres -d postgres -f public/assets/aistudio/prueba_f2ed2c82.sql
   ```

3. Carga los Stored Procedures y Triggers:
   ```bash
   psql -U postgres -d postgres -f database/solucion_postgresql.sql
   ```

4. Puedes probar las 10 consultas directamente en psql:
   ```bash
   psql -U postgres -d postgres -f database/reportes.sql
   ```

---

## Paso 2: Iniciar el Servidor Nativo Python (`app.py`)

1. Asegúrate de tener Python 3 y `psycopg2` instalado:
   ```bash
   pip install psycopg2-binary
   ```

2. (Opcional) Configura las variables de conexión si tu PostgreSQL usa credenciales distintas:
   ```bash
   export PGHOST=localhost
   export PGPORT=5432
   export PGDATABASE=postgres
   export PGUSER=postgres
   export PGPASSWORD=tu_password
   export PORT=8000
   ```

3. Ejecuta el servidor nativo:
   ```bash
   cd python_backend
   python app.py
   ```

Verás en la consola:
```text
======================================================================
 Servidor Nativo Python (http.server + psycopg2) en puerto 8000
 CERO FRAMEWORKS (Sin Flask, sin Express, sin React)
======================================================================
 URL local: http://localhost:8000
```

---

## Paso 3: Usar la Aplicación Web (`index.html`)

1. Abre en tu navegador favorito:
   ```text
   http://localhost:8000
   ```
   (O simplemente haz doble clic en `public/index_standalone.html` en tu explorador de archivos).

2. **10 Reportes:** Selecciona del desplegable cualquier reporte y presiona **"Ejecutar Consulta (fetch)"**. La tabla dinámica se construirá en tiempo real con los resultados de PostgreSQL.
3. **Stored Procedures de Clientes:** Prueba insertar un cliente con DNI de 8 dígitos, modificar sus datos o eliminarlo. Se invocarán `sp_insertar_cliente`, `sp_modificar_cliente` y `sp_eliminar_cliente`.
4. **Stored Procedures de Productos:** Inserta un producto nuevo en el catálogo o modifica precios.
5. **Triggers:** Entra a la pestaña "Triggers & Auditoría" para ver cómo cada operación en el catálogo queda auditada en la tabla `auditoria_cambios` automáticamente.

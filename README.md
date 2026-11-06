# Guía de Ejecución: PostgreSQL Suite & Servidor Nativo Python

Esta solución responde con rigor a los requerimientos solicitados para el esquema PostgreSQL:

1. **Stored Procedures en PL/pgSQL:** Inserción, Modificación y Borrado (`sp_insertar_cliente`, `sp_modificar_cliente`, `sp_eliminar_cliente`, `sp_insertar_producto`, `sp_modificar_producto`, `sp_eliminar_producto`, `sp_insertar_perfil_necesidad`, etc.).
2. **Triggers de Validación:**
   - `trg_validar_perfil` (BEFORE INSERT/UPDATE ON perfil_de_necesidad): Validación de reglas de negocio (presupuesto > 0, fechas no futuras).
   - `trg_validar_cliente` (BEFORE INSERT/UPDATE ON cliente): Validación estricta de formato DNI (8 dígitos numéricos) y sanitización de texto.
   - `trg_validar_producto` (BEFORE INSERT/UPDATE ON producto_catalogo): Validación de código/modelo no vacíos y precios referenciales no negativos.
3. **10 Consultas SQL para Reportes:** 8 con `JOINs` (catálogo, comparativa de precios, perfiles y asesores, matrices técnicas, recomendaciones con compatibilidad, ahorro financiero, etc.) y 2 analíticas directas.
4. **`app.py`:** Servidor HTTP nativo en Python usando únicamente `http.server` y `psycopg2` (sin Flask, sin Express, sin frameworks).
5. **`index.html`:** Interfaz web nativa con JavaScript puro (`fetch`) para enviar datos al servidor y mostrar los reportes en tablas dinámicas.

---

## Estructura de Archivos

```text
├── database/
│   ├── solucion_postgresql.sql    # Stored Procedures y Triggers de Validación
│   └── reportes.sql               # Las 10 consultas SQL para reportes
├── python_backend/
│   ├── app.py                     # Servidor nativo con http.server y psycopg2
│   └── index.html                 # Frontend nativo para despliegue junto al servidor
├── public/
│   └── index_standalone.html      # Copia independiente para doble clic o host estático
└── README.md                      # Esta documentación
```

---

## Paso 1: Configurar la Base de Datos PostgreSQL

1. Abre tu terminal o pgAdmin y conéctate a tu PostgreSQL:
   ```bash
   psql -U postgres -d postgres
   ```

2. Carga los Stored Procedures y Triggers de validación:
   ```bash
   psql -U postgres -d postgres -f database/solucion_postgresql.sql
   ```

3. Puedes probar las 10 consultas directamente en psql:
   ```bash
   psql -U postgres -d postgres -f database/reportes.sql
   ```

---

## Paso 2: Iniciar el Servidor Nativo Python (`app.py`)

1. Asegúrate de tener Python 3 y `psycopg2` instalado:
   ```bash
   pip install psycopg2-binary
   ```

2. Ejecuta el servidor nativo:
   ```bash
   cd python_backend
   python app.py
   ```

---

## Paso 3: Usar la Aplicación Web (`index.html`)

1. Abre en tu navegador favorito:
   ```text
   http://localhost:8000
   ```
   (O simplemente abre `public/index_standalone.html` con doble clic).

2. Selecciona cualquiera de los 10 reportes para consultar los datos mediante `fetch()` y visualizarlos en tablas dinámicas.

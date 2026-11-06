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

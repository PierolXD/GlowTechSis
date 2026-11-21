#!/usr/bin/env python3
"""
===============================================================================
GLOWTECH - BACKEND NATIVO PYTHON (http.server + psycopg2)
===============================================================================
Características:
- Cero frameworks externos (sin Flask, sin FastAPI, sin Django, sin Express).
- Usa únicamente la biblioteca estándar 'http.server' de Python y 'psycopg2'.
- Expone CRUD completo vía Stored Procedures (CALL public.sp_*) para las 9 tablas.
- Expone las 10 Consultas Operativas parametrizadas de INIFORMACION.docx.
- Expone los 10 Reportes Gerenciales con JOINs y agregaciones.
- Expone asistencia del Algoritmo de Mapeo en 3 etapas y diagnóstico de BD.
===============================================================================
"""

import json
import os
import urllib.parse
from datetime import date, datetime
from decimal import Decimal
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

try:
    import psycopg2
    from psycopg2 import extras
except ImportError:
    print("[ADVERTENCIA] psycopg2 no está instalado en este entorno de Python.")
    print("Instálalo con: pip install psycopg2-binary")
    psycopg2 = None


def _load_dotenv_if_present():
    """Carga variables de entorno desde .env local si existe (sin dependencias)."""
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", ".env"),
        os.path.join(os.path.dirname(__file__), ".env"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as fh:
                    for raw_line in fh:
                        line = raw_line.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        key, val = line.split("=", 1)
                        key = key.strip()
                        val = val.strip().strip('"').strip("'")
                        if key and key not in os.environ:
                            os.environ[key] = val
            except OSError:
                pass


_load_dotenv_if_present()

# -----------------------------------------------------------------------------
# CONFIGURACIÓN DE CONEXIÓN A POSTGRESQL
# -----------------------------------------------------------------------------
DB_CONFIG = {
    "host": os.environ.get("PGHOST", "localhost"),
    "port": int(os.environ.get("PGPORT", "5432")),
    "dbname": os.environ.get("PGDATABASE", "db_asesoria"),
    "user": os.environ.get("PGUSER", "postgres"),
    "password": os.environ.get("PGPASSWORD", "postgres"),
}

SERVER_PORT = int(os.environ.get("PORT", "8000"))

EXPECTED_TABLES = [
    "asesor_tecnico",
    "categoria",
    "cliente",
    "detalle_evaluacion",
    "marca",
    "matriz_de_comparativa",
    "perfil_de_necesidad",
    "producto_catalogo",
    "recomendacion_final",
]

# -----------------------------------------------------------------------------
# SECCIÓN A: 10 REPORTES GERENCIALES (8 CON JOINS + 2 ANALÍTICOS DIRECTOS)
# -----------------------------------------------------------------------------
REPORT_QUERIES = {
    1: {
        "title": "Catálogo Completo con Marca y Categoría",
        "description": "Lista todos los productos vinculando su marca y categoría (3 tablas con JOINs).",
        "sql": """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca,
                c.nombre_categoria,
                p.precio_referencial,
                p.especificaciones
            FROM public.producto_catalogo p
            INNER JOIN public.marca m ON p.id_marca = m.id_marca
            INNER JOIN public.categoria c ON p.id_categoria = c.id_categoria
            ORDER BY c.nombre_categoria ASC, p.precio_referencial DESC;
        """,
    },
    2: {
        "title": "Resumen Estadístico de Precios por Categoría",
        "description": "Total de productos, precio promedio, mínimo y máximo por categoría (LEFT JOIN con agregaciones).",
        "sql": """
            SELECT
                c.id_categoria,
                c.nombre_categoria,
                COUNT(p.codigo_producto) AS total_productos,
                COALESCE(ROUND(AVG(p.precio_referencial), 2), 0.00) AS precio_promedio,
                COALESCE(MIN(p.precio_referencial), 0.00) AS precio_minimo,
                COALESCE(MAX(p.precio_referencial), 0.00) AS precio_maximo
            FROM public.categoria c
            LEFT JOIN public.producto_catalogo p ON c.id_categoria = p.id_categoria
            GROUP BY c.id_categoria, c.nombre_categoria
            ORDER BY total_productos DESC, c.nombre_categoria ASC;
        """,
    },
    3: {
        "title": "Perfiles de Necesidad con Clientes y Asesores Asignados",
        "description": "Ficha completa de requerimientos del cliente con asesor, restricciones y marca preferida (4 tablas con JOINs).",
        "sql": """
            SELECT
                pn.id_perfil,
                pn.fecha_registro,
                cl.dni_cliente,
                CONCAT(cl.nombres, ' ', cl.apellidos) AS cliente_nombre,
                cl.canal_contacto,
                cl.telefono,
                pn.uso_principal,
                pn.presupuesto_max,
                pn.restriccion_tecnica,
                CONCAT(ast.nombres, ' ', ast.apellidos) AS asesor_tecnico,
                ast.turno AS turno_asesor,
                COALESCE(m.nombre_marca, 'Sin preferencia') AS marca_preferida
            FROM public.perfil_de_necesidad pn
            INNER JOIN public.cliente cl ON pn.dni_cliente = cl.dni_cliente
            INNER JOIN public.asesor_tecnico ast ON pn.id_asesor = ast.id_asesor
            LEFT JOIN public.marca m ON pn.id_marca = m.id_marca
            ORDER BY pn.fecha_registro DESC, pn.id_perfil DESC;
        """,
    },
    4: {
        "title": "Matriz Comparativa y Detalle de Evaluación Técnica",
        "description": "Criterios técnicos de evaluación y resultados de candidatos analizados (4 tablas con JOINs).",
        "sql": """
            SELECT
                mc.id_comparativa,
                mc.criterio_evaluacion,
                mc.diferencial_tecnico,
                p.codigo_producto,
                p.modelo AS producto_evaluado,
                m.nombre_marca,
                p.precio_referencial,
                de.resultado_evaluacion
            FROM public.matriz_de_comparativa mc
            INNER JOIN public.detalle_evaluacion de ON mc.id_comparativa = de.id_comparativa
            INNER JOIN public.producto_catalogo p ON de.codigo_producto = p.codigo_producto
            INNER JOIN public.marca m ON p.id_marca = m.id_marca
            ORDER BY mc.id_comparativa ASC, p.precio_referencial ASC;
        """,
    },
    5: {
        "title": "Recomendaciones Finales con Nivel de Compatibilidad",
        "description": "Productos finales recomendados al cliente con porcentaje de afinidad y sugerencias de uso (JOIN).",
        "sql": """
            SELECT
                rf.id_recomendacion,
                rf.id_comparativa,
                p.codigo_producto,
                p.modelo,
                m.nombre_marca,
                p.precio_referencial,
                COALESCE(rf.nivel_compatibilidad, 0.00) AS compatibilidad_pct,
                rf.justificacion_tecnica,
                rf.indicacion_uso
            FROM public.recomendacion_final rf
            INNER JOIN public.producto_catalogo p ON rf.codigo_producto = p.codigo_producto
            INNER JOIN public.marca m ON p.id_marca = m.id_marca
            ORDER BY rf.nivel_compatibilidad DESC NULLS LAST, rf.id_recomendacion ASC;
        """,
    },
    6: {
        "title": "Carga de Trabajo y Desempeño de Asesores Técnicos",
        "description": "Cantidad de perfiles asignados por asesor y presupuesto promedio gestionado (JOIN con agrupaciones).",
        "sql": """
            SELECT
                a.id_asesor,
                CONCAT(a.nombres, ' ', a.apellidos) AS asesor_nombre,
                a.especialidad,
                a.turno,
                COUNT(pn.id_perfil) AS total_perfiles_atendidos,
                COALESCE(ROUND(AVG(pn.presupuesto_max), 2), 0.00) AS presupuesto_promedio_atendido,
                COALESCE(SUM(pn.presupuesto_max), 0.00) AS volumen_total_presupuestos
            FROM public.asesor_tecnico a
            LEFT JOIN public.perfil_de_necesidad pn ON a.id_asesor = pn.id_asesor
            GROUP BY a.id_asesor, a.nombres, a.apellidos, a.especialidad, a.turno
            ORDER BY total_perfiles_atendidos DESC, a.apellidos ASC;
        """,
    },
    7: {
        "title": "Comparativa Financiera: Presupuesto vs Precio Recomendado",
        "description": "Cálculo del ahorro o saldo a favor del cliente contra el precio del producto (5 tablas con JOINs).",
        "sql": """
            SELECT
                pn.id_perfil,
                CONCAT(c.nombres, ' ', c.apellidos) AS cliente,
                c.dni_cliente,
                pn.presupuesto_max AS presupuesto_maximo,
                prod.modelo AS producto_recomendado,
                prod.precio_referencial AS precio_producto,
                (pn.presupuesto_max - prod.precio_referencial) AS saldo_favorable_ahorro,
                CASE
                    WHEN prod.precio_referencial <= pn.presupuesto_max THEN 'DENTRO DE PRESUPUESTO'
                    ELSE 'SUPERA PRESUPUESTO'
                END AS estado_financiero,
                rf.nivel_compatibilidad
            FROM public.recomendacion_final rf
            INNER JOIN public.matriz_de_comparativa mc ON rf.id_comparativa = mc.id_comparativa
            INNER JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
            INNER JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
            INNER JOIN public.producto_catalogo prod ON rf.codigo_producto = prod.codigo_producto
            ORDER BY pn.id_perfil ASC;
        """,
    },
    8: {
        "title": "Distribución y Rango de Precios por Marca",
        "description": "Marcas con mayor variedad de productos en el catálogo y espectro de precios (JOIN con agregaciones).",
        "sql": """
            SELECT
                m.id_marca,
                m.nombre_marca,
                COUNT(p.codigo_producto) AS cantidad_modelos,
                MIN(p.precio_referencial) AS precio_mas_bajo,
                MAX(p.precio_referencial) AS precio_mas_alto,
                ROUND(AVG(p.precio_referencial), 2) AS precio_promedio
            FROM public.marca m
            INNER JOIN public.producto_catalogo p ON m.id_marca = p.id_marca
            GROUP BY m.id_marca, m.nombre_marca
            ORDER BY cantidad_modelos DESC, precio_promedio DESC;
        """,
    },
    9: {
        "title": "Top 15 Productos de Mayor Valor en Catálogo",
        "description": "Consulta analítica directa de los 15 productos de mayor valor comercial.",
        "sql": """
            SELECT
                codigo_producto,
                modelo,
                precio_referencial,
                especificaciones
            FROM public.producto_catalogo
            ORDER BY precio_referencial DESC
            LIMIT 15;
        """,
    },
    10: {
        "title": "Distribución Porcentual de Clientes por Canal de Contacto",
        "description": "Consulta analítica directa agrupando medios de comunicación con porcentaje sobre el total.",
        "sql": """
            SELECT
                COALESCE(canal_contacto, 'No especificado') AS canal_contacto,
                COUNT(*) AS cantidad_clientes,
                ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
            FROM public.cliente
            GROUP BY canal_contacto
            ORDER BY cantidad_clientes DESC;
        """,
    },
}

# -----------------------------------------------------------------------------
# SECCIÓN B: 10 CONSULTAS OPERATIVAS DE INIFORMACION.docx (FIGURAS 26-35)
# -----------------------------------------------------------------------------
DOC_QUERIES_META = {
    1: {
        "title": "Doc 1: Buscar productos según el presupuesto del cliente",
        "description": "Filtra el catálogo por presupuesto máximo del cliente (ej. S/ 500).",
        "params": ["presupuesto"],
    },
    2: {
        "title": "Doc 2: Buscar un producto según lo que necesita el cliente",
        "description": "Busca por palabra clave en modelo o categoría (ej. JBL / AUDIFONOS).",
        "params": ["texto", "categoria"],
    },
    3: {
        "title": "Doc 3: Buscar productos de una marca preferida",
        "description": "Lista los productos disponibles de una marca específica (ej. SAMSUNG).",
        "params": ["marca"],
    },
    4: {
        "title": "Doc 4: Comparar productos dentro de un mismo rango de precios",
        "description": "Compara productos de una categoría dentro de un rango mínimo y máximo.",
        "params": ["categoria", "min", "max"],
    },
    5: {
        "title": "Doc 5: Encontrar las tres alternativas más económicas",
        "description": "Devuelve las 3 opciones de menor precio en una categoría (ej. PARLANTES).",
        "params": ["categoria"],
    },
    6: {
        "title": "Doc 6: Consultar el perfil y las necesidades de un cliente",
        "description": "Muestra el historial de perfiles registrados para un DNI de cliente.",
        "params": ["dni"],
    },
    7: {
        "title": "Doc 7: Buscar productos adecuados para el cliente",
        "description": "Cruza el perfil del cliente (presupuesto y marca preferida) con el catálogo y calcula el dinero restante.",
        "params": ["dni", "categoria"],
    },
    8: {
        "title": "Doc 8: Comparar las alternativas evaluadas",
        "description": "Lista las alternativas evaluadas en la matriz comparativa de un cliente.",
        "params": ["dni"],
    },
    9: {
        "title": "Doc 9: Identificar el producto recomendado óptimo",
        "description": "Obtiene la recomendación final con mayor nivel de compatibilidad para un cliente.",
        "params": ["dni"],
    },
    10: {
        "title": "Doc 10: Generar el reporte final de asesoría",
        "description": "Consolida cliente, asesor, perfil, producto recomendado, compatibilidad, justificación e indicación de uso.",
        "params": ["dni"],
    },
}


def build_doc_query(query_id: int, query_params: dict):
    """Construye (sql, params_tuple, sql_preview) para las 10 consultas de INIFORMACION.docx."""
    def qget(name, default):
        return query_params.get(name, [default])[0].strip() or default

    if query_id == 1:
        presupuesto = float(qget("presupuesto", "500"))
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca AS marca,
                c.nombre_categoria AS categoria,
                p.precio_referencial AS precio
            FROM public.producto_catalogo p
            JOIN public.marca m ON p.id_marca = m.id_marca
            JOIN public.categoria c ON p.id_categoria = c.id_categoria
            WHERE p.precio_referencial <= %s
            ORDER BY p.precio_referencial DESC;
        """
        return sql, (presupuesto,)

    if query_id == 2:
        texto = qget("texto", "JBL")
        categoria = qget("categoria", "AUDIFONOS")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca AS marca,
                c.nombre_categoria AS categoria,
                p.precio_referencial
            FROM public.producto_catalogo p
            JOIN public.marca m ON p.id_marca = m.id_marca
            JOIN public.categoria c ON p.id_categoria = c.id_categoria
            WHERE p.modelo ILIKE %s
               OR c.nombre_categoria ILIKE %s
            ORDER BY p.precio_referencial ASC;
        """
        return sql, (f"%{texto}%", f"%{categoria}%")

    if query_id == 3:
        marca = qget("marca", "SAMSUNG")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca,
                p.especificaciones,
                p.precio_referencial
            FROM public.producto_catalogo p
            JOIN public.marca m ON p.id_marca = m.id_marca
            WHERE m.nombre_marca ILIKE %s
            ORDER BY p.precio_referencial ASC;
        """
        return sql, (f"%{marca}%",)

    if query_id == 4:
        categoria = qget("categoria", "AUDIFONOS")
        pmin = float(qget("min", "200"))
        pmax = float(qget("max", "400"))
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca,
                p.especificaciones,
                p.precio_referencial
            FROM public.producto_catalogo p
            JOIN public.marca m ON p.id_marca = m.id_marca
            JOIN public.categoria c ON p.id_categoria = c.id_categoria
            WHERE c.nombre_categoria ILIKE %s
              AND p.precio_referencial BETWEEN %s AND %s
            ORDER BY p.precio_referencial ASC;
        """
        return sql, (f"%{categoria}%", pmin, pmax)

    if query_id == 5:
        categoria = qget("categoria", "PARLANTES")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca,
                p.precio_referencial
            FROM public.producto_catalogo p
            JOIN public.marca m ON p.id_marca = m.id_marca
            JOIN public.categoria c ON p.id_categoria = c.id_categoria
            WHERE c.nombre_categoria ILIKE %s
            ORDER BY p.precio_referencial ASC
            LIMIT 3;
        """
        return sql, (f"%{categoria}%",)

    if query_id == 6:
        dni = qget("dni", "12345678")
        sql = """
            SELECT
                c.nombres,
                c.apellidos,
                pn.id_perfil,
                pn.uso_principal,
                pn.presupuesto_max,
                pn.restriccion_tecnica,
                pn.fecha_registro,
                a.nombres AS nombre_asesor
            FROM public.perfil_de_necesidad pn
            JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
            JOIN public.asesor_tecnico a ON pn.id_asesor = a.id_asesor
            WHERE c.dni_cliente = %s
            ORDER BY pn.fecha_registro DESC;
        """
        return sql, (dni,)

    if query_id == 7:
        dni = qget("dni", "12345678")
        categoria = qget("categoria", "AUDIFON")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo,
                m.nombre_marca AS marca,
                p.precio_referencial AS precio,
                pn.presupuesto_max AS presupuesto,
                (pn.presupuesto_max - p.precio_referencial) AS dinero_restante
            FROM public.perfil_de_necesidad pn
            JOIN public.producto_catalogo p
                ON p.precio_referencial <= pn.presupuesto_max
                AND (pn.id_marca IS NULL OR p.id_marca = pn.id_marca)
            JOIN public.marca m ON p.id_marca = m.id_marca
            JOIN public.categoria cat ON p.id_categoria = cat.id_categoria
            WHERE pn.dni_cliente = %s
              AND cat.nombre_categoria ILIKE %s
            ORDER BY p.precio_referencial DESC;
        """
        return sql, (dni, f"%{categoria}%")

    if query_id == 8:
        dni = qget("dni", "12345678")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo AS producto,
                m.nombre_marca AS marca,
                p.precio_referencial AS precio,
                mc.criterio_evaluacion,
                de.resultado_evaluacion
            FROM public.detalle_evaluacion de
            JOIN public.matriz_de_comparativa mc ON de.id_comparativa = mc.id_comparativa
            JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
            JOIN public.producto_catalogo p ON de.codigo_producto = p.codigo_producto
            JOIN public.marca m ON p.id_marca = m.id_marca
            WHERE pn.dni_cliente = %s
            ORDER BY p.precio_referencial DESC;
        """
        return sql, (dni,)

    if query_id == 9:
        dni = qget("dni", "12345678")
        sql = """
            SELECT
                p.codigo_producto,
                p.modelo AS producto_recomendado,
                m.nombre_marca AS marca,
                p.precio_referencial AS precio,
                r.nivel_compatibilidad,
                r.justificacion_tecnica,
                r.indicacion_uso
            FROM public.recomendacion_final r
            JOIN public.matriz_de_comparativa mc ON r.id_comparativa = mc.id_comparativa
            JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
            JOIN public.producto_catalogo p ON r.codigo_producto = p.codigo_producto
            JOIN public.marca m ON p.id_marca = m.id_marca
            WHERE pn.dni_cliente = %s
            ORDER BY r.nivel_compatibilidad DESC NULLS LAST,
                     p.precio_referencial DESC
            LIMIT 1;
        """
        return sql, (dni,)

    if query_id == 10:
        dni = qget("dni", "12345678")
        sql = """
            SELECT
                c.nombres || ' ' || c.apellidos AS cliente,
                c.dni_cliente,
                a.nombres || ' ' || a.apellidos AS asesor,
                pn.fecha_registro,
                pn.uso_principal,
                pn.presupuesto_max,
                pn.restriccion_tecnica,
                p.codigo_producto,
                p.modelo AS producto_recomendado,
                m.nombre_marca AS marca,
                p.precio_referencial AS precio,
                r.nivel_compatibilidad,
                r.justificacion_tecnica,
                r.indicacion_uso
            FROM public.recomendacion_final r
            JOIN public.matriz_de_comparativa mc ON r.id_comparativa = mc.id_comparativa
            JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
            JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
            JOIN public.asesor_tecnico a ON pn.id_asesor = a.id_asesor
            JOIN public.producto_catalogo p ON r.codigo_producto = p.codigo_producto
            JOIN public.marca m ON p.id_marca = m.id_marca
            WHERE c.dni_cliente = %s
            ORDER BY pn.fecha_registro DESC,
                     r.nivel_compatibilidad DESC NULLS LAST;
        """
        return sql, (dni,)

    raise ValueError(f"ID de consulta inválido ({query_id}). Rango válido: 1 al 10.")


# -----------------------------------------------------------------------------
# SERIALIZADOR JSON Y CONEXIÓN
# -----------------------------------------------------------------------------
def json_serial(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Tipo no serializable: {type(obj)}")


def get_db_connection():
    if not psycopg2:
        raise ConnectionError(
            "Librería psycopg2 no disponible. Instala con 'pip install psycopg2-binary'."
        )
    return psycopg2.connect(**DB_CONFIG)


def _to_int_or_none(val):
    if val is None or str(val).strip() == "":
        return None
    return int(val)


def _to_float_or_none(val):
    if val is None or str(val).strip() == "":
        return None
    return float(val)


# -----------------------------------------------------------------------------
# MANEJADOR HTTP NATIVO
# -----------------------------------------------------------------------------
class NativePostgresServer(BaseHTTPRequestHandler):

    def _set_cors_headers(self, status=200, content_type="application/json; charset=utf-8"):
        self.send_response(status)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
        self.send_header("Content-Type", content_type)
        self.end_headers()

    def do_OPTIONS(self):
        self._set_cors_headers(204)

    def _send_json(self, status, payload):
        self._set_cors_headers(status, "application/json; charset=utf-8")
        body = json.dumps(payload, default=json_serial, ensure_ascii=False).encode("utf-8")
        self.wfile.write(body)

    def _read_body_json(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length <= 0:
            return {}
        raw = self.rfile.read(content_length).decode("utf-8")
        return json.loads(raw)

    # -------------------------------------------------------------------------
    # RUTAS GET
    # -------------------------------------------------------------------------
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path in ("/", "/index.html"):
            return self._serve_index_html()

        if path == "/api/health":
            return self._handle_health()

        if path == "/api/test-db":
            return self._handle_test_db()

        if path == "/api/reports/list":
            reports_meta = [
                {"id": num, "title": rep["title"], "description": rep["description"]}
                for num, rep in REPORT_QUERIES.items()
            ]
            return self._send_json(200, {"reports": reports_meta})

        if path == "/api/reports":
            return self._handle_report(query)

        if path == "/api/consultas-doc/list":
            meta = [
                {
                    "id": num,
                    "title": item["title"],
                    "description": item["description"],
                    "params": item["params"],
                }
                for num, item in DOC_QUERIES_META.items()
            ]
            return self._send_json(200, {"consultas": meta})

        if path == "/api/consultas-doc":
            return self._handle_doc_query(query)

        if path == "/api/asesoria/candidatos":
            return self._handle_candidatos(query)

        # Listados de las 9 tablas
        data_routes = {
            "/api/data/categorias": (
                "categorias",
                "SELECT id_categoria, nombre_categoria FROM public.categoria ORDER BY id_categoria;",
            ),
            "/api/data/marcas": (
                "marcas",
                "SELECT id_marca, nombre_marca FROM public.marca ORDER BY id_marca;",
            ),
            "/api/data/asesores": (
                "asesores",
                "SELECT id_asesor, nombres, apellidos, especialidad, turno FROM public.asesor_tecnico ORDER BY id_asesor;",
            ),
            "/api/data/clientes": (
                "clientes",
                "SELECT * FROM public.cliente ORDER BY apellidos, nombres;",
            ),
            "/api/data/productos": (
                "productos",
                """
                SELECT p.*, m.nombre_marca, c.nombre_categoria
                FROM public.producto_catalogo p
                JOIN public.marca m ON p.id_marca = m.id_marca
                JOIN public.categoria c ON p.id_categoria = c.id_categoria
                ORDER BY p.codigo_producto;
                """,
            ),
            "/api/data/perfiles": (
                "perfiles",
                """
                SELECT
                    pn.*,
                    CONCAT(c.nombres, ' ', c.apellidos) AS cliente_nombre,
                    CONCAT(a.nombres, ' ', a.apellidos) AS asesor_nombre,
                    COALESCE(m.nombre_marca, 'Sin preferencia') AS marca_nombre
                FROM public.perfil_de_necesidad pn
                JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
                JOIN public.asesor_tecnico a ON pn.id_asesor = a.id_asesor
                LEFT JOIN public.marca m ON pn.id_marca = m.id_marca
                ORDER BY pn.id_perfil DESC;
                """,
            ),
            "/api/data/matrices": (
                "matrices",
                """
                SELECT
                    mc.*,
                    pn.dni_cliente,
                    pn.uso_principal,
                    pn.presupuesto_max,
                    CONCAT(c.nombres, ' ', c.apellidos) AS cliente_nombre
                FROM public.matriz_de_comparativa mc
                JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
                JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
                ORDER BY mc.id_comparativa DESC;
                """,
            ),
            "/api/data/detalles": (
                "detalles",
                """
                SELECT
                    de.*,
                    mc.criterio_evaluacion,
                    p.modelo,
                    p.precio_referencial,
                    m.nombre_marca
                FROM public.detalle_evaluacion de
                JOIN public.matriz_de_comparativa mc ON de.id_comparativa = mc.id_comparativa
                JOIN public.producto_catalogo p ON de.codigo_producto = p.codigo_producto
                JOIN public.marca m ON p.id_marca = m.id_marca
                ORDER BY de.id_comparativa DESC, p.precio_referencial ASC;
                """,
            ),
            "/api/data/recomendaciones": (
                "recomendaciones",
                """
                SELECT
                    rf.*,
                    mc.id_perfil,
                    pn.dni_cliente,
                    CONCAT(c.nombres, ' ', c.apellidos) AS cliente_nombre,
                    p.modelo,
                    p.precio_referencial,
                    m.nombre_marca
                FROM public.recomendacion_final rf
                JOIN public.matriz_de_comparativa mc ON rf.id_comparativa = mc.id_comparativa
                JOIN public.perfil_de_necesidad pn ON mc.id_perfil = pn.id_perfil
                JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
                JOIN public.producto_catalogo p ON rf.codigo_producto = p.codigo_producto
                JOIN public.marca m ON p.id_marca = m.id_marca
                ORDER BY rf.id_recomendacion DESC;
                """,
            ),
        }

        if path in data_routes:
            key, sql = data_routes[path]
            try:
                conn = get_db_connection()
                with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                    cur.execute(sql)
                    rows = cur.fetchall()
                conn.close()
                return self._send_json(200, {key: rows})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        self._send_json(404, {"error": f"Ruta no encontrada: {path}"})

    def _handle_health(self):
        db_status = "desconectado"
        db_connected = False
        error_msg = None
        summary = {}
        if psycopg2:
            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("SELECT version();")
                    ver = cur.fetchone()[0]
                    cur.execute(
                        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';"
                    )
                    tables_count = cur.fetchone()[0]
                    cur.execute(
                        "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid WHERE n.nspname='public' AND p.prokind='p';"
                    )
                    procs_count = cur.fetchone()[0]
                    cur.execute(
                        "SELECT COUNT(*) FROM pg_trigger WHERE NOT tgisinternal;"
                    )
                    trgs_count = cur.fetchone()[0]
                conn.close()
                db_connected = True
                db_status = f"conectado: {ver}"
                summary = {
                    "tablas": tables_count,
                    "procedimientos": procs_count,
                    "triggers": trgs_count,
                }
            except Exception as ex:
                error_msg = str(ex)
        else:
            error_msg = "psycopg2 no instalado en Python"

        return self._send_json(
            200,
            {
                "server": "Python Native http.server",
                "framework": "NINGUNO (Estrictamente nativo)",
                "db_connected": db_connected,
                "postgres_status": db_status,
                "summary": summary,
                "error": error_msg,
                "config": {
                    "host": DB_CONFIG["host"],
                    "port": DB_CONFIG["port"],
                    "database": DB_CONFIG["dbname"],
                    "user": DB_CONFIG["user"],
                },
            },
        )

    def _handle_test_db(self):
        try:
            conn = get_db_connection()
            counts = {}
            with conn.cursor() as cur:
                cur.execute("SELECT version(), current_database(), current_user;")
                version, current_db, current_user = cur.fetchone()
                cur.execute(
                    "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"
                )
                present_tables = [r[0] for r in cur.fetchall()]
                missing_tables = [t for t in EXPECTED_TABLES if t not in present_tables]

                for tbl in present_tables:
                    if tbl in EXPECTED_TABLES:
                        cur.execute(f"SELECT COUNT(*) FROM public.{tbl};")
                        counts[tbl] = cur.fetchone()[0]

                cur.execute(
                    """
                    SELECT proname FROM pg_proc p
                    JOIN pg_namespace n ON p.pronamespace = n.oid
                    WHERE n.nspname = 'public' AND p.prokind = 'p'
                    ORDER BY proname;
                    """
                )
                procedures = [r[0] for r in cur.fetchall()]

                cur.execute(
                    """
                    SELECT tgname, tgrelid::regclass::text
                    FROM pg_trigger
                    WHERE NOT tgisinternal
                    ORDER BY tgname;
                    """
                )
                triggers = [{"trigger": r[0], "tabla": r[1]} for r in cur.fetchall()]
            conn.close()

            return self._send_json(
                200,
                {
                    "success": len(missing_tables) == 0,
                    "database": current_db,
                    "user": current_user,
                    "version": version,
                    "tables_expected": len(EXPECTED_TABLES),
                    "tables_present": len(present_tables),
                    "missing_tables": missing_tables,
                    "row_counts": counts,
                    "procedures_count": len(procedures),
                    "procedures": procedures,
                    "triggers_count": len(triggers),
                    "triggers": triggers,
                },
            )
        except Exception as e:
            return self._send_json(500, {"success": False, "error": str(e)})

    def _handle_report(self, query):
        try:
            report_id = int(query.get("id", ["1"])[0])
        except ValueError:
            return self._send_json(400, {"success": False, "error": "El parámetro 'id' debe ser numérico."})

        if report_id not in REPORT_QUERIES:
            return self._send_json(
                400, {"success": False, "error": f"ID de reporte inválido ({report_id}). Rango: 1 al 10."}
            )

        rep = REPORT_QUERIES[report_id]
        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                cur.execute(rep["sql"])
                rows = cur.fetchall()
                columns = [desc[0] for desc in cur.description] if cur.description else []
            conn.close()
            return self._send_json(
                200,
                {
                    "success": True,
                    "report_id": report_id,
                    "title": rep["title"],
                    "description": rep["description"],
                    "sql_used": rep["sql"].strip(),
                    "total_rows": len(rows),
                    "columns": columns,
                    "rows": rows,
                },
            )
        except Exception as e:
            return self._send_json(
                500, {"success": False, "report_id": report_id, "error": f"Error ejecutando reporte: {str(e)}"}
            )

    def _handle_doc_query(self, query):
        try:
            qid = int(query.get("id", ["1"])[0])
            sql, params = build_doc_query(qid, query)
        except Exception as e:
            return self._send_json(400, {"success": False, "error": str(e)})

        meta = DOC_QUERIES_META[qid]
        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()
                columns = [desc[0] for desc in cur.description] if cur.description else []
            conn.close()
            return self._send_json(
                200,
                {
                    "success": True,
                    "query_id": qid,
                    "title": meta["title"],
                    "description": meta["description"],
                    "params_used": list(params),
                    "sql_used": sql.strip(),
                    "total_rows": len(rows),
                    "columns": columns,
                    "rows": rows,
                },
            )
        except Exception as e:
            return self._send_json(500, {"success": False, "error": f"Error ejecutando consulta: {str(e)}"})

    def _handle_candidatos(self, query):
        """Algoritmo de mapeo: sugiere productos del catálogo según un perfil de necesidad."""
        try:
            id_perfil = int(query.get("id_perfil", ["0"])[0])
            categoria = query.get("categoria", [""])[0].strip()
        except ValueError:
            return self._send_json(400, {"success": False, "error": "Parámetro id_perfil inválido."})

        if id_perfil <= 0:
            return self._send_json(400, {"success": False, "error": "Se requiere id_perfil válido."})

        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                cur.execute(
                    """
                    SELECT pn.*, CONCAT(c.nombres, ' ', c.apellidos) AS cliente_nombre,
                           COALESCE(m.nombre_marca, 'Sin preferencia') AS marca_preferida
                    FROM public.perfil_de_necesidad pn
                    JOIN public.cliente c ON pn.dni_cliente = c.dni_cliente
                    LEFT JOIN public.marca m ON pn.id_marca = m.id_marca
                    WHERE pn.id_perfil = %s;
                    """,
                    (id_perfil,),
                )
                perfil = cur.fetchone()
                if not perfil:
                    conn.close()
                    return self._send_json(404, {"success": False, "error": f"Perfil {id_perfil} no encontrado."})

                sql = """
                    SELECT
                        p.codigo_producto,
                        p.modelo,
                        m.nombre_marca AS marca,
                        cat.nombre_categoria AS categoria,
                        p.precio_referencial AS precio,
                        p.especificaciones,
                        (%s - p.precio_referencial) AS ahorro_estimado,
                        ROUND(
                            LEAST(
                                100.0,
                                60.0
                                + CASE WHEN %s IS NOT NULL AND p.id_marca = %s THEN 25.0 ELSE 10.0 END
                                + CASE WHEN p.precio_referencial <= %s THEN 15.0 * (p.precio_referencial / NULLIF(%s, 0)) ELSE 0.0 END
                            ),
                            2
                        ) AS compatibilidad_sugerida
                    FROM public.producto_catalogo p
                    JOIN public.marca m ON p.id_marca = m.id_marca
                    JOIN public.categoria cat ON p.id_categoria = cat.id_categoria
                    WHERE p.precio_referencial <= %s
                      AND (%s IS NULL OR p.id_marca = %s)
                      AND (%s = '' OR cat.nombre_categoria ILIKE %s OR p.modelo ILIKE %s)
                    ORDER BY compatibilidad_sugerida DESC, p.precio_referencial DESC
                    LIMIT 25;
                """
                pres = perfil["presupuesto_max"]
                id_marca = perfil["id_marca"]
                like_cat = f"%{categoria}%" if categoria else ""
                cur.execute(
                    sql,
                    (pres, id_marca, id_marca, pres, pres, pres, id_marca, id_marca, categoria, like_cat, like_cat),
                )
                candidatos = cur.fetchall()
            conn.close()
            return self._send_json(
                200,
                {
                    "success": True,
                    "perfil": perfil,
                    "total_candidatos": len(candidatos),
                    "candidatos": candidatos,
                },
            )
        except Exception as e:
            return self._send_json(500, {"success": False, "error": str(e)})

    # -------------------------------------------------------------------------
    # RUTAS POST (Inserción mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        try:
            body = self._read_body_json()
        except Exception:
            return self._send_json(400, {"success": False, "error": "Cuerpo de solicitud JSON inválido."})

        try:
            if path == "/api/sp/insert_cliente":
                dni = str(body.get("dni", "")).strip()
                nombres = str(body.get("nombres", "")).strip()
                apellidos = str(body.get("apellidos", "")).strip()
                canal = str(body.get("canal_contacto", "Web")).strip()
                telefono = str(body.get("telefono", "")).strip()
                correo = str(body.get("correo", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_cliente(%s, %s, %s, %s, %s, %s);",
                        (dni, nombres, apellidos, canal, telefono, correo),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Cliente con DNI {dni} insertado exitosamente.", "dni": dni},
                )

            if path == "/api/sp/insert_producto":
                codigo = str(body.get("codigo", "")).strip()
                modelo = str(body.get("modelo", "")).strip()
                especificaciones = str(body.get("especificaciones", "")).strip()
                precio = _to_float_or_none(body.get("precio"))
                id_marca = _to_int_or_none(body.get("id_marca"))
                id_categoria = _to_int_or_none(body.get("id_categoria"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_producto(%s, %s, %s, %s, %s, %s);",
                        (codigo, modelo, especificaciones, precio, id_marca, id_categoria),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Producto {codigo} insertado correctamente.", "codigo": codigo},
                )

            if path == "/api/sp/insert_perfil":
                uso = str(body.get("uso_principal", "")).strip()
                presupuesto = _to_float_or_none(body.get("presupuesto_max"))
                restriccion = str(body.get("restriccion_tecnica", "")).strip()
                dni = str(body.get("dni_cliente", "")).strip()
                id_asesor = _to_int_or_none(body.get("id_asesor")) or 1
                id_marca = _to_int_or_none(body.get("id_marca"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_perfil_necesidad(%s, %s, %s, %s, %s, %s, NULL);",
                        (uso, presupuesto, restriccion, dni, id_asesor, id_marca),
                    )
                    row = cur.fetchone()
                    new_id = row[0] if row else None
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {
                        "success": True,
                        "message": f"Perfil de necesidad creado exitosamente (ID {new_id}).",
                        "id_perfil": new_id,
                    },
                )

            if path == "/api/sp/insert_categoria":
                nombre = str(body.get("nombre_categoria", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_insertar_categoria(%s, NULL);", (nombre,))
                    new_id = cur.fetchone()[0]
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Categoría creada (ID {new_id}).", "id_categoria": new_id},
                )

            if path == "/api/sp/insert_marca":
                nombre = str(body.get("nombre_marca", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_insertar_marca(%s, NULL);", (nombre,))
                    new_id = cur.fetchone()[0]
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Marca creada (ID {new_id}).", "id_marca": new_id},
                )

            if path == "/api/sp/insert_asesor":
                nombres = str(body.get("nombres", "")).strip()
                apellidos = str(body.get("apellidos", "")).strip()
                especialidad = str(body.get("especialidad", "")).strip()
                turno = str(body.get("turno", "MANANA")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_asesor(%s, %s, %s, %s, NULL);",
                        (nombres, apellidos, especialidad, turno),
                    )
                    new_id = cur.fetchone()[0]
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Asesor técnico creado (ID {new_id}).", "id_asesor": new_id},
                )

            if path == "/api/sp/insert_matriz":
                criterio = str(body.get("criterio_evaluacion", "")).strip()
                diferencial = str(body.get("diferencial_tecnico", "")).strip()
                id_perfil = _to_int_or_none(body.get("id_perfil"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_matriz(%s, %s, %s, NULL);",
                        (criterio, diferencial, id_perfil),
                    )
                    new_id = cur.fetchone()[0]
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Matriz comparativa creada (ID {new_id}).", "id_comparativa": new_id},
                )

            if path == "/api/sp/insert_detalle":
                id_comp = _to_int_or_none(body.get("id_comparativa"))
                codigo = str(body.get("codigo_producto", "")).strip()
                resultado = str(body.get("resultado_evaluacion", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_detalle_evaluacion(%s, %s, %s);",
                        (id_comp, codigo, resultado),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {"success": True, "message": f"Detalle registrado para matriz {id_comp} y producto {codigo}."},
                )

            if path == "/api/sp/insert_recomendacion":
                justificacion = str(body.get("justificacion_tecnica", "")).strip()
                indicacion = str(body.get("indicacion_uso", "")).strip()
                compatibilidad = _to_float_or_none(body.get("nivel_compatibilidad"))
                id_comp = _to_int_or_none(body.get("id_comparativa"))
                codigo = str(body.get("codigo_producto", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_recomendacion(%s, %s, %s, %s, %s, NULL);",
                        (justificacion, indicacion, compatibilidad, id_comp, codigo),
                    )
                    new_id = cur.fetchone()[0]
                conn.commit()
                conn.close()
                return self._send_json(
                    201,
                    {
                        "success": True,
                        "message": f"Recomendación final creada (ID {new_id}).",
                        "id_recomendacion": new_id,
                    },
                )

            return self._send_json(404, {"success": False, "error": f"Ruta POST no encontrada: {path}"})
        except Exception as e:
            return self._send_json(400, {"success": False, "error": str(e)})

    # -------------------------------------------------------------------------
    # RUTAS PUT (Modificación mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_PUT(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        try:
            body = self._read_body_json()
        except Exception:
            return self._send_json(400, {"success": False, "error": "Cuerpo de solicitud JSON inválido."})

        try:
            if path == "/api/sp/update_cliente":
                dni = str(body.get("dni", "")).strip()
                nombres = str(body.get("nombres", "")).strip()
                apellidos = str(body.get("apellidos", "")).strip()
                canal = str(body.get("canal_contacto", "")).strip()
                telefono = str(body.get("telefono", "")).strip()
                correo = str(body.get("correo", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_cliente(%s, %s, %s, %s, %s, %s);",
                        (dni, nombres, apellidos, canal, telefono, correo),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Cliente con DNI {dni} actualizado exitosamente."}
                )

            if path == "/api/sp/update_producto":
                codigo = str(body.get("codigo", "")).strip()
                modelo = str(body.get("modelo", "")).strip()
                especificaciones = str(body.get("especificaciones", "")).strip()
                precio = _to_float_or_none(body.get("precio"))
                id_marca = _to_int_or_none(body.get("id_marca"))
                id_categoria = _to_int_or_none(body.get("id_categoria"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_producto(%s, %s, %s, %s, %s, %s);",
                        (codigo, modelo, especificaciones, precio, id_marca, id_categoria),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Producto {codigo} modificado correctamente."}
                )

            if path == "/api/sp/update_perfil":
                id_perfil = _to_int_or_none(body.get("id_perfil"))
                uso = str(body.get("uso_principal", "")).strip()
                presupuesto = _to_float_or_none(body.get("presupuesto_max"))
                restriccion = str(body.get("restriccion_tecnica", "")).strip()
                id_marca = _to_int_or_none(body.get("id_marca"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_perfil_necesidad(%s, %s, %s, %s, %s);",
                        (id_perfil, uso, presupuesto, restriccion, id_marca),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Perfil ID {id_perfil} modificado correctamente."}
                )

            if path == "/api/sp/update_categoria":
                id_cat = _to_int_or_none(body.get("id_categoria"))
                nombre = str(body.get("nombre_categoria", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_modificar_categoria(%s, %s);", (id_cat, nombre))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Categoría ID {id_cat} modificada correctamente."}
                )

            if path == "/api/sp/update_marca":
                id_marca = _to_int_or_none(body.get("id_marca"))
                nombre = str(body.get("nombre_marca", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_modificar_marca(%s, %s);", (id_marca, nombre))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Marca ID {id_marca} modificada correctamente."}
                )

            if path == "/api/sp/update_asesor":
                id_asesor = _to_int_or_none(body.get("id_asesor"))
                nombres = str(body.get("nombres", "")).strip()
                apellidos = str(body.get("apellidos", "")).strip()
                especialidad = str(body.get("especialidad", "")).strip()
                turno = str(body.get("turno", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_asesor(%s, %s, %s, %s, %s);",
                        (id_asesor, nombres, apellidos, especialidad, turno),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Asesor ID {id_asesor} modificado correctamente."}
                )

            if path == "/api/sp/update_matriz":
                id_comp = _to_int_or_none(body.get("id_comparativa"))
                criterio = str(body.get("criterio_evaluacion", "")).strip()
                diferencial = str(body.get("diferencial_tecnico", "")).strip()
                id_perfil = _to_int_or_none(body.get("id_perfil"))
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_matriz(%s, %s, %s, %s);",
                        (id_comp, criterio, diferencial, id_perfil),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Matriz ID {id_comp} modificada correctamente."}
                )

            if path == "/api/sp/update_detalle":
                id_comp = _to_int_or_none(body.get("id_comparativa"))
                codigo = str(body.get("codigo_producto", "")).strip()
                resultado = str(body.get("resultado_evaluacion", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_detalle_evaluacion(%s, %s, %s);",
                        (id_comp, codigo, resultado),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Detalle actualizado ({id_comp}, {codigo})."}
                )

            if path == "/api/sp/update_recomendacion":
                id_rec = _to_int_or_none(body.get("id_recomendacion"))
                justificacion = str(body.get("justificacion_tecnica", "")).strip()
                indicacion = str(body.get("indicacion_uso", "")).strip()
                compatibilidad = _to_float_or_none(body.get("nivel_compatibilidad"))
                id_comp = _to_int_or_none(body.get("id_comparativa"))
                codigo = str(body.get("codigo_producto", "")).strip()
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_recomendacion(%s, %s, %s, %s, %s, %s);",
                        (id_rec, justificacion, indicacion, compatibilidad, id_comp, codigo),
                    )
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Recomendación ID {id_rec} modificada correctamente."}
                )

            return self._send_json(404, {"success": False, "error": f"Ruta PUT no encontrada: {path}"})
        except Exception as e:
            return self._send_json(400, {"success": False, "error": str(e)})

    # -------------------------------------------------------------------------
    # RUTAS DELETE (Borrado mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        try:
            if path == "/api/sp/delete_cliente":
                dni = query.get("dni", [""])[0].strip()
                if not dni:
                    return self._send_json(400, {"success": False, "error": "Se requiere el parámetro 'dni'."})
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_eliminar_cliente(%s);", (dni,))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Cliente con DNI {dni} eliminado correctamente."}
                )

            if path == "/api/sp/delete_producto":
                codigo = query.get("codigo", [""])[0].strip()
                if not codigo:
                    return self._send_json(400, {"success": False, "error": "Se requiere el parámetro 'codigo'."})
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_eliminar_producto(%s);", (codigo,))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Producto {codigo} eliminado correctamente."}
                )

            simple_id_deletes = {
                "/api/sp/delete_perfil": ("sp_eliminar_perfil_necesidad", "Perfil de necesidad"),
                "/api/sp/delete_categoria": ("sp_eliminar_categoria", "Categoría"),
                "/api/sp/delete_marca": ("sp_eliminar_marca", "Marca"),
                "/api/sp/delete_asesor": ("sp_eliminar_asesor", "Asesor técnico"),
                "/api/sp/delete_matriz": ("sp_eliminar_matriz", "Matriz comparativa"),
                "/api/sp/delete_recomendacion": ("sp_eliminar_recomendacion", "Recomendación final"),
            }

            if path in simple_id_deletes:
                sp_name, label = simple_id_deletes[path]
                raw_id = query.get("id", [""])[0].strip()
                if not raw_id:
                    return self._send_json(400, {"success": False, "error": "Se requiere el parámetro 'id'."})
                id_val = int(raw_id)
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(f"CALL public.{sp_name}(%s);", (id_val,))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"{label} ID {id_val} eliminado correctamente."}
                )

            if path == "/api/sp/delete_detalle":
                id_comp = _to_int_or_none(query.get("id_comparativa", [""])[0])
                codigo = query.get("codigo_producto", [""])[0].strip()
                if not id_comp or not codigo:
                    return self._send_json(
                        400,
                        {"success": False, "error": "Se requieren 'id_comparativa' y 'codigo_producto'."},
                    )
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_eliminar_detalle_evaluacion(%s, %s);", (id_comp, codigo))
                conn.commit()
                conn.close()
                return self._send_json(
                    200, {"success": True, "message": f"Detalle ({id_comp}, {codigo}) eliminado correctamente."}
                )

            return self._send_json(404, {"success": False, "error": f"Ruta DELETE no encontrada: {path}"})
        except Exception as e:
            return self._send_json(400, {"success": False, "error": str(e)})

    # -------------------------------------------------------------------------
    # SERVIR INDEX.HTML ESTÁTICO
    # -------------------------------------------------------------------------
    def _serve_index_html(self):
        candidate_paths = [
            os.path.join(os.path.dirname(__file__), "index.html"),
            os.path.join(os.path.dirname(__file__), "..", "public", "index_standalone.html"),
            "index.html",
        ]
        html_file = next((p for p in candidate_paths if os.path.exists(p)), None)
        if html_file:
            with open(html_file, "rb") as f:
                content = f.read()
            self._set_cors_headers(200, "text/html; charset=utf-8")
            self.wfile.write(content)
        else:
            self._send_json(200, {"mensaje": "Servidor nativo Python Glowtech en ejecución."})


def run(server_class=ThreadingHTTPServer, handler_class=NativePostgresServer, port=SERVER_PORT):
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    print("=" * 72)
    print(f" Glowtech - Servidor Nativo Python (http.server + psycopg2) : Puerto {port}")
    print(" CERO FRAMEWORKS | CRUD 9 Tablas | 27 SPs | 5 Triggers | 20 Consultas")
    print("=" * 72)
    print(f" URL local : http://localhost:{port}")
    print(f" PostgreSQL: Host={DB_CONFIG['host']}:{DB_CONFIG['port']} DB={DB_CONFIG['dbname']} User={DB_CONFIG['user']}")
    print(" Presiona Ctrl+C para detener el servidor.")
    print("=" * 72)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nDeteniendo servidor...")
        httpd.server_close()
        print("Servidor detenido exitosamente.")


if __name__ == "__main__":
    run()

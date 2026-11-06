#!/usr/bin/env python3
"""
===============================================================================
BACKEND NATIVO PYTHON - SERVIDOR HTTP Y CONEXIÓN POSTGRESQL (PSYCOPG2)
===============================================================================
Requisitos estrictos cumplidos:
- Cero frameworks externos de servidor (SIN Flask, SIN Express, SIN FastAPI, SIN Django).
- Usa exclusivamente la librería estándar 'http.server' de Python.
- Usa 'psycopg2' para interactuar con PostgreSQL, ejecutar Stored Procedures
  en PL/pgSQL y las 10 consultas de reportes.
- Incluye soporte completo de CORS para llamadas fetch desde JavaScript nativo.
===============================================================================
"""

import os
import sys
import json
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from decimal import Decimal
from datetime import date, datetime

try:
    import psycopg2
    from psycopg2 import extras
except ImportError:
    print("[ADVERTENCIA] psycopg2 no está instalado en este entorno de Python.")
    print("Para conectarse a PostgreSQL real, instálalo con: pip install psycopg2-binary")
    psycopg2 = None

# -----------------------------------------------------------------------------
# CONFIGURACIÓN DE CONEXIÓN A POSTGRESQL (Vía variables de entorno o defaults)
# -----------------------------------------------------------------------------
DB_CONFIG = {
    "host": os.environ.get("PGHOST", "localhost"),
    "port": int(os.environ.get("PGPORT", "5432")),
    "dbname": os.environ.get("PGDATABASE", "postgres"),
    "user": os.environ.get("PGUSER", "postgres"),
    "password": os.environ.get("PGPASSWORD", "postgres"),
}

SERVER_PORT = int(os.environ.get("PORT", "8000"))

# -----------------------------------------------------------------------------
# DEFINICIÓN DE LAS 10 CONSULTAS DE REPORTES
# -----------------------------------------------------------------------------
REPORT_QUERIES = {
    1: {
        "title": "Catálogo Completo con Marca y Categoría",
        "description": "Lista de todos los productos vinculando su marca y categoría (3 tablas con JOINs).",
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
        """
    },
    2: {
        "title": "Resumen Estadístico de Precios por Categoría",
        "description": "Total de productos, precio promedio, mínimo y máximo por categoría (JOIN con agregaciones).",
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
        """
    },
    3: {
        "title": "Perfiles de Necesidad con Clientes y Asesores Asignados",
        "description": "Ficha completa de requerimientos del cliente con asesor y marca preferida (4 tablas con JOINs).",
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
                CONCAT(ast.nombres, ' ', ast.apellidos) AS asesor_tecnico,
                ast.turno AS turno_asesor,
                COALESCE(m.nombre_marca, 'Sin preferencia') AS marca_preferida
            FROM public.perfil_de_necesidad pn
            INNER JOIN public.cliente cl ON pn.dni_cliente = cl.dni_cliente
            INNER JOIN public.asesor_tecnico ast ON pn.id_asesor = ast.id_asesor
            LEFT JOIN public.marca m ON pn.id_marca = m.id_marca
            ORDER BY pn.fecha_registro DESC;
        """
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
        """
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
            ORDER BY rf.nivel_compatibilidad DESC NULLS LAST;
        """
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
            ORDER BY total_perfiles_atendidos DESC;
        """
    },
    7: {
        "title": "Comparativa Financiera: Presupuesto vs Precio Recomendado",
        "description": "Cálculo del ahorro o saldo a favor del cliente contra la cotización del producto (5 tablas con JOINs).",
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
        """
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
        """
    },
    9: {
        "title": "Top 15 Productos de Mayor Valor en Catálogo",
        "description": "Consulta analítica directa de los productos más exclusivos y de mayor valor comercial.",
        "sql": """
            SELECT 
                codigo_producto,
                modelo,
                precio_referencial,
                especificaciones
            FROM public.producto_catalogo
            ORDER BY precio_referencial DESC
            LIMIT 15;
        """
    },
    10: {
        "title": "Distribución Porcentual de Clientes por Canal de Contacto",
        "description": "Consulta analítica directa agrupando medios de comunicación preferidos con porcentajes calculados.",
        "sql": """
            SELECT 
                COALESCE(canal_contacto, 'No especificado') AS canal_contacto,
                COUNT(*) AS cantidad_clientes,
                ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
            FROM public.cliente
            GROUP BY canal_contacto
            ORDER BY cantidad_clientes DESC;
        """
    }
}

# -----------------------------------------------------------------------------
# SERIALIZADOR JSON PERSONALIZADO (Manejo de Decimal, Date, Timestamp)
# -----------------------------------------------------------------------------
def json_serial(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Tipo no serializable: {type(obj)}")


def get_db_connection():
    if not psycopg2:
        raise ConnectionError("Librería psycopg2 no disponible. Instala con 'pip install psycopg2-binary'.")
    return psycopg2.connect(**DB_CONFIG)


# -----------------------------------------------------------------------------
# MANEJADOR HTTP NATIVO (http.server.BaseHTTPRequestHandler)
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
        """Manejo de peticiones pre-flight CORS."""
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
    # RUTAS GET (Reportes, Listados, Verificación)
    # -------------------------------------------------------------------------
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # Ruta raíz o index.html: Sirve el archivo estático index.html si existe
        if path in ("/", "/index.html"):
            return self._serve_index_html()

        # Endpoint de salud y diagnóstico
        if path == "/api/health":
            db_status = "desconectado"
            error_msg = None
            if psycopg2:
                try:
                    conn = get_db_connection()
                    with conn.cursor() as cur:
                        cur.execute("SELECT version();")
                        ver = cur.fetchone()[0]
                    conn.close()
                    db_status = f"conectado: {ver}"
                except Exception as ex:
                    error_msg = str(ex)
            else:
                error_msg = "psycopg2 no instalado en Python"
            
            return self._send_json(200, {
                "server": "Python Native http.server",
                "framework": "NINGUNO (Estrictamente nativo)",
                "postgres_status": db_status,
                "error": error_msg,
                "config": {
                    "host": DB_CONFIG["host"],
                    "port": DB_CONFIG["port"],
                    "database": DB_CONFIG["dbname"],
                    "user": DB_CONFIG["user"]
                }
            })

        # Listado de metadatos de los 10 reportes
        if path == "/api/reports/list":
            reports_meta = []
            for num, rep in REPORT_QUERIES.items():
                reports_meta.append({
                    "id": num,
                    "title": rep["title"],
                    "description": rep["description"]
                })
            return self._send_json(200, {"reports": reports_meta})

        # Ejecución de un Reporte por ID (1 al 10)
        if path == "/api/reports":
            report_id = int(query.get("id", ["1"])[0])
            if report_id not in REPORT_QUERIES:
                return self._send_json(400, {"error": f"ID de reporte inválido ({report_id}). Rango: 1 al 10."})

            rep = REPORT_QUERIES[report_id]
            try:
                conn = get_db_connection()
                with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                    cur.execute(rep["sql"])
                    rows = cur.fetchall()
                    columns = [desc[0] for desc in cur.description] if cur.description else []
                conn.close()

                return self._send_json(200, {
                    "success": True,
                    "report_id": report_id,
                    "title": rep["title"],
                    "description": rep["description"],
                    "sql_used": rep["sql"].strip(),
                    "total_rows": len(rows),
                    "columns": columns,
                    "rows": rows
                })
            except Exception as e:
                return self._send_json(500, {
                    "success": False,
                    "report_id": report_id,
                    "error": f"Error ejecutando consulta de reporte: {str(e)}"
                })

        # Datos auxiliares: Clientes
        if path == "/api/data/clientes":
            try:
                conn = get_db_connection()
                with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                    cur.execute("SELECT * FROM public.cliente ORDER BY apellidos, nombres;")
                    rows = cur.fetchall()
                conn.close()
                return self._send_json(200, {"clientes": rows})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # Datos auxiliares: Productos
        if path == "/api/data/productos":
            try:
                conn = get_db_connection()
                with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                    cur.execute("""
                        SELECT p.*, m.nombre_marca, c.nombre_categoria 
                        FROM public.producto_catalogo p
                        JOIN public.marca m ON p.id_marca = m.id_marca
                        JOIN public.categoria c ON p.id_categoria = c.id_categoria
                        ORDER BY p.codigo_producto;
                    """)
                    rows = cur.fetchall()
                conn.close()
                return self._send_json(200, {"productos": rows})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        self._send_json(404, {"error": f"Ruta no encontrada: {path}"})

    # -------------------------------------------------------------------------
    # RUTAS POST (Inserción mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        try:
            body = self._read_body_json()
        except Exception:
            return self._send_json(400, {"error": "Cuerpo de solicitud JSON inválido."})

        # SP: Inserción de Cliente (sp_insertar_cliente)
        if path == "/api/sp/insert_cliente":
            dni = body.get("dni", "").strip()
            nombres = body.get("nombres", "").strip()
            apellidos = body.get("apellidos", "").strip()
            canal = body.get("canal_contacto", "Web").strip()
            telefono = body.get("telefono", "").strip()
            correo = body.get("correo", "").strip()

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    # En PostgreSQL se ejecuta CALL sp_insertar_cliente(...)
                    cur.execute(
                        "CALL public.sp_insertar_cliente(%s, %s, %s, %s, %s, %s);",
                        (dni, nombres, apellidos, canal, telefono, correo)
                    )
                conn.commit()
                conn.close()
                return self._send_json(201, {
                    "success": True,
                    "message": f"Cliente con DNI {dni} insertado exitosamente mediante Stored Procedure.",
                    "dni": dni
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        # SP: Inserción de Producto (sp_insertar_producto)
        if path == "/api/sp/insert_producto":
            codigo = body.get("codigo", "").strip()
            modelo = body.get("modelo", "").strip()
            especificaciones = body.get("especificaciones", "").strip()
            precio = body.get("precio", 0.0)
            id_marca = body.get("id_marca")
            id_categoria = body.get("id_categoria")

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_producto(%s, %s, %s, %s, %s, %s);",
                        (codigo, modelo, especificaciones, precio, id_marca, id_categoria)
                    )
                conn.commit()
                conn.close()
                return self._send_json(201, {
                    "success": True,
                    "message": f"Producto {codigo} insertado correctamente mediante Stored Procedure.",
                    "codigo": codigo
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        # SP: Inserción de Perfil de Necesidad (sp_insertar_perfil_necesidad)
        if path == "/api/sp/insert_perfil":
            uso = body.get("uso_principal", "")
            presupuesto = body.get("presupuesto_max", 0.0)
            restriccion = body.get("restriccion_tecnica", "")
            dni = body.get("dni_cliente", "").strip()
            id_asesor = body.get("id_asesor", 1)
            id_marca = body.get("id_marca")

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_insertar_perfil_necesidad(%s, %s, %s, %s, %s, %s, NULL);",
                        (uso, presupuesto, restriccion, dni, id_asesor, id_marca)
                    )
                conn.commit()
                conn.close()
                return self._send_json(201, {
                    "success": True,
                    "message": "Perfil de necesidad registrado exitosamente mediante Stored Procedure."
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        self._send_json(404, {"error": f"Ruta POST no encontrada: {path}"})

    # -------------------------------------------------------------------------
    # RUTAS PUT (Modificación mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_PUT(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        try:
            body = self._read_body_json()
        except Exception:
            return self._send_json(400, {"error": "Cuerpo de solicitud JSON inválido."})

        # SP: Modificación de Cliente (sp_modificar_cliente)
        if path == "/api/sp/update_cliente":
            dni = body.get("dni", "").strip()
            nombres = body.get("nombres", "").strip()
            apellidos = body.get("apellidos", "").strip()
            canal = body.get("canal_contacto", "").strip()
            telefono = body.get("telefono", "").strip()
            correo = body.get("correo", "").strip()

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_cliente(%s, %s, %s, %s, %s, %s);",
                        (dni, nombres, apellidos, canal, telefono, correo)
                    )
                conn.commit()
                conn.close()
                return self._send_json(200, {
                    "success": True,
                    "message": f"Cliente con DNI {dni} actualizado exitosamente mediante Stored Procedure."
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        # SP: Modificación de Producto (sp_modificar_producto)
        if path == "/api/sp/update_producto":
            codigo = body.get("codigo", "").strip()
            modelo = body.get("modelo", "").strip()
            especificaciones = body.get("especificaciones", "").strip()
            precio = body.get("precio", 0.0)
            id_marca = body.get("id_marca")
            id_categoria = body.get("id_categoria")

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute(
                        "CALL public.sp_modificar_producto(%s, %s, %s, %s, %s, %s);",
                        (codigo, modelo, especificaciones, precio, id_marca, id_categoria)
                    )
                conn.commit()
                conn.close()
                return self._send_json(200, {
                    "success": True,
                    "message": f"Producto {codigo} modificado correctamente mediante Stored Procedure."
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        self._send_json(404, {"error": f"Ruta PUT no encontrada: {path}"})

    # -------------------------------------------------------------------------
    # RUTAS DELETE (Borrado mediante Stored Procedures)
    # -------------------------------------------------------------------------
    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # SP: Eliminación de Cliente (sp_eliminar_cliente)
        if path == "/api/sp/delete_cliente":
            dni = query.get("dni", [""])[0].strip()
            if not dni:
                return self._send_json(400, {"error": "Se requiere el parámetro 'dni'."})

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_eliminar_cliente(%s);", (dni,))
                conn.commit()
                conn.close()
                return self._send_json(200, {
                    "success": True,
                    "message": f"Cliente con DNI {dni} eliminado correctamente mediante Stored Procedure."
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        # SP: Eliminación de Producto (sp_eliminar_producto)
        if path == "/api/sp/delete_producto":
            codigo = query.get("codigo", [""])[0].strip()
            if not codigo:
                return self._send_json(400, {"error": "Se requiere el parámetro 'codigo'."})

            try:
                conn = get_db_connection()
                with conn.cursor() as cur:
                    cur.execute("CALL public.sp_eliminar_producto(%s);", (codigo,))
                conn.commit()
                conn.close()
                return self._send_json(200, {
                    "success": True,
                    "message": f"Producto {codigo} eliminado correctamente mediante Stored Procedure."
                })
            except Exception as e:
                return self._send_json(400, {"success": False, "error": str(e)})

        self._send_json(404, {"error": f"Ruta DELETE no encontrada: {path}"})

    # -------------------------------------------------------------------------
    # SERVIR INDEX.HTML ESTÁTICO (Fallback para navegador)
    # -------------------------------------------------------------------------
    def _serve_index_html(self):
        candidate_paths = [
            os.path.join(os.path.dirname(__file__), "index.html"),
            os.path.join(os.path.dirname(__file__), "..", "public", "index_standalone.html"),
            "index.html",
        ]
        html_file = None
        for p in candidate_paths:
            if os.path.exists(p):
                html_file = p
                break

        if html_file:
            with open(html_file, "rb") as f:
                content = f.read()
            self._set_cors_headers(200, "text/html; charset=utf-8")
            self.wfile.write(content)
        else:
            self._send_json(200, {
                "mensaje": "Servidor nativo Python en ejecución.",
                "rutas_disponibles": [
                    "/api/health",
                    "/api/reports/list",
                    "/api/reports?id=1..10",
                    "/api/sp/insert_cliente",
                    "/api/sp/update_cliente",
                    "/api/sp/delete_cliente",
                    "/api/sp/insert_producto",
                    "/api/sp/update_producto",
                    "/api/sp/delete_producto"
                ]
            })


# -----------------------------------------------------------------------------
# PUNTO DE ENTRADA PRINCIPAL
# -----------------------------------------------------------------------------
def run(server_class=ThreadingHTTPServer, handler_class=NativePostgresServer, port=SERVER_PORT):
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    print("=" * 70)
    print(f" Servidor Nativo Python (http.server + psycopg2) en puerto {port}")
    print(" CERO FRAMEWORKS (Sin Flask, sin Express, sin React)")
    print("=" * 70)
    print(f" URL local: http://localhost:{port}")
    print(f" Estado de PostgreSQL: Host={DB_CONFIG['host']}, DB={DB_CONFIG['dbname']}, User={DB_CONFIG['user']}")
    print(" Presiona Ctrl+C para detener el servidor.")
    print("=" * 70)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nDeteniendo servidor...")
        httpd.server_close()
        print("Servidor detenido exitosamente.")


if __name__ == "__main__":
    run()

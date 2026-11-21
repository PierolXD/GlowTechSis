#!/usr/bin/env python3
"""
Script de verificación y migración segura para GlowTechSis (PostgreSQL).
- Verifica conexión a PostgreSQL.
- Crea la base de datos `db_asesoria` si no existe.
- Aplica `database/script_completo_glowtech.sql` (idempotente: preserva datos existentes,
  completa tablas faltantes, carga los 211 productos base si faltan, e instala los 27 SPs y 5 Triggers).
"""

import os
import pathlib
import sys

try:
    import psycopg2
except ImportError:
    print("[ERROR] psycopg2 no está instalado. Ejecuta: pip install psycopg2-binary")
    sys.exit(1)

ROOT = pathlib.Path(__file__).resolve().parent.parent
MASTER_SQL = ROOT / "database" / "script_completo_glowtech.sql"


def _load_dotenv_if_present():
    """Carga variables de entorno desde .env local si existe (sin dependencias)."""
    env_path = ROOT / ".env"
    if not env_path.is_file():
        return
    try:
        for raw_line in env_path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = val
    except Exception:
        pass


_load_dotenv_if_present()

HOST = os.environ.get("PGHOST", "localhost")
PORT = int(os.environ.get("PGPORT", "5432"))
DBNAME = os.environ.get("PGDATABASE", "db_asesoria")
USER = os.environ.get("PGUSER", "postgres")
PASSWORD = os.environ.get("PGPASSWORD", "postgres")


def ensure_database():
    conn = psycopg2.connect(host=HOST, port=PORT, dbname="postgres", user=USER, password=PASSWORD)
    conn.autocommit = True
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (DBNAME,))
        if not cur.fetchone():
            cur.execute(f'CREATE DATABASE "{DBNAME}";')
            print(f"[OK] Base de datos '{DBNAME}' creada.")
        else:
            print(f"[OK] Base de datos '{DBNAME}' ya existe.")
    conn.close()


def apply_master_script():
    sql = MASTER_SQL.read_text(encoding="utf-8")
    conn = psycopg2.connect(host=HOST, port=PORT, dbname=DBNAME, user=USER, password=PASSWORD)
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"[OK] Script maestro aplicado correctamente en '{DBNAME}'.")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def print_summary():
    conn = psycopg2.connect(host=HOST, port=PORT, dbname=DBNAME, user=USER, password=PASSWORD)
    with conn.cursor() as cur:
        cur.execute("SELECT version();")
        print("PostgreSQL:", cur.fetchone()[0])
        cur.execute(
            "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"
        )
        tables = [r[0] for r in cur.fetchall()]
        print(f"Tablas ({len(tables)}):")
        for t in tables:
            cur.execute(f"SELECT COUNT(*) FROM public.{t};")
            print(f"  - {t}: {cur.fetchone()[0]} registros")
        cur.execute(
            "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid WHERE n.nspname='public' AND p.prokind='p';"
        )
        print("Stored Procedures:", cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM pg_trigger WHERE NOT tgisinternal;")
        print("Triggers activos:", cur.fetchone()[0])
    conn.close()


def _extract_error_text(ex):
    """Obtiene texto legible de excepciones psycopg2/libpq incluso con codificación CP1252 en Windows."""
    if isinstance(ex, UnicodeDecodeError) and isinstance(getattr(ex, "object", None), (bytes, bytearray)):
        return ex.object.decode("cp1252", errors="replace")
    try:
        return str(ex)
    except Exception:
        return repr(ex)


if __name__ == "__main__":
    try:
        ensure_database()
        apply_master_script()
        print_summary()
    except Exception as ex:
        msg = _extract_error_text(ex)
        lower_msg = msg.lower()
        is_auth_error = any(
            k in lower_msg
            for k in (
                "password authentication failed",
                "autenticaci",
                "autentificaci",
                "contraseña",
                "password",
                "no existe el rol",
                "pg_hba.conf",
                "0xf3",
            )
        ) or ("role " in lower_msg and "does not exist" in lower_msg)
        is_conn_error = "fatal:" not in lower_msg and any(
            k in lower_msg
            for k in (
                "connection to server",
                "could not connect",
                "refused",
                "no se pudo establecer",
                "no se puede conectar",
                "rechaz",
                "conexión",
                "timeout",
            )
        )

        if is_auth_error:
            print(
                f"[ERROR_AUTH] Contraseña incorrecta o usuario no autorizado para PostgreSQL (usuario '{USER}')."
            )
            sys.exit(2)
        if is_conn_error or isinstance(ex, UnicodeDecodeError):
            if isinstance(ex, UnicodeDecodeError):
                # Fallback si UnicodeDecodeError no trajo texto clasificable
                print(
                    f"[ERROR_AUTH] Error de autenticación o respuesta no UTF-8 de PostgreSQL para '{USER}'."
                )
                sys.exit(2)
            print(
                f"[ERROR_CONN] No se pudo conectar a PostgreSQL en {HOST}:{PORT}. Verifica que el servicio esté iniciado."
            )
            sys.exit(3)

        print(f"[ERROR] No se pudo verificar/migrar la base de datos: {msg}")
        sys.exit(1)

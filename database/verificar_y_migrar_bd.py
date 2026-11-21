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


if __name__ == "__main__":
    ensure_database()
    apply_master_script()
    print_summary()

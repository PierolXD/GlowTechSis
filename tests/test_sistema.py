#!/usr/bin/env python3
"""
Suite de pruebas automatizadas de GlowTechSis.
Valida:
  1. Conexión a PostgreSQL, 9 tablas, datos base (211 productos, 15 categorías, 26 marcas).
  2. Existencia de los 27 Stored Procedures y 5 Triggers.
  3. Ciclo completo CRUD vía Stored Procedures (Insert -> Update -> Delete) para las 9 tablas.
  4. Bloqueo real de los 5 Triggers de validación con datos inválidos.
  5. Ejecución de las 10 Consultas de INIFORMACION.docx y 10 Reportes Gerenciales vía HTTP API.
No deja datos residuales en la base de datos.
"""

import json
import os
import sys
import threading
import urllib.error
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "python_backend"))

import app as backend  # noqa: E402
import psycopg2  # noqa: E402

TEST_PORT = 8099
BASE_URL = f"http://127.0.0.1:{TEST_PORT}"


def http_req(method: str, path: str, payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    headers = {"Content-Type": "application/json"} if data is not None else {}
    req = urllib.request.Request(f"{BASE_URL}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode("utf-8"))


def run_tests():
    # Levantar servidor HTTP efímero en hilo daemon
    server = backend.ThreadingHTTPServer(("127.0.0.1", TEST_PORT), backend.NativePostgresServer)
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()

    try:
        # 1. Salud y Diagnóstico BD
        st, health = http_req("GET", "/api/health")
        assert st == 200 and health["db_connected"], f"Fallo /api/health: {health}"
        st, diag = http_req("GET", "/api/test-db")
        assert st == 200 and diag["success"], f"Fallo /api/test-db: {diag}"
        assert diag["tables_present"] >= 9, f"Faltan tablas: {diag}"
        assert diag["row_counts"]["producto_catalogo"] >= 211, "Faltan productos base"
        assert diag["row_counts"]["categoria"] >= 15, "Faltan categorías base"
        assert diag["row_counts"]["marca"] >= 26, "Faltan marcas base"
        assert diag["procedures_count"] >= 27, f"Se esperaban >=27 SPs, hay {diag['procedures_count']}"
        assert diag["triggers_count"] >= 5, f"Se esperaban >=5 triggers, hay {diag['triggers_count']}"
        print(f"[PASS] 1. Conexión e integridad BD ({diag['database']}: 9 tablas, {diag['procedures_count']} SPs, {diag['triggers_count']} triggers)")

        # 2. 10 Reportes Gerenciales
        for i in range(1, 11):
            st, rep = http_req("GET", f"/api/reports?id={i}")
            assert st == 200 and rep["success"], f"Fallo Reporte {i}: {rep}"
        print("[PASS] 2. 10 Reportes Gerenciales ejecutados correctamente")

        # 3. 10 Consultas del Documento (INIFORMACION.docx)
        for i in range(1, 11):
            st, q = http_req("GET", f"/api/consultas-doc?id={i}")
            assert st == 200 and q["success"], f"Fallo Consulta Doc {i}: {q}"
        print("[PASS] 3. 10 Consultas Operativas de INIFORMACION.docx ejecutadas correctamente")

        # 4. Algoritmo de Mapeo (Candidatos)
        st, cand = http_req("GET", "/api/asesoria/candidatos?id_perfil=1&categoria=AUDIFONOS")
        assert st == 200 and cand["success"] and cand["total_candidatos"] > 0, f"Fallo candidatos: {cand}"
        print(f"[PASS] 4. Algoritmo de Mapeo devolvió {cand['total_candidatos']} candidatos para Perfil #1")

        # 5. Ciclo CRUD completo sobre las 9 tablas (Insert -> Update -> Delete)
        st, r = http_req("POST", "/api/sp/insert_categoria", {"nombre_categoria": "CAT_TEST_TMP"})
        assert st == 201 and r["success"], r
        cat_id = r["id_categoria"]
        st, r = http_req("PUT", "/api/sp/update_categoria", {"id_categoria": cat_id, "nombre_categoria": "CAT_TEST_UPD"})
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_marca", {"nombre_marca": "MARCA_TEST_TMP"})
        assert st == 201 and r["success"], r
        mar_id = r["id_marca"]
        st, r = http_req("PUT", "/api/sp/update_marca", {"id_marca": mar_id, "nombre_marca": "MARCA_TEST_UPD"})
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_asesor", {
            "nombres": "Test", "apellidos": "Asesor", "especialidad": "Audio", "turno": "TARDE"
        })
        assert st == 201 and r["success"], r
        ase_id = r["id_asesor"]
        st, r = http_req("PUT", "/api/sp/update_asesor", {
            "id_asesor": ase_id, "nombres": "TestUpd", "apellidos": "Asesor", "especialidad": "Audio Pro", "turno": "NOCHE"
        })
        assert st == 200 and r["success"], r

        dni = "99998888"
        st, r = http_req("POST", "/api/sp/insert_cliente", {
            "dni": dni, "nombres": "Prueba", "apellidos": "Auto", "canal_contacto": "Web", "telefono": "900000000", "correo": "TEST@MAIL.COM"
        })
        assert st == 201 and r["success"], r
        st, r = http_req("PUT", "/api/sp/update_cliente", {
            "dni": dni, "nombres": "PruebaUpd", "apellidos": "Auto", "canal_contacto": "WhatsApp", "telefono": "911111111", "correo": "upd@mail.com"
        })
        assert st == 200 and r["success"], r

        cod = "PROD_TEST_99"
        st, r = http_req("POST", "/api/sp/insert_producto", {
            "codigo": cod, "modelo": "Modelo Test", "especificaciones": "Spec 1", "precio": 250.0, "id_marca": mar_id, "id_categoria": cat_id
        })
        assert st == 201 and r["success"], r
        st, r = http_req("PUT", "/api/sp/update_producto", {
            "codigo": cod, "modelo": "Modelo Test Upd", "especificaciones": "Spec 2", "precio": 275.0, "id_marca": mar_id, "id_categoria": cat_id
        })
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_perfil", {
            "uso_principal": "Prueba Auto", "presupuesto_max": 400.0, "restriccion_tecnica": "BT", "dni_cliente": dni, "id_asesor": ase_id, "id_marca": mar_id
        })
        assert st == 201 and r["success"] and r["id_perfil"], r
        per_id = r["id_perfil"]
        st, r = http_req("PUT", "/api/sp/update_perfil", {
            "id_perfil": per_id, "uso_principal": "Prueba Auto Upd", "presupuesto_max": 450.0, "restriccion_tecnica": "BT 5.3", "id_marca": mar_id
        })
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_matriz", {
            "criterio_evaluacion": "Criterio Test", "diferencial_tecnico": "Dif 1", "id_perfil": per_id
        })
        assert st == 201 and r["success"] and r["id_comparativa"], r
        mat_id = r["id_comparativa"]
        st, r = http_req("PUT", "/api/sp/update_matriz", {
            "id_comparativa": mat_id, "criterio_evaluacion": "Criterio Upd", "diferencial_tecnico": "Dif 2", "id_perfil": per_id
        })
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_detalle", {
            "id_comparativa": mat_id, "codigo_producto": cod, "resultado_evaluacion": "Candidato OK"
        })
        assert st == 201 and r["success"], r
        st, r = http_req("PUT", "/api/sp/update_detalle", {
            "id_comparativa": mat_id, "codigo_producto": cod, "resultado_evaluacion": "Candidato Óptimo"
        })
        assert st == 200 and r["success"], r

        st, r = http_req("POST", "/api/sp/insert_recomendacion", {
            "justificacion_tecnica": "Cumple todo", "indicacion_uso": "Cargar 2h", "nivel_compatibilidad": 95.5, "id_comparativa": mat_id, "codigo_producto": cod
        })
        assert st == 201 and r["success"] and r["id_recomendacion"], r
        rec_id = r["id_recomendacion"]
        st, r = http_req("PUT", "/api/sp/update_recomendacion", {
            "id_recomendacion": rec_id, "justificacion_tecnica": "Cumple todo Upd", "indicacion_uso": "Cargar 3h", "nivel_compatibilidad": 98.0, "id_comparativa": mat_id, "codigo_producto": cod
        })
        assert st == 200 and r["success"], r

        # Limpieza en orden inverso de FK (valida todos los SP de eliminación)
        for path in [
            f"/api/sp/delete_recomendacion?id={rec_id}",
            f"/api/sp/delete_detalle?id_comparativa={mat_id}&codigo_producto={cod}",
            f"/api/sp/delete_matriz?id={mat_id}",
            f"/api/sp/delete_perfil?id={per_id}",
            f"/api/sp/delete_producto?codigo={cod}",
            f"/api/sp/delete_cliente?dni={dni}",
            f"/api/sp/delete_asesor?id={ase_id}",
            f"/api/sp/delete_marca?id={mar_id}",
            f"/api/sp/delete_categoria?id={cat_id}",
        ]:
            st, r = http_req("DELETE", path)
            assert st == 200 and r["success"], f"Fallo DELETE {path}: {r}"
        print("[PASS] 5. Ciclo CRUD completo (Insert/Update/Delete) validado en las 9 tablas")

        # 6. Validación de los 5 Triggers con datos inválidos
        invalid_cases = [
            ("trg_validar_cliente", "/api/sp/insert_cliente", {"dni": "12AB5678", "nombres": "X", "apellidos": "Y"}),
            ("trg_validar_producto", "/api/sp/insert_producto", {"codigo": "BAD1", "modelo": "M", "precio": -10, "id_marca": 1, "id_categoria": 1}),
            ("trg_validar_perfil", "/api/sp/insert_perfil", {"uso_principal": "U", "presupuesto_max": 0, "dni_cliente": "12345678", "id_asesor": 1}),
            ("trg_validar_asesor", "/api/sp/insert_asesor", {"nombres": "A", "apellidos": "B", "turno": "MADRUGADA"}),
            ("trg_validar_recomendacion", "/api/sp/insert_recomendacion", {"id_comparativa": 1, "codigo_producto": "PROD0003", "nivel_compatibilidad": 150, "justificacion_tecnica": "X"}),
        ]
        for name, path, payload in invalid_cases:
            st, r = http_req("POST", path, payload)
            assert st == 400 and not r.get("success"), f"Trigger {name} no bloqueó dato inválido: {r}"
        print("[PASS] 6. Los 5 Triggers de validación bloquearon correctamente los casos inválidos")

        print("\n=== TODAS LAS PRUEBAS PASARON AL 100% ===")
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    run_tests()

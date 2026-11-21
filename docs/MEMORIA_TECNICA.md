# Memoria Técnica — Sistema de Asesoramiento Técnico GlowTechSis

**Proyecto:** Desarrollo de una Base de Datos y Aplicativo Orientado al Asesoramiento para la Compra de Productos Electrónicos en la Empresa Glowtech  
**Institución:** Universidad Católica de Santa María (UCSM) — Escuela Profesional de Ingeniería de Sistemas  
**Integrantes:** Janlennart Chávez Pérez, Pierol Yaren Huanqui Luque, Sergio Adrián Monroy Bellido  
**Motor de Base de Datos:** PostgreSQL (14 o superior)  
**Tecnología del Aplicativo:** Python 3 Nativo (`http.server` + `psycopg2`) + HTML5 / CSS3 / JavaScript Vanilla (`fetch`) — Cero Frameworks

---

## 1. Resumen Ejecutivo

GlowTechSis formaliza y automatiza el proceso de **Atención y Asesoramiento Técnico** de la empresa peruana **Glowtech**, dedicada a la comercialización de productos electrónicos, audio, cómputo, hogar y herramientas. El sistema se enfoca exclusivamente en el proceso consultivo (excluyendo facturación e inventario transaccional), cubriendo de extremo a extremo las tres etapas definidas en el informe base (`INIFORMACION.docx`):

1. **Registro de Requerimientos:** Captura de datos del cliente y construcción de su perfil de necesidad (uso principal, presupuesto máximo, restricciones técnicas, marca preferida y asesor asignado).
2. **Análisis Comparativo de Productos:** Aplicación del algoritmo de mapeo contra el catálogo de 211 productos, creación de la matriz comparativa y evaluación de candidatos.
3. **Generación de Recomendación Técnica:** Selección del producto óptimo con porcentaje de compatibilidad (0–100%), justificación técnica, indicaciones de uso/mantenimiento y emisión del **Reporte Final de Asesoría**.

---

## 2. Arquitectura del Sistema

El sistema sigue una arquitectura limpia de **tres capas** sin frameworks pesados, priorizando transparencia académica, trazabilidad SQL y control directo sobre el motor relacional:

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ CAPA DE PRESENTACIÓN (Frontend Nativo: python_backend/index.html)       │
│ • Vanilla HTML5, CSS3 y JavaScript (fetch API)                          │
│ • Diagnóstico de conexión real a PostgreSQL                             │
│ • Flujo guiado de Asesoramiento en 3 Etapas (Algoritmo de Mapeo)        │
│ • CRUD completo de las 9 tablas con selectores relacionales             │
│ • 10 Consultas Operativas del Documento + 10 Reportes Gerenciales + CSV │
│ • Panel interactivo de pruebas en vivo de los 5 Triggers                │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │ HTTP / JSON (Puerto 8000, CORS)
┌───────────────────────────────────▼──────────────────────────────────────┐
│ CAPA DE APLICACIÓN (Backend Nativo: python_backend/app.py)              │
│ • ThreadingHTTPServer (librería estándar http.server)                   │
│ • Conector psycopg2 con consultas parametrizadas (%s)                   │
│ • Invocación exclusiva de Stored Procedures (CALL public.sp_*)          │
│ • Lectura automática de variables de entorno / archivo .env             │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │ Protocolo PostgreSQL (Puerto 5432)
┌───────────────────────────────────▼──────────────────────────────────────┐
│ CAPA DE DATOS (PostgreSQL: base de datos db_asesoria)                   │
│ • 9 tablas normalizadas en 3FN con PK, FK y CHECK                       │
│ • 9 índices estratégicos de rendimiento                                 │
│ • 27 Stored Procedures PL/pgSQL (Insertar, Modificar, Eliminar x 9)     │
│ • 5 Triggers BEFORE INSERT/UPDATE para reglas de negocio                │
│ • Catálogo inicial: 15 categorías, 26 marcas, 211 productos             │
└──────────────────────────────────────────────────────────────────────────┘
```

> **Separación del Simulador React:** El prototipo visual en memoria (`src/`) fue separado y optimizado en la carpeta independiente `simulador_react/` para evitar confusiones con el sistema real conectado a PostgreSQL.

---

## 3. Modelo de Datos Físico (3FN)

Todas las tablas residen en el esquema `public` de la base de datos `db_asesoria`, respetando estrictamente el modelo normalizado hasta la Tercera Forma Normal (3FN):

| N.º | Tabla | Clave Primaria | Claves Foráneas | Registros Base | Propósito |
| :-: | :--- | :--- | :--- | :-: | :--- |
| 1 | `categoria` | `id_categoria` (IDENTITY) | — | 15 | Catálogo maestro de familias de productos |
| 2 | `marca` | `id_marca` (IDENTITY) | — | 26 | Catálogo maestro de fabricantes |
| 3 | `cliente` | `dni_cliente` (`CHAR(8)`) | — | 1+ | Datos de identificación y contacto del cliente |
| 4 | `asesor_tecnico` | `id_asesor` (IDENTITY) | — | 1+ | Personal técnico que atiende las asesorías |
| 5 | `producto_catalogo` | `codigo_producto` (`VARCHAR(20)`) | `id_marca`, `id_categoria` | 211 | Catálogo técnico con modelo, especificaciones y precio |
| 6 | `perfil_de_necesidad` | `id_perfil` (IDENTITY) | `dni_cliente`, `id_asesor`, `id_marca` (opcional) | 1+ | Requerimientos, presupuesto y restricciones del cliente |
| 7 | `matriz_de_comparativa` | `id_comparativa` (IDENTITY) | `id_perfil` | 1+ | Criterios de evaluación y diferencial técnico |
| 8 | `detalle_evaluacion` | `(id_comparativa, codigo_producto)` | `id_comparativa`, `codigo_producto` | 3+ | Resolución M:N entre matrices y productos evaluados |
| 9 | `recomendacion_final` | `id_recomendacion` (IDENTITY) | `id_comparativa`, `codigo_producto` | 1+ | Producto ganador, compatibilidad (`CHECK 0..100`), justificación y uso |

### Índices Estratégicos Implementados
Para optimizar las consultas frecuentes de filtrado por presupuesto, marca, categoría y cliente:
- `idx_producto_marca`, `idx_producto_categoria`, `idx_producto_precio` en `producto_catalogo`
- `idx_perfil_cliente`, `idx_perfil_asesor`, `idx_perfil_fecha` en `perfil_de_necesidad`
- `idx_matriz_perfil` en `matriz_de_comparativa`
- `idx_recomendacion_comp`, `idx_recomendacion_prod` en `recomendacion_final`

---

## 4. Lógica de Negocio en PostgreSQL (PL/pgSQL)

### 4.1 Stored Procedures (27 Procedimientos — Cobertura Total)
Cada una de las 9 entidades cuenta con 3 procedimientos almacenados (`sp_insertar_*`, `sp_modificar_*`, `sp_eliminar_*`) que encapsulan validaciones previas, integridad referencial explícita y retorno de identificadores `INOUT` en las tablas con `IDENTITY`:

- **Cliente:** `sp_insertar_cliente`, `sp_modificar_cliente`, `sp_eliminar_cliente`
- **Producto Catálogo:** `sp_insertar_producto`, `sp_modificar_producto`, `sp_eliminar_producto`
- **Perfil de Necesidad:** `sp_insertar_perfil_necesidad`, `sp_modificar_perfil_necesidad`, `sp_eliminar_perfil_necesidad`
- **Categoría:** `sp_insertar_categoria`, `sp_modificar_categoria`, `sp_eliminar_categoria`
- **Marca:** `sp_insertar_marca`, `sp_modificar_marca`, `sp_eliminar_marca`
- **Asesor Técnico:** `sp_insertar_asesor`, `sp_modificar_asesor`, `sp_eliminar_asesor`
- **Matriz de Comparativa:** `sp_insertar_matriz`, `sp_modificar_matriz`, `sp_eliminar_matriz`
- **Detalle de Evaluación:** `sp_insertar_detalle_evaluacion`, `sp_modificar_detalle_evaluacion`, `sp_eliminar_detalle_evaluacion`
- **Recomendación Final:** `sp_insertar_recomendacion`, `sp_modificar_recomendacion`, `sp_eliminar_recomendacion`

### 4.2 Triggers de Validación (5 Triggers Activos)
Garantizan la calidad de los datos independientemente de si la escritura proviene de la web, de la API o de `psql`:

| Trigger | Tabla | Evento | Regla de Negocio Enforced |
| :--- | :--- | :--- | :--- |
| `trg_validar_perfil` | `perfil_de_necesidad` | `BEFORE INSERT OR UPDATE` | `presupuesto_max > 0`; `fecha_registro <= CURRENT_DATE` (por defecto hoy). |
| `trg_validar_cliente` | `cliente` | `BEFORE INSERT OR UPDATE` | `dni_cliente` con regex `^[0-9]{8}$`; recorte de espacios y correo en minúsculas. |
| `trg_validar_producto` | `producto_catalogo` | `BEFORE INSERT OR UPDATE` | `codigo_producto` y `modelo` no vacíos; `precio_referencial >= 0`. |
| `trg_validar_asesor` | `asesor_tecnico` | `BEFORE INSERT OR UPDATE` | Nombres/apellidos obligatorios; `turno` normalizado en `{MANANA, TARDE, NOCHE, COMPLETO}`. |
| `trg_validar_recomendacion` | `recomendacion_final` | `BEFORE INSERT OR UPDATE` | `justificacion_tecnica` obligatoria; `nivel_compatibilidad` en rango `[0, 100]`. |

---

## 5. Implementación del Algoritmo de Mapeo y Consultas

### 5.1 Algoritmo de Mapeo en 3 Etapas
Implementado en `GET /api/asesoria/candidatos` y en la pestaña **Flujo de Asesoría (3 Etapas)**:
1. **Entrada:** Perfil de necesidad del cliente (`presupuesto_max`, `id_marca` preferida) + filtro opcional de categoría o palabra clave.
2. **Evaluación:** Filtra `producto_catalogo` por `precio_referencial <= presupuesto_max` y marca preferida (si existe), calcula `ahorro_estimado = presupuesto_max - precio_referencial` y un puntaje de `compatibilidad_sugerida` (0–100%).
3. **Salida:** Permite registrar con un clic la matriz comparativa, cada candidato en `detalle_evaluacion` y la `recomendacion_final`, generando inmediatamente el Reporte Final de Asesoría.

### 5.2 Catálogo de Consultas (20 Consultas SQL)
- **10 Consultas Operativas del Documento (`INIFORMACION.docx`, Figuras 26–35):** Accesibles desde `GET /api/consultas-doc?id=1..10` con parámetros dinámicos seguros (`%s`) y exportación CSV.
- **10 Reportes Gerenciales (8 con `JOIN` + 2 analíticos):** Accesibles desde `GET /api/reports?id=1..10` y en `database/reportes.sql` (con Reporte 3 alineado para incluir `restriccion_tecnica`).

---

## 6. Cumplimiento de la Agenda y Verificación

| Hito de la Agenda | Evidencia de Cumplimiento al 100% |
| :--- | :--- |
| **Conexión a BD y prueba de conexión (30%)** | Endpoints `/api/health` y `/api/test-db`, botón interactivo en el panel web, archivo `.env.example`, script `iniciar_ui.ps1` y `database/verificar_y_migrar_bd.py`. |
| **Aplicativo al 70%, CRUDs implementados y probados, procedimientos** | 27 Stored Procedures PL/pgSQL + 5 Triggers + API completa + UI CRUD para las 9 tablas con selectores dinámicos + suite automatizada `tests/test_sistema.py`. |
| **Aplicativo al 100% y documentos (script, códigos, memoria y manual de usuario)** | Flujo de Asesoría en 3 etapas, 20 consultas SQL (10 del documento + 10 reportes), script maestro idempotente `script_completo_glowtech.sql`, códigos limpios y separados (`simulador_react/`), `MEMORIA_TECNICA.md`, `DOCUMENTACION_SCRIPTS_Y_CODIGOS.md` y verificación de los manuales PDF existentes. |

---

## 7. Conclusiones

El sistema **GlowTechSis** materializa en su totalidad el diseño conceptual, lógico (3FN) y físico planteado en el informe de la empresa Glowtech. Al concentrar la integridad y reglas de negocio en PostgreSQL (mediante 27 procedimientos almacenados y 5 triggers) y exponerlos a través de un servidor nativo Python y una interfaz web ligera sin frameworks, se garantiza portabilidad, mantenibilidad, trazabilidad y un cumplimiento verificado al 100% de la agenda del proyecto.

-- ============================================================================
-- GLOWTECH - CONSULTAS REQUERIDAS DEL DOCUMENTO Y REPORTES GERENCIALES
-- Archivo: database/reportes.sql
-- Contenido:
--   SECCIÓN A: 10 Consultas Operativas requeridas en INIFORMACION.docx (Figuras 26-35)
--   SECCIÓN B: 10 Reportes Gerenciales con JOINs y agregaciones (Panel Web)
-- ============================================================================

-- ============================================================================
-- SECCIÓN A: 10 CONSULTAS REQUERIDAS EN EL DOCUMENTO (INIFORMACION.docx)
-- ============================================================================

-- Consulta Doc 1: Buscar productos según el presupuesto del cliente (ej. S/ 500)
SELECT
    p.codigo_producto,
    p.modelo,
    m.nombre_marca AS marca,
    c.nombre_categoria AS categoria,
    p.precio_referencial AS precio
FROM public.producto_catalogo p
JOIN public.marca m ON p.id_marca = m.id_marca
JOIN public.categoria c ON p.id_categoria = c.id_categoria
WHERE p.precio_referencial <= 500
ORDER BY p.precio_referencial DESC;

-- Consulta Doc 2: Buscar un producto según lo que necesita el cliente (ej. AUDIFONOS / JBL)
SELECT
    p.modelo,
    m.nombre_marca AS marca,
    c.nombre_categoria AS categoria,
    p.precio_referencial
FROM public.producto_catalogo p
JOIN public.marca m ON p.id_marca = m.id_marca
JOIN public.categoria c ON p.id_categoria = c.id_categoria
WHERE p.modelo ILIKE '%JBL%'
   OR c.nombre_categoria ILIKE '%AUDIFONOS%'
ORDER BY p.precio_referencial ASC;

-- Consulta Doc 3: Buscar productos de una marca preferida (ej. SAMSUNG)
SELECT
    p.modelo,
    m.nombre_marca,
    p.especificaciones,
    p.precio_referencial
FROM public.producto_catalogo p
JOIN public.marca m ON p.id_marca = m.id_marca
WHERE m.nombre_marca ILIKE '%SAMSUNG%'
ORDER BY p.precio_referencial ASC;

-- Consulta Doc 4: Comparar productos dentro de un mismo rango de precios (S/ 200 a S/ 400)
SELECT
    p.codigo_producto,
    p.modelo,
    m.nombre_marca,
    p.especificaciones,
    p.precio_referencial
FROM public.producto_catalogo p
JOIN public.marca m ON p.id_marca = m.id_marca
JOIN public.categoria c ON p.id_categoria = c.id_categoria
WHERE c.nombre_categoria ILIKE '%AUDIFONOS%'
  AND p.precio_referencial BETWEEN 200 AND 400
ORDER BY p.precio_referencial ASC;

-- Consulta Doc 5: Encontrar las tres alternativas más económicas (ej. PARLANTES)
SELECT
    p.modelo,
    m.nombre_marca,
    p.precio_referencial
FROM public.producto_catalogo p
JOIN public.marca m ON p.id_marca = m.id_marca
JOIN public.categoria c ON p.id_categoria = c.id_categoria
WHERE c.nombre_categoria ILIKE '%PARLANTES%'
ORDER BY p.precio_referencial ASC
LIMIT 3;

-- Consulta Doc 6: Consultar el perfil y las necesidades de un cliente (ej. DNI 12345678)
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
WHERE c.dni_cliente = '12345678'
ORDER BY pn.fecha_registro DESC;

-- Consulta Doc 7: Buscar productos adecuados para el cliente (presupuesto, marca y categoría)
SELECT
    p.modelo,
    m.nombre_marca AS marca,
    p.precio_referencial AS precio,
    pn.presupuesto_max AS presupuesto,
    pn.presupuesto_max - p.precio_referencial AS dinero_restante
FROM public.perfil_de_necesidad pn
JOIN public.producto_catalogo p
    ON p.precio_referencial <= pn.presupuesto_max
    AND (pn.id_marca IS NULL OR p.id_marca = pn.id_marca)
JOIN public.marca m ON p.id_marca = m.id_marca
JOIN public.categoria cat ON p.id_categoria = cat.id_categoria
WHERE pn.dni_cliente = '12345678'
  AND cat.nombre_categoria ILIKE '%AUDIFON%'
ORDER BY p.precio_referencial DESC;

-- Consulta Doc 8: Comparar las alternativas evaluadas para un cliente
SELECT
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
WHERE pn.dni_cliente = '12345678'
ORDER BY p.precio_referencial DESC;

-- Consulta Doc 9: Identificar el producto recomendado óptimo del cliente
SELECT
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
WHERE pn.dni_cliente = '12345678'
ORDER BY r.nivel_compatibilidad DESC NULLS LAST,
         p.precio_referencial DESC
LIMIT 1;

-- Consulta Doc 10: Generar el reporte final de asesoría completo
SELECT
    c.nombres || ' ' || c.apellidos AS cliente,
    c.dni_cliente,
    a.nombres || ' ' || a.apellidos AS asesor,
    pn.fecha_registro,
    pn.uso_principal,
    pn.presupuesto_max,
    pn.restriccion_tecnica,
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
WHERE c.dni_cliente = '12345678'
ORDER BY pn.fecha_registro DESC,
         r.nivel_compatibilidad DESC NULLS LAST;


-- ============================================================================
-- SECCIÓN B: 10 REPORTES GERENCIALES (8 CON JOINS + 2 ANALÍTICOS DIRECTOS)
-- ============================================================================

-- Reporte 1: Catálogo completo con marca y categoría
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

-- Reporte 2: Resumen estadístico de precios por categoría
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

-- Reporte 3: Perfiles de necesidad con clientes, asesores y marca preferida
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

-- Reporte 4: Matriz comparativa y detalle de evaluación técnica
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

-- Reporte 5: Recomendaciones finales con nivel de compatibilidad
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

-- Reporte 6: Carga de trabajo y desempeño de asesores técnicos
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

-- Reporte 7: Comparativa financiera (Presupuesto vs Precio Recomendado)
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

-- Reporte 8: Distribución y rango de precios por marca
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

-- Reporte 9: Top 15 productos de mayor valor en catálogo
SELECT
    codigo_producto,
    modelo,
    precio_referencial,
    especificaciones
FROM public.producto_catalogo
ORDER BY precio_referencial DESC
LIMIT 15;

-- Reporte 10: Distribución porcentual de clientes por canal de contacto
SELECT
    COALESCE(canal_contacto, 'No especificado') AS canal_contacto,
    COUNT(*) AS cantidad_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
FROM public.cliente
GROUP BY canal_contacto
ORDER BY cantidad_clientes DESC;

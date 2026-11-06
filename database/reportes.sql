
-- Muestra todos los productos vinculando su marca y categoría,
-- ordenados por categoría y precio referencial de mayor a menor.
SELECT 
    p.codigo_producto,
    p.modelo,
    m.nombre_marca,
    c.nombre_categoria,
    p.precio_referencial,
    p.especificaciones
FROM public.producto_catalogo p
INNER JOIN public.marca m 
    ON p.id_marca = m.id_marca
INNER JOIN public.categoria c 
    ON p.id_categoria = c.id_categoria
ORDER BY c.nombre_categoria ASC, p.precio_referencial DESC;


-- Calcula el total de productos, el precio promedio, el mínimo
-- y el máximo para cada una de las 15 categorías del catálogo.
SELECT 
    c.id_categoria,
    c.nombre_categoria,
    COUNT(p.codigo_producto) AS total_productos,
    COALESCE(ROUND(AVG(p.precio_referencial), 2), 0.00) AS precio_promedio,
    COALESCE(MIN(p.precio_referencial), 0.00) AS precio_minimo,
    COALESCE(MAX(p.precio_referencial), 0.00) AS precio_maximo
FROM public.categoria c
LEFT JOIN public.producto_catalogo p 
    ON c.id_categoria = p.id_categoria
GROUP BY c.id_categoria, c.nombre_categoria
ORDER BY total_productos DESC, c.nombre_categoria ASC;



-- Presenta la ficha completa de requerimientos del cliente,
-- indicando datos de contacto, asesor técnico asignado, turno y marca solicitada.
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
INNER JOIN public.cliente cl 
    ON pn.dni_cliente = cl.dni_cliente
INNER JOIN public.asesor_tecnico ast 
    ON pn.id_asesor = ast.id_asesor
LEFT JOIN public.marca m 
    ON pn.id_marca = m.id_marca
ORDER BY pn.fecha_registro DESC, pn.id_perfil DESC;


-- Relaciona las matrices de decisión técnica con los productos
-- evaluados y los veredictos o resultados de evaluación emitidos por el asesor.
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
INNER JOIN public.detalle_evaluacion de 
    ON mc.id_comparativa = de.id_comparativa
INNER JOIN public.producto_catalogo p 
    ON de.codigo_producto = p.codigo_producto
INNER JOIN public.marca m 
    ON p.id_marca = m.id_marca
ORDER BY mc.id_comparativa ASC, p.precio_referencial ASC;



-- Muestra las recomendaciones finales otorgadas al cliente,
-- incluyendo el porcentaje de compatibilidad y las indicaciones de uso.
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
INNER JOIN public.producto_catalogo p 
    ON rf.codigo_producto = p.codigo_producto
INNER JOIN public.marca m 
    ON p.id_marca = m.id_marca
ORDER BY rf.nivel_compatibilidad DESC NULLS LAST, rf.id_recomendacion ASC;



-- Evalúa cuántos perfiles de necesidad ha atendido cada asesor,
-- su especialidad y el presupuesto promedio de los clientes asignados.
SELECT 
    a.id_asesor,
    CONCAT(a.nombres, ' ', a.apellidos) AS asesor_nombre,
    a.especialidad,
    a.turno,
    COUNT(pn.id_perfil) AS total_perfiles_atendidos,
    COALESCE(ROUND(AVG(pn.presupuesto_max), 2), 0.00) AS presupuesto_promedio_atendido,
    COALESCE(SUM(pn.presupuesto_max), 0.00) AS volumen_total_presupuestos
FROM public.asesor_tecnico a
LEFT JOIN public.perfil_de_necesidad pn 
    ON a.id_asesor = pn.id_asesor
GROUP BY a.id_asesor, a.nombres, a.apellidos, a.especialidad, a.turno
ORDER BY total_perfiles_atendidos DESC, a.apellidos ASC;


-- Cruza el perfil del cliente con la recomendación final emitida
-- para calcular el ahorro o saldo a favor respecto al presupuesto tope.
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
INNER JOIN public.matriz_de_comparativa mc 
    ON rf.id_comparativa = mc.id_comparativa
INNER JOIN public.perfil_de_necesidad pn 
    ON mc.id_perfil = pn.id_perfil
INNER JOIN public.cliente c 
    ON pn.dni_cliente = c.dni_cliente
INNER JOIN public.producto_catalogo prod 
    ON rf.codigo_producto = prod.codigo_producto
ORDER BY pn.id_perfil ASC;


-- Identifica qué marcas tienen mayor presencia en el catálogo,
-- junto a sus precios máximos, mínimos y promedios.
SELECT 
    m.id_marca,
    m.nombre_marca,
    COUNT(p.codigo_producto) AS cantidad_modelos,
    MIN(p.precio_referencial) AS precio_mas_bajo,
    MAX(p.precio_referencial) AS precio_mas_alto,
    ROUND(AVG(p.precio_referencial), 2) AS precio_promedio
FROM public.marca m
INNER JOIN public.producto_catalogo p 
    ON m.id_marca = p.id_marca
GROUP BY m.id_marca, m.nombre_marca
ORDER BY cantidad_modelos DESC, precio_promedio DESC;



-- Lista los 15 artículos de mayor valor monetario registrados en
-- el sistema para análisis de inventario premium.
SELECT 
    codigo_producto,
    modelo,
    precio_referencial,
    especificaciones
FROM public.producto_catalogo
ORDER BY precio_referencial DESC
LIMIT 15;



-- Analiza los canales preferidos de los clientes (WhatsApp,
-- teléfono, correo, etc.) y calcula el peso porcentual de cada uno.
SELECT 
    COALESCE(canal_contacto, 'No especificado') AS canal_contacto,
    COUNT(*) AS cantidad_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
FROM public.cliente
GROUP BY canal_contacto
ORDER BY cantidad_clientes DESC;

/**
 * Metadatos y contenidos de código de las entregas de PostgreSQL, Python y HTML
 */

export interface ReportItem {
  id: number;
  title: string;
  hasJoin: boolean;
  tables: string[];
  description: string;
  sql: string;
  tags: string[];
}

export const REPORT_LIST: ReportItem[] = [
  {
    id: 1,
    title: "Catálogo Completo con Marca y Categoría",
    hasJoin: true,
    tables: ["producto_catalogo", "marca", "categoria"],
    description: "Lista de todos los artículos vinculando su marca y categoría, ordenados por categoría y precio referencial.",
    tags: ["3 tablas", "INNER JOIN", "Ordenamiento"],
    sql: `SELECT 
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
ORDER BY c.nombre_categoria ASC, p.precio_referencial DESC;`
  },
  {
    id: 2,
    title: "Resumen Estadístico de Precios por Categoría",
    hasJoin: true,
    tables: ["categoria", "producto_catalogo"],
    description: "Cálculo del total de productos, precio promedio, valor mínimo y máximo para cada categoría del catálogo.",
    tags: ["LEFT JOIN", "COUNT / AVG / MIN / MAX", "GROUP BY"],
    sql: `SELECT 
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
ORDER BY total_productos DESC, c.nombre_categoria ASC;`
  },
  {
    id: 3,
    title: "Perfiles de Necesidad con Cliente y Asesor Asignado",
    hasJoin: true,
    tables: ["perfil_de_necesidad", "cliente", "asesor_tecnico", "marca"],
    description: "Ficha integral de requerimientos con datos del cliente, asesor técnico asignado, turno y marca preferida.",
    tags: ["4 tablas", "INNER & LEFT JOIN", "Contacto"],
    sql: `SELECT 
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
ORDER BY pn.fecha_registro DESC, pn.id_perfil DESC;`
  },
  {
    id: 4,
    title: "Matriz Comparativa y Detalle de Evaluación Técnica",
    hasJoin: true,
    tables: ["matriz_de_comparativa", "detalle_evaluacion", "producto_catalogo", "marca"],
    description: "Criterios de evaluación técnica, diferenciales y resultados evaluados de los productos candidatos.",
    tags: ["4 tablas", "Evaluación Técnica", "INNER JOIN"],
    sql: `SELECT 
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
ORDER BY mc.id_comparativa ASC, p.precio_referencial ASC;`
  },
  {
    id: 5,
    title: "Recomendaciones Finales con Nivel de Compatibilidad",
    hasJoin: true,
    tables: ["recomendacion_final", "producto_catalogo", "marca"],
    description: "Productos recomendados al cliente con porcentaje de compatibilidad, justificación técnica e indicación de uso.",
    tags: ["Compatibilidad", "Recomendaciones", "INNER JOIN"],
    sql: `SELECT 
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
ORDER BY rf.nivel_compatibilidad DESC NULLS LAST, rf.id_recomendacion ASC;`
  },
  {
    id: 6,
    title: "Carga de Trabajo y Desempeño de Asesores Técnicos",
    hasJoin: true,
    tables: ["asesor_tecnico", "perfil_de_necesidad"],
    description: "Distribución de casos por asesor técnico, volumen y presupuesto promedio gestionado en sus turnos.",
    tags: ["LEFT JOIN", "Métricas Asesores", "Rendimiento"],
    sql: `SELECT 
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
ORDER BY total_perfiles_atendidos DESC, a.apellidos ASC;`
  },
  {
    id: 7,
    title: "Comparativa Financiera: Presupuesto vs Precio Recomendado",
    hasJoin: true,
    tables: ["recomendacion_final", "matriz_de_comparativa", "perfil_de_necesidad", "cliente", "producto_catalogo"],
    description: "Análisis financiero entre el tope máximo presupuestado por el cliente y el costo del producto recomendado.",
    tags: ["5 tablas", "CASE WHEN", "Análisis Financiero"],
    sql: `SELECT 
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
ORDER BY pn.id_perfil ASC;`
  },
  {
    id: 8,
    title: "Distribución y Rango de Precios por Marca",
    hasJoin: true,
    tables: ["marca", "producto_catalogo"],
    description: "Variedad de catálogo por fabricante con rango de precios mínimos, máximos y promedio.",
    tags: ["INNER JOIN", "Análisis por Fabricante", "GROUP BY"],
    sql: `SELECT 
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
ORDER BY cantidad_modelos DESC, precio_promedio DESC;`
  },
  {
    id: 9,
    title: "Top 15 Productos de Mayor Valor en Catálogo",
    hasJoin: false,
    tables: ["producto_catalogo"],
    description: "Consulta analítica directa que extrae los equipos de más alta gama y mayor precio referencial.",
    tags: ["Consulta Directa", "ORDER BY DESC", "LIMIT 15"],
    sql: `SELECT 
    codigo_producto,
    modelo,
    precio_referencial,
    especificaciones
FROM public.producto_catalogo
ORDER BY precio_referencial DESC
LIMIT 15;`
  },
  {
    id: 10,
    title: "Distribución de Clientes por Canal de Contacto",
    hasJoin: false,
    tables: ["cliente"],
    description: "Análisis de canales de entrada de clientes con cálculo porcentual acumulativo sobre el total.",
    tags: ["Window Function", "OVER()", "Porcentajes"],
    sql: `SELECT 
    COALESCE(canal_contacto, 'No especificado') AS canal_contacto,
    COUNT(*) AS cantidad_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
FROM public.cliente
GROUP BY canal_contacto
ORDER BY cantidad_clientes DESC;`
  }
];

export const SQL_FILES = {
  procedimientos_y_triggers: "database/solucion_postgresql.sql",
  reportes_sql: "database/reportes.sql",
  servidor_python: "python_backend/app.py",
  interfaz_html: "public/index_standalone.html",
  instrucciones_readme: "README.md"
};

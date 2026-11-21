-- ============================================================================
-- GLOWTECH - SISTEMA DE ASESORAMIENTO TÉCNICO (PostgreSQL PL/pgSQL)
-- Archivo: database/solucion_postgresql.sql
-- Contenido:
--   - Índices de rendimiento
--   - 27 Stored Procedures (CRUD completo para las 9 tablas del modelo 3FN)
--   - 5 Triggers de validación de reglas de negocio
-- Nota: Este script es idempotente (puede ejecutarse múltiples veces).
-- ============================================================================

-- ============================================================================
-- 0. ÍNDICES ESTRATÉGICOS DE RENDIMIENTO
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_producto_marca ON public.producto_catalogo (id_marca);
CREATE INDEX IF NOT EXISTS idx_producto_categoria ON public.producto_catalogo (id_categoria);
CREATE INDEX IF NOT EXISTS idx_producto_precio ON public.producto_catalogo (precio_referencial);
CREATE INDEX IF NOT EXISTS idx_perfil_cliente ON public.perfil_de_necesidad (dni_cliente);
CREATE INDEX IF NOT EXISTS idx_perfil_asesor ON public.perfil_de_necesidad (id_asesor);
CREATE INDEX IF NOT EXISTS idx_perfil_fecha ON public.perfil_de_necesidad (fecha_registro DESC);
CREATE INDEX IF NOT EXISTS idx_matriz_perfil ON public.matriz_de_comparativa (id_perfil);
CREATE INDEX IF NOT EXISTS idx_recomendacion_comp ON public.recomendacion_final (id_comparativa);
CREATE INDEX IF NOT EXISTS idx_recomendacion_prod ON public.recomendacion_final (codigo_producto);

-- ============================================================================
-- 1. STORED PROCEDURES: ENTIDAD CLIENTE (Inserción, Modificación, Borrado)
-- ============================================================================

-- 1.1 Inserción de Cliente
CREATE OR REPLACE PROCEDURE public.sp_insertar_cliente(
    IN p_dni CHARACTER(8),
    IN p_nombres VARCHAR(80),
    IN p_apellidos VARCHAR(80),
    IN p_canal_contacto VARCHAR(30),
    IN p_telefono VARCHAR(15),
    IN p_correo VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_dni IS NULL OR LENGTH(TRIM(p_dni)) <> 8 THEN
        RAISE EXCEPTION 'El DNI del cliente debe tener exactamente 8 caracteres.';
    END IF;

    IF p_nombres IS NULL OR TRIM(p_nombres) = '' OR p_apellidos IS NULL OR TRIM(p_apellidos) = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos son campos obligatorios.';
    END IF;

    INSERT INTO public.cliente (
        dni_cliente,
        nombres,
        apellidos,
        canal_contacto,
        telefono,
        correo
    )
    VALUES (
        TRIM(p_dni),
        TRIM(p_nombres),
        TRIM(p_apellidos),
        NULLIF(TRIM(COALESCE(p_canal_contacto, '')), ''),
        NULLIF(TRIM(COALESCE(p_telefono, '')), ''),
        LOWER(NULLIF(TRIM(COALESCE(p_correo, '')), ''))
    );

    RAISE NOTICE 'Cliente con DNI % insertado exitosamente.', TRIM(p_dni);
END;
$$;

-- 1.2 Modificación de Cliente
CREATE OR REPLACE PROCEDURE public.sp_modificar_cliente(
    IN p_dni CHARACTER(8),
    IN p_nombres VARCHAR(80),
    IN p_apellidos VARCHAR(80),
    IN p_canal_contacto VARCHAR(30),
    IN p_telefono VARCHAR(15),
    IN p_correo VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No se encontró el cliente con DNI % para modificar.', p_dni;
    END IF;

    IF p_nombres IS NULL OR TRIM(p_nombres) = '' OR p_apellidos IS NULL OR TRIM(p_apellidos) = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos son campos obligatorios.';
    END IF;

    UPDATE public.cliente
    SET
        nombres = TRIM(p_nombres),
        apellidos = TRIM(p_apellidos),
        canal_contacto = NULLIF(TRIM(COALESCE(p_canal_contacto, '')), ''),
        telefono = NULLIF(TRIM(COALESCE(p_telefono, '')), ''),
        correo = LOWER(NULLIF(TRIM(COALESCE(p_correo, '')), ''))
    WHERE dni_cliente = TRIM(p_dni);

    RAISE NOTICE 'Cliente con DNI % modificado exitosamente.', TRIM(p_dni);
END;
$$;

-- 1.3 Borrado de Cliente
CREATE OR REPLACE PROCEDURE public.sp_eliminar_cliente(
    IN p_dni CHARACTER(8)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No existe el cliente con DNI % que se desea eliminar.', p_dni;
    END IF;

    IF EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No se puede eliminar el cliente con DNI % porque tiene perfiles de necesidad vinculados.', p_dni;
    END IF;

    DELETE FROM public.cliente
    WHERE dni_cliente = TRIM(p_dni);

    RAISE NOTICE 'Cliente con DNI % eliminado exitosamente.', TRIM(p_dni);
END;
$$;

-- ============================================================================
-- 2. STORED PROCEDURES: ENTIDAD PRODUCTO_CATALOGO (Inserción, Modificación, Borrado)
-- ============================================================================

-- 2.1 Inserción de Producto
CREATE OR REPLACE PROCEDURE public.sp_insertar_producto(
    IN p_codigo VARCHAR(20),
    IN p_modelo VARCHAR(80),
    IN p_especificaciones TEXT,
    IN p_precio NUMERIC(10,2),
    IN p_id_marca INT,
    IN p_id_categoria INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_codigo IS NULL OR TRIM(p_codigo) = '' THEN
        RAISE EXCEPTION 'El código de producto no puede estar vacío.';
    END IF;

    IF p_modelo IS NULL OR TRIM(p_modelo) = '' THEN
        RAISE EXCEPTION 'El modelo del producto no puede estar vacío.';
    END IF;

    IF p_precio IS NULL OR p_precio < 0 THEN
        RAISE EXCEPTION 'El precio referencial no puede ser negativo.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca indicada (ID: %) no existe.', p_id_marca;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.categoria WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoría indicada (ID: %) no existe.', p_id_categoria;
    END IF;

    INSERT INTO public.producto_catalogo (
        codigo_producto,
        modelo,
        especificaciones,
        precio_referencial,
        id_marca,
        id_categoria
    )
    VALUES (
        TRIM(p_codigo),
        TRIM(p_modelo),
        NULLIF(TRIM(COALESCE(p_especificaciones, '')), ''),
        p_precio,
        p_id_marca,
        p_id_categoria
    );

    RAISE NOTICE 'Producto % insertado exitosamente.', TRIM(p_codigo);
END;
$$;

-- 2.2 Modificación de Producto
CREATE OR REPLACE PROCEDURE public.sp_modificar_producto(
    IN p_codigo VARCHAR(20),
    IN p_modelo VARCHAR(80),
    IN p_especificaciones TEXT,
    IN p_precio NUMERIC(10,2),
    IN p_id_marca INT,
    IN p_id_categoria INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.producto_catalogo WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No se encontró el producto con código % para modificar.', p_codigo;
    END IF;

    IF p_precio IS NULL OR p_precio < 0 THEN
        RAISE EXCEPTION 'El precio referencial no puede ser negativo.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca indicada (ID: %) no existe.', p_id_marca;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.categoria WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoría indicada (ID: %) no existe.', p_id_categoria;
    END IF;

    UPDATE public.producto_catalogo
    SET
        modelo = TRIM(p_modelo),
        especificaciones = NULLIF(TRIM(COALESCE(p_especificaciones, '')), ''),
        precio_referencial = p_precio,
        id_marca = p_id_marca,
        id_categoria = p_id_categoria
    WHERE codigo_producto = TRIM(p_codigo);

    RAISE NOTICE 'Producto % modificado correctamente.', TRIM(p_codigo);
END;
$$;

-- 2.3 Borrado de Producto
CREATE OR REPLACE PROCEDURE public.sp_eliminar_producto(
    IN p_codigo VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.producto_catalogo WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No existe el producto % para eliminar.', p_codigo;
    END IF;

    IF EXISTS (SELECT 1 FROM public.detalle_evaluacion WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No se puede eliminar el producto % porque está referenciado en evaluaciones técnicas.', p_codigo;
    END IF;

    IF EXISTS (SELECT 1 FROM public.recomendacion_final WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No se puede eliminar el producto % porque está registrado como recomendación final.', p_codigo;
    END IF;

    DELETE FROM public.producto_catalogo
    WHERE codigo_producto = TRIM(p_codigo);

    RAISE NOTICE 'Producto % eliminado correctamente.', TRIM(p_codigo);
END;
$$;

-- ============================================================================
-- 3. STORED PROCEDURES: ENTIDAD PERFIL_DE_NECESIDAD
-- ============================================================================

-- 3.1 Inserción de Perfil de Necesidad
CREATE OR REPLACE PROCEDURE public.sp_insertar_perfil_necesidad(
    IN p_uso_principal VARCHAR(100),
    IN p_presupuesto_max NUMERIC(10,2),
    IN p_restriccion_tecnica VARCHAR(255),
    IN p_dni_cliente CHARACTER(8),
    IN p_id_asesor INT,
    IN p_id_marca INT,
    INOUT p_id_perfil INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE dni_cliente = TRIM(p_dni_cliente)) THEN
        RAISE EXCEPTION 'El cliente con DNI % no existe en la base de datos.', p_dni_cliente;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.asesor_tecnico WHERE id_asesor = p_id_asesor) THEN
        RAISE EXCEPTION 'El asesor técnico con ID % no existe.', p_id_asesor;
    END IF;

    IF p_id_marca IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca preferida indicada (ID: %) no existe.', p_id_marca;
    END IF;

    INSERT INTO public.perfil_de_necesidad (
        uso_principal,
        presupuesto_max,
        restriccion_tecnica,
        fecha_registro,
        dni_cliente,
        id_asesor,
        id_marca
    )
    VALUES (
        TRIM(COALESCE(p_uso_principal, '')),
        p_presupuesto_max,
        NULLIF(TRIM(COALESCE(p_restriccion_tecnica, '')), ''),
        CURRENT_DATE,
        TRIM(p_dni_cliente),
        p_id_asesor,
        p_id_marca
    )
    RETURNING id_perfil INTO p_id_perfil;

    RAISE NOTICE 'Perfil de necesidad creado exitosamente con ID %', p_id_perfil;
END;
$$;

-- 3.2 Modificación de Perfil de Necesidad
CREATE OR REPLACE PROCEDURE public.sp_modificar_perfil_necesidad(
    IN p_id_perfil INT,
    IN p_uso_principal VARCHAR(100),
    IN p_presupuesto_max NUMERIC(10,2),
    IN p_restriccion_tecnica VARCHAR(255),
    IN p_id_marca INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'No se encontró el perfil de necesidad con ID %.', p_id_perfil;
    END IF;

    IF p_id_marca IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'La marca preferida indicada (ID: %) no existe.', p_id_marca;
    END IF;

    UPDATE public.perfil_de_necesidad
    SET
        uso_principal = TRIM(COALESCE(p_uso_principal, '')),
        presupuesto_max = p_presupuesto_max,
        restriccion_tecnica = NULLIF(TRIM(COALESCE(p_restriccion_tecnica, '')), ''),
        id_marca = p_id_marca
    WHERE id_perfil = p_id_perfil;

    RAISE NOTICE 'Perfil de necesidad ID % modificado correctamente.', p_id_perfil;
END;
$$;

-- 3.3 Borrado de Perfil de Necesidad
CREATE OR REPLACE PROCEDURE public.sp_eliminar_perfil_necesidad(
    IN p_id_perfil INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'No existe el perfil de necesidad con ID % para eliminar.', p_id_perfil;
    END IF;

    IF EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'No se puede eliminar el perfil % porque tiene comparativas asociadas.', p_id_perfil;
    END IF;

    DELETE FROM public.perfil_de_necesidad
    WHERE id_perfil = p_id_perfil;

    RAISE NOTICE 'Perfil de necesidad ID % eliminado correctamente.', p_id_perfil;
END;
$$;

-- ============================================================================
-- 4. STORED PROCEDURES: ENTIDAD CATEGORIA
-- ============================================================================

-- 4.1 Inserción de Categoría
CREATE OR REPLACE PROCEDURE public.sp_insertar_categoria(
    IN p_nombre_categoria VARCHAR(60),
    INOUT p_id_categoria INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_nombre_categoria IS NULL OR TRIM(p_nombre_categoria) = '' THEN
        RAISE EXCEPTION 'El nombre de la categoría no puede estar vacío.';
    END IF;

    INSERT INTO public.categoria (nombre_categoria)
    VALUES (UPPER(TRIM(p_nombre_categoria)))
    RETURNING id_categoria INTO p_id_categoria;

    RAISE NOTICE 'Categoría creada con ID %.', p_id_categoria;
END;
$$;

-- 4.2 Modificación de Categoría
CREATE OR REPLACE PROCEDURE public.sp_modificar_categoria(
    IN p_id_categoria INT,
    IN p_nombre_categoria VARCHAR(60)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.categoria WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'No existe la categoría con ID %.', p_id_categoria;
    END IF;

    IF p_nombre_categoria IS NULL OR TRIM(p_nombre_categoria) = '' THEN
        RAISE EXCEPTION 'El nombre de la categoría no puede estar vacío.';
    END IF;

    UPDATE public.categoria
    SET nombre_categoria = UPPER(TRIM(p_nombre_categoria))
    WHERE id_categoria = p_id_categoria;

    RAISE NOTICE 'Categoría ID % modificada correctamente.', p_id_categoria;
END;
$$;

-- 4.3 Borrado de Categoría
CREATE OR REPLACE PROCEDURE public.sp_eliminar_categoria(
    IN p_id_categoria INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.categoria WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'No existe la categoría con ID % para eliminar.', p_id_categoria;
    END IF;

    IF EXISTS (SELECT 1 FROM public.producto_catalogo WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'No se puede eliminar la categoría ID % porque tiene productos asociados.', p_id_categoria;
    END IF;

    DELETE FROM public.categoria
    WHERE id_categoria = p_id_categoria;

    RAISE NOTICE 'Categoría ID % eliminada correctamente.', p_id_categoria;
END;
$$;

-- ============================================================================
-- 5. STORED PROCEDURES: ENTIDAD MARCA
-- ============================================================================

-- 5.1 Inserción de Marca
CREATE OR REPLACE PROCEDURE public.sp_insertar_marca(
    IN p_nombre_marca VARCHAR(60),
    INOUT p_id_marca INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_nombre_marca IS NULL OR TRIM(p_nombre_marca) = '' THEN
        RAISE EXCEPTION 'El nombre de la marca no puede estar vacío.';
    END IF;

    INSERT INTO public.marca (nombre_marca)
    VALUES (UPPER(TRIM(p_nombre_marca)))
    RETURNING id_marca INTO p_id_marca;

    RAISE NOTICE 'Marca creada con ID %.', p_id_marca;
END;
$$;

-- 5.2 Modificación de Marca
CREATE OR REPLACE PROCEDURE public.sp_modificar_marca(
    IN p_id_marca INT,
    IN p_nombre_marca VARCHAR(60)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'No existe la marca con ID %.', p_id_marca;
    END IF;

    IF p_nombre_marca IS NULL OR TRIM(p_nombre_marca) = '' THEN
        RAISE EXCEPTION 'El nombre de la marca no puede estar vacío.';
    END IF;

    UPDATE public.marca
    SET nombre_marca = UPPER(TRIM(p_nombre_marca))
    WHERE id_marca = p_id_marca;

    RAISE NOTICE 'Marca ID % modificada correctamente.', p_id_marca;
END;
$$;

-- 5.3 Borrado de Marca
CREATE OR REPLACE PROCEDURE public.sp_eliminar_marca(
    IN p_id_marca INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.marca WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'No existe la marca con ID % para eliminar.', p_id_marca;
    END IF;

    IF EXISTS (SELECT 1 FROM public.producto_catalogo WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'No se puede eliminar la marca ID % porque tiene productos asociados.', p_id_marca;
    END IF;

    IF EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_marca = p_id_marca) THEN
        RAISE EXCEPTION 'No se puede eliminar la marca ID % porque está referenciada en perfiles de necesidad.', p_id_marca;
    END IF;

    DELETE FROM public.marca
    WHERE id_marca = p_id_marca;

    RAISE NOTICE 'Marca ID % eliminada correctamente.', p_id_marca;
END;
$$;

-- ============================================================================
-- 6. STORED PROCEDURES: ENTIDAD ASESOR_TECNICO
-- ============================================================================

-- 6.1 Inserción de Asesor Técnico
CREATE OR REPLACE PROCEDURE public.sp_insertar_asesor(
    IN p_nombres VARCHAR(80),
    IN p_apellidos VARCHAR(80),
    IN p_especialidad VARCHAR(60),
    IN p_turno VARCHAR(10),
    INOUT p_id_asesor INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_nombres IS NULL OR TRIM(p_nombres) = '' OR p_apellidos IS NULL OR TRIM(p_apellidos) = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos del asesor son obligatorios.';
    END IF;

    INSERT INTO public.asesor_tecnico (nombres, apellidos, especialidad, turno)
    VALUES (
        TRIM(p_nombres),
        TRIM(p_apellidos),
        NULLIF(TRIM(COALESCE(p_especialidad, '')), ''),
        UPPER(NULLIF(TRIM(COALESCE(p_turno, '')), ''))
    )
    RETURNING id_asesor INTO p_id_asesor;

    RAISE NOTICE 'Asesor técnico creado con ID %.', p_id_asesor;
END;
$$;

-- 6.2 Modificación de Asesor Técnico
CREATE OR REPLACE PROCEDURE public.sp_modificar_asesor(
    IN p_id_asesor INT,
    IN p_nombres VARCHAR(80),
    IN p_apellidos VARCHAR(80),
    IN p_especialidad VARCHAR(60),
    IN p_turno VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.asesor_tecnico WHERE id_asesor = p_id_asesor) THEN
        RAISE EXCEPTION 'No existe el asesor técnico con ID %.', p_id_asesor;
    END IF;

    UPDATE public.asesor_tecnico
    SET
        nombres = TRIM(p_nombres),
        apellidos = TRIM(p_apellidos),
        especialidad = NULLIF(TRIM(COALESCE(p_especialidad, '')), ''),
        turno = UPPER(NULLIF(TRIM(COALESCE(p_turno, '')), ''))
    WHERE id_asesor = p_id_asesor;

    RAISE NOTICE 'Asesor técnico ID % modificado correctamente.', p_id_asesor;
END;
$$;

-- 6.3 Borrado de Asesor Técnico
CREATE OR REPLACE PROCEDURE public.sp_eliminar_asesor(
    IN p_id_asesor INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.asesor_tecnico WHERE id_asesor = p_id_asesor) THEN
        RAISE EXCEPTION 'No existe el asesor técnico con ID % para eliminar.', p_id_asesor;
    END IF;

    IF EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_asesor = p_id_asesor) THEN
        RAISE EXCEPTION 'No se puede eliminar el asesor ID % porque tiene perfiles de necesidad asignados.', p_id_asesor;
    END IF;

    DELETE FROM public.asesor_tecnico
    WHERE id_asesor = p_id_asesor;

    RAISE NOTICE 'Asesor técnico ID % eliminado correctamente.', p_id_asesor;
END;
$$;

-- ============================================================================
-- 7. STORED PROCEDURES: ENTIDAD MATRIZ_DE_COMPARATIVA
-- ============================================================================

-- 7.1 Inserción de Matriz de Comparativa
CREATE OR REPLACE PROCEDURE public.sp_insertar_matriz(
    IN p_criterio_evaluacion VARCHAR(150),
    IN p_diferencial_tecnico TEXT,
    IN p_id_perfil INT,
    INOUT p_id_comparativa INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'El perfil de necesidad con ID % no existe.', p_id_perfil;
    END IF;

    IF p_criterio_evaluacion IS NULL OR TRIM(p_criterio_evaluacion) = '' THEN
        RAISE EXCEPTION 'El criterio de evaluación es obligatorio.';
    END IF;

    INSERT INTO public.matriz_de_comparativa (criterio_evaluacion, diferencial_tecnico, id_perfil)
    VALUES (
        TRIM(p_criterio_evaluacion),
        NULLIF(TRIM(COALESCE(p_diferencial_tecnico, '')), ''),
        p_id_perfil
    )
    RETURNING id_comparativa INTO p_id_comparativa;

    RAISE NOTICE 'Matriz de comparativa creada con ID %.', p_id_comparativa;
END;
$$;

-- 7.2 Modificación de Matriz de Comparativa
CREATE OR REPLACE PROCEDURE public.sp_modificar_matriz(
    IN p_id_comparativa INT,
    IN p_criterio_evaluacion VARCHAR(150),
    IN p_diferencial_tecnico TEXT,
    IN p_id_perfil INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'No existe la matriz de comparativa con ID %.', p_id_comparativa;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'El perfil de necesidad con ID % no existe.', p_id_perfil;
    END IF;

    UPDATE public.matriz_de_comparativa
    SET
        criterio_evaluacion = TRIM(p_criterio_evaluacion),
        diferencial_tecnico = NULLIF(TRIM(COALESCE(p_diferencial_tecnico, '')), ''),
        id_perfil = p_id_perfil
    WHERE id_comparativa = p_id_comparativa;

    RAISE NOTICE 'Matriz de comparativa ID % modificada correctamente.', p_id_comparativa;
END;
$$;

-- 7.3 Borrado de Matriz de Comparativa
CREATE OR REPLACE PROCEDURE public.sp_eliminar_matriz(
    IN p_id_comparativa INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'No existe la matriz de comparativa con ID % para eliminar.', p_id_comparativa;
    END IF;

    IF EXISTS (SELECT 1 FROM public.detalle_evaluacion WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'No se puede eliminar la matriz ID % porque tiene detalles de evaluación vinculados.', p_id_comparativa;
    END IF;

    IF EXISTS (SELECT 1 FROM public.recomendacion_final WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'No se puede eliminar la matriz ID % porque tiene recomendaciones finales vinculadas.', p_id_comparativa;
    END IF;

    DELETE FROM public.matriz_de_comparativa
    WHERE id_comparativa = p_id_comparativa;

    RAISE NOTICE 'Matriz de comparativa ID % eliminada correctamente.', p_id_comparativa;
END;
$$;

-- ============================================================================
-- 8. STORED PROCEDURES: ENTIDAD DETALLE_EVALUACION
-- ============================================================================

-- 8.1 Inserción de Detalle de Evaluación
CREATE OR REPLACE PROCEDURE public.sp_insertar_detalle_evaluacion(
    IN p_id_comparativa INT,
    IN p_codigo_producto VARCHAR(20),
    IN p_resultado_evaluacion VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'La matriz comparativa con ID % no existe.', p_id_comparativa;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.producto_catalogo WHERE codigo_producto = TRIM(p_codigo_producto)) THEN
        RAISE EXCEPTION 'El producto % no existe en el catálogo.', p_codigo_producto;
    END IF;

    INSERT INTO public.detalle_evaluacion (id_comparativa, codigo_producto, resultado_evaluacion)
    VALUES (
        p_id_comparativa,
        TRIM(p_codigo_producto),
        NULLIF(TRIM(COALESCE(p_resultado_evaluacion, '')), '')
    );

    RAISE NOTICE 'Evaluación registrada para matriz % y producto %.', p_id_comparativa, TRIM(p_codigo_producto);
END;
$$;

-- 8.2 Modificación de Detalle de Evaluación
CREATE OR REPLACE PROCEDURE public.sp_modificar_detalle_evaluacion(
    IN p_id_comparativa INT,
    IN p_codigo_producto VARCHAR(20),
    IN p_resultado_evaluacion VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.detalle_evaluacion
        WHERE id_comparativa = p_id_comparativa AND codigo_producto = TRIM(p_codigo_producto)
    ) THEN
        RAISE EXCEPTION 'No existe el detalle de evaluación para matriz % y producto %.', p_id_comparativa, p_codigo_producto;
    END IF;

    UPDATE public.detalle_evaluacion
    SET resultado_evaluacion = NULLIF(TRIM(COALESCE(p_resultado_evaluacion, '')), '')
    WHERE id_comparativa = p_id_comparativa AND codigo_producto = TRIM(p_codigo_producto);

    RAISE NOTICE 'Detalle de evaluación actualizado.';
END;
$$;

-- 8.3 Borrado de Detalle de Evaluación
CREATE OR REPLACE PROCEDURE public.sp_eliminar_detalle_evaluacion(
    IN p_id_comparativa INT,
    IN p_codigo_producto VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.detalle_evaluacion
        WHERE id_comparativa = p_id_comparativa AND codigo_producto = TRIM(p_codigo_producto)
    ) THEN
        RAISE EXCEPTION 'No existe el detalle de evaluación para matriz % y producto %.', p_id_comparativa, p_codigo_producto;
    END IF;

    DELETE FROM public.detalle_evaluacion
    WHERE id_comparativa = p_id_comparativa AND codigo_producto = TRIM(p_codigo_producto);

    RAISE NOTICE 'Detalle de evaluación eliminado.';
END;
$$;

-- ============================================================================
-- 9. STORED PROCEDURES: ENTIDAD RECOMENDACION_FINAL
-- ============================================================================

-- 9.1 Inserción de Recomendación Final
CREATE OR REPLACE PROCEDURE public.sp_insertar_recomendacion(
    IN p_justificacion_tecnica TEXT,
    IN p_indicacion_uso TEXT,
    IN p_nivel_compatibilidad NUMERIC(5,2),
    IN p_id_comparativa INT,
    IN p_codigo_producto VARCHAR(20),
    INOUT p_id_recomendacion INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'La matriz comparativa con ID % no existe.', p_id_comparativa;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.producto_catalogo WHERE codigo_producto = TRIM(p_codigo_producto)) THEN
        RAISE EXCEPTION 'El producto % no existe en el catálogo.', p_codigo_producto;
    END IF;

    INSERT INTO public.recomendacion_final (
        justificacion_tecnica,
        indicacion_uso,
        nivel_compatibilidad,
        id_comparativa,
        codigo_producto
    )
    VALUES (
        TRIM(COALESCE(p_justificacion_tecnica, '')),
        NULLIF(TRIM(COALESCE(p_indicacion_uso, '')), ''),
        p_nivel_compatibilidad,
        p_id_comparativa,
        TRIM(p_codigo_producto)
    )
    RETURNING id_recomendacion INTO p_id_recomendacion;

    RAISE NOTICE 'Recomendación final creada con ID %.', p_id_recomendacion;
END;
$$;

-- 9.2 Modificación de Recomendación Final
CREATE OR REPLACE PROCEDURE public.sp_modificar_recomendacion(
    IN p_id_recomendacion INT,
    IN p_justificacion_tecnica TEXT,
    IN p_indicacion_uso TEXT,
    IN p_nivel_compatibilidad NUMERIC(5,2),
    IN p_id_comparativa INT,
    IN p_codigo_producto VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.recomendacion_final WHERE id_recomendacion = p_id_recomendacion) THEN
        RAISE EXCEPTION 'No existe la recomendación final con ID %.', p_id_recomendacion;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_comparativa = p_id_comparativa) THEN
        RAISE EXCEPTION 'La matriz comparativa con ID % no existe.', p_id_comparativa;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.producto_catalogo WHERE codigo_producto = TRIM(p_codigo_producto)) THEN
        RAISE EXCEPTION 'El producto % no existe en el catálogo.', p_codigo_producto;
    END IF;

    UPDATE public.recomendacion_final
    SET
        justificacion_tecnica = TRIM(COALESCE(p_justificacion_tecnica, '')),
        indicacion_uso = NULLIF(TRIM(COALESCE(p_indicacion_uso, '')), ''),
        nivel_compatibilidad = p_nivel_compatibilidad,
        id_comparativa = p_id_comparativa,
        codigo_producto = TRIM(p_codigo_producto)
    WHERE id_recomendacion = p_id_recomendacion;

    RAISE NOTICE 'Recomendación final ID % modificada correctamente.', p_id_recomendacion;
END;
$$;

-- 9.3 Borrado de Recomendación Final
CREATE OR REPLACE PROCEDURE public.sp_eliminar_recomendacion(
    IN p_id_recomendacion INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.recomendacion_final WHERE id_recomendacion = p_id_recomendacion) THEN
        RAISE EXCEPTION 'No existe la recomendación final con ID % para eliminar.', p_id_recomendacion;
    END IF;

    DELETE FROM public.recomendacion_final
    WHERE id_recomendacion = p_id_recomendacion;

    RAISE NOTICE 'Recomendación final ID % eliminada correctamente.', p_id_recomendacion;
END;
$$;

-- ============================================================================
-- 10. TRIGGERS DE VALIDACIÓN DE REGLAS DE NEGOCIO (5 TRIGGERS)
-- ============================================================================

-- TRIGGER 1: Validación de Perfil de Necesidad
CREATE OR REPLACE FUNCTION public.fn_validar_perfil_necesidad()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.presupuesto_max IS NULL OR NEW.presupuesto_max <= 0 THEN
        RAISE EXCEPTION 'Regla de negocio infringida: El presupuesto máximo debe ser mayor a 0 (recibido: %).',
            NEW.presupuesto_max;
    END IF;

    IF NEW.fecha_registro IS NULL THEN
        NEW.fecha_registro := CURRENT_DATE;
    ELSIF NEW.fecha_registro > CURRENT_DATE THEN
        RAISE EXCEPTION 'Regla de negocio infringida: La fecha de registro (%) no puede ser futura.',
            NEW.fecha_registro;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_perfil ON public.perfil_de_necesidad;
CREATE TRIGGER trg_validar_perfil
    BEFORE INSERT OR UPDATE
    ON public.perfil_de_necesidad
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validar_perfil_necesidad();

-- TRIGGER 2: Validación de Cliente
CREATE OR REPLACE FUNCTION public.fn_validar_cliente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.dni_cliente IS NULL OR NEW.dni_cliente !~ '^[0-9]{8}$' THEN
        RAISE EXCEPTION 'DNI inválido: % (debe contener exactamente 8 números).', NEW.dni_cliente;
    END IF;

    NEW.nombres := TRIM(NEW.nombres);
    NEW.apellidos := TRIM(NEW.apellidos);
    IF NEW.nombres = '' OR NEW.apellidos = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos del cliente no pueden quedar vacíos.';
    END IF;

    IF NEW.correo IS NOT NULL THEN
        NEW.correo := LOWER(TRIM(NEW.correo));
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_cliente ON public.cliente;
CREATE TRIGGER trg_validar_cliente
    BEFORE INSERT OR UPDATE
    ON public.cliente
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validar_cliente();

-- TRIGGER 3: Validación de Producto Catálogo
CREATE OR REPLACE FUNCTION public.fn_validar_producto()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.codigo_producto IS NULL OR TRIM(NEW.codigo_producto) = '' THEN
        RAISE EXCEPTION 'El código de producto no puede estar vacío.';
    END IF;

    IF NEW.modelo IS NULL OR TRIM(NEW.modelo) = '' THEN
        RAISE EXCEPTION 'El modelo del producto no puede estar vacío.';
    END IF;

    IF NEW.precio_referencial IS NULL OR NEW.precio_referencial < 0 THEN
        RAISE EXCEPTION 'El precio referencial no puede ser negativo (recibido: %).', NEW.precio_referencial;
    END IF;

    NEW.codigo_producto := TRIM(NEW.codigo_producto);
    NEW.modelo := TRIM(NEW.modelo);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_producto ON public.producto_catalogo;
CREATE TRIGGER trg_validar_producto
    BEFORE INSERT OR UPDATE
    ON public.producto_catalogo
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validar_producto();

-- TRIGGER 4: Validación de Asesor Técnico
CREATE OR REPLACE FUNCTION public.fn_validar_asesor()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.nombres IS NULL OR TRIM(NEW.nombres) = '' OR NEW.apellidos IS NULL OR TRIM(NEW.apellidos) = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos del asesor técnico son obligatorios.';
    END IF;

    NEW.nombres := TRIM(NEW.nombres);
    NEW.apellidos := TRIM(NEW.apellidos);

    IF NEW.turno IS NOT NULL AND TRIM(NEW.turno) <> '' THEN
        NEW.turno := UPPER(TRIM(NEW.turno));
        IF NEW.turno NOT IN ('MANANA', 'TARDE', 'NOCHE', 'COMPLETO') THEN
            RAISE EXCEPTION 'Turno inválido: % (valores permitidos: MANANA, TARDE, NOCHE, COMPLETO).', NEW.turno;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_asesor ON public.asesor_tecnico;
CREATE TRIGGER trg_validar_asesor
    BEFORE INSERT OR UPDATE
    ON public.asesor_tecnico
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validar_asesor();

-- TRIGGER 5: Validación de Recomendación Final
CREATE OR REPLACE FUNCTION public.fn_validar_recomendacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.justificacion_tecnica IS NULL OR TRIM(NEW.justificacion_tecnica) = '' THEN
        RAISE EXCEPTION 'Regla de negocio infringida: La justificación técnica es obligatoria en la recomendación final.';
    END IF;

    IF NEW.nivel_compatibilidad IS NOT NULL AND (NEW.nivel_compatibilidad < 0 OR NEW.nivel_compatibilidad > 100) THEN
        RAISE EXCEPTION 'Regla de negocio infringida: El nivel de compatibilidad debe estar entre 0 y 100 (recibido: %).',
            NEW.nivel_compatibilidad;
    END IF;

    NEW.justificacion_tecnica := TRIM(NEW.justificacion_tecnica);
    IF NEW.indicacion_uso IS NOT NULL THEN
        NEW.indicacion_uso := TRIM(NEW.indicacion_uso);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_recomendacion ON public.recomendacion_final;
CREATE TRIGGER trg_validar_recomendacion
    BEFORE INSERT OR UPDATE
    ON public.recomendacion_final
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validar_recomendacion();

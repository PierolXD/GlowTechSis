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
    -- Validaciones básicas de entrada
    IF p_dni IS NULL OR LENGTH(TRIM(p_dni)) <> 8 THEN
        RAISE EXCEPTION 'El DNI del cliente debe tener exactamente 8 caracteres.';
    END IF;

    IF TRIM(p_nombres) = '' OR TRIM(p_apellidos) = '' THEN
        RAISE EXCEPTION 'Nombres y apellidos son campos obligatorios.';
    END IF;

    -- Inserción en la tabla
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
        NULLIF(TRIM(p_canal_contacto), ''),
        NULLIF(TRIM(p_telefono), ''),
        LOWER(NULLIF(TRIM(p_correo), ''))
    );

    RAISE NOTICE 'Cliente con DNI % insertado exitosamente.', p_dni;
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
    -- Verificar si existe el cliente
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No se encontró el cliente con DNI % para modificar.', p_dni;
    END IF;

    -- Actualizar registros
    UPDATE public.cliente
    SET
        nombres = TRIM(p_nombres),
        apellidos = TRIM(p_apellidos),
        canal_contacto = NULLIF(TRIM(p_canal_contacto), ''),
        telefono = NULLIF(TRIM(p_telefono), ''),
        correo = LOWER(NULLIF(TRIM(p_correo), ''))
    WHERE dni_cliente = TRIM(p_dni);

    RAISE NOTICE 'Cliente con DNI % modificado exitosamente.', p_dni;
END;
$$;

-- 1.3 Borrado de Cliente
CREATE OR REPLACE PROCEDURE public.sp_eliminar_cliente(
    IN p_dni CHARACTER(8)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No existe el cliente con DNI % que se desea eliminar.', p_dni;
    END IF;

    -- Verificar integridad referencial antes de borrar
    IF EXISTS (SELECT 1 FROM public.perfil_de_necesidad WHERE dni_cliente = TRIM(p_dni)) THEN
        RAISE EXCEPTION 'No se puede eliminar el cliente con DNI % porque tiene perfiles de necesidad vinculados.', p_dni;
    END IF;

    -- Eliminación
    DELETE FROM public.cliente
    WHERE dni_cliente = TRIM(p_dni);

    RAISE NOTICE 'Cliente con DNI % eliminado exitosamente.', p_dni;
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
    -- Validaciones de entrada
    IF p_codigo IS NULL OR TRIM(p_codigo) = '' THEN
        RAISE EXCEPTION 'El código de producto no puede estar vacío.';
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

    -- Inserción
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
        p_especificaciones,
        p_precio,
        p_id_marca,
        p_id_categoria
    );

    RAISE NOTICE 'Producto % insertado exitosamente.', p_codigo;
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

    IF p_precio < 0 THEN
        RAISE EXCEPTION 'El precio referencial no puede ser negativo.';
    END IF;

    UPDATE public.producto_catalogo
    SET
        modelo = TRIM(p_modelo),
        especificaciones = p_especificaciones,
        precio_referencial = p_precio,
        id_marca = p_id_marca,
        id_categoria = p_id_categoria
    WHERE codigo_producto = TRIM(p_codigo);

    RAISE NOTICE 'Producto % modificado correctamente.', p_codigo;
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

    -- Verificar dependencias en detalle_evaluacion y recomendacion_final
    IF EXISTS (SELECT 1 FROM public.detalle_evaluacion WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No se puede eliminar el producto % porque está referenciado en evaluaciones técnicas.', p_codigo;
    END IF;

    IF EXISTS (SELECT 1 FROM public.recomendacion_final WHERE codigo_producto = TRIM(p_codigo)) THEN
        RAISE EXCEPTION 'No se puede eliminar el producto % porque está registrado como recomendación final.', p_codigo;
    END IF;

    DELETE FROM public.producto_catalogo
    WHERE codigo_producto = TRIM(p_codigo);

    RAISE NOTICE 'Producto % eliminado correctamente.', p_codigo;
END;
$$;

-- ============================================================================
-- 3. STORED PROCEDURES: ENTIDAD PERFIL_DE_NECESIDAD (Inserción, Modificación, Borrado)
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
    -- Validaciones
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
        p_uso_principal,
        p_presupuesto_max,
        p_restriccion_tecnica,
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
        RAISE EXCEPTION 'No se encontró el perfil de necesidad con ID %', p_id_perfil;
    END IF;

    UPDATE public.perfil_de_necesidad
    SET
        uso_principal = p_uso_principal,
        presupuesto_max = p_presupuesto_max,
        restriccion_tecnica = p_restriccion_tecnica,
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

    -- Verificar si tiene matrices comparativas
    IF EXISTS (SELECT 1 FROM public.matriz_de_comparativa WHERE id_perfil = p_id_perfil) THEN
        RAISE EXCEPTION 'No se puede eliminar el perfil % porque tiene comparativas asociadas.', p_id_perfil;
    END IF;

    DELETE FROM public.perfil_de_necesidad
    WHERE id_perfil = p_id_perfil;

    RAISE NOTICE 'Perfil de necesidad ID % eliminado correctamente.', p_id_perfil;
END;
$$;

-- ============================================================================
-- 4. TRIGGERS DE VALIDACIÓN DE REGLAS DE NEGOCIO
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: VALIDACIÓN DE REGLAS DE NEGOCIO EN PERFIL DE NECESIDAD
-- Valida que el presupuesto sea estrictamente positivo y que la fecha de registro
-- sea congruente (nunca futura). Si no se proporciona fecha, asume CURRENT_DATE.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_validar_perfil_necesidad()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Regla de Validación 1: Presupuesto máximo estrictamente positivo
    IF NEW.presupuesto_max IS NULL OR NEW.presupuesto_max <= 0 THEN
        RAISE EXCEPTION 'Regla de negocio infringida: El presupuesto máximo debe ser mayor a 0 (recibido: %)',
            NEW.presupuesto_max;
    END IF;

    -- Regla de Validación 2: Fecha de registro no puede ser en el futuro
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

-- ----------------------------------------------------------------------------
-- TRIGGER 2: VALIDACIÓN DE FORMATO DE DNI Y SANITIZACIÓN DE CLIENTES
-- Valida que el DNI contenga exactamente 8 dígitos numéricos y normaliza
-- nombres, apellidos y correo a minúsculas sin espacios residuales.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_validar_cliente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el DNI contenga exactamente 8 dígitos numéricos
    IF NEW.dni_cliente !~ '^[0-9]{8}$' THEN
        RAISE EXCEPTION 'DNI inválido: % (debe contener exactamente 8 números).', NEW.dni_cliente;
    END IF;

    -- Normalizar campos de texto
    NEW.nombres := TRIM(NEW.nombres);
    NEW.apellidos := TRIM(NEW.apellidos);
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

-- ----------------------------------------------------------------------------
-- TRIGGER 3: VALIDACIÓN DE INTEGRIDAD EN PRODUCTO_CATALOGO
-- Valida que el modelo no esté vacío y que el precio no sea negativo.
-- ----------------------------------------------------------------------------

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

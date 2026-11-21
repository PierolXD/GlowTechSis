-- ============================================================================
-- GLOWTECH - SCRIPT MAESTRO COMPLETO DE BASE DE DATOS (PostgreSQL 14+)
-- Archivo: database/script_completo_glowtech.sql
-- Compatible con: psql y pgAdmin 4 Query Tool (100% SQL estándar, idempotente)
-- Contiene:
--   1. DDL de las 9 tablas en 3FN (PK, FK, CHECK)
--   2. Carga DML completa de INIFORMACION.docx (15 categorías, 26 marcas, 211 productos y caso base)
--   3. Sincronización de secuencias IDENTITY
--   4. Índices de rendimiento, 27 Stored Procedures y 5 Triggers de validación
-- ============================================================================

-- 1. CREACIÓN DE TABLAS (DDL)
CREATE TABLE IF NOT EXISTS public.categoria (
    id_categoria INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_categoria VARCHAR(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.marca (
    id_marca INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_marca VARCHAR(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.cliente (
    dni_cliente CHAR(8) PRIMARY KEY,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    canal_contacto VARCHAR(30),
    telefono VARCHAR(15),
    correo VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS public.asesor_tecnico (
    id_asesor INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    especialidad VARCHAR(60),
    turno VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS public.producto_catalogo (
    codigo_producto VARCHAR(20) PRIMARY KEY,
    modelo VARCHAR(80) NOT NULL,
    especificaciones TEXT,
    precio_referencial NUMERIC(10,2),
    id_marca INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    CONSTRAINT fk_producto_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria)
);

CREATE TABLE IF NOT EXISTS public.perfil_de_necesidad (
    id_perfil INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uso_principal VARCHAR(100),
    presupuesto_max NUMERIC(10,2),
    restriccion_tecnica VARCHAR(255),
    fecha_registro DATE,
    dni_cliente CHAR(8) NOT NULL,
    id_asesor INTEGER NOT NULL,
    id_marca INTEGER,
    CONSTRAINT fk_perfil_cliente FOREIGN KEY (dni_cliente) REFERENCES public.cliente(dni_cliente),
    CONSTRAINT fk_perfil_asesor FOREIGN KEY (id_asesor) REFERENCES public.asesor_tecnico(id_asesor),
    CONSTRAINT fk_perfil_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca)
);

CREATE TABLE IF NOT EXISTS public.matriz_de_comparativa (
    id_comparativa INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    criterio_evaluacion VARCHAR(150),
    diferencial_tecnico TEXT,
    id_perfil INTEGER NOT NULL,
    CONSTRAINT fk_matriz_perfil FOREIGN KEY (id_perfil) REFERENCES public.perfil_de_necesidad(id_perfil)
);

CREATE TABLE IF NOT EXISTS public.detalle_evaluacion (
    id_comparativa INTEGER NOT NULL,
    codigo_producto VARCHAR(20) NOT NULL,
    resultado_evaluacion VARCHAR(255),
    CONSTRAINT pk_detalle_evaluacion PRIMARY KEY (id_comparativa, codigo_producto),
    CONSTRAINT fk_detalle_comparativa FOREIGN KEY (id_comparativa) REFERENCES public.matriz_de_comparativa(id_comparativa),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (codigo_producto) REFERENCES public.producto_catalogo(codigo_producto)
);

CREATE TABLE IF NOT EXISTS public.recomendacion_final (
    id_recomendacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    justificacion_tecnica TEXT,
    indicacion_uso TEXT,
    nivel_compatibilidad NUMERIC(5,2),
    id_comparativa INTEGER NOT NULL,
    codigo_producto VARCHAR(20) NOT NULL,
    CONSTRAINT fk_recomendacion_comparativa FOREIGN KEY (id_comparativa) REFERENCES public.matriz_de_comparativa(id_comparativa),
    CONSTRAINT fk_recomendacion_producto FOREIGN KEY (codigo_producto) REFERENCES public.producto_catalogo(codigo_producto),
    CONSTRAINT chk_nivel_compatibilidad CHECK (nivel_compatibilidad BETWEEN 0 AND 100)
);

-- 2. CARGA DE DATOS INICIALES (DML)

-- Datos de categoria (15 registros)
INSERT INTO public.categoria (id_categoria, nombre_categoria) OVERRIDING SYSTEM VALUE VALUES
  (1, 'AUDIFONOS'),
  (2, 'PARLANTES'),
  (3, 'EQUIPOS'),
  (4, 'AUDIO PARA CASA (HOME -  BARRA SONIDO)'),
  (5, 'MICROFONOS'),
  (6, 'INSTRUMENTOS MUSICALES Y DJ'),
  (7, 'TELEVISORES'),
  (8, 'CELULARES - TABLETS Y ACCESORIOS DE CÓMPUTO'),
  (9, 'CARGADORES Y CABLES'),
  (10, 'SMARTWATCH'),
  (11, 'CÁMARAS, DRONES Y ACCESORIOS DE VIDEO'),
  (12, 'AUDIO PARA AUTO'),
  (13, 'CUIDADO PERSONAL'),
  (14, 'ELECTRODOMESTICOS'),
  (15, 'HERRAMIENTAS')
ON CONFLICT DO NOTHING;

-- Datos de marca (26 registros)
INSERT INTO public.marca (id_marca, nombre_marca) OVERRIDING SYSTEM VALUE VALUES
  (1, 'JBL'),
  (2, 'SONOS'),
  (3, 'XIAOMI'),
  (4, 'BOSE'),
  (5, 'HARMAN KARDON'),
  (6, 'ANKER'),
  (7, 'TRONSMART'),
  (8, 'HIFUTURE'),
  (9, 'BOYA'),
  (10, 'PIONEER'),
  (11, 'YAMAHA'),
  (12, 'SAMSUNG'),
  (13, 'LG'),
  (14, 'MOTOROLA'),
  (15, 'ZTE'),
  (16, 'HUION'),
  (17, 'SIN MARCA'),
  (18, 'APPLE'),
  (19, 'DJI'),
  (20, 'KUZLER'),
  (21, 'TP-LINK'),
  (22, 'REMINGTON'),
  (23, 'SIEGEN'),
  (24, 'OSTER'),
  (25, 'THOMAS'),
  (26, 'EMTOP')
ON CONFLICT DO NOTHING;

-- Datos de cliente (1 registros)
INSERT INTO public.cliente (dni_cliente, nombres, apellidos, canal_contacto, telefono, correo) VALUES
  ('12345678', 'Carlos', 'Mendoza Lopez', 'WhatsApp', '999888777', 'carlos.prueba@example.com')
ON CONFLICT DO NOTHING;

-- Datos de asesor_tecnico (1 registros)
INSERT INTO public.asesor_tecnico (id_asesor, nombres, apellidos, especialidad, turno) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Luis', 'Ramirez Torres', 'Audio y tecnologia', 'MANANA')
ON CONFLICT DO NOTHING;

-- Datos de producto_catalogo (211 registros)
INSERT INTO public.producto_catalogo (codigo_producto, modelo, especificaciones, precio_referencial, id_marca, id_categoria) VALUES
  ('PROD0001', 'JBL Tour One M3 Smart Tx BLACK', 'Color: NEGRO', 1069.00, 1, 1),
  ('PROD0002', 'JBL Tour One M3 BLACK', 'Color: NEGRO', 949.00, 1, 1),
  ('PROD0003', 'JBL LIVE 780NC BLACK', 'Color: NEGRO', 479.00, 1, 1),
  ('PROD0004', 'JBL Live 680 NC', 'Color: NEGRO', 399.00, 1, 1),
  ('PROD0005', 'JBL TUNE 780BT NC', 'Color: NEGRO', 269.00, 1, 1),
  ('PROD0006', 'JBL Tune 780 ANC WHITE', 'Color: BLANCO', 269.00, 1, 1),
  ('PROD0007', 'JBL Tune 780 ANC BLUE', 'Color: AZUL', 269.00, 1, 1),
  ('PROD0008', 'JBL TUNE 530BT BLACK', 'Color: NEGRO', 129.00, 1, 1),
  ('PROD0009', 'JBL TUNE 530BT LAVENDER', 'Color: LAVANDA', 129.00, 1, 1),
  ('PROD0010', 'JBL TUNE 530BT WHITE', 'Color: BLANCO', 129.00, 1, 1),
  ('PROD0011', 'JBL TUNE 530BT BLUE', 'Color: AZUL', 129.00, 1, 1),
  ('PROD0012', 'JBL ENDURANCE PACE SPORT HOOK TWS', 'Color: NEGRO', 189.00, 1, 1),
  ('PROD0013', 'JBL ENDURANCE RUN 3 BT BLACK', 'Color: NEGRO', 109.00, 1, 1),
  ('PROD0014', 'JBL Soundgear Clips - Blue - EAR CUFF', 'Color: AZUL', 329.00, 1, 1),
  ('PROD0015', 'JBL Soundgear Clips - Black - EAR CUFF', 'Color: NEGRO', 329.00, 1, 1),
  ('PROD0016', 'JBL Soundgear Clips - Copper - EAR CUFF', 'Color: CAFÉ', 329.00, 1, 1),
  ('PROD0017', 'JBL Sense Lite Open Ear - Purple', 'Color: MORADO', 289.00, 1, 1),
  ('PROD0018', 'JBL Sense Lite Open Ear - Blue', 'Color: AZUL', 289.00, 1, 1),
  ('PROD0019', 'JBL Sense Lite Open Ear - Black', 'Color: NEGRO', 289.00, 1, 1),
  ('PROD0020', 'JBL Sense Pro gray EAR HOOK', 'Color: GRAY', 459.00, 1, 1),
  ('PROD0021', 'JBL Sense Pro blue EAR HOOK', 'Color: NEGRO', 459.00, 1, 1),
  ('PROD0022', 'JBL Sense Pro - Black - EAR HOOK', 'Color: NEGRO', 459.00, 1, 1),
  ('PROD0023', 'JBL LIVE Beam 4 - Headphones - Silver', 'Color: PLATA', 639.00, 1, 1),
  ('PROD0024', 'JBL LIVE Beam 4 - Headphones - Blue', 'Color: BLUE', 639.00, 1, 1),
  ('PROD0025', 'JBL LIVE Beam 4 - Headphones - Champagne', 'Color: CHAMPAN', 639.00, 1, 1),
  ('PROD0026', 'JBL WAVE BEAM 2 TWS BLACK', 'Color: NEGRO', 159.00, 1, 1),
  ('PROD0027', 'SONOS HEADPHONE ACE WIRELESS OVER-EAR', 'Color: NEGRO', 1689.00, 2, 1),
  ('PROD0028', 'XIAOMI REDMI BUDS 8 PRO BLACK', 'Color: NEGRO', 249.00, 3, 1),
  ('PROD0029', 'XIAOMI REDMI BUDS 8 ACTIVE WHITE', 'Color: NEGRO / BLANCO', 75.00, 3, 1),
  ('PROD0030', 'XIAOMI Redmi Buds 6 Play', 'Color: NEGRO / BLANCO', 45.00, 3, 1),
  ('PROD0031', 'BOSE SOUNDLINK MAX PORTABLE BLACK', 'Color: NEGRO', 1599.00, 4, 2),
  ('PROD0032', 'BOSE SOUNDLINK MAX PORTABLE BLUE', 'Color: AZUL', 1599.00, 4, 2),
  ('PROD0033', 'BOSE SIST MUS SOUNDLINK PLUS BLACK', 'Color: NEGRO', 1249.00, 4, 2),
  ('PROD0034', 'BOSE SIST MUS SOUNDLINK PLUS BLUE', 'Color: AZUL', 1249.00, 4, 2),
  ('PROD0035', 'BOSE SIST MUS SOUNDLINK REVOL II PLUS', 'Color: NEGRO', 1080.00, 4, 2),
  ('PROD0036', 'HARMAN KARDON ONYX STUDIO 9 SPEAKER', 'Color: NEGRO', 499.00, 5, 2),
  ('PROD0037', 'HARMAN KARDON Luna 2 BLACK', 'Color: NEGRO', 479.00, 5, 2),
  ('PROD0038', 'JBL PARTYBOX ON THE GO 2 PLUS', 'Color: NEGRO', 1179.00, 1, 2),
  ('PROD0039', 'JBL PARLANTE PARTYBOX ENCORE ESSENTIAL 2 BT', 'Color: NEGRO', 879.00, 1, 2),
  ('PROD0040', 'JBL PARLANTE BOOMBOX 4 NEGRO', 'Color: NEGRO', 1399.00, 1, 2),
  ('PROD0041', 'JBL PARLANTE BOOMBOX 4 AZUL', 'Color: AZUL', 1399.00, 1, 2),
  ('PROD0042', 'JBL PARLANTE BOOMBOX 4 BLANCO', 'Color: BLANCO', 1429.00, 1, 2),
  ('PROD0043', 'JBL PARLANTE BOOMBOX 4 CAMUFLADO', 'Color: NARANJA', 1399.00, 1, 2),
  ('PROD0044', 'JBL XTREME 5 NEGRO', 'Color: NEGRO', 979.00, 1, 2),
  ('PROD0045', 'JBL XTREME 5 AZUL', 'Color: AZUL', 979.00, 1, 2),
  ('PROD0046', 'JBL XTREME 5 CAMUFLADO', 'Color: CAMUFLADO', 979.00, 1, 2),
  ('PROD0047', 'JBL CHARGE 6 BLACK', 'Color: NEGRO', 465.00, 1, 2),
  ('PROD0048', 'JBL CHARGE 6 BLUE', 'Color: AZUL', 465.00, 1, 2),
  ('PROD0049', 'JBL CHARGE 6 CAMUFLADO', 'Color: CAMUFLADO', 465.00, 1, 2),
  ('PROD0050', 'JBL CHARGE 6 PURPLE', 'Color: MORADO', 465.00, 1, 2),
  ('PROD0051', 'JBL CHARGE 6 FUNKY', 'Color: ROSADO', 465.00, 1, 2),
  ('PROD0052', 'JBL GRIP CAMUFLADO', 'Color: CAMUFLADO', 185.00, 1, 2),
  ('PROD0053', 'JBL GO5 SPEAKER BLACK', 'Color: NARANJA', 139.00, 1, 2),
  ('PROD0054', 'JBL GO5 SPEAKER BLUE', 'Color: AMARILLO', 139.00, 1, 2),
  ('PROD0055', 'JBL GO5 SPEAKER SQUAD', 'Color: CELESTE', 139.00, 1, 2),
  ('PROD0056', 'JBL GO5 SPEAKER PURPLE', 'Color: MORADO', 139.00, 1, 2),
  ('PROD0057', 'JBL GO5 SPEAKER RED', 'Color: ROJO', 139.00, 1, 2),
  ('PROD0058', 'JBL GO5 SPEAKER ORANGE', 'Color: NARANJA', 139.00, 1, 2),
  ('PROD0059', 'SONOS SPEAKER ROAM 2 BLACK', 'Color: NEGRO', 499.00, 2, 2),
  ('PROD0060', 'SONOS SPEAKER ROAM 2 BLUE', 'Color: AZUL', 499.00, 2, 2),
  ('PROD0061', 'SONOS SPEAKER ROAM 2 GREEN', 'Color: VERDE', 499.00, 2, 2),
  ('PROD0062', 'SONOS SPEAKER MOVE 2 BLACK', 'Color: NEGRO', 1799.00, 2, 2),
  ('PROD0063', 'XIAOMI PARLANTE SOUND POCKET ROSADO', 'Color: ROSADO', 59.00, 3, 2),
  ('PROD0064', 'ANKER SOUNDCORE SPEAKER BOOM 2 PRO BLACK', 'Color: NEGRO', 849.00, 6, 2),
  ('PROD0065', 'ANKER SOUNDCORE SPEAKER RAVE 3S BLACK', 'Color: NEGRO', 999.00, 6, 2),
  ('PROD0066', 'TRONSMART T8 MINI 15W BLUETOOTH 5.3 18H IPX7', 'Color: NEGRO', 109.00, 7, 2),
  ('PROD0067', 'TRONSMART MIRTUNE C3 24W IPX7 BT AZUL', 'Color: AZUL', 129.00, 7, 2),
  ('PROD0068', 'TRONSMART MIRTUNE C3 PLUS 30W IPX7 BT', 'Color: NEGRO', 179.00, 7, 2),
  ('PROD0069', 'TRONSMART BANG 2', 'Color: NEGRO', 389.00, 7, 2),
  ('PROD0070', 'TRONSMART ELEMENT HALO 200 + 2 MICROFONO 120W', 'Color: NEGRO', 649.00, 7, 2),
  ('PROD0071', 'HIFUTURE SPEAKER MEGA S - GRAY', 'Color: NEGRO / GRIS / CREMA / VERDE', 29.00, 8, 2),
  ('PROD0072', 'BOSE L1 PRO8 PARLANTE AMPLIFICADO', 'Color: NEGRO', 4449.00, 4, 3),
  ('PROD0073', 'BOSE S1 PRO+ WIRELESS PA SYSTEM', 'Color: NEGRO', 2599.00, 4, 3),
  ('PROD0074', 'JBL EON ONE COMPACT', 'Color: NEGRO', 1899.00, 1, 3),
  ('PROD0075', 'JBL SPEAKER PARTYBOX ULTIMATE BT', 'Color: NEGRO', 3699.00, 1, 3),
  ('PROD0076', 'JBL SPEAKER PARTYBOX 720 BT', 'Color: NEGRO', 2699.00, 1, 3),
  ('PROD0077', 'JBL SPEAKER PARTYBOX 520BT', 'Color: NEGRO', 1999.00, 1, 3),
  ('PROD0078', 'JBL SPEAKER PARTYBOX 330BT', 'Color: NEGRO', 1699.00, 1, 3),
  ('PROD0079', 'JBL SPEAKER PARTYBOX 330BT BLANCO', 'Color: BLANCO', 1799.00, 1, 3),
  ('PROD0080', 'JBL SPEAKER PARTYBOX 320 BT', 'Color: NEGRO', 1649.00, 1, 3),
  ('PROD0081', 'JBL SPEAKER PARTYBOX 130BT', 'Color: NEGRO', 1189.00, 1, 3),
  ('PROD0082', 'JBL SPEAKER PARTYBOX 130BT BLANCO', 'Color: BLANCO', 1189.00, 1, 3),
  ('PROD0083', 'JBL BATERIA200 PARTYBOX BLACK', 'Color: NEGRO', 179.00, 1, 3),
  ('PROD0084', 'JBL BATERIA400 PARTYBOX BLACK', 'Color: NEGRO', 249.00, 1, 3),
  ('PROD0085', 'SONOS SPEAKER FIVE', 'Color: NEGRO', 2299.00, 2, 4),
  ('PROD0086', 'SONOS SOUNDBAR BEAM G2 BLACK', 'Color: NEGRO', 1899.00, 2, 4),
  ('PROD0087', 'SONOS MINI SOUNDBAR RAY', 'Color: NEGRO', 899.00, 2, 4),
  ('PROD0088', 'SONOS SUB MINI SUBWOOFER', 'Color: NEGRO', 1699.00, 2, 4),
  ('PROD0089', 'BOYA MICROFONO INALAMBRICO BY-V10', 'Color: NEGRO', 89.00, 9, 5),
  ('PROD0090', 'BOYA MICROFONO INALAMBRICO BY-V20', 'Color: NEGRO', 179.00, 9, 5),
  ('PROD0091', 'BOYA MINI 2-02 MICROFONO INALAMBRICO', 'Color: NEGRO', 199.00, 9, 5),
  ('PROD0092', 'BOYA MICROFONO INALAMBRICO BY-V4U', 'Color: NEGRO', 399.00, 9, 5),
  ('PROD0093', 'JBL MICROFONO EASYSING MINI', 'Color: NEGRO', 499.00, 1, 5),
  ('PROD0094', 'JBL MICROFONO IA EASYSING MICS', 'Color: NEGRO', 429.00, 1, 5),
  ('PROD0095', 'PIONEER DJ CONTROLADOR DDJ-FLX4-W WHITE', 'Color: BLANCA', 1299.00, 10, 6),
  ('PROD0096', 'PIONEER DJ CONTROLADOR DDJ-FLX4 NEGRO', 'Color: NEGRO', 1439.00, 10, 6),
  ('PROD0097', 'YAMAHA YRS-23 FLAUTA DULCE MARFIL', 'Color: CREMA', 25.00, 11, 6),
  ('PROD0098', 'YAMAHA PSR-F52 ORGANO ELECTRONIC + PA- 3C', 'Color: NEGRO', 499.00, 11, 6),
  ('PROD0099', 'YAMAHA PSR-E283 ORGANO ELECTRONIC + PA- 3C', 'Color: NEGRO', 599.00, 11, 6),
  ('PROD0100', 'YAMAHA PSR-EW425 ORGANO ELECTRONIC + PA-30', 'Color: NEGRO', 1999.00, 11, 6),
  ('PROD0101', 'YAMAHA P-145BTB PIANO DIGITAL + PA 150', 'Color: NEGRO', 1999.00, 11, 6),
  ('PROD0102', 'SAMSUNG TELEVISOR CRYSTAL 75 UHD 4K Smart TV UN75U8000FGXPE', 'Color: NEGRO', 2399.00, 12, 7),
  ('PROD0103', 'SAMSUNG TELEVISOR QLED 65 UHD 4K Smart TV Q6F QN65Q6FAAGXPE', 'Color: NEGRO', 1999.00, 12, 7),
  ('PROD0104', 'SAMSUNG TELEVISOR QLED 55 UHD 4K Smart TV Q6F QN55Q6FAAGXPE', 'Color: NEGRO', 1499.00, 12, 7),
  ('PROD0105', 'SAMSUNG TELEVISOR MINILED 55 UHD 4K SMART TV M80H VISION AI UN55M80HAGXPE', 'Color: NEGRO', 1399.00, 12, 7),
  ('PROD0106', 'LG TELEVISOR SMART TV 75 4K ULTRA HD 75UA8050PSA', 'Color: NEGRO', 2399.00, 13, 7),
  ('PROD0107', 'LG TELEVISOR SMART LED 65UA7300PSBAWFQ UHD THINQ AI+ MAGIC', 'Color: NEGRO', 1699.00, 13, 7),
  ('PROD0108', 'SAMSUNG GALAXY A17 8GB 256GB BLACK', 'Color: NEGRO', 799.00, 12, 8),
  ('PROD0109', 'XIAOMI CELULAR REDMI 17 4GB 256GB BLACK', 'Color: NEGRO', 739.00, 3, 8),
  ('PROD0110', 'XIAOMI CELULAR REDMI NOTE 17 6GB 256GB BLACK', 'Color: NEGRO', 1049.00, 3, 8),
  ('PROD0111', 'MOTOROLA CELULAR G17 4GB 256GB PINK', 'Color: ROSADO', 539.00, 14, 8),
  ('PROD0112', 'ZTE CELULAR NUBIA NEO 5 GT 8GB 256GB', 'Color: NEGRO / PLATA', 999.00, 15, 8),
  ('PROD0113', 'SAMSUNG TABLET S11 ULTRA 12GB 512GB', 'Color: NEGRO', 4599.00, 12, 8),
  ('PROD0114', 'SAMSUNG TABLET ACTIVE 5 5G 6GB 128GB GREEN', 'Color: NEGRO', 1799.00, 12, 8),
  ('PROD0115', 'HUION TAB GRAFICA HS611', 'Color: NEGRO', 270.00, 16, 8),
  ('PROD0116', 'STAND PARA LAPTOP', 'Color: NEGRO', 100.00, 17, 8),
  ('PROD0117', 'SAMSUNG CARGADOR 45W PD POWER ADAPTER TIPO C CON CABLE', 'Color: NEGRO', 99.00, 12, 9),
  ('PROD0118', 'SAMSUNG CARGADOR 45W DADO POWER ADAPTER TIPO C', 'Color: NEGRO', 99.00, 12, 9),
  ('PROD0119', 'SAMSUNG CARGADOR 25W PD ADAPTER USB C DADO', 'Color: NEGRO', 89.00, 12, 9),
  ('PROD0120', 'SAMSUNG CARGADOR 25W DADO USB-C + CABLE', 'Color: NEGRO', 79.00, 12, 9),
  ('PROD0121', 'APPLE POWER ADAPTER 20W USB-C', 'Color: BLANCO', 85.00, 18, 9),
  ('PROD0122', 'APPLE CHARGE CABLE USB-C 1m 60W', 'Color: BLANCO', 85.00, 18, 9),
  ('PROD0123', 'XIAOMI REDMI WATCH 5 LITE LIDTH GOLD', 'Color: DORADO', 185.00, 3, 10),
  ('PROD0124', 'XIAOMI REDMI WATCH 5 ACTIVE MIDNIGHT BLACK', 'Color: NEGRO', 129.00, 3, 10),
  ('PROD0125', 'XIAOMI REDMI WATCH 5 ACTIVE MATTE SILVER', 'Color: SILVER', 129.00, 3, 10),
  ('PROD0126', 'XIAOMI SMART BAND 10 MYSTIC ROSE', 'Color: ROSADO', 175.00, 3, 10),
  ('PROD0127', 'SAMSUNG GALAXY FIT 3 BLACK', 'Color: NEGRO', 129.00, 12, 10),
  ('PROD0128', 'DJI NEO FLY MORE COMBO', 'Color: NEGRO', 1499.00, 19, 11),
  ('PROD0129', 'KUZLER LUZ LED BICOLOR LDC DISPLAY LIGHT', 'Color: NEGRO', 69.00, 20, 11),
  ('PROD0130', 'KUZLER TRIPODE SELFIE STICK MULTIFUNTIONAL', 'Color: NEGRO', 69.00, 20, 11),
  ('PROD0131', 'TP-LINK TAPO C225 PAN/TILT AL HOME SECURITY WIFI CAMERA', 'Color: NEGRO', 169.00, 21, 11),
  ('PROD0132', 'XIAOMI SMART CEILING LIGHT D20 - SENSOR LED', 'Color: BLANCO', 149.00, 3, 11),
  ('PROD0133', 'JBL FLEX4 6TRFX55 PARLANTES PAR 6 TRIAXIAL', 'Color: NEGRO', 109.00, 1, 12),
  ('PROD0134', 'JBL FLEX4 69QDFX110 PARLANTES PAR 6x9 220W', 'Color: NEGRO', 199.00, 1, 12),
  ('PROD0135', 'PIONEER MVH-S145BT AUTORRADIO BT/MP3/USB', 'Color: NEGRO', 199.00, 10, 12),
  ('PROD0136', 'PIONEER MVH-S325BT AUTORRADIO BT/MP3/USB', 'Color: NEGRO', 309.00, 10, 12),
  ('PROD0137', 'PIONEER TS-G1010F-2 PARLANTES DE 10CM', 'Color: NEGRO', 79.00, 10, 12),
  ('PROD0138', 'PIONEER PARLANTES TS-F1034R 10CM 2 VIAS', 'Color: NEGRO', 89.00, 10, 12),
  ('PROD0139', 'PIONEER TS-F1634R PARLANTES 16CM 200W 2V', 'Color: NEGRO', 99.00, 10, 12),
  ('PROD0140', 'PIONEER PARLANTES TS-G1610F 16CM 280W', 'Color: NEGRO', 89.00, 10, 12),
  ('PROD0141', 'PIONEER PARLANTES TS-G1620F 16CM 300W', 'Color: NEGRO', 129.00, 10, 12),
  ('PROD0142', 'PIONEER TS-A1678S PARLANTES 16C 3V 320W', 'Color: NEGRO', 199.00, 10, 12),
  ('PROD0143', 'PIONEER TS-A1688S PARLANTES 16C 4V 350W', 'Color: NEGRO', 259.00, 10, 12),
  ('PROD0144', 'PIONEER TS-A6968S PARLANTES 6X9 4V 450W', 'Color: NEGRO', 189.00, 10, 12),
  ('PROD0145', 'PIONEER TS-A6978S PARLANTES 6X9 4V 650W', 'Color: NEGRO', 269.00, 10, 12),
  ('PROD0146', 'PIONEER TS-A6998S PARLANTES 6X9 5V 750W', 'Color: NEGRO', 329.00, 10, 12),
  ('PROD0147', 'PIONEER TS-S250 BOCINA AGUD P/AUTO', 'Color: NEGRO', 169.00, 10, 12),
  ('PROD0148', 'PIONEER TS-B351PRO AGUDO TIPO BALA 3.5', 'Color: NEGRO', 169.00, 10, 12),
  ('PROD0149', 'PIONEER TS-B401PRO AGUDO TIPO BALA 4', 'Color: NEGRO', 199.00, 10, 12),
  ('PROD0150', 'PIONEER TS-M1610PRO PARLANTE MEDIO 6', 'Color: NEGRO', 269.00, 10, 12),
  ('PROD0151', 'PIONEER TS-M651PRO PARLANTE MEDIO 6.5', 'Color: NEGRO', 369.00, 10, 12),
  ('PROD0152', 'PIONEER TS-M801PRO PARLNATE MEDIO 8', 'Color: NEGRO', 459.00, 10, 12),
  ('PROD0153', 'PIONEER TS-6900PRO PARLANTES 6X9 OVALADO', 'Color: NEGRO', 499.00, 10, 12),
  ('PROD0154', 'PIONEER TS-651C PARLANTES COMP 390W', 'Color: NEGRO', 289.00, 10, 12),
  ('PROD0155', 'PIONEER GM-A6704 AMPLIFICADOR 4CH', 'Color: NEGRO', 479.00, 10, 12),
  ('PROD0156', 'PIONEER TS-WX130EA SUBWOOFER ACTIVO', 'Color: NEGRO', 399.00, 10, 12),
  ('PROD0157', 'PIONEER TS-WX400DA SUBWOOFER ACTIVO', 'Color: NEGRO', 999.00, 10, 12),
  ('PROD0158', 'PIONEER GM-D9704 AMPLIFICADOR CLAS D 4C', 'Color: NEGRO', 1099.00, 10, 12),
  ('PROD0159', 'PIONEER GM-D9705 AMPLIFICADOR CLAS D 5C', 'Color: NEGRO', 1199.00, 10, 12),
  ('PROD0160', 'PIONEER TS-W312D4 SUBWOOFER 12" 1600W DOBLE BOBINA', 'Color: NEGRO', 299.00, 10, 12),
  ('PROD0161', 'PIONEER TS-W3004D4 SUBWOOFER 12" 2400W', 'Color: NEGRO', 519.00, 10, 12),
  ('PROD0162', 'PIONEER TS-WX300A SUBWOOFER', 'Color: NEGRO', 599.00, 10, 12),
  ('PROD0163', 'REMINGTON HC1095 CORTADORA DE CABELLO', 'Color: ROJO', 69.00, 22, 13),
  ('PROD0164', 'REMINGTON CORTADORA PERSONAL PG181 GROOMERS', 'Color: NEGRO', 69.00, 22, 13),
  ('PROD0165', 'REMINGTON AFEITADORA ROTATIVA R1001 NEGRO', 'Color: NEGRO', 119.00, 22, 13),
  ('PROD0166', 'REMINGTON AFEITADORA DE LAMINA F1001', 'Color: NEGRO', 99.00, 22, 13),
  ('PROD0167', 'REMINGTON AFEITADORA ROTATIVA GRAF R4011', 'Color: NEGRO', 165.00, 22, 13),
  ('PROD0168', 'REMINGTON ALISADORA DE CABELLO S1520 BLUE', 'Color: AZUL', 89.00, 22, 13),
  ('PROD0169', 'REMINGTON ALISADORA DE CABELLO S27A CREMA', 'Color: CREMA', 129.00, 22, 13),
  ('PROD0170', 'REMINGTON ALISADORA DE CABELLO S5805 SAPPHIROLUX', 'Color: AZUL', 115.00, 22, 13),
  ('PROD0171', 'REMINGTON ALISADORA DE CABELLO S12A', 'Color: VERDE', 139.00, 22, 13),
  ('PROD0172', 'REMINGTON ALISADORA DE CABELLO S9350 GLOSS', 'Color: MORADO', 139.00, 22, 13),
  ('PROD0173', 'REMINGTON ALISADORA DE CABELLO S9600 PROFESIONAL', 'Color: ROJO', 179.00, 22, 13),
  ('PROD0174', 'REMINGTON AS8930 ESTILIZADOR AIRE 2EN1', 'Color: CREMA', 369.00, 22, 13),
  ('PROD0175', 'REMINGTON SECADORA DE CABELLOS D5805 SAPPHIROLUX', 'Color: NEGRO', 119.00, 22, 13),
  ('PROD0176', 'REMINGTON SECADORA DE CABELLO D13A', 'Color: NEGRO', 129.00, 22, 13),
  ('PROD0177', 'REMINGTON SECADORA DE CABELLO AC9096 ROJO', 'Color: NEGRO', 209.00, 22, 13),
  ('PROD0178', 'REMINGTON SECADORA CABELLO AC9350 GLOSS', 'Color: MORADO', 199.00, 22, 13),
  ('PROD0179', 'REMINGTON SECADORA CABELLO EC8930', 'Color: CREMA', 329.00, 22, 13),
  ('PROD0180', 'REMINGTON COMBO SECA+ALI DS5805GP SAPPHIROLUX', 'Color: NEGRO', 249.00, 22, 13),
  ('PROD0181', 'REMINGTON CEPILLO DE AIRE AS15A WET2STYL', 'Color: NEGRO', 159.00, 22, 13),
  ('PROD0182', 'REMINGTON AS5805 CEPILLO 3 EN 1 SAPPHIROLUX', 'Color: NEGRO', 199.00, 22, 13),
  ('PROD0183', 'REMINGTON AS9350 CEPILLO DE AIRE GLOSS', 'Color: NEGRO', 189.00, 22, 13),
  ('PROD0184', 'SIEGEN ALISADOR SG-3540 CERAMICA', 'Color: NEGRO', 129.00, 23, 13),
  ('PROD0185', 'SIEGEN ALISADOR SG-4700 Titanium', 'Color: NEGRO', 299.00, 23, 13),
  ('PROD0186', 'SIEGEN CEPILLO MODELADOR SG-2805 1000w', 'Color: NEGRO', 119.00, 23, 13),
  ('PROD0187', 'SIEGEN SECADORA DE CABELLO SG-3110 2000W', 'Color: NEGRO', 119.00, 23, 13),
  ('PROD0188', 'SIEGEN SECADORA DE CABELLO SG-3035 2000W', 'Color: NEGRO', 99.00, 23, 13),
  ('PROD0189', 'OSTER LICUADORA 1.25L BLST4126R-053', 'Color: ROJO', 299.00, 24, 14),
  ('PROD0190', 'THOMAS LICUADORA MOD TH-410V PLATA', 'Color: PLATA', 149.00, 25, 14),
  ('PROD0191', 'THOMAS LICUADORA MOD TH-300PB 600ML', 'Color: PLATA', 129.00, 25, 14),
  ('PROD0192', 'THOMAS PLANCHA TH-7060 2200W', 'Color: BLANCO', 99.00, 25, 14),
  ('PROD0193', 'THOMAS PLANCHA TH-7300 VERTICAL', 'Color: ROJO', 119.00, 25, 14),
  ('PROD0194', 'THOMAS FREIDORA DE AIRE TH-AF130DV NEGRO', 'Color: NEGRO', 629.00, 25, 14),
  ('PROD0195', 'THOMAS SANDWICHERA TH-965 750W BLANCO', 'Color: BLANCO', 109.00, 25, 14),
  ('PROD0196', 'EMTOP AMOLADORA 7" 2000W 8450RPM EAGR20073', 'Color: ROJO', 189.00, 26, 15),
  ('PROD0197', 'EMTOP GATA HIDRAULICA TIPO LAGARTO 2TN EHJK2021', 'Color: ROJO', 129.00, 26, 15),
  ('PROD0198', 'EMTOP PISTOLA DE CALOR 2000W EHGN20078', 'Color: ROJO', 69.00, 26, 15),
  ('PROD0199', 'EMTOP SIERRA CIRCULAR 7 1/4"1600W ECSW1853', 'Color: ROJO', 199.00, 26, 15),
  ('PROD0200', 'EMTOP CORTADOR DE CERÁMICOS 60CM ETCR6004', 'Color: ROJO', 149.00, 26, 15),
  ('PROD0201', 'EMTOP EDSD10501 LIJADORA TELESCOPICA PARA PARED 1050W', 'Color: ROJO', 349.00, 26, 15),
  ('PROD0202', 'EMTOP HIDROLAVADORA 2000W 2320PSI EHPW2011', 'Color: ROJO', 349.00, 26, 15),
  ('PROD0203', 'EMTOP ASPIRADORA 12L 220V EVCR0801', 'Color: ROJO', 199.00, 26, 15),
  ('PROD0204', 'EMTOP LIJADORA ORBITAL 20V ELPS201250', 'Color: ROJO', 150.00, 26, 15),
  ('PROD0205', 'EMTOP SIERRA CALADORA 570W + ACC EJSW5701', 'Color: ROJO', 99.00, 26, 15),
  ('PROD0206', 'EMTOP SIERRA CALADORA 800W + ACC EJSW8001', 'Color: ROJO', 150.00, 26, 15),
  ('PROD0207', 'EMTOP SOPLADOR ASPIRADOR 800W EABR8003', 'Color: ROJO', 159.00, 26, 15),
  ('PROD0208', 'EMTOP TALADRO DE IMPACTO 1/2 20V 66N.M + 2 BAT+CARG+MALETA ECIDL20668', 'Color: ROJO', 219.00, 26, 15),
  ('PROD0209', 'EMTOP LLAVE DE IMPACTO 1/2" 20V LI-ION BL + 2 BAT 2 AH MALETIN ECDLIW2038', 'Color: ROJO', 279.00, 26, 15),
  ('PROD0210', 'EMTOP LLAVE DE IMPACTO INALAMBRICA 1/2'''' 20V 850N.M + 2BAT 4.0AH ECIWL2085', 'Color: ROJO', 439.00, 26, 15),
  ('PROD0211', 'EMTOP TALADRO DE IMPACTO 1/2 20V 66N.M + 2 BAT+CARG+MALETA ECIDL20668', 'Color: ROJO', 229.00, 26, 15)
ON CONFLICT DO NOTHING;

-- Datos de perfil_de_necesidad (1 registros)
INSERT INTO public.perfil_de_necesidad (id_perfil, uso_principal, presupuesto_max, restriccion_tecnica, fecha_registro, dni_cliente, id_asesor, id_marca) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Estudio y musica', 500.00, 'Audifonos inalambricos con cancelacion de ruido', '2026-10-23', '12345678', 1, 1)
ON CONFLICT DO NOTHING;

-- Datos de matriz_de_comparativa (1 registros)
INSERT INTO public.matriz_de_comparativa (id_comparativa, criterio_evaluacion, diferencial_tecnico, id_perfil) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Precio, conectividad y cancelacion de ruido', 'Comparacion de audifonos JBL segun las necesidades del cliente', 1)
ON CONFLICT DO NOTHING;

-- Datos de detalle_evaluacion (3 registros)
INSERT INTO public.detalle_evaluacion (id_comparativa, codigo_producto, resultado_evaluacion) VALUES
  (1, 'PROD0003', 'Candidato por modelo y presupuesto; verificar caracteristicas tecnicas'),
  (1, 'PROD0004', 'Candidato por modelo y presupuesto; verificar caracteristicas tecnicas'),
  (1, 'PROD0005', 'Candidato por modelo y presupuesto; verificar caracteristicas tecnicas')
ON CONFLICT DO NOTHING;

-- Datos de recomendacion_final (1 registros)
INSERT INTO public.recomendacion_final (id_recomendacion, justificacion_tecnica, indicacion_uso, nivel_compatibilidad, id_comparativa, codigo_producto) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Seleccion preliminar dentro del presupuesto. Pendiente de validacion tecnica.', 'Verificar conectividad, cancelacion de ruido y comodidad antes de recomendar.', NULL, 1, 'PROD0003')
ON CONFLICT DO NOTHING;

-- 3. SINCRONIZACIÓN DE SECUENCIAS IDENTITY
SELECT setval(pg_get_serial_sequence('public.categoria', 'id_categoria'), COALESCE((SELECT MAX(id_categoria) FROM public.categoria), 1), true);
SELECT setval(pg_get_serial_sequence('public.marca', 'id_marca'), COALESCE((SELECT MAX(id_marca) FROM public.marca), 1), true);
SELECT setval(pg_get_serial_sequence('public.asesor_tecnico', 'id_asesor'), COALESCE((SELECT MAX(id_asesor) FROM public.asesor_tecnico), 1), true);
SELECT setval(pg_get_serial_sequence('public.perfil_de_necesidad', 'id_perfil'), COALESCE((SELECT MAX(id_perfil) FROM public.perfil_de_necesidad), 1), true);
SELECT setval(pg_get_serial_sequence('public.matriz_de_comparativa', 'id_comparativa'), COALESCE((SELECT MAX(id_comparativa) FROM public.matriz_de_comparativa), 1), true);
SELECT setval(pg_get_serial_sequence('public.recomendacion_final', 'id_recomendacion'), COALESCE((SELECT MAX(id_recomendacion) FROM public.recomendacion_final), 1), true);

-- 4. ÍNDICES, 27 STORED PROCEDURES Y 5 TRIGGERS

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

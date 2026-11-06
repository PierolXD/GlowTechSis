--
-- PostgreSQL database dump
--

\restrict w4ygLyLy8OzvZHMKQ5mgXFxpFPJXUzqYvK3AjwKjDGV31ggTZkQqDlnfQJCKrdc

-- Dumped from database version 14.23
-- Dumped by pg_dump version 18.3

-- Started on 2026-11-06 13:34:25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 17472)
-- Name: asesor_tecnico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asesor_tecnico (
    id_asesor integer NOT NULL,
    nombres character varying(80) NOT NULL,
    apellidos character varying(80) NOT NULL,
    especialidad character varying(60),
    turno character varying(10)
);


ALTER TABLE public.asesor_tecnico OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 17471)
-- Name: asesor_tecnico_id_asesor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.asesor_tecnico ALTER COLUMN id_asesor ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.asesor_tecnico_id_asesor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 210 (class 1259 OID 17455)
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    nombre_categoria character varying(60) NOT NULL
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 17454)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categoria ALTER COLUMN id_categoria ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categoria_id_categoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 213 (class 1259 OID 17466)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    dni_cliente character(8) NOT NULL,
    nombres character varying(80) NOT NULL,
    apellidos character varying(80) NOT NULL,
    canal_contacto character varying(30),
    telefono character varying(15),
    correo character varying(100)
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 17528)
-- Name: detalle_evaluacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_evaluacion (
    id_comparativa integer NOT NULL,
    codigo_producto character varying(20) NOT NULL,
    resultado_evaluacion character varying(255)
);


ALTER TABLE public.detalle_evaluacion OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 17461)
-- Name: marca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.marca (
    id_marca integer NOT NULL,
    nombre_marca character varying(60) NOT NULL
);


ALTER TABLE public.marca OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 17460)
-- Name: marca_id_marca_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.marca ALTER COLUMN id_marca ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.marca_id_marca_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 220 (class 1259 OID 17516)
-- Name: matriz_de_comparativa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.matriz_de_comparativa (
    id_comparativa integer NOT NULL,
    criterio_evaluacion character varying(150),
    diferencial_tecnico text,
    id_perfil integer NOT NULL
);


ALTER TABLE public.matriz_de_comparativa OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 17515)
-- Name: matriz_de_comparativa_id_comparativa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.matriz_de_comparativa ALTER COLUMN id_comparativa ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.matriz_de_comparativa_id_comparativa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 218 (class 1259 OID 17495)
-- Name: perfil_de_necesidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.perfil_de_necesidad (
    id_perfil integer NOT NULL,
    uso_principal character varying(100),
    presupuesto_max numeric(10,2),
    restriccion_tecnica character varying(255),
    fecha_registro date,
    dni_cliente character(8) NOT NULL,
    id_asesor integer NOT NULL,
    id_marca integer
);


ALTER TABLE public.perfil_de_necesidad OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 17494)
-- Name: perfil_de_necesidad_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.perfil_de_necesidad ALTER COLUMN id_perfil ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.perfil_de_necesidad_id_perfil_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 17477)
-- Name: producto_catalogo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto_catalogo (
    codigo_producto character varying(20) NOT NULL,
    modelo character varying(80) NOT NULL,
    especificaciones text,
    precio_referencial numeric(10,2),
    id_marca integer NOT NULL,
    id_categoria integer NOT NULL
);


ALTER TABLE public.producto_catalogo OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 17544)
-- Name: recomendacion_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recomendacion_final (
    id_recomendacion integer NOT NULL,
    justificacion_tecnica text,
    indicacion_uso text,
    nivel_compatibilidad numeric(5,2),
    id_comparativa integer NOT NULL,
    codigo_producto character varying(20) NOT NULL,
    CONSTRAINT chk_nivel_compatibilidad CHECK (((nivel_compatibilidad >= (0)::numeric) AND (nivel_compatibilidad <= (100)::numeric)))
);


ALTER TABLE public.recomendacion_final OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 17543)
-- Name: recomendacion_final_id_recomendacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.recomendacion_final ALTER COLUMN id_recomendacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.recomendacion_final_id_recomendacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3375 (class 0 OID 17472)
-- Dependencies: 215
-- Data for Name: asesor_tecnico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asesor_tecnico (id_asesor, nombres, apellidos, especialidad, turno) FROM stdin;
1	Luis	Ramirez Torres	Audio y tecnologia	MANANA
\.


--
-- TOC entry 3370 (class 0 OID 17455)
-- Dependencies: 210
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id_categoria, nombre_categoria) FROM stdin;
1	AUDIFONOS
2	PARLANTES
3	EQUIPOS
4	AUDIO PARA CASA (HOME -  BARRA SONIDO)
5	MICROFONOS
6	INSTRUMENTOS MUSICALES Y DJ
7	TELEVISORES
8	CELULARES - TABLETS Y ACCESORIOS DE CÓMPUTO
9	CARGADORES Y CABLES
10	SMARTWATCH
11	CÁMARAS, DRONES Y ACCESORIOS DE VIDEO
12	AUDIO PARA AUTO
13	CUIDADO PERSONAL
14	ELECTRODOMESTICOS
15	HERRAMIENTAS
\.


--
-- TOC entry 3373 (class 0 OID 17466)
-- Dependencies: 213
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cliente (dni_cliente, nombres, apellidos, canal_contacto, telefono, correo) FROM stdin;
12345678	Carlos	Mendoza Lopez	WhatsApp	999888777	carlos.prueba@example.com
\.


--
-- TOC entry 3381 (class 0 OID 17528)
-- Dependencies: 221
-- Data for Name: detalle_evaluacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_evaluacion (id_comparativa, codigo_producto, resultado_evaluacion) FROM stdin;
1	PROD0003	Candidato por modelo y presupuesto; verificar caracteristicas tecnicas
1	PROD0004	Candidato por modelo y presupuesto; verificar caracteristicas tecnicas
1	PROD0005	Candidato por modelo y presupuesto; verificar caracteristicas tecnicas
\.


--
-- TOC entry 3372 (class 0 OID 17461)
-- Dependencies: 212
-- Data for Name: marca; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.marca (id_marca, nombre_marca) FROM stdin;
1	JBL
2	SONOS
3	XIAOMI
4	BOSE
5	HARMAN KARDON
6	ANKER
7	TRONSMART
8	HIFUTURE
9	BOYA
10	PIONEER
11	YAMAHA
12	SAMSUNG
13	LG
14	MOTOROLA
15	ZTE
16	HUION
17	SIN MARCA
18	APPLE
19	DJI
20	KUZLER
21	TP-LINK
22	REMINGTON
23	SIEGEN
24	OSTER
25	THOMAS
26	EMTOP
\.


--
-- TOC entry 3380 (class 0 OID 17516)
-- Dependencies: 220
-- Data for Name: matriz_de_comparativa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.matriz_de_comparativa (id_comparativa, criterio_evaluacion, diferencial_tecnico, id_perfil) FROM stdin;
1	Precio, conectividad y cancelacion de ruido	Comparacion de audifonos JBL segun las necesidades del cliente	1
\.


--
-- TOC entry 3378 (class 0 OID 17495)
-- Dependencies: 218
-- Data for Name: perfil_de_necesidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.perfil_de_necesidad (id_perfil, uso_principal, presupuesto_max, restriccion_tecnica, fecha_registro, dni_cliente, id_asesor, id_marca) FROM stdin;
1	Estudio y musica	500.00	Audifonos inalambricos con cancelacion de ruido	2026-10-23	12345678	1	1
\.


--
-- TOC entry 3376 (class 0 OID 17477)
-- Dependencies: 216
-- Data for Name: producto_catalogo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto_catalogo (codigo_producto, modelo, especificaciones, precio_referencial, id_marca, id_categoria) FROM stdin;
PROD0001	JBL Tour One M3 Smart Tx BLACK	Color: NEGRO	1069.00	1	1
PROD0002	JBL Tour One M3 BLACK	Color: NEGRO	949.00	1	1
PROD0003	JBL LIVE 780NC BLACK	Color: NEGRO	479.00	1	1
PROD0004	JBL Live 680 NC	Color: NEGRO	399.00	1	1
PROD0005	JBL TUNE 780BT NC	Color: NEGRO	269.00	1	1
PROD0006	JBL Tune 780 ANC WHITE	Color: BLANCO	269.00	1	1
PROD0007	JBL Tune 780 ANC BLUE	Color: AZUL	269.00	1	1
PROD0008	JBL TUNE 530BT BLACK	Color: NEGRO	129.00	1	1
PROD0009	JBL TUNE 530BT LAVENDER	Color: LAVANDA	129.00	1	1
PROD0010	JBL TUNE 530BT WHITE	Color: BLANCO	129.00	1	1
PROD0011	JBL TUNE 530BT BLUE	Color: AZUL	129.00	1	1
PROD0012	JBL ENDURANCE PACE SPORT HOOK TWS	Color: NEGRO	189.00	1	1
PROD0013	JBL ENDURANCE RUN 3 BT BLACK	Color: NEGRO	109.00	1	1
PROD0014	JBL Soundgear Clips - Blue - EAR CUFF	Color: AZUL	329.00	1	1
PROD0015	JBL Soundgear Clips - Black - EAR CUFF	Color: NEGRO	329.00	1	1
PROD0016	JBL Soundgear Clips - Copper - EAR CUFF	Color: CAFÉ	329.00	1	1
PROD0017	JBL Sense Lite Open Ear - Purple	Color: MORADO	289.00	1	1
PROD0018	JBL Sense Lite Open Ear - Blue	Color: AZUL	289.00	1	1
PROD0019	JBL Sense Lite Open Ear - Black	Color: NEGRO	289.00	1	1
PROD0020	JBL Sense Pro gray EAR HOOK	Color: GRAY	459.00	1	1
PROD0021	JBL Sense Pro blue EAR HOOK	Color: NEGRO	459.00	1	1
PROD0022	JBL Sense Pro - Black - EAR HOOK	Color: NEGRO	459.00	1	1
PROD0023	JBL LIVE Beam 4 - Headphones - Silver	Color: PLATA	639.00	1	1
PROD0024	JBL LIVE Beam 4 - Headphones - Blue	Color: BLUE	639.00	1	1
PROD0025	JBL LIVE Beam 4 - Headphones - Champagne	Color: CHAMPAN	639.00	1	1
PROD0026	JBL WAVE BEAM 2 TWS BLACK	Color: NEGRO	159.00	1	1
PROD0027	SONOS HEADPHONE ACE WIRELESS OVER-EAR	Color: NEGRO	1689.00	2	1
PROD0028	XIAOMI REDMI BUDS 8 PRO BLACK	Color: NEGRO	249.00	3	1
PROD0029	XIAOMI REDMI BUDS 8 ACTIVE WHITE	Color: NEGRO / BLANCO	75.00	3	1
PROD0030	XIAOMI Redmi Buds 6 Play	Color: NEGRO / BLANCO	45.00	3	1
PROD0031	BOSE SOUNDLINK MAX PORTABLE BLACK	Color: NEGRO	1599.00	4	2
PROD0032	BOSE SOUNDLINK MAX PORTABLE BLUE	Color: AZUL	1599.00	4	2
PROD0033	BOSE SIST MUS SOUNDLINK PLUS BLACK	Color: NEGRO	1249.00	4	2
PROD0034	BOSE SIST MUS SOUNDLINK PLUS BLUE	Color: AZUL	1249.00	4	2
PROD0035	BOSE SIST MUS SOUNDLINK REVOL II PLUS	Color: NEGRO	1080.00	4	2
PROD0036	HARMAN KARDON ONYX STUDIO 9 SPEAKER	Color: NEGRO	499.00	5	2
PROD0037	HARMAN KARDON Luna 2 BLACK	Color: NEGRO	479.00	5	2
PROD0038	JBL PARTYBOX ON THE GO 2 PLUS	Color: NEGRO	1179.00	1	2
PROD0039	JBL PARLANTE PARTYBOX ENCORE ESSENTIAL 2 BT	Color: NEGRO	879.00	1	2
PROD0040	JBL PARLANTE BOOMBOX 4 NEGRO	Color: NEGRO	1399.00	1	2
PROD0041	JBL PARLANTE BOOMBOX 4 AZUL	Color: AZUL	1399.00	1	2
PROD0042	JBL PARLANTE BOOMBOX 4 BLANCO	Color: BLANCO	1429.00	1	2
PROD0043	JBL PARLANTE BOOMBOX 4 CAMUFLADO	Color: NARANJA	1399.00	1	2
PROD0044	JBL XTREME 5 NEGRO	Color: NEGRO	979.00	1	2
PROD0045	JBL XTREME 5 AZUL	Color: AZUL	979.00	1	2
PROD0046	JBL XTREME 5 CAMUFLADO	Color: CAMUFLADO	979.00	1	2
PROD0047	JBL CHARGE 6 BLACK	Color: NEGRO	465.00	1	2
PROD0048	JBL CHARGE 6 BLUE	Color: AZUL	465.00	1	2
PROD0049	JBL CHARGE 6 CAMUFLADO	Color: CAMUFLADO	465.00	1	2
PROD0050	JBL CHARGE 6 PURPLE	Color: MORADO	465.00	1	2
PROD0051	JBL CHARGE 6 FUNKY	Color: ROSADO	465.00	1	2
PROD0052	JBL GRIP CAMUFLADO	Color: CAMUFLADO	185.00	1	2
PROD0053	JBL GO5 SPEAKER BLACK	Color: NARANJA	139.00	1	2
PROD0054	JBL GO5 SPEAKER BLUE	Color: AMARILLO	139.00	1	2
PROD0055	JBL GO5 SPEAKER SQUAD	Color: CELESTE	139.00	1	2
PROD0056	JBL GO5 SPEAKER PURPLE	Color: MORADO	139.00	1	2
PROD0057	JBL GO5 SPEAKER RED	Color: ROJO	139.00	1	2
PROD0058	JBL GO5 SPEAKER ORANGE	Color: NARANJA	139.00	1	2
PROD0059	SONOS SPEAKER ROAM 2 BLACK	Color: NEGRO	499.00	2	2
PROD0060	SONOS SPEAKER ROAM 2 BLUE	Color: AZUL	499.00	2	2
PROD0061	SONOS SPEAKER ROAM 2 GREEN	Color: VERDE	499.00	2	2
PROD0062	SONOS SPEAKER MOVE 2 BLACK	Color: NEGRO	1799.00	2	2
PROD0063	XIAOMI PARLANTE SOUND POCKET ROSADO	Color: ROSADO	59.00	3	2
PROD0064	ANKER SOUNDCORE SPEAKER BOOM 2 PRO BLACK	Color: NEGRO	849.00	6	2
PROD0065	ANKER SOUNDCORE SPEAKER RAVE 3S BLACK	Color: NEGRO	999.00	6	2
PROD0066	TRONSMART T8 MINI 15W BLUETOOTH 5.3 18H IPX7	Color: NEGRO	109.00	7	2
PROD0067	TRONSMART MIRTUNE C3 24W IPX7 BT AZUL	Color: AZUL	129.00	7	2
PROD0068	TRONSMART MIRTUNE C3 PLUS 30W IPX7 BT	Color: NEGRO	179.00	7	2
PROD0069	TRONSMART BANG 2	Color: NEGRO	389.00	7	2
PROD0070	TRONSMART ELEMENT HALO 200 + 2 MICROFONO 120W	Color: NEGRO	649.00	7	2
PROD0071	HIFUTURE SPEAKER MEGA S - GRAY	Color: NEGRO / GRIS / CREMA / VERDE	29.00	8	2
PROD0072	BOSE L1 PRO8 PARLANTE AMPLIFICADO	Color: NEGRO	4449.00	4	3
PROD0073	BOSE S1 PRO+ WIRELESS PA SYSTEM	Color: NEGRO	2599.00	4	3
PROD0074	JBL EON ONE COMPACT	Color: NEGRO	1899.00	1	3
PROD0075	JBL SPEAKER PARTYBOX ULTIMATE BT	Color: NEGRO	3699.00	1	3
PROD0076	JBL SPEAKER PARTYBOX 720 BT	Color: NEGRO	2699.00	1	3
PROD0077	JBL SPEAKER PARTYBOX 520BT	Color: NEGRO	1999.00	1	3
PROD0078	JBL SPEAKER PARTYBOX 330BT	Color: NEGRO	1699.00	1	3
PROD0079	JBL SPEAKER PARTYBOX 330BT BLANCO	Color: BLANCO	1799.00	1	3
PROD0080	JBL SPEAKER PARTYBOX 320 BT	Color: NEGRO	1649.00	1	3
PROD0081	JBL SPEAKER PARTYBOX 130BT	Color: NEGRO	1189.00	1	3
PROD0082	JBL SPEAKER PARTYBOX 130BT BLANCO	Color: BLANCO	1189.00	1	3
PROD0083	JBL BATERIA200 PARTYBOX BLACK	Color: NEGRO	179.00	1	3
PROD0084	JBL BATERIA400 PARTYBOX BLACK	Color: NEGRO	249.00	1	3
PROD0085	SONOS SPEAKER FIVE	Color: NEGRO	2299.00	2	4
PROD0086	SONOS SOUNDBAR BEAM G2 BLACK	Color: NEGRO	1899.00	2	4
PROD0087	SONOS MINI SOUNDBAR RAY	Color: NEGRO	899.00	2	4
PROD0088	SONOS SUB MINI SUBWOOFER	Color: NEGRO	1699.00	2	4
PROD0089	BOYA MICROFONO INALAMBRICO BY-V10	Color: NEGRO	89.00	9	5
PROD0090	BOYA MICROFONO INALAMBRICO BY-V20	Color: NEGRO	179.00	9	5
PROD0091	BOYA MINI 2-02 MICROFONO INALAMBRICO	Color: NEGRO	199.00	9	5
PROD0092	BOYA MICROFONO INALAMBRICO BY-V4U	Color: NEGRO	399.00	9	5
PROD0093	JBL MICROFONO EASYSING MINI	Color: NEGRO	499.00	1	5
PROD0094	JBL MICROFONO IA EASYSING MICS	Color: NEGRO	429.00	1	5
PROD0095	PIONEER DJ CONTROLADOR DDJ-FLX4-W WHITE	Color: BLANCA	1299.00	10	6
PROD0096	PIONEER DJ CONTROLADOR DDJ-FLX4 NEGRO	Color: NEGRO	1439.00	10	6
PROD0097	YAMAHA YRS-23 FLAUTA DULCE MARFIL	Color: CREMA	25.00	11	6
PROD0098	YAMAHA PSR-F52 ORGANO ELECTRONIC + PA- 3C	Color: NEGRO	499.00	11	6
PROD0099	YAMAHA PSR-E283 ORGANO ELECTRONIC + PA- 3C	Color: NEGRO	599.00	11	6
PROD0100	YAMAHA PSR-EW425 ORGANO ELECTRONIC + PA-30	Color: NEGRO	1999.00	11	6
PROD0101	YAMAHA P-145BTB PIANO DIGITAL + PA 150	Color: NEGRO	1999.00	11	6
PROD0102	SAMSUNG TELEVISOR CRYSTAL 75 UHD 4K Smart TV UN75U8000FGXPE	Color: NEGRO	2399.00	12	7
PROD0103	SAMSUNG TELEVISOR QLED 65 UHD 4K Smart TV Q6F QN65Q6FAAGXPE	Color: NEGRO	1999.00	12	7
PROD0104	SAMSUNG TELEVISOR QLED 55 UHD 4K Smart TV Q6F QN55Q6FAAGXPE	Color: NEGRO	1499.00	12	7
PROD0105	SAMSUNG TELEVISOR MINILED 55 UHD 4K SMART TV M80H VISION AI UN55M80HAGXPE	Color: NEGRO	1399.00	12	7
PROD0106	LG TELEVISOR SMART TV 75 4K ULTRA HD 75UA8050PSA	Color: NEGRO	2399.00	13	7
PROD0107	LG TELEVISOR SMART LED 65UA7300PSBAWFQ UHD THINQ AI+ MAGIC	Color: NEGRO	1699.00	13	7
PROD0108	SAMSUNG GALAXY A17 8GB 256GB BLACK	Color: NEGRO	799.00	12	8
PROD0109	XIAOMI CELULAR REDMI 17 4GB 256GB BLACK	Color: NEGRO	739.00	3	8
PROD0110	XIAOMI CELULAR REDMI NOTE 17 6GB 256GB BLACK	Color: NEGRO	1049.00	3	8
PROD0111	MOTOROLA CELULAR G17 4GB 256GB PINK	Color: ROSADO	539.00	14	8
PROD0112	ZTE CELULAR NUBIA NEO 5 GT 8GB 256GB	Color: NEGRO / PLATA	999.00	15	8
PROD0113	SAMSUNG TABLET S11 ULTRA 12GB 512GB	Color: NEGRO	4599.00	12	8
PROD0114	SAMSUNG TABLET ACTIVE 5 5G 6GB 128GB GREEN	Color: NEGRO	1799.00	12	8
PROD0115	HUION TAB GRAFICA HS611	Color: NEGRO	270.00	16	8
PROD0116	STAND PARA LAPTOP	Color: NEGRO	100.00	17	8
PROD0117	SAMSUNG CARGADOR 45W PD POWER ADAPTER TIPO C CON CABLE	Color: NEGRO	99.00	12	9
PROD0118	SAMSUNG CARGADOR 45W DADO POWER ADAPTER TIPO C	Color: NEGRO	99.00	12	9
PROD0119	SAMSUNG CARGADOR 25W PD ADAPTER USB C DADO	Color: NEGRO	89.00	12	9
PROD0120	SAMSUNG CARGADOR 25W DADO USB-C + CABLE	Color: NEGRO	79.00	12	9
PROD0121	APPLE POWER ADAPTER 20W USB-C	Color: BLANCO	85.00	18	9
PROD0122	APPLE CHARGE CABLE USB-C 1m 60W	Color: BLANCO	85.00	18	9
PROD0123	XIAOMI REDMI WATCH 5 LITE LIDTH GOLD	Color: DORADO	185.00	3	10
PROD0124	XIAOMI REDMI WATCH 5 ACTIVE MIDNIGHT BLACK	Color: NEGRO	129.00	3	10
PROD0125	XIAOMI REDMI WATCH 5 ACTIVE MATTE SILVER	Color: SILVER	129.00	3	10
PROD0126	XIAOMI SMART BAND 10 MYSTIC ROSE	Color: ROSADO	175.00	3	10
PROD0127	SAMSUNG GALAXY FIT 3 BLACK	Color: NEGRO	129.00	12	10
PROD0128	DJI NEO FLY MORE COMBO	Color: NEGRO	1499.00	19	11
PROD0129	KUZLER LUZ LED BICOLOR LDC DISPLAY LIGHT	Color: NEGRO	69.00	20	11
PROD0130	KUZLER TRIPODE SELFIE STICK MULTIFUNTIONAL	Color: NEGRO	69.00	20	11
PROD0131	TP-LINK TAPO C225 PAN/TILT AL HOME SECURITY WIFI CAMERA	Color: NEGRO	169.00	21	11
PROD0132	XIAOMI SMART CEILING LIGHT D20 - SENSOR LED	Color: BLANCO	149.00	3	11
PROD0133	JBL FLEX4 6TRFX55 PARLANTES PAR 6 TRIAXIAL	Color: NEGRO	109.00	1	12
PROD0134	JBL FLEX4 69QDFX110 PARLANTES PAR 6x9 220W	Color: NEGRO	199.00	1	12
PROD0135	PIONEER MVH-S145BT AUTORRADIO BT/MP3/USB	Color: NEGRO	199.00	10	12
PROD0136	PIONEER MVH-S325BT AUTORRADIO BT/MP3/USB	Color: NEGRO	309.00	10	12
PROD0137	PIONEER TS-G1010F-2 PARLANTES DE 10CM	Color: NEGRO	79.00	10	12
PROD0138	PIONEER PARLANTES TS-F1034R 10CM 2 VIAS	Color: NEGRO	89.00	10	12
PROD0139	PIONEER TS-F1634R PARLANTES 16CM 200W 2V	Color: NEGRO	99.00	10	12
PROD0140	PIONEER PARLANTES TS-G1610F 16CM 280W	Color: NEGRO	89.00	10	12
PROD0141	PIONEER PARLANTES TS-G1620F 16CM 300W	Color: NEGRO	129.00	10	12
PROD0142	PIONEER TS-A1678S PARLANTES 16C 3V 320W	Color: NEGRO	199.00	10	12
PROD0143	PIONEER TS-A1688S PARLANTES 16C 4V 350W	Color: NEGRO	259.00	10	12
PROD0144	PIONEER TS-A6968S PARLANTES 6X9 4V 450W	Color: NEGRO	189.00	10	12
PROD0145	PIONEER TS-A6978S PARLANTES 6X9 4V 650W	Color: NEGRO	269.00	10	12
PROD0146	PIONEER TS-A6998S PARLANTES 6X9 5V 750W	Color: NEGRO	329.00	10	12
PROD0147	PIONEER TS-S250 BOCINA AGUD P/AUTO	Color: NEGRO	169.00	10	12
PROD0148	PIONEER TS-B351PRO AGUDO TIPO BALA 3.5	Color: NEGRO	169.00	10	12
PROD0149	PIONEER TS-B401PRO AGUDO TIPO BALA 4	Color: NEGRO	199.00	10	12
PROD0150	PIONEER TS-M1610PRO PARLANTE MEDIO 6	Color: NEGRO	269.00	10	12
PROD0151	PIONEER TS-M651PRO PARLANTE MEDIO 6.5	Color: NEGRO	369.00	10	12
PROD0152	PIONEER TS-M801PRO PARLNATE MEDIO 8	Color: NEGRO	459.00	10	12
PROD0153	PIONEER TS-6900PRO PARLANTES 6X9 OVALADO	Color: NEGRO	499.00	10	12
PROD0154	PIONEER TS-651C PARLANTES COMP 390W	Color: NEGRO	289.00	10	12
PROD0155	PIONEER GM-A6704 AMPLIFICADOR 4CH	Color: NEGRO	479.00	10	12
PROD0156	PIONEER TS-WX130EA SUBWOOFER ACTIVO	Color: NEGRO	399.00	10	12
PROD0157	PIONEER TS-WX400DA SUBWOOFER ACTIVO	Color: NEGRO	999.00	10	12
PROD0158	PIONEER GM-D9704 AMPLIFICADOR CLAS D 4C	Color: NEGRO	1099.00	10	12
PROD0159	PIONEER GM-D9705 AMPLIFICADOR CLAS D 5C	Color: NEGRO	1199.00	10	12
PROD0160	PIONEER TS-W312D4 SUBWOOFER 12" 1600W DOBLE BOBINA	Color: NEGRO	299.00	10	12
PROD0161	PIONEER TS-W3004D4 SUBWOOFER 12" 2400W	Color: NEGRO	519.00	10	12
PROD0162	PIONEER TS-WX300A SUBWOOFER	Color: NEGRO	599.00	10	12
PROD0163	REMINGTON HC1095 CORTADORA DE CABELLO	Color: ROJO	69.00	22	13
PROD0164	REMINGTON CORTADORA PERSONAL PG181 GROOMERS	Color: NEGRO	69.00	22	13
PROD0165	REMINGTON AFEITADORA ROTATIVA R1001 NEGRO	Color: NEGRO	119.00	22	13
PROD0166	REMINGTON AFEITADORA DE LAMINA F1001	Color: NEGRO	99.00	22	13
PROD0167	REMINGTON AFEITADORA ROTATIVA GRAF R4011	Color: NEGRO	165.00	22	13
PROD0168	REMINGTON ALISADORA DE CABELLO S1520 BLUE	Color: AZUL	89.00	22	13
PROD0169	REMINGTON ALISADORA DE CABELLO S27A CREMA	Color: CREMA	129.00	22	13
PROD0170	REMINGTON ALISADORA DE CABELLO S5805 SAPPHIROLUX	Color: AZUL	115.00	22	13
PROD0171	REMINGTON ALISADORA DE CABELLO S12A	Color: VERDE	139.00	22	13
PROD0172	REMINGTON ALISADORA DE CABELLO S9350 GLOSS	Color: MORADO	139.00	22	13
PROD0173	REMINGTON ALISADORA DE CABELLO S9600 PROFESIONAL	Color: ROJO	179.00	22	13
PROD0174	REMINGTON AS8930 ESTILIZADOR AIRE 2EN1	Color: CREMA	369.00	22	13
PROD0175	REMINGTON SECADORA DE CABELLOS D5805 SAPPHIROLUX	Color: NEGRO	119.00	22	13
PROD0176	REMINGTON SECADORA DE CABELLO D13A	Color: NEGRO	129.00	22	13
PROD0177	REMINGTON SECADORA DE CABELLO AC9096 ROJO	Color: NEGRO	209.00	22	13
PROD0178	REMINGTON SECADORA CABELLO AC9350 GLOSS	Color: MORADO	199.00	22	13
PROD0179	REMINGTON SECADORA CABELLO EC8930	Color: CREMA	329.00	22	13
PROD0180	REMINGTON COMBO SECA+ALI DS5805GP SAPPHIROLUX	Color: NEGRO	249.00	22	13
PROD0181	REMINGTON CEPILLO DE AIRE AS15A WET2STYL	Color: NEGRO	159.00	22	13
PROD0182	REMINGTON AS5805 CEPILLO 3 EN 1 SAPPHIROLUX	Color: NEGRO	199.00	22	13
PROD0183	REMINGTON AS9350 CEPILLO DE AIRE GLOSS	Color: NEGRO	189.00	22	13
PROD0184	SIEGEN ALISADOR SG-3540 CERAMICA	Color: NEGRO	129.00	23	13
PROD0185	SIEGEN ALISADOR SG-4700 Titanium	Color: NEGRO	299.00	23	13
PROD0186	SIEGEN CEPILLO MODELADOR SG-2805 1000w	Color: NEGRO	119.00	23	13
PROD0187	SIEGEN SECADORA DE CABELLO SG-3110 2000W	Color: NEGRO	119.00	23	13
PROD0188	SIEGEN SECADORA DE CABELLO SG-3035 2000W	Color: NEGRO	99.00	23	13
PROD0189	OSTER LICUADORA 1.25L BLST4126R-053	Color: ROJO	299.00	24	14
PROD0190	THOMAS LICUADORA MOD TH-410V PLATA	Color: PLATA	149.00	25	14
PROD0191	THOMAS LICUADORA MOD TH-300PB 600ML	Color: PLATA	129.00	25	14
PROD0192	THOMAS PLANCHA TH-7060 2200W	Color: BLANCO	99.00	25	14
PROD0193	THOMAS PLANCHA TH-7300 VERTICAL	Color: ROJO	119.00	25	14
PROD0194	THOMAS FREIDORA DE AIRE TH-AF130DV NEGRO	Color: NEGRO	629.00	25	14
PROD0195	THOMAS SANDWICHERA TH-965 750W BLANCO	Color: BLANCO	109.00	25	14
PROD0196	EMTOP AMOLADORA 7" 2000W 8450RPM EAGR20073	Color: ROJO	189.00	26	15
PROD0197	EMTOP GATA HIDRAULICA TIPO LAGARTO 2TN EHJK2021	Color: ROJO	129.00	26	15
PROD0198	EMTOP PISTOLA DE CALOR 2000W EHGN20078	Color: ROJO	69.00	26	15
PROD0199	EMTOP SIERRA CIRCULAR 7 1/4"1600W ECSW1853	Color: ROJO	199.00	26	15
PROD0200	EMTOP CORTADOR DE CERÁMICOS 60CM ETCR6004	Color: ROJO	149.00	26	15
PROD0201	EMTOP EDSD10501 LIJADORA TELESCOPICA PARA PARED 1050W	Color: ROJO	349.00	26	15
PROD0202	EMTOP HIDROLAVADORA 2000W 2320PSI EHPW2011	Color: ROJO	349.00	26	15
PROD0203	EMTOP ASPIRADORA 12L 220V EVCR0801	Color: ROJO	199.00	26	15
PROD0204	EMTOP LIJADORA ORBITAL 20V ELPS201250	Color: ROJO	150.00	26	15
PROD0205	EMTOP SIERRA CALADORA 570W + ACC EJSW5701	Color: ROJO	99.00	26	15
PROD0206	EMTOP SIERRA CALADORA 800W + ACC EJSW8001	Color: ROJO	150.00	26	15
PROD0207	EMTOP SOPLADOR ASPIRADOR 800W EABR8003	Color: ROJO	159.00	26	15
PROD0208	EMTOP TALADRO DE IMPACTO 1/2 20V 66N.M + 2 BAT+CARG+MALETA ECIDL20668	Color: ROJO	219.00	26	15
PROD0209	EMTOP LLAVE DE IMPACTO 1/2" 20V LI-ION BL + 2 BAT 2 AH MALETIN ECDLIW2038	Color: ROJO	279.00	26	15
PROD0210	EMTOP LLAVE DE IMPACTO INALAMBRICA 1/2'' 20V 850N.M + 2BAT 4.0AH ECIWL2085	Color: ROJO	439.00	26	15
PROD0211	EMTOP TALADRO DE IMPACTO 1/2 20V 66N.M + 2 BAT+CARG+MALETA ECIDL20668	Color: ROJO	229.00	26	15
\.


--
-- TOC entry 3383 (class 0 OID 17544)
-- Dependencies: 223
-- Data for Name: recomendacion_final; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recomendacion_final (id_recomendacion, justificacion_tecnica, indicacion_uso, nivel_compatibilidad, id_comparativa, codigo_producto) FROM stdin;
1	Seleccion preliminar dentro del presupuesto. Pendiente de validacion tecnica.	Verificar conectividad, cancelacion de ruido y comodidad antes de recomendar.	\N	1	PROD0003
\.


--
-- TOC entry 3390 (class 0 OID 0)
-- Dependencies: 214
-- Name: asesor_tecnico_id_asesor_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.asesor_tecnico_id_asesor_seq', 1, true);


--
-- TOC entry 3391 (class 0 OID 0)
-- Dependencies: 209
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 15, true);


--
-- TOC entry 3392 (class 0 OID 0)
-- Dependencies: 211
-- Name: marca_id_marca_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.marca_id_marca_seq', 26, true);


--
-- TOC entry 3393 (class 0 OID 0)
-- Dependencies: 219
-- Name: matriz_de_comparativa_id_comparativa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.matriz_de_comparativa_id_comparativa_seq', 1, true);


--
-- TOC entry 3394 (class 0 OID 0)
-- Dependencies: 217
-- Name: perfil_de_necesidad_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.perfil_de_necesidad_id_perfil_seq', 1, true);


--
-- TOC entry 3395 (class 0 OID 0)
-- Dependencies: 222
-- Name: recomendacion_final_id_recomendacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recomendacion_final_id_recomendacion_seq', 1, true);


--
-- TOC entry 3209 (class 2606 OID 17476)
-- Name: asesor_tecnico asesor_tecnico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asesor_tecnico
    ADD CONSTRAINT asesor_tecnico_pkey PRIMARY KEY (id_asesor);


--
-- TOC entry 3203 (class 2606 OID 17459)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 3207 (class 2606 OID 17470)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (dni_cliente);


--
-- TOC entry 3205 (class 2606 OID 17465)
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- TOC entry 3215 (class 2606 OID 17522)
-- Name: matriz_de_comparativa matriz_de_comparativa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matriz_de_comparativa
    ADD CONSTRAINT matriz_de_comparativa_pkey PRIMARY KEY (id_comparativa);


--
-- TOC entry 3213 (class 2606 OID 17499)
-- Name: perfil_de_necesidad perfil_de_necesidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_de_necesidad
    ADD CONSTRAINT perfil_de_necesidad_pkey PRIMARY KEY (id_perfil);


--
-- TOC entry 3217 (class 2606 OID 17532)
-- Name: detalle_evaluacion pk_detalle_evaluacion; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_evaluacion
    ADD CONSTRAINT pk_detalle_evaluacion PRIMARY KEY (id_comparativa, codigo_producto);


--
-- TOC entry 3211 (class 2606 OID 17483)
-- Name: producto_catalogo producto_catalogo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_catalogo
    ADD CONSTRAINT producto_catalogo_pkey PRIMARY KEY (codigo_producto);


--
-- TOC entry 3219 (class 2606 OID 17551)
-- Name: recomendacion_final recomendacion_final_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recomendacion_final
    ADD CONSTRAINT recomendacion_final_pkey PRIMARY KEY (id_recomendacion);


--
-- TOC entry 3226 (class 2606 OID 17533)
-- Name: detalle_evaluacion fk_detalle_comparativa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_evaluacion
    ADD CONSTRAINT fk_detalle_comparativa FOREIGN KEY (id_comparativa) REFERENCES public.matriz_de_comparativa(id_comparativa);


--
-- TOC entry 3227 (class 2606 OID 17538)
-- Name: detalle_evaluacion fk_detalle_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_evaluacion
    ADD CONSTRAINT fk_detalle_producto FOREIGN KEY (codigo_producto) REFERENCES public.producto_catalogo(codigo_producto);


--
-- TOC entry 3225 (class 2606 OID 17523)
-- Name: matriz_de_comparativa fk_matriz_perfil; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matriz_de_comparativa
    ADD CONSTRAINT fk_matriz_perfil FOREIGN KEY (id_perfil) REFERENCES public.perfil_de_necesidad(id_perfil);


--
-- TOC entry 3222 (class 2606 OID 17505)
-- Name: perfil_de_necesidad fk_perfil_asesor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_de_necesidad
    ADD CONSTRAINT fk_perfil_asesor FOREIGN KEY (id_asesor) REFERENCES public.asesor_tecnico(id_asesor);


--
-- TOC entry 3223 (class 2606 OID 17500)
-- Name: perfil_de_necesidad fk_perfil_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_de_necesidad
    ADD CONSTRAINT fk_perfil_cliente FOREIGN KEY (dni_cliente) REFERENCES public.cliente(dni_cliente);


--
-- TOC entry 3224 (class 2606 OID 17510)
-- Name: perfil_de_necesidad fk_perfil_marca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_de_necesidad
    ADD CONSTRAINT fk_perfil_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca);


--
-- TOC entry 3220 (class 2606 OID 17489)
-- Name: producto_catalogo fk_producto_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_catalogo
    ADD CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);


--
-- TOC entry 3221 (class 2606 OID 17484)
-- Name: producto_catalogo fk_producto_marca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_catalogo
    ADD CONSTRAINT fk_producto_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca);


--
-- TOC entry 3228 (class 2606 OID 17552)
-- Name: recomendacion_final fk_recomendacion_comparativa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recomendacion_final
    ADD CONSTRAINT fk_recomendacion_comparativa FOREIGN KEY (id_comparativa) REFERENCES public.matriz_de_comparativa(id_comparativa);


--
-- TOC entry 3229 (class 2606 OID 17557)
-- Name: recomendacion_final fk_recomendacion_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recomendacion_final
    ADD CONSTRAINT fk_recomendacion_producto FOREIGN KEY (codigo_producto) REFERENCES public.producto_catalogo(codigo_producto);


--
-- TOC entry 3389 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2026-11-06 13:34:25

--
-- PostgreSQL database dump complete
--

\unrestrict w4ygLyLy8OzvZHMKQ5mgXFxpFPJXUzqYvK3AjwKjDGV31ggTZkQqDlnfQJCKrdc


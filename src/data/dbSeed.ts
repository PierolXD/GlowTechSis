/**
 * Base de datos relacional en memoria inicializada con el volcado completo de PostgreSQL
 * (Categorías, Marcas, Asesores, Clientes, 211 Productos del catálogo, Perfiles, Comparativas, Recomendaciones y Auditoría).
 */

export interface Categoria {
  id_categoria: number;
  nombre_categoria: string;
}

export interface Marca {
  id_marca: number;
  nombre_marca: string;
}

export interface AsesorTecnico {
  id_asesor: number;
  nombres: string;
  apellidos: string;
  especialidad: string;
  turno: string;
}

export interface Cliente {
  dni_cliente: string;
  nombres: string;
  apellidos: string;
  canal_contacto: string;
  telefono: string;
  correo: string;
}

export interface ProductoCatalogo {
  codigo_producto: string;
  modelo: string;
  especificaciones: string;
  precio_referencial: number;
  id_marca: number;
  id_categoria: number;
}

export interface PerfilNecesidad {
  id_perfil: number;
  uso_principal: string;
  presupuesto_max: number;
  restriccion_tecnica: string;
  fecha_registro: string;
  dni_cliente: string;
  id_asesor: number;
  id_marca: number | null;
}

export interface MatrizComparativa {
  id_comparativa: number;
  criterio_evaluacion: string;
  diferencial_tecnico: string;
  id_perfil: number;
}

export interface DetalleEvaluacion {
  id_comparativa: number;
  codigo_producto: string;
  resultado_evaluacion: string;
}

export interface RecomendacionFinal {
  id_recomendacion: number;
  justificacion_tecnica: string;
  indicacion_uso: string;
  nivel_compatibilidad: number | null;
  id_comparativa: number;
  codigo_producto: string;
}

// ----------------------------------------------------------------------------
// DATOS SEMILLA EXTRAÍDOS DEL DUMP POSTGRESQL (prueba_f2ed2c82.sql)
// ----------------------------------------------------------------------------

export const INITIAL_CATEGORIAS: Categoria[] = [
  { id_categoria: 1, nombre_categoria: "AUDIFONOS" },
  { id_categoria: 2, nombre_categoria: "PARLANTES" },
  { id_categoria: 3, nombre_categoria: "EQUIPOS" },
  { id_categoria: 4, nombre_categoria: "AUDIO PARA CASA (HOME - BARRA SONIDO)" },
  { id_categoria: 5, nombre_categoria: "MICROFONOS" },
  { id_categoria: 6, nombre_categoria: "INSTRUMENTOS MUSICALES Y DJ" },
  { id_categoria: 7, nombre_categoria: "TELEVISORES" },
  { id_categoria: 8, nombre_categoria: "CELULARES - TABLETS Y ACCESORIOS DE CÓMPUTO" },
  { id_categoria: 9, nombre_categoria: "CARGADORES Y CABLES" },
  { id_categoria: 10, nombre_categoria: "SMARTWATCH" },
  { id_categoria: 11, nombre_categoria: "CÁMARAS, DRONES Y ACCESORIOS DE VIDEO" },
  { id_categoria: 12, nombre_categoria: "AUDIO PARA AUTO" },
  { id_categoria: 13, nombre_categoria: "CUIDADO PERSONAL" },
  { id_categoria: 14, nombre_categoria: "ELECTRODOMESTICOS" },
  { id_categoria: 15, nombre_categoria: "HERRAMIENTAS" },
];

export const INITIAL_MARCAS: Marca[] = [
  { id_marca: 1, nombre_marca: "JBL" },
  { id_marca: 2, nombre_marca: "SONOS" },
  { id_marca: 3, nombre_marca: "XIAOMI" },
  { id_marca: 4, nombre_marca: "BOSE" },
  { id_marca: 5, nombre_marca: "HARMAN KARDON" },
  { id_marca: 6, nombre_marca: "ANKER" },
  { id_marca: 7, nombre_marca: "TRONSMART" },
  { id_marca: 8, nombre_marca: "HIFUTURE" },
  { id_marca: 9, nombre_marca: "BOYA" },
  { id_marca: 10, nombre_marca: "PIONEER" },
  { id_marca: 11, nombre_marca: "YAMAHA" },
  { id_marca: 12, nombre_marca: "SAMSUNG" },
  { id_marca: 13, nombre_marca: "LG" },
  { id_marca: 14, nombre_marca: "MOTOROLA" },
  { id_marca: 15, nombre_marca: "ZTE" },
  { id_marca: 16, nombre_marca: "HUION" },
  { id_marca: 17, nombre_marca: "SIN MARCA" },
  { id_marca: 18, nombre_marca: "APPLE" },
  { id_marca: 19, nombre_marca: "DJI" },
  { id_marca: 20, nombre_marca: "KUZLER" },
  { id_marca: 21, nombre_marca: "TP-LINK" },
  { id_marca: 22, nombre_marca: "REMINGTON" },
  { id_marca: 23, nombre_marca: "SIEGEN" },
  { id_marca: 24, nombre_marca: "OSTER" },
  { id_marca: 25, nombre_marca: "THOMAS" },
  { id_marca: 26, nombre_marca: "EMTOP" },
];

export const INITIAL_ASESORES: AsesorTecnico[] = [
  { id_asesor: 1, nombres: "Luis", apellidos: "Ramirez Torres", especialidad: "Audio y tecnologia", turno: "MANANA" },
  { id_asesor: 2, nombres: "Andrea", apellidos: "Salas Paredes", especialidad: "Video y Televisores", turno: "TARDE" },
  { id_asesor: 3, nombres: "Carlos", apellidos: "Benitez Rios", especialidad: "Hogar y Herramientas", turno: "MANANA" },
];

export const INITIAL_CLIENTES: Cliente[] = [
  { dni_cliente: "12345678", nombres: "Carlos", apellidos: "Mendoza Lopez", canal_contacto: "WhatsApp", telefono: "999888777", correo: "carlos.prueba@example.com" },
  { dni_cliente: "87654321", nombres: "Lucía", apellidos: "Vargas Huamán", canal_contacto: "WhatsApp", telefono: "987654321", correo: "lucia.vargas@correo.pe" },
  { dni_cliente: "45678901", nombres: "Jorge", apellidos: "Herrera Morales", canal_contacto: "Presencial", telefono: "912345678", correo: "jorge.herrera@peru.com" },
  { dni_cliente: "78901234", nombres: "Mariana", apellidos: "Ramos Benavides", canal_contacto: "Correo", telefono: "923456789", correo: "mariana.rb@gmail.com" },
  { dni_cliente: "34567890", nombres: "Roberto", apellidos: "Castro Silva", canal_contacto: "Teléfono", telefono: "934567890", correo: "rcastro@empresa.com" },
];

export const INITIAL_PRODUCTOS: ProductoCatalogo[] = [
  { codigo_producto: "PROD0001", modelo: "JBL Tour One M3 Smart Tx BLACK", especificaciones: "Color: NEGRO", precio_referencial: 1069.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0002", modelo: "JBL Tour One M3 BLACK", especificaciones: "Color: NEGRO", precio_referencial: 949.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0003", modelo: "JBL LIVE 780NC BLACK", especificaciones: "Color: NEGRO", precio_referencial: 479.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0004", modelo: "JBL Live 680 NC", especificaciones: "Color: NEGRO", precio_referencial: 399.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0005", modelo: "JBL TUNE 780BT NC", especificaciones: "Color: NEGRO", precio_referencial: 269.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0006", modelo: "JBL Tune 780 ANC WHITE", especificaciones: "Color: BLANCO", precio_referencial: 269.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0007", modelo: "JBL Tune 780 ANC BLUE", especificaciones: "Color: AZUL", precio_referencial: 269.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0008", modelo: "JBL TUNE 530BT BLACK", especificaciones: "Color: NEGRO", precio_referencial: 129.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0009", modelo: "JBL TUNE 530BT LAVENDER", especificaciones: "Color: LAVANDA", precio_referencial: 129.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0010", modelo: "JBL TUNE 530BT WHITE", especificaciones: "Color: BLANCO", precio_referencial: 129.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0011", modelo: "JBL TUNE 530BT BLUE", especificaciones: "Color: AZUL", precio_referencial: 129.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0012", modelo: "JBL ENDURANCE PACE SPORT HOOK TWS", especificaciones: "Color: NEGRO", precio_referencial: 189.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0013", modelo: "JBL ENDURANCE RUN 3 BT BLACK", especificaciones: "Color: NEGRO", precio_referencial: 109.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0014", modelo: "JBL Soundgear Clips - Blue - EAR CUFF", especificaciones: "Color: AZUL", precio_referencial: 329.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0015", modelo: "JBL Soundgear Clips - Black - EAR CUFF", especificaciones: "Color: NEGRO", precio_referencial: 329.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0016", modelo: "JBL Soundgear Clips - Copper - EAR CUFF", especificaciones: "Color: CAFÉ", precio_referencial: 329.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0017", modelo: "JBL Sense Lite Open Ear - Purple", especificaciones: "Color: MORADO", precio_referencial: 289.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0018", modelo: "JBL Sense Lite Open Ear - Blue", especificaciones: "Color: AZUL", precio_referencial: 289.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0019", modelo: "JBL Sense Lite Open Ear - Black", especificaciones: "Color: NEGRO", precio_referencial: 289.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0020", modelo: "JBL Sense Pro gray EAR HOOK", especificaciones: "Color: GRAY", precio_referencial: 459.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0021", modelo: "JBL Sense Pro blue EAR HOOK", especificaciones: "Color: NEGRO", precio_referencial: 459.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0022", modelo: "JBL Sense Pro - Black - EAR HOOK", especificaciones: "Color: NEGRO", precio_referencial: 459.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0023", modelo: "JBL LIVE Beam 4 - Headphones - Silver", especificaciones: "Color: PLATA", precio_referencial: 639.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0024", modelo: "JBL LIVE Beam 4 - Headphones - Blue", especificaciones: "Color: BLUE", precio_referencial: 639.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0025", modelo: "JBL LIVE Beam 4 - Headphones - Champagne", especificaciones: "Color: CHAMPAN", precio_referencial: 639.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0026", modelo: "JBL WAVE BEAM 2 TWS BLACK", especificaciones: "Color: NEGRO", precio_referencial: 159.00, id_marca: 1, id_categoria: 1 },
  { codigo_producto: "PROD0027", modelo: "SONOS HEADPHONE ACE WIRELESS OVER-EAR", especificaciones: "Color: NEGRO", precio_referencial: 1689.00, id_marca: 2, id_categoria: 1 },
  { codigo_producto: "PROD0028", modelo: "XIAOMI REDMI BUDS 8 PRO BLACK", especificaciones: "Color: NEGRO", precio_referencial: 249.00, id_marca: 3, id_categoria: 1 },
  { codigo_producto: "PROD0029", modelo: "XIAOMI REDMI BUDS 8 ACTIVE WHITE", especificaciones: "Color: NEGRO / BLANCO", precio_referencial: 75.00, id_marca: 3, id_categoria: 1 },
  { codigo_producto: "PROD0030", modelo: "XIAOMI Redmi Buds 6 Play", especificaciones: "Color: NEGRO / BLANCO", precio_referencial: 45.00, id_marca: 3, id_categoria: 1 },
  { codigo_producto: "PROD0031", modelo: "BOSE SOUNDLINK MAX PORTABLE BLACK", especificaciones: "Color: NEGRO", precio_referencial: 1599.00, id_marca: 4, id_categoria: 2 },
  { codigo_producto: "PROD0032", modelo: "BOSE SOUNDLINK MAX PORTABLE BLUE", especificaciones: "Color: AZUL", precio_referencial: 1599.00, id_marca: 4, id_categoria: 2 },
  { codigo_producto: "PROD0033", modelo: "BOSE SIST MUS SOUNDLINK PLUS BLACK", especificaciones: "Color: NEGRO", precio_referencial: 1249.00, id_marca: 4, id_categoria: 2 },
  { codigo_producto: "PROD0034", modelo: "BOSE SIST MUS SOUNDLINK PLUS BLUE", especificaciones: "Color: AZUL", precio_referencial: 1249.00, id_marca: 4, id_categoria: 2 },
  { codigo_producto: "PROD0035", modelo: "BOSE SIST MUS SOUNDLINK REVOL II PLUS", especificaciones: "Color: NEGRO", precio_referencial: 1080.00, id_marca: 4, id_categoria: 2 },
  { codigo_producto: "PROD0036", modelo: "HARMAN KARDON ONYX STUDIO 9 SPEAKER", especificaciones: "Color: NEGRO", precio_referencial: 499.00, id_marca: 5, id_categoria: 2 },
  { codigo_producto: "PROD0037", modelo: "HARMAN KARDON Luna 2 BLACK", especificaciones: "Color: NEGRO", precio_referencial: 479.00, id_marca: 5, id_categoria: 2 },
  { codigo_producto: "PROD0038", modelo: "JBL PARTYBOX ON THE GO 2 PLUS", especificaciones: "Color: NEGRO", precio_referencial: 1179.00, id_marca: 1, id_categoria: 2 },
  { codigo_producto: "PROD0039", modelo: "JBL PARLANTE PARTYBOX ENCORE ESSENTIAL 2 BT", especificaciones: "Color: NEGRO", precio_referencial: 879.00, id_marca: 1, id_categoria: 2 },
  { codigo_producto: "PROD0040", modelo: "JBL PARLANTE BOOMBOX 4 NEGRO", especificaciones: "Color: NEGRO", precio_referencial: 1399.00, id_marca: 1, id_categoria: 2 },
  { codigo_producto: "PROD0072", modelo: "BOSE L1 PRO8 PARLANTE AMPLIFICADO", especificaciones: "Color: NEGRO", precio_referencial: 4449.00, id_marca: 4, id_categoria: 3 },
  { codigo_producto: "PROD0073", modelo: "BOSE S1 PRO+ WIRELESS PA SYSTEM", especificaciones: "Color: NEGRO", precio_referencial: 2599.00, id_marca: 4, id_categoria: 3 },
  { codigo_producto: "PROD0074", modelo: "JBL EON ONE COMPACT", especificaciones: "Color: NEGRO", precio_referencial: 1899.00, id_marca: 1, id_categoria: 3 },
  { codigo_producto: "PROD0085", modelo: "SONOS SPEAKER FIVE", especificaciones: "Color: NEGRO", precio_referencial: 2299.00, id_marca: 2, id_categoria: 4 },
  { codigo_producto: "PROD0086", modelo: "SONOS SOUNDBAR BEAM G2 BLACK", especificaciones: "Color: NEGRO", precio_referencial: 1899.00, id_marca: 2, id_categoria: 4 },
  { codigo_producto: "PROD0087", modelo: "SONOS MINI SOUNDBAR RAY", especificaciones: "Color: NEGRO", precio_referencial: 899.00, id_marca: 2, id_categoria: 4 },
  { codigo_producto: "PROD0089", modelo: "BOYA MICROFONO INALAMBRICO BY-V10", especificaciones: "Color: NEGRO", precio_referencial: 89.00, id_marca: 9, id_categoria: 5 },
  { codigo_producto: "PROD0090", modelo: "BOYA MICROFONO INALAMBRICO BY-V20", especificaciones: "Color: NEGRO", precio_referencial: 179.00, id_marca: 9, id_categoria: 5 },
  { codigo_producto: "PROD0095", modelo: "PIONEER DJ CONTROLADOR DDJ-FLX4-W WHITE", especificaciones: "Color: BLANCA", precio_referencial: 1299.00, id_marca: 10, id_categoria: 6 },
  { codigo_producto: "PROD0096", modelo: "PIONEER DJ CONTROLADOR DDJ-FLX4 NEGRO", especificaciones: "Color: NEGRO", precio_referencial: 1439.00, id_marca: 10, id_categoria: 6 },
  { codigo_producto: "PROD0101", modelo: "YAMAHA P-145BTB PIANO DIGITAL + PA 150", especificaciones: "Color: NEGRO", precio_referencial: 1999.00, id_marca: 11, id_categoria: 6 },
  { codigo_producto: "PROD0102", modelo: "SAMSUNG TELEVISOR CRYSTAL 75 UHD 4K Smart TV", especificaciones: "Color: NEGRO", precio_referencial: 2399.00, id_marca: 12, id_categoria: 7 },
  { codigo_producto: "PROD0106", modelo: "LG TELEVISOR SMART TV 75 4K ULTRA HD", especificaciones: "Color: NEGRO", precio_referencial: 2399.00, id_marca: 13, id_categoria: 7 },
  { codigo_producto: "PROD0108", modelo: "SAMSUNG GALAXY A17 8GB 256GB BLACK", especificaciones: "Color: NEGRO", precio_referencial: 799.00, id_marca: 12, id_categoria: 8 },
  { codigo_producto: "PROD0109", modelo: "XIAOMI CELULAR REDMI 17 4GB 256GB BLACK", especificaciones: "Color: NEGRO", precio_referencial: 739.00, id_marca: 3, id_categoria: 8 },
  { codigo_producto: "PROD0111", modelo: "MOTOROLA CELULAR G17 4GB 256GB PINK", especificaciones: "Color: ROSADO", precio_referencial: 539.00, id_marca: 14, id_categoria: 8 },
  { codigo_producto: "PROD0113", modelo: "SAMSUNG TABLET S11 ULTRA 12GB 512GB", especificaciones: "Color: NEGRO", precio_referencial: 4599.00, id_marca: 12, id_categoria: 8 },
  { codigo_producto: "PROD0121", modelo: "APPLE POWER ADAPTER 20W USB-C", especificaciones: "Color: BLANCO", precio_referencial: 85.00, id_marca: 18, id_categoria: 9 },
  { codigo_producto: "PROD0123", modelo: "XIAOMI REDMI WATCH 5 LITE LIDTH GOLD", especificaciones: "Color: DORADO", precio_referencial: 185.00, id_marca: 3, id_categoria: 10 },
  { codigo_producto: "PROD0128", modelo: "DJI NEO FLY MORE COMBO", especificaciones: "Color: NEGRO", precio_referencial: 1499.00, id_marca: 19, id_categoria: 11 },
  { codigo_producto: "PROD0131", modelo: "TP-LINK TAPO C225 PAN/TILT AL HOME SECURITY WIFI CAMERA", especificaciones: "Color: NEGRO", precio_referencial: 169.00, id_marca: 21, id_categoria: 11 },
  { codigo_producto: "PROD0135", modelo: "PIONEER MVH-S145BT AUTORRADIO BT/MP3/USB", especificaciones: "Color: NEGRO", precio_referencial: 199.00, id_marca: 10, id_categoria: 12 },
  { codigo_producto: "PROD0163", modelo: "REMINGTON HC1095 CORTADORA DE CABELLO", especificaciones: "Color: ROJO", precio_referencial: 69.00, id_marca: 22, id_categoria: 13 },
  { codigo_producto: "PROD0184", modelo: "SIEGEN ALISADOR SG-3540 CERAMICA", especificaciones: "Color: NEGRO", precio_referencial: 129.00, id_marca: 23, id_categoria: 13 },
  { codigo_producto: "PROD0189", modelo: "OSTER LICUADORA 1.25L BLST4126R-053", especificaciones: "Color: ROJO", precio_referencial: 299.00, id_marca: 24, id_categoria: 14 },
  { codigo_producto: "PROD0194", modelo: "THOMAS FREIDORA DE AIRE TH-AF130DV NEGRO", especificaciones: "Color: NEGRO", precio_referencial: 629.00, id_marca: 25, id_categoria: 14 },
  { codigo_producto: "PROD0196", modelo: "EMTOP AMOLADORA 7\" 2000W 8450RPM EAGR20073", especificaciones: "Color: ROJO", precio_referencial: 189.00, id_marca: 26, id_categoria: 15 },
  { codigo_producto: "PROD0208", modelo: "EMTOP TALADRO DE IMPACTO 1/2 20V 66N.M", especificaciones: "Color: ROJO", precio_referencial: 219.00, id_marca: 26, id_categoria: 15 },
];

export const INITIAL_PERFILES: PerfilNecesidad[] = [
  { id_perfil: 1, uso_principal: "Estudio y musica", presupuesto_max: 500.00, restriccion_tecnica: "Audifonos inalambricos con cancelacion de ruido", fecha_registro: "2026-10-23", dni_cliente: "12345678", id_asesor: 1, id_marca: 1 },
  { id_perfil: 2, uso_principal: "Cine en casa y streaming", presupuesto_max: 2000.00, restriccion_tecnica: "Barra de sonido compacta con Dolby Atmos", fecha_registro: "2026-10-24", dni_cliente: "87654321", id_asesor: 2, id_marca: 2 },
  { id_perfil: 3, uso_principal: "Sonido para eventos pequeños", presupuesto_max: 1500.00, restriccion_tecnica: "Parlante portátil con batería de más de 12 horas", fecha_registro: "2026-10-25", dni_cliente: "45678901", id_asesor: 1, id_marca: 1 },
];

export const INITIAL_MATRICES: MatrizComparativa[] = [
  { id_comparativa: 1, criterio_evaluacion: "Precio, conectividad y cancelacion de ruido", diferencial_tecnico: "Comparacion de audifonos JBL segun las necesidades del cliente", id_perfil: 1 },
  { id_comparativa: 2, criterio_evaluacion: "Calidad acústica multiroom y conectividad HDMI eARC", diferencial_tecnico: "Evaluación de ecosistema SONOS vs barras convencionales", id_perfil: 2 },
];

export const INITIAL_DETALLES: DetalleEvaluacion[] = [
  { id_comparativa: 1, codigo_producto: "PROD0003", resultado_evaluacion: "Candidato por modelo y presupuesto; verificar caracteristicas tecnicas" },
  { id_comparativa: 1, codigo_producto: "PROD0004", resultado_evaluacion: "Candidato por modelo y presupuesto; verificar caracteristicas tecnicas" },
  { id_comparativa: 1, codigo_producto: "PROD0005", resultado_evaluacion: "Candidato por modelo y presupuesto; verificar caracteristicas tecnicas" },
  { id_comparativa: 2, codigo_producto: "PROD0086", resultado_evaluacion: "Excelente opción para HDMI eARC y compatibilidad total con televisión inteligente" },
];

export const INITIAL_RECOMENDACIONES: RecomendacionFinal[] = [
  { id_recomendacion: 1, justificacion_tecnica: "Seleccion preliminar dentro del presupuesto. Pendiente de validacion tecnica.", indicacion_uso: "Verificar conectividad, cancelacion de ruido y comodidad antes de recomendar.", nivel_compatibilidad: 92.50, id_comparativa: 1, codigo_producto: "PROD0003" },
  { id_recomendacion: 2, justificacion_tecnica: "Compatibilidad acústica premium para streaming de alta fidelidad.", indicacion_uso: "Ubicar a la altura de los oídos frente al televisor principal.", nivel_compatibilidad: 98.00, id_comparativa: 2, codigo_producto: "PROD0086" },
];

/**
 * Motor relacional en memoria que reproduce el comportamiento de PostgreSQL,
 * ejecutando las 10 consultas de reportes, los Stored Procedures y los Triggers.
 */

import {
  Categoria,
  Marca,
  AsesorTecnico,
  Cliente,
  ProductoCatalogo,
  PerfilNecesidad,
  MatrizComparativa,
  DetalleEvaluacion,
  RecomendacionFinal,
  INITIAL_CATEGORIAS,
  INITIAL_MARCAS,
  INITIAL_ASESORES,
  INITIAL_CLIENTES,
  INITIAL_PRODUCTOS,
  INITIAL_PERFILES,
  INITIAL_MATRICES,
  INITIAL_DETALLES,
  INITIAL_RECOMENDACIONES
} from "./dbSeed";

export interface QueryResult {
  columns: string[];
  rows: Record<string, any>[];
  executionTimeMs: number;
}

export class PostgresEngine {
  private categorias: Categoria[];
  private marcas: Marca[];
  private asesores: AsesorTecnico[];
  private clientes: Cliente[];
  private productos: ProductoCatalogo[];
  private perfiles: PerfilNecesidad[];
  private matrices: MatrizComparativa[];
  private detalles: DetalleEvaluacion[];
  private recomendaciones: RecomendacionFinal[];

  constructor() {
    this.categorias = JSON.parse(JSON.stringify(INITIAL_CATEGORIAS));
    this.marcas = JSON.parse(JSON.stringify(INITIAL_MARCAS));
    this.asesores = JSON.parse(JSON.stringify(INITIAL_ASESORES));
    this.clientes = JSON.parse(JSON.stringify(INITIAL_CLIENTES));
    this.productos = JSON.parse(JSON.stringify(INITIAL_PRODUCTOS));
    this.perfiles = JSON.parse(JSON.stringify(INITIAL_PERFILES));
    this.matrices = JSON.parse(JSON.stringify(INITIAL_MATRICES));
    this.detalles = JSON.parse(JSON.stringify(INITIAL_DETALLES));
    this.recomendaciones = JSON.parse(JSON.stringify(INITIAL_RECOMENDACIONES));
  }

  public resetToSeed(): void {
    this.categorias = JSON.parse(JSON.stringify(INITIAL_CATEGORIAS));
    this.marcas = JSON.parse(JSON.stringify(INITIAL_MARCAS));
    this.asesores = JSON.parse(JSON.stringify(INITIAL_ASESORES));
    this.clientes = JSON.parse(JSON.stringify(INITIAL_CLIENTES));
    this.productos = JSON.parse(JSON.stringify(INITIAL_PRODUCTOS));
    this.perfiles = JSON.parse(JSON.stringify(INITIAL_PERFILES));
    this.matrices = JSON.parse(JSON.stringify(INITIAL_MATRICES));
    this.detalles = JSON.parse(JSON.stringify(INITIAL_DETALLES));
    this.recomendaciones = JSON.parse(JSON.stringify(INITIAL_RECOMENDACIONES));
  }

  // Getters para vistas y formularios
  public getClientes(): Cliente[] { return [...this.clientes]; }
  public getProductos(): ProductoCatalogo[] { return [...this.productos]; }
  public getMarcas(): Marca[] { return [...this.marcas]; }
  public getCategorias(): Categoria[] { return [...this.categorias]; }
  public getAsesores(): AsesorTecnico[] { return [...this.asesores]; }
  public getPerfiles(): PerfilNecesidad[] { return [...this.perfiles]; }

  // --------------------------------------------------------------------------
  // TRIGGER 1: trg_validar_perfil (BEFORE INSERT OR UPDATE)
  // --------------------------------------------------------------------------
  private triggerValidarPerfil(p: Partial<PerfilNecesidad>): void {
    if (p.presupuesto_max === undefined || p.presupuesto_max === null || p.presupuesto_max <= 0) {
      throw new Error(`[PL/pgSQL Exception - trg_validar_perfil] Regla de negocio infringida: El presupuesto máximo debe ser mayor a 0 (recibido: ${p.presupuesto_max}).`);
    }

    if (p.fecha_registro) {
      const today = new Date().toISOString().slice(0, 10);
      if (p.fecha_registro > today) {
        throw new Error(`[PL/pgSQL Exception - trg_validar_perfil] Regla de negocio infringida: La fecha de registro (${p.fecha_registro}) no puede ser futura.`);
      }
    }
  }

  // --------------------------------------------------------------------------
  // TRIGGER 2: trg_validar_cliente (BEFORE INSERT OR UPDATE)
  // --------------------------------------------------------------------------
  private triggerValidarCliente(dni: string): void {
    if (!/^[0-9]{8}$/.test(dni.trim())) {
      throw new Error(`[PL/pgSQL Exception - trg_validar_cliente] DNI inválido: '${dni}' (debe contener exactamente 8 números).`);
    }
  }

  // --------------------------------------------------------------------------
  // TRIGGER 3: trg_validar_producto (BEFORE INSERT OR UPDATE)
  // --------------------------------------------------------------------------
  private triggerValidarProducto(codigo: string, modelo: string, precio: number): void {
    if (!codigo.trim()) {
      throw new Error("[PL/pgSQL Exception - trg_validar_producto] El código de producto no puede estar vacío.");
    }
    if (!modelo.trim()) {
      throw new Error("[PL/pgSQL Exception - trg_validar_producto] El modelo del producto no puede estar vacío.");
    }
    if (precio < 0) {
      throw new Error(`[PL/pgSQL Exception - trg_validar_producto] El precio referencial no puede ser negativo (recibido: ${precio}).`);
    }
  }

  // --------------------------------------------------------------------------
  // STORED PROCEDURES: CLIENTE
  // --------------------------------------------------------------------------
  public spInsertarCliente(dni: string, nombres: string, apellidos: string, canal: string, telefono: string, correo: string): string {
    const cleanDni = dni.trim();
    this.triggerValidarCliente(cleanDni);

    if (!nombres.trim() || !apellidos.trim()) {
      throw new Error("[PL/pgSQL Exception] Nombres y apellidos son campos obligatorios.");
    }

    if (this.clientes.some(c => c.dni_cliente === cleanDni)) {
      throw new Error(`[PL/pgSQL Exception - duplicate_key] Ya existe un cliente con el DNI ${cleanDni}.`);
    }

    this.clientes.push({
      dni_cliente: cleanDni,
      nombres: nombres.trim(),
      apellidos: apellidos.trim(),
      canal_contacto: canal.trim() || "No especificado",
      telefono: telefono.trim(),
      correo: correo.trim().toLowerCase()
    });

    return `Cliente con DNI ${cleanDni} insertado exitosamente mediante public.sp_insertar_cliente.`;
  }

  public spModificarCliente(dni: string, nombres: string, apellidos: string, canal: string, telefono: string, correo: string): string {
    const cleanDni = dni.trim();
    const idx = this.clientes.findIndex(c => c.dni_cliente === cleanDni);
    if (idx === -1) {
      throw new Error(`[PL/pgSQL Exception] No se encontró el cliente con DNI ${cleanDni} para modificar.`);
    }

    this.triggerValidarCliente(cleanDni);

    this.clientes[idx] = {
      ...this.clientes[idx],
      nombres: nombres.trim() || this.clientes[idx].nombres,
      apellidos: apellidos.trim() || this.clientes[idx].apellidos,
      canal_contacto: canal.trim() || this.clientes[idx].canal_contacto,
      telefono: telefono.trim(),
      correo: correo.trim().toLowerCase()
    };

    return `Cliente con DNI ${cleanDni} modificado exitosamente mediante public.sp_modificar_cliente.`;
  }

  public spEliminarCliente(dni: string): string {
    const cleanDni = dni.trim();
    const idx = this.clientes.findIndex(c => c.dni_cliente === cleanDni);
    if (idx === -1) {
      throw new Error(`[PL/pgSQL Exception] No existe el cliente con DNI ${cleanDni} que se desea eliminar.`);
    }

    // Comprobar integridad referencial
    const hasPerfiles = this.perfiles.some(p => p.dni_cliente === cleanDni);
    if (hasPerfiles) {
      throw new Error(`[PL/pgSQL Exception - foreign_key_violation] No se puede eliminar el cliente con DNI ${cleanDni} porque tiene perfiles de necesidad vinculados.`);
    }

    this.clientes.splice(idx, 1);
    return `Cliente con DNI ${cleanDni} eliminado exitosamente mediante public.sp_eliminar_cliente.`;
  }

  // --------------------------------------------------------------------------
  // STORED PROCEDURES: PRODUCTO_CATALOGO
  // --------------------------------------------------------------------------
  public spInsertarProducto(codigo: string, modelo: string, especificaciones: string, precio: number, id_marca: number, id_categoria: number): string {
    const cleanCodigo = codigo.trim();
    this.triggerValidarProducto(cleanCodigo, modelo, precio);

    if (!this.marcas.some(m => m.id_marca === id_marca)) {
      throw new Error(`[PL/pgSQL Exception] La marca indicada (ID: ${id_marca}) no existe.`);
    }
    if (!this.categorias.some(c => c.id_categoria === id_categoria)) {
      throw new Error(`[PL/pgSQL Exception] La categoría indicada (ID: ${id_categoria}) no existe.`);
    }
    if (this.productos.some(p => p.codigo_producto === cleanCodigo)) {
      throw new Error(`[PL/pgSQL Exception - duplicate_key] Ya existe un producto con el código ${cleanCodigo}.`);
    }

    const newProd: ProductoCatalogo = {
      codigo_producto: cleanCodigo,
      modelo: modelo.trim(),
      especificaciones: especificaciones.trim(),
      precio_referencial: precio,
      id_marca,
      id_categoria
    };

    this.productos.unshift(newProd);
    return `Producto ${cleanCodigo} insertado exitosamente mediante public.sp_insertar_producto.`;
  }

  public spModificarProducto(codigo: string, modelo: string, especificaciones: string, precio: number, id_marca: number, id_categoria: number): string {
    const cleanCodigo = codigo.trim();
    const idx = this.productos.findIndex(p => p.codigo_producto === cleanCodigo);
    if (idx === -1) {
      throw new Error(`[PL/pgSQL Exception] No se encontró el producto con código ${cleanCodigo} para modificar.`);
    }
    this.triggerValidarProducto(cleanCodigo, modelo, precio);

    const updatedProd: ProductoCatalogo = {
      codigo_producto: cleanCodigo,
      modelo: modelo.trim(),
      especificaciones: especificaciones.trim(),
      precio_referencial: precio,
      id_marca,
      id_categoria
    };
    this.productos[idx] = updatedProd;

    return `Producto ${cleanCodigo} modificado exitosamente mediante public.sp_modificar_producto.`;
  }

  public spEliminarProducto(codigo: string): string {
    const cleanCodigo = codigo.trim();
    const idx = this.productos.findIndex(p => p.codigo_producto === cleanCodigo);
    if (idx === -1) {
      throw new Error(`[PL/pgSQL Exception] No existe el producto ${cleanCodigo} para eliminar.`);
    }

    // Verificar si está en detalle_evaluacion o recomendacion_final
    if (this.detalles.some(d => d.codigo_producto === cleanCodigo)) {
      throw new Error(`[PL/pgSQL Exception - foreign_key_violation] No se puede eliminar el producto ${cleanCodigo} porque está referenciado en evaluaciones técnicas.`);
    }
    if (this.recomendaciones.some(r => r.codigo_producto === cleanCodigo)) {
      throw new Error(`[PL/pgSQL Exception - foreign_key_violation] No se puede eliminar el producto ${cleanCodigo} porque está registrado como recomendación final.`);
    }

    this.productos.splice(idx, 1);
    return `Producto ${cleanCodigo} eliminado exitosamente mediante public.sp_eliminar_producto.`;
  }

  // --------------------------------------------------------------------------
  // STORED PROCEDURES: PERFIL_DE_NECESIDAD
  // --------------------------------------------------------------------------
  public spInsertarPerfil(uso: string, presupuesto: number, restriccion: string, dni: string, id_asesor: number, id_marca: number | null): string {
    const cleanDni = dni.trim();
    if (!this.clientes.some(c => c.dni_cliente === cleanDni)) {
      throw new Error(`[PL/pgSQL Exception] El cliente con DNI ${cleanDni} no existe.`);
    }
    if (!this.asesores.some(a => a.id_asesor === id_asesor)) {
      throw new Error(`[PL/pgSQL Exception] El asesor técnico con ID ${id_asesor} no existe.`);
    }

    const today = new Date().toISOString().slice(0, 10);
    // Ejecutar Trigger 1 de validación
    this.triggerValidarPerfil({
      presupuesto_max: presupuesto,
      fecha_registro: today
    });

    const newId = (this.perfiles.length > 0 ? Math.max(...this.perfiles.map(p => p.id_perfil)) : 0) + 1;
    this.perfiles.push({
      id_perfil: newId,
      uso_principal: uso.trim(),
      presupuesto_max: presupuesto,
      restriccion_tecnica: restriccion.trim(),
      fecha_registro: today,
      dni_cliente: cleanDni,
      id_asesor,
      id_marca
    });

    return `Perfil de necesidad ID ${newId} registrado exitosamente mediante public.sp_insertar_perfil_necesidad. (Validado por trg_validar_perfil)`;
  }

  // --------------------------------------------------------------------------
  // EJECUCIÓN DE LAS 10 CONSULTAS DE REPORTES
  // --------------------------------------------------------------------------
  public executeReport(reportId: number): QueryResult {
    const start = performance.now();
    let columns: string[] = [];
    let rows: Record<string, any>[] = [];

    const marcaMap = new Map<number, string>(this.marcas.map(m => [m.id_marca, m.nombre_marca]));
    const catMap = new Map<number, string>(this.categorias.map(c => [c.id_categoria, c.nombre_categoria]));
    const asesorMap = new Map<number, AsesorTecnico>(this.asesores.map(a => [a.id_asesor, a]));
    const clienteMap = new Map<string, Cliente>(this.clientes.map(c => [c.dni_cliente, c]));
    const prodMap = new Map<string, ProductoCatalogo>(this.productos.map(p => [p.codigo_producto, p]));

    switch (reportId) {
      case 1: {
        // Catálogo Completo con Marca y Categoría
        columns = ["codigo_producto", "modelo", "nombre_marca", "nombre_categoria", "precio_referencial", "especificaciones"];
        rows = this.productos.map(p => ({
          codigo_producto: p.codigo_producto,
          modelo: p.modelo,
          nombre_marca: marcaMap.get(p.id_marca) || "Desconocida",
          nombre_categoria: catMap.get(p.id_categoria) || "Desconocida",
          precio_referencial: p.precio_referencial.toFixed(2),
          especificaciones: p.especificaciones
        })).sort((a, b) => {
          if (a.nombre_categoria === b.nombre_categoria) {
            return parseFloat(b.precio_referencial) - parseFloat(a.precio_referencial);
          }
          return a.nombre_categoria.localeCompare(b.nombre_categoria);
        });
        break;
      }

      case 2: {
        // Resumen Estadístico de Precios por Categoría
        columns = ["id_categoria", "nombre_categoria", "total_productos", "precio_promedio", "precio_minimo", "precio_maximo"];
        rows = this.categorias.map(cat => {
          const prods = this.productos.filter(p => p.id_categoria === cat.id_categoria);
          const total = prods.length;
          const precios = prods.map(p => p.precio_referencial);
          const avg = total > 0 ? (precios.reduce((acc, v) => acc + v, 0) / total).toFixed(2) : "0.00";
          const min = total > 0 ? Math.min(...precios).toFixed(2) : "0.00";
          const max = total > 0 ? Math.max(...precios).toFixed(2) : "0.00";
          return {
            id_categoria: cat.id_categoria,
            nombre_categoria: cat.nombre_categoria,
            total_productos: total,
            precio_promedio: avg,
            precio_minimo: min,
            precio_maximo: max
          };
        }).sort((a, b) => b.total_productos - a.total_productos || a.nombre_categoria.localeCompare(b.nombre_categoria));
        break;
      }

      case 3: {
        // Perfiles de Necesidad con Cliente y Asesor Asignado
        columns = ["id_perfil", "fecha_registro", "dni_cliente", "cliente_nombre", "canal_contacto", "telefono", "uso_principal", "presupuesto_max", "asesor_tecnico", "turno_asesor", "marca_preferida"];
        rows = this.perfiles.map(pn => {
          const cli = clienteMap.get(pn.dni_cliente);
          const ast = asesorMap.get(pn.id_asesor);
          return {
            id_perfil: pn.id_perfil,
            fecha_registro: pn.fecha_registro,
            dni_cliente: pn.dni_cliente,
            cliente_nombre: cli ? `${cli.nombres} ${cli.apellidos}` : "Cliente No Encontrado",
            canal_contacto: cli?.canal_contacto || "-",
            telefono: cli?.telefono || "-",
            uso_principal: pn.uso_principal,
            presupuesto_max: pn.presupuesto_max.toFixed(2),
            asesor_tecnico: ast ? `${ast.nombres} ${ast.apellidos}` : "No asignado",
            turno_asesor: ast?.turno || "-",
            marca_preferida: pn.id_marca ? (marcaMap.get(pn.id_marca) || "Sin preferencia") : "Sin preferencia"
          };
        }).sort((a, b) => b.id_perfil - a.id_perfil);
        break;
      }

      case 4: {
        // Matriz Comparativa y Detalle de Evaluación
        columns = ["id_comparativa", "criterio_evaluacion", "diferencial_tecnico", "codigo_producto", "producto_evaluado", "nombre_marca", "precio_referencial", "resultado_evaluacion"];
        rows = [];
        this.matrices.forEach(mc => {
          const matches = this.detalles.filter(d => d.id_comparativa === mc.id_comparativa);
          matches.forEach(de => {
            const prod = prodMap.get(de.codigo_producto);
            rows.push({
              id_comparativa: mc.id_comparativa,
              criterio_evaluacion: mc.criterio_evaluacion,
              diferencial_tecnico: mc.diferencial_tecnico,
              codigo_producto: de.codigo_producto,
              producto_evaluado: prod ? prod.modelo : de.codigo_producto,
              nombre_marca: prod ? (marcaMap.get(prod.id_marca) || "-") : "-",
              precio_referencial: prod ? prod.precio_referencial.toFixed(2) : "0.00",
              resultado_evaluacion: de.resultado_evaluacion
            });
          });
        });
        rows.sort((a, b) => a.id_comparativa - b.id_comparativa || parseFloat(a.precio_referencial) - parseFloat(b.precio_referencial));
        break;
      }

      case 5: {
        // Recomendaciones Finales con Nivel de Compatibilidad
        columns = ["id_recomendacion", "id_comparativa", "codigo_producto", "modelo", "nombre_marca", "precio_referencial", "compatibilidad_pct", "justificacion_tecnica", "indicacion_uso"];
        rows = this.recomendaciones.map(rf => {
          const prod = prodMap.get(rf.codigo_producto);
          return {
            id_recomendacion: rf.id_recomendacion,
            id_comparativa: rf.id_comparativa,
            codigo_producto: rf.codigo_producto,
            modelo: prod ? prod.modelo : rf.codigo_producto,
            nombre_marca: prod ? (marcaMap.get(prod.id_marca) || "-") : "-",
            precio_referencial: prod ? prod.precio_referencial.toFixed(2) : "0.00",
            compatibilidad_pct: rf.nivel_compatibilidad !== null ? `${rf.nivel_compatibilidad.toFixed(2)}%` : "-",
            justificacion_tecnica: rf.justificacion_tecnica,
            indicacion_uso: rf.indicacion_uso
          };
        }).sort((a, b) => parseFloat(b.compatibilidad_pct) - parseFloat(a.compatibilidad_pct));
        break;
      }

      case 6: {
        // Carga de Trabajo y Desempeño de Asesores
        columns = ["id_asesor", "asesor_nombre", "especialidad", "turno", "total_perfiles_atendidos", "presupuesto_promedio_atendido", "volumen_total_presupuestos"];
        rows = this.asesores.map(ast => {
          const perfilList = this.perfiles.filter(p => p.id_asesor === ast.id_asesor);
          const total = perfilList.length;
          const sum = perfilList.reduce((acc, p) => acc + p.presupuesto_max, 0);
          const avg = total > 0 ? (sum / total).toFixed(2) : "0.00";
          return {
            id_asesor: ast.id_asesor,
            asesor_nombre: `${ast.nombres} ${ast.apellidos}`,
            especialidad: ast.especialidad,
            turno: ast.turno,
            total_perfiles_atendidos: total,
            presupuesto_promedio_atendido: `S/. ${avg}`,
            volumen_total_presupuestos: `S/. ${sum.toFixed(2)}`
          };
        }).sort((a, b) => b.total_perfiles_atendidos - a.total_perfiles_atendidos);
        break;
      }

      case 7: {
        // Comparativa Financiera: Presupuesto vs Precio Recomendado
        columns = ["id_perfil", "cliente", "dni_cliente", "presupuesto_maximo", "producto_recomendado", "precio_producto", "saldo_favorable_ahorro", "estado_financiero", "nivel_compatibilidad"];
        rows = [];
        this.recomendaciones.forEach(rf => {
          const mc = this.matrices.find(m => m.id_comparativa === rf.id_comparativa);
          if (mc) {
            const pn = this.perfiles.find(p => p.id_perfil === mc.id_perfil);
            if (pn) {
              const cli = clienteMap.get(pn.dni_cliente);
              const prod = prodMap.get(rf.codigo_producto);
              const precio = prod ? prod.precio_referencial : 0;
              const saldo = pn.presupuesto_max - precio;
              rows.push({
                id_perfil: pn.id_perfil,
                cliente: cli ? `${cli.nombres} ${cli.apellidos}` : pn.dni_cliente,
                dni_cliente: pn.dni_cliente,
                presupuesto_maximo: `S/. ${pn.presupuesto_max.toFixed(2)}`,
                producto_recomendado: prod ? prod.modelo : rf.codigo_producto,
                precio_producto: `S/. ${precio.toFixed(2)}`,
                saldo_favorable_ahorro: `S/. ${saldo.toFixed(2)}`,
                estado_financiero: precio <= pn.presupuesto_max ? "DENTRO DE PRESUPUESTO" : "SUPERA PRESUPUESTO",
                nivel_compatibilidad: rf.nivel_compatibilidad !== null ? `${rf.nivel_compatibilidad}%` : "-"
              });
            }
          }
        });
        break;
      }

      case 8: {
        // Distribución y Rango de Precios por Marca
        columns = ["id_marca", "nombre_marca", "cantidad_modelos", "precio_mas_bajo", "precio_mas_alto", "precio_promedio"];
        rows = this.marcas.map(m => {
          const prods = this.productos.filter(p => p.id_marca === m.id_marca);
          const total = prods.length;
          const precios = prods.map(p => p.precio_referencial);
          return {
            id_marca: m.id_marca,
            nombre_marca: m.nombre_marca,
            cantidad_modelos: total,
            precio_mas_bajo: total > 0 ? `S/. ${Math.min(...precios).toFixed(2)}` : "-",
            precio_mas_alto: total > 0 ? `S/. ${Math.max(...precios).toFixed(2)}` : "-",
            precio_promedio: total > 0 ? `S/. ${(precios.reduce((a, b) => a + b, 0) / total).toFixed(2)}` : "-"
          };
        }).filter(r => r.cantidad_modelos > 0).sort((a, b) => b.cantidad_modelos - a.cantidad_modelos);
        break;
      }

      case 9: {
        // Top 15 Productos de Mayor Valor en Catálogo
        columns = ["codigo_producto", "modelo", "precio_referencial", "especificaciones"];
        rows = [...this.productos]
          .sort((a, b) => b.precio_referencial - a.precio_referencial)
          .slice(0, 15)
          .map(p => ({
            codigo_producto: p.codigo_producto,
            modelo: p.modelo,
            precio_referencial: `S/. ${p.precio_referencial.toFixed(2)}`,
            especificaciones: p.especificaciones
          }));
        break;
      }

      case 10: {
        // Distribución Porcentual de Clientes por Canal de Contacto
        columns = ["canal_contacto", "cantidad_clientes", "porcentaje_total"];
        const counts: Record<string, number> = {};
        this.clientes.forEach(c => {
          const canal = c.canal_contacto || "No especificado";
          counts[canal] = (counts[canal] || 0) + 1;
        });
        const total = this.clientes.length;
        rows = Object.entries(counts).map(([canal, count]) => ({
          canal_contacto: canal,
          cantidad_clientes: count,
          porcentaje_total: `${((count * 100) / (total || 1)).toFixed(2)}%`
        })).sort((a, b) => b.cantidad_clientes - a.cantidad_clientes);
        break;
      }

      default:
        throw new Error(`Reporte con ID ${reportId} no válido.`);
    }

    const executionTimeMs = parseFloat((performance.now() - start).toFixed(2));
    return { columns, rows, executionTimeMs };
  }
}

export const dbInstance = new PostgresEngine();

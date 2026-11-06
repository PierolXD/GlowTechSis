/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useMemo } from "react";
import {
  Database,
  Terminal,
  Play,
  Copy,
  Check,
  Search,
  Table as TableIcon,
  ShieldCheck,
  Layers,
  ExternalLink,
  RefreshCw,
  Plus,
  Edit2,
  Trash2,
  AlertCircle,
  LayoutDashboard,
  Globe
} from "lucide-react";
import { REPORT_LIST, ReportItem } from "./data/sqlDefinitions";
import { dbInstance, QueryResult } from "./data/dbEngine";
import { exportTableToCSV } from "./utils/downloader";

type TabType = "reportes" | "procedures" | "triggers" | "erd" | "sandbox";

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>("reportes");
  const [previousTab, setPreviousTab] = useState<TabType>("reportes");
  const [selectedReportId, setSelectedReportId] = useState<number>(1);
  const [queryResult, setQueryResult] = useState<QueryResult | null>(null);
  const [searchTerm, setSearchTerm] = useState<string>("");
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  // Estado para Stored Procedures (CRUD)
  const [spEntity, setSpEntity] = useState<"clientes" | "productos" | "perfiles">("clientes");
  const [spActionLog, setSpActionLog] = useState<{ message: string; isError: boolean } | null>(null);
  const [dbVersion, setDbVersion] = useState<number>(0);

  // Formulario Cliente
  const [cliDni, setCliDni] = useState("98765432");
  const [cliNombres, setCliNombres] = useState("Valeria");
  const [cliApellidos, setCliApellidos] = useState("Paredes Gómez");
  const [cliCanal, setCliCanal] = useState("WhatsApp");
  const [cliTelefono, setCliTelefono] = useState("987112233");
  const [cliCorreo, setCliCorreo] = useState("valeria.paredes@gmail.com");

  // Formulario Producto
  const [prodCodigo, setProdCodigo] = useState("PROD0300");
  const [prodModelo, setProdModelo] = useState("JBL Quantum 910 Wireless");
  const [prodSpecs, setProdSpecs] = useState("Color: NEGRO, Espacial 3D, RGB");
  const [prodPrecio, setProdPrecio] = useState("899.00");
  const [prodMarca, setProdMarca] = useState("1");
  const [prodCat, setProdCat] = useState("1");

  // Formulario Perfil (para probar Trigger 1)
  const [perfilUso, setPerfilUso] = useState("Trabajo remoto y llamadas");
  const [perfilPresupuesto, setPerfilPresupuesto] = useState("450.00");
  const [perfilRestriccion, setPerfilRestriccion] = useState("Micrófono con cancelación de eco");
  const [perfilDni, setPerfilDni] = useState("12345678");
  const [perfilAsesor, setPerfilAsesor] = useState("1");
  const [perfilMarca, setPerfilMarca] = useState("1");

  // Ejecutar reporte actual
  const currentReport = useMemo(() => {
    return REPORT_LIST.find((r) => r.id === selectedReportId) || REPORT_LIST[0];
  }, [selectedReportId]);

  const handleRunReport = (id = selectedReportId) => {
    try {
      const res = dbInstance.executeReport(id);
      setQueryResult(res);
      setSearchTerm("");
    } catch (err: any) {
      setQueryResult({
        columns: ["Error"],
        rows: [{ Error: err.message }],
        executionTimeMs: 0
      });
    }
  };

  useEffect(() => {
    handleRunReport(selectedReportId);
  }, [selectedReportId, dbVersion]);

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2500);
  };

  // Filtrado de filas en la tabla del reporte
  const filteredRows = useMemo(() => {
    if (!queryResult) return [];
    if (!searchTerm.trim()) return queryResult.rows;
    const term = searchTerm.toLowerCase();
    return queryResult.rows.filter((row) =>
      Object.values(row).some((val) =>
        String(val).toLowerCase().includes(term)
      )
    );
  }, [queryResult, searchTerm]);

  // Handlers para Stored Procedures (Clientes)
  const handleInsertCliente = () => {
    try {
      const msg = dbInstance.spInsertarCliente(
        cliDni,
        cliNombres,
        cliApellidos,
        cliCanal,
        cliTelefono,
        cliCorreo
      );
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  const handleUpdateCliente = () => {
    try {
      const msg = dbInstance.spModificarCliente(
        cliDni,
        cliNombres,
        cliApellidos,
        cliCanal,
        cliTelefono,
        cliCorreo
      );
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  const handleDeleteCliente = (dni = cliDni) => {
    try {
      const msg = dbInstance.spEliminarCliente(dni);
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  // Handlers para Stored Procedures (Productos)
  const handleInsertProducto = () => {
    try {
      const precio = parseFloat(prodPrecio) || 0;
      const marcaId = parseInt(prodMarca, 10);
      const catId = parseInt(prodCat, 10);
      const msg = dbInstance.spInsertarProducto(
        prodCodigo,
        prodModelo,
        prodSpecs,
        precio,
        marcaId,
        catId
      );
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  const handleUpdateProducto = () => {
    try {
      const precio = parseFloat(prodPrecio) || 0;
      const marcaId = parseInt(prodMarca, 10);
      const catId = parseInt(prodCat, 10);
      const msg = dbInstance.spModificarProducto(
        prodCodigo,
        prodModelo,
        prodSpecs,
        precio,
        marcaId,
        catId
      );
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  const handleDeleteProducto = (codigo = prodCodigo) => {
    try {
      const msg = dbInstance.spEliminarProducto(codigo);
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  // Handlers para Trigger 1 (Perfiles)
  const handleInsertPerfil = () => {
    try {
      const pres = parseFloat(perfilPresupuesto);
      const asesorId = parseInt(perfilAsesor, 10);
      const marcaId = perfilMarca ? parseInt(perfilMarca, 10) : null;
      const msg = dbInstance.spInsertarPerfil(
        perfilUso,
        pres,
        perfilRestriccion,
        perfilDni,
        asesorId,
        marcaId
      );
      setSpActionLog({ message: msg, isError: false });
      setDbVersion((v) => v + 1);
    } catch (err: any) {
      setSpActionLog({ message: err.message, isError: true });
    }
  };

  // Datos actuales
  const clientesList = useMemo(() => dbInstance.getClientes(), [dbVersion]);
  const productosList = useMemo(() => dbInstance.getProductos(), [dbVersion]);
  const perfilesList = useMemo(() => dbInstance.getPerfiles(), [dbVersion]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-blue-600 selection:text-white">
      {/* Top Bar Contract (1 row, 3 zones: Brand, 4 Nav links, 1 Primary Action) */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-8">
          {/* Zone 1: Wordmark */}
          <div className="flex items-center gap-3 shrink-0">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold shadow-md shadow-blue-500/20">
              <Database className="w-4 h-4" />
            </div>
            <span className="text-base font-bold tracking-tight text-white whitespace-nowrap">
              PostgreSQL Suite & Native Hub
            </span>
          </div>

          {/* Zone 2: Clean Single-Line Nav Links */}
          <nav className="hidden md:flex items-center gap-6 text-sm font-medium text-slate-300">
            <button
              onClick={() => setActiveTab("reportes")}
              className={`hover:text-white transition-colors whitespace-nowrap ${
                activeTab === "reportes" ? "text-blue-400 font-semibold" : ""
              }`}
            >
              10 Reportes SQL
            </button>
            <button
              onClick={() => setActiveTab("procedures")}
              className={`hover:text-white transition-colors whitespace-nowrap ${
                activeTab === "procedures" ? "text-blue-400 font-semibold" : ""
              }`}
            >
              Stored Procedures
            </button>
            <button
              onClick={() => setActiveTab("triggers")}
              className={`hover:text-white transition-colors whitespace-nowrap ${
                activeTab === "triggers" ? "text-blue-400 font-semibold" : ""
              }`}
            >
              Triggers de Validación
            </button>
            <button
              onClick={() => setActiveTab("erd")}
              className={`hover:text-white transition-colors whitespace-nowrap ${
                activeTab === "erd" ? "text-blue-400 font-semibold" : ""
              }`}
            >
              Arquitectura ERD
            </button>
          </nav>

          {/* Zone 3: Botón en esquina para alternar entre vista normal y vista HTML */}
          <div className="flex items-center gap-3 shrink-0">
            {activeTab === "sandbox" ? (
              <button
                onClick={() => setActiveTab(previousTab === "sandbox" ? "reportes" : previousTab)}
                className="px-4 py-2 text-xs font-semibold text-white bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors shadow-sm flex items-center gap-1.5 whitespace-nowrap"
              >
                <LayoutDashboard className="w-3.5 h-3.5" />
                <span>Vista Normal (Panel)</span>
              </button>
            ) : (
              <button
                onClick={() => {
                  setPreviousTab(activeTab);
                  setActiveTab("sandbox");
                }}
                className="px-4 py-2 text-xs font-semibold text-slate-200 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg transition-colors shadow-sm flex items-center gap-1.5 whitespace-nowrap"
              >
                <Globe className="w-3.5 h-3.5 text-blue-400" />
                <span>Vista HTML</span>
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Tab 1: 10 Reportes SQL */}
        {activeTab === "reportes" && (
          <div className="space-y-6">
            {/* Selector de los 10 Reportes */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Selecciona una de las 10 Consultas SQL
                </span>
                <span className="text-xs text-slate-400">
                  {REPORT_LIST.filter((r) => r.hasJoin).length} de 10 incluyen JOINs
                </span>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                {REPORT_LIST.map((rep) => {
                  const isSelected = rep.id === selectedReportId;
                  return (
                    <button
                      key={rep.id}
                      onClick={() => setSelectedReportId(rep.id)}
                      className={`p-3 text-left rounded-lg border transition-all flex flex-col justify-between ${
                        isSelected
                          ? "bg-blue-950/40 border-blue-500 shadow-sm shadow-blue-500/10 text-white"
                          : "bg-slate-900 border-slate-800 hover:border-slate-700 text-slate-300 hover:text-white"
                      }`}
                    >
                      <div className="flex items-center justify-between w-full mb-1">
                        <span className="text-xs font-bold text-slate-400">
                          {rep.id < 10 ? `0${rep.id}` : rep.id}
                        </span>
                        {rep.hasJoin ? (
                          <span className="text-[10px] text-blue-400 font-medium">JOIN</span>
                        ) : (
                          <span className="text-[10px] text-slate-500 font-medium">Directa</span>
                        )}
                      </div>
                      <p className="text-xs font-medium line-clamp-2 leading-tight">
                        {rep.title}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Ficha del Reporte Seleccionado y Código SQL */}
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-slate-800">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-blue-400 uppercase tracking-wider">
                      Reporte {currentReport.id}
                    </span>
                    <span className="text-xs text-slate-500">·</span>
                    <span className="text-xs text-slate-400">
                      Tablas: {currentReport.tables.join(", ")}
                    </span>
                  </div>
                  <h3 className="text-lg font-bold text-white mt-1">
                    {currentReport.title}
                  </h3>
                  <p className="text-xs text-slate-400 mt-1 max-w-3xl">
                    {currentReport.description}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => copyToClipboard(currentReport.sql, `report-${currentReport.id}`)}
                    className="px-3 py-1.5 text-xs font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-lg border border-slate-700 transition-colors flex items-center gap-1.5"
                  >
                    {copiedKey === `report-${currentReport.id}` ? (
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                    ) : (
                      <Copy className="w-3.5 h-3.5" />
                    )}
                    <span>{copiedKey === `report-${currentReport.id}` ? "Copiado" : "Copiar SQL"}</span>
                  </button>

                  <button
                    onClick={() => handleRunReport(currentReport.id)}
                    className="px-4 py-1.5 text-xs font-semibold text-white bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
                  >
                    <Play className="w-3.5 h-3.5" />
                    <span>Ejecutar Consulta</span>
                  </button>
                </div>
              </div>

              {/* Bloque de código SQL */}
              <div className="mt-4">
                <div className="bg-slate-950 border border-slate-800/80 rounded-lg p-3 overflow-x-auto">
                  <pre className="text-xs font-mono text-blue-300 leading-relaxed">
                    {currentReport.sql}
                  </pre>
                </div>
              </div>
            </div>

            {/* Resultados de la Consulta */}
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
                <div className="flex items-center gap-3">
                  <TableIcon className="w-4 h-4 text-blue-400" />
                  <span className="text-sm font-bold text-white">
                    Resultados de la Ejecución
                  </span>
                  {queryResult && (
                    <div className="flex items-center gap-2 text-xs text-slate-400">
                      <span className="font-mono tabular-nums font-semibold text-slate-200">
                        {filteredRows.length}
                      </span>
                      <span>filas</span>
                      <span>·</span>
                      <span className="font-mono tabular-nums text-slate-300">
                        {queryResult.executionTimeMs} ms
                      </span>
                    </div>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                      type="text"
                      placeholder="Filtrar en resultados..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-lg pl-8 pr-3 py-1 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-blue-500 w-44 sm:w-56"
                    />
                  </div>

                  {queryResult && queryResult.rows.length > 0 && (
                    <button
                      onClick={() => exportTableToCSV(`reporte_${currentReport.id}`, queryResult.columns, queryResult.rows)}
                      className="px-3 py-1 text-xs font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-lg border border-slate-700 transition-colors flex items-center gap-1.5"
                    >
                      <span>Descargar CSV</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Tabla de Resultados */}
              <div className="border border-slate-800 rounded-lg overflow-x-auto bg-slate-950 max-h-[460px]">
                {queryResult && queryResult.columns.length > 0 ? (
                  <table className="w-full text-left text-xs border-collapse">
                    <thead className="bg-slate-900 sticky top-0 z-10 border-b border-slate-800 text-slate-400 uppercase tracking-wider text-[11px]">
                      <tr>
                        {queryResult.columns.map((col) => (
                          <th key={col} className="py-2.5 px-4 font-semibold whitespace-nowrap">
                            {col.replace(/_/g, " ")}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60 font-mono text-[11px]">
                      {filteredRows.length > 0 ? (
                        filteredRows.map((row, idx) => (
                          <tr key={idx} className="hover:bg-slate-900/60 transition-colors">
                            {queryResult.columns.map((col) => (
                              <td key={col} className="py-2 px-4 text-slate-300 whitespace-nowrap">
                                {row[col] !== null && row[col] !== undefined ? String(row[col]) : "-"}
                              </td>
                            ))}
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={queryResult.columns.length} className="py-8 text-center text-slate-500">
                            No se encontraron registros coincidentes.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                ) : (
                  <div className="py-12 text-center text-slate-500">
                    Presiona "Ejecutar Consulta" para cargar los datos en memoria.
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Stored Procedures */}
        {activeTab === "procedures" && (
          <div className="space-y-6">
            {spActionLog && (
              <div
                className={`p-3.5 rounded-lg border text-xs flex items-start gap-2.5 ${
                  spActionLog.isError
                    ? "bg-rose-950/30 border-rose-800 text-rose-300"
                    : "bg-emerald-950/30 border-emerald-800 text-emerald-300"
                }`}
              >
                <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                <div className="flex-1">
                  <span className="font-semibold">
                    {spActionLog.isError ? "Error capturado en PostgreSQL:" : "Confirmación de ejecución:"}
                  </span>{" "}
                  {spActionLog.message}
                </div>
                <button
                  onClick={() => setSpActionLog(null)}
                  className="text-slate-400 hover:text-white text-xs underline"
                >
                  Cerrar
                </button>
              </div>
            )}

            {/* Selector de Entidad */}
            <div className="flex items-center gap-2 border-b border-slate-800 pb-3">
              <button
                onClick={() => setSpEntity("clientes")}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors ${
                  spEntity === "clientes"
                    ? "bg-blue-600 text-white"
                    : "bg-slate-900 text-slate-400 hover:text-white"
                }`}
              >
                sp_cliente (Inserción, Modificación, Borrado)
              </button>
              <button
                onClick={() => setSpEntity("productos")}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors ${
                  spEntity === "productos"
                    ? "bg-blue-600 text-white"
                    : "bg-slate-900 text-slate-400 hover:text-white"
                }`}
              >
                sp_producto_catalogo
              </button>
              <button
                onClick={() => setSpEntity("perfiles")}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors ${
                  spEntity === "perfiles"
                    ? "bg-blue-600 text-white"
                    : "bg-slate-900 text-slate-400 hover:text-white"
                }`}
              >
                sp_perfil_necesidad
              </button>
            </div>

            {/* 1. Stored Procedures: CLIENTES */}
            {spEntity === "clientes" && (
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                <div className="lg:col-span-5 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <h3 className="text-sm font-bold text-white mb-1">
                    Probar Invocación de Stored Procedures
                  </h3>
                  <p className="text-xs text-slate-400 mb-4">
                    Ejecuta <code className="text-blue-400">CALL public.sp_insertar_cliente(...)</code>, <code className="text-blue-400">sp_modificar_cliente</code> y <code className="text-blue-400">sp_eliminar_cliente</code>.
                  </p>

                  <div className="space-y-3">
                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        DNI Cliente (8 dígitos numéricos): *
                      </label>
                      <input
                        type="text"
                        maxLength={8}
                        value={cliDni}
                        onChange={(e) => setCliDni(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Nombres: *
                        </label>
                        <input
                          type="text"
                          value={cliNombres}
                          onChange={(e) => setCliNombres(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Apellidos: *
                        </label>
                        <input
                          type="text"
                          value={cliApellidos}
                          onChange={(e) => setCliApellidos(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Canal de Contacto:
                        </label>
                        <select
                          value={cliCanal}
                          onChange={(e) => setCliCanal(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                        >
                          <option value="WhatsApp">WhatsApp</option>
                          <option value="Presencial">Presencial</option>
                          <option value="Teléfono">Teléfono</option>
                          <option value="Correo">Correo</option>
                          <option value="Web">Web</option>
                        </select>
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Teléfono:
                        </label>
                        <input
                          type="text"
                          value={cliTelefono}
                          onChange={(e) => setCliTelefono(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        Correo Electrónico:
                      </label>
                      <input
                        type="email"
                        value={cliCorreo}
                        onChange={(e) => setCliCorreo(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                      />
                    </div>

                    <div className="pt-2 flex flex-wrap gap-2">
                      <button
                        onClick={handleInsertCliente}
                        className="flex-1 py-1.5 px-3 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5" />
                        <span>sp_insertar_cliente</span>
                      </button>
                      <button
                        onClick={handleUpdateCliente}
                        className="py-1.5 px-3 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                        <span>sp_modificar</span>
                      </button>
                      <button
                        onClick={() => handleDeleteCliente(cliDni)}
                        className="py-1.5 px-3 bg-rose-950/60 hover:bg-rose-900 border border-rose-800 text-rose-300 rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>sp_eliminar</span>
                      </button>
                    </div>
                  </div>
                </div>

                <div className="lg:col-span-7 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <h4 className="text-sm font-bold text-white">
                        Registros en Tabla 'public.cliente'
                      </h4>
                      <p className="text-xs text-slate-400">
                        {clientesList.length} clientes registrados
                      </p>
                    </div>
                  </div>

                  <div className="border border-slate-800 rounded-lg overflow-x-auto bg-slate-950 max-h-[380px]">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-900 border-b border-slate-800 text-slate-400 text-[11px] uppercase">
                        <tr>
                          <th className="py-2 px-3">DNI</th>
                          <th className="py-2 px-3">Cliente</th>
                          <th className="py-2 px-3">Canal</th>
                          <th className="py-2 px-3">Teléfono</th>
                          <th className="py-2 px-3">Correo</th>
                          <th className="py-2 px-3 text-right">Acción</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-800/60 font-mono text-[11px]">
                        {clientesList.map((c) => (
                          <tr key={c.dni_cliente} className="hover:bg-slate-900/60">
                            <td className="py-2 px-3 text-blue-400 font-bold">{c.dni_cliente}</td>
                            <td className="py-2 px-3 text-white font-sans">{c.nombres} {c.apellidos}</td>
                            <td className="py-2 px-3 text-slate-300 font-sans">{c.canal_contacto}</td>
                            <td className="py-2 px-3 text-slate-400">{c.telefono || "-"}</td>
                            <td className="py-2 px-3 text-slate-400">{c.correo || "-"}</td>
                            <td className="py-2 px-3 text-right">
                              <button
                                onClick={() => {
                                  setCliDni(c.dni_cliente);
                                  setCliNombres(c.nombres);
                                  setCliApellidos(c.apellidos);
                                  setCliCanal(c.canal_contacto);
                                  setCliTelefono(c.telefono);
                                  setCliCorreo(c.correo);
                                }}
                                className="text-[10px] text-blue-400 hover:text-blue-300 font-sans underline"
                              >
                                Cargar
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* 2. Stored Procedures: PRODUCTOS */}
            {spEntity === "productos" && (
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                <div className="lg:col-span-5 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <h3 className="text-sm font-bold text-white mb-1">
                    sp_insertar_producto & sp_modificar_producto
                  </h3>
                  <p className="text-xs text-slate-400 mb-4">
                    Invocación de procedimientos para altas, bajas y cambios en <code className="text-blue-400">producto_catalogo</code>.
                  </p>

                  <div className="space-y-3">
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Código Producto: *
                        </label>
                        <input
                          type="text"
                          value={prodCodigo}
                          onChange={(e) => setProdCodigo(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Precio Referencial (S/.): *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          value={prodPrecio}
                          onChange={(e) => setProdPrecio(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        Modelo / Nombre Comercial: *
                      </label>
                      <input
                        type="text"
                        value={prodModelo}
                        onChange={(e) => setProdModelo(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          ID Marca: (1=JBL, 2=SONOS...)
                        </label>
                        <input
                          type="number"
                          value={prodMarca}
                          onChange={(e) => setProdMarca(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          ID Categoría: (1=AUDIFONOS...)
                        </label>
                        <input
                          type="number"
                          value={prodCat}
                          onChange={(e) => setProdCat(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        Especificaciones:
                      </label>
                      <input
                        type="text"
                        value={prodSpecs}
                        onChange={(e) => setProdSpecs(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                      />
                    </div>

                    <div className="pt-2 flex flex-wrap gap-2">
                      <button
                        onClick={handleInsertProducto}
                        className="flex-1 py-1.5 px-3 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5" />
                        <span>sp_insertar_producto</span>
                      </button>
                      <button
                        onClick={handleUpdateProducto}
                        className="py-1.5 px-3 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                        <span>sp_modificar</span>
                      </button>
                      <button
                        onClick={() => handleDeleteProducto(prodCodigo)}
                        className="py-1.5 px-3 bg-rose-950/60 hover:bg-rose-900 border border-rose-800 text-rose-300 rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>sp_eliminar</span>
                      </button>
                    </div>
                  </div>
                </div>

                <div className="lg:col-span-7 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="text-sm font-bold text-white">
                      Catálogo de Productos ({productosList.length} ítems)
                    </h4>
                  </div>
                  <div className="border border-slate-800 rounded-lg overflow-x-auto bg-slate-950 max-h-[380px]">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-900 border-b border-slate-800 text-slate-400 text-[11px] uppercase">
                        <tr>
                          <th className="py-2 px-3">Código</th>
                          <th className="py-2 px-3">Modelo</th>
                          <th className="py-2 px-3">Precio</th>
                          <th className="py-2 px-3">Marca/Cat</th>
                          <th className="py-2 px-3 text-right">Acción</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-800/60 font-mono text-[11px]">
                        {productosList.slice(0, 30).map((p) => (
                          <tr key={p.codigo_producto} className="hover:bg-slate-900/60">
                            <td className="py-2 px-3 text-blue-400 font-bold">{p.codigo_producto}</td>
                            <td className="py-2 px-3 text-white font-sans">{p.modelo}</td>
                            <td className="py-2 px-3 text-emerald-400">S/. {p.precio_referencial.toFixed(2)}</td>
                            <td className="py-2 px-3 text-slate-400">M:{p.id_marca} | C:{p.id_categoria}</td>
                            <td className="py-2 px-3 text-right">
                              <button
                                onClick={() => {
                                  setProdCodigo(p.codigo_producto);
                                  setProdModelo(p.modelo);
                                  setProdSpecs(p.especificaciones);
                                  setProdPrecio(p.precio_referencial.toString());
                                  setProdMarca(p.id_marca.toString());
                                  setProdCat(p.id_categoria.toString());
                                }}
                                className="text-[10px] text-blue-400 hover:text-blue-300 font-sans underline"
                              >
                                Cargar
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* 3. Stored Procedures: PERFILES */}
            {spEntity === "perfiles" && (
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                <div className="lg:col-span-5 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <h3 className="text-sm font-bold text-white mb-1">
                    sp_insertar_perfil_necesidad
                  </h3>
                  <p className="text-xs text-slate-400 mb-4">
                    Invocación validada por el <span className="text-blue-400 font-medium">Trigger 1 (trg_validar_perfil)</span>.
                  </p>

                  <div className="space-y-3">
                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        Uso Principal Requerido:
                      </label>
                      <input
                        type="text"
                        value={perfilUso}
                        onChange={(e) => setPerfilUso(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          Presupuesto Máx (S/.): *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          value={perfilPresupuesto}
                          onChange={(e) => setPerfilPresupuesto(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          DNI Cliente Existente: *
                        </label>
                        <input
                          type="text"
                          value={perfilDni}
                          onChange={(e) => setPerfilDni(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                        Restricción Técnica:
                      </label>
                      <input
                        type="text"
                        value={perfilRestriccion}
                        onChange={(e) => setPerfilRestriccion(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          ID Asesor Técnico:
                        </label>
                        <input
                          type="number"
                          value={perfilAsesor}
                          onChange={(e) => setPerfilAsesor(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                      <div>
                        <label className="text-[11px] font-semibold text-slate-400 block mb-1">
                          ID Marca Preferida:
                        </label>
                        <input
                          type="number"
                          value={perfilMarca}
                          onChange={(e) => setPerfilMarca(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-blue-500 font-mono"
                        />
                      </div>
                    </div>

                    <div className="pt-2 flex gap-2">
                      <button
                        onClick={handleInsertPerfil}
                        className="w-full py-1.5 px-3 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1 transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5" />
                        <span>Ejecutar sp_insertar_perfil_necesidad</span>
                      </button>
                    </div>

                    <div className="pt-2 border-t border-slate-800">
                      <button
                        onClick={() => {
                          setPerfilPresupuesto("-50.00");
                        }}
                        className="text-[11px] text-amber-400 hover:text-amber-300 underline block"
                      >
                        Probar Presupuesto Negativo (-50.00) para forzar excepción de validación
                      </button>
                    </div>
                  </div>
                </div>

                <div className="lg:col-span-7 bg-slate-900 border border-slate-800 rounded-xl p-5">
                  <h4 className="text-sm font-bold text-white mb-3">
                    Perfiles de Necesidad ({perfilesList.length} registrados)
                  </h4>
                  <div className="border border-slate-800 rounded-lg overflow-x-auto bg-slate-950 max-h-[380px]">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-900 border-b border-slate-800 text-slate-400 text-[11px] uppercase">
                        <tr>
                          <th className="py-2 px-3">ID</th>
                          <th className="py-2 px-3">Fecha</th>
                          <th className="py-2 px-3">DNI</th>
                          <th className="py-2 px-3">Uso Principal</th>
                          <th className="py-2 px-3">Presupuesto</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-800/60 font-mono text-[11px]">
                        {perfilesList.map((p) => (
                          <tr key={p.id_perfil} className="hover:bg-slate-900/60">
                            <td className="py-2 px-3 text-blue-400 font-bold">{p.id_perfil}</td>
                            <td className="py-2 px-3 text-slate-400">{p.fecha_registro}</td>
                            <td className="py-2 px-3 text-slate-300">{p.dni_cliente}</td>
                            <td className="py-2 px-3 text-white font-sans">{p.uso_principal}</td>
                            <td className="py-2 px-3 text-emerald-400">S/. {p.presupuesto_max.toFixed(2)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Tab 3: Triggers de Validación */}
        {activeTab === "triggers" && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {/* Trigger 1 Card */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                <div className="flex items-center gap-2 mb-2">
                  <ShieldCheck className="w-4 h-4 text-emerald-400" />
                  <h3 className="text-sm font-bold text-white">
                    Trigger 1: trg_validar_perfil (Validación Financiera y Temporal)
                  </h3>
                </div>
                <div className="text-xs text-slate-400 space-y-1.5 mb-4">
                  <p><strong>Evento:</strong> <code className="text-blue-300">BEFORE INSERT OR UPDATE ON perfil_de_necesidad</code></p>
                  <p><strong>Regla 1:</strong> Valida que <code className="text-slate-200">presupuesto_max &gt; 0</code>. Si es menor o igual a cero, lanza una excepción abortando la operación.</p>
                  <p><strong>Regla 2:</strong> Prohíbe fechas de registro en el futuro. Si no se especifica, asigna <code className="text-slate-200">CURRENT_DATE</code>.</p>
                </div>
                <div className="bg-slate-950 border border-slate-800 rounded-lg p-3 font-mono text-[11px] text-emerald-300 overflow-x-auto">
                  <pre>{`IF NEW.presupuesto_max IS NULL OR NEW.presupuesto_max <= 0 THEN
    RAISE EXCEPTION 'Regla de negocio infringida: El presupuesto máximo debe ser mayor a 0 (recibido: %)',
        NEW.presupuesto_max;
END IF;

IF NEW.fecha_registro > CURRENT_DATE THEN
    RAISE EXCEPTION 'Regla de negocio infringida: La fecha de registro (%) no puede ser futura.',
        NEW.fecha_registro;
END IF;`}</pre>
                </div>
              </div>

              {/* Trigger 2 Card */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                <div className="flex items-center gap-2 mb-2">
                  <ShieldCheck className="w-4 h-4 text-blue-400" />
                  <h3 className="text-sm font-bold text-white">
                    Trigger 2: trg_validar_cliente (Validación de DNI y Sanitización)
                  </h3>
                </div>
                <div className="text-xs text-slate-400 space-y-1.5 mb-4">
                  <p><strong>Evento:</strong> <code className="text-blue-300">BEFORE INSERT OR UPDATE ON cliente</code></p>
                  <p><strong>Regla 1:</strong> Valida con expresión regular <code className="text-slate-200">^[0-9]&#123;8&#125;$</code> que el DNI tenga exactamente 8 dígitos.</p>
                  <p><strong>Regla 2:</strong> Sanitiza y normaliza automáticamente correos a minúsculas y elimina espacios en blanco residuales.</p>
                </div>
                <div className="bg-slate-950 border border-slate-800 rounded-lg p-3 font-mono text-[11px] text-blue-300 overflow-x-auto">
                  <pre>{`IF NEW.dni_cliente !~ '^[0-9]{8}$' THEN
    RAISE EXCEPTION 'DNI inválido: % (debe contener exactamente 8 números).',
        NEW.dni_cliente;
END IF;

NEW.nombres := TRIM(NEW.nombres);
NEW.apellidos := TRIM(NEW.apellidos);
IF NEW.correo IS NOT NULL THEN
    NEW.correo := LOWER(TRIM(NEW.correo));
END IF;`}</pre>
                </div>
              </div>
            </div>

            {/* Panel de prueba interactiva de validaciones */}
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
              <h4 className="text-sm font-bold text-white mb-2">
                Simulador de Excepciones de Validación PL/pgSQL
              </h4>
              <p className="text-xs text-slate-400 mb-4">
                Prueba cómo responden las funciones trigger ante datos inválidos ingresados por el usuario:
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-3.5 rounded-lg bg-slate-950 border border-slate-800 flex flex-col justify-between">
                  <div>
                    <span className="text-xs font-semibold text-white block mb-1">
                      Probar Validación de Presupuesto Negativo (Trigger 1)
                    </span>
                    <p className="text-xs text-slate-400 mb-3">
                      Intenta registrar un perfil con <code className="text-rose-400">presupuesto = -150.00</code>.
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      setActiveTab("procedures");
                      setSpEntity("perfiles");
                      setPerfilPresupuesto("-150.00");
                    }}
                    className="py-1.5 px-3 bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 rounded-lg border border-slate-700 transition-colors w-fit"
                  >
                    Ir al Formulario con Presupuesto Inválido
                  </button>
                </div>

                <div className="p-3.5 rounded-lg bg-slate-950 border border-slate-800 flex flex-col justify-between">
                  <div>
                    <span className="text-xs font-semibold text-white block mb-1">
                      Probar Validación de Formato DNI (Trigger 2)
                    </span>
                    <p className="text-xs text-slate-400 mb-3">
                      Intenta registrar un cliente con <code className="text-rose-400">DNI = "ABC12"</code> (menos de 8 caracteres o letras).
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      setActiveTab("procedures");
                      setSpEntity("clientes");
                      setCliDni("ABC12");
                    }}
                    className="py-1.5 px-3 bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 rounded-lg border border-slate-700 transition-colors w-fit"
                  >
                    Ir al Formulario con DNI Inválido
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab 4: Arquitectura ERD */}
        {activeTab === "erd" && (
          <div className="space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
              <div className="flex items-center gap-2 mb-2">
                <Layers className="w-5 h-5 text-blue-400" />
                <h3 className="text-base font-bold text-white">
                  Modelo Relacional de Base de Datos (PostgreSQL)
                </h3>
              </div>
              <p className="text-xs text-slate-400 max-w-3xl">
                Estructura de las 9 tablas del esquema de Asesoría Técnica con sus claves primarias, foráneas y cardinalidad.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {/* Tabla 1: Cliente */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.cliente</span>
                  <span className="text-[10px] text-slate-400 font-mono">DNI (PK)</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">dni_cliente</span><span>CHAR(8) [PK]</span></div>
                  <div className="flex justify-between"><span>nombres</span><span>VARCHAR(80)</span></div>
                  <div className="flex justify-between"><span>apellidos</span><span>VARCHAR(80)</span></div>
                  <div className="flex justify-between"><span>canal_contacto</span><span>VARCHAR(30)</span></div>
                  <div className="flex justify-between"><span>telefono</span><span>VARCHAR(15)</span></div>
                  <div className="flex justify-between"><span>correo</span><span>VARCHAR(100)</span></div>
                </div>
              </div>

              {/* Tabla 2: Producto Catálogo */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.producto_catalogo</span>
                  <span className="text-[10px] text-slate-400 font-mono">211 productos</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">codigo_producto</span><span>VARCHAR(20) [PK]</span></div>
                  <div className="flex justify-between"><span>modelo</span><span>VARCHAR(80)</span></div>
                  <div className="flex justify-between"><span>especificaciones</span><span>TEXT</span></div>
                  <div className="flex justify-between"><span>precio_referencial</span><span>NUMERIC(10,2)</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_marca</span><span>INT [FK]</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_categoria</span><span>INT [FK]</span></div>
                </div>
              </div>

              {/* Tabla 3: Perfil de Necesidad */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.perfil_de_necesidad</span>
                  <span className="text-[10px] text-emerald-400 font-mono">Trigger 1</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">id_perfil</span><span>INT [PK, Identity]</span></div>
                  <div className="flex justify-between"><span>uso_principal</span><span>VARCHAR(100)</span></div>
                  <div className="flex justify-between"><span>presupuesto_max</span><span>NUMERIC(10,2)</span></div>
                  <div className="flex justify-between"><span>restriccion_tecnica</span><span>VARCHAR(255)</span></div>
                  <div className="flex justify-between"><span>fecha_registro</span><span>DATE</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">dni_cliente</span><span>CHAR(8) [FK]</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_asesor</span><span>INT [FK]</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_marca</span><span>INT [FK]</span></div>
                </div>
              </div>

              {/* Tabla 4: Matriz de Comparativa */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.matriz_de_comparativa</span>
                  <span className="text-[10px] text-slate-400 font-mono">Comparativas</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">id_comparativa</span><span>INT [PK, Identity]</span></div>
                  <div className="flex justify-between"><span>criterio_evaluacion</span><span>VARCHAR(150)</span></div>
                  <div className="flex justify-between"><span>diferencial_tecnico</span><span>TEXT</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_perfil</span><span>INT [FK]</span></div>
                </div>
              </div>

              {/* Tabla 5: Detalle de Evaluación */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.detalle_evaluacion</span>
                  <span className="text-[10px] text-slate-400 font-mono">PK Compuesta</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">id_comparativa</span><span>INT [PK, FK]</span></div>
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">codigo_producto</span><span>VARCHAR(20) [PK, FK]</span></div>
                  <div className="flex justify-between"><span>resultado_evaluacion</span><span>VARCHAR(255)</span></div>
                </div>
              </div>

              {/* Tabla 6: Recomendación Final */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.recomendacion_final</span>
                  <span className="text-[10px] text-slate-400 font-mono">Recomendaciones</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">id_recomendacion</span><span>INT [PK, Identity]</span></div>
                  <div className="flex justify-between"><span>justificacion_tecnica</span><span>TEXT</span></div>
                  <div className="flex justify-between"><span>indicacion_uso</span><span>TEXT</span></div>
                  <div className="flex justify-between"><span>nivel_compatibilidad</span><span>NUMERIC(5,2)</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">id_comparativa</span><span>INT [FK]</span></div>
                  <div className="flex justify-between"><span className="text-cyan-400">codigo_producto</span><span>VARCHAR(20) [FK]</span></div>
                </div>
              </div>

              {/* Tabla 7: Asesor Técnico */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.asesor_tecnico</span>
                  <span className="text-[10px] text-slate-400 font-mono">Personal</span>
                </div>
                <div className="text-xs space-y-1 font-mono text-slate-300">
                  <div className="flex justify-between"><span className="text-amber-400 font-bold">id_asesor</span><span>INT [PK, Identity]</span></div>
                  <div className="flex justify-between"><span>nombres</span><span>VARCHAR(80)</span></div>
                  <div className="flex justify-between"><span>apellidos</span><span>VARCHAR(80)</span></div>
                  <div className="flex justify-between"><span>especialidad</span><span>VARCHAR(60)</span></div>
                  <div className="flex justify-between"><span>turno</span><span>VARCHAR(10)</span></div>
                </div>
              </div>

              {/* Tabla 8: Marca & Categoría */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
                <div className="flex items-center justify-between pb-2 border-b border-slate-800 mb-3">
                  <span className="text-xs font-bold text-blue-400">public.marca & public.categoria</span>
                  <span className="text-[10px] text-slate-400 font-mono">Catálogos</span>
                </div>
                <div className="text-xs space-y-2 font-mono text-slate-300">
                  <div>
                    <span className="text-blue-300 font-semibold block text-[11px]">marca:</span>
                    <div className="flex justify-between"><span className="text-amber-400">id_marca [PK]</span><span>INT</span></div>
                    <div className="flex justify-between"><span>nombre_marca</span><span>VARCHAR(60)</span></div>
                  </div>
                  <div>
                    <span className="text-blue-300 font-semibold block text-[11px]">categoria:</span>
                    <div className="flex justify-between"><span className="text-amber-400">id_categoria [PK]</span><span>INT</span></div>
                    <div className="flex justify-between"><span>nombre_categoria</span><span>VARCHAR(60)</span></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Vista Standalone index.html */}
        {activeTab === "sandbox" && (
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-slate-400 pb-1">
              <div className="flex items-center gap-2">
                <span className="font-semibold text-slate-200">Vista HTML Nativo (public/index_standalone.html)</span>
                <span>·</span>
                <span>JavaScript puro con fetch nativo (Zero Frameworks)</span>
              </div>
              <button
                onClick={() => setActiveTab(previousTab === "sandbox" ? "reportes" : previousTab)}
                className="text-xs text-blue-400 hover:text-blue-300 font-medium underline"
              >
                ← Volver al Panel Normal
              </button>
            </div>

            <div className="border border-slate-800 rounded-xl overflow-hidden bg-slate-950 h-[calc(100vh-140px)] min-h-[680px]">
              <iframe
                src="/index_standalone.html"
                title="Frontend Nativo Standalone"
                className="w-full h-full border-0"
              />
            </div>
          </div>
        )}
      </main>

      {/* Footer anti-slop */}
      <footer className="border-t border-slate-800 py-6 text-center text-xs text-slate-500">
        <p>PostgreSQL PL/pgSQL Suite &bull; Servidor Nativo Python (http.server + psycopg2) &bull; Frontend Vanilla JS</p>
      </footer>
    </div>
  );
}

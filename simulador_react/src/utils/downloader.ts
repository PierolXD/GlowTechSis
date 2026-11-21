/**
 * Utilidades para descarga de archivos y copiado al portapapeles
 */

export function downloadTextFile(filename: string, content: string, mimeType = "text/plain;charset=utf-8"): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export function exportTableToCSV(filename: string, columns: string[], rows: Record<string, any>[]): void {
  const header = columns.join(",");
  const csvRows = rows.map(r => {
    return columns.map(c => {
      let val = r[c];
      if (val === null || val === undefined) val = "";
      val = String(val).replace(/"/g, '""');
      return `"${val}"`;
    }).join(",");
  });

  const fullCsv = [header, ...csvRows].join("\n");
  downloadTextFile(`${filename}.csv`, fullCsv, "text/csv;charset=utf-8");
}

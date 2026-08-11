/**
 * Parses a CSV string into a 2D array of strings.
 *
 * The CSV format is expected to use semicolons (;) as delimiters and double quotes (")
 * for escaping values that contain special characters. Newlines can be represented
 * as \n or \r\n.
 */
export function parseCsv(csvText: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let value = "";
  let inQuotes = false;

  for (let i = 0; i < csvText.length; i++) {
    const c = csvText[i];

    if (c === '"') {
      if (inQuotes && csvText[i + 1] === '"') {
        value += '"';
        i++;
      }
      else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (!inQuotes && c === ";") {
      row.push(value);
      value = "";
      continue;
    }

    if (!inQuotes && (c === "\n" || c === "\r")) {
      if (c === "\r" && csvText[i + 1] === "\n") {
        i++;
      }
      row.push(value);
      rows.push(row);
      row = [];
      value = "";
      continue;
    }

    value += c;
  }

  if (value.length > 0 || row.length > 0) {
    row.push(value);
    rows.push(row);
  }

  return rows;
}

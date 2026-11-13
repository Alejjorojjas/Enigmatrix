// Genera functions/data/solutions.json a partir de los casos completos de la app
// (app/assets/cases/mansion-*.json y reto-*.json). Las funciones leen ese archivo para
// validar soluciones; no sale a ningún cliente y NO se versiona (está en .gitignore).
// No publica nada en Firestore ni necesita credenciales.
//
// Uso:  npm run build:solutions
import { readdirSync, readFileSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ID_PATTERN, caseShapeFromDoc } from "../functions/src/validation";
import { parseSolutions, type SolutionEntry } from "../functions/src/solutions";

const here = path.dirname(fileURLToPath(import.meta.url));
export const DEFAULT_CASES_DIR = path.resolve(here, "../../app/assets/cases");
export const DEFAULT_OUTPUT = path.resolve(here, "../functions/data/solutions.json");

export interface CaseFile {
  caseId: string;
  solution?: {
    positions?: Record<string, number>;
    murderer?: string;
    lethalWeapon?: string;
  };
  [k: string]: unknown;
}

export function listCaseFiles(dir: string): string[] {
  return readdirSync(dir)
    .filter((f) => /^(mansion|reto)-.+\.json$/.test(f))
    .sort();
}

/** Convierte un caso completo en su entrada de soluciones. Lanza Error si algo no cuadra. */
export function solutionEntryFromCase(raw: CaseFile): SolutionEntry {
  const shape = caseShapeFromDoc(raw);
  if (!shape) throw new Error(`El caso ${raw.caseId} está mal formado (mapa o personajes).`);
  const sol = raw.solution;
  if (!sol || typeof sol.positions !== "object" || sol.positions === null || typeof sol.murderer !== "string") {
    throw new Error(`El caso ${raw.caseId} no tiene una solución válida.`);
  }
  for (const cid of Object.keys(sol.positions)) {
    if (!ID_PATTERN.test(cid)) throw new Error(`El caso ${raw.caseId} tiene un id de personaje no válido: ${cid}`);
  }
  const entry: SolutionEntry = {
    size: shape.size,
    characterIds: shape.characterIds,
    positions: sol.positions,
    murderer: sol.murderer,
  };
  if (typeof sol.lethalWeapon === "string") entry.lethalWeapon = sol.lethalWeapon;
  return entry;
}

/** Lee todos los casos de la carpeta y devuelve el mapa caseId -> solución (ordenado por id). */
export function buildSolutions(casesDir: string = DEFAULT_CASES_DIR): Record<string, SolutionEntry> {
  const out: Record<string, SolutionEntry> = {};
  for (const file of listCaseFiles(casesDir)) {
    const raw = JSON.parse(readFileSync(path.join(casesDir, file), "utf8")) as CaseFile;
    const id = file.replace(/\.json$/, "");
    if (raw.caseId !== id) throw new Error(`${file}: caseId (${raw.caseId}) no coincide con el nombre.`);
    out[id] = solutionEntryFromCase(raw);
  }
  // Validación final con el mismo lector que usan las funciones.
  parseSolutions(out);
  return out;
}

export function writeSolutions(casesDir: string = DEFAULT_CASES_DIR, output: string = DEFAULT_OUTPUT): number {
  const sols = buildSolutions(casesDir);
  mkdirSync(path.dirname(output), { recursive: true });
  writeFileSync(output, JSON.stringify(sols, null, 1) + "\n", "utf8");
  return Object.keys(sols).length;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const n = writeSolutions();
    console.log(`Soluciones generadas: ${n} casos -> ${path.relative(process.cwd(), DEFAULT_OUTPUT)}`);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

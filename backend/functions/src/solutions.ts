// Soluciones de los casos: las lee del JSON generado por scripts/build-solutions.ts
// (functions/data/solutions.json, fuera de git). Nunca salen en una respuesta.
import { readFileSync } from "node:fs";
import { ID_PATTERN, type CaseShape } from "./validation";

export interface SolutionEntry {
  size: number;
  characterIds: string[];
  positions: Record<string, number>;
  murderer: string;
  lethalWeapon?: string;
}

export type SolutionsMap = Record<string, SolutionEntry>;

const hasOwn = (o: object, k: string): boolean => Object.prototype.hasOwnProperty.call(o, k);
const isPlainObject = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

/** Valida el contenido del JSON. Lanza Error con el caso y el motivo si algo está mal. */
export function parseSolutions(raw: unknown): SolutionsMap {
  if (!isPlainObject(raw)) throw new Error("solutions.json no es un objeto.");
  const out: SolutionsMap = Object.create(null) as SolutionsMap;
  for (const [id, e] of Object.entries(raw)) {
    const bad = (why: string) => new Error(`solutions.json, caso ${id}: ${why}`);
    if (!ID_PATTERN.test(id)) throw bad("id no válido");
    if (!isPlainObject(e)) throw bad("entrada no es un objeto");
    const { size, characterIds, positions, murderer, lethalWeapon } = e;
    if (typeof size !== "number" || !Number.isInteger(size) || size < 1) throw bad("size no válido");
    if (!Array.isArray(characterIds) || characterIds.length === 0) throw bad("characterIds no válido");
    for (const c of characterIds) if (typeof c !== "string" || !ID_PATTERN.test(c)) throw bad("id de personaje no válido");
    if (new Set(characterIds).size !== characterIds.length) throw bad("personajes repetidos");
    if (!isPlainObject(positions)) throw bad("positions no válido");
    const keys = Object.keys(positions);
    if (keys.length !== characterIds.length) throw bad("positions no coincide con los personajes");
    const seen = new Set<number>();
    for (const c of characterIds as string[]) {
      const v = positions[c];
      if (!hasOwn(positions, c) || typeof v !== "number" || !Number.isInteger(v) || v < 0 || v >= size * size) {
        throw bad(`casilla no válida para ${c}`);
      }
      if (seen.has(v)) throw bad("casillas repetidas");
      seen.add(v);
    }
    if (typeof murderer !== "string" || !(characterIds as string[]).includes(murderer)) throw bad("murderer no válido");
    if (lethalWeapon !== undefined && typeof lethalWeapon !== "string") throw bad("lethalWeapon no válido");
    const entry: SolutionEntry = {
      size,
      characterIds: characterIds as string[],
      positions: positions as Record<string, number>,
      murderer,
    };
    if (typeof lethalWeapon === "string") entry.lethalWeapon = lethalWeapon;
    out[id] = entry;
  }
  return out;
}

export function loadSolutionsFile(file: string): SolutionsMap {
  return parseSolutions(JSON.parse(readFileSync(file, "utf8")));
}

/** Busca un caso en el mapa; null si no existe (no se deja engañar por "constructor", "__proto__", etc.). */
export function findSolution(map: SolutionsMap, caseId: string): SolutionEntry | null {
  return hasOwn(map, caseId) ? map[caseId] : null;
}

export function shapeOf(entry: SolutionEntry): CaseShape {
  return { characterIds: entry.characterIds, size: entry.size };
}

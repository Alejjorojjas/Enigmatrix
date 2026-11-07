// Publica los casos de la campaña y del reto en Firestore, en dos partes:
//   cases/{id}          -> el caso SIN la clave "solution"
//   caseSolutions/{id}  -> positions, murderer y lethalWeapon (si hay)
// No publica caso-* ni el tutorial (siguen validando en el teléfono, ADR-0016).
//
// Uso (emulador, por defecto):  npm run publish:cases
// Otro proyecto:                npm run publish:cases -- --project <id>   (no se usa en la 5A.1)
import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ID_PATTERN } from "../functions/src/validation";
import { initializeApp, deleteApp } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";

const here = path.dirname(fileURLToPath(import.meta.url));
export const DEFAULT_CASES_DIR = path.resolve(here, "../../app/assets/cases");

export interface CaseFile {
  caseId: string;
  solution: {
    positions: Record<string, number>;
    murderer: string;
    lethalWeapon?: string;
  };
  [k: string]: unknown;
}

export function listCaseFiles(dir: string): string[] {
  return readdirSync(dir)
    .filter((f) => /^(mansion|reto)-.+\.json$/.test(f))
    .sort();
}

/** Separa un caso en la parte pública y la solución. */
export function splitCase(raw: CaseFile): { pub: Record<string, unknown>; sol: Record<string, unknown> } {
  const { solution, ...pub } = raw;
  if (!solution || typeof solution.positions !== "object" || typeof solution.murderer !== "string") {
    throw new Error(`El caso ${raw.caseId} no tiene una solución válida.`);
  }
  for (const cid of Object.keys(solution.positions)) {
    if (!ID_PATTERN.test(cid)) throw new Error(`El caso ${raw.caseId} tiene un id de personaje no válido: ${cid}`);
  }
  const sol: Record<string, unknown> = {
    positions: solution.positions,
    murderer: solution.murderer,
  };
  if (typeof solution.lethalWeapon === "string") sol.lethalWeapon = solution.lethalWeapon;
  return { pub, sol };
}

/** Versión corta (16 hex de SHA-256) del JSON público + la solución. Cambia si cambia cualquiera de los dos. */
export function caseVersion(pub: Record<string, unknown>, sol: Record<string, unknown>): string {
  return createHash("sha256").update(JSON.stringify({ pub, sol })).digest("hex").slice(0, 16);
}

export async function publishCases(
  firestore: Firestore,
  casesDir: string = DEFAULT_CASES_DIR,
): Promise<string[]> {
  const ids: string[] = [];
  for (const file of listCaseFiles(casesDir)) {
    const raw = JSON.parse(readFileSync(path.join(casesDir, file), "utf8")) as CaseFile;
    const id = file.replace(/\.json$/, "");
    if (raw.caseId !== id) throw new Error(`${file}: caseId (${raw.caseId}) no coincide con el nombre.`);
    const { pub, sol } = splitCase(raw);
    // Un lote por caso: las dos partes se escriben juntas o ninguna.
    const version = caseVersion(pub, sol);
    const batch = firestore.batch();
    batch.set(firestore.collection("cases").doc(id), { ...pub, version });
    batch.set(firestore.collection("caseSolutions").doc(id), { ...sol, version });
    await batch.commit();
    ids.push(id);
  }
  return ids;
}

async function main() {
  const args = process.argv.slice(2);
  const i = args.indexOf("--project");
  const project = i >= 0 ? args[i + 1] : "demo-enigmatrix";
  if (!project) throw new Error("Falta el id después de --project.");
  const real = !project.startsWith("demo-");
  if (!real && !process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  }
  console.log(
    real
      ? `ATENCIÓN: publicando en el proyecto REAL ${project}`
      : `Publicando en el emulador (${process.env.FIRESTORE_EMULATOR_HOST}), proyecto ${project}`,
  );
  const app = initializeApp({ projectId: project }, "publisher");
  try {
    const ids = await publishCases(getFirestore(app));
    console.log(`Publicados ${ids.length} casos.`);
  } finally {
    await deleteApp(app);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}

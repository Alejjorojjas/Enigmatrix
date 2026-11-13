import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { describe, expect, it } from "vitest";
import {
  buildSolutions,
  DEFAULT_CASES_DIR,
  DEFAULT_OUTPUT,
  listCaseFiles,
  solutionEntryFromCase,
  writeSolutions,
} from "../../scripts/build-solutions";
import { findSolution, loadSolutionsFile, parseSolutions, shapeOf } from "../../functions/src/solutions";

const goodEntry = {
  size: 4,
  characterIds: ["c1", "c2", "c3", "c4"],
  positions: { c1: 0, c2: 5, c3: 10, c4: 15 },
  murderer: "c2",
};

function throwsMsg(fn: () => unknown, part: string) {
  try {
    fn();
  } catch (e) {
    expect((e as Error).message).toContain(part);
    return;
  }
  throw new Error("Debía lanzar y no lo hizo");
}

describe("parseSolutions", () => {
  it("acepta una entrada correcta, con y sin arma", () => {
    const m = parseSolutions({ "caso-1": goodEntry, "caso-2": { ...goodEntry, lethalWeapon: "cuchillo" } });
    expect(findSolution(m, "caso-1")!.murderer).toBe("c2");
    expect(findSolution(m, "caso-2")!.lethalWeapon).toBe("cuchillo");
    expect(shapeOf(findSolution(m, "caso-1")!)).toEqual({ characterIds: ["c1", "c2", "c3", "c4"], size: 4 });
  });
  it("rechaza entradas mal formadas", () => {
    throwsMsg(() => parseSolutions(null), "no es un objeto");
    throwsMsg(() => parseSolutions({ "-x": goodEntry }), "id no válido");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, size: 0 } }), "size");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, positions: { c1: 0, c2: 5, c3: 10 } } }), "positions");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, positions: { c1: 0, c2: 5, c3: 10, c4: 16 } } }), "casilla");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, positions: { c1: 0, c2: 5, c3: 5, c4: 15 } } }), "repetidas");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, murderer: "zz" } }), "murderer");
    throwsMsg(() => parseSolutions({ a1: { ...goodEntry, lethalWeapon: 5 } }), "lethalWeapon");
  });
  it("findSolution no se deja engañar por nombres heredados", () => {
    const m = parseSolutions({ "caso-1": goodEntry });
    for (const id of ["constructor", "toString", "hasOwnProperty", "__proto__", "caso-2"]) {
      expect(findSolution(m, id)).toBeNull();
    }
  });
});

describe("build-solutions con los casos completos del servidor (tools/data/casos-servidor)", () => {
  it("lee los 40 casos (10 mansion y 30 reto) y reto-001..reto-030 existen", () => {
    expect(listCaseFiles(DEFAULT_CASES_DIR)).toHaveLength(40);
    const sols = buildSolutions();
    expect(Object.keys(sols)).toHaveLength(40);
    for (let i = 1; i <= 30; i++) expect(sols[`reto-${String(i).padStart(3, "0")}`]).toBeDefined();
    for (let i = 1; i <= 10; i++) expect(sols[`mansion-${String(i).padStart(2, "0")}`]).toBeDefined();
    // No incluye el banco caso-* ni el tutorial.
    expect(Object.keys(sols).some((k) => k.startsWith("caso-"))).toBe(false);
  });
  it("cada solución trae todos sus personajes y asesino; mansion-08 trae arma", () => {
    const sols = buildSolutions();
    for (const e of Object.values(sols)) {
      expect(Object.keys(e.positions).sort()).toEqual([...e.characterIds].sort());
      expect(e.characterIds).toContain(e.murderer);
    }
    expect(sols["mansion-08"].lethalWeapon).toBe("abrecartas");
    expect(sols["mansion-01"].lethalWeapon).toBeUndefined();
  });
  it("el archivo generado se lee con el mismo lector que usan las funciones", () => {
    const n = writeSolutions();
    expect(n).toBe(40);
    const map = loadSolutionsFile(DEFAULT_OUTPUT);
    expect(findSolution(map, "reto-001")!.murderer).toBe("c7");
    // Orden estable: ids ordenados.
    const keys = Object.keys(JSON.parse(readFileSync(DEFAULT_OUTPUT, "utf8")));
    expect(keys).toEqual([...keys].sort());
  });
});

describe("build-solutions con carpetas de prueba", () => {
  const caseJson = (id: string, extra: Record<string, unknown> = {}) => ({
    caseId: id,
    map: { size: 4 },
    characters: [{ id: "c1" }, { id: "c2" }],
    solution: { positions: { c1: 0, c2: 5 }, murderer: "c1" },
    ...extra,
  });
  const dirWith = (files: Record<string, unknown>) => {
    const d = mkdtempSync(path.join(os.tmpdir(), "enx-sol-"));
    for (const [f, c] of Object.entries(files)) writeFileSync(path.join(d, f), JSON.stringify(c));
    return d;
  };
  it("ignora archivos que no son mansion-* ni reto-*", () => {
    const d = dirWith({ "mansion-01.json": caseJson("mansion-01"), "caso-x.json": caseJson("caso-x"), "catalogo.json": {} });
    expect(Object.keys(buildSolutions(d))).toEqual(["mansion-01"]);
  });
  it("falla si el caseId no coincide con el nombre, si falta la solución o el personaje es raro", () => {
    throwsMsg(() => buildSolutions(dirWith({ "reto-001.json": caseJson("reto-002") })), "no coincide");
    throwsMsg(() => buildSolutions(dirWith({ "reto-001.json": caseJson("reto-001", { solution: undefined }) })), "solución válida");
    throwsMsg(() => buildSolutions(dirWith({ "reto-001.json": caseJson("reto-001", { map: {} }) })), "mal formado");
    throwsMsg(
      () => solutionEntryFromCase(caseJson("x-1", { solution: { positions: { "-c1": 0 }, murderer: "c1" } }) as never),
      "no válido",
    );
  });
  it("writeSolutions crea la carpeta de salida", () => {
    const d = dirWith({ "mansion-01.json": caseJson("mansion-01") });
    const out = path.join(d, "sub", "dir", "solutions.json");
    expect(writeSolutions(d, out)).toBe(1);
    expect(Object.keys(loadSolutionsFile(out))).toEqual(["mansion-01"]);
  });
});

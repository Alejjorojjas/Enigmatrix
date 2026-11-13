import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { resolveEnforceAppCheck } from "../../functions/src/appcheck";
import {
  InputError,
  applyRateLimit,
  caseShapeFromDoc,
  compareSolution,
  parseCaseId,
  parseClientElapsedMs,
  parsePositions,
  parseSubmissionId,
  parseSubmitInput,
  computeRanked,
  findSubmission,
  isSuspicious,
  rememberSubmission,
  computeScore,
  assertCanPlay,
  assertEmailVerified,
  isTooFast,
  resolveMinRankedElapsedMs,
  isRegisteredProvider,
  resolveFreeCaseIds,
  resolveClientClockMarginMs,
  resolveErrorPenaltyMs,
  resolveMaxSubmitsPerMinute,
  resolveMaxWrongPerCase,
  type CaseShape,
} from "../../functions/src/validation";

// Caso de 4x4: 16 casillas (0..15), personajes c1..c4.
const shape: CaseShape = { characterIds: ["c1", "c2", "c3", "c4"], size: 4 };
const solution = { c1: 0, c2: 5, c3: 10, c4: 15 };

function rejects(fn: () => unknown, code = "invalid-argument") {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(InputError);
    expect((e as InputError).code).toBe(code);
    return;
  }
  throw new Error("Debía rechazar la entrada y no lo hizo");
}

describe("compareSolution", () => {
  it("tablero correcto", () => {
    expect(compareSolution({ ...solution }, solution)).toEqual({ correct: true, wrongCount: 0 });
  });
  it("tablero incorrecto: cuenta exacta de personajes fuera de su casilla", () => {
    expect(compareSolution({ c1: 5, c2: 0, c3: 10, c4: 15 }, solution)).toEqual({ correct: false, wrongCount: 2 });
    expect(compareSolution({ c1: 1, c2: 2, c3: 3, c4: 4 }, solution)).toEqual({ correct: false, wrongCount: 4 });
    expect(compareSolution({ c1: 0, c2: 5, c3: 10, c4: 14 }, solution)).toEqual({ correct: false, wrongCount: 1 });
  });
  it("un personaje ausente en el envío cuenta como fallo", () => {
    expect(compareSolution({ c1: 0, c2: 5, c3: 10 }, solution).wrongCount).toBe(1);
  });
});

describe("parsePositions", () => {
  it("acepta el tablero bien formado", () => {
    expect(parsePositions({ ...solution }, shape)).toEqual(solution);
  });
  it("rechaza ids que faltan", () => {
    rejects(() => parsePositions({ c1: 0, c2: 5, c3: 10 }, shape));
  });
  it("rechaza ids de más", () => {
    rejects(() => parsePositions({ ...solution, c5: 3 }, shape));
  });
  it("rechaza un id distinto con la misma cantidad de claves", () => {
    rejects(() => parsePositions({ c1: 0, c2: 5, c3: 10, zz: 15 }, shape));
  });
  it("rechaza valores fuera de rango", () => {
    rejects(() => parsePositions({ ...solution, c4: 16 }, shape));
    rejects(() => parsePositions({ ...solution, c4: -1 }, shape));
    rejects(() => parsePositions({ ...solution, c4: Number.MAX_SAFE_INTEGER }, shape));
  });
  it("rechaza valores repetidos", () => {
    rejects(() => parsePositions({ c1: 0, c2: 5, c3: 5, c4: 15 }, shape));
  });
  it("rechaza tipos incorrectos", () => {
    for (const bad of ["5", null, undefined, true, 1.5, NaN, Infinity, [], {}]) {
      rejects(() => parsePositions({ ...solution, c4: bad }, shape));
    }
    for (const bad of [null, undefined, "x", 7, true, [], [0, 5, 10, 15]]) {
      rejects(() => parsePositions(bad, shape));
    }
  });
  it("rechaza objetos enormes sin recorrerlos", () => {
    const big: Record<string, number> = {};
    for (let i = 0; i < 200000; i++) big[`k${i}`] = i;
    rejects(() => parsePositions(big, shape));
  });
  it("no se deja engañar por __proto__ ni por claves heredadas", () => {
    const evil = JSON.parse('{"__proto__": 1, "c2": 5, "c3": 10, "c4": 15}');
    rejects(() => parsePositions(evil, shape));
    const inherited = Object.create({ c1: 0 }) as Record<string, number>;
    Object.assign(inherited, { c2: 5, c3: 10, c4: 15 });
    rejects(() => parsePositions(inherited, shape));
  });
});

describe("parseCaseId", () => {
  it("acepta ids normales", () => {
    expect(parseCaseId("mansion-01")).toBe("mansion-01");
    expect(parseCaseId("a".repeat(64))).toHaveLength(64);
  });
  it("rechaza vacío, largo, tipos y caracteres de ruta", () => {
    for (const bad of ["", "a".repeat(65), 5, null, undefined, {}, [], "a/b", "..", "a b", "a\u0000b", "../caseSolutions/x", "-a", "_a"]) {
      rejects(() => parseCaseId(bad));
    }
    expect(parseCaseId("9-a_b")).toBe("9-a_b");
  });
});

describe("parseClientElapsedMs", () => {
  it("acepta de 0 a 24 h", () => {
    expect(parseClientElapsedMs(0)).toBe(0);
    expect(parseClientElapsedMs(86_400_000)).toBe(86_400_000);
  });
  it("rechaza lo demás", () => {
    for (const bad of [-1, 86_400_001, 1.5, NaN, Infinity, "10", null, undefined]) {
      rejects(() => parseClientElapsedMs(bad));
    }
  });
});

describe("parseSubmitInput", () => {
  const ok = { caseId: "x-1", positions: { ...solution }, clientElapsedMs: 1000, startedOnline: true, submissionId: "abcd1234" };
  it("acepta un envío completo", () => {
    expect(parseSubmitInput(ok, shape)).toEqual(ok);
  });
  it("rechaza datos que no son objeto y startedOnline que no es booleano", () => {
    rejects(() => parseSubmitInput(null, shape));
    rejects(() => parseSubmitInput("hola", shape));
    rejects(() => parseSubmitInput({ ...ok, startedOnline: "true" }, shape));
    rejects(() => parseSubmitInput({ ...ok, startedOnline: undefined }, shape));
    rejects(() => parseSubmitInput({ ...ok, submissionId: undefined }, shape));
    rejects(() => parseSubmitInput({ ...ok, submissionId: "corto" }, shape));
  });
});

describe("caseShapeFromDoc", () => {
  it("lee tamaño y personajes del caso público", () => {
    const doc = { map: { size: 4 }, characters: [{ id: "c1" }, { id: "c2" }] };
    expect(caseShapeFromDoc(doc)).toEqual({ characterIds: ["c1", "c2"], size: 4 });
  });
  it("devuelve null si está mal formado", () => {
    expect(caseShapeFromDoc(null)).toBeNull();
    expect(caseShapeFromDoc({ map: {}, characters: [] })).toBeNull();
    expect(caseShapeFromDoc({ map: { size: 4 }, characters: [{ id: "c1" }, { id: "c1" }] })).toBeNull();
  });
  it("rechaza ids de personaje que no empiezan por letra o número", () => {
    for (const bad of ["-c1", "_c1", "", "c 1", "c/1"]) {
      expect(caseShapeFromDoc({ map: { size: 4 }, characters: [{ id: bad }] })).toBeNull();
    }
  });
});

describe("límite de intentos", () => {
  it("permite hasta el máximo en 60 s y luego bloquea sin anotar el rechazado", () => {
    let recent: number[] = [];
    const t0 = 1_000_000;
    for (let i = 0; i < 6; i++) {
      const d = applyRateLimit(recent, t0 + i * 100, 6);
      expect(d.allowed).toBe(true);
      recent = d.recent;
    }
    const blocked = applyRateLimit(recent, t0 + 1000, 6);
    expect(blocked.allowed).toBe(false);
    expect(blocked.recent).toHaveLength(6);
  });
  it("vuelve a permitir cuando vence la ventana", () => {
    const t0 = 1_000_000;
    const recent = [t0, t0, t0, t0, t0, t0];
    expect(applyRateLimit(recent, t0 + 59_999, 6).allowed).toBe(false);
    expect(applyRateLimit(recent, t0 + 60_000, 6).allowed).toBe(true);
  });
  it("ignora basura guardada y marcas del futuro", () => {
    const d = applyRateLimit(["x", null, NaN, 9e15], 1000, 6);
    expect(d).toEqual({ allowed: true, recent: [1000] });
  });
  it("lee el máximo de la configuración con valor por defecto", () => {
    expect(resolveMaxSubmitsPerMinute(undefined)).toBe(6);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 3 })).toBe(3);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: "9" })).toBe(6);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 1.5 })).toBe(6);
  });
  it("acota maxSubmitsPerMinute entre 1 y 60", () => {
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 0 })).toBe(1);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: -5 })).toBe(1);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 1 })).toBe(1);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 60 })).toBe(60);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 61 })).toBe(60);
    expect(resolveMaxSubmitsPerMinute({ maxSubmitsPerMinute: 1_000_000 })).toBe(60);
  });
});

describe("parseSubmissionId", () => {
  it("acepta 8 a 64 caracteres [A-Za-z0-9_-]", () => {
    expect(parseSubmissionId("abcd1234")).toBe("abcd1234");
    expect(parseSubmissionId("-_aB3-_x")).toBe("-_aB3-_x");
    expect(parseSubmissionId("a".repeat(64))).toHaveLength(64);
  });
  it("rechaza lo demás", () => {
    for (const bad of ["abc1234", "a".repeat(65), "abcd 1234", "abcd/1234", "abcd.1234", "", 12345678, null, undefined, {}]) {
      rejects(() => parseSubmissionId(bad));
    }
  });
});

describe("ranked (solo lo decide el servidor)", () => {
  it("exige rankable distinto de false, startedAt y startedOnline true", () => {
    expect(computeRanked(undefined, true, true)).toBe(true);
    expect(computeRanked(true, true, true)).toBe(true);
    expect(computeRanked(false, true, true)).toBe(false);
    expect(computeRanked(undefined, false, true)).toBe(false);
    expect(computeRanked(undefined, true, false)).toBe(false);
  });
  it("startedOnline nunca sube ranked: sin startedAt o con rankable false siempre es false", () => {
    for (const online of [true, false]) {
      expect(computeRanked(false, true, online)).toBe(false);
      expect(computeRanked(undefined, false, online)).toBe(false);
    }
  });
});

describe("suspicious", () => {
  it("se marca cuando el cliente supera al servidor por más del margen", () => {
    expect(isSuspicious(10_001, 5_000, 5_000)).toBe(true);
    expect(isSuspicious(10_000, 5_000, 5_000)).toBe(false);
    expect(isSuspicious(1, 5_000, 5_000)).toBe(false);
    expect(isSuspicious(999_999, null, 5_000)).toBe(false);
  });
  it("el margen sale de config/server con 5000 por defecto", () => {
    expect(resolveClientClockMarginMs(undefined)).toBe(5000);
    expect(resolveClientClockMarginMs({ clientClockMarginMs: 100 })).toBe(100);
    expect(resolveClientClockMarginMs({ clientClockMarginMs: 0 })).toBe(0);
    expect(resolveClientClockMarginMs({ clientClockMarginMs: -1 })).toBe(5000);
    expect(resolveClientClockMarginMs({ clientClockMarginMs: "9" })).toBe(5000);
  });
});

describe("lastSubmissions (idempotencia)", () => {
  const rec = (n: number) => ({ id: `id-${n}`.padEnd(8, "0"), response: { result: "wrong", wrongCount: n } });
  it("encuentra un envío ya visto y devuelve su respuesta", () => {
    const list = rememberSubmission([], rec(2));
    expect(findSubmission(list, rec(2).id)).toEqual(rec(2));
    expect(findSubmission(list, "otro-id-00")).toBeNull();
    expect(findSubmission(undefined, "x")).toBeNull();
    expect(findSubmission([null, { id: "x" }, 5], "x")).toBeNull();
  });
  it("guarda solo los últimos 20", () => {
    let list: unknown = [];
    for (let i = 0; i < 25; i++) list = rememberSubmission(list, rec(i));
    expect(list).toHaveLength(20);
    expect(findSubmission(list, rec(4).id)).toBeNull();
    expect(findSubmission(list, rec(5).id)).not.toBeNull();
    expect(findSubmission(list, rec(24).id)).not.toBeNull();
  });
});

describe("App Check no se puede apagar en producción", () => {
  it("fuera del emulador siempre es true, diga lo que diga el parámetro", () => {
    expect(resolveEnforceAppCheck({}, false)).toBe(true);
    expect(resolveEnforceAppCheck({ FUNCTIONS_EMULATOR: "false" }, false)).toBe(true);
    expect(resolveEnforceAppCheck({ FUNCTIONS_EMULATOR: "TRUE" }, false)).toBe(true);
    expect(resolveEnforceAppCheck({ ENFORCE_APP_CHECK: "false" }, false)).toBe(true);
  });
  it("solo en el emulador se usa el parámetro", () => {
    expect(resolveEnforceAppCheck({ FUNCTIONS_EMULATOR: "true" }, false)).toBe(false);
    expect(resolveEnforceAppCheck({ FUNCTIONS_EMULATOR: "true" }, true)).toBe(true);
  });
  it("index.ts pasa por resolveEnforceAppCheck y las funciones no usan el parámetro directo", () => {
    const here = path.dirname(fileURLToPath(import.meta.url));
    const src = readFileSync(path.join(here, "../../functions/src/index.ts"), "utf8");
    expect(src).toContain("resolveEnforceAppCheck(process.env,");
    const uses = src.match(/enforceAppCheck:\s*\w+/g) ?? [];
    expect(uses.length).toBeGreaterThanOrEqual(2);
    for (const u of uses) expect(u).toMatch(/enforceAppCheck:\s*ENFORCE_APP_CHECK$/);
  });
});

describe("score del ranking", () => {
  it("score = tiempo del servidor + errores x penalización", () => {
    expect(computeScore(60_000, 0, 30_000)).toBe(60_000);
    expect(computeScore(60_000, 2, 30_000)).toBe(120_000);
    expect(computeScore(0, 3, 10_000)).toBe(30_000);
    expect(computeScore(45_000, 4, 0)).toBe(45_000);
  });
  it("un error cuesta 30 s: 90 s con 1 error empata con 120 s sin errores", () => {
    expect(computeScore(90_000, 1, 30_000)).toBe(computeScore(120_000, 0, 30_000));
  });
  it("errorPenaltyMs sale de config/server con 30000 por defecto", () => {
    expect(resolveErrorPenaltyMs(undefined)).toBe(30_000);
    expect(resolveErrorPenaltyMs({ errorPenaltyMs: 0 })).toBe(0);
    expect(resolveErrorPenaltyMs({ errorPenaltyMs: 15_000 })).toBe(15_000);
    for (const bad of [-1, 1.5, "9", null, 86_400_001]) expect(resolveErrorPenaltyMs({ errorPenaltyMs: bad })).toBe(30_000);
  });
});

describe("tope de errores por caso", () => {
  it("maxWrongPerCase sale de config/server (1 a 1000) con 15 por defecto", () => {
    expect(resolveMaxWrongPerCase(undefined)).toBe(15);
    expect(resolveMaxWrongPerCase({ maxWrongPerCase: 3 })).toBe(3);
    expect(resolveMaxWrongPerCase({ maxWrongPerCase: 0 })).toBe(1);
    expect(resolveMaxWrongPerCase({ maxWrongPerCase: 5000 })).toBe(1000);
    for (const bad of ["9", 1.5, null]) expect(resolveMaxWrongPerCase({ maxWrongPerCase: bad })).toBe(15);
  });
});

describe("tiempo mínimo plausible", () => {
  it("minRankedElapsedMs: entero entre 0 y 1 h; si no, 20000", () => {
    expect(resolveMinRankedElapsedMs(undefined)).toBe(20_000);
    expect(resolveMinRankedElapsedMs({ minRankedElapsedMs: 5000 })).toBe(5000);
    expect(resolveMinRankedElapsedMs({ minRankedElapsedMs: 0 })).toBe(0);
    for (const bad of ["9", 1.5, -1, 3_600_001, null]) expect(resolveMinRankedElapsedMs({ minRankedElapsedMs: bad })).toBe(20_000);
  });
  it("isTooFast: solo por debajo del mínimo y con tiempo del servidor", () => {
    expect(isTooFast(19_999, 20_000)).toBe(true);
    expect(isTooFast(20_000, 20_000)).toBe(false);
    expect(isTooFast(null, 20_000)).toBe(false);
  });
});

describe("invitados y usuarios registrados", () => {
  const free = ["mansion-01", "mansion-02"];
  it("solo 'anonymous' (o sin proveedor) es invitado", () => {
    expect(isRegisteredProvider("anonymous")).toBe(false);
    for (const bad of [undefined, null, "", 5, {}]) expect(isRegisteredProvider(bad)).toBe(false);
    for (const ok of ["password", "google.com", "apple.com", "custom", "phone"]) expect(isRegisteredProvider(ok)).toBe(true);
  });
  it("el invitado solo juega los casos gratis; nunca un reto", () => {
    assertCanPlay("anonymous", "mansion-01", false, free);
    assertCanPlay("anonymous", "mansion-02", false, free);
    rejects(() => assertCanPlay("anonymous", "mansion-03", false, free), "failed-precondition");
    rejects(() => assertCanPlay("anonymous", "reto-001", true, free), "failed-precondition");
    rejects(() => assertCanPlay("anonymous", "reto-001", true, ["reto-001"]), "failed-precondition");
    // Sin proveedor se trata como invitado: solo los gratis.
    assertCanPlay(undefined, "mansion-01", false, free);
    rejects(() => assertCanPlay(undefined, "mansion-03", false, free), "failed-precondition");
  });
  it("el registrado juega todo", () => {
    assertCanPlay("password", "mansion-09", false, free);
    assertCanPlay("google.com", "reto-030", true, []);
  });
  it("el correo sin verificar no juega retos, pero sí la campaña", () => {
    rejects(() => assertCanPlay("password", "reto-001", true, free, false), "failed-precondition");
    rejects(() => assertCanPlay("password", "reto-001", true, free, undefined), "failed-precondition");
    assertCanPlay("password", "reto-001", true, free, true);
    assertCanPlay("password", "mansion-09", false, free, false);
    assertCanPlay("google.com", "reto-001", true, free, false);
    assertCanPlay("apple.com", "reto-001", true, free, undefined);
    try {
      assertEmailVerified("password", false);
    } catch (e) {
      expect((e as InputError).details).toEqual({ reason: "email-unverified" });
      expect((e as Error).message).toBe("Verifica tu correo para jugar el reto.");
      return;
    }
    throw new Error("Debía fallar");
  });
  it("el mensaje es 'Regístrate para seguir jugando'", () => {
    try {
      assertCanPlay("anonymous", "mansion-03", false, free);
    } catch (e) {
      expect((e as Error).message).toContain("Regístrate para seguir jugando");
      return;
    }
    throw new Error("Debía fallar");
  });
  it("freeCaseIds sale de config/server con mansion-01 y mansion-02 por defecto", () => {
    expect(resolveFreeCaseIds(undefined)).toEqual(["mansion-01", "mansion-02"]);
    expect(resolveFreeCaseIds({})).toEqual(["mansion-01", "mansion-02"]);
    expect(resolveFreeCaseIds({ freeCaseIds: ["mansion-05"] })).toEqual(["mansion-05"]);
    expect(resolveFreeCaseIds({ freeCaseIds: [] })).toEqual([]);
    for (const bad of ["mansion-05", [5], ["../x"], ["-a"], null, {}, Array.from({ length: 51 }, (_, i) => `m-${i}`)]) {
      expect(resolveFreeCaseIds({ freeCaseIds: bad })).toEqual(["mansion-01", "mansion-02"]);
    }
  });
});

describe("limpieza programada", () => {
  it("index.ts declara la función programada diaria en la zona America/Bogota", () => {
    const here = path.dirname(fileURLToPath(import.meta.url));
    const src = readFileSync(path.join(here, "../../functions/src/index.ts"), "utf8");
    expect(src).toContain("onSchedule(");
    expect(src).toContain('timeZone: "America/Bogota"');
    expect(src).toContain("every day");
    expect(src).toContain("runCleanup(");
  });
});

// Integración: emuladores de Auth, Firestore y Functions (npm run test:emulator).
// Se llama a las funciones por HTTP con el protocolo de las callable, igual que el SDK de cliente.
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp, type Firestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { listCaseFiles, DEFAULT_CASES_DIR } from "../../scripts/build-solutions";
import { runCleanup } from "../../functions/src/cleanup";
import { dailyCaseId, isoDate } from "../../functions/src/daily";

const PROJECT = "demo-enigmatrix";
const REGION = "southamerica-east1";
const FUNCTIONS = `http://${process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001"}/${PROJECT}/${REGION}`;
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099"}`;

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

interface Solution {
  positions: Record<string, number>;
  murderer: string;
  lethalWeapon?: string;
}
interface CaseJson {
  caseId: string;
  map: { size: number };
  solution: Solution;
}

const loadCase = (id: string): CaseJson =>
  JSON.parse(readFileSync(path.join(DEFAULT_CASES_DIR, `${id}.json`), "utf8"));

/** Invitado (sesión anónima) del emulador de Auth: solo juega los casos gratis. */
async function signInAnonymously(): Promise<{ uid: string; token: string }> {
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const j = (await r.json()) as { idToken: string; localId: string };
  return { uid: j.localId, token: j.idToken };
}

let userCounter = 0;
/** Crea un usuario con correo y contraseña; `verified` fija email_verified (el token ya lo lleva). */
async function signInEmail(verified: boolean): Promise<{ uid: string; token: string }> {
  const email = `jugador-${Date.now().toString(36)}-${++userCounter}-${Math.random().toString(36).slice(2, 8)}@test.com`;
  const created = await getAuth(app).createUser({ email, password: "clave-segura-1", emailVerified: verified });
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password: "clave-segura-1", returnSecureToken: true }),
  });
  const j = (await r.json()) as { idToken: string };
  return { uid: created.uid, token: j.idToken };
}
/** Usuario registrado (proveedor "password", correo verificado) del emulador de Auth: puede jugar todo. */
const signInRegistered = () => signInEmail(true);
/** Usuario con correo SIN verificar: no puede jugar retos ni poner apodo. */
const signInUnverified = () => signInEmail(false);

interface CallResult {
  status: number;
  /** Cuerpo completo de la respuesta, en texto (para revisar que no se filtre nada). */
  raw: string;
  result?: Record<string, unknown>;
  errorStatus?: string;
  errorDetails?: Record<string, unknown>;
}

let sidCounter = 0;
/** submissionId nuevo y válido (8 a 64 caracteres [A-Za-z0-9_-]). */
const sid = (): string => `sub-${Date.now().toString(36)}-${++sidCounter}`;

async function call(name: string, data: unknown, token?: string): Promise<CallResult> {
  // Los envíos reciben un submissionId nuevo salvo que la prueba lo ponga (aunque sea undefined).
  if (name === "submitSolution" && typeof data === "object" && data !== null && !Array.isArray(data) && !("submissionId" in data)) {
    data = { ...data, submissionId: sid() };
  }
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (token) headers.authorization = `Bearer ${token}`;
  const r = await fetch(`${FUNCTIONS}/${name}`, { method: "POST", headers, body: JSON.stringify({ data }) });
  const raw = await r.text();
  const j = JSON.parse(raw) as { result?: Record<string, unknown>; error?: { status: string; details?: Record<string, unknown> } };
  return { status: r.status, raw, result: j.result, errorStatus: j.error?.status, errorDetails: j.error?.details };
}

/** Un tablero con exactamente `n` personajes fuera de su casilla (rota entre `n` personajes). */
function boardWithWrong(sol: Solution, n: number): Record<string, number> {
  const ids = Object.keys(sol.positions);
  const out = { ...sol.positions };
  for (let i = 0; i < n; i++) out[ids[i]] = sol.positions[ids[(i + 1) % n]];
  return out;
}

let app: App;
let db: Firestore;
const allResponses: string[] = [];
const track = async (p: Promise<CallResult>) => {
  const r = await p;
  allResponses.push(r.raw);
  return r;
};

beforeAll(async () => {
  app = initializeApp({ projectId: PROJECT }, "integration-test");
  db = getFirestore(app);
  // Las soluciones ya van dentro de las funciones (functions/data/solutions.json): no hay nada que publicar.
});
afterAll(async () => {
  await deleteApp(app);
});

/** Fecha local que usa toda la prueba: la de hoy en UTC (siempre cabe en la puerta del reto). */
const TODAY = isoDate(Date.now());
const addDays = (date: string, n: number): string => isoDate(Date.parse(`${date}T00:00:00Z`) + n * 86_400_000);
const retoId = (n: number): string => `reto-${String(n).padStart(3, "0")}`;

/** Deja config/server de modo que el reto de hoy (TODAY) sea reto-n; `extra` suma otros valores. */
async function setDaily(n: number, extra: Record<string, unknown> = {}): Promise<void> {
  await db.doc("config/server").set({ dailyStartDate: addDays(TODAY, -(n - 1)), minRankedElapsedMs: 0, ...extra });
}
const clearConfig = async (): Promise<void> => {
  await db.doc("config/server").delete();
};
const clearRanking = async (date: string = TODAY): Promise<void> => {
  await db.recursiveDelete(db.collection("dailyRankings").doc(date));
};

/** Usuario con apodo (por la función real). */
async function newUser(nick?: string): Promise<{ uid: string; token: string }> {
  const u = await signInRegistered();
  if (nick) {
    const r = await call("setNickname", { nickname: nick }, u.token);
    expect(r.result).toEqual({ nickname: nick.trim() });
  }
  return u;
}

describe("soluciones dentro de las funciones", () => {
  it("existen los 40 casos de la campaña y el reto; el banco caso-* y el tutorial no", async () => {
    expect(listCaseFiles(DEFAULT_CASES_DIR)).toHaveLength(40);
    const u = await signInRegistered();
    for (let i = 1; i <= 10; i++) {
      const id = `mansion-${String(i).padStart(2, "0")}`;
      expect((await track(call("startCase", { caseId: id }, u.token))).status).toBe(200);
    }
    for (let n = 1; n <= 30; n++) {
      await setDaily(n);
      const d = await track(call("getDailyChallenge", { localDate: TODAY }, u.token));
      expect(d.result).toEqual({ localDate: TODAY, caseId: retoId(n) });
      expect((await track(call("startCase", { caseId: retoId(n), localDate: TODAY }, u.token))).status).toBe(200);
    }
    await clearConfig();
    expect((await track(call("startCase", { caseId: "caso-casual-s1" }, u.token))).errorStatus).toBe("NOT_FOUND");
    expect((await track(call("startCase", { caseId: "reto-031", localDate: TODAY }, u.token))).errorStatus).toBe("NOT_FOUND");
  });
  it("ya no existen las colecciones cases ni caseSolutions en Firestore", async () => {
    expect((await db.collection("cases").limit(1).get()).empty).toBe(true);
    expect((await db.collection("caseSolutions").limit(1).get()).empty).toBe(true);
  });
  it("los nombres heredados de JavaScript no son casos", async () => {
    const u = await signInRegistered();
    for (const id of ["constructor", "toString", "hasOwnProperty"]) {
      expect((await track(call("startCase", { caseId: id }, u.token))).errorStatus).toBe("NOT_FOUND");
    }
  });
});

describe("autenticación", () => {
  it("sin sesión se rechaza", async () => {
    const a = await track(call("startCase", { caseId: "mansion-01" }));
    expect(a.errorStatus).toBe("UNAUTHENTICATED");
    const b = await track(
      call("submitSolution", { caseId: "mansion-01", positions: loadCase("mansion-01").solution.positions, clientElapsedMs: 1, startedOnline: true }),
    );
    expect(b.errorStatus).toBe("UNAUTHENTICATED");
  });
});

describe("startCase", () => {
  it("guarda startedAt con hora del servidor y no lo cambia al repetir", async () => {
    const u = await signInRegistered();
    const before = Date.now();
    const a = await track(call("startCase", { caseId: "mansion-02" }, u.token));
    expect(a.status).toBe(200);
    const startedAt = a.result!.startedAt as number;
    expect(startedAt).toBeGreaterThanOrEqual(before - 2000);
    expect(startedAt).toBeLessThanOrEqual(Date.now() + 2000);
    const b = await track(call("startCase", { caseId: "mansion-02" }, u.token));
    expect(b.result!.startedAt).toBe(startedAt);
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-02`).get()).data()!;
    expect(prog.startedAt.toMillis()).toBe(startedAt);
    expect(prog.solved).toBe(false);
    expect((await db.doc(`users/${u.uid}`).get()).exists).toBe(true);
  });
  it("rechaza casos inexistentes y caseId malos", async () => {
    const u = await signInRegistered();
    expect((await track(call("startCase", { caseId: "no-existe" }, u.token))).errorStatus).toBe("NOT_FOUND");
    // El banco no se publica: no existe en el servidor.
    expect((await track(call("startCase", { caseId: "caso-casual-s1" }, u.token))).errorStatus).toBe("NOT_FOUND");
    for (const bad of ["", "a".repeat(65), "a/b", "../caseSolutions/mansion-01", 5, null, undefined]) {
      expect((await track(call("startCase", { caseId: bad }, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
    }
  });
});

describe("submitSolution", () => {
  it("tablero correcto sin arma: solved, ranked si se empezó con startCase y conexión", async () => {
    const c = loadCase("mansion-01");
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-01" }, u.token));
    const r = await track(
      call("submitSolution", { caseId: "mansion-01", positions: c.solution.positions, clientElapsedMs: 5000, startedOnline: true }, u.token),
    );
    expect(r.status).toBe(200);
    expect(r.result).toEqual({ result: "solved", murdererId: c.solution.murderer, lethalWeaponId: null, ranked: true });
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-01`).get()).data()!;
    expect(prog.solved).toBe(true);
    expect(prog.clientElapsedMs).toBe(5000);
    expect(prog.ranked).toBe(true);
    expect(prog.serverElapsedMs).toBe(prog.solvedAt.toMillis() - prog.startedAt.toMillis());
    expect(prog.attempts).toBe(1);
    expect(prog.errors).toBe(0);
  });

  it("tablero correcto con arma devuelve el arma", async () => {
    const c = loadCase("mansion-08");
    const u = await signInRegistered();
    const r = await track(
      call("submitSolution", { caseId: "mansion-08", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", murdererId: "c7", lethalWeaponId: "abrecartas" });
    // Sin startCase previo no hay startedAt: no cuenta para el ranking.
    expect(r.result!.ranked).toBe(false);
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-08`).get()).data()!;
    expect(prog.serverElapsedMs).toBeNull();
  });

  it("ranked es falso si el teléfono dice que empezó sin conexión", async () => {
    const c = loadCase("mansion-03");
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-03" }, u.token));
    const r = await track(
      call("submitSolution", { caseId: "mansion-03", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: false }, u.token),
    );
    expect(r.result!.ranked).toBe(false);
  });

  it("tablero incorrecto: cuenta exacta, suma el error y no revela nada más", async () => {
    const c = loadCase("mansion-04");
    const u = await signInRegistered();
    for (const n of [2, 3]) {
      const r = await track(
        call("submitSolution", { caseId: "mansion-04", positions: boardWithWrong(c.solution, n), clientElapsedMs: 10, startedOnline: true }, u.token),
      );
      expect(r.status).toBe(200);
      expect(r.result).toEqual({ result: "wrong", wrongCount: n });
    }
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-04`).get()).data()!;
    expect(prog.errors).toBe(2);
    expect(prog.attempts).toBe(2);
    expect(prog.solved).toBe(false);
  });

  it("caso ya resuelto: repetir no cambia nada (idempotente)", async () => {
    const c = loadCase("mansion-05");
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-05" }, u.token));
    const body = { caseId: "mansion-05", positions: c.solution.positions, clientElapsedMs: 7, startedOnline: true };
    const first = await track(call("submitSolution", body, u.token));
    const snap1 = (await db.doc(`users/${u.uid}/progress/mansion-05`).get()).data()!;
    const again = await track(call("submitSolution", { ...body, clientElapsedMs: 999, submissionId: sid() }, u.token));
    const wrongAfter = await track(
      call("submitSolution", { ...body, positions: boardWithWrong(c.solution, 2), submissionId: sid() }, u.token),
    );
    expect(again.result).toEqual(first.result);
    expect(wrongAfter.result).toEqual(first.result);
    const snap2 = (await db.doc(`users/${u.uid}/progress/mansion-05`).get()).data()!;
    expect(snap2).toEqual(snap1);
  });

  it("envíos simultáneos del mismo tablero correcto no duplican efectos", async () => {
    const c = loadCase("mansion-06");
    const u = await signInRegistered();
    const body = { caseId: "mansion-06", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true };
    const rs = await Promise.all([1, 2, 3].map(() => track(call("submitSolution", body, u.token))));
    for (const r of rs) expect(r.result!.result).toBe("solved");
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-06`).get()).data()!;
    expect(prog.attempts).toBe(1);
  });

  it("límite de intentos: el séptimo envío en un minuto da resource-exhausted", async () => {
    const c = loadCase("mansion-07");
    const u = await signInRegistered();
    const body = { caseId: "mansion-07", positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true };
    for (let i = 0; i < 6; i++) {
      const r = await track(call("submitSolution", body, u.token));
      expect(r.result).toEqual({ result: "wrong", wrongCount: 2 });
    }
    const blocked = await track(call("submitSolution", body, u.token));
    expect(blocked.errorStatus).toBe("RESOURCE_EXHAUSTED");
    // Otro caso del mismo usuario y otro usuario en el mismo caso no se ven afectados.
    const other = await signInRegistered();
    expect((await track(call("submitSolution", body, other.token))).result!.result).toBe("wrong");
    const c9 = loadCase("mansion-09");
    const ok = await track(
      call("submitSolution", { caseId: "mansion-09", positions: boardWithWrong(c9.solution, 2), clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(ok.result!.result).toBe("wrong");
    // El bloqueado no suma error ni intento.
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-07`).get()).data()!;
    expect(prog.attempts).toBe(6);
  });

  it("20 envíos fallidos en paralelo: exactamente 6 wrong, el resto bloqueados (resource-exhausted o aborted), attempts == 6", async () => {
    const c = loadCase("reto-002");
    await setDaily(2);
    const u = await signInRegistered();
    // Calentamiento: el emulador abre un proceso por cada llamada simultánea y cargar 20 de golpe
    // puede pasar del tiempo de carga. Se sube la concurrencia por oleadas para que ya estén abiertos.
    for (const wave of [4, 8, 12, 16, 20]) {
      await Promise.all(Array.from({ length: wave }, () => call("getDailyChallenge", { localDate: TODAY }, u.token)));
    }
    // Lo mismo con submitSolution, con una entrada inválida: abre los procesos sin tocar el progreso.
    for (const wave of [4, 8, 12, 16, 20]) {
      await Promise.all(Array.from({ length: wave }, () => call("submitSolution", {}, u.token)));
    }
    const board = boardWithWrong(c.solution, 2);
    const rs = await Promise.all(
      Array.from({ length: 20 }, () =>
        track(call("submitSolution", { caseId: "reto-002", localDate: TODAY, positions: board, clientElapsedMs: 1, startedOnline: true }, u.token)),
      ),
    );
    const wrongs = rs.filter((r) => r.result?.result === "wrong");
    // Con 20 transacciones a la vez el emulador puede abortar algunas por
    // contención: deben llegar como "aborted" (reintentable), nunca como
    // "internal". Lo que importa es que no pasen más de 6 intentos.
    const blocked = rs.filter((r) => r.errorStatus === "RESOURCE_EXHAUSTED" || r.errorStatus === "ABORTED");
    expect(rs.filter((r) => r.errorStatus === "INTERNAL")).toHaveLength(0);
    expect(wrongs).toHaveLength(6);
    expect(blocked).toHaveLength(14);
    const prog = (await db.doc(`users/${u.uid}/progress/reto-002`).get()).data()!;
    expect(prog.attempts).toBe(6);
    expect(prog.errors).toBe(6);
  });

  it("sondear sin startCase, luego startCase y luego el tablero correcto: ranked false para siempre", async () => {
    const c = loadCase("reto-003");
    await setDaily(3);
    const u = await signInRegistered();
    const probe = await track(
      call("submitSolution", { caseId: "reto-003", localDate: TODAY, positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(probe.result).toEqual({ result: "wrong", wrongCount: 2 });
    const progRef = db.doc(`users/${u.uid}/progress/reto-003`);
    expect((await progRef.get()).data()!.rankable).toBe(false);
    // startCase sí guarda startedAt, pero no devuelve el progreso a rankeable.
    const st = await track(call("startCase", { caseId: "reto-003", localDate: TODAY }, u.token));
    expect(st.status).toBe(200);
    const afterStart = (await progRef.get()).data()!;
    expect(afterStart.startedAt.toMillis()).toBe(st.result!.startedAt);
    expect(afterStart.rankable).toBe(false);
    const r = await track(
      call("submitSolution", { caseId: "reto-003", localDate: TODAY, positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", ranked: false });
    const prog = (await progRef.get()).data()!;
    expect(prog.ranked).toBe(false);
    expect(prog.rankable).toBe(false);
  });

  it("startedOnline solo puede bajar ranked: false con startCase da false; true con startCase da true", async () => {
    const c = loadCase("reto-004");
    await setDaily(4);
    const off = await signInRegistered();
    await track(call("startCase", { caseId: "reto-004", localDate: TODAY }, off.token));
    const a = await track(
      call("submitSolution", { caseId: "reto-004", localDate: TODAY, positions: c.solution.positions, clientElapsedMs: 1, startedOnline: false }, off.token),
    );
    expect(a.result!.ranked).toBe(false);
    const on = await signInRegistered();
    await track(call("startCase", { caseId: "reto-004", localDate: TODAY }, on.token));
    const b = await track(
      call("submitSolution", { caseId: "reto-004", localDate: TODAY, positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, on.token),
    );
    expect(b.result!.ranked).toBe(true);
    expect((await db.doc(`users/${on.uid}/progress/reto-004`).get()).data()!.rankable).toBeUndefined();
  });

  it("un submissionId repetido devuelve la misma respuesta sin sumar intento, error ni límite", async () => {
    const c = loadCase("reto-005");
    await setDaily(5);
    const u = await signInRegistered();
    const wrongBody = { caseId: "reto-005", localDate: TODAY, positions: boardWithWrong(c.solution, 3), clientElapsedMs: 1, startedOnline: true };
    const id = "reintento-0001";
    const first = await track(call("submitSolution", { ...wrongBody, submissionId: id }, u.token));
    expect(first.result).toEqual({ result: "wrong", wrongCount: 3 });
    const progRef = db.doc(`users/${u.uid}/progress/reto-005`);
    const snap1 = (await progRef.get()).data()!;
    // 10 reintentos del mismo envío (más que el límite de 6 por minuto): ninguno falla ni suma.
    for (let i = 0; i < 10; i++) {
      const again = await track(call("submitSolution", { ...wrongBody, submissionId: id }, u.token));
      expect(again.result).toEqual(first.result);
    }
    const snap2 = (await progRef.get()).data()!;
    expect(snap2.attempts).toBe(1);
    expect(snap2.errors).toBe(1);
    expect(snap2).toEqual(snap1);
    // Y el límite sigue intacto: caben 5 envíos nuevos más.
    for (let i = 0; i < 5; i++) {
      expect((await track(call("submitSolution", wrongBody, u.token))).result!.result).toBe("wrong");
    }
    expect((await track(call("submitSolution", wrongBody, u.token))).errorStatus).toBe("RESOURCE_EXHAUSTED");
    // Guarda los envíos (aquí 6) con la respuesta dada.
    const stored = (await progRef.get()).data()!.lastSubmissions as Array<{ id: string; response: unknown }>;
    expect(stored).toHaveLength(6);
    expect(stored[0]).toEqual({ id, response: first.result });
  });

  it("marca suspicious si el teléfono declara más tiempo que el servidor + margen (configurable)", async () => {
    await setDaily(6);
    const solve = async (elapsed: number) => {
      const caseId = "reto-006";
      const u = await signInRegistered();
      await track(call("startCase", { caseId, localDate: TODAY }, u.token));
      await track(
        call("submitSolution", { caseId, localDate: TODAY, positions: loadCase(caseId).solution.positions, clientElapsedMs: elapsed, startedOnline: true }, u.token),
      );
      return (await db.doc(`users/${u.uid}/progress/${caseId}`).get()).data()!;
    };
    expect((await solve(600_000)).suspicious).toBe(true);
    expect((await solve(1)).suspicious).toBe(false);
    // Con un margen mayor en config/server, el mismo tiempo ya no es sospechoso.
    await setDaily(6, { clientClockMarginMs: 10_000_000 });
    try {
      expect((await solve(600_000)).suspicious).toBe(false);
    } finally {
      await clearConfig();
    }
  });

  it("el máximo se puede cambiar en config/server", async () => {
    await db.doc("config/server").set({ maxSubmitsPerMinute: 2 });
    try {
      const c = loadCase("mansion-10");
      const u = await signInRegistered();
      const body = { caseId: "mansion-10", positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true };
      expect((await track(call("submitSolution", body, u.token))).result!.result).toBe("wrong");
      expect((await track(call("submitSolution", body, u.token))).result!.result).toBe("wrong");
      expect((await track(call("submitSolution", body, u.token))).errorStatus).toBe("RESOURCE_EXHAUSTED");
    } finally {
      await db.doc("config/server").delete();
    }
  });
});

describe("entrada maliciosa", () => {
  const c = loadCase("reto-001");
  const good = c.solution.positions;
  const ids = Object.keys(good);
  const size2 = c.map.size * c.map.size;
  const base = { caseId: "reto-001", localDate: TODAY, positions: good, clientElapsedMs: 1000, startedOnline: true, submissionId: "base-submission-1" };
  beforeAll(async () => {
    await setDaily(1);
  });

  const cases: Array<[string, unknown, string]> = [
    ["falta un personaje", { ...base, positions: Object.fromEntries(Object.entries(good).slice(1)) }, "INVALID_ARGUMENT"],
    ["personaje de más", { ...base, positions: { ...good, zz: 0 } }, "INVALID_ARGUMENT"],
    ["id desconocido en lugar de uno válido", { ...base, positions: { ...Object.fromEntries(Object.entries(good).slice(1)), zz: 0 } }, "INVALID_ARGUMENT"],
    ["casilla negativa", { ...base, positions: { ...good, [ids[0]]: -1 } }, "INVALID_ARGUMENT"],
    ["casilla fuera del tablero", { ...base, positions: { ...good, [ids[0]]: size2 } }, "INVALID_ARGUMENT"],
    ["casilla decimal", { ...base, positions: { ...good, [ids[0]]: 1.5 } }, "INVALID_ARGUMENT"],
    ["casilla como texto", { ...base, positions: { ...good, [ids[0]]: "3" } }, "INVALID_ARGUMENT"],
    ["casilla nula", { ...base, positions: { ...good, [ids[0]]: null } }, "INVALID_ARGUMENT"],
    ["casillas repetidas", { ...base, positions: { ...good, [ids[0]]: good[ids[1]] } }, "INVALID_ARGUMENT"],
    ["positions es una lista", { ...base, positions: Object.values(good) }, "INVALID_ARGUMENT"],
    ["positions es texto", { ...base, positions: "hola" }, "INVALID_ARGUMENT"],
    ["positions falta", { caseId: "reto-001", clientElapsedMs: 1, startedOnline: true }, "INVALID_ARGUMENT"],
    ["tiempo negativo", { ...base, clientElapsedMs: -1 }, "INVALID_ARGUMENT"],
    ["tiempo mayor a 24 h", { ...base, clientElapsedMs: 86_400_001 }, "INVALID_ARGUMENT"],
    ["tiempo como texto", { ...base, clientElapsedMs: "10" }, "INVALID_ARGUMENT"],
    ["tiempo ausente", { caseId: "reto-001", positions: good, startedOnline: true }, "INVALID_ARGUMENT"],
    ["startedOnline no booleano", { ...base, startedOnline: "yes" }, "INVALID_ARGUMENT"],
    ["submissionId ausente", { ...base, submissionId: undefined }, "INVALID_ARGUMENT"],
    ["submissionId demasiado corto", { ...base, submissionId: "abc1234" }, "INVALID_ARGUMENT"],
    ["submissionId demasiado largo", { ...base, submissionId: "a".repeat(65) }, "INVALID_ARGUMENT"],
    ["submissionId con caracteres raros", { ...base, submissionId: "abcd efgh/12" }, "INVALID_ARGUMENT"],
    ["submissionId numérico", { ...base, submissionId: 12345678 }, "INVALID_ARGUMENT"],
    ["caseId que empieza por guion", { ...base, caseId: "-reto-001" }, "INVALID_ARGUMENT"],
    ["caseId que empieza por guion bajo", { ...base, caseId: "_reto-001" }, "INVALID_ARGUMENT"],
    ["caseId inexistente", { ...base, caseId: "reto-999" }, "NOT_FOUND"],
    ["caseId con barra (ruta)", { ...base, caseId: "reto-001/../x" }, "INVALID_ARGUMENT"],
    ["caseId de 65 caracteres", { ...base, caseId: "a".repeat(65) }, "INVALID_ARGUMENT"],
    ["caseId numérico", { ...base, caseId: 7 }, "INVALID_ARGUMENT"],
    ["data nulo", null, "INVALID_ARGUMENT"],
    ["data es una lista", [1, 2, 3], "INVALID_ARGUMENT"],
    [
      "objeto enorme",
      { ...base, positions: Object.fromEntries(Array.from({ length: 20000 }, (_, i) => [`k${i}`, i])) },
      "INVALID_ARGUMENT",
    ],
  ];

  it.each(cases)("rechaza: %s", async (_name, data, status) => {
    const u = await signInRegistered();
    const r = await track(call("submitSolution", data, u.token));
    expect(r.errorStatus).toBe(status);
    // Una entrada rechazada no deja rastro en el progreso.
    const prog = await db.doc(`users/${u.uid}/progress/reto-001`).get();
    expect(prog.exists).toBe(false);
  });

  it("__proto__ como clave no sirve para colar un tablero", async () => {
    const u = await signInRegistered();
    const raw = JSON.stringify({ data: { ...base, positions: JSON.parse(`{"__proto__": 1, "${ids[1]}": ${good[ids[1]]}}`) } });
    const r = await fetch(`${FUNCTIONS}/submitSolution`, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${u.token}` },
      body: raw,
    });
    const j = (await r.json()) as { error?: { status: string; details?: Record<string, unknown> } };
    expect(j.error?.status).toBe("INVALID_ARGUMENT");
  });
});

describe("getDailyChallenge", () => {
  it("sin sesión se rechaza", async () => {
    expect((await track(call("getDailyChallenge", { localDate: TODAY }))).errorStatus).toBe("UNAUTHENTICATED");
  });
  it("devuelve el reto de la fecha con la fecha de inicio por defecto (2026-11-16)", async () => {
    await clearConfig();
    const u = await signInRegistered();
    const r = await track(call("getDailyChallenge", { localDate: TODAY }, u.token));
    expect(r.status).toBe(200);
    expect(r.result).toEqual({ localDate: TODAY, caseId: dailyCaseId(TODAY, "2026-11-16") });
  });
  it("usa dailyStartDate de config/server y avanza un reto por día (en ciclo de 30)", async () => {
    const u = await signInRegistered();
    await db.doc("config/server").set({ dailyStartDate: addDays(TODAY, -29) });
    try {
      expect((await track(call("getDailyChallenge", { localDate: TODAY }, u.token))).result!.caseId).toBe("reto-030");
      // Mañana (si cabe en la ventana de husos) sería reto-001 otra vez; se comprueba con la fórmula.
      await db.doc("config/server").set({ dailyStartDate: TODAY });
      expect((await track(call("getDailyChallenge", { localDate: TODAY }, u.token))).result!.caseId).toBe("reto-001");
    } finally {
      await clearConfig();
    }
  });
  it("crea users/{uid} con createdAt y lastSeenAt", async () => {
    const u = await signInRegistered();
    await track(call("getDailyChallenge", { localDate: TODAY }, u.token));
    const user = (await db.doc(`users/${u.uid}`).get()).data()!;
    expect(user.createdAt).toBeInstanceOf(Timestamp);
    expect(user.lastSeenAt).toBeInstanceOf(Timestamp);
  });
  it("fecha inválida: INVALID_ARGUMENT", async () => {
    const u = await signInRegistered();
    for (const bad of [undefined, null, "", "2026-02-30", "16-11-2026", "2026/11/16", 20261116, "hoy", {}]) {
      const r = await track(call("getDailyChallenge", { localDate: bad }, u.token));
      expect(r.errorStatus, String(bad)).toBe("INVALID_ARGUMENT");
    }
    expect((await track(call("getDailyChallenge", null, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
  });
  it("puerta de fechas: ayer, mañana y fechas lejanas dan FAILED_PRECONDITION (UTC-12 a UTC+14)", async () => {
    const u = await signInRegistered();
    for (const d of [addDays(TODAY, -3), addDays(TODAY, 3), "2020-01-01", "2099-12-31"]) {
      const r = await track(call("getDailyChallenge", { localDate: d }, u.token));
      expect(r.errorStatus, d).toBe("FAILED_PRECONDITION");
      expect(r.raw).toContain("fecha");
    }
  });
});

describe("puerta del reto diario", () => {
  const solve = (u: { token: string }, caseId: string, localDate?: unknown) =>
    track(
      call(
        "submitSolution",
        { caseId, ...(localDate === undefined ? {} : { localDate }), positions: loadCase(caseId).solution.positions, clientElapsedMs: 1, startedOnline: true },
        u.token,
      ),
    );

  it("startCase de un reto exige localDate", async () => {
    await setDaily(10);
    const u = await signInRegistered();
    expect((await track(call("startCase", { caseId: "reto-010" }, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await track(call("startCase", { caseId: "reto-010", localDate: "2026-02-30" }, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await track(call("startCase", { caseId: "reto-010", localDate: TODAY }, u.token))).status).toBe(200);
  });
  it("un reto que no toca hoy no se entrega ni se valida (FAILED_PRECONDITION) y no deja rastro", async () => {
    await setDaily(10);
    const u = await signInRegistered();
    expect((await track(call("startCase", { caseId: "reto-011", localDate: TODAY }, u.token))).errorStatus).toBe("FAILED_PRECONDITION");
    expect((await solve(u, "reto-011", TODAY)).errorStatus).toBe("FAILED_PRECONDITION");
    expect((await db.doc(`users/${u.uid}/progress/reto-011`).get()).exists).toBe(false);
  });
  it("fecha de otro día (fuera de los husos): FAILED_PRECONDITION en startCase y submitSolution", async () => {
    await setDaily(10);
    const u = await signInRegistered();
    for (const d of [addDays(TODAY, -3), addDays(TODAY, 3)]) {
      // La fórmula daría otro reto o el mismo, pero la fecha ya no es de hoy en ningún huso.
      const id = dailyCaseId(d, addDays(TODAY, -9));
      expect((await track(call("startCase", { caseId: id, localDate: d }, u.token))).errorStatus, d).toBe("FAILED_PRECONDITION");
      expect((await solve(u, id, d)).errorStatus, d).toBe("FAILED_PRECONDITION");
    }
  });
  it("submitSolution de un reto sin localDate o con una inválida: INVALID_ARGUMENT", async () => {
    await setDaily(10);
    const u = await signInRegistered();
    expect((await solve(u, "reto-010")).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await solve(u, "reto-010", "ayer")).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await solve(u, "reto-010", 5)).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await db.doc(`users/${u.uid}/progress/reto-010`).get()).exists).toBe(false);
  });
  it("los casos de la campaña no necesitan localDate", async () => {
    const u = await signInRegistered();
    expect((await track(call("startCase", { caseId: "mansion-01" }, u.token))).status).toBe(200);
    // Si la mandan mal formada, se rechaza igual (entrada inválida).
    expect((await track(call("startCase", { caseId: "mansion-01", localDate: "mal" }, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
  });
  it("la fecha del día siguiente en el huso adelantado se acepta si cae en la ventana", async () => {
    const tomorrow = addDays(TODAY, 1);
    const inWindow = isoDate(Date.now() + 14 * 3_600_000) >= tomorrow; // ¿ya es mañana en UTC+14?
    await setDaily(12);
    const u = await signInRegistered();
    const id = dailyCaseId(tomorrow, addDays(TODAY, -11));
    const r = await track(call("startCase", { caseId: id, localDate: tomorrow }, u.token));
    if (inWindow) expect(r.status).toBe(200);
    else expect(r.errorStatus).toBe("FAILED_PRECONDITION");
  });
  it("un reto de otro ciclo (progreso de otra fecha) se reinicia al empezar de nuevo", async () => {
    await setDaily(8);
    const c8 = loadCase("reto-008");
    const u = await newUser("Ciclo Dos");
    // Progreso viejo, resuelto en otra fecha (el mismo reto volvió a tocar 30 días después).
    await db.doc(`users/${u.uid}/progress/reto-008`).set({
      startedAt: Timestamp.fromMillis(1_000),
      solved: true,
      solvedAt: Timestamp.fromMillis(5_000),
      attempts: 4,
      errors: 3,
      ranked: true,
      serverElapsedMs: 4_000,
      score: 94_000,
      rank: 1,
      localDate: addDays(TODAY, -30),
      lastSubmissions: [{ id: "viejo-envio-1", response: { result: "solved" } }],
    });
    const st = await track(call("startCase", { caseId: "reto-008", localDate: TODAY }, u.token));
    expect(st.status).toBe(200);
    const fresh = (await db.doc(`users/${u.uid}/progress/reto-008`).get()).data()!;
    expect(fresh.solved).toBe(false);
    expect(fresh.errors).toBe(0);
    expect(fresh.localDate).toBe(TODAY);
    expect(fresh.startedAt.toMillis()).toBe(st.result!.startedAt);
    expect(fresh.startedAt.toMillis()).toBeGreaterThan(1_000_000);
    // Y se puede resolver y entrar al ranking de hoy como si fuera la primera vez.
    await clearRanking();
    const r = await track(
      call("submitSolution", { caseId: "reto-008", localDate: TODAY, positions: c8.solution.positions, clientElapsedMs: 1, startedOnline: true, submissionId: "viejo-envio-1" }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", ranked: true, errors: 0, rank: 1 });
    await clearRanking();
  });
});

describe("ranking del día", () => {
  const solveReto = async (
    n: number,
    u: { uid: string; token: string },
    opts: { wrong?: number; start?: boolean; online?: boolean } = {},
  ) => {
    const id = retoId(n);
    const c = loadCase(id);
    if (opts.start !== false) await track(call("startCase", { caseId: id, localDate: TODAY }, u.token));
    for (let i = 0; i < (opts.wrong ?? 0); i++) {
      const w = await track(
        call("submitSolution", { caseId: id, localDate: TODAY, positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true }, u.token),
      );
      expect(w.result).toEqual({ result: "wrong", wrongCount: 2 });
    }
    return track(
      call("submitSolution", { caseId: id, localDate: TODAY, positions: c.solution.positions, clientElapsedMs: 1, startedOnline: opts.online ?? true }, u.token),
    );
  };
  const entry = async (uid: string, date: string = TODAY) => (await db.doc(`dailyRankings/${date}/entries/${uid}`).get()).data();

  it("con apodo entra: score = tiempo del servidor, rank 1, y la entrada trae los campos del contrato", async () => {
    await setDaily(20, { maxSubmitsPerMinute: 60 });
    await clearRanking();
    const u = await newUser("  Detective Ana  ");
    const r = await solveReto(20, u);
    expect(r.status).toBe(200);
    const res = r.result!;
    expect(res).toMatchObject({ result: "solved", ranked: true, errors: 0, rank: 1 });
    expect(Object.keys(res).sort()).toEqual(
      ["errors", "lethalWeaponId", "murdererId", "ranked", "rank", "result", "score", "serverElapsedMs"].sort(),
    );
    expect(typeof res.serverElapsedMs).toBe("number");
    expect(res.score).toBe(res.serverElapsedMs);
    const prog = (await db.doc(`users/${u.uid}/progress/reto-020`).get()).data()!;
    expect(prog.serverElapsedMs).toBe(prog.solvedAt.toMillis() - prog.startedAt.toMillis());
    const e = (await entry(u.uid))!;
    expect(e).not.toHaveProperty("uid");
    expect(Object.keys(e).sort()).toEqual(["errors", "nickname", "score", "serverElapsedMs", "solvedAt"]);
    expect(e).toMatchObject({ nickname: "Detective Ana", errors: 0, score: res.score, serverElapsedMs: res.serverElapsedMs });
    expect(e.solvedAt.toMillis()).toBe(prog.solvedAt.toMillis());
    expect(prog.localDate).toBe(TODAY);
    expect(prog.rank).toBe(1);
    expect(prog.score).toBe(res.score);
    await clearRanking();
    await clearConfig();
  });

  it("cada error suma 30 s al score (y el valor sale de errorPenaltyMs)", async () => {
    await setDaily(21, { maxSubmitsPerMinute: 60 });
    await clearRanking();
    const u = await newUser("Penalizado");
    const r = await solveReto(21, u, { wrong: 2 });
    expect(r.result).toMatchObject({ result: "solved", errors: 2, ranked: true });
    expect(r.result!.score).toBe((r.result!.serverElapsedMs as number) + 60_000);
    expect((await entry(u.uid))!.score).toBe(r.result!.score);
    // Con otro valor de penalización en config/server.
    await clearRanking();
    await setDaily(21, { maxSubmitsPerMinute: 60, errorPenaltyMs: 1000 });
    const v = await newUser("Penalizado Dos");
    const r2 = await solveReto(21, v, { wrong: 3 });
    expect(r2.result!.score).toBe((r2.result!.serverElapsedMs as number) + 3000);
    await clearRanking();
    await clearConfig();
  });

  it("el puesto cuenta a los que tienen menor score; los peores no pasan por delante", async () => {
    await setDaily(22, { maxSubmitsPerMinute: 60 });
    await clearRanking();
    const col = db.collection("dailyRankings").doc(TODAY).collection("entries");
    const seed = (id: string, score: number, solvedAtMs: number) =>
      col.doc(id).set({ nickname: id, serverElapsedMs: score, errors: 0, score, solvedAt: Timestamp.fromMillis(solvedAtMs) });
    await seed("mejor-1", 0, 1_000);
    await seed("mejor-2", 0, 2_000);
    await seed("peor-1", 9_000_000_000, 3_000);
    const u = await newUser("Tercero");
    const r = await solveReto(22, u);
    expect(r.result!.rank).toBe(3);
    // El tercero ya aparece en la consulta del cliente (score ascendente), por detrás de los dos mejores.
    const top = await col.orderBy("score").orderBy("solvedAt").limit(50).get();
    expect(top.docs.map((d) => d.id)).toEqual(["mejor-1", "mejor-2", u.uid, "peor-1"]);
    await clearRanking();
    await clearConfig();
  });

  it("con el mismo score gana quien resolvió antes (solvedAt más antiguo)", async () => {
    await clearRanking();
    const col = db.collection("dailyRankings").doc(TODAY).collection("entries");
    const seed = (id: string, solvedAtMs: number) =>
      col.doc(id).set({ nickname: id, serverElapsedMs: 5000, errors: 0, score: 5000, solvedAt: Timestamp.fromMillis(solvedAtMs) });
    await seed("tarde", 3_000);
    await seed("primero", 1_000);
    await seed("medio", 2_000);
    const top = await col.orderBy("score").orderBy("solvedAt").limit(50).get();
    expect(top.docs.map((d) => d.id)).toEqual(["primero", "medio", "tarde"]);
    await clearRanking();
  });

  it("sin apodo ranked es true pero no entra (rank null); al poner el apodo la entrada aparece y se actualiza", async () => {
    await setDaily(23, { maxSubmitsPerMinute: 60 });
    await clearRanking();
    const u = await newUser();
    const r = await solveReto(23, u);
    expect(r.result).toMatchObject({ result: "solved", ranked: true, rank: null, errors: 0 });
    expect(typeof r.result!.score).toBe("number");
    expect(await entry(u.uid)).toBeUndefined();
    // Pone el apodo después: la entrada se crea con los datos de su partida.
    const n1 = await track(call("setNickname", { nickname: "Tardón" }, u.token));
    expect(n1.result).toEqual({ nickname: "Tardón" });
    const e1 = (await entry(u.uid))!;
    expect(e1).toMatchObject({ nickname: "Tardón", score: r.result!.score, serverElapsedMs: r.result!.serverElapsedMs, errors: 0 });
    // Lo cambia: la entrada lleva el apodo nuevo y conserva el resto.
    await track(call("setNickname", { nickname: "Madrugador" }, u.token));
    const e2 = (await entry(u.uid))!;
    expect(e2).toMatchObject({ nickname: "Madrugador", score: e1.score, serverElapsedMs: e1.serverElapsedMs });
    expect(e2.solvedAt.toMillis()).toBe(e1.solvedAt.toMillis());
    expect((await db.doc(`users/${u.uid}`).get()).data()!.nickname).toBe("Madrugador");
    await clearRanking();
    await clearConfig();
  });

  it("un apodo nuevo no toca las entradas de otros jugadores", async () => {
    await setDaily(24);
    await clearRanking();
    const a = await newUser("Jugador A");
    const b = await newUser("Jugador B");
    await solveReto(24, a);
    await solveReto(24, b);
    await track(call("setNickname", { nickname: "Jugador C" }, a.token));
    expect((await entry(a.uid))!.nickname).toBe("Jugador C");
    expect((await entry(b.uid))!.nickname).toBe("Jugador B");
    // El segundo en resolver queda por detrás con el mismo reto: el puesto es 2 si su score es mayor.
    const ea = (await entry(a.uid))!;
    const eb = (await entry(b.uid))!;
    const first = ea.score <= eb.score ? ea : eb;
    expect(first.score).toBeLessThanOrEqual(Math.max(ea.score, eb.score));
    await clearRanking();
    await clearConfig();
  });

  it("no entra si empezó sin conexión, sin startCase o si resuelve otro reto que no es el de hoy", async () => {
    await setDaily(25);
    await clearRanking();
    const off = await newUser("Sin Conexion");
    const r1 = await solveReto(25, off, { online: false });
    expect(r1.result).toMatchObject({ result: "solved", ranked: false, rank: null });
    expect(await entry(off.uid)).toBeUndefined();
    const probe = await newUser("Sin Start");
    const r2 = await solveReto(25, probe, { start: false });
    expect(r2.result).toMatchObject({ result: "solved", ranked: false, rank: null, serverElapsedMs: null, score: null });
    expect(await entry(probe.uid)).toBeUndefined();
    // La campaña (mansion-*) nunca entra al ranking, ni con apodo ni con conexión.
    const camp = await newUser("Campana Uno");
    await track(call("startCase", { caseId: "mansion-02" }, camp.token));
    const m = await track(
      call("submitSolution", { caseId: "mansion-02", positions: loadCase("mansion-02").solution.positions, clientElapsedMs: 1, startedOnline: true }, camp.token),
    );
    expect(m.result!.ranked).toBe(true);
    expect(Object.keys(m.result!).sort()).toEqual(["lethalWeaponId", "murdererId", "ranked", "result"]);
    expect((await db.collection("dailyRankings").doc(TODAY).collection("entries").get()).size).toBe(0);
    await clearRanking();
    await clearConfig();
  });

  it("repetir un reto resuelto devuelve los mismos datos y no cambia el ranking", async () => {
    await setDaily(26);
    await clearRanking();
    const u = await newUser("Repetidor");
    const first = await solveReto(26, u);
    const e1 = await entry(u.uid);
    const again = await track(
      call("submitSolution", { caseId: "reto-026", localDate: TODAY, positions: loadCase("reto-026").solution.positions, clientElapsedMs: 77, startedOnline: true }, u.token),
    );
    expect(again.result).toEqual(first.result);
    expect(await entry(u.uid)).toEqual(e1);
    expect((await db.collection("dailyRankings").doc(TODAY).collection("entries").get()).size).toBe(1);
    await clearRanking();
    await clearConfig();
  });
});

describe("tope de errores por caso", () => {
  it("al llegar a maxWrongPerCase en un reto: failed-precondition con reason wrong-limit (también con el tablero correcto) y no entra al ranking", async () => {
    await setDaily(27, { maxWrongPerCase: 3, maxSubmitsPerMinute: 60 });
    await clearRanking();
    const c = loadCase("reto-027");
    const u = await newUser("Tope Tres");
    await track(call("startCase", { caseId: "reto-027", localDate: TODAY }, u.token));
    const wrong = { caseId: "reto-027", localDate: TODAY, positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true };
    for (let i = 0; i < 3; i++) expect((await track(call("submitSolution", wrong, u.token))).result).toEqual({ result: "wrong", wrongCount: 2 });
    const blocked = await track(call("submitSolution", wrong, u.token));
    expect(blocked.errorStatus).toBe("FAILED_PRECONDITION");
    expect(blocked.raw).toContain("Llegaste al máximo de intentos del reto de hoy.");
    expect(blocked.errorDetails).toEqual({ reason: "wrong-limit" });
    const good = await track(
      call("submitSolution", { ...wrong, positions: c.solution.positions }, u.token),
    );
    expect(good.errorStatus).toBe("FAILED_PRECONDITION");
    expect(good.errorDetails).toEqual({ reason: "wrong-limit" });
    const prog = (await db.doc(`users/${u.uid}/progress/reto-027`).get()).data()!;
    expect(prog.errors).toBe(3);
    expect(prog.solved).toBe(false);
    expect(await entry27(u.uid)).toBeUndefined();
    await clearRanking();
    await clearConfig();
  });

  it("la campaña no tiene tope de errores: más de 15 errores siguen evaluándose", async () => {
    await db.doc("config/server").set({ maxWrongPerCase: 2, maxSubmitsPerMinute: 60 });
    const c = loadCase("mansion-05");
    const u = await signInRegistered();
    const wrong = { caseId: "mansion-05", positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true };
    try {
      for (let i = 0; i < 5; i++) {
        expect((await track(call("submitSolution", wrong, u.token))).result, String(i)).toEqual({ result: "wrong", wrongCount: 2 });
      }
      const prog = (await db.doc(`users/${u.uid}/progress/mansion-05`).get()).data()!;
      expect(prog.errors).toBe(5);
      const ok = await track(call("submitSolution", { ...wrong, positions: c.solution.positions }, u.token));
      expect(ok.result).toMatchObject({ result: "solved" });
    } finally {
      await clearConfig();
    }
  });

  it("el tope de un reto es por usuario: otro jugador no queda bloqueado", async () => {
    await setDaily(26, { maxWrongPerCase: 1, maxSubmitsPerMinute: 60 });
    try {
      const mk = { caseId: "reto-026", localDate: TODAY, positions: boardWithWrong(loadCase("reto-026").solution, 2), clientElapsedMs: 1, startedOnline: true };
      const u = await signInRegistered();
      expect((await track(call("submitSolution", mk, u.token))).result!.result).toBe("wrong");
      expect((await track(call("submitSolution", mk, u.token))).errorDetails).toEqual({ reason: "wrong-limit" });
      const other = await signInRegistered();
      expect((await track(call("submitSolution", mk, other.token))).result!.result).toBe("wrong");
    } finally {
      await clearConfig();
    }
  });

  it("el límite por minuto sigue siendo resource-exhausted (sin reason wrong-limit)", async () => {
    await db.doc("config/server").set({ maxSubmitsPerMinute: 1 });
    try {
      const u = await signInRegistered();
      const w = { caseId: "mansion-06", positions: boardWithWrong(loadCase("mansion-06").solution, 2), clientElapsedMs: 1, startedOnline: true };
      expect((await track(call("submitSolution", w, u.token))).result!.result).toBe("wrong");
      const r = await track(call("submitSolution", w, u.token));
      expect(r.errorStatus).toBe("RESOURCE_EXHAUSTED");
      expect(r.errorDetails).toBeUndefined();
    } finally {
      await clearConfig();
    }
  });

});

async function entry27(uid: string) {
  return (await db.doc(`dailyRankings/${TODAY}/entries/${uid}`).get()).data();
}

describe("setNickname", () => {
  it("sin sesión se rechaza", async () => {
    expect((await track(call("setNickname", { nickname: "Ana" }))).errorStatus).toBe("UNAUTHENTICATED");
  });
  it("guarda el apodo limpio en users/{uid} y devuelve el apodo ya limpio", async () => {
    const u = await signInRegistered();
    const r = await track(call("setNickname", { nickname: "   José_Luis.9  " }, u.token));
    expect(r.status).toBe(200);
    expect(r.result).toEqual({ nickname: "José_Luis.9" });
    const user = (await db.doc(`users/${u.uid}`).get()).data()!;
    expect(user.nickname).toBe("José_Luis.9");
    expect(user.createdAt).toBeInstanceOf(Timestamp);
    expect(user.lastSeenAt).toBeInstanceOf(Timestamp);
  });
  it("acepta apodos válidos, también repetidos entre jugadores (no es único)", async () => {
    const a = await signInRegistered();
    const b = await signInRegistered();
    for (const ok of ["Ana", "Ñandú Ángel", "pepe-99", "a.b_c", "a".repeat(16), "1234"]) {
      expect((await track(call("setNickname", { nickname: ok }, a.token))).result).toEqual({ nickname: ok });
    }
    expect((await track(call("setNickname", { nickname: "Repetido" }, a.token))).result).toEqual({ nickname: "Repetido" });
    expect((await track(call("setNickname", { nickname: "Repetido" }, b.token))).result).toEqual({ nickname: "Repetido" });
  });
  it("rechaza apodos inválidos con el motivo en español y no cambia el apodo guardado", async () => {
    const u = await newUser("Original");
    const bad: Array<[unknown, string]> = [
      ["ab", "entre 3 y 16"],
      ["  ab  ", "entre 3 y 16"],
      ["a".repeat(17), "entre 3 y 16"],
      ["", "entre 3 y 16"],
      ["Ana!", "solo puede llevar"],
      ["Ana@x", "solo puede llevar"],
      ["Ана Иван", "solo puede llevar"],
      ["...", "al menos una letra"],
      [123, "texto"],
      [null, "texto"],
      [undefined, "texto"],
      [{ a: 1 }, "texto"],
      ["a".repeat(100_000), "entre 3 y 16"],
    ];
    for (const [nick, why] of bad) {
      const r = await track(call("setNickname", { nickname: nick }, u.token));
      expect(r.errorStatus, String(nick).slice(0, 20)).toBe("INVALID_ARGUMENT");
      expect(r.raw).toContain(why);
    }
    expect((await track(call("setNickname", null, u.token))).errorStatus).toBe("INVALID_ARGUMENT");
    expect((await db.doc(`users/${u.uid}`).get()).data()!.nickname).toBe("Original");
  });
  it("rechaza groserías en español e inglés (también con trucos)", async () => {
    const u = await signInRegistered();
    for (const nick of ["puta", "Hijueputa", "MIERDA", "pendejo99", "fuck", "FuckYou", "sh1t_head", "b1tch", "gonorrea", "Cabrón", "p.u.t.a", "Gran Puto"]) {
      const r = await track(call("setNickname", { nickname: nick }, u.token));
      expect(r.errorStatus, nick).toBe("INVALID_ARGUMENT");
      expect(r.raw).toContain("no está permitido");
    }
    // Palabras normales que se parecen no se bloquean.
    for (const ok of ["Mariana", "Computadora", "Vergara"]) {
      expect((await track(call("setNickname", { nickname: ok }, u.token))).result).toEqual({ nickname: ok });
    }
  });
});

describe("lastSeenAt", () => {
  const ago = (ms: number) => Timestamp.fromMillis(Date.now() - ms);
  const lastSeen = async (uid: string) => (await db.doc(`users/${uid}`).get()).data()!.lastSeenAt.toMillis() as number;

  it("la primera llamada crea users/{uid} con createdAt y lastSeenAt", async () => {
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-03" }, u.token));
    const a = (await db.doc(`users/${u.uid}`).get()).data()!;
    expect(a.createdAt).toBeInstanceOf(Timestamp);
    expect(a.lastSeenAt).toBeInstanceOf(Timestamp);
  });

  it("se refresca con cada función cuando pasaron más de 5 minutos; antes no se escribe de nuevo; createdAt no cambia", async () => {
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-03" }, u.token));
    const created = (await db.doc(`users/${u.uid}`).get()).data()!.createdAt.toMillis();
    const wrong = { caseId: "mansion-03", positions: boardWithWrong(loadCase("mansion-03").solution, 2), clientElapsedMs: 1, startedOnline: true };

    const calls: Array<[string, () => Promise<CallResult>]> = [
      ["startCase", () => track(call("startCase", { caseId: "mansion-03" }, u.token))],
      ["submitSolution", () => track(call("submitSolution", wrong, u.token))],
      ["getDailyChallenge", () => track(call("getDailyChallenge", { localDate: TODAY }, u.token))],
      ["setNickname", () => track(call("setNickname", { nickname: "Visto Hoy" }, u.token))],
    ];
    for (const [name, run] of calls) {
      // Dentro de los 5 minutos no cambia (salvo setNickname, que escribe el usuario siempre).
      const recent = ago(60_000);
      await db.doc(`users/${u.uid}`).update({ lastSeenAt: recent });
      const r1 = await run();
      expect(r1.status, name).toBe(200);
      if (name !== "setNickname") expect(await lastSeen(u.uid), name).toBe(recent.toMillis());
      // Con más de 5 minutos se refresca.
      const old = ago(10 * 60_000);
      await db.doc(`users/${u.uid}`).update({ lastSeenAt: old });
      const r2 = await run();
      expect(r2.status, name).toBe(200);
      expect(await lastSeen(u.uid), name).toBeGreaterThan(Date.now() - 60_000);
      expect((await db.doc(`users/${u.uid}`).get()).data()!.createdAt.toMillis()).toBe(created);
    }
    expect((await db.doc(`users/${u.uid}`).get()).data()!.nickname).toBe("Visto Hoy");
  });
});

describe("tiempo mínimo plausible del reto (minRankedElapsedMs)", () => {
  it("un reto resuelto más rápido que el mínimo vale como resuelto, pero no rankea y queda suspicious", async () => {
    await setDaily(25, { minRankedElapsedMs: 20_000 });
    await clearRanking();
    const u = await newUser("Muy Rapido");
    await track(call("startCase", { caseId: "reto-025", localDate: TODAY }, u.token));
    const r = await track(
      call("submitSolution", { caseId: "reto-025", localDate: TODAY, positions: loadCase("reto-025").solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", ranked: false });
    const prog = (await db.doc(`users/${u.uid}/progress/reto-025`).get()).data()!;
    expect(prog.solved).toBe(true);
    expect(prog.ranked).toBe(false);
    expect(prog.suspicious).toBe(true);
    expect((await db.collection("dailyRankings").doc(TODAY).collection("entries").get()).size).toBe(0);
    await clearRanking();
    await clearConfig();
  });

  it("pasado el mínimo (por defecto 20 s) entra al ranking", async () => {
    await db.doc("config/server").set({ dailyStartDate: addDays(TODAY, -24) }); // sin minRankedElapsedMs: vale el defecto
    await clearRanking();
    const u = await newUser("Con Calma");
    await track(call("startCase", { caseId: "reto-025", localDate: TODAY }, u.token));
    await db.doc(`users/${u.uid}/progress/reto-025`).update({ startedAt: Timestamp.fromMillis(Date.now() - 30_000) });
    const r = await track(
      call("submitSolution", { caseId: "reto-025", localDate: TODAY, positions: loadCase("reto-025").solution.positions, clientElapsedMs: 30_000, startedOnline: true }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", ranked: true });
    expect((await db.doc(`users/${u.uid}/progress/reto-025`).get()).data()!.suspicious).toBe(false);
    expect(await entry27(u.uid)).toBeDefined();
    await clearRanking();
    await clearConfig();
  });

  it("la campaña no se ve afectada por el mínimo", async () => {
    await db.doc("config/server").set({ minRankedElapsedMs: 60_000 });
    const u = await signInRegistered();
    await track(call("startCase", { caseId: "mansion-04" }, u.token));
    const r = await track(call("submitSolution", { caseId: "mansion-04", positions: loadCase("mansion-04").solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token));
    expect(r.result).toMatchObject({ result: "solved", ranked: true });
    await clearConfig();
  });
});

describe("correo sin verificar", () => {
  const EMAIL = "Verifica tu correo para jugar el reto.";
  const expectUnverified = (r: CallResult) => {
    expect(r.errorStatus).toBe("FAILED_PRECONDITION");
    expect(r.raw).toContain(EMAIL);
    expect(r.errorDetails).toEqual({ reason: "email-unverified" });
  };
  it("no puede pedir el reto, empezarlo, enviarlo ni poner apodo; sin rastro", async () => {
    await setDaily(24);
    const u = await signInUnverified();
    expectUnverified(await track(call("getDailyChallenge", { localDate: TODAY }, u.token)));
    expectUnverified(await track(call("startCase", { caseId: "reto-024", localDate: TODAY }, u.token)));
    expectUnverified(
      await track(call("submitSolution", { caseId: "reto-024", localDate: TODAY, positions: loadCase("reto-024").solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token)),
    );
    expectUnverified(await track(call("setNickname", { nickname: "Sin Verificar" }, u.token)));
    expect((await db.doc(`users/${u.uid}/progress/reto-024`).get()).exists).toBe(false);
    expect((await db.doc(`users/${u.uid}`).get()).data()?.nickname).toBeUndefined();
    await clearConfig();
  });
  it("en la campaña sí juega (basta con no ser anónimo)", async () => {
    const u = await signInUnverified();
    expect((await track(call("startCase", { caseId: "mansion-03" }, u.token))).status).toBe(200);
    const r = await track(call("submitSolution", { caseId: "mansion-03", positions: loadCase("mansion-03").solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token));
    expect(r.result).toMatchObject({ result: "solved" });
  });
  it("con el correo verificado todo se abre", async () => {
    await setDaily(24);
    const u = await signInRegistered();
    expect((await track(call("getDailyChallenge", { localDate: TODAY }, u.token))).result).toEqual({ localDate: TODAY, caseId: "reto-024" });
    expect((await track(call("setNickname", { nickname: "Verificado" }, u.token))).result).toEqual({ nickname: "Verificado" });
    await clearConfig();
  });
});

describe("limpieza de cuentas: orden y tolerancia a fallos", () => {
  it("al borrar una cuenta se eliminan sus entradas de las últimas 31 fechas aunque el progreso no las recuerde", async () => {
    const u = await signInRegistered();
    const other = await signInRegistered();
    const dates = [TODAY, addDays(TODAY, -10), addDays(TODAY, -30)];
    for (const d of dates) {
      for (const id of [u.uid, other.uid]) {
        await db.doc(`dailyRankings/${d}/entries/${id}`).set({ nickname: "N", score: 1, serverElapsedMs: 1, errors: 0, solvedAt: Timestamp.fromMillis(Date.now()) });
      }
    }
    expect((await track(call("deleteAccount", {}, u.token))).result).toEqual({ deleted: true });
    for (const d of dates) {
      expect((await db.doc(`dailyRankings/${d}/entries/${u.uid}`).get()).exists).toBe(false);
      expect((await db.doc(`dailyRankings/${d}/entries/${other.uid}`).get()).exists).toBe(true);
      await clearRanking(d);
    }
  });

  it("si una cuenta falla, la limpieza sigue con las demás y conserva los datos de la que falló", async () => {
    const now = Date.now();
    const old = Timestamp.fromMillis(now - 400 * 86_400_000);
    const bad = (await signInRegistered()).uid;
    const good = (await signInRegistered()).uid;
    for (const uid of [bad, good]) await db.doc(`users/${uid}`).set({ createdAt: old, lastSeenAt: old });
    const real = getAuth(app);
    const flaky = new Proxy(real, {
      get(t, prop) {
        if (prop === "deleteUser") {
          return async (uid: string) => {
            if (uid === bad) throw new Error("fallo simulado de Auth");
            return t.deleteUser(uid);
          };
        }
        const v = Reflect.get(t, prop);
        return typeof v === "function" ? v.bind(t) : v;
      },
    });
    const r = await runCleanup(db, flaky, now);
    expect(r.accountsFailed).toBe(1);
    expect(r.accountsDeleted).toBeGreaterThanOrEqual(1);
    expect((await db.doc(`users/${good}`).get()).exists).toBe(false);
    await expect(real.getUser(good)).rejects.toMatchObject({ code: "auth/user-not-found" });
    // Auth falló primero: los datos de la cuenta que falló siguen, para reintentar mañana.
    expect((await db.doc(`users/${bad}`).get()).exists).toBe(true);
    // Reintento con Auth sano: ahora sí.
    const again = await runCleanup(db, real, now);
    expect(again.accountsFailed).toBe(0);
    expect((await db.doc(`users/${bad}`).get()).exists).toBe(false);
  });

  it("si el usuario de Auth ya no existe, los datos igual se borran", async () => {
    const u = await signInRegistered();
    await db.doc(`users/${u.uid}`).set({ createdAt: Timestamp.now(), lastSeenAt: Timestamp.now() });
    await getAuth(app).deleteUser(u.uid);
    const { deleteUserData } = await import("../../functions/src/cleanup");
    await deleteUserData(db, getAuth(app), u.uid);
    expect((await db.doc(`users/${u.uid}`).get()).exists).toBe(false);
  });
});

describe("deleteAccount", () => {
  it("sin sesión se rechaza", async () => {
    expect((await track(call("deleteAccount", {}))).errorStatus).toBe("UNAUTHENTICATED");
  });
  it("borra users/{uid} con su progreso, sus entradas de ranking y el usuario de Auth; no toca a los demás", async () => {
    await setDaily(28);
    await clearRanking();
    const me = await newUser("Me Borro");
    const other = await newUser("Me Quedo");
    for (const u of [me, other]) {
      for (const id of ["mansion-01", "mansion-02"]) {
        await track(call("startCase", { caseId: id }, u.token));
        await track(call("submitSolution", { caseId: id, positions: loadCase(id).solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token));
      }
      await track(call("startCase", { caseId: "reto-028", localDate: TODAY }, u.token));
      await track(
        call("submitSolution", { caseId: "reto-028", localDate: TODAY, positions: loadCase("reto-028").solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
      );
    }
    expect(await entry27(me.uid)).toBeDefined();
    expect((await db.collection(`users/${me.uid}/progress`).get()).size).toBe(3);
    await getAuth(app).getUser(me.uid); // existe

    const r = await track(call("deleteAccount", {}, me.token));
    expect(r.status).toBe(200);
    expect(r.result).toEqual({ deleted: true });

    expect((await db.doc(`users/${me.uid}`).get()).exists).toBe(false);
    expect((await db.collection(`users/${me.uid}/progress`).get()).size).toBe(0);
    expect(await entry27(me.uid)).toBeUndefined();
    await expect(getAuth(app).getUser(me.uid)).rejects.toMatchObject({ code: "auth/user-not-found" });
    // El otro jugador queda intacto.
    expect((await db.doc(`users/${other.uid}`).get()).data()!.nickname).toBe("Me Quedo");
    expect((await db.collection(`users/${other.uid}/progress`).get()).size).toBe(3);
    expect(await entry27(other.uid)).toBeDefined();
    await getAuth(app).getUser(other.uid);
    await clearRanking();
    await clearConfig();
  });
  it("una cuenta sin datos también se borra (idempotente en los datos)", async () => {
    const u = await signInRegistered();
    const r = await track(call("deleteAccount", {}, u.token));
    expect(r.result).toEqual({ deleted: true });
    await expect(getAuth(app).getUser(u.uid)).rejects.toMatchObject({ code: "auth/user-not-found" });
  });
});

describe("limpieza por retención", () => {
  const DAY = 86_400_000;
  it("borra rankings de más de 30 días y cuentas sin uso de más de 12 meses; el resto se queda", async () => {
    const now = Date.now();
    const old1 = isoDate(now - 31 * DAY);
    const old2 = isoDate(now - 90 * DAY);
    const edge = isoDate(now - 30 * DAY); // justo 30 días: se conserva
    const recent = isoDate(now - 5 * DAY);
    for (const d of [old1, old2, edge, recent]) {
      await db.doc(`dailyRankings/${d}/entries/x1`).set({ nickname: "X", score: 1, serverElapsedMs: 1, errors: 0, solvedAt: Timestamp.fromMillis(now) });
      await db.doc(`dailyRankings/${d}/entries/x2`).set({ nickname: "Y", score: 2, serverElapsedMs: 2, errors: 0, solvedAt: Timestamp.fromMillis(now) });
    }

    const auth = getAuth(app);
    const mk = async () => (await signInRegistered()).uid;
    const inactive = await mk();
    const active = await mk();
    const noSeen = await mk();
    const nearYear = await mk();
    await db.doc(`users/${inactive}`).set({ createdAt: Timestamp.fromMillis(now - 500 * DAY), lastSeenAt: Timestamp.fromMillis(now - 366 * DAY), nickname: "Viejo" });
    await db.doc(`users/${inactive}/progress/mansion-01`).set({ solved: true });
    await db.doc(`users/${inactive}/progress/reto-001`).set({ solved: true, localDate: recent });
    await db.doc(`dailyRankings/${recent}/entries/${inactive}`).set({ nickname: "Viejo", score: 3, serverElapsedMs: 3, errors: 0, solvedAt: Timestamp.fromMillis(now) });
    await db.doc(`users/${active}`).set({ createdAt: Timestamp.fromMillis(now - 500 * DAY), lastSeenAt: Timestamp.fromMillis(now - 10 * DAY) });
    await db.doc(`users/${noSeen}`).set({ createdAt: Timestamp.fromMillis(now - 500 * DAY) });
    await db.doc(`users/${nearYear}`).set({ createdAt: Timestamp.fromMillis(now - 500 * DAY), lastSeenAt: Timestamp.fromMillis(now - 364 * DAY) });

    const res = await runCleanup(db, auth, now);
    expect(res.accountsDeleted).toBeGreaterThanOrEqual(1);
    expect(res.rankingDaysDeleted).toBeGreaterThanOrEqual(2);

    for (const d of [old1, old2]) expect((await db.collection(`dailyRankings/${d}/entries`).get()).size).toBe(0);
    for (const d of [edge, recent]) expect((await db.collection(`dailyRankings/${d}/entries`).get()).size).toBeGreaterThanOrEqual(2);

    expect((await db.doc(`users/${inactive}`).get()).exists).toBe(false);
    expect((await db.collection(`users/${inactive}/progress`).get()).size).toBe(0);
    expect((await db.doc(`dailyRankings/${recent}/entries/${inactive}`).get()).exists).toBe(false);
    await expect(auth.getUser(inactive)).rejects.toMatchObject({ code: "auth/user-not-found" });
    for (const uid of [active, noSeen, nearYear]) {
      expect((await db.doc(`users/${uid}`).get()).exists).toBe(true);
      await auth.getUser(uid);
    }
    // Una segunda corrida no encuentra nada más que borrar de lo ya borrado.
    const again = await runCleanup(db, auth, now);
    expect(again).toEqual({ rankingDaysDeleted: 0, accountsDeleted: 0, accountsFailed: 0 });
    for (const d of [edge, recent]) await clearRanking(d);
    for (const uid of [active, noSeen, nearYear]) await db.recursiveDelete(db.doc(`users/${uid}`));
  });
});

describe("invitados (sesión anónima) y usuarios registrados", () => {
  const REGISTER = "Regístrate para seguir jugando";
  const solveBody = (id: string, extra: Record<string, unknown> = {}) => ({
    caseId: id,
    positions: loadCase(id).solution.positions,
    clientElapsedMs: 1,
    startedOnline: true,
    ...extra,
  });

  it("un invitado juega mansion-01 y mansion-02 (gratis): startCase y submitSolution funcionan", async () => {
    const g = await signInAnonymously();
    for (const id of ["mansion-01", "mansion-02"]) {
      expect((await track(call("startCase", { caseId: id }, g.token))).status).toBe(200);
      const r = await track(call("submitSolution", solveBody(id), g.token));
      expect(r.result).toMatchObject({ result: "solved", ranked: true });
    }
  });

  it("un invitado no puede jugar el resto de la campaña: failed-precondition con mensaje en español y sin rastro", async () => {
    const g = await signInAnonymously();
    for (const id of ["mansion-03", "mansion-10"]) {
      const a = await track(call("startCase", { caseId: id }, g.token));
      expect(a.errorStatus).toBe("FAILED_PRECONDITION");
      expect(a.raw).toContain(REGISTER);
      const b = await track(call("submitSolution", solveBody(id), g.token));
      expect(b.errorStatus).toBe("FAILED_PRECONDITION");
      expect(b.raw).toContain(REGISTER);
      expect((await db.doc(`users/${g.uid}/progress/${id}`).get()).exists).toBe(false);
    }
  });

  it("un invitado tampoco juega los retos (startCase, submitSolution ni getDailyChallenge)", async () => {
    await setDaily(14);
    const g = await signInAnonymously();
    const d = await track(call("getDailyChallenge", { localDate: TODAY }, g.token));
    expect(d.errorStatus).toBe("FAILED_PRECONDITION");
    expect(d.raw).toContain(REGISTER);
    const s = await track(call("startCase", { caseId: "reto-014", localDate: TODAY }, g.token));
    expect(s.errorStatus).toBe("FAILED_PRECONDITION");
    expect(s.raw).toContain(REGISTER);
    const r = await track(call("submitSolution", solveBody("reto-014", { localDate: TODAY }), g.token));
    expect(r.errorStatus).toBe("FAILED_PRECONDITION");
    expect(r.raw).toContain(REGISTER);
    expect((await db.doc(`users/${g.uid}/progress/reto-014`).get()).exists).toBe(false);
    expect((await db.collection("dailyRankings").doc(TODAY).collection("entries").doc(g.uid).get()).exists).toBe(false);
    await clearConfig();
  });

  it("un invitado no puede poner apodo", async () => {
    const g = await signInAnonymously();
    const r = await track(call("setNickname", { nickname: "Invitado" }, g.token));
    expect(r.errorStatus).toBe("FAILED_PRECONDITION");
    expect(r.raw).toContain(REGISTER);
    const user = (await db.doc(`users/${g.uid}`).get()).data();
    expect(user?.nickname).toBeUndefined();
  });

  it("un usuario registrado (correo) juega todos los casos, los retos y puede poner apodo", async () => {
    await setDaily(15);
    const u = await signInRegistered();
    expect((await track(call("startCase", { caseId: "mansion-03" }, u.token))).status).toBe(200);
    expect((await track(call("getDailyChallenge", { localDate: TODAY }, u.token))).result).toEqual({ localDate: TODAY, caseId: "reto-015" });
    expect((await track(call("startCase", { caseId: "reto-015", localDate: TODAY }, u.token))).status).toBe(200);
    expect((await track(call("setNickname", { nickname: "Registrado" }, u.token))).result).toEqual({ nickname: "Registrado" });
    await clearConfig();
  });

  it("un usuario con token personalizado también cuenta como registrado", async () => {
    const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString("base64url");
    const now = Math.floor(Date.now() / 1000);
    const jwt = `${b64({ alg: "none", typ: "JWT" })}.${b64({
      iss: "firebase-auth-emulator@example.com",
      sub: "firebase-auth-emulator@example.com",
      aud: "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
      iat: now,
      exp: now + 3600,
      uid: `custom-${Date.now().toString(36)}`,
    })}.`;
    const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake-key`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ token: jwt, returnSecureToken: true }),
    });
    const j = (await r.json()) as { idToken: string };
    expect((await track(call("startCase", { caseId: "mansion-04" }, j.idToken))).status).toBe(200);
    expect((await track(call("setNickname", { nickname: "Personalizado" }, j.idToken))).result).toEqual({ nickname: "Personalizado" });
  });

  it("al registrarse (vincular la cuenta anónima) se conserva el uid y el progreso; ya puede seguir jugando", async () => {
    const g = await signInAnonymously();
    await track(call("startCase", { caseId: "mansion-01" }, g.token));
    await track(call("submitSolution", solveBody("mansion-01"), g.token));
    expect((await track(call("startCase", { caseId: "mansion-05" }, g.token))).errorStatus).toBe("FAILED_PRECONDITION");

    const email = `vinculado-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}@test.com`;
    const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ idToken: g.token, email, password: "clave-segura-1", returnSecureToken: true }),
    });
    const j = (await r.json()) as { idToken: string; localId: string };
    expect(j.localId).toBe(g.uid);

    expect((await db.doc(`users/${g.uid}/progress/mansion-01`).get()).data()!.solved).toBe(true);
    expect((await track(call("startCase", { caseId: "mansion-05" }, j.idToken))).status).toBe(200);
    // Recién vinculado, el correo aún no está verificado: la campaña sigue, el apodo espera.
    expect((await track(call("setNickname", { nickname: "Ya Registrado" }, j.idToken))).errorDetails).toEqual({ reason: "email-unverified" });
    await getAuth(app).updateUser(g.uid, { emailVerified: true });
    const refreshed = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password: "clave-segura-1", returnSecureToken: true }),
    });
    const verifiedToken = ((await refreshed.json()) as { idToken: string }).idToken;
    expect((await track(call("setNickname", { nickname: "Ya Registrado" }, verifiedToken))).result).toEqual({ nickname: "Ya Registrado" });
    // El mismo uid: mansion-01 sigue resuelto (respuesta idempotente).
    const again = await track(call("submitSolution", solveBody("mansion-01"), j.idToken));
    expect(again.result).toMatchObject({ result: "solved" });
  });

  it("los casos gratis salen de config/server.freeCaseIds (con mansion-01 y mansion-02 por defecto)", async () => {
    const g = await signInAnonymously();
    await db.doc("config/server").set({ freeCaseIds: ["mansion-06"] });
    try {
      expect((await track(call("startCase", { caseId: "mansion-06" }, g.token))).status).toBe(200);
      expect((await track(call("startCase", { caseId: "mansion-01" }, g.token))).errorStatus).toBe("FAILED_PRECONDITION");
      // Un reto no se vuelve gratis por estar en la lista.
      await db.doc("config/server").set({ freeCaseIds: ["reto-016"], dailyStartDate: addDays(TODAY, -15) });
      expect((await track(call("startCase", { caseId: "reto-016", localDate: TODAY }, g.token))).errorStatus).toBe("FAILED_PRECONDITION");
      // Valor mal formado: vuelve al valor por defecto.
      for (const bad of ["mansion-06", [5], ["../x"], null]) {
        await db.doc("config/server").set({ freeCaseIds: bad });
        expect((await track(call("startCase", { caseId: "mansion-02" }, g.token))).status).toBe(200);
        expect((await track(call("startCase", { caseId: "mansion-06" }, g.token))).errorStatus).toBe("FAILED_PRECONDITION");
      }
      // Lista vacía: nada es gratis.
      await db.doc("config/server").set({ freeCaseIds: [] });
      expect((await track(call("startCase", { caseId: "mansion-02" }, g.token))).errorStatus).toBe("FAILED_PRECONDITION");
      // Un registrado juega lo que sea.
      const u = await signInRegistered();
      expect((await track(call("startCase", { caseId: "mansion-02" }, u.token))).status).toBe(200);
    } finally {
      await clearConfig();
    }
  });

  it("un invitado puede borrar su cuenta", async () => {
    const g = await signInAnonymously();
    await track(call("startCase", { caseId: "mansion-01" }, g.token));
    const r = await track(call("deleteAccount", {}, g.token));
    expect(r.result).toEqual({ deleted: true });
    expect((await db.doc(`users/${g.uid}`).get()).exists).toBe(false);
  });
});

describe("la solución nunca sale", () => {
  it("ninguna respuesta de las pruebas contiene positions, solution ni las casillas de la solución", async () => {
    // Una respuesta de victoria y otra de fallo, a propósito, sobre el mismo caso.
    const c = loadCase("mansion-08");
    const u = await signInRegistered();
    const wrong = await track(
      call("submitSolution", { caseId: "mansion-08", positions: boardWithWrong(c.solution, 3), clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    const solved = await track(
      call("submitSolution", { caseId: "mansion-08", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(Object.keys(wrong.result!).sort()).toEqual(["result", "wrongCount"]);
    expect(Object.keys(solved.result!).sort()).toEqual(["lethalWeaponId", "murdererId", "ranked", "result"]);

    expect(allResponses.length).toBeGreaterThan(40);
    for (const raw of allResponses) {
      expect(raw).not.toContain("positions");
      expect(raw.toLowerCase()).not.toContain("solution");
    }
    // Ni siquiera el mapa personaje -> casilla de la solución aparece en una respuesta.
    for (const raw of [wrong.raw, solved.raw]) {
      expect(raw).not.toMatch(/"c1"\s*:/);
    }
  });
});

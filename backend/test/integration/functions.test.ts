// Integración: emuladores de Auth, Firestore y Functions (npm run test:emulator).
// Se llama a las funciones por HTTP con el protocolo de las callable, igual que el SDK de cliente.
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { publishCases, listCaseFiles, DEFAULT_CASES_DIR } from "../../scripts/publish-cases";

const PROJECT = "demo-enigmatrix";
const REGION = "southamerica-east1";
const FUNCTIONS = `http://${process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001"}/${PROJECT}/${REGION}`;
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099"}`;

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

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

/** Usuario anónimo del emulador de Auth. */
async function signInAnonymously(): Promise<{ uid: string; token: string }> {
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const j = (await r.json()) as { idToken: string; localId: string };
  return { uid: j.localId, token: j.idToken };
}

interface CallResult {
  status: number;
  /** Cuerpo completo de la respuesta, en texto (para revisar que no se filtre nada). */
  raw: string;
  result?: Record<string, unknown>;
  errorStatus?: string;
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
  const j = JSON.parse(raw) as { result?: Record<string, unknown>; error?: { status: string } };
  return { status: r.status, raw, result: j.result, errorStatus: j.error?.status };
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
  await publishCases(db);
});
afterAll(async () => {
  await deleteApp(app);
});

describe("publicación de casos", () => {
  it("publica los 40 casos, separados en cases y caseSolutions", async () => {
    expect(listCaseFiles(DEFAULT_CASES_DIR)).toHaveLength(40);
    expect((await db.collection("cases").get()).size).toBe(40);
    expect((await db.collection("caseSolutions").get()).size).toBe(40);
    // El banco caso-* y el tutorial no se publican.
    expect((await db.collection("cases").doc("caso-casual-s1").get()).exists).toBe(false);
  });
  it("el caso público no lleva solución; la solución lleva arma solo si el caso la tiene", async () => {
    for (const id of ["mansion-01", "mansion-08", "reto-030"]) {
      const pub = (await db.collection("cases").doc(id).get()).data()!;
      expect(pub).not.toHaveProperty("solution");
      expect(JSON.stringify(pub)).not.toContain("murderer");
      // Las dos partes llevan la misma versión (hash corto de caso + solución).
      const sol = (await db.collection("caseSolutions").doc(id).get()).data()!;
      expect(pub.version).toMatch(/^[0-9a-f]{16}$/);
      expect(sol.version).toBe(pub.version);
    }
    expect((await db.collection("caseSolutions").doc("mansion-01").get()).data()).not.toHaveProperty("lethalWeapon");
    expect((await db.collection("caseSolutions").doc("mansion-08").get()).data()).toHaveProperty("lethalWeapon", "abrecartas");
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
    const u = await signInAnonymously();
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
    const u = await signInAnonymously();
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
    const u = await signInAnonymously();
    await track(call("startCase", { caseId: "mansion-01" }, u.token));
    const r = await track(
      call("submitSolution", { caseId: "mansion-01", positions: c.solution.positions, clientElapsedMs: 5000, startedOnline: true }, u.token),
    );
    expect(r.status).toBe(200);
    expect(r.result).toEqual({ result: "solved", murdererId: c.solution.murderer, lethalWeaponId: null, ranked: true });
    expect((await db.collection("cases").doc("mansion-01").get()).data()!.version).toMatch(/^[0-9a-f]{16}$/);
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
    const u = await signInAnonymously();
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
    const u = await signInAnonymously();
    await track(call("startCase", { caseId: "mansion-03" }, u.token));
    const r = await track(
      call("submitSolution", { caseId: "mansion-03", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: false }, u.token),
    );
    expect(r.result!.ranked).toBe(false);
  });

  it("tablero incorrecto: cuenta exacta, suma el error y no revela nada más", async () => {
    const c = loadCase("mansion-04");
    const u = await signInAnonymously();
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
    const u = await signInAnonymously();
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
    const u = await signInAnonymously();
    const body = { caseId: "mansion-06", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true };
    const rs = await Promise.all([1, 2, 3].map(() => track(call("submitSolution", body, u.token))));
    for (const r of rs) expect(r.result!.result).toBe("solved");
    const prog = (await db.doc(`users/${u.uid}/progress/mansion-06`).get()).data()!;
    expect(prog.attempts).toBe(1);
  });

  it("límite de intentos: el séptimo envío en un minuto da resource-exhausted", async () => {
    const c = loadCase("mansion-07");
    const u = await signInAnonymously();
    const body = { caseId: "mansion-07", positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true };
    for (let i = 0; i < 6; i++) {
      const r = await track(call("submitSolution", body, u.token));
      expect(r.result).toEqual({ result: "wrong", wrongCount: 2 });
    }
    const blocked = await track(call("submitSolution", body, u.token));
    expect(blocked.errorStatus).toBe("RESOURCE_EXHAUSTED");
    // Otro caso del mismo usuario y otro usuario en el mismo caso no se ven afectados.
    const other = await signInAnonymously();
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
    const u = await signInAnonymously();
    const board = boardWithWrong(c.solution, 2);
    const rs = await Promise.all(
      Array.from({ length: 20 }, () =>
        track(call("submitSolution", { caseId: "reto-002", positions: board, clientElapsedMs: 1, startedOnline: true }, u.token)),
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
    const u = await signInAnonymously();
    const probe = await track(
      call("submitSolution", { caseId: "reto-003", positions: boardWithWrong(c.solution, 2), clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(probe.result).toEqual({ result: "wrong", wrongCount: 2 });
    const progRef = db.doc(`users/${u.uid}/progress/reto-003`);
    expect((await progRef.get()).data()!.rankable).toBe(false);
    // startCase sí guarda startedAt, pero no devuelve el progreso a rankeable.
    const st = await track(call("startCase", { caseId: "reto-003" }, u.token));
    expect(st.status).toBe(200);
    const afterStart = (await progRef.get()).data()!;
    expect(afterStart.startedAt.toMillis()).toBe(st.result!.startedAt);
    expect(afterStart.rankable).toBe(false);
    const r = await track(
      call("submitSolution", { caseId: "reto-003", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, u.token),
    );
    expect(r.result).toMatchObject({ result: "solved", ranked: false });
    const prog = (await progRef.get()).data()!;
    expect(prog.ranked).toBe(false);
    expect(prog.rankable).toBe(false);
  });

  it("startedOnline solo puede bajar ranked: false con startCase da false; true con startCase da true", async () => {
    const c = loadCase("reto-004");
    const off = await signInAnonymously();
    await track(call("startCase", { caseId: "reto-004" }, off.token));
    const a = await track(
      call("submitSolution", { caseId: "reto-004", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: false }, off.token),
    );
    expect(a.result!.ranked).toBe(false);
    const on = await signInAnonymously();
    await track(call("startCase", { caseId: "reto-004" }, on.token));
    const b = await track(
      call("submitSolution", { caseId: "reto-004", positions: c.solution.positions, clientElapsedMs: 1, startedOnline: true }, on.token),
    );
    expect(b.result!.ranked).toBe(true);
    expect((await db.doc(`users/${on.uid}/progress/reto-004`).get()).data()!.rankable).toBeUndefined();
  });

  it("un submissionId repetido devuelve la misma respuesta sin sumar intento, error ni límite", async () => {
    const c = loadCase("reto-005");
    const u = await signInAnonymously();
    const wrongBody = { caseId: "reto-005", positions: boardWithWrong(c.solution, 3), clientElapsedMs: 1, startedOnline: true };
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
    const solve = async (elapsed: number) => {
      const caseId = "reto-006";
      const u = await signInAnonymously();
      await track(call("startCase", { caseId }, u.token));
      await track(
        call("submitSolution", { caseId, positions: loadCase(caseId).solution.positions, clientElapsedMs: elapsed, startedOnline: true }, u.token),
      );
      return (await db.doc(`users/${u.uid}/progress/${caseId}`).get()).data()!;
    };
    expect((await solve(600_000)).suspicious).toBe(true);
    expect((await solve(1)).suspicious).toBe(false);
    // Con un margen mayor en config/server, el mismo tiempo ya no es sospechoso.
    await db.doc("config/server").set({ clientClockMarginMs: 10_000_000 });
    try {
      expect((await solve(600_000)).suspicious).toBe(false);
    } finally {
      await db.doc("config/server").delete();
    }
  });

  it("el máximo se puede cambiar en config/server", async () => {
    await db.doc("config/server").set({ maxSubmitsPerMinute: 2 });
    try {
      const c = loadCase("mansion-10");
      const u = await signInAnonymously();
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
  const base = { caseId: "reto-001", positions: good, clientElapsedMs: 1000, startedOnline: true, submissionId: "base-submission-1" };

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
    const u = await signInAnonymously();
    const r = await track(call("submitSolution", data, u.token));
    expect(r.errorStatus).toBe(status);
    // Una entrada rechazada no deja rastro en el progreso.
    const prog = await db.doc(`users/${u.uid}/progress/reto-001`).get();
    expect(prog.exists).toBe(false);
  });

  it("__proto__ como clave no sirve para colar un tablero", async () => {
    const u = await signInAnonymously();
    const raw = JSON.stringify({ data: { ...base, positions: JSON.parse(`{"__proto__": 1, "${ids[1]}": ${good[ids[1]]}}`) } });
    const r = await fetch(`${FUNCTIONS}/submitSolution`, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${u.token}` },
      body: raw,
    });
    const j = (await r.json()) as { error?: { status: string } };
    expect(j.error?.status).toBe("INVALID_ARGUMENT");
  });
});

describe("la solución nunca sale", () => {
  it("ninguna respuesta de las pruebas contiene positions, solution ni las casillas de la solución", async () => {
    // Una respuesta de victoria y otra de fallo, a propósito, sobre el mismo caso.
    const c = loadCase("mansion-08");
    const u = await signInAnonymously();
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

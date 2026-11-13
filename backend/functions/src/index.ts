// Cloud Functions de Enigmatrix, etapa 5A.3.
// El servidor es la autoridad: las soluciones viven en functions/data/solutions.json
// (generado al compilar, fuera de git) y NUNCA salen en una respuesta.
import path from "node:path";
import { initializeApp } from "firebase-admin/app";
import {
  getFirestore,
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
} from "firebase-admin/firestore";
import { defineBoolean } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { resolveEnforceAppCheck } from "./appcheck";
import { deleteUserData, rankingCutoffDate, runCleanup } from "./cleanup";
import {
  assertDailyGate,
  assertTodaysReto,
  dailyCaseId,
  isRetoId,
  parseLocalDate,
  parseOptionalLocalDate,
  requireLocalDateForReto,
  resolveDailyStartDate,
} from "./daily";
import { parseNickname } from "./nickname";
import {
  findSolution,
  loadSolutionsFile,
  shapeOf,
  type SolutionEntry,
  type SolutionsMap,
} from "./solutions";
import {
  InputError,
  REGISTER_MESSAGE,
  applyRateLimit,
  assertCanPlay,
  compareSolution,
  computeRanked,
  computeScore,
  findSubmission,
  isSuspicious,
  parseCaseId,
  parseSubmitInput,
  rememberSubmission,
  resolveClientClockMarginMs,
  isRegisteredProvider,
  resolveErrorPenaltyMs,
  resolveFreeCaseIds,
  resolveMaxSubmitsPerMinute,
  resolveMaxWrongPerCase,
} from "./validation";

initializeApp();

setGlobalOptions({ region: "southamerica-east1", maxInstances: 20 });

// El parámetro solo se respeta en el emulador (se apaga con backend/functions/.env.local).
// Fuera del emulador App Check queda forzado a true: no hay forma de apagarlo en producción.
const ENFORCE_APP_CHECK_PARAM = defineBoolean("ENFORCE_APP_CHECK", { default: true });
const ENFORCE_APP_CHECK = resolveEnforceAppCheck(process.env, ENFORCE_APP_CHECK_PARAM);

const db = (): Firestore => getFirestore();

// firebase-admin/auth tarda en cargar y solo hace falta al borrar cuentas: se carga bajo demanda.
const authService = async () => (await import("firebase-admin/auth")).getAuth();

function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Hace falta iniciar sesión.");
  return uid;
}

/** Convierte los errores de entrada en HttpsError; deja pasar los HttpsError. */
function toHttpsError(e: unknown): HttpsError {
  if (e instanceof HttpsError) return e;
  if (e instanceof InputError) return new HttpsError(e.code, e.message);
  // Muchas transacciones a la vez sobre el mismo documento (envíos en ráfaga
  // del mismo jugador): Firestore las aborta tras sus reintentos. No es un
  // fallo interno; el cliente reintenta con el mismo submissionId y no se
  // cuenta dos veces (11-11-2026).
  const code = (e as { code?: unknown } | null)?.code;
  if (code === 10 || code === "aborted" || code === "ABORTED") {
    console.warn("Transacción abortada por contención", e);
    return new HttpsError("aborted", "Hay muchos envíos a la vez; intenta de nuevo.");
  }
  console.error("Error inesperado", e);
  return new HttpsError("internal", "Error interno.");
}

// Soluciones: se leen una vez del JSON generado por scripts/build-solutions.ts.
let solutionsCache: SolutionsMap | null = null;
function solutions(): SolutionsMap {
  if (!solutionsCache) {
    try {
      solutionsCache = loadSolutionsFile(path.join(__dirname, "..", "data", "solutions.json"));
    } catch (e) {
      console.error("No se pudo leer solutions.json", e);
      throw new HttpsError("internal", "El servidor no tiene los casos cargados.");
    }
  }
  return solutionsCache;
}

function loadSolution(caseId: string): SolutionEntry {
  const sol = findSolution(solutions(), caseId);
  if (!sol) throw new HttpsError("not-found", "El caso no existe.");
  return sol;
}

/** Proveedor de inicio de sesión del token ("anonymous" para invitados). */
const signInProvider = (request: CallableRequest): unknown => request.auth?.token?.firebase?.sign_in_provider;

/** Exige usuario registrado (no invitado). */
function requireRegistered(request: CallableRequest): void {
  if (!isRegisteredProvider(signInProvider(request))) {
    throw new HttpsError("failed-precondition", REGISTER_MESSAGE);
  }
}

const isDoc = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null && !Array.isArray(v);

/** `lastSeenAt` se refresca como mucho cada 5 minutos: así no se escribe el usuario en cada llamada. */
const LAST_SEEN_THROTTLE_MS = 5 * 60 * 1000;

/**
 * Marca la última vez que el usuario usó el servidor (crea users/{uid} si no existía) y devuelve sus datos.
 * Va fuera de las transacciones: así no suma bloqueos cuando el mismo jugador envía varias veces a la vez.
 */
async function touchUser(userRef: DocumentReference): Promise<DocumentData | undefined> {
  const snap = await userRef.get();
  const data = snap.data();
  const nowMs = Date.now();
  const last = data?.lastSeenAt instanceof Timestamp ? data.lastSeenAt.toMillis() : 0;
  if (!snap.exists) {
    const now = Timestamp.fromMillis(nowMs);
    await userRef.set({ createdAt: now, lastSeenAt: now }, { merge: true });
  } else if (nowMs - last >= LAST_SEEN_THROTTLE_MS) {
    await userRef.update({ lastSeenAt: Timestamp.fromMillis(nowMs) });
  }
  return data;
}

export const getDailyChallenge = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      requireRegistered(request); // los retos son solo para usuarios registrados
      const data = isDoc(request.data) ? request.data : {};
      const localDate = parseLocalDate(data.localDate);
      assertDailyGate(localDate, Date.now());

      const userRef = db().collection("users").doc(uid);
      const cfgRef = db().collection("config").doc("server");
      const [, cfg] = await Promise.all([touchUser(userRef), cfgRef.get()]);
      const caseId = dailyCaseId(localDate, resolveDailyStartDate(cfg.data()));
      return { localDate, caseId };
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

export const startCase = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      const data = isDoc(request.data) ? request.data : {};
      const caseId = parseCaseId(data.caseId);
      loadSolution(caseId);
      const isReto = isRetoId(caseId);
      const localDate = requireLocalDateForReto(caseId, parseOptionalLocalDate(data.localDate));

      const userRef = db().collection("users").doc(uid);
      const progRef = userRef.collection("progress").doc(caseId);
      const cfgRef = db().collection("config").doc("server");
      await touchUser(userRef);
      const startedAt = await db().runTransaction(async (tx) => {
        const [prog, cfg] = await Promise.all([tx.get(progRef), tx.get(cfgRef)]);
        const nowMs = Date.now();
        assertCanPlay(signInProvider(request), caseId, isReto, resolveFreeCaseIds(cfg.data()));
        if (isReto) assertTodaysReto(caseId, localDate!, resolveDailyStartDate(cfg.data()), nowMs);
        const now = Timestamp.fromMillis(nowMs);

        // Un reto vuelve cada 30 días: el progreso de otra fecha se reinicia.
        const stale = isReto && prog.exists && prog.data()?.localDate !== localDate;
        const existing = prog.exists && !stale ? (prog.data()?.startedAt as Timestamp | null | undefined) : undefined;
        if (existing) return existing; // ya empezado: no se cambia (idempotente)

        if (prog.exists && !stale) tx.update(progRef, { startedAt: now });
        else {
          tx.set(progRef, {
            startedAt: now,
            solved: false,
            attempts: 0,
            errors: 0,
            recentSubmits: [],
            ...(isReto ? { localDate } : {}),
          });
        }
        return now;
      });
      return { startedAt: startedAt.toMillis() };
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

export const submitSolution = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      const data = isDoc(request.data) ? request.data : {};

      // 1. Validación de la entrada (H-45).
      const caseId = parseCaseId(data.caseId);
      const sol = loadSolution(caseId);
      const input = parseSubmitInput(request.data, shapeOf(sol));
      const isReto = isRetoId(caseId);
      const localDate = requireLocalDateForReto(caseId, parseOptionalLocalDate(data.localDate));

      const firestore = db();
      const userRef = firestore.collection("users").doc(uid);
      const progRef = userRef.collection("progress").doc(caseId);
      const cfgRef = firestore.collection("config").doc("server");
      const userData = await touchUser(userRef);

      // Todo en una transacción: un reintento o dos envíos a la vez no duplican efectos.
      return await firestore.runTransaction(async (tx) => {
        const [prog, cfg] = await Promise.all([tx.get(progRef), tx.get(cfgRef)]);
        const cfgData = cfg.data();
        const nowMs = Date.now();
        const now = Timestamp.fromMillis(nowMs);

        // Invitados: solo los casos gratis. El resto pide registro.
        assertCanPlay(signInProvider(request), caseId, isReto, resolveFreeCaseIds(cfgData));

        // Puerta del reto diario: solo se valida el reto de hoy.
        if (isReto) assertTodaysReto(caseId, localDate!, resolveDailyStartDate(cfgData), nowMs);

        // Un reto vuelve cada 30 días: el progreso de otra fecha cuenta como vacío y se reemplaza entero.
        const stale = isReto && prog.exists && prog.data()?.localDate !== localDate;
        const p: DocumentData = stale ? {} : (prog.data() ?? {});
        const mergeOpts = stale ? undefined : { merge: true };
        const put = (data: DocumentData) =>
          mergeOpts ? tx.set(progRef, data, mergeOpts) : tx.set(progRef, data);
        const retoFields = isReto ? { localDate } : {};

        // 0. Reintento del mismo envío: se devuelve la misma respuesta, sin tocar nada
        //    (ni intento, ni error, ni límite).
        const seen = findSubmission(p.lastSubmissions, input.submissionId);
        if (seen) {
          return seen.response;
        }

        // 4. Caso ya resuelto: mismos datos, sin cambios.
        if (p.solved === true) {
          return solvedResponse(sol, p.ranked === true, isReto ? retoStats(p) : null);
        }

        const errors = typeof p.errors === "number" ? p.errors : 0;

        // 1b. Tope de errores por usuario y caso: el caso ya no se puede enviar ni entra al ranking.
        if (errors >= resolveMaxWrongPerCase(cfgData)) {
          throw new HttpsError(
            "resource-exhausted",
            isReto
              ? "Llegaste al máximo de errores de este reto; ya no puedes enviarlo ni entra al ranking."
              : "Llegaste al máximo de errores de este caso.",
          );
        }

        // 2. Límite de intentos por usuario y caso.
        const rate = applyRateLimit(p.recentSubmits, nowMs, resolveMaxSubmitsPerMinute(cfgData));
        if (!rate.allowed) {
          throw new HttpsError("resource-exhausted", "Demasiados intentos. Espera un momento.");
        }

        // 3. Comparación con la solución.
        const cmp = compareSolution(input.positions, sol.positions);
        const attempts = (typeof p.attempts === "number" ? p.attempts : 0) + 1;
        const startedAt = (p.startedAt as Timestamp | null | undefined) ?? undefined;

        // Sin startedAt este envío es un sondeo previo a startCase: el progreso queda
        // como no rankeable para siempre (un startCase posterior no lo revierte).
        const rankableMark = startedAt === undefined || p.rankable === false ? { rankable: false } : {};

        if (cmp.correct) {
          const ranked = computeRanked(rankableMark.rankable ?? p.rankable, startedAt !== undefined, input.startedOnline);
          const serverElapsedMs = startedAt ? nowMs - startedAt.toMillis() : null;
          const score =
            isReto && serverElapsedMs !== null
              ? computeScore(serverElapsedMs, errors, resolveErrorPenaltyMs(cfgData))
              : null;
          const nickname = userData?.nickname;

          // Ranking del día: entra si es el reto de hoy, ranked y el usuario tiene apodo.
          let rank: number | null = null;
          let entryRef: DocumentReference | null = null;
          if (isReto && ranked && score !== null && typeof nickname === "string" && nickname.length > 0) {
            const entries = firestore.collection("dailyRankings").doc(localDate!).collection("entries");
            entryRef = entries.doc(uid);
            // Los que ya estaban con el mismo score resolvieron antes: van por delante (desempate por solvedAt).
            const better = await tx.get(entries.where("score", "<=", score).count());
            rank = better.data().count + 1;
          }

          const stats = isReto ? { serverElapsedMs, errors, score, rank } : null;
          const response = solvedResponse(sol, ranked, stats);
          if (entryRef) {
            tx.set(entryRef, { uid, nickname, serverElapsedMs, errors, score, solvedAt: now });
          }
          put({
            startedAt: startedAt ?? null,
            solved: true,
            solvedAt: now,
            attempts,
            errors,
            serverElapsedMs,
            clientElapsedMs: input.clientElapsedMs,
            ranked,
            suspicious: isSuspicious(input.clientElapsedMs, serverElapsedMs, resolveClientClockMarginMs(cfgData)),
            ...rankableMark,
            ...retoFields,
            ...(isReto ? { score, rank } : {}),
            recentSubmits: rate.recent,
            lastSubmissions: rememberSubmission(p.lastSubmissions, { id: input.submissionId, response }),
          });
          return response;
        }

        const wrongResponse = { result: "wrong", wrongCount: cmp.wrongCount };
        put({
          solved: false,
          attempts,
          errors: errors + 1,
          ...rankableMark,
          ...retoFields,
          ...(stale ? { startedAt: null } : {}),
          recentSubmits: rate.recent,
          lastSubmissions: rememberSubmission(p.lastSubmissions, {
            id: input.submissionId,
            response: wrongResponse,
          }),
        });
        return wrongResponse;
      });
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

interface RetoStats {
  serverElapsedMs: number | null;
  errors: number;
  score: number | null;
  rank: number | null;
}

/** Datos de la partida de un reto ya resuelto, tal como quedaron guardados. */
function retoStats(p: DocumentData): RetoStats {
  return {
    serverElapsedMs: typeof p.serverElapsedMs === "number" ? p.serverElapsedMs : null,
    errors: typeof p.errors === "number" ? p.errors : 0,
    score: typeof p.score === "number" ? p.score : null,
    rank: typeof p.rank === "number" ? p.rank : null,
  };
}

/**
 * Respuesta de victoria: revela asesino y arma (es lo que la app muestra al resolver), no las casillas.
 * En los retos suma tiempo del servidor, errores, score y puesto del día.
 */
function solvedResponse(sol: SolutionEntry, ranked: boolean, stats: RetoStats | null) {
  return {
    result: "solved",
    murdererId: sol.murderer,
    lethalWeaponId: typeof sol.lethalWeapon === "string" ? sol.lethalWeapon : null,
    ranked,
    ...(stats ?? {}),
  };
}

export const setNickname = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      requireRegistered(request);
      const data = isDoc(request.data) ? request.data : {};
      const nickname = parseNickname(data.nickname);

      const firestore = db();
      const userRef = firestore.collection("users").doc(uid);
      const solvedQuery = userRef.collection("progress").where("solved", "==", true);
      await firestore.runTransaction(async (tx) => {
        const [user, solved] = await Promise.all([tx.get(userRef), tx.get(solvedQuery)]);
        const nowMs = Date.now();
        const now = Timestamp.fromMillis(nowMs);
        if (user.exists) tx.update(userRef, { lastSeenAt: now, nickname });
        else tx.set(userRef, { createdAt: now, lastSeenAt: now, nickname });
        // Sus entradas de ranking (retos resueltos y rankeados, aún dentro de la retención) llevan el apodo nuevo.
        const cutoff = rankingCutoffDate(nowMs);
        for (const d of solved.docs) {
          const p = d.data();
          if (
            p.ranked === true &&
            typeof p.localDate === "string" &&
            p.localDate >= cutoff &&
            typeof p.score === "number" &&
            typeof p.serverElapsedMs === "number" &&
            p.solvedAt instanceof Timestamp
          ) {
            tx.set(firestore.collection("dailyRankings").doc(p.localDate).collection("entries").doc(uid), {
              uid,
              nickname,
              serverElapsedMs: p.serverElapsedMs,
              errors: typeof p.errors === "number" ? p.errors : 0,
              score: p.score,
              solvedAt: p.solvedAt,
            });
          }
        }
      });
      return { nickname };
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

export const deleteAccount = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      await deleteUserData(db(), await authService(), uid);
      return { deleted: true };
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

// Limpieza diaria: rankings de más de 30 días y cuentas sin uso de más de 12 meses.
export const dailyCleanup = onSchedule(
  { schedule: "every day 03:00", timeZone: "America/Bogota", timeoutSeconds: 540 },
  async () => {
    const r = await runCleanup(db(), await authService(), Date.now());
    console.log(`Limpieza: ${r.rankingDaysDeleted} días de ranking y ${r.accountsDeleted} cuentas borrados.`);
  },
);

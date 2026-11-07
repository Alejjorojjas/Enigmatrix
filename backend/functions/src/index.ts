// Cloud Functions de Enigmatrix, etapa 5A.1.
// El servidor es la autoridad: la solución vive en caseSolutions y NUNCA sale en una respuesta.
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, type Firestore } from "firebase-admin/firestore";
import { defineBoolean } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { resolveEnforceAppCheck } from "./appcheck";
import {
  InputError,
  applyRateLimit,
  caseShapeFromDoc,
  compareSolution,
  computeRanked,
  findSubmission,
  isSuspicious,
  parseCaseId,
  parseSubmitInput,
  rememberSubmission,
  resolveClientClockMarginMs,
  resolveMaxSubmitsPerMinute,
  type CaseShape,
} from "./validation";

initializeApp();

setGlobalOptions({ region: "southamerica-east1", maxInstances: 20 });

// El parámetro solo se respeta en el emulador (se apaga con backend/functions/.env.local).
// Fuera del emulador App Check queda forzado a true: no hay forma de apagarlo en producción.
const ENFORCE_APP_CHECK_PARAM = defineBoolean("ENFORCE_APP_CHECK", { default: true });
const ENFORCE_APP_CHECK = resolveEnforceAppCheck(process.env, ENFORCE_APP_CHECK_PARAM);

const db = (): Firestore => getFirestore();

function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Hace falta iniciar sesión.");
  return uid;
}

/** Convierte los errores de entrada en HttpsError; deja pasar los HttpsError. */
function toHttpsError(e: unknown): HttpsError {
  if (e instanceof HttpsError) return e;
  if (e instanceof InputError) return new HttpsError(e.code, e.message);
  console.error("Error inesperado", e);
  return new HttpsError("internal", "Error interno.");
}

async function loadCaseShape(caseId: string): Promise<CaseShape> {
  const snap = await db().collection("cases").doc(caseId).get();
  if (!snap.exists) throw new HttpsError("not-found", "El caso no existe.");
  const shape = caseShapeFromDoc(snap.data());
  if (!shape) throw new HttpsError("internal", "El caso publicado está mal formado.");
  return shape;
}

export const startCase = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK },
  async (request) => {
    try {
      const uid = requireUid(request);
      const data = request.data as { caseId?: unknown } | null;
      const caseId = parseCaseId(data?.caseId);
      await loadCaseShape(caseId);

      const userRef = db().collection("users").doc(uid);
      const progRef = userRef.collection("progress").doc(caseId);
      const startedAt = await db().runTransaction(async (tx) => {
        const [user, prog] = await Promise.all([tx.get(userRef), tx.get(progRef)]);
        const existing = prog.exists ? (prog.data()?.startedAt as Timestamp | null | undefined) : undefined;
        if (existing) return existing; // ya empezado: no se cambia (idempotente)
        const now = Timestamp.now();
        if (!user.exists) tx.set(userRef, { createdAt: now });
        if (prog.exists) tx.update(progRef, { startedAt: now });
        else {
          tx.set(progRef, {
            startedAt: now,
            solved: false,
            attempts: 0,
            errors: 0,
            recentSubmits: [],
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
      const data = request.data as { caseId?: unknown } | null;

      // 1. Validación de la entrada (H-45).
      const caseId = parseCaseId(data?.caseId);
      const shape = await loadCaseShape(caseId);
      const input = parseSubmitInput(request.data, shape);

      const firestore = db();
      const userRef = firestore.collection("users").doc(uid);
      const progRef = userRef.collection("progress").doc(caseId);
      const solRef = firestore.collection("caseSolutions").doc(caseId);
      const cfgRef = firestore.collection("config").doc("server");

      // Todo en una transacción: un reintento o dos envíos a la vez no duplican efectos.
      return await firestore.runTransaction(async (tx) => {
        const [user, prog, sol, cfg] = await Promise.all([
          tx.get(userRef),
          tx.get(progRef),
          tx.get(solRef),
          tx.get(cfgRef),
        ]);
        const solution = sol.data();
        if (!solution || typeof solution.positions !== "object" || solution.positions === null) {
          throw new HttpsError("internal", "El caso no tiene solución publicada.");
        }
        const p = prog.data() ?? {};

        // 0. Reintento del mismo envío: se devuelve la misma respuesta, sin tocar nada
        //    (ni intento, ni error, ni límite).
        const seen = findSubmission(p.lastSubmissions, input.submissionId);
        if (seen) return seen.response;

        // 4. Caso ya resuelto: mismos datos, sin cambios.
        if (p.solved === true) {
          return solvedResponse(solution, p.ranked === true);
        }

        // 2. Límite de intentos por usuario y caso.
        const nowMs = Date.now();
        const rate = applyRateLimit(
          p.recentSubmits,
          nowMs,
          resolveMaxSubmitsPerMinute(cfg.data()),
        );
        if (!rate.allowed) {
          throw new HttpsError("resource-exhausted", "Demasiados intentos. Espera un momento.");
        }

        // 3. Comparación con la solución.
        const cmp = compareSolution(input.positions, solution.positions as Record<string, number>);
        const now = Timestamp.fromMillis(nowMs);
        const attempts = (typeof p.attempts === "number" ? p.attempts : 0) + 1;
        const errors = typeof p.errors === "number" ? p.errors : 0;
        const startedAt = (p.startedAt as Timestamp | null | undefined) ?? undefined;
        if (!user.exists) tx.set(userRef, { createdAt: now });

        // Sin startedAt este envío es un sondeo previo a startCase: el progreso queda
        // como no rankeable para siempre (un startCase posterior no lo revierte).
        const rankableMark = startedAt === undefined || p.rankable === false ? { rankable: false } : {};

        if (cmp.correct) {
          const ranked = computeRanked(rankableMark.rankable ?? p.rankable, startedAt !== undefined, input.startedOnline);
          const serverElapsedMs = startedAt ? nowMs - startedAt.toMillis() : null;
          const response = solvedResponse(solution, ranked);
          tx.set(
            progRef,
            {
              startedAt: startedAt ?? null,
              solved: true,
              solvedAt: now,
              attempts,
              errors,
              serverElapsedMs,
              clientElapsedMs: input.clientElapsedMs,
              ranked,
              suspicious: isSuspicious(
                input.clientElapsedMs,
                serverElapsedMs,
                resolveClientClockMarginMs(cfg.data()),
              ),
              ...rankableMark,
              recentSubmits: rate.recent,
              lastSubmissions: rememberSubmission(p.lastSubmissions, { id: input.submissionId, response }),
            },
            { merge: true },
          );
          return response;
        }

        const wrongResponse = { result: "wrong", wrongCount: cmp.wrongCount };
        tx.set(
          progRef,
          {
            solved: false,
            attempts,
            errors: errors + 1,
            ...rankableMark,
            recentSubmits: rate.recent,
            lastSubmissions: rememberSubmission(p.lastSubmissions, {
              id: input.submissionId,
              response: wrongResponse,
            }),
          },
          { merge: true },
        );
        return wrongResponse;
      });
    } catch (e) {
      throw toHttpsError(e);
    }
  },
);

/** Respuesta de victoria: revela asesino y arma (es lo que la app muestra al resolver), no las casillas. */
function solvedResponse(solution: FirebaseFirestore.DocumentData, ranked: boolean) {
  return {
    result: "solved",
    murdererId: typeof solution.murderer === "string" ? solution.murderer : null,
    lethalWeaponId: typeof solution.lethalWeapon === "string" ? solution.lethalWeapon : null,
    ranked,
  };
}

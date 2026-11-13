// Borrado de datos: cuenta completa (a pedido) y limpieza diaria por retención.
import type { Auth } from "firebase-admin/auth";
import type { Firestore } from "firebase-admin/firestore";
import { isValidDateString, isoDate } from "./daily";

export const RANKING_RETENTION_DAYS = 30;
export const INACTIVE_ACCOUNT_DAYS = 365;
const DAY_MS = 24 * 60 * 60 * 1000;
const BATCH_SIZE = 400;
const ACCOUNTS_PER_PASS = 100;
const MAX_PASSES = 50;

/** Las entradas de ranking con fecha anterior a esta tienen más de 30 días. */
export function rankingCutoffDate(nowMs: number): string {
  return isoDate(nowMs - RANKING_RETENTION_DAYS * DAY_MS);
}

export function inactiveCutoffMs(nowMs: number): number {
  return nowMs - INACTIVE_ACCOUNT_DAYS * DAY_MS;
}

/**
 * Borra las entradas de ranking del usuario: las fechas de sus retos y, además, las últimas 31 fechas
 * (la retención) por si el progreso ya no las recuerda. No toca las de otros jugadores.
 */
async function deleteRankingEntries(db: Firestore, uid: string, nowMs: number): Promise<void> {
  const prog = await db.collection("users").doc(uid).collection("progress").get();
  const dates = new Set<string>();
  for (const d of prog.docs) {
    const ld = d.data().localDate;
    if (isValidDateString(ld)) dates.add(ld);
  }
  // Hoy y los 30 días anteriores (31 fechas) más mañana UTC, que ya es "hoy" en husos adelantados.
  for (let i = -1; i <= RANKING_RETENTION_DAYS; i++) dates.add(isoDate(nowMs - i * DAY_MS));
  const list = [...dates];
  for (let i = 0; i < list.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const date of list.slice(i, i + BATCH_SIZE)) {
      batch.delete(db.collection("dailyRankings").doc(date).collection("entries").doc(uid));
    }
    await batch.commit();
  }
}

/**
 * Borra el usuario de Auth y después users/{uid} con sus subcolecciones y sus entradas de ranking.
 * Auth va primero: si falla, los datos siguen y se puede reintentar; si Auth ya no lo tiene, se sigue.
 */
export async function deleteUserData(db: Firestore, auth: Auth, uid: string, nowMs: number = Date.now()): Promise<void> {
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string } | null)?.code !== "auth/user-not-found") throw e;
  }
  await deleteRankingEntries(db, uid, nowMs);
  await db.recursiveDelete(db.collection("users").doc(uid));
}

export interface CleanupResult {
  rankingDaysDeleted: number;
  accountsDeleted: number;
  /** Cuentas que fallaron al borrarse (se reintentan en la siguiente limpieza). */
  accountsFailed: number;
}

/** Borra rankings de más de 30 días y cuentas sin uso (lastSeenAt) de más de 12 meses. */
export async function runCleanup(db: Firestore, auth: Auth, nowMs: number): Promise<CleanupResult> {
  const cutoff = rankingCutoffDate(nowMs);
  let rankingDaysDeleted = 0;
  // listDocuments incluye los documentos "fantasma" que solo tienen subcolecciones.
  for (const ref of await db.collection("dailyRankings").listDocuments()) {
    if (isValidDateString(ref.id) && ref.id < cutoff) {
      await db.recursiveDelete(ref);
      rankingDaysDeleted++;
    }
  }

  let accountsDeleted = 0;
  let accountsFailed = 0;
  const failed = new Set<string>();
  const limit = new Date(inactiveCutoffMs(nowMs));
  for (let pass = 0; pass < MAX_PASSES; pass++) {
    const snap = await db.collection("users").where("lastSeenAt", "<", limit).limit(ACCOUNTS_PER_PASS).get();
    if (snap.empty) break;
    let progressed = false;
    for (const d of snap.docs) {
      if (failed.has(d.id)) continue;
      try {
        await deleteUserData(db, auth, d.id, nowMs);
        accountsDeleted++;
        progressed = true;
      } catch (e) {
        console.error(`No se pudo borrar la cuenta ${d.id}`, e);
        failed.add(d.id);
        accountsFailed++;
      }
    }
    if (!progressed) break; // solo quedan cuentas que fallan: se reintentan mañana
  }
  return { rankingDaysDeleted, accountsDeleted, accountsFailed };
}

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

/** Borra las entradas de ranking del usuario (por las fechas de sus retos), sin tocar las de otros. */
async function deleteRankingEntries(db: Firestore, uid: string): Promise<void> {
  const prog = await db.collection("users").doc(uid).collection("progress").get();
  const dates = new Set<string>();
  for (const d of prog.docs) {
    const ld = d.data().localDate;
    if (isValidDateString(ld)) dates.add(ld);
  }
  const list = [...dates];
  for (let i = 0; i < list.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const date of list.slice(i, i + BATCH_SIZE)) {
      batch.delete(db.collection("dailyRankings").doc(date).collection("entries").doc(uid));
    }
    await batch.commit();
  }
}

/** Borra users/{uid} con sus subcolecciones, sus entradas de ranking y el usuario de Auth. */
export async function deleteUserData(db: Firestore, auth: Auth, uid: string): Promise<void> {
  await deleteRankingEntries(db, uid);
  await db.recursiveDelete(db.collection("users").doc(uid));
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string } | null)?.code !== "auth/user-not-found") throw e;
  }
}

export interface CleanupResult {
  rankingDaysDeleted: number;
  accountsDeleted: number;
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
  const limit = new Date(inactiveCutoffMs(nowMs));
  for (let pass = 0; pass < MAX_PASSES; pass++) {
    const snap = await db.collection("users").where("lastSeenAt", "<", limit).limit(ACCOUNTS_PER_PASS).get();
    if (snap.empty) break;
    for (const d of snap.docs) {
      await deleteUserData(db, auth, d.id);
      accountsDeleted++;
    }
  }
  return { rankingDaysDeleted, accountsDeleted };
}

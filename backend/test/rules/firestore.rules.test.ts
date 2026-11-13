import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, limit, orderBy, query } from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

const here = path.dirname(fileURLToPath(import.meta.url));
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-enigmatrix-rules",
    firestore: { rules: readFileSync(path.resolve(here, "../../firestore.rules"), "utf8") },
  });
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "cases/c-1"), { caseId: "c-1" });
    await setDoc(doc(db, "caseSolutions/c-1"), { positions: { c1: 0 }, murderer: "c1" });
    await setDoc(doc(db, "users/alice"), { createdAt: 1, nickname: "Alice" });
    await setDoc(doc(db, "users/alice/progress/c-1"), { solved: false });
    await setDoc(doc(db, "users/bob/progress/c-1"), { solved: true });
    await setDoc(doc(db, "config/server"), { maxSubmitsPerMinute: 6 });
    await setDoc(doc(db, "dailyRankings/2026-11-16/entries/alice"), { nickname: "Alice", score: 1000 });
    await setDoc(doc(db, "dailyRankings/2026-11-16/entries/bob"), { nickname: "Bob", score: 2000 });
  });
});

describe("cases y caseSolutions (retiradas en la 5A.3)", () => {
  it("quedaron denegadas para todos: ni se leen ni se escriben, con o sin sesión", async () => {
    for (const db of [env.unauthenticatedContext().firestore(), env.authenticatedContext("alice").firestore()]) {
      for (const col of ["caseSolutions", "cases"]) {
        await assertFails(getDoc(doc(db, `${col}/c-1`)));
        await assertFails(getDocs(collection(db, col)));
        await assertFails(setDoc(doc(db, `${col}/c-1`), { murderer: "c2" }));
        await assertFails(setDoc(doc(db, `${col}/nuevo`), { murderer: "c2" }));
        await assertFails(updateDoc(doc(db, `${col}/c-1`), { x: 1 }));
        await assertFails(deleteDoc(doc(db, `${col}/c-1`)));
      }
    }
  });
});

describe("progreso y usuario", () => {
  it("el progreso propio se lee y el ajeno no", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(getDoc(doc(db, "users/alice/progress/c-1")));
    await assertSucceeds(getDoc(doc(db, "users/alice")));
    await assertSucceeds(getDocs(collection(db, "users/alice/progress")));
    await assertFails(getDoc(doc(db, "users/bob/progress/c-1")));
    await assertFails(getDoc(doc(db, "users/bob")));
    await assertFails(getDocs(collection(db, "users/bob/progress")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "users/alice/progress/c-1")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "users/alice")));
  });
  it("nadie escribe el progreso ni el usuario desde el cliente (ni el apodo)", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "users/alice/progress/c-1"), { solved: true }));
    await assertFails(updateDoc(doc(db, "users/alice/progress/c-1"), { solved: true }));
    await assertFails(setDoc(doc(db, "users/alice/progress/otro"), { solved: true }));
    await assertFails(deleteDoc(doc(db, "users/alice/progress/c-1")));
    await assertFails(setDoc(doc(db, "users/alice"), { createdAt: 2 }));
    await assertFails(updateDoc(doc(db, "users/alice"), { nickname: "Otro" }));
    await assertFails(deleteDoc(doc(db, "users/alice")));
    await assertFails(setDoc(doc(db, "users/bob/progress/c-1"), { solved: true }));
  });
});

describe("dailyRankings", () => {
  it("cualquier usuario con sesión lee una entrada y consulta el ranking del día; sin sesión no", async () => {
    const db = env.authenticatedContext("carol", { firebase: { sign_in_provider: "anonymous" } }).firestore();
    await assertSucceeds(getDoc(doc(db, "dailyRankings/2026-11-16/entries/alice")));
    await assertSucceeds(getDocs(query(collection(db, "dailyRankings/2026-11-16/entries"), orderBy("score"), limit(50))));
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, "dailyRankings/2026-11-16/entries/alice")));
    await assertFails(getDocs(collection(anon, "dailyRankings/2026-11-16/entries")));
  });
  it("nadie escribe en el ranking desde el cliente, ni siquiera su propia entrada", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "dailyRankings/2026-11-16/entries/alice"), { score: 1 }));
    await assertFails(updateDoc(doc(db, "dailyRankings/2026-11-16/entries/alice"), { score: 1 }));
    await assertFails(deleteDoc(doc(db, "dailyRankings/2026-11-16/entries/alice")));
    await assertFails(setDoc(doc(db, "dailyRankings/2026-11-16/entries/bob"), { score: 1 }));
    await assertFails(setDoc(doc(db, "dailyRankings/2026-11-17/entries/alice"), { score: 1 }));
    await assertFails(setDoc(doc(db, "dailyRankings/2026-11-16"), { x: 1 }));
  });
});

describe("config y rutas desconocidas", () => {
  it("config/server no se lee ni se escribe", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "config/server")));
    await assertFails(setDoc(doc(db, "config/server"), { maxSubmitsPerMinute: 9999 }));
    await assertFails(setDoc(doc(db, "config/server"), { dailyStartDate: "2020-01-01" }));
  });
  it("cualquier otra colección está denegada", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "otra/x")));
    await assertFails(setDoc(doc(db, "otra/x"), { a: 1 }));
    await assertFails(getDoc(doc(db, "users/alice/otra/x")));
  });
});

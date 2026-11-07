import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs } from "firebase/firestore";
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
    await setDoc(doc(db, "users/alice"), { createdAt: 1 });
    await setDoc(doc(db, "users/alice/progress/c-1"), { solved: false });
    await setDoc(doc(db, "users/bob/progress/c-1"), { solved: true });
    await setDoc(doc(db, "config/server"), { maxSubmitsPerMinute: 6 });
  });
});

describe("caseSolutions", () => {
  it("no se lee ni se escribe, con o sin sesión", async () => {
    for (const db of [env.unauthenticatedContext().firestore(), env.authenticatedContext("alice").firestore()]) {
      await assertFails(getDoc(doc(db, "caseSolutions/c-1")));
      await assertFails(getDocs(collection(db, "caseSolutions")));
      await assertFails(setDoc(doc(db, "caseSolutions/c-1"), { murderer: "c2" }));
      await assertFails(setDoc(doc(db, "caseSolutions/nuevo"), { murderer: "c2" }));
      await assertFails(deleteDoc(doc(db, "caseSolutions/c-1")));
    }
  });
});

describe("cases", () => {
  it("se lee con sesión (también anónima) y no sin sesión", async () => {
    const anon = env.authenticatedContext("alice", { firebase: { sign_in_provider: "anonymous" } });
    await assertSucceeds(getDoc(doc(anon.firestore(), "cases/c-1")));
    await assertSucceeds(getDocs(collection(env.authenticatedContext("alice").firestore(), "cases")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "cases/c-1")));
  });
  it("no se escribe desde el cliente", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "cases/c-1"), { caseId: "c-1", solution: {} }));
    await assertFails(updateDoc(doc(db, "cases/c-1"), { x: 1 }));
    await assertFails(deleteDoc(doc(db, "cases/c-1")));
  });
});

describe("progreso y usuario", () => {
  it("el progreso propio se lee y el ajeno no", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(getDoc(doc(db, "users/alice/progress/c-1")));
    await assertSucceeds(getDoc(doc(db, "users/alice")));
    await assertFails(getDoc(doc(db, "users/bob/progress/c-1")));
    await assertFails(getDoc(doc(db, "users/bob")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "users/alice/progress/c-1")));
  });
  it("nadie escribe el progreso ni el usuario desde el cliente", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "users/alice/progress/c-1"), { solved: true }));
    await assertFails(updateDoc(doc(db, "users/alice/progress/c-1"), { solved: true }));
    await assertFails(setDoc(doc(db, "users/alice/progress/otro"), { solved: true }));
    await assertFails(deleteDoc(doc(db, "users/alice/progress/c-1")));
    await assertFails(setDoc(doc(db, "users/alice"), { createdAt: 2 }));
    await assertFails(setDoc(doc(db, "users/bob/progress/c-1"), { solved: true }));
  });
});

describe("config y rutas desconocidas", () => {
  it("config/server no se lee ni se escribe", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "config/server")));
    await assertFails(setDoc(doc(db, "config/server"), { maxSubmitsPerMinute: 9999 }));
  });
  it("cualquier otra colección está denegada", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "otra/x")));
    await assertFails(setDoc(doc(db, "otra/x"), { a: 1 }));
  });
});

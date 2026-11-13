import { describe, expect, it } from "vitest";
import {
  assertDailyGate,
  assertTodaysReto,
  dailyCaseId,
  dayNumber,
  isLocalDateInWindow,
  isRetoId,
  isValidDateString,
  parseLocalDate,
  parseOptionalLocalDate,
  requireLocalDateForReto,
  resolveDailyStartDate,
} from "../../functions/src/daily";
import { InputError } from "../../functions/src/validation";

function fails(fn: () => unknown, code: string) {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(InputError);
    expect((e as InputError).code).toBe(code);
    return;
  }
  throw new Error("Debía fallar y no lo hizo");
}

const at = (iso: string) => Date.parse(iso);

describe("fechas locales", () => {
  it("acepta solo AAAA-MM-DD de calendario real", () => {
    expect(parseLocalDate("2026-11-16")).toBe("2026-11-16");
    expect(parseLocalDate("2028-02-29")).toBe("2028-02-29");
    for (const bad of ["2026-02-30", "2026-13-01", "2026-00-10", "2027-02-29", "26-11-16", "2026/11/16", "2026-1-16", " 2026-11-16", "2026-11-16T00:00", "", 20261116, null, undefined, {}, []]) {
      fails(() => parseLocalDate(bad), "invalid-argument");
    }
    expect(isValidDateString("2026-11-31")).toBe(false);
  });
  it("localDate opcional: ausente da undefined, presente se valida", () => {
    expect(parseOptionalLocalDate(undefined)).toBeUndefined();
    expect(parseOptionalLocalDate(null)).toBeUndefined();
    expect(parseOptionalLocalDate("2026-11-16")).toBe("2026-11-16");
    fails(() => parseOptionalLocalDate("mañana"), "invalid-argument");
  });
  it("los retos exigen localDate y los demás casos no", () => {
    fails(() => requireLocalDateForReto("reto-001", undefined), "invalid-argument");
    expect(requireLocalDateForReto("reto-001", "2026-11-16")).toBe("2026-11-16");
    expect(requireLocalDateForReto("mansion-01", undefined)).toBeUndefined();
    expect(isRetoId("reto-030")).toBe(true);
    expect(isRetoId("mansion-01")).toBe(false);
  });
});

describe("qué reto toca cada día", () => {
  it("el día de inicio es reto-001 y avanza uno por día", () => {
    expect(dailyCaseId("2026-11-16", "2026-11-16")).toBe("reto-001");
    expect(dailyCaseId("2026-11-17", "2026-11-16")).toBe("reto-002");
    expect(dailyCaseId("2026-12-15", "2026-11-16")).toBe("reto-030");
  });
  it("da la vuelta cada 30 días", () => {
    expect(dailyCaseId("2026-12-16", "2026-11-16")).toBe("reto-001");
    expect(dailyCaseId("2027-01-14", "2026-11-16")).toBe("reto-030");
    // 365 días después: 365 mod 30 = 5, así que toca el reto 6.
    expect(dailyCaseId("2027-11-16", "2026-11-16")).toBe("reto-006");
  });
  it("antes del día de inicio también cuenta hacia atrás en ciclo", () => {
    expect(dailyCaseId("2026-11-15", "2026-11-16")).toBe("reto-030");
    expect(dailyCaseId("2026-10-17", "2026-11-16")).toBe("reto-001");
  });
  it("cruza fin de mes y de año sin errores", () => {
    expect(dayNumber("2027-01-01") - dayNumber("2026-12-31")).toBe(1);
    expect(dayNumber("2028-03-01") - dayNumber("2028-02-28")).toBe(2);
    expect(dailyCaseId("2027-01-01", "2026-12-31")).toBe("reto-002");
  });
  it("dailyStartDate sale de config/server con 2026-11-16 por defecto", () => {
    expect(resolveDailyStartDate(undefined)).toBe("2026-11-16");
    expect(resolveDailyStartDate({})).toBe("2026-11-16");
    expect(resolveDailyStartDate({ dailyStartDate: "2026-12-01" })).toBe("2026-12-01");
    for (const bad of ["2026-02-30", "x", 5, null]) expect(resolveDailyStartDate({ dailyStartDate: bad })).toBe("2026-11-16");
  });
});

describe("puerta del reto (UTC-12 a UTC+14)", () => {
  const now = at("2026-11-16T12:00:00Z");
  it("acepta la fecha de hoy y las de los husos extremos", () => {
    expect(isLocalDateInWindow("2026-11-16", now)).toBe(true);
    // 12:00Z: en UTC-12 son las 00:00 del 16 y en UTC+14 las 02:00 del 17.
    expect(isLocalDateInWindow("2026-11-17", now)).toBe(true);
  });
  it("día anterior y día siguiente fuera de ventana", () => {
    expect(isLocalDateInWindow("2026-11-15", now)).toBe(false);
    expect(isLocalDateInWindow("2026-11-18", now)).toBe(false);
  });
  it("los límites exactos: UTC-12 y UTC+14", () => {
    // 11:59:59Z: en UTC-12 todavía es el 15 (23:59:59), así que el 15 vale.
    expect(isLocalDateInWindow("2026-11-15", at("2026-11-16T11:59:59Z"))).toBe(true);
    expect(isLocalDateInWindow("2026-11-15", at("2026-11-16T12:00:00Z"))).toBe(false);
    // 09:59:59Z: en UTC+14 todavía es el 16 (23:59:59); a las 10:00Z ya es el 17.
    expect(isLocalDateInWindow("2026-11-17", at("2026-11-16T09:59:59Z"))).toBe(false);
    expect(isLocalDateInWindow("2026-11-17", at("2026-11-16T10:00:00Z"))).toBe(true);
  });
  it("assertDailyGate da failed-precondition fuera de ventana", () => {
    assertDailyGate("2026-11-16", now);
    fails(() => assertDailyGate("2026-11-14", now), "failed-precondition");
    fails(() => assertDailyGate("2030-01-01", now), "failed-precondition");
  });
  it("assertTodaysReto: solo el reto que corresponde a la fecha", () => {
    assertTodaysReto("reto-001", "2026-11-16", "2026-11-16", now);
    fails(() => assertTodaysReto("reto-002", "2026-11-16", "2026-11-16", now), "failed-precondition");
    fails(() => assertTodaysReto("reto-001", "2026-11-15", "2026-11-16", now), "failed-precondition");
    // Mañana de otro huso: el reto de mañana se entrega si la fecha entra en la ventana.
    assertTodaysReto("reto-002", "2026-11-17", "2026-11-16", now);
  });
});

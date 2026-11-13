// Reto diario: fechas locales, puerta del día y qué reto toca cada día.
// Lógica pura: sin Firebase y sin reloj propio (la hora entra como parámetro).
import { InputError } from "./validation";

export const DAILY_CYCLE_DAYS = 30;
export const DEFAULT_DAILY_START_DATE = "2026-11-16";
/** Husos aceptados: de UTC-12 a UTC+14. */
export const MIN_UTC_OFFSET_HOURS = -12;
export const MAX_UTC_OFFSET_HOURS = 14;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

/** `YYYY-MM-DD` (UTC) de un instante en ms. */
export function isoDate(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

/** Es una fecha de calendario real en formato `YYYY-MM-DD`. */
export function isValidDateString(raw: unknown): raw is string {
  if (typeof raw !== "string") return false;
  const m = DATE_PATTERN.exec(raw);
  if (!m) return false;
  const ms = Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  return Number.isFinite(ms) && isoDate(ms) === raw;
}

export function parseLocalDate(raw: unknown): string {
  if (!isValidDateString(raw)) {
    throw new InputError("invalid-argument", "La fecha (localDate) no es válida; debe ser AAAA-MM-DD.");
  }
  return raw;
}

/** Número de día (días desde 1970-01-01) de una fecha ya validada. */
export function dayNumber(date: string): number {
  const m = DATE_PATTERN.exec(date)!;
  return Math.round(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])) / DAY_MS);
}

/** `dailyStartDate` de config/server; si falta o no es una fecha válida, el valor por defecto. */
export function resolveDailyStartDate(cfg: unknown): string {
  if (typeof cfg === "object" && cfg !== null) {
    const v = (cfg as Record<string, unknown>).dailyStartDate;
    if (isValidDateString(v)) return v;
  }
  return DEFAULT_DAILY_START_DATE;
}

/** `reto-001` a `reto-030`, en ciclo: (díasEntre(inicio, fecha) mod 30) + 1. */
export function dailyCaseId(localDate: string, startDate: string): string {
  const diff = dayNumber(localDate) - dayNumber(startDate);
  const idx = ((diff % DAILY_CYCLE_DAYS) + DAILY_CYCLE_DAYS) % DAILY_CYCLE_DAYS;
  return `reto-${String(idx + 1).padStart(3, "0")}`;
}

/** ¿Es `localDate` la fecha actual en algún huso entre UTC-12 y UTC+14? */
export function isLocalDateInWindow(localDate: string, nowMs: number): boolean {
  const lo = isoDate(nowMs + MIN_UTC_OFFSET_HOURS * HOUR_MS);
  const hi = isoDate(nowMs + MAX_UTC_OFFSET_HOURS * HOUR_MS);
  return localDate >= lo && localDate <= hi;
}

export function assertDailyGate(localDate: string, nowMs: number): void {
  if (!isLocalDateInWindow(localDate, nowMs)) {
    throw new InputError(
      "failed-precondition",
      "La fecha de tu teléfono no coincide con la del servidor. Revisa la fecha y la zona horaria.",
    );
  }
}

export const isRetoId = (caseId: string): boolean => caseId.startsWith("reto-");

/** Puerta del reto diario: la fecha debe ser de hoy en algún huso y el reto debe ser el de esa fecha. */
export function assertTodaysReto(caseId: string, localDate: string, startDate: string, nowMs: number): void {
  assertDailyGate(localDate, nowMs);
  if (dailyCaseId(localDate, startDate) !== caseId) {
    throw new InputError("failed-precondition", "Ese reto no es el de hoy.");
  }
}

/** `localDate` opcional: ausente (undefined o null) da undefined; si viene, tiene que ser válida. */
export function parseOptionalLocalDate(raw: unknown): string | undefined {
  return raw === undefined || raw === null ? undefined : parseLocalDate(raw);
}

/** Los retos exigen `localDate`; los demás casos la ignoran. */
export function requireLocalDateForReto(caseId: string, localDate: string | undefined): string | undefined {
  if (isRetoId(caseId) && localDate === undefined) {
    throw new InputError("invalid-argument", "Falta la fecha (localDate) del reto.");
  }
  return localDate;
}

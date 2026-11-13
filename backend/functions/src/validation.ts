// Lógica pura de validación: sin Firebase, sin red, sin reloj propio.
// Se prueba con tests unitarios (backend/test/unit).

export const MAX_CASE_ID_LENGTH = 64;
export const MAX_CLIENT_ELAPSED_MS = 24 * 60 * 60 * 1000; // 24 h
export const RATE_WINDOW_MS = 60 * 1000;
export const DEFAULT_MAX_SUBMITS_PER_MINUTE = 6;
export const MIN_SUBMITS_PER_MINUTE = 1;
export const MAX_SUBMITS_PER_MINUTE_LIMIT = 60;
/** Margen por defecto entre el reloj del teléfono y el del servidor para marcar `suspicious`. */
export const DEFAULT_CLIENT_CLOCK_MARGIN_MS = 5000;
export const MAX_LAST_SUBMISSIONS = 20;
export const DEFAULT_MAX_WRONG_PER_CASE = 15;
export const MAX_WRONG_PER_CASE_LIMIT = 1000;
export const DEFAULT_ERROR_PENALTY_MS = 30_000;
export const MAX_ERROR_PENALTY_MS = 24 * 60 * 60 * 1000;
/** Casos que puede jugar un invitado (sesión anónima), además del tutorial que corre en el teléfono. */
export const DEFAULT_FREE_CASE_IDS: readonly string[] = ["mansion-01", "mansion-02"];
export const MAX_FREE_CASE_IDS = 50;
/** Tiempo mínimo plausible (servidor) para resolver un reto y entrar al ranking. */
export const DEFAULT_MIN_RANKED_ELAPSED_MS = 20_000;
export const MAX_MIN_RANKED_ELAPSED_MS = 60 * 60 * 1000;

/** Ids de caso y de personaje: empiezan por letra o número; luego letras, números, `-` y `_`. */
export const ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]*$/;
export const SUBMISSION_ID_PATTERN = /^[A-Za-z0-9_-]{8,64}$/;

/** Error de entrada: `code` usa los mismos nombres que HttpsError. */
export class InputError extends Error {
  constructor(
    public readonly code: "invalid-argument" | "not-found" | "resource-exhausted" | "failed-precondition",
    message: string,
    /** Datos extra para el cliente (HttpsError.details), p. ej. `{ reason: "email-unverified" }`. */
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "InputError";
  }
}

/** Lo mínimo que se necesita del caso público para validar un envío. */
export interface CaseShape {
  characterIds: string[];
  size: number;
}

export interface SubmitInput {
  caseId: string;
  positions: Record<string, number>;
  clientElapsedMs: number;
  startedOnline: boolean;
  submissionId: string;
}

const hasOwn = (o: object, k: string): boolean =>
  Object.prototype.hasOwnProperty.call(o, k);

const isPlainObject = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

/** `caseId`: texto no vacío de hasta 64 caracteres; empieza por letra o número y sigue con letras, números, `-` y `_`. */
export function parseCaseId(raw: unknown): string {
  if (typeof raw !== "string" || raw.length === 0 || raw.length > MAX_CASE_ID_LENGTH) {
    throw new InputError("invalid-argument", "caseId no es válido.");
  }
  // Evita rutas de Firestore con "/" y caracteres raros.
  if (!ID_PATTERN.test(raw)) {
    throw new InputError("invalid-argument", "caseId no es válido.");
  }
  return raw;
}

/**
 * Extrae los datos del caso público (sin solución) que hacen falta para validar.
 * Devuelve null si el documento no tiene la forma esperada.
 */
export function caseShapeFromDoc(doc: unknown): CaseShape | null {
  if (!isPlainObject(doc)) return null;
  const map = doc.map;
  const chars = doc.characters;
  if (!isPlainObject(map) || !Array.isArray(chars)) return null;
  const size = map.size;
  if (typeof size !== "number" || !Number.isInteger(size) || size < 1) return null;
  const ids: string[] = [];
  for (const c of chars) {
    if (!isPlainObject(c) || typeof c.id !== "string" || !ID_PATTERN.test(c.id)) return null;
    ids.push(c.id);
  }
  if (new Set(ids).size !== ids.length) return null;
  return { characterIds: ids, size };
}

/** Valida `positions` contra el caso: exactamente sus ids, enteros en rango, sin repetir. */
export function parsePositions(raw: unknown, shape: CaseShape): Record<string, number> {
  const bad = (msg: string) => new InputError("invalid-argument", msg);
  if (!isPlainObject(raw)) throw bad("El tablero debe ser un objeto.");
  // Se mira el tamaño antes de recorrer nada: un objeto enorme se rechaza de inmediato.
  const keys = Object.keys(raw);
  if (keys.length !== shape.characterIds.length) {
    throw bad("El tablero no tiene los personajes del caso.");
  }
  const max = shape.size * shape.size;
  const seen = new Set<number>();
  const out: Record<string, number> = {};
  for (const id of shape.characterIds) {
    if (!hasOwn(raw, id)) throw bad("El tablero no tiene los personajes del caso.");
    const v = raw[id];
    if (typeof v !== "number" || !Number.isInteger(v) || v < 0 || v >= max) {
      throw bad("Una posición está fuera del tablero.");
    }
    if (seen.has(v)) throw bad("Hay posiciones repetidas.");
    seen.add(v);
    out[id] = v;
  }
  return out;
}

export function parseClientElapsedMs(raw: unknown): number {
  if (
    typeof raw !== "number" ||
    !Number.isInteger(raw) ||
    raw < 0 ||
    raw > MAX_CLIENT_ELAPSED_MS
  ) {
    throw new InputError("invalid-argument", "clientElapsedMs no es válido.");
  }
  return raw;
}

export function parseStartedOnline(raw: unknown): boolean {
  if (typeof raw !== "boolean") {
    throw new InputError("invalid-argument", "startedOnline debe ser verdadero o falso.");
  }
  return raw;
}

/** `submissionId`: texto de 8 a 64 caracteres [A-Za-z0-9_-]. Identifica un envío para poder reintentarlo. */
export function parseSubmissionId(raw: unknown): string {
  if (typeof raw !== "string" || !SUBMISSION_ID_PATTERN.test(raw)) {
    throw new InputError("invalid-argument", "submissionId no es válido.");
  }
  return raw;
}

/** Valida todo el envío una vez conocido el caso. */
export function parseSubmitInput(data: unknown, shape: CaseShape): SubmitInput {
  if (!isPlainObject(data)) throw new InputError("invalid-argument", "Datos inválidos.");
  return {
    caseId: parseCaseId(data.caseId),
    positions: parsePositions(data.positions, shape),
    clientElapsedMs: parseClientElapsedMs(data.clientElapsedMs),
    startedOnline: parseStartedOnline(data.startedOnline),
    submissionId: parseSubmissionId(data.submissionId),
  };
}

export interface Comparison {
  correct: boolean;
  /** Personajes fuera de su casilla (igual que game_controller.dart). */
  wrongCount: number;
}

/**
 * Compara el tablero con la solución. `wrongCount` es la cantidad de personajes
 * que no están en su casilla; nunca se devuelve cuáles.
 */
export function compareSolution(
  positions: Record<string, number>,
  solution: Record<string, number>,
): Comparison {
  let wrong = 0;
  for (const [id, cell] of Object.entries(positions)) {
    if (solution[id] !== cell) wrong++;
  }
  // Un personaje que la solución tenga y el envío no: también cuenta como fallo.
  for (const id of Object.keys(solution)) {
    if (!hasOwn(positions, id)) wrong++;
  }
  return { correct: wrong === 0, wrongCount: wrong };
}

/**
 * Lee `maxSubmitsPerMinute` de config/server y lo acota entre 1 y 60.
 * Si no es un entero, usa el valor por defecto.
 */
export function resolveMaxSubmitsPerMinute(cfg: unknown): number {
  if (isPlainObject(cfg)) {
    const v = cfg.maxSubmitsPerMinute;
    if (typeof v === "number" && Number.isInteger(v)) {
      return Math.min(MAX_SUBMITS_PER_MINUTE_LIMIT, Math.max(MIN_SUBMITS_PER_MINUTE, v));
    }
  }
  return DEFAULT_MAX_SUBMITS_PER_MINUTE;
}

/** Lee `maxWrongPerCase` de config/server (entero entre 1 y 1000); si no, 15. */
export function resolveMaxWrongPerCase(cfg: unknown): number {
  if (isPlainObject(cfg)) {
    const v = cfg.maxWrongPerCase;
    if (typeof v === "number" && Number.isInteger(v)) {
      return Math.min(MAX_WRONG_PER_CASE_LIMIT, Math.max(1, v));
    }
  }
  return DEFAULT_MAX_WRONG_PER_CASE;
}

/** Lee `errorPenaltyMs` de config/server (entero entre 0 y 24 h); si no, 30000 ms. */
export function resolveErrorPenaltyMs(cfg: unknown): number {
  if (isPlainObject(cfg)) {
    const v = cfg.errorPenaltyMs;
    if (typeof v === "number" && Number.isInteger(v) && v >= 0 && v <= MAX_ERROR_PENALTY_MS) return v;
  }
  return DEFAULT_ERROR_PENALTY_MS;
}

/** Puntaje del ranking: tiempo del servidor más la penalización por cada error. Gana el menor. */
export function computeScore(serverElapsedMs: number, errors: number, penaltyMs: number): number {
  return serverElapsedMs + errors * penaltyMs;
}

/** Lee `freeCaseIds` de config/server (lista de ids de caso); si falta o es inválida, mansion-01 y mansion-02. */
export function resolveFreeCaseIds(cfg: unknown): string[] {
  if (isPlainObject(cfg)) {
    const v = cfg.freeCaseIds;
    if (
      Array.isArray(v) &&
      v.length <= MAX_FREE_CASE_IDS &&
      v.every((x) => typeof x === "string" && x.length <= MAX_CASE_ID_LENGTH && ID_PATTERN.test(x))
    ) {
      return [...(v as string[])];
    }
  }
  return [...DEFAULT_FREE_CASE_IDS];
}

/** ¿El proveedor de inicio de sesión es de un usuario registrado? Solo "anonymous" (o ausente) es invitado. */
export function isRegisteredProvider(provider: unknown): boolean {
  return typeof provider === "string" && provider.length > 0 && provider !== "anonymous";
}

export const REGISTER_MESSAGE = "Regístrate para seguir jugando.";

export const EMAIL_UNVERIFIED_MESSAGE = "Verifica tu correo para jugar el reto.";

/**
 * Un correo con contraseña sin verificar no cuenta como registrado para el reto ni para el apodo.
 * Los demás proveedores (Google, Apple...) ya vienen verificados. Lanza failed-precondition
 * con details `{ reason: "email-unverified" }`.
 */
export function assertEmailVerified(provider: unknown, emailVerified: unknown): void {
  if (provider === "password" && emailVerified !== true) {
    throw new InputError("failed-precondition", EMAIL_UNVERIFIED_MESSAGE, { reason: "email-unverified" });
  }
}

/**
 * Los invitados solo juegan los casos gratis; el resto de la campaña y todos los retos exigen registro.
 * En la campaña basta con no ser anónimo; en los retos, además, el correo debe estar verificado.
 * Lanza failed-precondition si no se puede jugar.
 */
export function assertCanPlay(
  provider: unknown,
  caseId: string,
  isReto: boolean,
  freeCaseIds: readonly string[],
  emailVerified?: unknown,
): void {
  if (isRegisteredProvider(provider)) {
    if (isReto) assertEmailVerified(provider, emailVerified);
    return;
  }
  if (!isReto && freeCaseIds.includes(caseId)) return;
  throw new InputError("failed-precondition", REGISTER_MESSAGE);
}

/** Lee `minRankedElapsedMs` de config/server (entero entre 0 y 1 h); si no, 20000 ms. */
export function resolveMinRankedElapsedMs(cfg: unknown): number {
  if (isPlainObject(cfg)) {
    const v = cfg.minRankedElapsedMs;
    if (typeof v === "number" && Number.isInteger(v) && v >= 0 && v <= MAX_MIN_RANKED_ELAPSED_MS) return v;
  }
  return DEFAULT_MIN_RANKED_ELAPSED_MS;
}

/** ¿Un reto resuelto en menos del mínimo plausible? Entonces no es rankeable y es sospechoso. */
export function isTooFast(serverElapsedMs: number | null, minMs: number): boolean {
  return serverElapsedMs !== null && serverElapsedMs < minMs;
}

/** Lee `clientClockMarginMs` de config/server (entero >= 0); si no, 5000 ms. */
export function resolveClientClockMarginMs(cfg: unknown): number {
  if (isPlainObject(cfg)) {
    const v = cfg.clientClockMarginMs;
    if (typeof v === "number" && Number.isInteger(v) && v >= 0) return v;
  }
  return DEFAULT_CLIENT_CLOCK_MARGIN_MS;
}

/**
 * ¿Cuenta para el ranking? Solo el servidor lo decide: `rankable` no puede ser false,
 * tiene que existir startedAt (puesto por startCase) y el teléfono tiene que decir
 * que empezó con conexión. `startedOnline` solo puede bajar el resultado, nunca subirlo.
 */
export function computeRanked(
  rankable: unknown,
  hasStartedAt: boolean,
  startedOnline: boolean,
): boolean {
  return rankable !== false && hasStartedAt && startedOnline === true;
}

/** El tiempo que declara el teléfono supera al del servidor por más del margen. */
export function isSuspicious(
  clientElapsedMs: number,
  serverElapsedMs: number | null,
  marginMs: number,
): boolean {
  return serverElapsedMs !== null && clientElapsedMs > serverElapsedMs + marginMs;
}

export interface SubmissionRecord {
  id: string;
  response: Record<string, unknown>;
}

/** Busca un submissionId ya visto en la lista guardada (ignora basura). */
export function findSubmission(list: unknown, id: string): SubmissionRecord | null {
  if (!Array.isArray(list)) return null;
  for (const e of list) {
    if (isPlainObject(e) && e.id === id && isPlainObject(e.response)) {
      return { id, response: e.response };
    }
  }
  return null;
}

/** Agrega un envío a la lista y deja solo los últimos 20. */
export function rememberSubmission(list: unknown, rec: SubmissionRecord): SubmissionRecord[] {
  const prev: SubmissionRecord[] = [];
  if (Array.isArray(list)) {
    for (const e of list) {
      if (isPlainObject(e) && typeof e.id === "string" && isPlainObject(e.response)) {
        prev.push({ id: e.id, response: e.response });
      }
    }
  }
  return [...prev, rec].slice(-MAX_LAST_SUBMISSIONS);
}

export interface RateDecision {
  allowed: boolean;
  /** Marcas de tiempo vigentes (ya podadas); si se permite, incluye la nueva. */
  recent: number[];
}

/**
 * Ventana deslizante de 60 s. Un envío rechazado NO se anota, para que el
 * bloqueo termine cuando se vence el primero.
 */
export function applyRateLimit(
  previous: unknown,
  nowMs: number,
  maxPerMinute: number,
): RateDecision {
  const list = Array.isArray(previous) ? previous : [];
  const recent = list
    .filter((t): t is number => typeof t === "number" && Number.isFinite(t))
    .filter((t) => nowMs - t < RATE_WINDOW_MS && t <= nowMs);
  if (recent.length >= maxPerMinute) return { allowed: false, recent };
  return { allowed: true, recent: [...recent, nowMs] };
}

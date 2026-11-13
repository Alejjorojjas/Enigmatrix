// Apodos: reglas de formato y filtro de groserías (es/en). Lógica pura.
import profanity from "./profanity.json";
import { InputError } from "./validation";

export const NICKNAME_MIN_LENGTH = 3;
export const NICKNAME_MAX_LENGTH = 16;

/** Letras latinas con tildes y ñ, números, espacio, punto, guion y guion bajo. */
const NICKNAME_PATTERN = /^[A-Za-zÀ-ÖØ-öø-ÿ0-9 ._-]+$/;
const HAS_LETTER_OR_DIGIT = /[A-Za-zÀ-ÖØ-öø-ÿ0-9]/;

const LEET: Record<string, string> = { "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s", "!": "i" };

/** Minúsculas, sin tildes, sin trucos de números/símbolos, solo a-z y sin letras repetidas seguidas. */
export function normalizeForFilter(s: string): string {
  const base = s
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .replace(/[013457@$!]/g, (c) => LEET[c] ?? c)
    .replace(/[^a-z]/g, "");
  return base.replace(/(.)\1+/g, "$1");
}

const EXACT = new Set(profanity.exacta.map(normalizeForFilter));
const CONTAINS = profanity.contiene.map(normalizeForFilter);

/** ¿El apodo lleva una grosería? Palabra entera para las cortas, y en cualquier parte para las largas. */
export function containsProfanity(nickname: string): boolean {
  const tokens = nickname.split(/[ ._-]+/).filter((t) => t.length > 0);
  const normTokens = tokens.map(normalizeForFilter);
  const joined = normalizeForFilter(nickname);
  if (normTokens.some((t) => EXACT.has(t))) return true;
  if (EXACT.has(joined)) return true;
  return CONTAINS.some((w) => joined.includes(w));
}

/**
 * Limpia y valida un apodo: recorta espacios a los lados, de 3 a 16 caracteres, solo letras
 * (con tildes y ñ), números, espacio, `.`, `-` y `_`, y sin groserías. No tiene que ser único.
 */
export function parseNickname(raw: unknown): string {
  const badLength = () =>
    new InputError("invalid-argument", `El apodo debe tener entre ${NICKNAME_MIN_LENGTH} y ${NICKNAME_MAX_LENGTH} caracteres.`);
  if (typeof raw !== "string") throw new InputError("invalid-argument", "El apodo debe ser texto.");
  // Un texto enorme se rechaza de inmediato, antes de recorrerlo.
  if (raw.length > 64) throw badLength();
  const nick = raw.normalize("NFC").trim();
  const len = Array.from(nick).length;
  if (len < NICKNAME_MIN_LENGTH || len > NICKNAME_MAX_LENGTH) throw badLength();
  if (!NICKNAME_PATTERN.test(nick)) {
    throw new InputError(
      "invalid-argument",
      "El apodo solo puede llevar letras, números, espacio, punto, guion y guion bajo.",
    );
  }
  if (!HAS_LETTER_OR_DIGIT.test(nick)) {
    throw new InputError("invalid-argument", "El apodo debe llevar al menos una letra o un número.");
  }
  if (containsProfanity(nick)) {
    throw new InputError("invalid-argument", "Ese apodo no está permitido. Elige otro.");
  }
  return nick;
}

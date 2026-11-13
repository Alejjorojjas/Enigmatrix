import { describe, expect, it } from "vitest";
import { containsProfanity, normalizeForFilter, parseNickname } from "../../functions/src/nickname";
import { InputError } from "../../functions/src/validation";

function rejects(raw: unknown, messagePart?: string) {
  try {
    parseNickname(raw);
  } catch (e) {
    expect(e).toBeInstanceOf(InputError);
    expect((e as InputError).code).toBe("invalid-argument");
    if (messagePart) expect((e as InputError).message).toContain(messagePart);
    return;
  }
  throw new Error(`Debía rechazar ${JSON.stringify(raw)} y no lo hizo`);
}

describe("apodo válido", () => {
  it("acepta letras con tildes y ñ, números, espacio, punto, guion y guion bajo", () => {
    for (const ok of ["Ana", "José_Luis", "Niña.Sol", "pepe-99", "Ángel Muñoz", "ÑandúÜ", "a.b", "Ab 1", "X_Y-Z.9", "1234", "a".repeat(16)]) {
      expect(parseNickname(ok)).toBe(ok);
    }
  });
  it("recorta los espacios a los lados antes de contar", () => {
    expect(parseNickname("   Ana   ")).toBe("Ana");
    expect(parseNickname("  abc  ")).toBe("abc");
    expect(parseNickname("\tAna\n")).toBe("Ana");
  });
  it("normaliza tildes descompuestas a la forma compuesta", () => {
    expect(parseNickname("José Luis")).toBe("José Luis");
  });
  it("cuenta caracteres, no bytes: 16 con tildes vale", () => {
    expect(parseNickname("ñ".repeat(16))).toHaveLength(16);
  });
});

describe("apodo inválido", () => {
  it("largo fuera de 3 a 16 después de recortar", () => {
    for (const bad of ["", "  ", "ab", " ab ", "a".repeat(17), "  " + "a".repeat(17) + "  ", "a".repeat(500)]) {
      rejects(bad, "entre 3 y 16");
    }
  });
  it("tipos que no son texto", () => {
    for (const bad of [null, undefined, 123, true, {}, [], ["Ana"]]) rejects(bad, "texto");
  });
  it("caracteres no permitidos", () => {
    for (const bad of ["Ana!", "Ana@mail", "Ana#1", "Ana/Pepe", "Ana<b>", "Ana\u{1F600}", "Ана Иван", "漢字漢字", "Ana\u0000x", "ab c$", "Ana,Luis", "Ana\nLuis"]) {
      rejects(bad, "solo puede llevar");
    }
  });
  it("sin ninguna letra ni número", () => {
    for (const bad of ["...", "---", "___", " . - ", "._-"]) rejects(bad, "al menos una letra");
  });
  it("groserías en español e inglés", () => {
    for (const bad of ["puta", "Hijueputa", "MIERDA", "Gran Puta", "pendejo99", "fuck", "FuckYou", "shit_head", "bitch", "gonorrea", "Cabrón", "Pe.n.de.jo"]) {
      rejects(bad, "no está permitido");
    }
  });
});

describe("filtro de groserías", () => {
  it("quita tildes, números por letras, símbolos y letras repetidas", () => {
    expect(normalizeForFilter("Pu7a")).toBe("puta");
    expect(normalizeForFilter("PUUUTA")).toBe("puta");
    expect(normalizeForFilter("m1erd@")).toBe("mierda");
    expect(normalizeForFilter("Cabrón")).toBe("cabron");
  });
  it("detecta trucos habituales", () => {
    for (const bad of ["pu7a", "puuuta", "m1erda", "f.u.c.k", "p u t a", "sh1t", "h1jueputa", "p3nd3j0", "C4brón"]) {
      expect(containsProfanity(bad), bad).toBe(true);
    }
  });
  it("no bloquea palabras normales que contienen letras de una grosería", () => {
    for (const ok of ["Mariana", "Computadora", "Scunthorpe", "Cassandra", "Vergara", "Disputa", "Classic", "Peña", "Pluto", "Grupo", "Culebra", "Pistola", "Analista", "Hello World", "Mario", "Conchita", "Cumbre", "Penelope", "Pijamas"]) {
      expect(containsProfanity(ok), ok).toBe(false);
      expect(() => parseNickname(ok)).not.toThrow();
    }
  });
  it("palabras cortas solo como palabra entera: 'marica' exacta sí, 'Maricarmen' no", () => {
    expect(containsProfanity("Marica")).toBe(true);
    expect(containsProfanity("Maricarmen")).toBe(false);
  });
});

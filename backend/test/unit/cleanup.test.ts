import { describe, expect, it } from "vitest";
import { inactiveCutoffMs, rankingCutoffDate } from "../../functions/src/cleanup";

const at = (iso: string) => Date.parse(iso);

describe("fechas de retención", () => {
  it("las entradas se conservan 30 días: la fecha de corte es la de hace 30 días", () => {
    expect(rankingCutoffDate(at("2026-12-16T10:00:00Z"))).toBe("2026-11-16");
    expect(rankingCutoffDate(at("2027-01-05T00:00:00Z"))).toBe("2026-12-06");
    // Una fecha igual al corte se conserva; solo se borran las anteriores.
    const cutoff = rankingCutoffDate(at("2026-12-16T10:00:00Z"));
    expect("2026-11-16" < cutoff).toBe(false);
    expect("2026-11-15" < cutoff).toBe(true);
  });
  it("las cuentas sin uso se borran a los 365 días", () => {
    const now = at("2027-11-12T00:00:00Z");
    expect(now - inactiveCutoffMs(now)).toBe(365 * 24 * 3600 * 1000);
  });
});

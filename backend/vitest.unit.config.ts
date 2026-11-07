import { defineConfig } from "vitest/config";

// Pruebas unitarias: lógica pura, sin emulador.
export default defineConfig({
  test: { include: ["test/unit/**/*.test.ts"] },
});

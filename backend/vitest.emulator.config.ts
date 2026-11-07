import { defineConfig } from "vitest/config";

// Reglas e integración: necesitan los emuladores (se lanzan con `npm run test:emulator`).
// Los archivos corren uno tras otro porque comparten la misma base de datos del emulador.
export default defineConfig({
  test: {
    include: ["test/rules/**/*.test.ts", "test/integration/**/*.test.ts"],
    fileParallelism: false,
    testTimeout: 30000,
    hookTimeout: 120000,
  },
});

// App Check no se puede apagar en producción: solo el emulador respeta el parámetro.

/**
 * Devuelve `true` siempre, salvo cuando corre el emulador de Functions
 * (FUNCTIONS_EMULATOR === "true"); ahí se usa el valor del parámetro.
 */
export function resolveEnforceAppCheck<T>(env: Record<string, string | undefined>, param: T): T | true {
  if (env.FUNCTIONS_EMULATOR === "true") return param;
  // Excepción TEMPORAL y explícita (13-11-2026, decisión de Alejandro): solo se
  // apaga en producción si además se declara APP_CHECK_TEMPORALMENTE_APAGADO.
  if (env.APP_CHECK_TEMPORALMENTE_APAGADO === "si") return param;
  return true;
}

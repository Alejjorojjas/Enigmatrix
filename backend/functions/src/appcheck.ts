// App Check no se puede apagar en producción: solo el emulador respeta el parámetro.

/**
 * Devuelve `true` siempre, salvo cuando corre el emulador de Functions
 * (FUNCTIONS_EMULATOR === "true"); ahí se usa el valor del parámetro.
 */
export function resolveEnforceAppCheck<T>(env: Record<string, string | undefined>, param: T): T | true {
  return env.FUNCTIONS_EMULATOR === "true" ? param : true;
}

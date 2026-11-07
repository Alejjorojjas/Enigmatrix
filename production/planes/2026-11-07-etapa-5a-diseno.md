# Etapa 5A: diseño técnico del servidor (ronda 5A.1, solo emulador)

- **Fecha:** 07-11-2026
- **Base:** ADR-0016, aceptado el 07-11-2026.
- **Alcance de la ronda 5A.1:** backend en `backend/` que corre en el emulador de Firebase, con pruebas. No cambia la app ni `tools/` y no usa ningún proyecto real de Firebase.
- **Ronda 5A.2:** la app se conecta (Auth anónimo, caché de casos sin solución, cola "por validar") y `tools/` publica los casos en dos partes.

## Proyecto y entorno

- **Proyecto:** el id de emulador es `demo-enigmatrix`. Con el prefijo `demo-`, el emulador no necesita un proyecto real ni credenciales.
- **Código:**
  - Cloud Functions de 2.ª generación en TypeScript, con runtime Node 22 y región `southamerica-east1`;
  - `firebase-admin` y `firebase-functions` en su versión estable actual.
- **Emuladores:** Auth, Firestore y Functions. Requieren Java 17: `JAVA_HOME="C:/Program Files/Java/jdk-17"`.

## Datos en Firestore

| Ruta | Contenido | Quién lee | Quién escribe |
|---|---|---|---|
| `cases/{caseId}` | El caso público: el JSON del caso **sin** `solution` | Cualquier usuario con sesión (también anónima) | Nadie desde el cliente |
| `caseSolutions/{caseId}` | `positions`, `murderer` y `lethalWeapon` (si hay arma) | Nadie desde el cliente | Solo el script de publicación (Admin) |
| `users/{uid}` | `createdAt` | El dueño | Solo las funciones |
| `users/{uid}/progress/{caseId}` | `startedAt`, `solved`, `solvedAt`, `attempts`, `errors`, `serverElapsedMs`, `clientElapsedMs`, `ranked` y `recentSubmits` (para el límite) | El dueño | Solo las funciones |
| `config/server` | Valores del servidor, como `maxSubmitsPerMinute` | Nadie desde el cliente | Admin |

Valores por defecto en el código, por si `config/server` no existe: `maxSubmitsPerMinute = 6`. Pasan a Remote Config en la 5B.

## Funciones (llamables, `onCall`)

### `startCase({caseId})`

- Exige sesión.
- Si el caso existe y el progreso todavía no tiene `startedAt`, lo guarda con la hora del servidor. Si ya lo tiene, no lo cambia.
- Devuelve `{startedAt}`.

### `submitSolution({caseId, positions, clientElapsedMs, startedOnline})`

1. **Validación de la entrada (H-45):**
   - hay sesión;
   - `caseId` es un texto de como máximo 64 caracteres y el caso existe;
   - `positions` es un objeto con **exactamente** los ids de personaje del caso, y cada valor es un entero en `[0, size²)` sin repetir;
   - `clientElapsedMs` es un entero entre 0 y 24 h.

   Si algo falla: `invalid-argument` o `not-found`.
2. **Límite de intentos:** más de `maxSubmitsPerMinute` envíos por usuario y caso en 60 s da `resource-exhausted`.
3. **Comparación con `caseSolutions`:**
   - **Correcto.** Guarda `solved`, `solvedAt`, `serverElapsedMs` (= solvedAt − startedAt, solo si hay `startedAt`), `clientElapsedMs` y `ranked` (= `startedOnline` y que exista `startedAt`). Devuelve `{result: "solved", murdererId, lethalWeaponId (o null), ranked}`.
   - **Incorrecto.** Suma 1 a `errors` y devuelve `{result: "wrong", wrongCount}`. `wrongCount` es la cantidad de personajes fuera de su casilla, igual que hoy en `game_controller.dart`.
   - **Nunca** devuelve la solución ni qué casillas fallan.
4. **Caso ya resuelto:** devuelve `{result: "solved"}` con los mismos datos y no cambia nada.
5. **App Check:** se exige con un parámetro `ENFORCE_APP_CHECK`, que vale `true` por defecto y `false` en el emulador (`.env.local`).

## Publicación de casos

- `backend/scripts/publish-cases.ts` lee `app/assets/cases/mansion-*.json` y `reto-*.json`.
- El banco `caso-*` y el tutorial no se publican: siguen validando en el teléfono (ADR-0016).
- De cada archivo escribe `cases/{id}` sin `solution` y `caseSolutions/{id}`.
- Por defecto apunta al emulador. Para un proyecto real hace falta `--project <id>`, y eso no se usa en esta ronda.

## Pruebas (deben pasar todas)

- **Unitarias** de la comparación y de la validación de la entrada, sin emulador: tablero correcto, tablero incorrecto (conteo exacto), ids que faltan, ids de más, valores fuera de rango, repetidos, tipos incorrectos y objetos enormes.
- **Reglas** con `@firebase/rules-unit-testing`:
  - `caseSolutions` no se puede leer ni escribir con o sin sesión;
  - `cases` se lee con sesión y no se escribe;
  - el progreso propio se lee y el ajeno no;
  - nadie escribe el progreso desde el cliente.
- **Integración** con `firebase emulators:exec`: publicar los 40 casos y llamar a `startCase` y `submitSolution` con un usuario anónimo del emulador de Auth. Casos: correcto, incorrecto, límite de intentos y que la respuesta nunca contenga la clave `positions` de la solución ni la palabra `solution`.

## Pendiente de decisión (para Alejandro, no bloquea la 5A.1)

- **El reloj del ranking.** La decisión 10 del ADR-0012 (el reloj se pausa al salir) "se revisa antes de la etapa 5". El servidor no puede ver las pausas, así que la 5A.1 guarda los dos tiempos: el del servidor y el que informa el teléfono. La regla del ranking se decide en la 5B.

## Cambios tras la auditoría de seguridad (07-11-2026)

La auditoría la hizo el agente `seguridad` y no encontró nada crítico. Ningún camino lleva la solución al cliente. Se corrigió en la 5A.1:

- **`ranked` lo decide el servidor.** Si se intenta resolver antes de `startCase`, el caso queda `rankable: false` para siempre. `startedOnline` solo puede bajar `ranked`, nunca subirlo. Si el reloj del teléfono supera al del servidor por más de 5 s, el progreso se marca `suspicious`.
- **`submissionId`, obligatorio.** Un reenvío desde la cola "por validar" no suma otro error.
- **App Check** queda forzado fuera del emulador, con una prueba que lo vigila.
- **Datos:**
  - `maxSubmitsPerMinute` acotado entre 1 y 60;
  - los ids empiezan por letra o número;
  - cada caso publicado lleva `version`;
  - `predeploy` compila las funciones antes de desplegar.

### Condiciones de entrada de la 5B y del primer despliegue

- **Puerta del reto diario.** El servidor no entrega ni valida un `reto-*` antes de su fecha local, según la regla de la pregunta 7.
- **Vidas.** El servidor se niega a validar con 0 vidas y pone un tope diario de errores por usuario y caso. El `wrongCount` permite adivinar un 6×6 en unos 17 envíos, y crear usuarios anónimos es gratis.
- **Consola de Firebase.** Activar la exigencia de App Check también en Firestore y en Auth, poner la alerta de presupuesto y dar de baja las cuentas anónimas inactivas.
- **Borrado.** Al eliminar la cuenta, borrar también `users/{uid}` (doc 15).
- **Regla del reloj del ranking.** Pendiente de Alejandro: la pausa al salir (ADR-0012, decisión 10) frente al tiempo del servidor.
- **Dependencias.** Revisar `npm audit` antes de desplegar: hoy hay 6 vulnerabilidades moderadas, transitivas de `firebase-admin`.

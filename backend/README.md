# Backend de Enigmatrix (etapa 5A.3, solo emulador hasta el despliegue)

Cloud Functions de 2.ª generación (TypeScript, Node 22, región `southamerica-east1`) y reglas de Firestore. Todo corre en el **emulador local**: no hay proyecto real de Firebase ni hace falta iniciar sesión. El id de proyecto `demo-enigmatrix` (prefijo `demo-`) le dice al emulador que no use nada real.

Diseño: `production/planes/2026-11-07-etapa-5a-diseno.md`. Decisión: `docs/adr/0016-validacion-en-servidor-y-partida-sin-conexion.md`.

## Qué hace

Todas son `onCall`, región `southamerica-east1`, con sesión obligatoria y App Check exigido fuera del emulador. Los errores van en español.

- `getDailyChallenge({localDate})` -> `{localDate, caseId}`: el reto que toca ese día (`reto-001` a `reto-030`, en ciclo desde `dailyStartDate`). Solo usuarios registrados.
- `startCase({caseId, localDate?})` -> `{startedAt}`: anota con la hora del servidor cuándo empezó el jugador el caso. `localDate` es obligatorio en los `reto-*`. El primer `startCase` fija `startedAt`; reabrir no lo reinicia. Si el progreso de un reto es de otra fecha (el reto vuelve a tocar a los 30 días), se reinicia.
- `submitSolution({caseId, positions, clientElapsedMs, startedOnline, submissionId, localDate?})`: valida la entrada, limita los intentos y compara con la solución. Responde `solved` (con asesino y arma) o `wrong` (con cuántos personajes no cuadran). **Nunca devuelve la solución ni qué casillas fallan.**
  - En un reto resuelto suma `serverElapsedMs`, `errors`, `score` y `rank` (puesto del día, o `null` si no entró al ranking).
  - `score = serverElapsedMs + errors x errorPenaltyMs` (30 000 ms por defecto). Gana el menor; con empate, quien resolvió antes (`solvedAt` más antiguo).
  - El reto solo se entrega y se valida el día que le corresponde: `localDate` debe ser la fecha actual en algún huso de UTC-12 a UTC+14 (si no, `failed-precondition`) y el reto debe ser el de esa fecha.
  - Tope de errores: al llegar a `maxWrongPerCase` (15 por defecto) por usuario y caso, responde `resource-exhausted` y el reto ya no entra al ranking.
  - `submissionId` (obligatorio): texto de 8 a 64 caracteres `[A-Za-z0-9_-]` que el teléfono genera una vez por envío y **repite tal cual en los reintentos**. El servidor guarda en el progreso los últimos 20 (`lastSubmissions`) con la respuesta dada; si llega uno repetido, devuelve exactamente la misma respuesta sin sumar intento ni error ni gastar el límite por minuto. Las respuestas de error no se guardan.
  - `ranked` lo decide solo el servidor: es verdadero si el progreso es rankeable (`rankable` distinto de `false`), existe `startedAt` y `startedOnline` es `true`. Un envío sin `startedAt` marca el progreso con `rankable: false` para siempre.
  - Entra al ranking (`dailyRankings/{localDate}/entries/{uid}`) el reto de hoy resuelto con `ranked` y un usuario con apodo.
  - Al resolver se guarda `suspicious: true` si `clientElapsedMs` supera el tiempo del servidor en más de `clientClockMarginMs` (5000 por defecto).
- `setNickname({nickname})` -> `{nickname}` ya limpio: de 3 a 16 caracteres tras recortar espacios; solo letras latinas con tildes y ñ, números, espacio, `.`, `-` y `_`; con al menos una letra o número; sin groserías (lista es/en en `functions/src/profanity.json`). No tiene que ser único. Actualiza (o crea, si ya había resuelto el reto) las entradas de ranking del usuario. Solo usuarios registrados.
- `deleteAccount({})` -> `{deleted: true}`: borra `users/{uid}` con sus subcolecciones, sus entradas de ranking y el usuario de Auth.
- `dailyCleanup` (programada, todos los días 03:00 `America/Bogota`): borra los rankings de más de 30 días y las cuentas con `lastSeenAt` de hace más de 12 meses. `lastSeenAt` se actualiza en cada llamada.
- **Invitados** (sesión anónima): solo juegan los casos de `freeCaseIds` (por defecto `mansion-01` y `mansion-02`; el tutorial corre en el teléfono). Cualquier otro caso, los `reto-*`, `getDailyChallenge` y `setNickname` responden `failed-precondition` con "Regístrate para seguir jugando." Al registrarse Firebase conserva el uid, así que el progreso se mantiene.
- `config/server` (solo Admin), todo opcional: `maxSubmitsPerMinute` (entero, 1 a 60; 6), `maxWrongPerCase` (1 a 1000; 15), `errorPenaltyMs` (0 a 24 h; 30000), `dailyStartDate` (`AAAA-MM-DD`; `2026-11-16`), `freeCaseIds` (lista de ids; `["mansion-01","mansion-02"]`), `clientClockMarginMs` (>= 0; 5000).
- **Las soluciones no están en Firestore.** `scripts/build-solutions.ts` lee `tools/data/casos-servidor/mansion-*.json` y `reto-*.json` (los casos completos; los de `app/assets/cases` ya no llevan `solution`) y genera `functions/data/solutions.json` (fuera de git), que las funciones leen. Se genera antes de compilar, de las pruebas y en `predeploy`. Las colecciones `cases` y `caseSolutions` ya no existen.

## Datos en Firestore

| Ruta | Contenido | Lectura desde el cliente |
|---|---|---|
| `users/{uid}` | `createdAt`, `lastSeenAt`, `nickname` | Solo el dueño |
| `users/{uid}/progress/{caseId}` | Progreso del caso (`localDate`, `score` y `rank` en los retos) | Solo el dueño |
| `dailyRankings/{localDate}/entries/{uid}` | `uid`, `nickname`, `serverElapsedMs`, `errors`, `score`, `solvedAt` | Cualquier usuario con sesión (consulta por `score` y `solvedAt` ascendente, máximo 50) |
| `config/server` | Valores del servidor | Nadie |

Escribir desde el cliente está denegado en todo. El índice `entries` (`score`, `solvedAt`) está en `firestore.indexes.json`.

## Requisitos

- Node 22 o superior y npm.
- Firebase CLI (`firebase --version`; probado con 15.10).
- **Java 21 o superior** para los emuladores (el CLI 15 ya no acepta Java 17). Antes de correr algo con emuladores:

```sh
export JAVA_HOME="C:/Program Files/Java/jdk-21.0.10.7-hotspot"
export PATH="/c/Program Files/Java/jdk-21.0.10.7-hotspot/bin:$PATH"
```

## Instalar

```sh
cd backend
npm install
npm --prefix functions install
```

## Levantar el emulador

```sh
npm run build                       # compila functions/ a functions/lib/
firebase emulators:start --project demo-enigmatrix
```

Puertos: Auth 9099, Firestore 8080, Functions 5001. En el emulador App Check está apagado (`functions/.env.local` pone `ENFORCE_APP_CHECK=false`); fuera del emulador queda forzado a `true` en el código (`functions/src/appcheck.ts`) y no se puede apagar con ningún parámetro. `firebase.json` compila las funciones antes de desplegar (`predeploy`).

## Generar las soluciones

```sh
npm run build:solutions     # escribe functions/data/solutions.json (40 casos)
```

No hace falta con `npm run build`, `npm test` ni `firebase deploy`: los tres lo hacen solos. No publica nada en Firestore ni necesita credenciales.

## Pruebas

```sh
npm test
```

Corre todo, en este orden:

1. **Unitarias** (`npm run test:unit`): genera las soluciones y prueba validación, fechas del reto, apodos y filtro, lector de soluciones, retención y reglas de invitados, sin emulador.
2. **Reglas e integración** (`npm run test:emulator`): compila, levanta los emuladores con `firebase emulators:exec` y prueba las reglas de Firestore y las funciones (puerta del reto, ranking, tope de errores, apodo, invitados, borrado de cuenta, limpieza, entrada maliciosa y que ninguna respuesta filtre la solución).

## Estructura

```
firebase.json, .firebaserc, firestore.rules, firestore.indexes.json
functions/src/validation.ts   lógica pura (sin Firebase)
functions/src/daily.ts        fechas locales, puerta y reto del día
functions/src/nickname.ts     reglas del apodo y filtro (datos en profanity.json)
functions/src/solutions.ts    lector de functions/data/solutions.json
functions/src/cleanup.ts      borrado de cuenta y limpieza por retención
functions/src/appcheck.ts     App Check forzado fuera del emulador
functions/src/index.ts        las funciones
scripts/build-solutions.ts    genera functions/data/solutions.json (fuera de git)
test/unit, test/rules, test/integration
```

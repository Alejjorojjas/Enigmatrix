# Backend de Enigmatrix (etapa 5A.1, solo emulador)

Cloud Functions de 2.ª generación (TypeScript, Node 22, región `southamerica-east1`) y reglas de Firestore. Todo corre en el **emulador local**: no hay proyecto real de Firebase ni hace falta iniciar sesión. El id de proyecto `demo-enigmatrix` (prefijo `demo-`) le dice al emulador que no use nada real.

Diseño: `production/planes/2026-11-07-etapa-5a-diseno.md`. Decisión: `docs/adr/0016-validacion-en-servidor-y-partida-sin-conexion.md`.

## Qué hace

- `startCase({caseId})`: anota con la hora del servidor cuándo empezó el jugador el caso.
- `submitSolution({caseId, positions, clientElapsedMs, startedOnline, submissionId})`: valida la entrada, limita los intentos y compara con la solución. Responde `solved` (con asesino y arma) o `wrong` (con cuántos personajes no cuadran). **Nunca devuelve la solución ni qué casillas fallan.**
  - `submissionId` (obligatorio): texto de 8 a 64 caracteres `[A-Za-z0-9_-]` que el teléfono genera una vez por envío y **repite tal cual en los reintentos**. El servidor guarda en el progreso los últimos 20 (`lastSubmissions`) con la respuesta dada; si llega uno repetido, devuelve exactamente la misma respuesta sin sumar intento ni error ni gastar el límite por minuto. Las respuestas de error (p. ej. `resource-exhausted`) no se guardan: reintentar con el mismo id vuelve a evaluarse.
  - `caseId` y los ids de personaje empiezan por letra o número (luego letras, números, `-` y `_`).
  - `ranked` lo decide solo el servidor: es verdadero si el progreso es rankeable (`rankable` distinto de `false`), existe `startedAt` (puesto por `startCase`) y `startedOnline` es `true`. Un envío que llega sin `startedAt` marca el progreso con `rankable: false` para siempre; `startedOnline` solo puede bajar `ranked`, nunca subirlo.
  - Al resolver se guarda `suspicious: true` si `clientElapsedMs` supera el tiempo del servidor en más de `clientClockMarginMs` (5000 por defecto).
- `config/server` (solo Admin) admite `maxSubmitsPerMinute` (entero, se acota entre 1 y 60; por defecto 6) y `clientClockMarginMs` (entero >= 0; por defecto 5000).
- Cada documento publicado (`cases/{id}` y `caseSolutions/{id}`) lleva `version`: hash SHA-256 corto (16 hex) del JSON público + la solución.
- La solución vive en `caseSolutions/{id}`, que las reglas no dejan leer ni escribir a ningún cliente.

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

## Publicar los casos en el emulador

Con el emulador levantado, en otra terminal:

```sh
npm run publish:cases
```

Publica los 40 casos (`mansion-*` y `reto-*`) leyendo `app/assets/cases/`: el caso público (sin `solution`) en `cases/{id}` y la solución en `caseSolutions/{id}`. No publica `caso-*` ni el tutorial. Solo toca un proyecto real si se le pasa `--project <id>` con un id que no empiece por `demo-`; no se usa en esta ronda.

## Pruebas

```sh
npm test
```

Corre todo, en este orden:

1. **Unitarias** (`npm run test:unit`): validación de la entrada y comparación, sin emulador.
2. **Reglas e integración** (`npm run test:emulator`): compila, levanta los emuladores con `firebase emulators:exec`, publica los casos y prueba las reglas de Firestore y las funciones (correcto, incorrecto, límite de intentos, entrada maliciosa y que ninguna respuesta filtre la solución).

## Estructura

```
firebase.json, .firebaserc, firestore.rules, firestore.indexes.json
functions/src/validation.ts   lógica pura (sin Firebase)
functions/src/appcheck.ts     App Check forzado fuera del emulador
functions/src/index.ts        startCase y submitSolution
scripts/publish-cases.ts      publicación en dos partes
test/unit, test/rules, test/integration
```

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

## Ronda 5A.2: la app se conecta (07-11-2026)

**Decisión del arquitecto (reversible).** Todavía no existe el proyecto real de Firebase. Si la app dependiera hoy del servidor, el APK de Alejandro dejaría de validar. Por eso el servidor queda detrás de una bandera de compilación:

| `--dart-define=ENX_BACKEND=` | Qué hace |
|---|---|
| `none` (por defecto) | Igual que hoy: valida en el teléfono con la solución local (excepción de la Fase 1). No arranca Firebase ni usa la red. |
| `emulator` | Valida con el emulador. El host se pasa con `ENX_EMULATOR_HOST` (por defecto `localhost` en web y `10.0.2.2` en el emulador de Android). Usa el proyecto `demo-enigmatrix` con `FirebaseOptions` escritas a mano, sin `google-services.json`. |
| `firebase` | Proyecto real. Se activa en la ronda de corte, cuando Alejandro cree el proyecto. |

**Ronda de corte (5A.3, después).** Con el proyecto real se hacen cuatro cosas: el valor por defecto pasa a `firebase`, los JSON de `mansion-*` y `reto-*` dejan de llevar `solution`, `tools/` publica en dos partes y caduca la excepción del principio 2.

**Qué hace la app en modo servidor:**
- **Sesión.** Al arrancar inicia una sesión anónima con Firebase Auth. Sin red, sigue y lo reintenta más tarde.
- **Casos.** Siguen incluidos en la app, así que se juega sin conexión desde el primer día.
- **Inicio de partida.** Llama a `startCase` al empezar un caso de la campaña o del reto si hay red. Si no hay red, no pasa nada, pero esa partida no entra al ranking (ADR-0016, punto 5).
- **Resolver.** Llama a `submitSolution` con un `submissionId` nuevo por envío.
  - Si no hay red, el envío queda en una cola guardada en `shared_preferences` y el caso queda "por validar". La cola se reintenta al volver a la app, al recuperar la red y cada cierto tiempo, siempre con el mismo `submissionId`.
  - Si la respuesta es `wrong`, se muestra cuántas casillas no cuadran, como hoy, con el bloqueo.
  - Si la respuesta es `solved`, va a la victoria con el asesino y el arma que manda el servidor.
- **Casos locales.** El tutorial y el banco `caso-*` validan siempre en el teléfono.

### Condiciones de entrada de la ronda de corte 5A.3

Vienen de la revisión de seguridad del cliente, 07-11-2026:

- **App Check en la app.** Agregar `firebase_app_check`, con Play Integrity para la tienda y el proveedor de depuración para los APK de prueba. Sin él, el servidor real rechaza todo, porque exige App Check fuera del emulador.
- **Privacidad.** Con Auth anónimo hay un id de usuario y la IP llega a Google. Antes del primer build con `firebase` hay que actualizar la política de privacidad, los docs 15 y 20 y el formulario de Seguridad de datos de Play. Al borrar la cuenta también se limpian `pending:submissions`, `started:*`, `done:*` y `game:*`.
- **Permisos.** Revisar el manifiesto fusionado del APK, porque los paquetes de Firebase pueden sumar el permiso INTERNET aunque el modo sea `none`. Si lo suman, corregir los docs 15 y 20.
- **Quitar `solution` de los assets.** Hoy `PuzzleCase.fromJson` exige la solución (`tools/lib/src/puzzle_case.dart`). Hace falta un tipo de caso sin solución para el cliente, o que la solución sea opcional.
- **Banco de pruebas.** Decidir si el banco `caso-*` sale del release.
- **Progreso de la Fase 1.** El `done:` local de la Fase 1 no se migra al servidor: son datos sin verificar.
- **Ranking.** Usar siempre `serverElapsedMs` y `errors` del servidor, nunca los de la cola local.

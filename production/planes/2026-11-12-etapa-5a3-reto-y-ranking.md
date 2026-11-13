# Ronda 5A.3: servidor real, reto diario y ranking con apodo

- **Fecha:** 12-11-2026
- **Base:**
  - `production/planes/2026-11-07-etapa-5a-diseno.md`, cuyas condiciones de entrada de la 5A.3 siguen vigentes;
  - ADR-0016;
  - ADR-0014, decisiones del 12-11-2026.
- **Proyecto real:** `murdoku-diario`, plan Blaze, Firestore `(default)` en `southamerica-east1`, App Check registrado. La aplicación obligatoria (Enforce) en la consola sigue apagada.
- **Rama:** `feature/firebase-real`. Nada se despliega ni se sube a tiendas en esta ronda sin que Alejandro lo apruebe.

## Decisiones de Alejandro (12-11-2026)

1. **Reloj del ranking: tiempo del servidor.**
   - Se mide desde el `startedAt` de `startCase` hasta la resolución correcta, sin pausas.
   - Antes de empezar el reto, la app avisa que el reloj no se detiene.
   - Con esto se resuelve la pregunta pendiente del ADR-0012, decisión 10: en los retos con ranking manda el servidor. La campaña sin ranking puede seguir pausando su reloj local.
2. **Orden del ranking.** `score = serverElapsedMs + errors × 30 000 ms` (30 s por error). Gana el menor score; si hay empate, gana quien resolvió primero (`solvedAt` más antiguo). La penalización va en config: `errorPenaltyMs`, por defecto 30000.
3. **Apodo al abrir la app la primera vez.**
   - Se pide antes de entrar al inicio. Se puede cambiar después en Configuración.
   - Reglas:
     - de 3 a 16 caracteres después de quitar espacios a los lados;
     - solo letras (con tildes y ñ), números, espacio, punto, guion y guion bajo;
     - filtro de groserías en español e inglés;
     - no tiene que ser único.
4. **Correo de privacidad:** murdokudiario@gmail.com.
5. **Registro obligatorio, decidido el mismo día.** Esta decisión **reemplaza al punto 3 en cuándo se pide el apodo**.
   - **Sin cuenta:** el invitado, con sesión anónima, juega el tutorial y los 2 primeros casos de La Mansión.
   - **Con cuenta:** el resto de la campaña y el reto diario exigen registrarse.
   - **Métodos de registro:**
     - Google, en Android e iPhone;
     - Apple, en iPhone;
     - correo y contraseña, con verificación del correo y "olvidé mi contraseña".
   - **Progreso:** la cuenta de invitado se vincula a la registrada, conserva el mismo uid y no pierde lo jugado.
   - **Apodo:** se pide justo después de registrarse.
   - **Servidor:** exige que el proveedor de la sesión no sea `anonymous` para los casos que no son gratis, para el reto y para `setNickname`. La lista de casos gratis va en `config/server.freeCaseIds`.

## Decisiones del arquitecto (reversibles)

- **Soluciones dentro de las funciones, sin publicar en Firestore.**
  - Las funciones leen las soluciones de un JSON que se genera al compilar (`backend/functions/data/solutions.json`, fuera de git). Lo produce un script desde los casos completos.
  - Así el despliegue es solo `firebase deploy`, sin credenciales de administrador ni script de publicación contra el proyecto real.
  - El cliente ya trae los casos públicos dentro de la app, así que `cases/{id}` deja de ser necesario. La colección `caseSolutions` se retira.
- **Qué reto toca cada día.**
  - `índice = (díasEntre(dailyStartDate, localDate) mod 30) + 1`, que da `reto-001` a `reto-030`, en ciclo.
  - `dailyStartDate` va en `config/server`; si no existe, el valor por defecto en el código es `2026-11-16`.
  - La app usa la misma fórmula sin conexión, pero la partida sin conexión no entra al ranking.
- **Fecha local, según la pregunta 7: medianoche local de cada jugador.**
  - El cliente envía `localDate` en formato `YYYY-MM-DD`.
  - El servidor la acepta solo si es la fecha actual en algún huso entre UTC−12 y UTC+14; si no, devuelve `failed-precondition`.
  - Un `reto-*` solo se entrega y se valida en el día que le corresponde (puerta del reto diario).
- **Intento oficial.** El primer `startCase` del reto del día fija `startedAt`. Reabrir no lo reinicia.
- **Tope de errores.**
  - `maxWrongPerCase` (por defecto 15) cuenta por usuario y caso.
  - Al llegar al tope, `submitSolution` responde `resource-exhausted` con un mensaje claro y el reto ya no entra al ranking.
  - Reemplaza las vidas del servidor en la V1, donde las vidas no se muestran.
- **Retención.**
  - Las entradas del ranking se borran a los 30 días.
  - Las cuentas sin uso por 12 meses se eliminan: `lastSeenAt` se actualiza en cada llamada.
  - Las dos limpiezas las hace una función programada diaria.

## Contrato del servidor (lo implementa `backend`; lo usa `frontend`)

Todas las funciones son `onCall`, región `southamerica-east1`, con sesión obligatoria y App Check exigido fuera del emulador. Los errores usan `HttpsError` con mensaje en español.

| Función | Entrada | Salida |
|---|---|---|
| `getDailyChallenge` | `{localDate}` | `{localDate, caseId}` |
| `startCase` | `{caseId, localDate?}`. `localDate` es obligatorio si `caseId` empieza por `reto-` | `{startedAt}` en ms desde la época |
| `submitSolution` | Lo de hoy (`caseId, positions, clientElapsedMs, startedOnline, submissionId`) más `localDate?` para los retos | Lo de hoy. Si es reto y está resuelto: además `serverElapsedMs, errors, score, rank` (puesto del día, o `null` si no entró al ranking) |
| `setNickname` | `{nickname}` | `{nickname}`, ya limpio. `invalid-argument` con el motivo si no cumple las reglas |
| `deleteAccount` | `{}` | `{deleted: true}`. Borra `users/{uid}` con sus subcolecciones, sus entradas de ranking y el usuario de Auth |

**Datos en Firestore**

| Ruta | Contenido | Lectura desde el cliente |
|---|---|---|
| `users/{uid}` | `createdAt`, `lastSeenAt`, `nickname` | Solo el dueño |
| `users/{uid}/progress/{caseId}` | Lo de hoy | Solo el dueño |
| `dailyRankings/{localDate}/entries/{uid}` | `uid`, `nickname`, `serverElapsedMs`, `errors`, `score`, `solvedAt` | Cualquier usuario con sesión. Se consulta por `score` ascendente, máximo 50 |
| `config/server` | `maxSubmitsPerMinute`, `maxWrongPerCase`, `errorPenaltyMs`, `dailyStartDate` | Nadie |

Escribir desde el cliente está denegado en todo.

**Cuándo entra un reto al ranking:** cuando se resuelve el reto de su día, con `ranked` en verdadero y el usuario con apodo. Si el jugador pone el apodo después, `setNickname` actualiza sus entradas.

## Reparto

### B1: `backend`, solo `backend/`

1. **Soluciones desde el JSON generado.**
   - El script `backend/scripts/build-solutions.ts` lee `app/assets/cases/mansion-*.json` y `reto-*.json` y escribe `functions/data/solutions.json`.
   - Va en `predeploy` y antes de las pruebas.
   - Se retira la lectura de `caseSolutions` y el uso de `cases/{id}`. Para validar el caso basta con su presencia en el JSON y sus ids de personaje.
2. **Funciones:**
   - las nuevas, `getDailyChallenge`, `setNickname` y `deleteAccount`;
   - los cambios a `startCase` y `submitSolution`;
   - la función programada de limpieza;
   - el filtro de groserías en un archivo de datos aparte.
3. **Reglas** de `dailyRankings` y retiro de `cases` y `caseSolutions`. El índice que haga falta va en `firestore.indexes.json`.
4. **Pruebas.** Unitarias y de emulador para todo lo nuevo:
   - la puerta del reto (día anterior, día siguiente, fecha inválida);
   - el score y el empate;
   - el tope de errores;
   - el apodo (válidos, inválidos, groserías);
   - el ranking (entra, no entra sin apodo, se actualiza con `setNickname`);
   - el borrado de cuenta;
   - la limpieza.

   Las 95 pruebas actuales se adaptan, sin borrarlas a la ligera.
5. `npm audit`: informar sin forzar actualizaciones mayores.

### F1: `frontend`, solo `app/` (sin `app/assets/`) y los workflows de `.github/`

1. **App Check.**
   - Agregar `firebase_app_check`.
   - Release: Play Integrity en Android y App Attest en iOS. Debug: el proveedor de depuración.
   - Agregar `Runner.entitlements` con `com.apple.developer.devicecheck.appattest-environment = production` y referenciarlo en el proyecto de Xcode.
2. **Modo `firebase`.**
   - `Firebase.initializeApp()` usa los archivos nativos: el plugin `com.google.gms.google-services` en Gradle y `GoogleService-Info.plist` agregado al target Runner en `project.pbxproj`.
   - Los dos archivos están fuera de git.
   - **El valor por defecto de `ENX_BACKEND` sigue en `none` en esta ronda.** Pasa a `firebase` en el corte, tras desplegar.
3. **CI.**
   - Los workflows de Android e iOS escriben los dos archivos desde los secretos `GOOGLE_SERVICES_JSON_B64` y `GOOGLE_SERVICE_INFO_PLIST_B64`.
   - Si el secreto falta, el paso falla con un mensaje claro. No se imprime su contenido.
4. **Apodo.**
   - Pantalla de apodo en el primer arranque con modo servidor, con las mismas reglas que el servidor; el servidor tiene la última palabra.
   - Sin conexión se guarda localmente y se envía después.
   - En Configuración: "Cambiar apodo" y "Borrar mi cuenta y mis datos", que confirma, llama a `deleteAccount` y limpia las claves locales (`pending:submissions`, `started:*`, `done:*`, `game:*` y el apodo).
5. **Pruebas** de widget y de unidad de lo nuevo, con el cliente simulado. Ninguna prueba debe necesitar red.

### F2, después de B1 y F1: reto y ranking en la app

- La pantalla Reto real reemplaza la DEMO. Muestra el aviso de que el reloj no se pausa y el tiempo según `startedAt`.
- La pestaña Ranking muestra el ranking real del día: los 50 primeros y la fila propia. Se ve en la build de tienda cuando el modo es servidor.
- La victoria muestra el tiempo del servidor, los errores, el score y el puesto.

### Corte, después de F2 (arquitecto y Alejandro)

- Quitar `solution` de los assets de `mansion-*` y `reto-*`. La fuente completa queda para `build-solutions`.
- `ENX_BACKEND` pasa a `firebase` por defecto.
- Alejandro corre `firebase login` una vez y se despliega.
- Prueba en el teléfono instalando desde la prueba interna.
- Se activa Enforce de App Check en la consola.
- Se publica la política y se actualizan los formularios de las tiendas.

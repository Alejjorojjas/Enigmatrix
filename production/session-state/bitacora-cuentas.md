# Bitácora entre cuentas

Cada sesión anota aquí lo que hizo, de lo más reciente arriba a lo más antiguo, con este formato:

```
## dd-mm-yyyy · cuenta (principal / secundaria)
- Qué se hizo:
- Archivos tocados:
- Commit(s):
- Pruebas (números):
- Pendiente o dudas para la otra cuenta:
```

## 09-11-2026 · cuenta secundaria · Google Play con GitHub Actions (ADR-0017)

- **Pedido de Alejandro:** que cada push a `main` se suba solo a Google Play. Después irán App Store y las demás tiendas.
- **Qué se hizo:**
  - **Workflow `.github/workflows/android-play.yml`.** Corre las pruebas de tools y de la app, compila el `.aab` firmado (sin `ENX_DEV` y con `ENX_BACKEND=none`) y lo guarda como artefacto. Con `PLAY_UPLOAD=true` lo sube a la prueba interna.
    - `versionCode` = 10000 + número de run.
    - Si faltan los secretos de la llave, falla. También falla si el `.aab` sale firmado con la llave de depuración.
  - **ADR-0017** y la guía `production/guias/2026-11-09-google-play-github-actions.md`. La guía tiene los pasos de Alejandro: secretos de la llave, crear la app, primera subida manual, cuenta de servicio y variables.
- **El arquitecto no leyó ni tocó la llave ni `key.properties`.** Los secretos los carga Alejandro.
- **Pruebas:** sin cambios de código; `dart analyze` del motor está limpio.
- **Regla nueva de Alejandro:** desde la primera subida a Play, todo cambio va en una rama y un PR, y solo llega a `main` cuando él lo aprueba. El workflow ahora también corre en los PR (pruebas y AAB, sin subir) y la subida a Play solo ocurre desde `main`. Anotado en `TRASPASO.md`.
- **Nombre (decisión de Alejandro):** la app se llama **"Murdoku Diario"** en la tienda, debajo del ícono, en la carga y en Configuración. El paquete pasa a `com.murdokudiario.app`, y ese cambio es permanente desde la primera subida. Se le avisó que "Murdoku" es una marca de libros (Manuel Garand) y que ya hay una app con ese nombre en la App Store; dijo que no hay problema.
  - Se cambiaron `appTitle` y `settingsVersion` en el `.arb`, la etiqueta de Android, el `applicationId`, `CFBundleDisplayName`, la web, el workflow y las pruebas.
  - La versión pasa a 0.8.1+11. App: 707 pruebas pasan; analyze limpio.
- **Decisión de Alejandro:** se publica en la cuenta de Google Play de un amigo, donde Alejandro es colaborador. Ya publicaron otras apps juntos y "está todo cuadrado". A futuro piensan separarse y se usará la transferencia de apps. Quedó anotado en el ADR-0017.
- **Pendiente:**
  - Alejandro hace los pasos 1 a 5 de la guía. El primer run fallará en "AAB firmado" hasta que existan los secretos; las pruebas sí corren.
  - Antes de la prueba cerrada: ocultar las pantallas simuladas (pregunta 18), privacidad y ficha.

## 07-11-2026 · cuenta secundaria · etapa 5A.2: la app se conecta al servidor (0.8.0+10)

- **Qué se hizo:**
  - **Bandera `ENX_BACKEND`** (decisión del arquitecto, reversible):
    - `none` es el valor por defecto: la app valida en el teléfono, sin Firebase ni red. Así los APK de Alejandro siguen funcionando mientras no exista el proyecto real.
    - `emulator` es para pruebas. En release se convierte en `none`, así que para probar en web hay que compilar con `--profile`.
    - `firebase` queda para la ronda de corte 5A.3.
  - **App (`frontend`):** `app/lib/src/backend/` con Auth anónimo, cliente de las funciones y cola "por validar" guardada, con `submissionId` y reintentos. Además:
    - mensajes "Sin conexión…", "Demasiados intentos…" y envío detenido con Reintentar o Cancelar;
    - marca "Por validar" en la lista de casos.
    - El tutorial y el banco `caso-*` siguen validando en el teléfono. Paquetes nuevos: firebase_core, firebase_auth y cloud_functions.
  - **QA independiente:** RECHAZÓ la primera versión por 2 bugs al salir de la partida mientras se valida. Se corrigieron y sus 8 pruebas pasan.
  - **Seguridad:** sin hallazgos críticos. Se corrigieron en la ronda:
    - `submit` ya no se bloquea;
    - los errores del servidor tienen tope de reintentos;
    - el modo `emulator` no funciona en release;
    - `solve()` local no se puede usar con casos del servidor;
    - una partida empezada antes del servidor no entra al ranking.

    Lo demás quedó como condición de entrada de la 5A.3 en el diseño: App Check en la app, privacidad y Seguridad de datos, y el permiso INTERNET.
  - **Verificación del arquitecto en web contra el emulador:**
    - mansion-01 se resolvió y el servidor la guardó resuelta y rankeada (22 s del servidor y 21 s del teléfono);
    - mansion-03 se resolvió sin red: quedó "por validar" y el reintento a los 60 s la validó;
    - mansion-07, abierta desde Inicio, registró startedAt.

    Encontré y se corrigieron dos cosas: la sesión no se esperaba antes de `startCase`, y reintentar `startCase` justo antes de Resolver daba un tiempo oficial casi cero.
  - **Limitación conocida (solo web):** al recargar directamente en `#/play/<id>`, el aviso de inicio puede no salir. En Android siempre se entra por Inicio.
- **Pruebas:** app 707 (antes 627) y backend 95, todas pasan; analyze limpio. Las corrió el arquitecto.
- **Versión:** 0.8.0+10.
- **APK:** `APKs/enigmatrix-0.8.0+10-arm64.apk` (y `-armeabi-v7a`), con `ENX_DEV=true` y el modo `none`. Firma igual (SHA-256 659f…84df).
  - Para compilar con Firebase hubo que subir Kotlin a 2.4.0 (firebase-auth 25 lo exige), pasar `jvmTarget` a `compilerOptions` y poner `kotlin.incremental=false`. Kotlin 2.4 falla en Windows con el proyecto en D: y el pub-cache en C:.
  - **Permisos confirmados (hallazgo M1 de seguridad):** el APK ya pide `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `READ_GSERVICES` y `c2dm.RECEIVE`. Los suman las librerías de Firebase aunque el modo `none` no use la red. Los docs 15 y 20 (y la política de privacidad) dicen "sin INTERNET" y hay que corregirlos en la 5A.3, junto con el formulario de Seguridad de datos.
- **Pendiente o dudas para la otra cuenta:**
  - la 5A.3 (proyecto real de Firebase de Alejandro y las condiciones del diseño);
  - el aviso `params.ENFORCE_APP_CHECK.value() invoked during function deployment` del emulador, que es inofensivo pero conviene revisarlo.

## 07-11-2026 · cuenta secundaria · etapa 5A.1: servidor en el emulador

- **Qué se hizo:**
  - **Diseño:** el arquitecto escribió `production/planes/2026-11-07-etapa-5a-diseno.md`, con los datos en Firestore, las funciones `startCase` y `submitSolution`, la publicación de casos y las pruebas.
  - **Backend (`backend`, Sonnet, activo desde hoy):**
    - `backend/` con Firebase solo en el emulador (`demo-enigmatrix`);
    - reglas de Firestore: `caseSolutions` y `config` cerradas para el cliente;
    - Cloud Functions en TypeScript (Node 22, `southamerica-east1`);
    - script `scripts/publish-cases.ts`, que publica los 40 casos separados en parte pública y solución.
  - **Seguridad (`seguridad`):** auditoría sin hallazgos críticos; ningún camino lleva la solución al cliente. Se corrigieron en la misma ronda:
    - `ranked` lo decide el servidor (`rankable`, `suspicious`);
    - `submissionId` evita contar dos veces un error;
    - App Check forzado fuera del emulador;
    - topes, ids, `version` y `predeploy`.
  - **Para la 5B y el primer despliegue:** lo que no se corrigió quedó anotado en el diseño (puerta del reto por fecha, vidas, tope diario de errores, consola de Firebase, borrado de cuenta, `npm audit`).
- **Entorno:** el CLI de Firebase 15.10 exige **Java 21** para los emuladores: `C:/Program Files/Java/jdk-21.0.10.7-hotspot`. Android sigue con el JDK 17.
- **Pruebas:** backend 95 (37 unitarias y 58 en el emulador), todas pasan; las corrió el arquitecto con `npm test` en `backend/`. La app y `tools/` no cambiaron.
- **Pendiente o dudas para la otra cuenta:**
  - la 5A.2: la app con Auth anónimo, caché de casos sin solución, cola "por validar" con `submissionId`, y `tools/` publicando en dos partes;
  - que Alejandro cree el proyecto real de Firebase y active Blaze (todavía no hace falta);
  - la regla del reloj del ranking.

## 07-11-2026 · cuenta secundaria · ADR-0016 (validación en el servidor y partida sin conexión)

- **Qué se hizo:**
  - **Decisión de Alejandro:** la opción A. Sin conexión se juega y Resolver espera a que vuelva la señal.
  - **ADR:** el arquitecto escribió `docs/adr/0016-validacion-en-servidor-y-partida-sin-conexion.md` y Alejandro lo **aceptó completo** el 07-11-2026. Dice:
    - la solución solo vive en el servidor y la valida una Cloud Function;
    - el Mundo 1 se descarga por adelantado, sin solución;
    - una partida cuenta para el ranking solo si se empezó con conexión, y el reto diario exige conexión para empezar;
    - la vida se descuenta cuando el servidor valida;
    - App Check y un límite de intentos.
  - **Al día:** el plan, el roadmap y el README.
- **Pruebas:** sin cambios de código.
- **Pendiente o dudas para la otra cuenta:**
  - si el iPhone entra al lanzamiento;
  - la fecha de creación de la cuenta de Google Play.

## 06-11-2026 · cuenta secundaria · decisiones y plan de las etapas 5 y 6

- **Qué se hizo:**
  - **Decisiones de Alejandro:**
    - ya tiene pagadas las cuentas de Google Play y de Apple, y la versión web queda para la V2;
    - 17: publica como persona natural;
    - 7: el reto cambia a la medianoche local de cada jugador (no a la de Colombia, como recomendaba la auditoría);
    - 6, 8, 16, 18 y 23: acepta las recomendaciones (premium con vidas ilimitadas, víctima como ficha con †, 13 años o más, versión de revisión sin pantallas simuladas, mundos bloqueados con candado).
  - **Plan:** `production/planes/2026-11-06-etapas-5-y-6.md`, con ADR-0016 (validación en el servidor) por escribir, 5A, 5B, la etapa 6 en paralelo y las preguntas abiertas: partida sin conexión, iPhone, orden, puntos y ayudas.
  - **Pregunta 19 (arma):** estaba decidida el 05-11-2026 (ADR-0014) y se quitó de las pendientes. La política de privacidad dice ahora 13 años o más.
  - **Documentos:** `revisor-docs` aplicó las decisiones en el roadmap, los docs 03, 06, 08, 13, 15 y 20, el ADR-0014 y el README, y el arquitecto lo revisó.
- **Archivos tocados:** el plan nuevo, esos documentos y `production/session-state/`.
- **Pruebas:** sin cambios de código.
- **Pendiente o dudas para la otra cuenta:** las respuestas a la sección 4 del plan y la fecha de creación de la cuenta de Google Play (de ella depende la regla de los 12 probadores).

## 06-11-2026 · cuenta secundaria · máximo 2 del mismo mueble por habitación (0.7.2+9)

- **Qué se hizo:**
  - **Decisión de Alejandro:** como máximo 2 muebles del mismo tipo por habitación (antes, mansion-04 tenía 7 mesas). Quedó en el ADR-0015, punto 8, y en la spec 16, §1.3.1.
  - **Motor (`puzzle-engineer`):** `kMaxSameTypePerRoom = 2` en `tools/lib/src/map_rules.dart`. El generador nunca lo supera y la puerta de contenido lo rechaza. También ajustó `tools/test/qa_mapa_independiente_test.dart` para que funcione con el interruptor de regeneración.
  - **Contenido (`contenido-puzzles`):** regeneró los 40 casos y cambió 12 semillas. Se mantiene la curva (4, 6, 7 | 6, 7, 8 | 9, 10, 11, 14), el arma en 08, 09 y 10, y las 16 premisas que nombran algo siguen encajando. Hay bañera en 13 de los 40 casos.
  - **Verificación del arquitecto:** conteo propio con un máximo de 2 del mismo tipo por habitación y 0 problemas. Revisó mansion-08 en web a 360×740.
- **Commits:** `3f19bc5` (motor) y el de cierre.
- **Pruebas:** tools 342 y app 627, todas pasan; analyze limpio.
- **APK:** `APKs/enigmatrix-0.7.2+9-arm64.apk` (y `-armeabi-v7a`), con `ENX_DEV=true`.

## 05-11-2026 · cuenta secundaria · baño en la Mansión (0.7.1+8)

- **Qué se hizo:**
  - **Decisión de Alejandro:** agregar un baño a la Mansión para que aparezca la bañera.
  - **Mundo:** `tools/data/mundos/mansion.json` lleva "el Baño" (bañera, planta, alfombra).
  - **Casos:** `contenido-puzzles` regeneró los 40 casos y cambió 15 semillas para conservar la curva (4, 6, 7 | 6, 7, 8 | 9, 10, 11, 13), el arma en 08, 09 y 10, y que las premisas encajen.
  - **Cobertura:** 20 casos tienen baño y 15 tienen bañera (37,5 %).
  - **Tests:** se actualizaron 2 aserciones de `tools/test/map_rules_test.dart`, por la tabla del Mundo 1 con `bano`.
  - **Revisión:** el arquitecto miró mansion-01 en web a 360×740 y su conteo propio dio 0 problemas.
- **Archivos tocados:** `tools/data/mundos/` (los 3 archivos), los 40 JSON de `app/assets/cases/`, `tools/test/map_rules_test.dart`, el informe `production/revisiones/2026-11-05-contenido-mundo1-reglas-mapa.md` y la versión.
- **Pruebas:** tools 335 y app 627, todas pasan; analyze limpio.
- **APK:** `APKs/enigmatrix-0.7.1+8-arm64.apk` (y `-armeabi-v7a`), con `ENX_DEV=true`.
- **Ojo:** algunas pruebas de `tools/test/qa_mapa_independiente_test.dart` dependen del contenido de mansion-01, 03 y 04. Si se cambian esas semillas, pueden fallar.

## 05-11-2026 · cuenta secundaria · resultados de la prueba de juego n.º 1 → 0.7.0+7

- **Lo que trajo Alejandro de sus probadores:**
  - **Dificultad:** "está bien por ahora". Los rangos de `tools/lib/src/difficulty_ranges.dart` se mantienen.
  - **Muebles:** confundían "silla" con el sillón y el sofá.
  - **Habitaciones:** les extrañaron dos camas en una misma habitación y "una cama en una cocina".
- **Decisión de Alejandro (ADR-0015):**
  - un solo tipo por familia de muebles parecidos en cada mapa (asientos, superficies, plantas, almacenaje, electrodomésticos);
  - objetos únicos por habitación;
  - cada mueble solo en las habitaciones donde tiene sentido;
  - objetos nuevos: perchero, bañera, nevera y chimenea.
- **Qué se hizo:**
  - **Motor (`puzzle-engineer`):** `tools/lib/src/map_rules.dart`, generador, puerta de contenido y spec 16, sección 1.3.1.
  - **Dibujos (`frontend`):** los 4 objetos nuevos en las dos pieles. Además, la silla quedó de madera sin cojín, la barra con tapa de piedra y la alfombra con guarda.
  - **Contenido (`contenido-puzzles`):** regeneró los 10 casos del Mundo 1 y los 30 retos. Cambió semillas en 6 casos y 3 retos para conservar la curva (4, 6, 8 | 6, 7, 8 | 9, 10, 12, 14) y para que cada premisa encaje con su mapa. Informe en `production/revisiones/2026-11-05-contenido-mundo1-reglas-mapa.md`.
  - **QA independiente:** APROBADO, con el test propio `tools/test/qa_mapa_independiente_test.dart`.
  - **Revisión visual del arquitecto:** lámina de los 18 muebles (2 pieles × 2 modos) y el caso mansion-04 en web a 360×740, en Papel claro e Ilustrada oscura.
  - **Versión:** 0.7.0+7.
- **Commits:** `c84e55f` (motor), `7c9f7d6` (contenido, dibujos y versión) y el de cierre.
- **Pruebas:** tools 335 y app 627, todas pasan; analyze limpio en las dos carpetas.
- **APK:** `APKs/enigmatrix-0.7.0+7-arm64.apk` (y `-armeabi-v7a`), con `ENX_DEV=true` y compilado en la carpeta principal.
- **Pendiente o dudas para la otra cuenta:**
  - **Bañera:** resuelto en la 0.7.1+8 (entrada de arriba).
  - **Repetición de muebles:** resuelto en la 0.7.2+9 (tope de 2 por habitación).
  - **Élite:** con las reglas nuevas el generador no saca casos 16×16. Ya estaba fuera de la V1.
  - **Interruptor sin uso:** `tools/test/support/regeneracion_pendiente.dart` ya está en `false` y se puede limpiar.
  - **Banco de pruebas y tutorial:** no se regeneraron y están exentos de la puerta de contenido.

## 05-11-2026 · cuenta secundaria · medición de FPS

- **Qué se hizo:** Alejandro midió los FPS con la 0.6.0+6 en su teléfono, un Samsung Galaxy A52: **siempre anduvo a 60 fps**. Queda cerrada la medición de FPS de la ronda 4.3. Falta probar TalkBack en el teléfono.
- **Archivos tocados:** esta bitácora, `active.md` y `TRASPASO.md`.
- **Pruebas:** sin cambios de código.

## 05-11-2026 · cuenta secundaria · ronda 4.3b (0.6.0+6)

- **Qué se hizo:**
  - **H-65:** los valores de juego pasaron a `app/assets/config/game_config.json`, leídos por `GameConfig` (`app/lib/src/game/game_config.dart`, `gameConfigProvider`). Son el límite de deshacer (50), el guardado periódico (15 s), el bloqueo tras un Resolver fallido (3 s), la espera del splash (1700 ms), el inicio del reto (01-11-2026), el ciclo de 30 días, las vidas máximas (5), las dificultades de la V1 y los mundos disponibles. No cambió ningún valor. Si el JSON falta o está roto, se usan los valores por defecto.
  - **H-66:** el banco de pruebas, "Copiar feedback de playtest", el medidor de FPS y el cuadro de feedback de la victoria solo aparecen si se compila con `--dart-define=ENX_DEV=true` (`app/lib/src/game/dev_tools.dart`). Sin la bandera, `/banco` lleva a Inicio. Además, la descripción de `pubspec.yaml` quedó neutra.
  - **H-63:** todos los textos visibles están en `app/lib/l10n/app_es.arb` (gen-l10n, `context.l10n`). Son 295 claves, 77 con datos y 13 con plural. Las clases `*Texts` y `BoardStrings` desaparecieron. Lo de desarrollo quedó en `DevTexts`, que no se traduce. Las pistas pasan por `clueText(...)` (`app/lib/src/ui/clue_text.dart`). Para sumar inglés basta con un `app_en.arb`. Cambio de texto a propósito: el singular ahora dice "1 error" en vez de "1 errores".
  - **Versión:** 0.6.0+6.
  - **Verificación:** QA independiente (agente `qa`) APROBADO, con 7 pruebas propias en `app/test/qa_ronda43b_test.dart`. Revisión visual del arquitecto en web a 360×740 de Inicio, Cómo jugar, tutorial, lista de casos y Configuración, en Ilustrada y Papel, claro y oscuro. Sin la bandera, Configuración no muestra la sección de desarrollo.
- **Archivos tocados:** `app/pubspec.yaml`, `app/l10n.yaml`, `app/assets/config/`, `app/lib/l10n/`, `app/lib/main.dart`, `app/lib/src/game/` (`game_config`, `dev_tools`, `game_controller`), unos 30 archivos de `app/lib/src/ui/` y `app/lib/src/board/`, y los tests de `app/test/`. También `production/session-state/` (esta bitácora, `active.md`, `TRASPASO.md`).
- **Commits:** `0785455` (paso 1), `18666ff` (paso 2) y el de cierre de la ronda, en la rama `claude/traspaso-ronda-4-3b-2b34df`, llevada a `main` con avance directo y push.
- **Pruebas:** app 625 (antes 540), tools 279, todas pasan. `flutter analyze` limpio. Compila en web.
- **APK:** `APKs/enigmatrix-0.6.0+6-arm64.apk`, compilado en la carpeta principal (allí está la firma) con `ENX_DEV=true` para poder medir FPS.
- **Pendiente o dudas para la otra cuenta:**
  - El APK de un worktree sale firmado con la llave de depuración, porque `key.properties` solo está en la carpeta principal. Los APK para Alejandro se compilan siempre en la carpeta principal.
  - `app/lib/src/board/audio/audio_service.dart:27` tiene un mensaje técnico en español sin pasar al `.arb`. El jugador no lo ve.
  - No se hicieron (H-66, fuera de alcance): leer la versión con `package_info_plus`, unificar "Caso Nº"/"Expediente", la pantalla de error con Reintentar y subir el nivel de lints.
  - Siguen pendientes los resultados de la prueba de juego. (La medición de FPS se hizo después; ver la entrada de arriba.)

## 05-11-2026 · cuenta principal (cierre)

- **Qué se hizo:** auditoría, documentación al día, etapas 1, 2, 3.1, 3.2, 4.1, 4.2 y 4.3a. La versión actual es 0.5.0+5. Se prepararon este archivo y `TRASPASO.md`.
- **Último commit:** el del traspaso, después de `a4dca02`.
- **Pruebas:** tools 279 y app 540, todas pasan.
- **Pendiente:** la ronda 4.3b (ver `TRASPASO.md`).

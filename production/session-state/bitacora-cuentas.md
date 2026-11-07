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

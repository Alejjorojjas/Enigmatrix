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

## 05-11-2026 · cuenta secundaria · resultados de la prueba de juego n.º 1 (EN CURSO)

- **Lo que trajo Alejandro de sus probadores:**
  - **Dificultad:** "está bien por ahora". Los rangos de `tools/lib/src/difficulty_ranges.dart` se mantienen.
  - **Confusión de muebles:** "silla" se confunde con el sillón y el sofá, porque casi todos los casos los mezclan (8 de 10 del Mundo 1, 27 de 30 retos y 18 de 21 casos de prueba).
  - **Coherencia de las habitaciones:** les extrañó ver dos camas en una habitación o una cama en una cocina.
- **Decisión de Alejandro:**
  - un solo tipo por familia de muebles parecidos en cada mapa, revisando todas las familias, no solo los asientos;
  - objetos nuevos coherentes con cada habitación (perchero y similares);
  - coherencia por habitación.
- **Plan:**
  1. `puzzle-engineer`: reglas en el generador, objetos nuevos, puerta de contenido y spec 16.
  2. `frontend`: dibujos de los objetos nuevos en las dos pieles.
  3. `contenido-puzzles`: regenerar el Mundo 1 y los 30 retos con la misma dificultad.
  4. QA, revisión visual, 0.7.0+7, APK, commit y push.
- Si esta entrada sigue "EN CURSO", la sesión se cortó: revisa `git status` y `git diff` en la rama `claude/traspaso-ronda-4-3b-2b34df`.

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

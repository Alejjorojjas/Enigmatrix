# Contenido del Mundo 1 sin nombres con V (11-11-2026)

Decisión del dueño (11-11-2026): ningún personaje puede tener un nombre que empiece por V. La V es exclusiva de la víctima y su ficha en el tablero muestra siempre "V".

## Elenco

- Único nombre con V en `tools/data/mundos/mansion.json`: Valeria (la prima viajera). Se reemplazó por **Yolanda** (mujer, "la prima viajera"). Se mantiene el tamaño del elenco (36), el equilibrio por género y las 23 iniciales distintas (la Y entra donde salió la V).
- No hay más archivos de mundo con elenco (`mansion-casos.json` y `mansion-reto.json` son planes).

## Regla en el motor

- `tools/lib/src/world.dart`: `kVictimInitial`, `startsWithVictimInitial` y un problema nuevo en `WorldData.problems()` (nombre del elenco que empieza por V).
- `tools/lib/src/content_gate.dart`: `reservedInitialProblems(pc)`, exigida en `checkCaseContent` cuando hay reglas de mundo (`mapRules`).
- `tools/lib/src/tooling/content_files.dart`: la puerta de contenido la exige a los casos del catálogo de los mundos reales (campaña y retos). El banco de pruebas queda exento, igual que con las reglas de mapa, y el tutorial no se revisa.
- Pruebas nuevas: 1 en `world_test.dart` y 2 en `story_gate_test.dart`.

## Regeneración

- Se rehicieron los 40 casos con `build-plan` y los planes existentes. **Ninguna semilla cambió**: el elenco solo cambia nombres y textos de pistas, no mapas ni lógica. Comprobado: mapa, solución, víctima, métricas e historia son idénticos a los de antes en los 40 archivos; solo cambian los nombres de los personajes (los 17 casos con Valeria, y todos los demás porque `pickCast` baraja distinto al cambiar la lista de iniciales).
- Se conservan los ids, el arma en mansion-08, 09 y 10, las reglas de mapa (ADR-0015 y máximo 2 del mismo mueble por habitación) y el encaje de cada premisa con su mapa. El catálogo no cambió (mismos ids y archivos).
- Curva de campaña: Principiante 4, 6, 7 | Casual 6, 7, 8 | Intermedio 9, 10, 11, 14.
- Los 30 retos mantienen los pasos de la tabla de `2026-11-05-contenido-mundo1-reglas-mapa.md`.

## Banco de pruebas y tutorial

Revisados `app/assets/cases/caso-*.json` (20) y `app/assets/tutorial/caso-tutorial.json`: ningún personaje empieza por V. No se tocaron.

## Pruebas

`qa_mapa_independiente_test.dart` y `map_rules_test.dart` no necesitaron cambios (los mapas no cambiaron).

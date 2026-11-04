# ADR-0003: Mapas procedurales únicos por caso y tamaños de tablero tipo Murdoku

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 11-06-2026 (segunda ronda de pruebas de juego)
- **Decisores**: Alejandro (usuario), a partir de lo que vio jugando murdoku.com y de las imágenes de referencia que aportó; implementó el arquitecto.

## Contexto

En la Fase 0 (10-06-2026) los casos se generaban sobre tres mapas de prueba fijos de 4×4, 5×5 y 6×6 (`tools/lib/src/maps/test_maps.dart`), y el documento 05 planteaba mapas dibujados a mano y reutilizados por muchos casos (50 mapas de campaña). Al jugar, Alejandro comparó con el Murdoku original: allí cada caso tiene su propia distribución de habitaciones y los tableros son bastante más grandes. Con mapas fijos, el jugador reconoce el plano y la deducción deja de ser deducción.

## Decisión

1. **Cada caso tiene su propio mapa**, generado por código: habitaciones por crecimiento de regiones, muebles y armas en áreas distintas. Dos casos nunca comparten distribución. El mapa viaja dentro del JSON del caso (lo arma `CaseFactory`). El generador es `tools/lib/src/map_generator.dart`.
2. **Tamaños por dificultad**: Principiante 6×6, Casual 8×8, Intermedio 9×9, Experto 12×12 y Élite 16×16 (el tamaño es también el número de personajes). Están fijados en `tools/lib/src/generator.dart`.
3. El arte hecho a mano pasa a ser solo la "piel" por mundo (texturas, sprites de muebles) que se pone encima del mapa generado.

## Alternativas consideradas

- **Mapas dibujados a mano y reutilizados** (el modelo original del doc 05). No: se vuelven reconocibles, y habría que dibujar más de 50 mapas antes de tener contenido.
- **Quedarse en 4×4, 5×5 y 6×6** (tamaños de la Fase 0). No: son demasiado fáciles de adivinar y no se parecen al juego de referencia.
- **Generar solo la distribución de personajes sobre un catálogo de mapas**. No: reintroduce el problema de repetición.

## Consecuencias

- Se gana variedad infinita de planos y no hace falta un editor de mapas para el contenido.
- Se pierde el control artístico: el plano que sale no tiene por qué parecerse a "La Mansión" (hallazgo H-44 de la auditoría). Cómo se hace la piel por mundo sigue abierto (ver ADR-0005 y ADR-0006).
- Cada mapa necesita su propio verificador de solución única; el generador lo hace, pero **no tiene límite de tiempo** (H-42).
- Experto (12×12) y Élite (16×16) están definidos, pero **nunca se han generado**: no se sabe cuánto tarda el generador ni si el tablero cabe en una pantalla de 6 pulgadas (H-39). La etapa 3 del plan (ADR-0011) incluye una prueba de generación.
- Los documentos 05 y 16 todavía conservan cifras y textos de los tamaños y mapas anteriores; su limpieza es otra tarea de la etapa 0 (H-33).

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 13): esta decisión fija 12×12 y 16×16 como tamaños de Experto y Élite, y el plan de contenido de lanzamiento aún no dice si esas dificultades entran al lanzamiento. Versión A: entran, y se generan y prueban desde la etapa 3. Versión B: no entran al primer lanzamiento. La recomendación de la auditoría es decidirlo después de la prueba de generación y de verlos en pantalla. Este ADR no lo resuelve.

## Fuentes

- `production/session-state/active.md`, entrada "2026-06-11 — SEGUNDA RONDA de playtest" (11-06-2026).
- `docs/16-spec-puzzle.md`, §1.1 y §7 "cerradas (2026-06-11, segunda ronda de playtest)".
- `docs/05-pipeline-puzzles.md`, banner "ACTUALIZACIÓN 2026-06-11".
- Commit `954a3fd` (11-06-2026, "Mapas unicos por caso, tamanos Murdoku, auto-X y nueva interaccion").
- `tools/lib/src/generator.dart` (perfiles de dificultad) y `tools/lib/src/map_generator.dart`.
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-33, H-39, H-42, H-44.

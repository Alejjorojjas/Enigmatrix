# ADR-0004: Vocabulario de pistas estilo Murdoku y regla del mínimo 2

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 11-06-2026 (rediseño del motor tras la tercera ronda de feedback)
- **Decisores**: Alejandro (usuario), después de jugar murdoku.com y de ver el video del cuadernillo; implementó el arquitecto.

## Contexto

El motor de la Fase 0 (10-06-2026) usaba pistas "mecánicas": de fila, de columna, de esquina y cardinales ("al oeste de"). Alejandro jugó y señaló que no se parecían al Murdoku original. Después, con las pistas ya rediseñadas, notó que algunas regalaban la posición de su personaje sin necesidad de cruzar nada. Además, el motor había demostrado que con pistas solo de área la solución única es matemáticamente imposible (dos personas de la misma área se pueden intercambiar), así que alguna pista tenía que llegar al nivel de la casilla.

## Decisión

1. **Una pista por personaje**, escrita en su tarjeta (la víctima también tiene la suya, normalmente de relleno). Las pistas sueltas "extra" (área vacía, arma) solo aparecen desde Intermedio, con un máximo de 2 en el diseño.
2. **El vocabulario son habitaciones, muebles y personas**. El spec 16, sección 3.1, define 16 tipos (en el código son 16 clases de pista en `tools/lib/src/clue.dart`). La precisión a nivel de casilla la aportan los **muebles** ("sobre una cama", "junto a una planta"), no las pistas mecánicas.
3. **Se eliminan de la primera versión** las pistas de fila, columna, esquina y cardinales. Las técnicas de tachar fila y columna siguen siendo el corazón del juego, pero ninguna pista las menciona.
4. **Regla del mínimo 2** (11-06-2026): ninguna pista de tarjeta puede dejar una sola casilla posible por sí sola. La posición exacta siempre nace de cruzar la pista con el tachado de filas y columnas de los demás. Vale también para las pistas compuestas. Está probada por el test `REGLA MURDOKU` en `tools/test/generator_test.dart`.

## Alternativas consideradas

- **Mantener las pistas mecánicas de fila, columna, esquina y cardinales**. No: no se parecen al juego de referencia que Alejandro quiere seguir.
- **Pistas solo de área**. No: no permiten solución única (ver Contexto).
- **Permitir que una pista deje una sola casilla** (sin la regla del mínimo 2). No: la deducción se reduce a leer la pista, y se debilita el pilar 1 (deducción pura, nunca adivinar).
- **Varias pistas por tarjeta**. No: el formato "una por tarjeta" es el del juego de referencia.

## Consecuencias

- Los casos exigen más razonamiento: según la bitácora, los pasos de deducción del solver subieron de 3-7 a 5-14 al aplicar la regla del mínimo 2.
- Una pista deja de poder resolver a su personaje, pero el generador tiene que esforzarse más para lograr unicidad con muebles repetidos.
- **La dificultad no se controla**: el generador no impone rangos (hallazgo H-40). Los tipos de pista se usan poco: los 20 casos del banco usan 9 de los 16 tipos y ninguno usa pistas extra (H-52).
- Los textos de las pistas los escribe el motor en español, con género y artículos fijos en el código (`cardTextEs`, `predicateEs`). Eso complica traducirlos (H-63).
- Los documentos 03, 05, 16 y 01 todavía mencionan pistas y rangos anteriores; su limpieza es otra tarea de la etapa 0 (H-33).

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 15): inglés y formato de las pistas. Versión A (hoy): el motor escribe las pistas directamente en español. Versión B (recomendación de la auditoría): guardar cada pista como datos (tipo de pista y personajes) y redactarla aparte en cada idioma. Hay que decidirlo antes de la etapa 3, para no rehacer el Mundo 1. Este ADR no lo resuelve.

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 19): uso del arma homicida. Versión A (hoy): el arma aparece en el 10 % de los casos y nunca por encima de Casual. Versión B (recomendación de la auditoría): usarla más en el Mundo 1, desde Intermedio. Este ADR no lo resuelve.

## Fuentes

- `production/session-state/active.md`, entradas "2026-06-11 — REDISEÑO MURDOKU del motor" y "2026-06-11 — REGLA DEL MÍNIMO 2" (11-06-2026).
- `docs/16-spec-puzzle.md`, §3.1, §3.2 y §7 "cerradas (2026-06-11, rediseño Murdoku tras playtest del usuario)".
- Commits `6af707a` (11-06-2026, "Rediseno Murdoku del motor: pistas de muebles, una por tarjeta") y `21b2f87` (11-06-2026, "Regla del minimo 2").
- `tools/lib/src/clue.dart`, `tools/lib/src/generator.dart` (filtro de candidatas) y `tools/test/generator_test.dart`.
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-33, H-40, H-52, H-63.

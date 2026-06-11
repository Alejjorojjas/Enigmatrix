# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito.

## Fase actual

**FASE 0** — solver (ver `docs/17-roadmap.md`). Spec del puzzle cerrada y lista para implementar.

## Tarea actual

Ninguna en curso. Próximo paso acordado: implementar el modelo de datos del puzzle en `tools/` (Dart puro) según `docs/16-spec-puzzle.md`, empezando por mapa/áreas/celdas y el motor de deducción. Agente: `puzzle-engineer`.

## Decisiones recientes

- 2026-06-10 (sesión 2, confirmadas por el usuario):
  - Grilla cuadrada N×N con N = personajes (incluida víctima); exactamente una persona por fila y columna; 4×4 (Principiante) → 7×7/8×8 (Elite).
  - Ayudas: no penalizan en Tutorial/Principiante; penalizan desde Casual. Doc 03 corregido — contradicción con 08 eliminada.
  - La rotación anti-trampa también rota el texto de las pistas (cardinales y fila/columna se remapean en el renderizador; el servidor valida en coordenadas canónicas).
  - "Island" de la web no es regla del motor; nombres de áreas/objetos son datos del mapa.
- 2026-06-10 (sesión 1): estructura del repo, docs migrados, spec 16 y roadmap 17, 6 agentes, ADR-0001 (Flutter+Firebase), ADR-0002 (Riverpod).

## Archivos en progreso

- Ninguno.

## Preguntas abiertas para el usuario

- Tutorial: ¿mecánica completa en 4×4 guiado? (decidir en Fase 1)
- Mockups de Claude Design pendientes de entrega → `docs/mockups/`.

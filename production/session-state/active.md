# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito.

## Fase actual

**FASE 0 — COMPLETADA** (2026-06-10). Criterio de salida cumplido: 20 casos únicos de deducción pura generados. Pendiente: validación a mano del usuario (jugar casos de `production/fase0-casos/casos-para-jugar.txt`).

Siguiente fase: **FASE 1** (vertical slice Flutter) — ver `docs/17-roadmap.md`. Esperando mockups del usuario (Claude Design) para la UI; el tablero puede arrancar antes con UI provisional si el usuario lo aprueba.

## El motor (tools/) — estado

- `lib/src/model.dart` — grilla, áreas, objetos, armas, esquinas, adyacencia
- `lib/src/clue.dart` — 16 tipos de pista con semántica formal + JSON + texto ES
- `lib/src/validator.dart` — validación de asignación completa (ESTA lógica se porta a Cloud Functions en Fase 2)
- `lib/src/deduction.dart` — motor de deducción: 8 técnicas en 4 niveles (T1 pista directa → T4 conteo de áreas/asesino/arma)
- `lib/src/uniqueness.dart` — verificador de unicidad por backtracking
- `lib/src/generator.dart` — generador con minimización a conjunto irreducible
- `lib/src/maps/test_maps.dart` — 3 mapas de prueba (4×4, 5×5, 6×6); NO son contenido final
- `bin/enigmatrix.dart` — CLI: generate / show / validate
- 38 tests pasando (`dart test` en tools/)

Comandos útiles:
```
cd tools
dart test
dart run bin/enigmatrix.dart generate --difficulty casual --count 5 --seed 1 --out out
dart run bin/enigmatrix.dart show out/<caso>.json --solution
dart run bin/enigmatrix.dart validate out/<caso>.json
```

## Decisiones y hallazgos recientes

- 2026-06-10 (sesión 3 — Fase 0): motor completo. Hallazgos clave (en spec 16 §3.2):
  - Pistas solo de área NUNCA dan solución única (simetría de intercambio víctima/asesino) → toda dificultad lleva pistas de celda.
  - Rangos de pistas reales: 4×4≈4-6, 5×5≈8-9, 6×6≈10-12 (doc 05 quedó corto, se recalibra con playtest).
  - Semántica cardinal corregida en spec 1.4: comparación estricta de coordenada (dos personas nunca comparten fila/columna).
- 2026-06-10 (sesión 2): grilla N×N = personajes; ayudas no penalizan en Tutorial/Principiante; la rotación rota también el texto de las pistas.
- 2026-06-10 (sesión 1): estructura, docs migrados, 6 agentes, ADRs 0001-0002.

## Preguntas abiertas para el usuario

- Jugar 2-3 casos en papel y dar feedback (¿se sienten justos? ¿la dificultad escala?).
- Tutorial: ¿mecánica completa en 4×4 guiado? (decidir al diseñar Fase 1)
- Mockups de Claude Design → `docs/mockups/` cuando estén.

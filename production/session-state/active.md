# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito.

## Fase actual

**FASE 1 — EN CURSO**. App Flutter en `app/` corriendo como web local: `JUGAR.bat` abre http://localhost:8123.

**2026-06-11 — REDISEÑO MURDOKU del motor** (feedback del usuario jugando murdoku.com + video del cuadernillo): vocabulario de muebles, una pista por tarjeta, sin pistas mecánicas (detalle en spec 16 §3 y §7).

**2026-06-11 — SEGUNDA RONDA de playtest**: (1) MAPAS ÚNICOS POR CASO — generador procedural de mapas (`tools/lib/src/map_generator.dart`: habitaciones por crecimiento de regiones, muebles, armas en áreas distintas; el mapa viaja embebido en el JSON del caso vía `CaseFactory`); doc 05 actualizado (autorado a mano = solo piel artística). (2) TAMAÑOS MURDOKU: 6×6/8×8/9×9/12×12/16×16 (referencias por imágenes del usuario). (3) AUTO-X opcional (default on): confirmar tacha fila/columna, se retira al borrar el confirmado (board_state con autoXFrom). (4) Interacción: tap = candidato (letra) · mantener oprimido o arrastrar = confirmado (círculo avatar) · X grandes. 57 tests motor + 15 app. 20 casos regenerados con mapas únicos.

**2026-06-11 — PASE DE DISEÑO VISUAL** (commit e91cfe2, feedback "se ve muy plano"): fondo con gradiente radial; tablero enmarcado (borde dorado, sombra, resplandor) con paredes gruesas estilo plano, gradientes por habitación y NOMBRES de habitación sobre el mapa; muebles con color propio; confirmados con gradiente+anillo+glow; tarjetas de sospechosos estilo polaroid (claras, nombre manuscrito Segoe Script, cinta LA VÍCTIMA, pista en burbuja); chips pill en header; RESOLVER con gradiente dorado; paneles en tarjetas; lista de casos con cabecera serif y colores por dificultad (difficultyColor en main.dart). El arte FINAL sigue pendiente de los mockups del usuario.

**2026-06-11 — REGLA DEL MÍNIMO 2** (tercer feedback del usuario): ninguna pista de tarjeta deja una sola casilla posible por sí sola (mín. 2, también compuestas) — el descarte nace de cruzar pistas, no de pistas que regalan posición. Filtro en `_candidatesFor` del generador + test `REGLA MURDOKU`. Efecto medible: pasos de deducción subieron de 3-7 a 5-14. Spec 16 §3.2 actualizada. 58 tests.

Pendiente: que el usuario juegue y dé feedback; tutorial; UI definitiva con mockups ("quiero que se vea con más imágenes" — necesita los sprites/arte); build Android; experto 12×12 y elite 16×16 (perfiles ya existen, evaluar UI móvil).

FASE 0 — COMPLETADA (2026-06-10, motor rediseñado 06-11).

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

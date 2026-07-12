# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito.

## Fase actual

**FASE 1 — EN CURSO**. App Flutter en `app/` corriendo como web local: `JUGAR.bat` abre http://localhost:8123.

**2026-07-12 — MUEBLES ILUSTRADOS** (commit 99507b8, feedback: "la cama es solo un rectángulo, quiero ver los objetos de verdad"): nuevo `ui/furniture_painters.dart` — FurniturePainter dibuja cada ObjectType como ilustración vectorial top-down cartoon (cama con marco/colchón/almohada/cobija con doblez, sofá/sillón con respaldo/brazos/cojines, silla con barrotes, mesa con veta, barra con encimera de piedra, alfombra con cenefa/rombo/flecos, planta con matera y hojas radiales, arbusto, TV con reflejo, armario con puertas y manijas, caja con solapas y cinta, lavadora con ojo de buey, piano con teclado). Piezas verticales rotan el lienzo 90°; sombra difusa propia; pisables a opacidad .88. board_view._furniture ahora usa CustomPaint (el gradiente+icono viejo se eliminó; objectIcon/objectColor siguen vivos para la leyenda de game_screen). 24 tests. PENDIENTE del usuario: elegir ambiente de color definitivo + feedback de los muebles.

**2026-07-12 — CULEBRITA + SELECTOR DE AMBIENTES** (commit 2d016f7): al usuario le gustó el pase Enx; pidió (1) camino en culebrita — ahora las fichas siguen una onda seno (período 6, amplitud hasta 120px según ancho) con filas de altura fija (_rowHeight 124) y el hilo carmesí punteado SIGUE la curva (cúbicas entre centros de ficha + punteado por PathMetrics en _ThreadPainter); (2) más opciones de color — selector en vivo (icono paleta en top bar) con 5 ambientes persistidos en prefs (`enx:palette`): Medianoche (violeta, default), Noir (azul-negro), Estudio del detective (sepia), Bosque (verde botella), Vino tinto. EnxPalette + paletteProvider (Notifier) en enx_style.dart; lo fijo entre ambientes: latón dorado, hilo carmesí, papel crema, colores de dificultad. PENDIENTE: el usuario elige ambiente definitivo → luego llevar el estilo Enx al tablero de partida (game_screen aún dorado viejo).

**2026-07-11 — PASE ENX v2 (identidad propia)**: feedback del usuario al pase Duo: "demasiado parecido a Duolingo — mantener lo redondeado pero hacerlo único". Reemplazo completo: `ui/duo_widgets.dart` eliminado → `ui/enx_style.dart` (clase Enx: fondo violeta medianoche #1B1426, latón dorado #F0B429 como marca con tinta #4A3200, hilo carmesí #D64550, papel crema #F5EFE6; tipografías Baloo 2 display + Quicksand body — ya no Nunito). La lista es un TABLERO DE EVIDENCIAS: fichas cuadradas redondeadas inclinadas (±0.045 rad) unidas por hilo carmesí punteado (_ThreadPainter), carpetas "EXPEDIENTE NºN" con pestaña por dificultad, ficha actual con borde dorado + etiqueta de papel "SIGUIENTE CASO" rebotando, pendientes como carpeta archivada. Victoria = sello "CASO CERRADO" carmesí estampado (doble borde, rotado, elasticOut desde 2.2) sobre informe en papel crema con EnxReportStat. Paleta de dificultad retonada a vintage (salvia/empolvado/calabaza/ladrillo/violeta) en main.dart. Botón del sheet: "Investigar"/"Reabrir caso". Tests renombrados a enx_screens_smoke_test.dart, 24 pasando. Commit 09b3e4b.

**2026-07-11 — PASE DUO (dirección visual Duolingo, SUSTITUIDO por el pase Enx)**: el usuario decidió abandonar Claude Design y hacer la UI directo en Flutter con el lenguaje visual de Duolingo (referencias: racha, camino de nodos, perfil) adaptado a la identidad detective. Nuevo `ui/duo_widgets.dart` (paleta Duo fondo #131F24, botones 3D presionables con borde inferior duro, Nunito vía google_fonts, DuoStatCard, DuoChip). `case_list_screen.dart` REESCRITA como camino de nodos en zigzag agrupado por sección de dificultad (banner de color, nodo actual con anillo + burbuja EMPEZAR animada, resueltos con check, ficha de caso en bottom-sheet con botón JUGAR; todos los nodos siguen jugables por ser banco de pruebas). Resumen de victoria movido de AlertDialog a `ui/victory_screen.dart` a pantalla completa (insignia dorada con rebote, revelación del asesino/arma, DuoStatCards de tiempo y errores, feedback de playtest conservado, botón CONTINUAR verde). Bug real corregido: el AnimationController lazy del nodo explotaba en dispose de nodos no-actuales (ahora se crea solo si isCurrent, con didUpdateWidget). 24 tests (20 previos + 4 smoke de las pantallas nuevas en `test/duo_screens_smoke_test.dart`; pumps fijos porque la burbuja anima en bucle). El tablero de partida AÚN tiene el estilo dorado viejo — si al usuario le gusta el pase Duo, extenderlo a game_screen/board_view. Nota entorno: el Browser pane de Claude quedó con la pestaña hidden (rAF congelado) y no renderiza Flutter — verificar visualmente vía JUGAR.bat.

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

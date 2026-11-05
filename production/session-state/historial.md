# Historial de sesiones (movido desde active.md el 04-11-2026)

> ACTUALIZACIÓN 04-11-2026: este archivo conserva, sin cambiar una sola palabra, todo lo que había en `active.md` hasta el 04-11-2026. El estado actual, las decisiones vigentes y las preguntas abiertas están ahora en [active.md](active.md). Lo que sigue es historia: sirve para saber por qué se decidió algo, no para saber qué está pendiente.
>
> Cómo leerlo:
> - Las entradas están en el orden en que se escribieron, que **no** es el orden cronológico real (por ejemplo, "LOGO + SPLASH + TUTORIAL" va primero pero es anterior al shell de navegación y al icono). Las fechas de cada entrada mandan.
> - Las cifras de tests y de casos que aparecen abajo (24, 25, 26, 38, 57, 58, 60) son de momentos distintos y no coinciden entre sí. Cifras verificadas leyendo el código el 04-11-2026: 54 tests en `tools/test` y 26 en `app/test`; tamaños de tablero 6×6, 8×8, 9×9, 12×12 y 16×16 (`tools/lib/src/generator.dart`); los 20 casos incluidos en la app son 8 Principiante (6×6), 7 Casual (8×8) y 5 Intermedio (9×9).
> - Registro de commits que faltaba en la bitácora: `6cdd9f6` (tutorial jugable paso a paso antes del Caso N1, 12-07-2026), `c6140c9` (el tutorial de primera vez se dispara en el shell, 12-07-2026), `9b7e768` (herramientas arriba de PERSONAJES y título PISTAS en el deslizador, 12-07-2026) y `84835be` (pistas como tarjetas de personaje compactas horizontales, PERSONAJES eliminado, 12-07-2026; es el último commit del repositorio).
>
> Pendientes de esta bitácora que `git log` demuestra resueltos (cerrados el 04-11-2026):
> - Tutorial: hecho en versión simple. Hay un diálogo de 5 páginas (`86f5925`) y un tutorial jugable (`6cdd9f6`). Su diseño definitivo sigue abierto: ver la pregunta 11 de la auditoría.
> - Compilar la versión Android: hecho (APK en `561c11e`, AAB firmado con la llave de subida en `28bbde9`).
> - Llave de firma propia ("keystore propio pendiente"): hecho en `28bbde9`. Queda pendiente respaldarla fuera del PC (hallazgo H-05 de la auditoría).
> - Icono de la app ("icono default de Flutter pendiente"): hecho en `54dced2`.
> - Elegir estilo entre los 6 mockups: hecho, se eligió Paper Craft (`561c11e`). Desde el 01-11-2026 la dirección gráfica está en revisión.
> - "Elegir ambiente de color definitivo" y "llevar el estilo Enx al tablero de partida": superados, porque Paper Craft (`561c11e`) reemplazó los 5 ambientes en toda la app, incluido el tablero.
> - "PLAN DEL PRÓXIMO BLOQUE", puntos (b) navegación inferior con Inicio, Mundos, Reto, Ranking y Perfil, (f) ranking simulado, (g) tienda y premium simulados, y (h) icono: hechos en `f6f2d1d` y `54dced2`. El punto (e) perfil local quedó en parte (nickname editable y guardado). Los puntos (a) Mundo 1 real, (c) reto diario con estado real y (d) vidas funcionales **no se hicieron**: hoy son datos simulados y el banco sigue siendo de 20 casos.
> - "Mockups de Claude Design → `docs/mockups/`": superado. Claude Design se abandonó el 11-07-2026.
> - "Tutorial: ¿mecánica completa en 4×4 guiado?": superado por el tutorial jugable de `6cdd9f6`. El tamaño 4×4 ya no existe en el generador.
>
> Siguen abiertos (y ahora viven en las decisiones pendientes de `active.md`): jugar 2-3 casos en papel y dar feedback (no hay registro de que se hiciera, hallazgo H-22), Experto 12×12 y Élite 16×16 sin generar (pregunta 13), el proyecto Firebase (etapa 5), la cuenta de Google Play y el acceso a un Mac (preguntas 17 y 22; **PENDIENTE DE DECISIÓN**, auditoría 04-11-2026, pregunta 22: esta bitácora dice que el usuario confirmó acceso a un Mac el 12-07-2026, y la auditoría lo vuelve a preguntar).
>
> ACTUALIZACIÓN 04-11-2026 (decisión de Alejandro): el acceso a un Mac queda **confirmado desde el 12-07-2026**, como dice esta bitácora. La pregunta 22 de la auditoría queda reducida a si el iPhone entra al lanzamiento (sigue pendiente). Lo de arriba sobre el Mac queda como historia.

## Contenido original de active.md (palabra por palabra)

# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito.

## Fase actual

**FASE 1 — EN CURSO**. App Flutter en `app/` corriendo como web local: `JUGAR.bat` abre http://localhost:8123.

**2026-07-12 — LOGO + SPLASH + TUTORIAL (commit 86f5925)** — primera ronda de feedback del usuario jugando el APK: (1) logo ✅ ui/logo.dart PaperLogo lupa de papel (dirección elegida vía AskUserQuestion); (2) splash ✅ ui/splash_screen.dart en ruta '/' (lista pasó a '/casos'); (3) tutorial primera vez ✅ ui/tutorial_dialog.dart, 5 páginas paginadas, Omitir, prefs 'tutorial:seen', botón ? en top bar de la lista. DECISIONES DEL USUARIO (AskUserQuestion): pantallas completas PRIMERO con datos locales simulados, Firebase después; monetización INCLUIDA ya simulada (tienda/premium fake); campaña: SOLO Mundo 1 (Mansión, 10 casos dificultad creciente) para calibrar; después los otros 4 mundos.

**2026-07-12 — UX DE PARTIDA v2 (commit 0bde190)** — 2ª ronda de feedback jugando en teléfono: (1) RESOLVER movido ARRIBA junto al chip de errores (decisión del usuario "arriba al lado de errores"), compacto dorado en el _Header; quitado de _Controls. (2) _ClueStrip nuevo: barra de pistas FIJA bajo el tablero (64px, scroll horizontal, 235px por chip, tap=cycleClue destacar/tachar sincronizado con tarjetas) — sustituyó la idea del botón mantener-presionado porque ocuparía el dedo y no dejaría marcar el tablero. (3) Toda la tarjeta del sospechoso selecciona (GestureDetector opaque alrededor; burbuja de pista conserva su tap). (4) Leyenda (_InfoPanel habitaciones/muebles/reglas) fuera del scroll → botón menu_book en AppBar abre bottom sheet (80% alto). (5) Orden móvil: header+RESOLVER / tablero / pistas / papelera / PERSONAJES / controles compactos (deshacer·rehacer·limpiar·Mapa-Notas·Auto-X). Layout ancho >1150: panel lateral + columna central con controles abajo, sin panel derecho. 26 tests.

**2026-07-12 — ICONO DE APP (commit 54dced2)**: el usuario reportó que el APK instala con icono default. Resuelto: '?' del logo pasado a vectorial, test/generate_icon_test.dart rasteriza PaperLogo a assets/icon/icon_full.png + icon_fg.png (1024), flutter_launcher_icons genera mipmaps Android (adaptive, fondo #E9DCBE) + iOS. Icono verificado visualmente: lupa dorada + ? + hilo carmesí sobre kraft. REFERENCIA UX del usuario (captura Duolingo): barra inferior SOLO ICONOS sin texto, gorditos, pestaña activa enmarcada con borde redondeado — aplicar así en el shell de navegación (versión papel: recortes + marco de chincheta).

**2026-07-12 — SHELL DE NAVEGACIÓN (commit f6f2d1d)**: ui/home_shell.dart — barra inferior solo-iconos con pestaña activa enmarcada (patrón Duolingo del usuario, versión papel), 5 tabs: Inicio (saludo por hora, vidas mock 4/5, tarjetas reto/mundo con progreso REAL/tienda), Mundos (Mansión activa + 4 bloqueados), Reto (racha mock, semana en circulitos, caso del día determinista: cases[díasDesde2026-01-01 % n]), Ranking (bots detectives + fila usuario, DEMO), Perfil (nickname editable persistido 'profile:nick', stats, menú → Tienda/Premium/Config como bottom sheets DEMO con precios doc 08; toggles config persistidos 'cfg:*'). Rutas: '/' splash → '/home' shell; '/casos' = camino Mundo 1 con flecha de vuelta. Mock centralizado en constantes al inicio de home_shell.dart (reemplazar por repos Firebase en Fase 2). 25 tests. PENDIENTE PRÓXIMO: generar Mundo 1 real (10 casos Mansión temáticos, dificultad creciente) para reemplazar el banco de 20; vidas funcionales locales (doc 08); reto diario con estado real local (intento único/día); racha real local.

**PLAN DEL PRÓXIMO BLOQUE (todo local/simulado, doc 06 como guía)**: (a) generar Mundo 1 con tools (10 casos mansión, nombres temáticos, dificultad creciente) reemplazando el banco de 20; (b) Inicio (pantalla 12) con tarjetas: reto diario / continuar / mundo actual + navegación inferior Inicio·Mundos·Reto·Ranking·Perfil; (c) reto diario local (caso del día determinista por fecha desde pool, racha local + protectores, pantalla 32-35); (d) vidas locales (5 máx, -1 por error al Resolver, recarga 1/h con timestamps, doc 08); (e) perfil local editable (nickname/avatar de papel/bandera, stats); (f) ranking simulado (bots con nombres + score del usuario); (g) tienda/premium SIMULADAS (compras fake marcadas "DEMO"); (h) icono Android/iOS desde PaperLogo (pendiente rasterizar; sin ImageMagick — opción: screenshot del widget vía test golden o flutter_launcher_icons con PNG generado por test). Todo detrás de la MISMA estética paper craft (Enx). Los datos simulados se diseñan detrás de interfaces/repositorios para recablear a Firebase en Fase 2 sin tocar UI.

**2026-07-12 — CUMPLIMIENTO DE TIENDAS (commit 28bbde9)**: keystore de subida generado (android/upload-keystore.jks + key.properties, GITIGNORADOS — el usuario debe respaldarlos fuera del PC) y cableado en build.gradle.kts (fallback a debug si no existe key.properties); .aab firmado compilado (41.2MB, PUBLICAR-PLAYSTORE.bat) y APK re-firmado con la clave de subida (verificado con apksigner: CN=Enigmatrix); INTERNET declarado en manifest release (bug latente de google_fonts); version 0.1.0+1; iOS: ITSAppUsesNonExemptEncryption=false + PrivacyInfo.xcprivacy (agregar al target en Xcode); docs/legal/politica-privacidad.md (faltan nombre+correo del responsable) y docs/20-checklist-tiendas.md (estado de cada requisito; ojo: Play exige 12 testers × 14 días a cuentas nuevas; icono default de Flutter pendiente de diseño). Usuario confirmó: tiene acceso a Mac; plan = jugar y corregir ahora, publicar al final.

**2026-07-12 — PAPER CRAFT + ANDROID/iOS (commit 561c11e)**: el usuario eligió el estilo 5 (Paper Craft). Aplicado a TODA la app: Brand en main.dart pasó a tema CLARO kraft/tinta (cream ahora significa texto tinta #3D2F1C), EnxPalette reducida a preset único 'Papel' (selector eliminado, infra conservada), tablero con marco de corcho + hoja de papel base + pisos pastel (areaPalette papel) + paredes tinta + X marcador carmesí #8A2F1B + candidatos a lápiz, muebles con sombra dura de recorte, Enx.hand() = Patrick Hand. PLATAFORMAS: android/ e ios/ generados (flutter create --org com.enigmatrix); applicationId com.enigmatrix.app, label Enigmatrix, iOS CFBundleDisplayName listo (compilar iOS requiere Mac). APK RELEASE COMPILADO: `app/build/app/outputs/flutter-apk/app-release.apk` (49.5MB, firma debug — keystore propio pendiente antes de publicar). SEGURIDAD (doc 18): allowBackup=false, usesCleartextTraffic=false, sin permisos extra, sin logs de solución; riesgo aceptado Fase 1 = solución en JSON local. QA: analyzer limpio, 24 tests. PREGUNTAS ABIERTAS AL USUARIO: crear proyecto Firebase (Fase 2), cuenta Google Play (US$25), acceso a Mac para iOS.

**2026-07-12 — 6 MOCKUPS DE ESTILO VISUAL** (commit 02d1e26): al usuario no le convenció el estilo cartoon plano de los muebles ilustrados — pidió "gráficos complejos, modernos, de última tecnología, mínimo 6 mockups". Investigación: tendencias 2025-26 = tactile minimalism, glossy premium (Royal Match), painterly (June's Journey líder del género detective); Flutter con Impeller + shaders GLSL 120fps + Flame/Rive viabilizan efectos de lujo. Creados en `docs/mockups/estilos/`: 01-luxe-royal (glossy Royal Match), 02-painterly-deco (June's Journey años 20), 03-diorama-iso (Monument Valley isométrico + glassmorphism), 04-neon-noir (holográfico forense, neón), 05-paper-craft (Lumino City papel/cartón), 06-toon-premium (Toon Blast outline grueso) + index.html galería comparativa. Todos muestran la MISMA pantalla de partida (mismo caso/tablero/marcas). PENDIENTE: usuario elige estilo (o mezcla) → ese estilo se implementa en el tablero real de Flutter.

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


## Estado hoy anterior (05-11-2026, mañana), movido desde active.md

### Estado hoy (05-11-2026)

- **Etapa actual:** etapa 0 cerrada. Las etapas 1 y 2 están en curso, con el plan por etapas 0 a 6 aprobado (detalle en [docs/17-roadmap.md](../../docs/17-roadmap.md)).
- **Etapa 1, versión de prueba `0.2.0+2`:** implementada y aprobada por QA independiente el 05-11-2026. Incluye:
  - partida guardada en `game:<caseId>`;
  - pausa con el tablero tapado y reloj detenido en el diálogo de salida;
  - salida con confirmación hacia `/casos`;
  - errores mostrados solo como cantidad (regla 9);
  - aviso "Elige primero a un sospechoso" (regla 20);
  - pista completa al mantenerla oprimida;
  - etiquetas DEMO y "Próximamente";
  - casos ordenados por número y carga tolerante a archivos dañados;
  - versión y casos sin terminar en el reporte de feedback;
  - tutorial nuevo de 5×5 (`assets/tutorial/caso-tutorial.json`, semilla 192), obligatorio una vez (`tutorial:v2:done`) con Saltar visible, que ya no consume el Caso 1.

  Pruebas: tools 65 y app 98, todas pasan; analyze sin errores. Falta la guía de la prueba de juego.
- **Etapa 2, prototipo gráfico (`prototipos/tablero-flame/`):** la parte técnica está hecha (Flame, director de feedback, sonidos propios generados por código, medidor de FPS, 85 tests). Se están construyendo dos pieles, "Ilustrada" (cualidades de la referencia de Alejandro del 05-11-2026, ver [docs/referencias-visuales/](../../docs/referencias-visuales/README.md)) y "Papel", con modo claro y oscuro que sigue al teléfono. Falta medir en el Android de gama media de Alejandro.
- **05-11-2026, prototipo corregido y aprobado en dirección.** Alejandro dijo "sí me gustó" y confirmó las herramientas:
  - Anotar = candidato.
  - Tachar = X a mano.
  - Confirmar = un toque fija al sospechoso, además de mantener oprimido o arrastrar. Así se cumple el gesto alternativo de la regla 20 del ADR-0012.
  - Borrar = borrador.

  Tablero a todo el ancho (336 px a 360 de ancho). Commit `3ee6487`. Siguen pendientes: qué piel prefiere, la medición de FPS en su teléfono y cómo se hace el arte final.
- **Compilación:** el JAVA_HOME por defecto del PC es Java 11, y para compilar Android hay que usar `JAVA_HOME=C:/Program Files/Java/jdk-17`.
- **Protección:** Alejandro creó el repositorio privado `https://github.com/Alejjorojjas/Enigmatrix` y autorizó los commits el 04-11-2026. Los commits llevan solo su autoría, sin coautoría de Claude. Siguen sin autorizar: sacar el proyecto de OneDrive, versionar `app/pubspec.lock` y cambiar la firma.
- **Documentos:** puestos al día el 04-11-2026 y revisados por el arquitecto y por dos verificadores independientes. El índice con el estado de cada documento está en [docs/README.md](../../docs/README.md) y hay registros de decisión nuevos (ADR 0003 a 0012).
- **Decididas el 04-11-2026:** reglas 5, 9, 10, 11 y 20; pregunta 21 (3 a 5 personas); prueba de concepto gráfica autorizada con ambos estilos y arte gratuito; Mac confirmado desde el 12-07-2026 (ver "Decisiones vigentes").
- **Preguntas abiertas:** 6, 7, 8, 12, 13, 14, 15, 16, 17, 18, 19, 22 (solo el iPhone) y 23 (nueva). Detalle en la [sección 5 de la auditoría](../revisiones/2026-11-04-auditoria-proyecto.md#5-decisiones-que-necesito-de-ti) y abajo.
- **Cómo se juega hoy:** `JUGAR.bat` abre http://localhost:8123 (web local). `COMPILAR-ANDROID.bat` genera el APK.
- **Estado verificado en el código:** 54 tests en `tools/test` y 26 en `app/test`; tableros 6×6, 8×8, 9×9, 12×12 y 16×16 (solo los tres primeros tienen casos); `shared_preferences`; sin audio, vibración, traducciones ni lectores de pantalla.
- **Próximos pasos:**
  1. ~~Alejandro crea el repositorio privado en GitHub y Claude sube el historial.~~ Hecho el 04-11-2026.
  2. ~~Alejandro consigue sus propias referencias visuales.~~ Las envió el 05-11-2026.
  3. ~~Preparar la versión de prueba de la etapa 1.~~ Hecho el 05-11-2026. Falta la guía de la prueba de juego, con hoja de registro y umbrales a acordar con Alejandro.
  4. Alejandro instala la versión de prueba y el prototipo en su Android de gama media. Mide la fluidez del prototipo y compara las pieles; arranca la prueba de juego con 3 a 5 personas.


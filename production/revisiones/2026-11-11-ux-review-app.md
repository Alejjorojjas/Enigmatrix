# Revisión de UX: la app (versión 0.8.1+11)

- **Fecha:** 11-11-2026
- **Skill:** `/ux-review` (rigor `minimal`)
- **Código revisado:** la copia `Enigmatrix-revision-ccgs` (versión 0.8.1+11, más nueva que esta rama).
- **Alcance:** solo revisión, sobre el código y los documentos. **No se abrió la app** ni se tomaron capturas: lo visual queda sin verificar. No se modificó ningún archivo del proyecto. Este informe no tiene commit.

## Qué se usó como especificación

La skill espera especificaciones de UX en `design/ux/`. Este proyecto no las tiene: su equivalente es:

| Rol en la skill | Archivo del proyecto |
|---|---|
| Especificación de pantallas | `docs/06-pantallas-ui.md` (unas 50 pantallas, PARCIALMENTE OBSOLETO según el índice) |
| Nivel de accesibilidad comprometido | `docs/11-accesibilidad.md`: WCAG 2.1 AA como meta de la V1. Ojo: el índice lo marca VISIÓN FUTURA, así que el nivel se toma como **supuesto**, no como compromiso firmado |
| Biblioteca de patrones | No existe (`design/ux/interaction-patterns.md`). En rigor `minimal` no se exige |
| Alcance de la V1 | ADR-0014 y `app/lib/src/ui/v1_scope.dart` |

Se usó la lista de la fase 3A (especificación de UX), adaptada: cada requisito del doc 11 se contrastó con el código de `app/lib`.

## Veredicto: NEEDS REVISION

- **Bloqueantes:** 2. Deben resolverse o decidirse antes de la publicación abierta, no de la prueba interna.
- **Recomendados:** 6.
- **Dimensiones sin evaluar:** 2. La revisión visual (contraste real, recortes de texto al 130 y al 150 %, distribución) necesita capturas de la app en un teléfono. La biblioteca de patrones no existe y en `minimal` no se exige.

La base de accesibilidad es **mucho mejor de lo que dicen los documentos**: casi todo lo que el doc 11 lista como "no existe" ya está hecho. Los huecos que quedan son pocos y concretos.

## Lo que ya cumple (comprobado en el código)

| Requisito del doc 11 | Evidencia |
|---|---|
| Lector de pantalla en el tablero: casillas anunciadas con su contenido | `app/lib/src/ui/board_semantics.dart`: un nodo por casilla con fila, columna, habitación, mueble, candidatos y confirmado, más las acciones de tocar y mantener oprimido. No revela la solución |
| Mensajes de error y de éxito anunciados | `Semantics(liveRegion: true)` en `game_screen.dart:1062` y en `tutorial_coach.dart:498` |
| `Semantics` en las pantallas principales | Aparece en 9 archivos de interfaz (`game_screen`, `game_toolbar`, `game_tray`, `game_chrome`, `ui_kit`, `tutorial_coach`, `bank_screen`…) |
| Alternativa al arrastre por toque | `doubleTapConfirm = true` en `app/lib/src/game/board_interaction.dart` |
| Aviso "Elige primero a un sospechoso" | `PlacementProblem.noSuspect` en `src/board/feedback/feedback_director.dart:238` |
| Escala de letra del sistema respetada | `MediaQuery.textScalerOf` en `game_screen`, `game_tray`, `home_shell` y `layout_metrics` (las filas crecen con la escala) |
| Texto mínimo | No hay ningún `fontSize` menor de 12 en `app/lib` (el doc 11 hablaba de textos de 11 px) |
| Toque mínimo de 48 en botones | `minTouch` en `skin_theme.dart:281,337`; `Size(0, 48)` en `game_menu.dart` |
| Reducir animaciones | Opción `cfg:movimiento-reducido` (`app_settings.dart:44`) y además lee la preferencia del sistema (`MediaQuery.disableAnimationsOf`, `game_screen.dart:163`) |
| Vibración y sonido con interruptor propio | `cfg:vibracion` y `cfg:sonido` en `app_settings.dart` |
| El error no depende solo del color | Resolver fallido muestra texto con el conteo ("3 casillas no cuadran", `boardWrongCells`) |

## Bloqueantes

1. **No existe el modo daltónico.** El doc 11 lo pone como opción "que entra a V1" (líneas 64 y 204), y no aparece en `app_settings.dart` ni en ninguna parte de `app/lib`. El riesgo está acotado: los colores de las habitaciones son la pista visual principal del mapa (pilar 5), y el error ya se comunica con texto.
   - **Decisión de Alejandro:** (a) hacerlo para la V1; (b) aplazarlo a la V1.1 y validar antes con un simulador que las habitaciones se distinguen por algo más que el color (paredes, nombre en la vista Mapa).
   - **Recomendación:** (b), con la validación de los tres tipos de daltonismo como condición para la publicación abierta.
2. **Casillas del tablero por debajo de 48 en Intermedio (9×9). Sin verificar.** En un teléfono de 360 dp de ancho, una grilla de 9 casillas deja unos 36 a 38 dp por casilla, menos que el mínimo de 48 del doc 11 (línea 98). No pude medirlo sin la app.
   - **Qué hacer:** medirlo en el teléfono más angosto de prueba. Si queda por debajo, decidir si el tablero es una excepción documentada (lo es en casi todos los juegos de grilla) y apoyarse en la confirmación por toque doble y en la papelera grande.

## Recomendados

3. **El doc 11 describe una app que ya no existe.** Su bloque "Estado real hoy" (líneas 5 a 11) dice que no hay `Semantics`, ni audio, ni vibración, ni traducción, y que hay textos de 11 px. Todo eso cambió. Quien lo lea concluirá que la accesibilidad está por hacer. Hay que reescribir ese bloque con la tabla "Lo que ya cumple" de arriba.
4. **Pruebas obligatorias del doc 11 sin evidencia** (líneas 220 a 226): contraste automático, simulador de daltonismo, TalkBack en las pantallas principales, escala al 130 y al 150 % y medida de toque. No encontré registro de ninguna. Son una o dos horas con un teléfono y conviene hacerlas antes de la publicación abierta.
5. **Desactivar la rotación del mapa** (doc 11, línea 187). La rotación antitrampa no existe, así que la opción sobra hoy. Hay que marcarla "no aplica mientras no haya rotación".
6. **Bloqueo de capturas** (doc 11, líneas 178 a 183). Tampoco existe. Mismo tratamiento.
7. **VoiceOver en iPhone.** Con el iPhone ya en el alcance de la V1 (09-11-2026), el requisito "VoiceOver cuando aplique" pasa a aplicar. El código usa `Semantics` de Flutter, que sirve para los dos, pero hay que probarlo en TestFlight.
8. **El doc 06 (pantallas) frente a la versión de tienda.** El ADR-0014 y `v1_scope.dart` muestran Experto, Élite y los mundos 2 a 5 como "Próximamente". El doc 06 describe 50 pantallas de la visión completa. Para la tienda conviene una lista corta de "pantallas que ve el jugador en la 0.8.x" que sirva de especificación real y de guion para las capturas de la ficha.

## Alineación con el diseño (doc 06 y ADR-0014)

**GAPS FOUND (menores).** Lo que el código muestra respeta el alcance del ADR-0014: tres dificultades jugables, La Mansión disponible y el resto "Próximamente". Las diferencias son de documentación (punto 8), no de comportamiento. No pude comprobar pantalla por pantalla sin abrir la app.

## Accesibilidad: GAPS

- **Nivel supuesto:** WCAG 2.1 AA, tomado del doc 11. No hay `design/accessibility-requirements.md`, y el índice marca el doc 11 como VISIÓN FUTURA. Si Alejandro quiere que este nivel sea el compromiso de la V1, hay que pasar el doc 11 a VIGENTE.
- **Huecos:** el modo daltónico (bloqueante 1), el tamaño de casilla (bloqueante 2) y las pruebas sin hacer (punto 4).

## Biblioteca de patrones: N/A

En rigor `minimal` no se exige.

## Lo que no se pudo verificar

- Contraste real de las dos pieles (Ilustrada y Papel) en modo claro y oscuro: hacen falta capturas.
- Recortes de texto al 130 y al 150 % de escala.
- Tamaño real de casilla en un teléfono angosto.
- Comportamiento de TalkBack y VoiceOver en uso real.

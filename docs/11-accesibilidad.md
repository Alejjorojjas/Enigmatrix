# Enigmatrix - Accesibilidad

> ACTUALIZACIÓN 04-11-2026: este documento fija los requisitos de accesibilidad de la **V1 final**; el prototipo de la Fase 1 casi no los cumple todavía y el arreglo de fondo va con el diseño nuevo (etapa 4 del plan). Se conserva todo el texto. Auditoría: `production/revisiones/2026-11-04-auditoria-proyecto.md` (H-25, H-31, H-56).
>
> **ACTUALIZACIÓN 11-11-2026 (revisión de UX y CCGS; `production/revisiones/2026-11-11-ux-review-app.md`, sección "Lo que ya cumple"):** el bloque "Estado real hoy" de abajo describe una app que ya no existe. Comprobado en el código de `app/lib/` el 11-11-2026 (versión 0.8.1+11):
>
> | Requisito de este documento | Estado hoy | Evidencia |
> |---|---|---|
> | Lector de pantalla en el tablero | **Hecho**: un nodo por casilla con fila, columna, habitación, mueble, candidatos y confirmado; no revela la solución | `app/lib/src/ui/board_semantics.dart` |
> | Mensajes de error y éxito anunciados | **Hecho** | `Semantics(liveRegion: true)` en `game_screen.dart` y `tutorial_coach.dart` |
> | `Semantics` en las pantallas principales | **Hecho** (9 archivos de interfaz según la revisión de UX; 11 según la revisión CCGS) | `game_screen`, `game_toolbar`, `game_tray`, `game_chrome`, `ui_kit`, `tutorial_coach`, `bank_screen`... |
> | Alternativa al arrastre por toque | **Hecho** | `doubleTapConfirm = true` en `app/lib/src/game/board_interaction.dart` |
> | Aviso "Elige primero a un sospechoso" | **Hecho** | `PlacementProblem.noSuspect` en `src/board/feedback/feedback_director.dart` |
> | Escala de letra del sistema | **Hecho** | `MediaQuery.textScalerOf` en `game_screen`, `game_tray`, `home_shell` y `layout_metrics` |
> | Texto mínimo | **Hecho**: ningún `fontSize` menor de 12 | `app/lib/` |
> | Toque mínimo de 48 en botones | **Hecho** | `minTouch` en `skin_theme.dart`; `Size(0, 48)` en `game_menu.dart` |
> | Reducir animaciones | **Hecho**, y lee también la preferencia del sistema | `cfg:movimiento-reducido` en `app_settings.dart`; `MediaQuery.disableAnimationsOf` en `game_screen.dart` |
> | Vibración y sonido con interruptor propio | **Hecho** | `cfg:vibracion` y `cfg:sonido` en `app_settings.dart` |
> | El error no depende solo del color | **Hecho**: texto con el conteo de casillas | `boardWrongCells` |
> | Audio y vibración | **Hecho** (13 sonidos desde la 0.3.0) | doc 12 |
> | Traducción | **Hecho** el sistema (308 claves en `app_es.arb`); solo español en la V1 | `app/lib/l10n/` |
> | Modo daltónico | **No existe**; decidido 11-11-2026: pasa a la **V1.1** (ver abajo) | no aparece en `app_settings.dart` |
> | Desactivar rotación del mapa | **No aplica mientras no haya rotación** (la rotación antitrampa no existe) | doc 03, Antitrampa |
> | Bloqueo de capturas | **No aplica mientras no exista**; tampoco existe hoy | doc 03, Antitrampa |
>
> **Decisiones de Alejandro del 11-11-2026 sobre este documento (ADR-0014, sección "Decisiones de Alejandro (11-11-2026)"):**
> - **Daltonismo:** el modo daltónico **pasa a la V1.1**. Antes de la **publicación abierta** hay que validar con un simulador de daltonismo (los tres tipos) que las habitaciones se distinguen también por paredes y nombres, no solo por color. Si no se distinguen, se corrige antes de esa publicación. Donde este documento dice que el modo daltónico "entra a V1", queda SUPERADO 11-11-2026.
> - **Excepción al mínimo de 48 px en el 9×9:** las casillas del tablero Intermedio (9×9) miden unos 37 px en un teléfono de 360 de ancho. Se acepta como **excepción documentada** al mínimo de 48 por 48 de "Objetivos de toque y motricidad". Se apoya en la confirmación por toque doble y en la papelera grande. Alejandro lo prueba en su teléfono y, si resulta incómodo, se corrige. Los botones y controles fuera del tablero siguen en 48.
> - **VoiceOver:** con el iPhone en la V1 (09-11-2026), el requisito "VoiceOver cuando aplique" pasa a aplicar. `Semantics` de Flutter sirve para los dos sistemas, pero falta probarlo en TestFlight.
> - **Pruebas obligatorias sin evidencia** (sección "Validación antes del lanzamiento": contraste automático, simulador de daltonismo, TalkBack, escala al 130 y 150 %, medida de toque): no hay registro de ninguna. Quedan **pendientes antes de la publicación abierta**, no de la prueba interna.
> - Este documento sigue marcado VISIÓN FUTURA en el índice; WCAG 2.1 AA se toma como supuesto y pasa a ser el compromiso de la V1 solo si Alejandro lo confirma.
>
> (SUPERADO 11-11-2026) El bloque "Estado real hoy" siguiente se conserva como historial del 04-11-2026.

> **Estado real al 04-11-2026 (SUPERADO 11-11-2026; ver la tabla de arriba), comprobado entonces en el código de `app/lib/`:**
> - No hay soporte para lectores de pantalla: el código no usa `Semantics` ni etiquetas accesibles en ninguna parte, y los íconos de la barra inferior no tienen etiqueta ni tooltip.
> - Las casillas con error se marcan **solo con un tinte de color rojo** (sin borde, patrón ni ícono), y los textos de ayuda y de las pistas llegan a medir unos 11 px, por debajo del mínimo de este documento.
> - No hay audio ni vibración en la app. Los interruptores de sonido, música y vibración de Configuración se guardan pero no hacen nada.
> - Los textos están fijos en español (no hay traducción preparada).
> - No existen el modo daltónico, "reducir animaciones" ni "desactivar rotación" (el mapa tampoco rota).
> - Un arreglo mínimo, ver la pista completa al tocarla, está previsto en la versión de prueba de la etapa 1 (H-56).
>
> **Decisiones de Alejandro del 04-11-2026 que tocan este documento:** ninguna cambia sus requisitos. La meta visual del rediseño ("pocas pantallas muy pulidas") deberá cumplirlos.

## Objetivo de este documento
Definir los requisitos minimos de accesibilidad de Enigmatrix V1, para que el juego sea jugable por la mayor cantidad posible de personas sin sacrificar el diseno.

Cubre:

- estandar de referencia
- color y contraste
- daltonismo
- texto y escala
- objetivos de toque y motricidad
- navegacion por lectores de pantalla
- subtitulos y audio alternativo
- preferencias de movimiento
- tensiones con el sistema antitrampa
- opciones del jugador
- pendientes

## Estandar de referencia
- WCAG 2.1 nivel AA como meta para V1
- WCAG 2.2 nivel AA como meta a futuro
- guias de accesibilidad de Material 3 para Android
- guias de accesibilidad de Apple para iOS cuando aplique

## Color y contraste

### Reglas
- todo texto contra su fondo cumple ratio de contraste 4.5 a 1 minimo
- texto grande cumple ratio 3 a 1 minimo
- elementos interactivos cumplen ratio 3 a 1 minimo contra su entorno
- el feedback de exito y error nunca depende solo del color

### Reforzadores no cromaticos
- exito: color verde mas icono de confirmacion mas mensaje
- error: color rojo mas borde grueso mas icono mas mensaje
- destacado: color azul mas borde mas icono
- alerta: color amarillo mas icono mas mensaje

## Daltonismo

### Tipos cubiertos
- protanopia
- deuteranopia
- tritanopia

### Estrategia
- la paleta funcional se valida contra simuladores de los 3 tipos
- se ofrece un modo daltonico alterno como opcion en configuracion
- el modo daltonico cambia los colores de feedback por una paleta de alto contraste con formas distintivas

### Modo daltonico

> **ACTUALIZACIÓN 11-11-2026:** el modo daltónico pasa a la **V1.1** (decisión de Alejandro, ADR-0014). Para la publicación abierta de la V1 basta validar con un simulador (los tres tipos) que las habitaciones se distinguen por paredes y nombres. Lo de abajo es el diseño previsto para la V1.1.

- exito: azul saturado mas icono de confirmacion
- error: naranja saturado mas borde dentado
- alerta: amarillo neutro mas icono de exclamacion
- destacado: morado saturado

### Reglas de juego asociadas
- las casillas con error siempre se diferencian con borde y patron, no solo color
- los avatares confirmados siempre llevan flecha, no solo verde

> ACTUALIZACIÓN 04-11-2026 (H-25): el confirmado de hoy es un círculo con la ficha del personaje, sin la "flecha verde" del modelo anterior (`docs/03-reglas-del-juego.md`, sección superada). Cuando se rediseñe el tablero hay que fijar qué refuerzo no cromático lleva, y el marcado de casillas con error está sujeto a la pregunta 9 (**DECIDIDA 04-11-2026**, ver ADR-0012: en el juego normal solo se muestra cuántas casillas no cuadran; el marcado exacto de casillas con error queda solo para el tutorial, y ahí debe llevar borde y patrón, no solo color).
- las pistas destacadas siempre llevan icono, no solo color

## Texto y escala

### Tamanos minimos
- texto principal: equivalente a 14 puntos en pantallas medianas
- numeros del cronometro y puntos: legibles sin zoom
- texto de pistas: equivalente a 16 puntos

### Escala dinamica
- la app respeta el escalado de fuente del sistema operativo
- la UI se adapta sin romperse a 130 por ciento de escala
- la UI sigue siendo usable a 150 por ciento aunque algunos elementos pierdan elegancia
- a 200 por ciento o mas se garantiza el funcional, no el estetico

### Reglas
- ningun texto critico se trunca sin acceso al completo
- los tooltips son tocables, no solo visibles al pasar
- los nombres de los sospechosos no se cortan si caben en su panel

## Objetivos de toque y motricidad

### Tamanos
- area minima de toque: 48 por 48 puntos
- **Excepción documentada 11-11-2026:** las casillas del tablero 9×9 (Intermedio) miden unos 37 px en un teléfono de 360 de ancho, por debajo de este mínimo. Decidido por Alejandro el 11-11-2026 (ADR-0014); se apoya en la confirmación por toque doble y en la papelera grande. Se revisa con la prueba en su teléfono.
- separacion minima entre elementos tocables adyacentes: 8 puntos
- la papelera es siempre suficientemente grande para arrastrar sin precision fina

### Arrastre
- el arrastre tolera variacion en la trayectoria
- al soltar cerca de una casilla valida, el sistema asume la intencion del jugador
- los gestos rapidos no descartan elementos por accidente

### Alternativa al arrastre
- toque para seleccionar mas toque para colocar es valido como alternativa al arrastre
- la opcion se activa desde configuracion y no penaliza al jugador
- esta opcion debe estar disponible en V1

> **DECIDIDO 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". Hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto (etapa 2).
>
> Requisitos de accesibilidad que se derivan: el modo de tocar dos veces es la alternativa por toque que pide este documento y debe poder usarse sin mantener oprimido ni arrastrar; el aviso "Elige primero a un sospechoso" se anuncia a los lectores de pantalla y no depende solo del color ni de un texto pequeño; y el modo alternativo queda disponible desde la V1 (ver arriba). El diseño exacto se hace en la prueba de concepto gráfica (etapa 2).
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 20, H-25): gesto para confirmar a un personaje. Versión de este documento: "toque para seleccionar más toque para colocar" como alternativa al arrastre. Versión del juego de hoy (`docs/16-spec-puzzle.md`, sección 4): **tocar una casilla anota un candidato y confirmar exige mantener oprimido o arrastrar la ficha**. Ese gesto es poco descubrible, puede parecer que la app no responde, y no hay una alternativa por toque, así que hoy **no se cumple** la alternativa que pide este documento. Tocar una casilla sin sospechoso elegido tampoco da respuesta (solo hay un párrafo gris de 11 px con la explicación). Recomendación de la auditoría (solo recomendación): mostrar el aviso "Elige primero a un sospechoso" y agregar un modo alternativo de tocar dos veces, diseñado en la prueba de concepto gráfica. Falta que Alejandro decida.

### Tap repetido

> ACTUALIZACIÓN 04-11-2026 (H-25): hoy el ciclo por toques repetidos existe solo para la **X** (X pequeña, X grande, sin herramienta). Para los sospechosos tocar la ficha solo la selecciona o la deselecciona; el paso de candidato a confirmado ya no es un segundo toque (ver el pendiente de arriba).

- los ciclos de estado para sospechoso y X tienen feedback inmediato
- doble tap accidental no provoca acciones destructivas sin confirmacion

## Navegacion por lectores de pantalla

### Compatibilidad
- TalkBack en Android
- VoiceOver en iOS cuando aplique

### Cobertura V1
- pantallas de cuenta, login, registro, configuracion accesibles
- pantallas de inicio, mundos, ranking, tienda accesibles
- pantalla de partida con cobertura basica:
  - sospechosos del panel anunciados con nombre y estado
  - casillas anunciadas con su contenido actual
  - boton resolver, ayudas, papelera anunciados
  - mensaje de error y de exito anunciados

### Limites aceptables en V1
- la lectura completa del tablero como mapa visual queda como una experiencia limitada
- el jugador con lector de pantalla puede entender la informacion, pero no se garantiza la misma fluidez de juego que en visual

### Etiquetado
- todos los elementos interactivos tienen etiqueta accesible
- los iconos sin texto tienen descripcion accesible
- los avatares de sospechosos tienen nombre asociado

## Subtitulos y audio alternativo

### Reglas
- ningun audio comunica informacion critica sin reforzador visual
- la musica y los efectos pueden silenciarse desde configuracion
- las animaciones celebratorias no dependen del audio para entenderse

### Si en futuro hay narracion hablada
- subtitulos obligatorios sincronizados
- subtitulos toggle desde configuracion
- contraste y tamano cumpliendo el resto de reglas de texto

## Preferencias de movimiento

### Reduccion de movimiento
- opcion en configuracion: reducir animaciones
- al activarse:
  - desaparece la animacion de desbloqueo de mundo larga
  - las transiciones largas se reemplazan por fades cortos
  - el feedback de error pulsante se reemplaza por un parpadeo unico (nota 04-11-2026: el parpadeo de la pista en conflicto solo existe en el tutorial, pregunta 9)
- las animaciones esenciales para entender una accion se mantienen

### Vibracion y haptics
- toggle independiente desde configuracion
- nunca se asume que la vibracion comunica informacion critica
- la vibracion es siempre un refuerzo, nunca un canal exclusivo

## Tensiones con el sistema antitrampa

### Bloqueo de capturas
> **ACTUALIZACIÓN 11-11-2026:** no aplica mientras no exista el bloqueo de capturas (hoy no existe; es visión de la etapa 5B).

- aplica solo en partida oficial y reto diario
- no aplica en tutorial, practica ni como jugar
- documentar publicamente que las capturas estan bloqueadas en partida oficial
- si un usuario depende de capturas para accesibilidad, se le ofrece practica como alternativa
- los lectores de pantalla siguen funcionando aunque la captura este bloqueada

### Rotacion del mapa
> **ACTUALIZACIÓN 11-11-2026:** no aplica mientras no exista la rotación antitrampa (hoy el mapa no rota); la opción "desactivar rotación" sobra por ahora.

- la rotacion puede ser dificil para personas con motricidad reducida o con dispositivos asistidos
- opcion en configuracion: desactivar rotacion del mapa
- al desactivarla:
  - la partida sigue siendo oficial y puntuable
  - los textos del mapa se mantienen orientados al jugador como ya hacen por defecto
  - se mantiene el resto de antitrampa
- la opcion se documenta como ayuda de accesibilidad, no como ventaja

### Tiempo siempre corriendo

> ACTUALIZACIÓN 04-11-2026: el reloj y qué pasa al salir de la partida quedaron **DECIDIDOS 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre y, al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real; se revisa antes de la etapa 5 (con ranking real, la regla de abajo de que el tiempo no se pausa y descuenta bloqueos del servidor puede volver). Ver `docs/03-reglas-del-juego.md`, sección "Tiempo".

- ~~el tiempo no se pausa~~ (SUPERADO 04-11-2026 mientras no haya ranking real; se revisa antes de la etapa 5), pero el sistema reconoce automaticamente bloqueos del propio servidor y los descuenta
- nunca se descuenta tiempo manualmente por peticion

## Opciones del jugador en configuracion

### Opciones nuevas que entran a V1
- ~~modo daltonico~~ (SUPERADO 11-11-2026: pasa a la V1.1, ver "Modo daltonico")
- alternativa al arrastre por toque
- reducir animaciones
- ~~desactivar rotacion del mapa~~ (no aplica mientras no haya rotacion, 11-11-2026)
- vibracion y haptics
- escala de texto del sistema respetada por defecto

### Opciones que mantenemos
- sonido
- musica
- vibracion y haptics
- idioma
- notificaciones

## Validacion antes del lanzamiento

### Pruebas obligatorias
> **Estado 11-11-2026:** ninguna tiene registro de haberse hecho; se hacen antes de la publicación abierta (no de la prueba interna). La de daltonismo, con simulador y los tres tipos, es condición para esa publicación (decisión del 11-11-2026). VoiceOver en iPhone se prueba en TestFlight.

- contraste validado con herramientas automaticas
- daltonismo validado con simuladores en las 3 variantes
- TalkBack validado en pantallas principales
- escala de fuente probada al 130 y 150 por ciento
- tamano de toque medido con grilla en pantallas pequenas
- tiempo de respuesta del feedback validado para no superar 100 ms en interacciones criticas

### Pruebas con usuarios reales
- sesiones con jugadores con baja vision
- sesiones con jugadores con motricidad reducida
- sesiones con jugadores daltonicos
- sesiones con jugadores que usen TalkBack o VoiceOver
- documentar hallazgos y priorizar fixes antes de release

## Pendientes
- definir paleta exacta del modo daltonico en hex
- decidir si la lectura del tablero por TalkBack mejora a un modo dedicado en futuro
- explorar alternativa de juego por teclado o gamepad
- decidir si las pistas tienen lectura sintetica como ayuda futura

# Enigmatrix - Pantallas UI

> **ACTUALIZACIÓN 11-11-2026 (versión de tienda 0.8.1+11, "Murdoku Diario"; revisión CCGS 5.4 y de UX punto 8):** lo que ve el jugador en la versión de tienda es una lista corta; el resto del documento es la visión completa. Rutas de `app/lib/main.dart`: carga (`/`), Inicio con sus pestañas (`/home`), lista de casos del Mundo 1 (`/casos`), partida (`/play/:id`, con selector Mapa/Notas, mini panel y victoria) y tutorial (`/tutorial`). El **banco de pruebas** (`/banco`), el feedback de prueba y el medidor de FPS solo existen con `ENX_DEV=true`, no en la tienda. La versión de tienda **oculta las pantallas simuladas** (Tienda, Premium, Ranking, vidas, racha, protectores, puntos de la semana y estadísticas simuladas): `kShowSimulated = kEnxDev` en `app/lib/src/game/dev_tools.dart` (decisión 18, 06-11-2026; rama `fix/creditos-seguridad-y-documentos`). Experto, Élite y los mundos 2 a 5 se muestran "Próximamente" y no se abren (`app/lib/src/ui/v1_scope.dart`, ADR-0014). La V1 sale **sin ayudas ni puntos** (pregunta 12, 11-11-2026): la victoria muestra tiempo y errores. Esta lista sirve de especificación real y de guion para las capturas de la ficha de la tienda; no se contrastó pantalla por pantalla con la app abierta.
>
> (SUPERADO 11-11-2026) Las rutas y el "aviso del prototipo" de los bloques de abajo hablan de constantes en `home_shell.dart`: los datos simulados viven hoy en `mock_data.dart`, `v1_scope.dart`, `home_tabs.dart` y `home_sheets.dart`.

> ACTUALIZACIÓN 04-11-2026: este documento lista las ~50 pantallas de la **app completa**. El prototipo de la Fase 1 implementa solo una parte, y su diseño visual está en revisión (etapa 2 del plan, prueba de concepto gráfica). Se conserva el texto original salvo donde se marca **SUPERADO**. Auditoría: `production/revisiones/2026-11-04-auditoria-proyecto.md` (H-25, H-28 a H-31).
>
> **Aviso del prototipo (Fase 1).** En el juego de hoy las pantallas de vidas, racha, reto diario, ranking, tienda, premium y las estadísticas del perfil usan **datos simulados** (constantes escritas en `app/lib/src/ui/home_shell.dart`, aprobadas el 12-07-2026). No hay servidor ni cuentas. Lo que este documento dice sobre esas pantallas es la intención de la Fase 2 en adelante, no lo que la app hace hoy.
>
> **Qué existe hoy en la app** (rutas de `app/lib/main.dart` y `app/lib/src/ui/`): carga (01), Inicio (12), Mundos (14), lista de casos del mundo (15, simplificada, ruta `/casos`), partida (19 con 20/21 como selector Mapa/Notas, 22 mini panel, 26 y 27 simplificadas), victoria (28 simplificada), un Reto diario simulado (32), un Ranking simulado (36), Perfil (41 simplificado), y como hojas modales Tienda (43), Premium (44) y Configuración (45), más el diálogo de 5 páginas de Cómo jugar (46) y el tutorial jugable (09). **No existen** las pantallas de cuenta (02 a 05, 13), la previa del mapa como pantalla propia (16 es una hoja con datos del caso), las de partida pendiente (17 y 18), los paneles de ayudas y de vidas (23 a 25), los resúmenes de práctica, mundo y reto (29, 30, 34), la racha ampliada (35), los detalles de ranking y de perfil público (37 a 40), el cambio de nickname con validación (42), soporte, cerrar sesión, eliminar cuenta y sin conexión (47 a 50).

## Objetivo de este documento
Este documento aterriza Enigmatrix en pantallas concretas de interfaz para que despues sea mas facil:

- diseñar wireframes
- crear mockups
- dividir trabajo de frontend
- definir navegacion real
- pasar a codigo sin ambiguedades

## Navegacion general

> ACTUALIZACIÓN 04-11-2026 (H-31): **la navegación de abajo quedó SUPERADA** y se conserva como historial. Lo que hace la app hoy (`app/lib/src/ui/home_shell.dart` y las rutas de `app/lib/main.dart`):
>
> - **Barra inferior de 5 pestañas, solo íconos, sin texto:** Inicio, Mundos, Reto, Ranking y Perfil. La activa se enmarca. Decisión consciente del 12-07-2026 (referencia: la barra de Duolingo, versión papel).
> - **Mundos** muestra los 5 mundos; solo La Mansión está desbloqueada y los otros cuatro se ven con candado. Contradecía el "solo mundos desbloqueados visibles" de la pantalla 14 de este documento; **DECIDIDO 06-11-2026 (pregunta 23):** se muestran los mundos bloqueados con candado. ~~Antes: PENDIENTE DE DECISIÓN.~~
> - **Perfil** da acceso a Tienda, Premium, Cómo jugar y Configuración. Tienda, Premium y Configuración son hojas modales que suben desde abajo (no pantallas), y "Cómo jugar" es un diálogo de 5 páginas. No hay menú lateral.
> - **No hay barra superior persistente.** Las vidas simuladas aparecen solo en Inicio.
> - **Rutas:** carga (`/`), `/home` (las 5 pestañas), `/casos` (lista de casos), `/play/:id` (partida, con `?tutorial=1` para el tutorial jugable). Atrás en la partida y "Continuar" en la victoria vuelven a `/` y pasan otra vez por la pantalla de carga.
> - **Accesibilidad:** los íconos de la barra no tienen etiqueta ni tooltip, y la app no usa `Semantics` en ninguna parte (ver `docs/11-accesibilidad.md`).

**Texto original (superado):**

### Navegacion principal
- Menu inferior:
  - Inicio
  - Mundos
  - Reto diario
  - Ranking

### Navegacion secundaria
- Menu lateral o secundario:
  - Perfil
  - Tienda
  - Premium
  - Configuracion
  - Como jugar

### Elementos persistentes
- Barra superior visible en pantallas principales con:
  - vidas actuales
  - tiempo para la proxima vida
  - nickname
  - avatar
  - bandera/pais

## Lista de pantallas

### 01. Splash / carga inicial
Funcion:
- cargar estado base de la app
- revisar sesion
- revisar conexion
- revisar desbloqueos pendientes

Muestra:
- logo de Enigmatrix
- indicador de carga

Estados especiales:
- reconexion automatica
- flujo pendiente de anuncio para desbloqueo de mundo

### 02. Login y acceso
Funcion:
- permitir entrar con Google o email

Muestra:
- boton Google
- boton login email
- boton registro email
- links a terminos y politica

### 03. Registro con email
Funcion:
- crear cuenta con email y contrasena

Muestra:
- email
- contrasena
- aceptar terminos
- aceptar politica
- boton crear cuenta

### 04. Login con email
Funcion:
- iniciar sesion con email y contrasena

Muestra:
- email
- contrasena
- boton iniciar sesion
- recuperar contrasena

### 05. Configuracion inicial de perfil
Funcion:
- completar los datos obligatorios antes del tutorial

Version Google:
- avatar cargado desde Google por defecto
- nickname unico obligatorio
- bandera/pais obligatoria
- opcion de cambiar avatar

Version email:
- elegir avatar predeterminado
- nickname unico obligatorio
- bandera/pais obligatoria

### 06. Bienvenida 1
Funcion:
- explicar que es Enigmatrix

Muestra:
- mensaje corto del concepto central
- ilustracion o apoyo visual
- continuar

### 07. Bienvenida 2
Funcion:
- explicar reto diario

Muestra:
- mensaje corto
- ilustracion
- continuar

### 08. Bienvenida 3
Funcion:
- explicar rankings y racha

Muestra:
- mensaje corto
- ilustracion
- continuar

### 09. Tutorial guiado
Funcion:
- enseñar el juego con un caso facil

Muestra:
- mapa simplificado
- pistas
- panel de sospechosos
- notas
- boton resolver
- ayudas

Comportamientos:
- pasos obligatorios
- acciones bloqueadas hasta completar lo correcto
- prueba de ambos modos de notas
- demostracion de error al resolver
- demostracion de ayuda

(Lista de comportamientos original; el alcance vigente está en el bloque DECIDIDO de abajo.)

> **DECIDIDO 04-11-2026** (auditoría, pregunta 11; ver ADR-0012): el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
>
> Para esta pantalla 09: el tutorial usa un caso propio pequeño (no el Caso 1), con botón **Saltar** siempre visible. Enseña la X, las notas (selector Mapa / Notas), la papelera y un Resolver fallido; en ese Resolver fallido del tutorial sí se muestra el resaltado exacto y el parpadeo de la pista en conflicto (pregunta 9). Las ayudas dependen de la pregunta 12 (pendiente) y la pantalla 10 (modo preferido) quedó sin función mientras no haya dos modos de notas.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 11, H-29): tutorial. Este documento pide un tutorial obligatorio con pasos que bloquean acciones. Hoy hay **dos** tutoriales que se pueden omitir: el diálogo de 5 páginas ("Omitir") y el tutorial jugable de 7 pasos ("Saltar"), que usa el Caso 1 y no bloquea acciones. No enseña la X manual, el borrador, Mapa/Notas ni un Resolver fallido, y no hay ayudas. Además la tarjeta de instrucciones puede tapar las pistas. Recomendación de la auditoría (solo recomendación): un caso propio de 4×4 o 5×5, obligatorio la primera vez con botón Saltar visible. Falta que Alejandro decida.


### 10. Eleccion de modo preferido
Funcion:
- dejar configurado el modo de notas por defecto

Muestra:
- opcion notas separadas
- opcion superposicion
- boton confirmar

### 11. Resumen del tutorial
Funcion:
- cerrar el tutorial

Muestra:
- tiempo
- errores
- ayudas
- puntuacion visual
- continuar

Primera vez:
- anuncio si no es premium
- desbloqueo de Mundo 1

Rejugado:
- vuelve a Como jugar

### 12. Inicio
Funcion:
- pantalla central del usuario

Muestra tarjetas en prioridad:
1. Verifica tu correo
2. Reto diario
3. Continuar partida pendiente
4. Mundo actual

Adicional:
- accesos de navegacion
- barra superior persistente
- indicador de sin conexion si aplica

> ACTUALIZACIÓN 04-11-2026: el Inicio real tiene saludo, vidas simuladas, tarjeta de Reto diario (simulada), tarjeta del Mundo 1 (casos cerrados reales) y tarjeta de Tienda (DEMO). No hay tarjeta de verificar correo ni de partida pendiente, ni barra superior ni indicador de conexión.

### 13. Modulo de verificacion de correo
Funcion:
- explicar bloqueo por correo no verificado

Muestra:
- mensaje de verificacion requerida
- correo actual
- reenviar correo
- cambiar correo

### 14. Mundos
Funcion:
- mostrar mundos desbloqueados

Muestra:
- lista o carrusel de mundos
- nombre del mundo
- miniatura del mundo
- ~~solo mundos desbloqueados visibles~~ (SUPERADO 06-11-2026: se ven también los bloqueados, con candado)

> ACTUALIZACIÓN 06-11-2026: **DECIDIDO** (auditoría, pregunta 23): los mundos bloqueados **se muestran con candado**. Es lo que ya hace la app de hoy (5 mundos, los 4 bloqueados atenuados y con candado); la función y la línea "solo mundos desbloqueados visibles" de esta pantalla quedan superadas.
>
> ACTUALIZACIÓN 04-11-2026 (H-31): la app de hoy muestra los 5 mundos, con los 4 bloqueados atenuados y con candado. ~~PENDIENTE DE DECISIÓN (pregunta 23, nueva)~~ (decidida el 06-11-2026, ver arriba).

### 15. Detalle de mundo
Funcion:
- mostrar progreso del mundo actual

Muestra:
- nombre del mundo
- barra o texto de progreso
- mapas en orden fijo
- miniatura por mapa
- nombre del mapa
- estado del mapa

Estados visuales por mapa:
- no iniciado
- en progreso
- completado
- completado, practica bloqueada
- practica disponible
- mapa sin resolver

### 16. Pantalla previa del mapa
Funcion:
- presentar el caso antes de jugar

Muestra:
- nombre del mapa
- mundo
- dificultad
- tipo de intento
- etiqueta si el caso incluye arma homicida
- aviso de intento oficial
- boton comenzar

Casos especiales:
- mapa sin resolver
- practica disponible

### 17. Advertencia por partida pendiente
Funcion:
- gestionar conflicto cuando ya existe otra partida oficial pendiente

Muestra:
- mensaje explicando que perdera el progreso guardado
- boton volver a partida pendiente
- boton iniciar nueva y perder anterior

### 18. Pantalla intermedia de mapa pendiente
Funcion:
- decidir que hacer al volver a un mapa en progreso

Muestra:
- continuar intento oficial
- jugar en practica deshabilitado
- volver

### 19. Pantalla de partida principal
Funcion:
- resolver el caso

Estructura:
- mapa grafico
- pistas visibles
- panel fijo de sospechosos
- acceso a notas
- papelera siempre visible
- boton ayudas
- boton resolver
- boton limpiar tablero
- boton deshacer
- boton rehacer

Header de partida:
- tiempo
- ayudas usadas
- intentos fallidos de resolver
- puntos actuales estimados

> **DECIDIDO 11-11-2026** (pregunta 12, ADR-0014, "Decisiones de Alejandro (11-11-2026)"): la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan en la **etapa 5B**, con el ranking del servidor.
>
> ACTUALIZACIÓN 04-11-2026: el header de hoy muestra solo **tiempo y errores**. Ayudas y puntos estimados no existen (**(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN**, auditoría 04-11-2026, pregunta 12, H-30). Las pistas son tarjetas compactas con scroll horizontal bajo el tablero, y el texto de cada una puede cortarse (H-56). Reglas de colocación: ver la nota de las pantallas 20 y 21.
>
> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-55, H-32): salir de la partida y reloj. Hoy, al salir (botón Atrás, una llamada) se pierde todo el progreso y no hay aviso; el reloj es un temporizador de 1 segundo que se detiene si Android suspende la app.

### 20. Modo notas separadas

> **SUPERADO 04-11-2026 (H-25):** las pantallas 20 y 21 no son dos pantallas ni dos cuadrículas. En la app es un selector **Mapa / Notas** sobre un único tablero y un único estado de marcas. "Mapa" muestra muebles, nombres de habitación y colores intensos; "Notas" oculta muebles y nombres y atenúa los colores. Texto original abajo.
>
> Reglas de colocación (H-25): **la fuente única de las reglas de colocación es `docs/16-spec-puzzle.md`, sección 4.** Resumen de lo que hace la app hoy, comprobado en `app/lib/src/game/board_state.dart`, `game_controller.dart` y `app/lib/src/ui/`:
>
> - **Herramienta y gesto.** Primero se elige una herramienta (un sospechoso, la X o el borrador) y luego se actúa sobre una casilla. **Tocar** la casilla anota un *candidato* (la letra del personaje). **Mantener oprimido** o **arrastrar** la ficha *confirma* al personaje en esa casilla. No existe el modelo de "toque 1 = candidato, toque 2 = confirmado".
> - **Convivencia.** Varios candidatos pueden convivir en una casilla. La X y los candidatos **no** conviven: una casilla con X rechaza candidatos (con mensaje) y poner una X a mano limpia los candidatos de esa casilla. Una casilla con un confirmado rechaza candidatos y X.
> - **Un confirmado por personaje.** Confirmar a alguien que ya está fijado en otra casilla se rechaza con mensaje. Al confirmar, sus candidatos desaparecen de todo el tablero. Confirmar sobre otro confirmado pide confirmación ("¿Reemplazar confirmado?").
> - **Auto-X.** Interruptor "Auto-X", encendido por defecto. Al confirmar a un personaje se tachan su fila y su columna, pero solo en casillas vacías: nunca pisa candidatos ni confirmados, y esas X se retiran si se borra el confirmado que las originó.
> - **Borrador.** Herramienta aparte: con el borrador elegido, tocar una casilla la deja vacía (candidatos, X y confirmado, con sus X automáticas). Además existen la papelera (arrastrar una marca) y el mini panel (tocar una casilla con contenido sin ninguna herramienta elegida, para borrar un elemento).
> - **Mapa / Notas.** Es un selector de dos opciones sobre **un solo tablero**, no dos cuadrículas. "Mapa" dibuja los muebles y los nombres de las habitaciones con el color de cada habitación más intenso. "Notas" oculta muebles y nombres y atenúa los colores para ver mejor las marcas. Las marcas son las mismas en ambas vistas. Esto reemplaza a los "dos modos de notas" (separadas / superpuestas) de los textos anteriores.
> - **Tocar una casilla vacía sin herramienta elegida** no da ninguna respuesta. El aviso ("Elige primero a un sospechoso") y un gesto alternativo al de mantener oprimido quedaron **DECIDIDOS 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): al tocar una casilla sin sospechoso elegido aparece el aviso, y hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto (etapa 2); ver `docs/11-accesibilidad.md`. Hoy la app sigue sin dar respuesta.
> - **Deshacer / rehacer.** Historial de 50 acciones del tablero (no incluye las pistas).

Funcion (texto original):
- mostrar la cuadricula logica separada

Muestra:
- cuadricula logica
- estado sincronizado con el mapa

### 21. Modo notas superpuestas
Funcion:
- mostrar la cuadricula logica sobre el mapa

Muestra:
- mapa atenuado
- logica superpuesta
- estado sincronizado con el mapa

### 22. Mini panel de casilla

> ACTUALIZACIÓN 04-11-2026: existe en la app. Aparece al tocar una casilla con contenido **sin** ninguna herramienta elegida. Con el borrador elegido, tocar la casilla la limpia directamente.

Funcion:
- borrar elementos de una casilla con varios contenidos

Muestra:
- lista simple o rejilla pequena con elementos
- al tocar uno:
  - lo elimina
  - cierra el panel

### 23. Panel de ayudas

> **DECIDIDO 11-11-2026** (pregunta 12, ADR-0014, "Decisiones de Alejandro (11-11-2026)"): la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan en la **etapa 5B**, con el ranking del servidor.
>
> **No existe en la app de hoy.** **(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12, H-30): qué ayudas existen y cómo se puntúan.

Funcion:
- listar ayudas disponibles

Muestra:
- ayudas activas
- ayudas deshabilitadas
- confirmacion simple antes de usar

No muestra:
- penalizacion numerica exacta

### 24. Panel de vidas

> **No existe en la app de hoy** (las vidas son una cifra simulada en Inicio).
>
> **DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio. Sugerencia de diseño, no decidida: con 0 vidas el panel podría mostrar el botón de ver un anuncio y el tiempo que falta para la próxima vida (los anuncios dependen de la pregunta 18).
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 5, H-26): qué pasa al quedar con 0 vidas.
>
> **DECIDIDO 06-11-2026** (auditoría, pregunta 6, H-26): vidas de Premium ilimitadas. ~~(SUPERADO) Versión con tope de 5 y recarga instantánea de `docs/08-balance.md`.~~

Funcion:
- explicar estado de vidas

Muestra:
- vidas activas
- tiempo para proxima vida
- vidas extra
- ver anuncio
- comprar pack de vidas
- boton reglas de vida

### 25. Panel reglas de vida
Funcion:
- explicar solo reglas de vidas

Muestra:
- como se pierden
- como se recuperan
- como funcionan extras

### 26. Error de resolver

> **DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo **cuántas** casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 9, H-28): cómo se muestran los errores. Hoy se resaltan **exactamente** las casillas equivocadas, con 3 segundos de bloqueo, y un aviso de texto; el color es el único marcador de las casillas con error (H-56). Recomendación de la auditoría: mostrar solo cuántas casillas no cuadran y dejar el resaltado exacto solo en el tutorial (eso cambia la animación de error del informe gráfico). Falta que Alejandro decida.
>
> Tablero incompleto: Resolver avisa "Confirma a cada personaje exactamente una vez antes de resolver" y no cuenta como error.

Funcion:
- feedback cuando el tablero esta mal

Muestra:
- texto de error
- casillas incorrectas resaltadas (SUPERADO 04-11-2026: se muestra solo cuántas casillas no cuadran; el resaltado exacto queda solo en el tutorial)
- bloqueo temporal de edicion
- feedback rojo de penalizacion

### 27. Exito de resolver
Funcion:
- feedback cuando el tablero esta correcto

Muestra:
- mensaje de completado exitoso
- tablero bloqueado
- boton continuar

### 28. Resumen de mapa oficial
Funcion:
- cerrar partida oficial de campana

Muestra:
- nombre del caso
- mundo
- tiempo
- errores de resolver
- ayudas usadas
- puntuacion
- posicion global
- promedio historico del mapa
- mejor marca anterior
- si aplica:
  - arma homicida revelada
- compartir
- continuar

### 29. Resumen de practica
Funcion:
- cerrar partida de practica

Muestra:
- tiempo
- errores
- ayudas
- puntuacion de practica
- puntaje oficial registrado
- compartir
- continuar

### 30. Resumen del mundo
Funcion:
- cerrar un mundo cuando termina su ultimo mapa

Muestra:
- mapas completados
- tiempo total del mundo
- puntuacion total del mundo
- ayudas totales
- errores totales
- continuar

Flujo posterior:
- anuncio si no es premium
- animacion de desbloqueo del siguiente mundo

### 31. Animacion de desbloqueo de mundo
Funcion:
- celebrar y confirmar nuevo acceso

Muestra:
- nombre del mundo desbloqueado
- efecto visual
- continuar

### 32. Modulo de reto diario

> ACTUALIZACIÓN 04-11-2026: hoy es una pestaña simulada (DEMO) con racha de mentira y un botón que abre un caso elegido por la fecha del teléfono, de cualquier dificultad y repetible.
>
> **DECIDIDO 06-11-2026** (auditoría, pregunta 7, H-27): el reto diario cambia a la medianoche local de cada jugador, mismo caso para todos los de esa fecha (ver `docs/03-reglas-del-juego.md`, "Reto diario").

Funcion:
- centro de informacion del reto del dia

Muestra:
- estado del reto
- racha actual
- mejor racha historica
- puntos semanales acumulados
- protectores disponibles
- tiempo restante para el siguiente reto
- ranking del dia
- ranking semanal
- dificultad
- nombre del caso
- badge mientras no se complete

Estados:
- no iniciado
- en progreso
- completado
- invalido/fuera de tiempo

### 33. Advertencia de intento oficial del reto diario
Funcion:
- confirmar inicio del intento diario

Muestra:
- mensaje de que abrirlo registra el intento oficial del dia
- confirmar
- cancelar

### 34. Resumen del reto diario
Funcion:
- cerrar el reto diario jugado

Muestra:
- nombre del reto
- dificultad
- tiempo
- errores
- ayudas
- puntos
- posicion
- promedio del reto
- puntos ganados hoy
- acumulado semanal
- si aplica:
  - arma homicida revelada
- compartir
- continuar

### 35. Pantalla de racha y progreso diario
Funcion:
- mostrar el resultado diario ampliado

Muestra:
- racha actual
- mejor racha historica
- puntos ganados hoy
- acumulado semanal
- posicion en ranking diario
- protectores disponibles
- fechas de los ultimos 3 protectores usados
- acceso a ranking diario
- acceso a ranking semanal

Si aplica:
- racha protegida
- racha perdida
- motivo del fallo

### 36. Ranking principal
Funcion:
- elegir tipo de ranking

Pestanas:
- Mapas
- Reto diario
- Semanal

### 37. Ranking de mapas - selector
Funcion:
- elegir mundo y mapa

Muestra:
- selector de mundo
- selector de mapa

### 38. Vista de ranking
Funcion:
- mostrar ranking concreto

Muestra:
- podio visual top 3
- tabla puestos 4 al 10
- bloque del usuario con 3 anteriores y 3 siguientes

Comportamientos:
- si el usuario esta en top 10, no muestra bloque extra
- tocar avatar o nickname abre perfil publico
- tocar puntos abre detalle del resultado

### 39. Perfil publico
Funcion:
- mostrar perfil publico de otro jugador

Muestra:
- avatar
- nickname
- bandera/pais
- racha actual
- mejor racha historica
- retos iniciados
- retos completados
- retos fallados
- porcentaje de exito
- retos disponibles desde el registro
- mundos completados
- mapas completados

### 40. Detalle de resultado
Funcion:
- mostrar detalle de un resultado oficial concreto

Muestra:
- mapa o reto jugado
- tiempo
- puntos
- errores
- ayudas usadas
- fecha
- posicion obtenida

### 41. Perfil propio
Funcion:
- mostrar y editar datos del jugador

Muestra:
- avatar
- nickname
- bandera/pais
- estadisticas

Acciones:
- cambiar avatar
- cambiar nickname
- cambiar bandera/pais

### 42. Cambio de nickname
Funcion:
- editar nickname con validacion

Muestra:
- nickname actual
- campo nuevo
- validacion de disponibilidad
- sugerencias si ya existe

Restriccion:
- solo cada 15 dias

### 43. Tienda

> ACTUALIZACIÓN 04-11-2026: hoy es una hoja modal DEMO que se abre desde Perfil o desde la tarjeta de Inicio; los botones de compra solo muestran "Función simulada".

Funcion:
- monetizacion basica

Muestra:
- premium
- packs de vidas
- protectores de racha

No muestra aun:
- eventos
- cosmeticos futuros

### 44. Premium

> ACTUALIZACIÓN 04-11-2026: hoy es una hoja modal DEMO desde Perfil.
>
> **DECIDIDO 06-11-2026** (auditoría, pregunta 6, H-26): vidas de Premium ilimitadas. ~~(SUPERADO) Tope de 5 con recarga instantánea.~~

Funcion:
- vender planes premium

Muestra:
- comparacion gratis vs premium mensual vs premium anual
- beneficios
- ahorro visible en anual

### 45. Configuracion

> ACTUALIZACIÓN 04-11-2026: hoy es una hoja modal desde Perfil con cuatro interruptores (sonido, música, vibración, notificaciones) que se guardan pero **no hacen nada** (la app no tiene audio, vibración ni notificaciones) y un idioma fijo en español.

Funcion:
- administrar preferencias del jugador

Muestra:
- sonido
- musica
- vibracion/haptics
- idioma
- notificaciones
- restaurar compras
- cerrar sesion
- eliminar cuenta
- soporte

### 46. Como jugar

> ACTUALIZACIÓN 04-11-2026: hoy es un **diálogo paginado de 5 hojas** (el mismo de la primera apertura), no una página única con índice. Se abre desde Perfil y desde un ícono de la lista de casos.

Funcion:
- explicar el juego sin necesidad de jugar una partida real

Muestra:
- indice arriba
- pagina unica con scroll

Secciones:
- Que es Enigmatrix
- Reglas basicas
- Pistas
- Notas
- Simbolos del tablero
- Tutorial

Contenido:
- texto
- apoyos visuales
- mockups simplificados
- boton para jugar el tutorial

### 47. Soporte
Funcion:
- dar ayuda basica y acceso legal

Muestra:
- correo o contacto de soporte
- FAQ
- politica de privacidad
- terminos

### 48. Confirmacion de cerrar sesion
Funcion:
- advertir perdida de partida pendiente

Muestra:
- mensaje fuerte si existe partida oficial pendiente
- confirmar cerrar sesion
- cancelar

### 49. Confirmacion de eliminar cuenta
Funcion:
- advertir perdida total de datos

Muestra:
- progreso que se perdera
- rankings
- racha
- compras
- perfil
- confirmacion fuerte

### 50. Pantalla sin conexion
Funcion:
- informar bloqueo cuando falta internet

Casos:
- ranking offline
- tienda offline
- partida oficial bloqueada por falta de conexion

Muestra:
- mensaje de sin conexion
- reintento automatico o estado de espera

## Pantallas derivadas o futuras
Estas no entran todavia como modulos completos visibles, pero pueden existir despues:

- Eventos
- Historial de partidas
- Logros
- Amigos
- Rankings por pais
- Temporadas

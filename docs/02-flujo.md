# Enigmatrix - Flujo de la app

> ACTUALIZACIÓN 04-11-2026: este documento describe el flujo **objetivo** de la app completa. El prototipo de la Fase 1 cubre solo una parte; debajo de cada sección se anotan las diferencias. Se conserva el texto original salvo donde se marca **SUPERADO**. Auditoría: `production/revisiones/2026-11-04-auditoria-proyecto.md` (H-25, H-28 a H-32).
>
> **Aviso del prototipo (Fase 1).** En el juego de hoy las pantallas de vidas, racha, reto diario, ranking, tienda, premium y las estadísticas del perfil usan **datos simulados** (constantes escritas en `app/lib/src/ui/home_shell.dart`, aprobadas el 12-07-2026). No hay servidor ni cuentas. Lo que este documento dice sobre esas pantallas es la intención de la Fase 2 en adelante, no lo que la app hace hoy.
>
> **Qué existe hoy.** No hay registro, login, cuenta, verificación de correo ni intento oficial. El recorrido real es: pantalla de carga (`/`), luego `/home` (las 5 pestañas), luego la lista de casos (`/casos`) y la partida (`/play/:id`, con `?tutorial=1` para el tutorial jugable). Las secciones de acceso, rankings oficiales, perfil público y conectividad son **visión de la Fase 2 en adelante**.

## Flujo general
El recorrido principal del usuario en Enigmatrix es:

1. Registro o login
2. Configuracion inicial de cuenta
3. Pantallas de bienvenida
4. Tutorial obligatorio
5. Acceso a Inicio
6. Campana o reto diario
7. Resumen de partida
8. Ranking, progreso, racha o siguiente desbloqueo

## Flujo de acceso

### Registro y login
- Google
- Email y contrasena

### Flujo con Google
1. Login con Google
2. Se carga avatar de Google por defecto
3. Se pide nickname unico
4. Se pide bandera/pais
5. Puede cambiar avatar si quiere
6. Pasa a bienvenida

### Flujo con email
1. Registro con email y contrasena
2. Aceptacion de terminos y politica
3. Se pide nickname unico
4. Se pide avatar predeterminado
5. Se pide bandera/pais
6. Pasa a bienvenida

### Restricciones de email no verificado
- Puede jugar tutorial, campana y practica
- No puede entrar a reto diario
- No puede ver rankings
- Ve avisos para verificar correo

## Flujo inicial

> ACTUALIZACIÓN 04-11-2026: en la app de hoy no hay pantallas de bienvenida separadas ni configuración de perfil. Tras la pantalla de carga se entra a Inicio, y **la primera vez que se abre la app aparece un diálogo de 5 páginas** ("Bienvenido, detective", el tablero, las pistas, tus marcas, resolver el caso) con botón "Omitir".

### Bienvenida
Antes del tutorial se muestran 2 o 3 pantallas que explican:

- que es Enigmatrix
- que existe el reto diario
- que existen rankings y racha

No se pueden saltar por completo la primera vez.

### Tutorial obligatorio

> **DECIDIDO 04-11-2026** (auditoría, pregunta 11; ver ADR-0012): el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
>
> Recorrido nuevo del tutorial (reemplaza la lista de abajo): caso propio pequeño; enseña las reglas base, el tablero único con selector Mapa / Notas, las marcas (candidato, confirmado, X, notas), la papelera y un Resolver fallido; botón **Saltar** siempre visible; no quita vidas y no cuenta como Caso 1. Las ayudas (pregunta 12) y la elección de modo preferido ya no forman parte de este tutorial mientras no estén decididas.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 11, H-29): este flujo pide un tutorial obligatorio con el recorrido de abajo (ambos modos de notas, error de Resolver, ayuda, modo preferido, desbloqueo del Mundo 1). Lo que hay hoy es otra cosa: dos tutoriales que se pueden omitir (el diálogo de 5 páginas y un tutorial jugable de 7 pasos que usa el Caso 1 y por eso lo consume). El tutorial jugable no enseña la X manual, el borrador, Mapa/Notas ni un Resolver fallido, y no hay ayudas que mostrar. Recomendación de la auditoría (solo recomendación): un caso propio de 4×4 o 5×5 que no cuente como Caso 1, obligatorio la primera vez con botón Saltar visible. Falta que Alejandro decida; hasta entonces la lista de abajo es el objetivo original.

**Lista original (SUPERADO 04-11-2026, conservada como historial):**

1. Caso guiado muy facil
2. Explica reglas base
3. Explica los dos modos de notas
4. Obliga a probar ambos modos
5. Muestra error de resolver
6. Muestra uso de ayuda
7. Muestra resumen
8. Permite escoger modo preferido por defecto
9. Al completar:
   - resumen
   - continuar
   - anuncio si no es premium
   - desbloqueo de Mundo 1
   - entrada a Inicio

## Inicio

### Prioridad de tarjetas
De arriba hacia abajo:

1. Verifica tu correo
2. Reto diario
3. Continuar partida pendiente
4. Mundo actual

El jugador puede ver varias tarjetas al mismo tiempo.

### Inicio muestra
- tarjeta de verificacion si aplica
- tarjeta de reto diario
- tarjeta de partida pendiente si existe
- tarjeta del mundo actual
- acceso a menus principales

> ACTUALIZACIÓN 04-11-2026 (H-31): el Inicio real muestra, de arriba abajo: saludo según la hora, vidas simuladas (4/5, con "+1 en 23:41", datos de mentira), tarjeta de **Reto diario** (racha simulada, botón "Jugar el reto"), tarjeta del **Mundo 1 · La Mansión** (casos cerrados reales, leídos de la memoria del teléfono, con botón "Continuar investigando") y tarjeta de **Tienda** (DEMO). No existe la tarjeta de verificar correo ni la de partida pendiente.

## Navegacion principal

> ACTUALIZACIÓN 04-11-2026 (H-31): **la navegación de abajo quedó SUPERADA** y se conserva como historial. Lo que hace la app hoy (`app/lib/src/ui/home_shell.dart` y las rutas de `app/lib/main.dart`):
>
> - **Barra inferior de 5 pestañas, solo íconos, sin texto:** Inicio, Mundos, Reto, Ranking y Perfil. La pestaña activa se enmarca. Es una decisión consciente del 12-07-2026 (referencia: la barra de Duolingo, versión papel).
> - **Mundos:** muestra los 5 mundos. Solo La Mansión está desbloqueada (botón "Entrar", que abre la lista de casos en `/casos`); los otros cuatro se ven bloqueados con un candado. Esto contradice el "solo mundos desbloqueados visibles" de `docs/06-pantallas-ui.md`. **DECIDIDO 06-11-2026 (pregunta 23):** los mundos bloqueados se muestran con candado; lo que hace la app de hoy es lo correcto y el "solo mundos desbloqueados visibles" del doc 06 queda SUPERADO. ~~Antes: PENDIENTE DE DECISIÓN.~~
> - **Perfil** contiene el nombre editable, estadísticas (casi todas simuladas) y la entrada a **Tienda**, **Premium**, **Cómo jugar** y **Configuración**. Tienda, Premium y Configuración son hojas que suben desde abajo, no pantallas; "Cómo jugar" abre el diálogo de 5 páginas. No hay menú lateral.
> - **No hay barra superior persistente.** Las vidas simuladas se ven solo en Inicio. El nombre se ve en Perfil; la bandera es un dato fijo simulado.
> - **Flujo de pantallas completas:** carga (`/`) → `/home` → `/casos` (lista de casos del mundo) → `/play/:id` (partida). El botón Atrás de la partida y el botón "Continuar" de la victoria llevan a `/`, es decir, pasan otra vez por la pantalla de carga (unos 1,7 s) antes de volver a Inicio.
> - **Accesibilidad de la barra:** los íconos no tienen etiqueta accesible ni tooltip (el código no usa `Semantics` en ninguna parte de la app). Ver `docs/11-accesibilidad.md`.

**Texto original (superado):**

### Menu inferior
- Inicio
- Mundos
- Reto diario
- Ranking

### Menu secundario
- Perfil
- Tienda
- Premium
- Configuracion
- Como jugar

### Menu superior persistente
- vidas actuales
- tiempo para la proxima vida
- nickname
- avatar
- bandera/pais

## Flujo de mundos

### Detalle de mundo
Muestra:

- nombre del mundo
- indicador de progreso
- lista de mapas en orden fijo
- miniatura por mapa
- nombre de mapa
- estado del mapa

### Estados posibles del mapa
- No iniciado
- En progreso
- Completado
- Completado, practica bloqueada
- Practica disponible
- Mapa sin resolver

### Entrada a un mapa no iniciado
1. Pantalla previa del mapa
2. Muestra:
   - nombre
   - mundo
   - dificultad
   - tipo de intento
   - etiqueta si el caso incluye arma homicida
   - aviso de intento oficial
3. Boton comenzar

### Mapa oficial
1. Se abre el tablero
2. Se fija la orientacion aleatoria del mapa para ese jugador
3. El tiempo empieza a correr
4. El jugador resuelve
5. Si abandona:
   - el intento oficial queda iniciado
   - puede volver a continuarlo
6. Si sale del mapa:
   - se le muestra aviso de que su intento oficial ya fue registrado

> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-55, H-32): salir de la partida y reloj. Hoy, al salir (botón Atrás o una llamada) **se pierde todo el progreso del tablero** y no hay aviso; no existen intento oficial ni partida pendiente. Recomendación de la auditoría (solo recomendación): guardar siempre el progreso; para el reloj, opción A (pausarlo al salir y ocultar el tablero) u opción B (que siga corriendo). Falta que Alejandro decida.

7. Si vuelve a un mapa pendiente:
   - aparece pantalla intermedia:
     - Continuar intento oficial
     - Jugar en practica (deshabilitado mientras exista intento oficial pendiente)
     - Volver
   - Practica queda bloqueada si el intento oficial no ha terminado

### Si ya hay una partida oficial pendiente
Si intenta abrir otro mapa oficial o reto diario:

1. aparece advertencia
2. puede escoger:
   - continuar partida pendiente
   - iniciar la nueva
3. si inicia la nueva:
   - pierde el progreso de la anterior
   - la anterior queda sin validez oficial

### Mapa sin resolver
Sucede cuando se pierde el intento oficial por:

- borrar cache
- cerrar sesion con partida pendiente
- perder datos locales
- abandonar la pendiente para abrir otra

Ese mapa:

- ya no cuenta para ranking ni estadisticas oficiales
- pero debe completarse para avanzar

## Flujo dentro de partida

### Vista principal
Durante una partida se muestran:

- mapa
- pistas visibles
- panel fijo de sospechosos
- acceso a notas
- tiempo
- ayudas usadas
- intentos fallidos de resolver
- puntos actuales estimados
- papelera siempre visible
- boton de ayudas
- boton resolver
- boton limpiar tablero
- deshacer
- rehacer

> **DECIDIDO 11-11-2026** (pregunta 12, ADR-0014, "Decisiones de Alejandro (11-11-2026)"): la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan en la **etapa 5B**, con el ranking del servidor.
>
> ACTUALIZACIÓN 04-11-2026: la partida de hoy muestra tiempo y errores. **No hay ayudas ni puntos estimados.** **(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12, H-30): cómo se calculan ayudas y puntuación; la spec 16 no lo define.
>
> Los botones X, Borrador, Deshacer y Rehacer van después del tablero, las pistas y la papelera y, según el diseño, podrían quedar fuera de la pantalla en un teléfono (estimado, sin medir; H-67).

### Interaccion con sospechosos

> **SUPERADO 04-11-2026 (H-25):** el modelo de "tap 1 = candidato con ?, tap 2 = confirmado con flecha verde" y las "Reglas de colocacion" de más abajo ya no rigen. Los textos originales se conservan debajo como historial. Lo vigente es lo siguiente y `docs/16-spec-puzzle.md`, sección 4.

> ACTUALIZACIÓN 04-11-2026 (H-25): **la fuente única de las reglas de colocación es `docs/16-spec-puzzle.md`, sección 4.** Resumen de lo que hace la app hoy, comprobado en `app/lib/src/game/board_state.dart`, `game_controller.dart` y `app/lib/src/ui/`:
>
> - **Herramienta y gesto.** Primero se elige una herramienta (un sospechoso, la X o el borrador) y luego se actúa sobre una casilla. **Tocar** la casilla anota un *candidato* (la letra del personaje). **Mantener oprimido** o **arrastrar** la ficha *confirma* al personaje en esa casilla. No existe el modelo de "toque 1 = candidato, toque 2 = confirmado".
> - **Convivencia.** Varios candidatos pueden convivir en una casilla. La X y los candidatos **no** conviven: una casilla con X rechaza candidatos (con mensaje) y poner una X a mano limpia los candidatos de esa casilla. Una casilla con un confirmado rechaza candidatos y X.
> - **Un confirmado por personaje.** Confirmar a alguien que ya está fijado en otra casilla se rechaza con mensaje. Al confirmar, sus candidatos desaparecen de todo el tablero. Confirmar sobre otro confirmado pide confirmación ("¿Reemplazar confirmado?").
> - **Auto-X.** Interruptor "Auto-X", encendido por defecto. Al confirmar a un personaje se tachan su fila y su columna, pero solo en casillas vacías: nunca pisa candidatos ni confirmados, y esas X se retiran si se borra el confirmado que las originó.
> - **Borrador.** Herramienta aparte: con el borrador elegido, tocar una casilla la deja vacía (candidatos, X y confirmado, con sus X automáticas). Además existen la papelera (arrastrar una marca) y el mini panel (tocar una casilla con contenido sin ninguna herramienta elegida, para borrar un elemento).
> - **Mapa / Notas.** Es un selector de dos opciones sobre **un solo tablero**, no dos cuadrículas. "Mapa" dibuja los muebles y los nombres de las habitaciones con el color de cada habitación más intenso. "Notas" oculta muebles y nombres y atenúa los colores para ver mejor las marcas. Las marcas son las mismas en ambas vistas. Esto reemplaza a los "dos modos de notas" (separadas / superpuestas) de los textos anteriores.
> - **Tocar una casilla vacía sin herramienta elegida** no da ninguna respuesta. El aviso ("Elige primero a un sospechoso") y un gesto alternativo al de mantener oprimido quedaron **DECIDIDOS 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): al tocar una casilla sin sospechoso elegido aparece el aviso, y hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. El diseño exacto se hace en la prueba de concepto (etapa 2); ver `docs/11-accesibilidad.md`. Hasta que se implemente, la app de hoy sigue sin dar respuesta.
> - **Deshacer / rehacer.** Historial de 50 acciones del tablero (no incluye las pistas).

**Texto original (superado):**
- tap 1 en avatar: candidato `avatar pequeno + ?`
- tap 2: confirmado `avatar grande + flecha verde`
- se arrastra al tablero

### Interaccion con X
- tap 1: X pequena
- tap 2: X grande
- se arrastra al tablero

### Reglas de colocacion (SUPERADO, ver la nota de "Interaccion con sospechosos")
- si el mismo elemento ya existe, no hace nada
- si es la misma entidad con otro estado, reemplaza
- si es entidad distinta, coexiste
- si se pone confirmado en una casilla:
  - borra automaticamente todo lo demas de esa casilla
- si una casilla ya tiene confirmado:
  - no permite poner candidatos ni X
  - muestra mensaje
- si se pone otro confirmado encima:
  - pide confirmacion
  - reemplaza al anterior

### Borrado
- mini panel al tocar casillas con varios elementos
- mini panel sirve solo para borrar
- papelera siempre visible para cualquier elemento arrastrable

### Limpiar tablero
- pide confirmacion
- borra estado manual del tablero
- borra marcas de pistas
- borra historial visual de tablero
- mantiene tiempo
- mantiene errores
- mantiene ayudas ya contadas
- mantiene penalizacion ya aplicada

### Resolver
Si el tablero esta mal:

- valida de una vez, sin confirmacion
- mensaje de error
- resalta casillas incorrectas (SUPERADO 04-11-2026: ahora se muestra solo cuántas no cuadran; el resaltado exacto queda solo para el tutorial)
- bloquea edicion por unos segundos
- pierde puntos
- pierde vida si aplica
- luego permite seguir

> **DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo **cuántas** casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 9, H-28): cómo se muestran los errores al resolver. Hoy se marcan **exactamente** las casillas equivocadas y el tablero se bloquea 3 segundos (lo que dice esta sección). Recomendación de la auditoría: mostrar solo cuántas casillas no cuadran y dejar el resaltado exacto solo en el tutorial. Falta que Alejandro decida.
>
> **DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 5, H-26): qué pasa al quedar con 0 vidas. Esta sección no lo define.
>
> Hoy no se pierden puntos ni vidas al fallar (no existen). Si el tablero está incompleto (falta confirmar algún personaje), Resolver no valida: avisa "Confirma a cada personaje exactamente una vez antes de resolver" y **no cuenta como error**.

Si el tablero esta bien:

- mensaje de completado en la misma pantalla
- bloquea tablero
- habilita boton `Continuar`

> ACTUALIZACIÓN 04-11-2026: al acertar, la app abre una pantalla de victoria con el asesino revelado, tiempo y errores. "Continuar" vuelve a Inicio y "Seguir mirando el tablero" deja el tablero a la vista. No hay anuncio.

## Flujo de salida de partida correcta

### Mapa normal
1. Resolver correcto
2. Boton `Continuar`
3. Anuncio si no es premium
4. Resumen del mapa
5. Continuar
6. Si es ultimo mapa del mundo:
   - resumen del mundo
   - continuar
   - anuncio si no premium
   - animacion de desbloqueo
   - siguiente mundo desbloqueado

### Entrada a reto diario
1. Estado previo en el modulo de reto diario
2. Si el estado es `No iniciado`:
   - se muestra advertencia de intento oficial
   - al confirmar, se registra el intento oficial del dia
3. Se abre el tablero
4. Se juega normalmente

### Salida de reto diario correcto
1. Resolver correcto
2. Boton `Continuar`
3. Anuncio si no es premium
4. Resumen del reto diario
5. Pantalla de racha y progreso diario

### Tutorial
1. Resolver correcto
2. Resumen del tutorial
3. Continuar
4. Anuncio si no es premium
5. Desbloqueo de Mundo 1 la primera vez
6. Entrada a Inicio

## Resumenes

### Resumen normal

> **DECIDIDO 11-11-2026** (pregunta 12, ADR-0014, "Decisiones de Alejandro (11-11-2026)"): la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan en la **etapa 5B**, con el ranking del servidor.
>
> ACTUALIZACIÓN 04-11-2026: la pantalla de victoria de hoy solo muestra tiempo y errores (más el asesino revelado). Puntuación, posición, promedio y mejor marca no existen. Puntos y ayudas: **(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12, H-30). Posición y promedio dependen del servidor (etapa 5).

Muestra:

- estado de la partida
- nombre del caso
- mundo
- tiempo final
- intentos fallidos de resolver
- ayudas usadas
- puntuacion
- posicion global del mapa
- promedio historico global del mapa
- mejor marca anterior
- si el caso tenia arma:
  - arma homicida revelada
- opcion de compartir

### Resumen de practica
Muestra:

- datos de esa partida de practica
- puntaje oficial ya registrado
- comparte resultado de practica no oficial solo como visual, pero sin tocar ranking

### Resumen diario
Muestra:

- nombre del reto
- dificultad
- tiempo
- intentos fallidos
- ayudas
- puntos
- posicion del reto diario
- promedio del reto
- puntos ganados hoy
- acumulado semanal
- si el caso tenia arma:
  - arma homicida revelada
- opcion de compartir

### Pantalla de racha y progreso diario
Muestra:

- racha actual
- mejor racha historica
- puntos ganados hoy
- acumulado semanal
- posicion en ranking del reto diario
- protectores disponibles
- fecha de los ultimos 3 protectores usados
- acceso a ranking diario
- acceso a ranking semanal
- si aplica:
  - racha protegida
  - racha perdida
  - motivo del fallo

### Resumen del mundo
Muestra:

- mapas completados
- tiempo total del mundo
- puntuacion total del mundo
- ayudas totales
- errores totales

No muestra competencia global del mundo.

## Reto diario

> **DECIDIDO 06-11-2026** (auditoría, pregunta 7, H-27): el reto diario cambia a la medianoche local de cada jugador, mismo caso para todos los de esa fecha (ver `docs/03-reglas-del-juego.md`, sección "Reto diario"). ~~(SUPERADO) Antes: "día local" del doc 03 contra hora del servidor del doc 08.~~
>
> Hoy el Reto es una simulación DEMO: la pestaña "Reto" muestra una racha de mentira y un botón "Comenzar intento oficial" que abre un caso elegido por la fecha del teléfono (cualquier dificultad, repetible). No hay advertencia de intento oficial, ranking ni cierre a medianoche reales.

### Modulo de reto diario
Antes de empezar o continuar muestra:

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

### Estados del reto diario
- No iniciado
- En progreso
- Completado
- Invalido/fuera de tiempo

### Badge de reto diario
- se muestra mientras el reto del dia siga pendiente y jugable
- si el reto se abre pero no termina, sigue visible
- desaparece al completarlo
- desaparece si el reto ya no puede abrirse el resto del dia

## Ranking

### Estructura
- pestana Mapas
- pestana Reto diario
- pestana Semanal

### Ranking de mapas
1. elegir mundo
2. elegir mapa
3. ver ranking especifico

### Ranking diario
- abre primero el ranking del dia
- permite revisar dias anteriores

### Ranking semanal
- abre primero la semana actual
- permite revisar semanas anteriores

### Layout de ranking
- podio visual con top 3
- tabla del 4 al 10
- bloque del usuario con 3 anteriores y 3 siguientes
- si el usuario esta en top 10, se oculta el bloque extra

### Acciones dentro del ranking
- tap en avatar o nickname: perfil publico
- tap en puntos: detalle del resultado

## Perfil

### Perfil publico
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

### Perfil propio
Puede editar:

- avatar
- nickname
- bandera/pais

## Tienda
- premium
- packs de vidas
- protectores de racha

## Premium
- comparacion entre Gratis, Premium mensual y Premium anual
- anual muestra ahorro visible

## Configuracion

> ACTUALIZACIÓN 04-11-2026: la hoja de Configuración de hoy tiene cuatro interruptores (sonido, música, vibración, notificaciones) que **se guardan pero no hacen nada**: la app no tiene audio, vibración ni notificaciones. El idioma muestra "Español" sin selector. Restaurar compras, cerrar sesión y eliminar cuenta aparecen solo como texto ("se activan con el modo online").

- sonido
- musica
- vibracion/haptics
- idioma
- notificaciones
- restaurar compras
- cerrar sesion
- eliminar cuenta
- soporte

## Como jugar

> ACTUALIZACIÓN 04-11-2026: hoy "Cómo jugar" (en Perfil, y un ícono en la lista de casos) abre el **diálogo paginado de 5 hojas**, no una página única con índice. Es el mismo diálogo de la primera apertura.

- pagina unica
- indice arriba
- secciones:
  - Que es Enigmatrix
  - Reglas basicas
  - Pistas
  - Notas
  - Simbolos del tablero
  - Tutorial
- usa texto + apoyos visuales
- mockups simplificados
- el tutorial se puede rejugar desde aqui

Nota:
- los casos con arma homicida no se explican a fondo al inicio
- el tutorial solo los menciona brevemente
- el jugador aprende ese sistema al llegar a esos casos

## Conectividad

> ACTUALIZACIÓN 04-11-2026: el prototipo de la Fase 1 funciona **sin conexión** (casos y progreso en el teléfono). Esta sección es la intención para cuando exista servidor (etapa 5).

- Toda la app es online
- Si se pierde internet durante una partida oficial:
  - puede seguir un tiempo limitado
  - si supera ese tiempo:
    - partida bloqueada
    - no puede ver tablero ni pistas
    - debe recuperar conexion
- Al volver la conexion:
  - reintento automatico

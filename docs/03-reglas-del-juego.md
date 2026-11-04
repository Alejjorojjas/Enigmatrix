# Enigmatrix - Reglas del juego

> ACTUALIZACIÓN 04-11-2026: este documento mezcla reglas **vigentes** con reglas de la visión completa y con reglas que el juego ya no usa. Se conserva todo el texto; lo superado se marca **SUPERADO** y los temas que decide Alejandro llevan **PENDIENTE DE DECISIÓN**. Auditoría: `production/revisiones/2026-11-04-auditoria-proyecto.md` (H-25 a H-33).
>
> - **Vigente y comprobado en el código:** victoria solo con todo el tablero correcto, estructura del caso, reglas de colocación (ver la sección "Reglas de colocacion"), borrado, límite de 50 acciones de deshacer, pistas que se destacan o tachan.
> - **Fuente única de la colocación:** `docs/16-spec-puzzle.md`, sección 4.
> - **Visión de la Fase 2 en adelante (hoy no existe):** vidas, ayudas, puntos, intento oficial, ranking, racha, protectores, antitrampa, reto diario oficial y modo online.
>
> **Aviso del prototipo (Fase 1).** En el juego de hoy las pantallas de vidas, racha, reto diario, ranking, tienda, premium y las estadísticas del perfil usan **datos simulados** (constantes escritas en `app/lib/src/ui/home_shell.dart`, aprobadas el 12-07-2026). No hay servidor ni cuentas. Lo que este documento dice sobre esas pantallas es la intención de la Fase 2 en adelante, no lo que la app hace hoy.

## Identidad del juego
Enigmatrix es un juego de deduccion visual y logica espacial. El jugador resuelve casos colocando sospechosos y marcas sobre un mapa con habitaciones y objetos, a partir de pistas textuales.

## Regla general de victoria
El jugador solo gana cuando `todo el tablero` esta correcto.

- No basta con acertar el asesino.
- No basta con acertar la victima o una parte del mapa.
- Todo el caso debe quedar bien resuelto.

## Estructura del caso
Cada caso tiene:

- mapa grafico
- habitaciones
- objetos
- sospechosos
- pistas
- una solucion unica

De forma opcional segun dificultad, un caso tambien puede incluir:

- armas potenciales visibles
- una arma homicida correcta

## Reglas del tablero
- El tablero se resuelve sobre el mapa
- La victima no aparece al inicio
- Al final, todas las personas deben estar ubicadas correctamente

> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 8, H-35): representación de la víctima. Versión de este documento (y de los docs 13, 15 y 20): la víctima no se ve. Versión del juego de hoy, de `CLAUDE.md` y de `docs/16-spec-puzzle.md`: el jugador **ubica a todos los personajes, incluida la víctima**, y en el tablero y en el panel la víctima aparece con una ficha normal marcada con una † (`board_view.dart`, `game_screen.dart`). La auditoría recomienda confirmar la ficha con † sin cuerpo ni sangre y corregir los docs 13, 15 y 20. Falta que Alejandro lo confirme.
- El jugador puede usar notas o no

## Sistema de arma homicida

### Presencia por dificultad
- `Tutorial`: no usa arma homicida
- `Principiante`: no usa arma homicida
- `Casual`: algunos casos pueden incluir arma homicida en una version simplificada
- `Intermedio`, `Experto` y `Elite`: el arma homicida puede formar parte normal del caso

> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 19, H-52): uso del arma. Este documento dice que desde Intermedio el arma es parte normal del caso. En los casos de hoy el arma aparece solo en una parte pequeña de los casos y nunca por encima de Casual. Falta decidir si se usa más en el Mundo 1, desde Intermedio.

### Regla general
- El arma homicida agrega complejidad al caso
- El arma homicida no se acusa manualmente en V1
- El sistema la deduce automaticamente cuando el tablero esta correctamente resuelto
- El arma homicida se revela en el resumen final del caso
- No aparece en ranking

### Representacion en el mapa
- El arma se muestra como un objeto potencial pequeno dentro de una habitacion
- No ocupa el mismo papel estructural que cama, mesa o sofa
- Visualmente puede verse en un punto del mapa
- Logicamente pertenece a una `habitacion`, no a una casilla exacta

### Relacion con la solucion
En los casos con arma homicida:

- el asesino
- la victima
- y el arma homicida

pertenecen a la misma habitacion

### Multiples armas potenciales
- En dificultades bajas con arma, puede haber muy pocas armas potenciales visibles
- En dificultades altas pueden existir varias armas potenciales visibles
- Solo una es la correcta por caso

### Pistas sobre el arma
Las pistas pueden hablar de:

- la habitacion donde esta el arma
- el tipo de arma
- el arma especifica

### Categorias logicas del arma
Las categorias existen para deduccion, pero no se muestran explicitamente en la UI.

Categorias base:
- cortante
- contundente
- veneno
- asfixia o atadura

Cada arma especifica pertenece a una sola categoria.

### Reglas de dificultad del arma
- En `Casual` con arma:
  - debe haber pocas pistas de arma
  - la deduccion se centra mas en la habitacion
- En `Intermedio` en adelante:
  - pueden entrar mas pistas por tipo o categoria
  - puede haber mayor variedad de armas potenciales visibles

### Lista base oficial de armas V1
- Cuchillo de cocina
- Tijeras
- Abrecartas
- Candelabro
- Estatua pequena
- Busto decorativo
- Martillo de servicio
- Botella rota
- Cable
- Cuerda
- Frasco de veneno
- Jeringa

### Distribucion base de armas por mundo
- Mansion:
  - Abrecartas
  - Candelabro
  - Estatua pequena
  - Cuerda
  - Frasco de veneno
  - Tijeras
- Hotel:
  - Cuchillo de cocina
  - Tijeras
  - Botella rota
  - Cable
  - Frasco de veneno
  - Martillo de servicio
- Museo:
  - Abrecartas
  - Estatua pequena
  - Busto decorativo
  - Cuerda
  - Frasco de veneno
- Tren:
  - Cuchillo de cocina
  - Botella rota
  - Cable
  - Martillo de servicio
- Hospital:
  - Cuchillo de cocina
  - Tijeras
  - Cable
  - Martillo de servicio
  - Jeringa

## Regla global de partida oficial pendiente
- El jugador solo puede tener `una` partida oficial incompleta en toda la app.
- Aplica tanto para mapas normales como para reto diario.
- Si intenta iniciar otro contenido oficial teniendo una pendiente:
  - recibe advertencia
  - puede volver a la pendiente
  - o puede abandonarla para iniciar la nueva
- Si la abandona:
  - pierde el intento oficial anterior
  - el contenido anterior queda sin validez oficial

> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-55, H-32): salir de la partida y reloj. Hoy no existen intento oficial ni partida pendiente, y **al salir de una partida se pierde todo el progreso del tablero**. Falta decidir qué se guarda y qué pasa con el reloj (ver la sección "Tiempo").

## Modos de notas

> **SUPERADO 04-11-2026 (H-25):** no hay dos modos de notas con cuadrículas distintas. La app tiene un selector **Mapa / Notas** sobre un único tablero; ver el resumen en "Reglas de colocacion". El texto original se conserva abajo.

### Modo 1
- Cuadricula logica separada

### Modo 2
- Cuadricula logica superpuesta al mapa

### Regla comun
- Ambos modos comparten el mismo estado logico
- El jugador puede cambiar entre ellos en partida
- Tambien puede jugar sin usar notas

## Elementos visuales del tablero

> **SUPERADO 04-11-2026 (H-25):** en el juego de hoy el candidato se dibuja como la **letra** del personaje (no "avatar pequeño + ?") y el confirmado como un círculo con la ficha del personaje (spec 16, sección 4). Los colores base siguen siendo válidos como intención. Texto original abajo.

### Candidato
- `avatar pequeno + signo de interrogacion`

### Confirmado
- `avatar grande + flecha verde`

### Descarte parcial
- `X pequena`

### Descarte fuerte
- `X grande`

### Colores base
- error: rojo
- exito/confirmacion: verde
- informativo/destacado: azul
- X: negro oscuro o gris muy oscuro

## Reglas de colocacion

> **SUPERADO 04-11-2026 (H-25):** el modelo de "tocar una vez = candidato, tocar otra vez = confirmado" y las "Reglas de convivencia" (una entidad distinta coexiste) de las secciones de abajo ya **no rigen**. Se conservan como historial. Lo vigente:

> ACTUALIZACIÓN 04-11-2026 (H-25): **la fuente única de las reglas de colocación es `docs/16-spec-puzzle.md`, sección 4.** Resumen de lo que hace la app hoy, comprobado en `app/lib/src/game/board_state.dart`, `game_controller.dart` y `app/lib/src/ui/`:
>
> - **Herramienta y gesto.** Primero se elige una herramienta (un sospechoso, la X o el borrador) y luego se actúa sobre una casilla. **Tocar** la casilla anota un *candidato* (la letra del personaje). **Mantener oprimido** o **arrastrar** la ficha *confirma* al personaje en esa casilla. No existe el modelo de "toque 1 = candidato, toque 2 = confirmado".
> - **Convivencia.** Varios candidatos pueden convivir en una casilla. La X y los candidatos **no** conviven: una casilla con X rechaza candidatos (con mensaje) y poner una X a mano limpia los candidatos de esa casilla. Una casilla con un confirmado rechaza candidatos y X.
> - **Un confirmado por personaje.** Confirmar a alguien que ya está fijado en otra casilla se rechaza con mensaje. Al confirmar, sus candidatos desaparecen de todo el tablero. Confirmar sobre otro confirmado pide confirmación ("¿Reemplazar confirmado?").
> - **Auto-X.** Interruptor "Auto-X", encendido por defecto. Al confirmar a un personaje se tachan su fila y su columna, pero solo en casillas vacías: nunca pisa candidatos ni confirmados, y esas X se retiran si se borra el confirmado que las originó.
> - **Borrador.** Herramienta aparte: con el borrador elegido, tocar una casilla la deja vacía (candidatos, X y confirmado, con sus X automáticas). Además existen la papelera (arrastrar una marca) y el mini panel (tocar una casilla con contenido sin ninguna herramienta elegida, para borrar un elemento).
> - **Mapa / Notas.** Es un selector de dos opciones sobre **un solo tablero**, no dos cuadrículas. "Mapa" dibuja los muebles y los nombres de las habitaciones con el color de cada habitación más intenso. "Notas" oculta muebles y nombres y atenúa los colores para ver mejor las marcas. Las marcas son las mismas en ambas vistas. Esto reemplaza a los "dos modos de notas" (separadas / superpuestas) de los textos anteriores.
> - **Tocar una casilla vacía sin herramienta elegida** no da ninguna respuesta. El aviso ("Elige primero a un sospechoso") y un gesto alternativo al de mantener oprimido quedaron **DECIDIDOS 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): al tocar una casilla sin sospechoso elegido aparece el aviso, y hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto (etapa 2); ver `docs/11-accesibilidad.md`. Hasta que se implemente, la app de hoy sigue sin dar respuesta.
> - **Deshacer / rehacer.** Historial de 50 acciones del tablero (no incluye las pistas).

**Texto original (superado):**

### Desde panel fijo
- El panel fijo muestra solo avatar y nombre
- Tocar avatar una vez: candidato
- Tocar avatar otra vez: confirmado
- Se arrastra al mapa

### Para X
- Tocar una vez: X pequena
- Tocar otra vez: X grande
- Se arrastra al mapa

### Reglas de convivencia (SUPERADO: hoy X y candidatos no conviven)
- Si el mismo elemento ya existe, no hace nada
- Si llega la misma entidad en otro estado, reemplaza
- Si es una entidad distinta, coexiste

### Regla de confirmado
Si se coloca un confirmado:

- borra automaticamente todo lo anterior en esa casilla
- deja solo el confirmado

Si una casilla ya tiene un confirmado:

- no se pueden poner candidatos
- no se pueden poner X
- muestra mensaje:
  - `Esta casilla ya tiene una decision confirmada, borra primero para colocar candidato`

Si se coloca otro confirmado sobre un confirmado:

- pide confirmacion
- reemplaza al anterior

## Reglas de borrado

### Mini panel
- aparece al tocar una casilla con varios elementos
- sirve solo para borrar
- muestra los elementos de manera simple
- se cierra al borrar un elemento

### Papelera
- siempre visible en partida
- se puede arrastrar cualquier elemento para borrarlo
- admite:
  - candidatos
  - confirmados
  - X pequenas
  - X grandes
- tiene feedback visual al pasar por encima
- borrar puede recuperarse con `deshacer`

## Resolver

### Al pulsar Resolver
- No pide confirmacion
- Valida de inmediato

### Si la solucion esta mal
- muestra alerta
- resalta casillas incorrectas (SUPERADO 04-11-2026: ahora se muestra solo cuántas casillas no cuadran; ver pregunta 9 abajo)
- bloquea edicion por unos segundos
- tiempo sigue corriendo (mientras se está en la partida; al salir, el reloj se pausa por la regla 10, ver ADR-0012)
- pierde puntos
- en partidas con vidas, pierde una vida
- luego se desbloquea para seguir jugando

> **DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo **cuántas** casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 9, H-28): cómo se muestran los errores al resolver. Hoy se marcan **exactamente** las casillas equivocadas y el bloqueo dura 3 segundos (lo que dice esta sección). Recomendación de la auditoría: mostrar solo cuántas casillas no cuadran y dejar el resaltado exacto solo en el tutorial. Falta que Alejandro decida.
>
> Hoy no se pierden puntos ni vidas al fallar (no existen). **Tablero incompleto:** si falta confirmar algún personaje, Resolver no valida; avisa "Confirma a cada personaje exactamente una vez antes de resolver" y **no cuenta como error** (`game_controller.dart`, resultado `incompleteBoard`).

### Si la solucion esta bien
- muestra mensaje de completado exitoso
- no cambia de pantalla inmediatamente
- bloquea la edicion
- habilita boton `Continuar`

## Errores

> Ver el bloque **DECIDIDO 04-11-2026** de la pregunta 9 en la sección "Resolver": hoy el resaltado es exacto, pero la regla decidida es mostrar solo cuántas casillas no cuadran.

- Los errores solo cuentan al pulsar `Resolver`
- Confirmar o marcar mal antes de validar no penaliza
- ~~El error resalta solo las `casillas incorrectas`~~ (SUPERADO 04-11-2026, pregunta 9: el error muestra solo cuántas casillas no cuadran; el resaltado exacto queda solo para el tutorial)
- No se resaltan sospechosos en el panel fijo

## Puntos
La logica base de puntuacion es:

- base por dificultad
- bonus por velocidad
- penalizacion por intentos fallidos de resolver
- penalizacion por ayudas usadas

Numeros exactos: `pendiente`

> ACTUALIZACIÓN 04-11-2026: el doc 08 propone fórmula y números, pero siguen en revisión (se recalibran con la prueba de juego). **La app de hoy no calcula puntos.**
>
> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12, H-30): ayudas y puntuación. La spec 16 solo dice cuándo penalizan las ayudas; no define cómo se calcula cada una ni la fórmula de puntos. Recomendación de la auditoría: la prueba de juego se hace sin ayudas y en la etapa 3 `puzzle-engineer` las especifica. Falta que Alejandro decida.

## Ayudas

> **Hoy no existen ayudas en la app.** Ver el **PENDIENTE DE DECISIÓN** de la pregunta 12 en la sección "Puntos": las cinco ayudas de abajo son la intención original y no están decididas ni especificadas.

### Ayudas V1
- resaltar pista importante
- eliminar opciones imposibles en una casilla
- autodescartar para un personaje
- revelar una casilla correcta
- explicar una deduccion parcial

### Reglas de ayudas
- penalizan en `Casual` y dificultades superiores
- en `Tutorial` y `Principiante` no penalizan (decidido 2026-06-10, detalle en `08-balance.md`)
- la penalizacion exacta no se muestra antes
- hay boton visible de `Ayudas`
- se pide confirmacion simple antes de usarlas
- algunas ayudas son contextuales
- las no disponibles se ven deshabilitadas
- se pueden tocar para explicar por que no estan disponibles
- al usarlas:
  - aparece feedback temporal rojo de perdida de puntos

## Pistas
- Siempre visibles durante la partida
- El jugador puede tacharlas manualmente
- El jugador puede destacarlas manualmente
- El estado de la pista queda guardado si abandona la partida

> ACTUALIZACIÓN 04-11-2026: hoy el estado de las pistas **no se guarda** al salir (se pierde junto con el tablero). Ver pregunta 10.
- El cambio de estado funciona en ciclo:
  - normal
  - destacada
  - tachada
  - normal

## Tiempo
- El tiempo siempre esta visible
- ~~Sigue corriendo incluso si la app se minimiza~~ (SUPERADO 04-11-2026, pregunta 10: al salir o minimizar el reloj se pausa y el tablero se oculta durante la pausa)
- No hay pausa manual

> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-32, H-55): reloj al salir o minimizar. Este documento dice que el tiempo sigue corriendo aunque se minimice la app. El cronómetro de hoy es un temporizador de 1 segundo (`game_controller.dart`) que **se detiene cuando Android suspende la app**, así que no cumple esa regla. Recomendación de la auditoría (solo recomendación): opción A, pausar el reloj al salir y ocultar el tablero, mientras no haya ranking real; opción B, que siga corriendo (lo que dice este documento). Con ranking real habría que calcularlo con la hora del servidor. Falta que Alejandro decida.

## Deshacer y rehacer
- Existen ambos botones
- Solo afectan acciones del mapa
- No afectan pistas
- Limite tecnico pendiente (CERRADO 04-11-2026: 50 acciones, `docs/08-balance.md` y `_undoLimit` en el código)

## Limpiar tablero
- Existe boton `Limpiar tablero`
- Pide confirmacion
- Borra estado visual/manual de la partida
- Borra marcas del mapa
- Borra pistas marcadas
- Mantiene:
  - tiempo
  - errores
  - ayudas usadas
  - penalizaciones acumuladas

## Vidas

> ACTUALIZACIÓN 04-11-2026: hoy las vidas son un dato simulado fijo (4/5) y no se descuentan.
>
> **DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 5, H-26): qué pasa al quedar con 0 vidas. Ningún documento lo define y el cronómetro no se detiene. Recomendación de la auditoría (solo recomendación): no se puede pulsar Resolver ni empezar casos nuevos; la partida queda guardada hasta recuperar una vida o ver un anuncio. Falta que Alejandro decida.

### Regla base
- Maximo de vidas activas gratis: 5
- Recarga de 1 vida por hora
- Una sola bolsa global

### Perdida de vidas
- Solo se pierde vida al `Resolver` mal
- Aplica en:
  - mapas normales
  - reto diario
  - practica
- No aplica en:
  - tutorial

### Recuperacion
- anuncios recargan vidas activas
- anuncios nunca crean vidas extra
- si ya esta en 5/5, no pasa nada visible

### Vidas extra
- solo por compra
- primero rellenan activas
- el resto va a reserva extra
- se consumen automaticamente 1x1 para rellenar activas

## Publicidad
- entre tableros al terminar
- para recuperar vida
- para desbloquear mundo
- premium elimina anuncios

## Practica
- Un mapa puede jugarse en practica cuando:
  - ya tuvo su intento oficial
  - y se completo todo su mundo
- Practica no afecta ranking
- Practica no afecta promedio global
- Practica muestra resumen completo
- Practica muestra tambien el puntaje oficial registrado

## Mapa oficial
- Tiene un solo intento oficial puntuable
- Si se pierde ese intento oficial:
  - el mapa ya no cuenta para ranking
  - pero debe completarse para avanzar

## Mapa sin resolver
Un mapa queda `sin resolver` cuando pierde su intento oficial.

- sigue siendo necesario para progresar
- no cuenta para ranking ni estadisticas oficiales

## Reto diario

> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 7, H-27): hora en que cambia el reto diario. Este documento dice "dentro del día local"; `docs/08-balance.md` dice hora del servidor (cierre semanal domingo 23:59 UTC). Recomendación de la auditoría: medianoche de Colombia, igual para todos. Falta que Alejandro decida.
>
> Hoy el Reto es una simulación DEMO: elige el caso por la fecha del teléfono (cualquier dificultad) y se puede repetir sin límite; "un intento" y "mismo caso para todos" no se cumplen.

### Reglas
- un intento oficial
- no repetible oficialmente
- al abrirlo por primera vez en el dia:
  - aparece advertencia de intento oficial
  - al confirmar, se registra el intento oficial del dia
- si no se completa dentro del dia local:
  - puede terminarse despues
  - pero no cuenta para ranking, puntos semanales ni racha
- si se pierde la validez oficial:
  - ya no se puede volver a abrir

### Ranking del reto
- ranking separado
- muestra tiempo y puntos
- se ordena por tiempo

### Badge del reto diario
- se muestra mientras el reto del dia siga pendiente y jugable
- desaparece al completar el reto
- desaparece si el reto deja de ser jugable para el resto del dia

## Ranking semanal
- suma puntos de retos diarios validos
- si un dia no juega, no suma
- sigue participando el resto de la semana

## Racha
- Solo cuenta el reto diario
- Sube solo si lo completa correctamente
- Si falla:
  - revisa protectores disponibles
  - si hay, consume uno por cada dia perdido
  - si no hay, la racha vuelve a cero
- Se muestra mejor racha historica

## Protectores de racha
- compra directa
- eventos
- hitos de racha
- se activan automaticamente
- pueden acumularse sin limite por ahora
- en la pantalla diaria se muestran los ultimos 3 usados con fecha

### Hitos definidos
- dia 50: 1 protector
- dia 100: 1 protector
- dia 150: 2 protectores
- dia 200: 2 protectores

## Antitrampa

> ACTUALIZACIÓN 04-11-2026: **nada de esta sección está implementado hoy**: ni bloqueo de capturas, ni rotación del mapa, ni guardado de partidas incompletas. Es la intención de la Fase 2. La rotación de mapas y su efecto en tableros de 16×16 tampoco se ha estudiado (H-30).

### Captura y grabacion
- bloqueo en partidas oficiales
- no aplica a tutorial, practica o como jugar

### Rotacion de mapa
- aplica en:
  - mapas normales
  - reto diario
  - practica
- no aplica en:
  - tutorial
  - como jugar
- una de 4 orientaciones:
  - 0
  - 90
  - 180
  - 270
- el mapa rota, pero los textos e imagenes quedan orientados hacia el usuario
- cada mapa recibe una orientacion fija por jugador
- el reto diario usa orientacion aleatoria por jugador

### Partidas incompletas
- Se guardan solo en cache local
- si se borra cache o datos, se pierde el intento oficial
- si se cierra sesion con una partida pendiente, se pierde el intento oficial

> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03. Esta decisión no cubre perder el intento oficial por borrar la memoria o cerrar sesión: esa parte sigue sin resolverse y se revisa junto con la regla antes de la etapa 5 (choca con el pilar 3 de `docs/09-pillars.md`).
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-32, H-55): guardado de la partida al salir. Perder el intento oficial por borrar la memoria o cerrar sesión choca con el pilar 3 de `docs/09-pillars.md` (la sección de tensiones de ese documento no lo menciona). Falta decidir la regla antes de la Fase 2.

## Conexion

> ACTUALIZACIÓN 04-11-2026: el prototipo de la Fase 1 funciona sin conexión. Esta sección es la intención para cuando exista servidor (etapa 5).

- Todo el juego es online
- si se pierde conexion durante una partida oficial:
  - puede seguir un tiempo
  - luego se bloquea
  - no deja ver tablero ni pistas
- al volver la conexion:
  - reintento automatico

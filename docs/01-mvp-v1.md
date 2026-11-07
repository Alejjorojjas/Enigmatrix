# Enigmatrix - MVP V1

> ACTUALIZACIÓN 04-11-2026: este documento describe el **alcance del MVP completo (la visión)**, no lo que la app hace hoy. Se mantiene el texto original y se anotan debajo de cada sección los cambios y las preguntas abiertas. La auditoría que motiva estas notas está en `production/revisiones/2026-11-04-auditoria-proyecto.md` (hallazgos H-25 a H-33). El plan por etapas fue aprobado por Alejandro el 04-11-2026.
>
> **Aviso del prototipo (Fase 1).** En el juego de hoy las pantallas de vidas, racha, reto diario, ranking, tienda, premium y las estadísticas del perfil usan **datos simulados** (constantes escritas en `app/lib/src/ui/home_shell.dart`, aprobadas el 12-07-2026). No hay servidor ni cuentas. Lo que este documento dice sobre esas pantallas es la intención de la Fase 2 en adelante, no lo que la app hace hoy.
>
> **Decisiones ya tomadas por Alejandro el 04-11-2026**
> - Plan por etapas aprobado (etapas 0 a 6 de la sección 4 de la auditoría).
> - Protección del trabajo: autorizó **solo** el repositorio privado en GitHub (aún no creado). Todavía no autorizó el commit, sacar el proyecto de OneDrive ni cambiar la configuración de firma.
> - Autorizó poner los documentos al día y la prueba de concepto gráfica (etapa 2), con meta visual "pocas pantallas muy pulidas" (nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match), mostrando **ambas** opciones de estilo (papel como maqueta e ilustración 2D sin papel) y con arte provisional gratuito (CC0 o hecho por código). El arte de pago se decide después y las referencias visuales siguen pendientes: Alejandro pidió ver ejemplos.
> - Mac: el 12-07-2026 confirmó que tiene acceso a un Mac. La pregunta 22 queda reducida a si el iPhone entra al lanzamiento (ver Plataformas).
>
> **Regla de colocación en el tablero:** la fuente única es `docs/16-spec-puzzle.md`, sección 4 (ver la nota en "Juego base").

## Vision
Enigmatrix busca ser una app mobile de puzzles logicos centrada en investigaciones visuales sobre mapas con habitaciones, objetos y sospechosos, donde el jugador resuelve casos por deduccion y compite con tiempo, puntos y rankings.

## Objetivo del MVP
Lanzar una primera version jugable y competitiva de Enigmatrix enfocada en el modo principal del juego, con:

- tutorial obligatorio
- campana por mundos
- reto diario
- ranking
- racha
- vidas
- premium
- tienda basica
- sistema antitrampa inicial
- compartir resultados

## Nombre del producto
- Nombre actual: `Enigmatrix`
- El nombre anterior `Murdoku` ya no se usa como nombre del producto.

## Alcance del MVP

### Modo principal
- Solo existira `Enigmatrix` como juego principal.
- No entran en V1 otros modos como Sudoku, Queen, Caballos o Tango.

### Plataformas
- Prioridad inicial: `Android`
- Se deja preparada la definicion para llevarlo despues a `iOS`

> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 22, H-10): el 12-07-2026 Alejandro confirmó que tiene acceso a un Mac, así que ese punto está resuelto. Queda abierto **si el iPhone entra al lanzamiento**. Hoy la app nunca se ha compilado para iPhone.

### Cuenta y acceso
- Inicio de sesion con `Google`
- Inicio de sesion con `email y contrasena`
- Usuario con `nickname unico`
- `avatar`
- `bandera/pais`
- Usuarios con Google quedan verificados automaticamente.
- Usuarios con email deben verificar correo para acceder a `Reto diario` y `Rankings`.

### Onboarding
- Pantallas breves de bienvenida antes del tutorial
- Tutorial obligatorio la primera vez
- Tutorial rejugable desde `Como jugar`

> **DECIDIDO 04-11-2026** (auditoría, pregunta 11; ver ADR-0012): el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 11, H-29): este documento pide un tutorial **obligatorio**. La app de hoy tiene **dos** tutoriales y los dos se pueden omitir: un diálogo de 5 páginas (botón "Omitir") y un tutorial jugable de 7 pasos (botón "Saltar") que usa el Caso 1. Versión de la auditoría (solo recomendación): un caso propio de 4×4 o 5×5, obligatorio la primera vez con un botón Saltar visible. Falta que Alejandro decida.

### Campana
- `Mundo 0`: Tutorial
- `Mundo 1`: Mansion
- `Mundo 2`: Hotel
- `Mundo 3`: Museo
- `Mundo 4`: Tren
- `Mundo 5`: Hospital
- Los mundos tienen tema fijo.
- La distribucion de los mapas y los objetos cambia dentro de cada mundo.
- Los mapas dentro de un mundo se juegan en secuencia.
- El siguiente mapa se desbloquea al completar el anterior.
- El siguiente mundo se desbloquea al completar todo el mundo actual.

### Tipos de mapa
- Mapa oficial
- Mapa sin resolver
- Modo practica
- Tutorial
- Reto diario

### Dificultad
La dificultad del juego se organizara con estas etiquetas:

- Principiante
- Casual
- Intermedio
- Experto
- Elite

La dificultad puede subir dentro de un mismo mundo.

> ACTUALIZACIÓN 04-11-2026 (H-33): los tamaños de tablero vigentes son 6×6, 8×8, 9×9, 12×12 y 16×16 (`tools/lib/src/generator.dart`; spec 16, sección 1.1). Los casos incluidos hoy en la app son 20, de Principiante, Casual e Intermedio; **nunca se han generado casos Experto ni Élite**.
>
> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 13, H-39): si Experto (12×12) y Élite (16×16) entran al lanzamiento. Este documento los da por incluidos.
>
> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 14, H-49): con cuánto contenido se lanza. Este documento lista cinco mundos más el tutorial; la propuesta de la auditoría (solo recomendación) es el Mundo 1, La Mansión, con 10 casos más 30 días de reto diario.

### Sistema de arma homicida
- `Tutorial` e `Principiante`: no usan arma homicida
- `Casual`: algunos casos pueden incluir arma homicida en una version simplificada
- `Intermedio`, `Experto` y `Elite`: el arma homicida puede formar parte normal del caso
- El arma homicida agrega complejidad al caso
- El arma homicida se deduce automaticamente por el sistema al resolver correctamente el tablero
- El jugador no acusa el arma manualmente en V1
- El arma homicida es visible en el mapa como objeto potencial pequeno dentro de una habitacion
- Logicamente el arma pertenece a la `habitacion`, no a una casilla exacta
- En los casos con arma:
  - asesino
  - victima
  - arma homicida
  quedan en la misma habitacion
- Puede haber varias armas potenciales visibles en dificultades altas, pero solo una es la correcta
- El jugador sabe desde la pantalla previa si el caso incluye arma homicida

> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 19, H-52): este documento dice que desde Intermedio el arma es parte normal del caso. En los casos de hoy el arma aparece solo en una parte pequeña de los casos y nunca por encima de Casual. Falta decidir si se usa más en el Mundo 1, desde Intermedio.

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

### Juego base
- Mapa grafico con habitaciones y objetos
- Pistas visibles
- Panel fijo de sospechosos
- Sistema de notas opcional
- Dos modos de notas:
  - notas separadas
  - superposicion sobre el mapa
- El jugador puede jugar tambien sin usar notas

> ACTUALIZACIÓN 04-11-2026 (H-25): lo de "dos modos de notas" quedó **superado**. En la app es un selector **Mapa / Notas** sobre un único tablero (misma información, distinta vista), y las reglas de colocación (tocar = candidato, mantener oprimido o arrastrar = confirmado, X, auto-X, borrador) están en `docs/16-spec-puzzle.md`, sección 4. Resumen en `docs/03-reglas-del-juego.md`. El gesto de mantener oprimido tiene ahora una alternativa **DECIDIDA 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): modo de tocar dos veces (elegir y tocar el destino), con el aviso "Elige primero a un sospechoso"; ver `docs/11-accesibilidad.md`.

### Reglas principales del tablero
- Todo el tablero debe quedar correcto para ganar
- El boton `Resolver` valida todo el tablero
- Si hay error:
  - alerta
  - resaltado temporal de errores (SUPERADO 04-11-2026: ahora se muestra solo cuántas casillas no cuadran; ver la nota de abajo)
  - perdida de puntos
  - perdida de vida en partidas oficiales y practica

> **DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo **cuántas** casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 9, H-28): cómo se muestran los errores al resolver. Hoy la app marca **exactamente** las casillas equivocadas y bloquea el tablero 3 segundos, y este documento dice lo mismo ("resaltado temporal de errores"). La recomendación de la auditoría es mostrar solo *cuántas* casillas no cuadran, porque el resaltado exacto permite resolver por ensayo y error en tableros pequeños y debilita el pilar 1. Falta que Alejandro decida.
>
> Comportamiento actual, no recogido antes: pulsar Resolver con algún personaje sin confirmar **no cuenta como error**; solo muestra el aviso "Confirma a cada personaje exactamente una vez antes de resolver" (`game_controller.dart`). Hoy tampoco se pierden puntos ni vidas al fallar: no existen.

- Si esta correcto:
  - mensaje de completado en la misma pantalla
  - se bloquea la edicion
  - se habilita `Continuar`

### Regla global de partida pendiente
- El jugador solo puede tener `una` partida oficial incompleta en toda la app al mismo tiempo.
- Si intenta abrir otro mapa oficial o el reto diario teniendo una partida oficial pendiente:
  - aparece una advertencia
  - puede volver a la partida pendiente
  - o puede abandonar la pendiente para iniciar la nueva
- Si abandona la pendiente para iniciar otra:
  - pierde el intento oficial anterior
  - el contenido anterior queda sin validez oficial

> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-55, H-32): salir de la partida y reloj. Este documento da por hecho que la partida incompleta se guarda. **La app de hoy no guarda nada al salir** (botón Atrás, una llamada): el progreso del tablero se pierde. Tampoco existe hoy el concepto de intento oficial ni de partida pendiente. Recomendación de la auditoría (solo recomendación): guardar siempre el progreso y decidir si el reloj se pausa (opción A) o sigue corriendo (opción B, la que dice el doc 03). Además, perder el intento oficial por borrar la memoria o cerrar sesión choca con el pilar 3 (`docs/09-pillars.md`). Falta que Alejandro decida.

### Vidas
- Una sola bolsa global de vidas para todo Enigmatrix
- Maximo de vidas activas gratis: `5`
- Recarga de `1 vida cada 1 hora`
- Ver anuncio puede recargar vidas activas
- Si ya esta en `5/5`, el anuncio no agrega nada
- Las `vidas extra` solo se consiguen por compra
- Una compra primero rellena vidas activas y el sobrante va a reserva extra
- Las vidas extra se consumen automaticamente `1x1` para mantener la barra activa
- Iniciar tablero no consume vida
- Solo se pierde vida al pulsar `Resolver` y estar mal
- El tutorial no quita vidas

> **DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 5, H-26): qué pasa al quedar con 0 vidas. Este documento no lo define. Recomendación de la auditoría (solo recomendación): no se puede pulsar Resolver ni empezar casos nuevos, y la partida queda guardada hasta recuperar una vida o ver un anuncio.
>
> En la app de hoy las vidas son una cifra fija simulada (4/5) y **no se descuentan** al fallar un Resolver.

### Publicidad
- Anuncio entre tableros al terminar una partida
- Anuncio para desbloquear el siguiente mundo en usuarios no premium
- Anuncio para recuperar vidas
- Premium elimina anuncios

### Premium
- Plan `mensual`
- Plan `anual`
- Beneficios:
  - sin anuncios
  - sin limite de vidas
- No da ventajas directas de ranking

> **DECIDIDO 06-11-2026** (auditoría, pregunta 6, H-26): premium da vidas ilimitadas (versión A de este documento). ~~(SUPERADO) Versión B de `docs/08-balance.md`: tope de 5 con recarga instantánea.~~

### Reto diario
- Disponible tras completar tutorial
- Visible aunque el usuario de email no verificado lo tenga bloqueado
- Un solo intento oficial
- No repetible oficialmente
- Mismo caso para todos
- Orientacion aleatoria por jugador
- Tiene ranking diario
- Suma al ranking semanal
- Tiene racha asociada
- Al abrirlo por primera vez en el dia:
  - se advierte que se registrara el intento oficial
  - al confirmar, queda consumido el intento oficial del dia

> **DECIDIDO 06-11-2026** (auditoría, pregunta 7, H-27): el reto diario cambia a la medianoche local de cada jugador, con el mismo caso para todos los que juegan esa fecha (detalle en `docs/03-reglas-del-juego.md`, sección "Reto diario"). ~~(SUPERADO) Recomendación de la auditoría: medianoche de Colombia, igual para todos.~~ El cierre semanal (domingo 23:59 UTC, doc 08) queda sin definir.
>
> Hoy la pantalla de Reto es una simulación: elige el caso según los días transcurridos desde el 01-01-2026 con la hora del teléfono, sin mirar la dificultad, y se puede repetir sin límite. "Un solo intento" y "mismo caso para todos" **no se cumplen** en el prototipo.

### Ranking
- Ranking por mapa
- Ranking de reto diario
- Ranking semanal
- En mapas y reto diario se ordena por tiempo
- En semanal se ordena por puntos
- En todos se muestran tiempo y puntos

### Resumenes
- Resumen normal
- Resumen de reto diario
- Resumen del tutorial
- Resumen del mundo

### Compartir resultados
- Compartir resultado de mapa
- Compartir resultado de reto diario
- Compartir racha
- Formato visual con:
  - avatar
  - nickname
  - resultado
  - tiempo y puntos
  - branding del juego

### Perfil
- Perfil propio editable
- Perfil publico visible
- Avatar, nickname, bandera/pais
- Estadisticas publicas de racha, retos y progreso

### Tienda
- Premium
- Packs de vidas
- Protectores de racha
- Espacio preparado para futuro

### Antitrampa V1
- Bloqueo de capturas en partidas oficiales
- Bloqueo de grabacion en partidas oficiales si es posible
- Mapa rotado aleatoriamente por jugador
- Cada mapa conserva una orientacion fija por jugador
- Reto diario con orientacion distinta por jugador
- ~~La partida oficial sigue corriendo aunque la app se minimice~~ (SUPERADO 04-11-2026: al salir el reloj se pausa y el tablero se oculta; ver pregunta 10)
- El progreso de partida incompleta se guarda solo en cache local

> ACTUALIZACIÓN 04-11-2026: de este bloque **hoy no existe nada**: ni bloqueo de capturas, ni rotación del mapa por jugador, ni guardado de la partida incompleta. El cronómetro de la app es un temporizador de 1 segundo que se detiene cuando Android suspende la app, al revés de lo que dice la línea sobre minimizar.
>
> **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Esto reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
>
> (SUPERADO 04-11-2026) Versión anterior, conservada como historial: Antes pendiente (auditoría 04-11-2026, pregunta 10, H-32, H-55): si el reloj sigue corriendo al minimizar o salir, y si la partida incompleta se guarda siempre (ver la pregunta 10 más arriba).

## Lo que no entra al MVP
- Otros juegos logicos
- Sistema de amigos
- Rankings por pais
- Temporadas
- Moneda interna
- Eventos visibles como seccion
- Historial de partidas
- Busqueda
- Logros
- Moderacion avanzada de avatar
- Anti-cheat avanzado
- Variaciones musicales por mundo
- Mini ejemplos interactivos en `Como jugar`

## Pendientes tecnicos o de balance

> ACTUALIZACIÓN 04-11-2026 (H-33): la lista original se conserva abajo. Estado de cada punto:
> - **CERRADOS** (resueltos en `docs/08-balance.md`, sección "Limites tecnicos pendientes ya cerrados", y en el código):
>   - Fórmula de puntuación, penalizaciones por error y por ayuda, y balance por dificultad: el doc 08 trae propuestas numéricas (siguen en revisión hasta la prueba de juego; el doc 08 lo marca).
>   - Tiempo offline máximo: 60 segundos.
>   - Límite de reenvío del correo de verificación: 1 envío cada 5 minutos y máximo 5 por día.
>   - Historial de deshacer y rehacer: 50 acciones por partida (es también lo que hace el código, `_undoLimit = 50`).
> - **SIGUEN ABIERTOS:**
>   - Validación final en servidor: etapa 5 del plan. En la Fase 1 la validación es local (riesgo aceptado, `docs/18-revision-seguridad-fase1.md`).
>   - Detecciones avanzadas de fraude: Fase 2 en adelante.
>
> **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12, H-30): ayudas y puntuación. Aunque el doc 08 propone números, **la app no tiene hoy ni ayudas ni puntos** (la pantalla de victoria solo muestra tiempo y errores) y la spec 16 no define cómo se calculan. La prueba de juego se hará sin ayudas; en la etapa 3 `puzzle-engineer` las especificaría.

**Lista original:**
- Formula exacta de puntuacion
- Penalizaciones numericas por error y ayuda
- Balance exacto por dificultad
- Tiempo offline maximo permitido antes de bloqueo
- Limite de reenvio de correo de verificacion
- Reglas tecnicas del historial de deshacer/rehacer
- Validacion final en servidor
- Detecciones avanzadas de fraude

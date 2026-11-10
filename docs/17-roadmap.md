# Enigmatrix - Roadmap por fases

## Objetivo de este documento

Ordenar el MVP del doc 01 en fases construibles. El MVP completo es grande (~50 pantallas, 5 mundos, monetización, anti-trampa); intentarlo de una vez es el riesgo #1 del proyecto. Cada fase tiene criterio de salida verificable. **No se arranca una fase sin cerrar la anterior.**

> ACTUALIZACIÓN 04-11-2026: esta regla sigue vigente, con una excepción explícita aprobada el 12-07-2026 (ver "Excepción aprobada: pantallas simuladas de fases futuras"). Desde el 04-11-2026 el orden de trabajo lo marca el **plan por etapas 0 a 6** de este documento. Las fases originales del 10-06-2026 se conservan al final, en "Historial del plan original (10-06-2026)", con sus entregables marcados según lo que muestra `git log`.

## Estado verificado al 04-11-2026

Comprobado leyendo el código y `git log` el 04-11-2026 (fuente: [auditoría del proyecto](../production/revisiones/2026-11-04-auditoria-proyecto.md)).

### Dónde está el proyecto

- **Fase 0 (el corazón: especificación y motor de puzzles): cerrada.** Se cerró el 10-06-2026 y el motor se rediseñó el 11-06-2026 (estilo "Murdoku": muebles, una pista por tarjeta).
- **Fase 1 (app local jugable, sin cuentas): en curso, con gran parte de los entregables hechos** en junio y julio de 2026. La app Flutter corre como web local y como Android (APK y AAB firmado con la llave de subida), tiene tablero jugable, 20 casos, tutorial, pantalla de victoria, instrumentación de playtest y el estilo Paper Craft. Faltan los entregables marcados `[ ]` y `[~]` en el historial, y sobre todo falta el **criterio de salida**: no hay registro de que se haya medido si el juego es divertido y justo (hallazgo H-22 de la auditoría). Las rondas de feedback documentadas fueron sobre la apariencia.
- **Además, se adelantaron pantallas simuladas de fases futuras** (ver la excepción de abajo).
- **Etapa actual del plan: la etapa 0, "Orden y protección".** No toca código del juego.
- **Último commit:** `84835be`, del 12-07-2026 (39 commits en total). No hay repositorio remoto y hay cambios sin commit del 01-11-2026 (agentes, CLAUDE.md, configuración).

### Cifras verificadas

| Qué | Cifra | Dónde se comprueba |
|---|---|---|
| Tests del motor | 54 | `tools/test` (`dart test`) |
| Tests de la app | 26 | `app/test` (`flutter test`) |
| Tamaños de tablero que sabe generar el motor | 6×6, 8×8, 9×9, 12×12 y 16×16 | `tools/lib/src/generator.dart` |
| Casos incluidos en la app | 20: 8 Principiante (6×6), 7 Casual (8×8) y 5 Intermedio (9×9) | `app/assets/cases/` |
| Experto (12×12) y Élite (16×16) | El motor tiene el perfil, pero nunca se han generado casos | pregunta 13 de la auditoría |
| Almacenamiento local | `shared_preferences` (no Hive ni Isar) | `app/pubspec.yaml` |
| Tablero | Cuadrícula de widgets, un contenedor por casilla; los muebles se dibujan con `CustomPainter` | `board_view.dart`, `furniture_painters.dart` |
| Audio, vibración, traducciones y lectores de pantalla | No existen | `app/lib` |
| Servidor | No existe (`backend/` vacío) | `backend/` |

### Excepción aprobada: pantallas simuladas de fases futuras

El 12-07-2026 Alejandro aprobó (hallazgo H-18 de la auditoría) construir primero las pantallas completas de la app con datos locales simulados, dejar Firebase para después e incluir ya la monetización simulada. Es una **excepción explícita** a la regla "no se arranca una fase sin cerrar la anterior" y a "no implementar features de fases futuras sin acuerdo explícito".

- **Qué se permite:** pantallas de fases futuras solo como simulación local: Inicio, Mundos, Reto diario, Ranking, Perfil, Tienda y Premium, con vidas, racha y puntajes de ejemplo. Los datos simulados están agrupados al inicio de `home_shell.dart`.
- **Qué sigue prohibido hasta su fase:** cobros reales, validación en el servidor, ranking real, vidas o racha oficiales.
- **Condición:** lo simulado debe verse como simulado (etiqueta DEMO). Hoy tienda, premium, ranking, configuración y los puntos de la semana del Reto la llevan, pero vidas, racha y estadísticas del perfil no, y hay cuatro ajustes que parecen funcionar sin hacer nada (H-62). Se corrige en la etapa 1.
- **Caducidad:** las excepciones de la Fase 1 caducan en la etapa 5 (servidor). Si se rehace la parte gráfica, estas pantallas se reescribirán; no se invierte más en ellas hasta tener el sistema visual nuevo.
- Esta excepción también está escrita en CLAUDE.md ("Excepciones vigentes de la Fase 1").

## Decisiones de Alejandro del 04-11-2026

Decididas en chat el 04-11-2026. Detalle de las reglas: [ADR-0012](adr/0012-reglas-decididas-antes-de-la-prueba-de-juego.md). Estado diario: `production/session-state/active.md`.

- **Plan por etapas 0 a 6:** aprobado.
- **Protección:** autorizó **solo** el repositorio privado en GitHub, que todavía no está creado (lo crea él en github.com). **No** autorizó todavía el commit, sacar el proyecto de OneDrive, versionar `app/pubspec.lock` ni cambiar la configuración de firma.
- **Documentos al día:** autorizado.
- **Prueba de concepto gráfica (etapa 2):** autorizada.
  - Meta visual: "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match.
  - Estilo: la prueba muestra **ambas** opciones (papel recortado tipo maqueta e ilustración 2D sin papel) para compararlas.
  - Arte provisional gratuito (CC0, por código o con texturas de papel fotografiadas por Alejandro); el arte de pago se decide después.
  - Referencias visuales: **pendiente**; Alejandro pidió ver ejemplos.
- **Teléfono de prueba:** Alejandro tiene un Android de gama media.
- **Personas para la prueba de juego (pregunta 21):** puede conseguir de 3 a 5.
- **Mac:** el 12-07-2026 Alejandro confirmó que tiene acceso a uno. La pregunta 22 queda reducida a si el iPhone entra al lanzamiento (sigue pendiente).
- **Reglas decididas** (aceptó las recomendaciones de la sección 5 de la auditoría):
  - **5.** Con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
  - **9.** Al fallar en Resolver se muestra solo cuántas casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
  - **10.** La partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y se revisa antes de la etapa 5. Reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
  - **11.** El tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
  - **20.** Al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". Hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto.
- **Siguen pendientes:** 6, 7, 8, 12, 13, 14, 15, 16, 17, 18, 19 y 22 (solo el iPhone), más la pregunta 23 nueva (ver la tabla de pendientes).
  - ACTUALIZACIÓN 06-11-2026: de esa lista se decidieron la 6, 7, 8, 16, 17, 18 y 23 (ver la sección siguiente).

## Decisiones de Alejandro del 06-11-2026

Decididas en chat el 06-11-2026. Detalle y consecuencias: [plan de las etapas 5 y 6](../production/planes/2026-11-06-etapas-5-y-6.md), sección 1. Estado diario: `production/session-state/active.md`.

- **Cuentas de tienda:** ya tiene pagadas la cuenta de desarrollador de Google Play y la de Apple. Que existan **no** cambia el alcance: Android sigue siendo lo único decidido (ADR-0014) y si el iPhone entra al lanzamiento sigue pendiente (pregunta 22).
- **Versión web:** queda para la V2.
- **Reglas y trámites decididos** (preguntas de la sección 5 de la auditoría):
  - **6.** Premium da **vidas ilimitadas**.
  - **7.** El reto diario cambia a la **medianoche local de cada jugador**. Es el mismo caso para todos los que juegan esa fecha. El servidor calcula la fecha con su propia hora y con la zona horaria guardada en la cuenta; esa zona solo se puede cambiar cada cierto tiempo (por ejemplo, cada 7 días, valor en Remote Config); y no entrega un reto con fecha posterior a la del huso más adelantado (UTC+14). La racha también se cuenta por fecha local con la zona guardada. Reemplaza la recomendación de la auditoría (medianoche de Colombia para todos).
  - **8.** La víctima es una **ficha normal marcada con †, sin cuerpo ni sangre**. Se corrigen los docs 13, 15 y 20.
  - **16.** Edad mínima de **13 años o más**. La clasificación final la da el cuestionario de cada tienda.
  - **17.** Publica como **persona natural**. Con compras, las tiendas la tratan como comerciante y en la UE pueden mostrar sus datos de contacto: conviene un apartado postal u oficina virtual y preguntar a un contador por los ingresos. No bloquea el desarrollo.
  - **18.** La versión que revisa la tienda va **sin la tienda, el premium ni el ranking simulados, y sin ajustes que no hacen nada**.
  - **23.** Los mundos bloqueados **se muestran con candado**. Se corrige el doc 06.
- **Partida sin conexión (07-11-2026):** se juega sin señal y Resolver espera a que vuelva la conexión. Detalle en el [ADR-0016](adr/0016-validacion-en-servidor-y-partida-sin-conexion.md), aceptado completo el 07-11-2026.
- **Siguen pendientes:** 12, 13, 14, 15, 22 (solo el iPhone), más las preguntas abiertas de la sección 4 del plan nuevo: si el iPhone entra al lanzamiento, el orden (prueba cerrada ya o después) y puntos y ayudas (la 12).

## Plan por etapas 0 a 6 (aprobado por Alejandro el 04-11-2026)

Este plan reordena el trabajo que antes estaba en las Fases 1 a 4. La razón (hallazgos H-22, H-23 y H-24): el arte iba al final aunque la queja principal de hoy es el arte; no hay registro de que se haya medido si el juego engancha; y lo que el plan viejo llamaba "MVP publicable" no incluía los trámites de las tiendas.

Los tiempos y costos son **estimaciones sin verificar**, tomadas de la auditoría y del informe gráfico.

### Etapa 0. Orden y protección

- **Qué incluye:**
  - la protección del trabajo de la sección 3 de la auditoría. **Autorizado el 04-11-2026: solo el repositorio privado en GitHub** (todavía no creado; lo crea Alejandro). **Todavía no autorizados:** el commit del 01-11-2026, sacar el proyecto de OneDrive, versionar `app/pubspec.lock` y cambiar la configuración de firma. Quedan además sin decidir la verificación automática, el respaldo de la llave de firma y que OneDrive deje de sincronizar las compilaciones;
  - los documentos al día (sección 6 de la auditoría);
  - las decisiones de reglas del primer grupo de la sección 5 (el grupo "Antes de la prueba de juego": preguntas 5, 9, 10, 11, 20 y 21). **Decididas el 04-11-2026** (ver arriba y ADR-0012).
- **Termina cuando:** el proyecto está en GitHub; los documentos dicen la verdad o están marcados como "en revisión"; las decisiones del primer grupo están escritas.
- **¿Toca código?** Solo configuración (firma y versiones de librerías).
- **Tiempo y costo:** sin costo de dinero.
- **Estado al 04-11-2026:** en curso. Los documentos se ponen al día (autorizado). Las decisiones del primer grupo están tomadas. La protección espera a que Alejandro cree el repositorio privado y autorice el resto.

### Etapa 1. ¿Es divertido y justo?

- **Qué incluye:**
  - **Versión de prueba:** se arregla lo mínimo para que la medición no salga sucia: guardar la partida y pedir confirmación al salir (H-55), poder leer la pista completa al tocarla (H-56), ocultar o rotular los datos simulados (H-62), ordenar los casos como números (H-50) y poner la versión de la app en el feedback (H-70). ~~Lo que quede provisional, como el tutorial y el resaltado de errores, se avisa a los probadores.~~ (SUPERADO 04-11-2026: las reglas de abajo ya están decididas; lo que no alcance a quedar listo se avisa a los probadores.)
  - **Reglas decididas que se aplican en la versión de prueba** (ADR-0012; los cambios de código se autorizan aparte):
    - Con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos; la partida queda guardada (regla 5).
    - Al fallar en Resolver se muestra solo cuántas casillas no cuadran (regla 9).
    - La partida se guarda siempre; al salir, el reloj se pausa y el tablero se oculta durante la pausa (regla 10).
    - Tutorial propio de 4×4 o 5×5, obligatorio la primera vez, con Saltar visible, que no cuenta como Caso 1 (regla 11).
    - Aviso "Elige primero a un sospechoso" al tocar una casilla sin sospechoso elegido; el modo de tocar dos veces se diseña en la etapa 2 (regla 20).
  - **Prueba de juego:** Alejandro juega 10 casos y 3 a 5 personas externas juegan los suyos. Se registran tiempo por caso, errores, dónde se atasca cada uno y si lo volvería a jugar mañana.
- **Termina cuando:** se cumplen los umbrales que se fijen antes de empezar. Ejemplo de la auditoría: al menos 3 de 4 personas terminan el tercer caso Principiante sin que nadie les explique ni les dé pistas, y 3 de 4 lo volverían a jugar. Estos umbrales reemplazan al criterio de salida original de la Fase 1.
- **¿Toca código?** Poco.
- **Tiempo y costo:** sin costo de dinero; requiere el tiempo de Alejandro y el de las personas. Necesita 3 a 5 personas con Android, porque el iPhone nunca se ha compilado. Alejandro dijo el 04-11-2026 que puede conseguirlas (pregunta 21 resuelta). Sus datos sirven para calibrar los rangos de dificultad de la etapa 3.

### Etapa 2. Prueba de concepto gráfica

- **Qué incluye:** la del [informe gráfico](../production/revisiones/2026-11-04-investigacion-grafica.md): opción A (quedarse en Flutter y usar Flame, una librería para hacer juegos dentro de Flutter, y Rive, un programa para animar personajes), en una carpeta aparte y con una copia fija del generador de hoy.
- **Termina cuando:** se cumplen los 7 criterios de la sección 9 del informe gráfico (fluidez, peso, arranque, toques sin bloqueo, opinión de 5 a 8 personas y el veredicto de Alejandro). Si falla, se aplica el plan alterno de ese informe.
- **¿Toca código?** Sí, pero aislado del juego actual.
- **Tiempo y costo:** 1 a 2 semanas; 50 a 200 USD en herramientas, más un teléfono de prueba si no hay.
- ~~**Condición para empezar:** que Alejandro la autorice y responda las preguntas 1, 2, 3, 5, 7, 8 y 10 de la sección 10 del informe gráfico.~~ (SUPERADO 04-11-2026)
- **Autorizada por Alejandro el 04-11-2026**, con estas condiciones:
  - la prueba muestra **ambas** opciones, papel recortado tipo maqueta e ilustración 2D sin papel, para compararlas;
  - arte provisional gratuito (CC0, por código o con texturas de papel fotografiadas por Alejandro); el arte de pago se decide después;
  - meta visual: "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match;
  - **referencias visuales pendientes**: Alejandro pidió ver ejemplos antes de elegir;
  - teléfono de prueba: un Android de gama media de Alejandro;
  - aquí se diseña el modo alternativo de tocar dos veces (regla 20).

### Etapa 3. Motor y contenido

- **Qué incluye:**
  - arreglar el error del generador y el control de dificultad (los rangos definitivos se fijan con los datos de la prueba de juego);
  - una puerta automática de contenido;
  - un catálogo de casos con id único;
  - una prueba de generación en 12×12 y 16×16, con un prototipo en pantalla para ver si se pueden jugar;
  - el Mundo 1 (La Mansión) con 10 casos y narrativa propia;
  - 30 días de reto diario.
- **Termina cuando:** `qa` verifica el Mundo 1 completo.
- **¿Toca código?** Sí: el motor (`tools/`) y cambios pequeños en la app (cómo carga los casos y las claves del progreso).
- **Tiempo y costo:** sin costo de dinero (trabajo de agentes).

### Etapa 4. Producción visual

- **Condición:** solo si pasan la prueba de juego (etapa 1) y la prueba de concepto (etapa 2).
- **Qué incluye:** primero, pruebas automáticas de la partida y preparación del tablero (H-57, H-60). Después: el estilo en todas las pantallas, game feel (la sensación al jugar), sonido, vibración, guardado completo de partida, accesibilidad y textos listos para traducir.
- **Termina cuando:** el Mundo 1 completo con el estilo definitivo pasa la lista de verificación que se fije al cerrar la etapa 2.
- **¿Toca código?** Sí.
- **Tiempo y costo:** según el informe gráfico, 12 a 16 semanas y 2.000 a 8.500 USD por mundo con la opción A.

### Etapa 5. Servidor (Firebase)

- **Qué incluye:**
  - **5A:** cuentas, validación de la solución en el servidor y casos sin la solución dentro.
  - **5B:** ranking, reto diario real, vidas y compras.
  - Antes de empezar se escribe un ADR (un registro corto de una decisión técnica, con opciones y motivo) sobre cómo validar en el servidor (H-41).
- **Termina cuando:** la validación en el servidor funciona.
- **Plan detallado (06-11-2026):** [production/planes/2026-11-06-etapas-5-y-6.md](../production/planes/2026-11-06-etapas-5-y-6.md), sección 2. Incluye las decisiones de vidas de premium y de la hora del reto diario (medianoche local de cada jugador). La partida sin conexión se decidió el 07-11-2026: ver el [ADR-0016](adr/0016-validacion-en-servidor-y-partida-sin-conexion.md).
- **¿Toca código?** Sí.
- **Tiempo y costo:** sin estimar.
- Aquí caducan las excepciones de la Fase 1 (solución local y datos simulados).

### Etapa 6. Tiendas

- **Qué incluye:** trámites legales; en Google Play, la prueba cerrada con probadores; iPhone solo si Alejandro decide que entra al lanzamiento.
- **Termina cuando:** publicación.
- **¿Toca código?** Poco.
- **Tiempo y costo:** cuentas de unos 25 USD únicos en Google Play y unos 99 USD al año en Apple (conocimiento general, a confirmar). ACTUALIZACIÓN 06-11-2026: Alejandro ya tiene pagadas las dos cuentas.
- **Plan detallado (06-11-2026):** [production/planes/2026-11-06-etapas-5-y-6.md](../production/planes/2026-11-06-etapas-5-y-6.md), sección 3. Se puede empezar en paralelo con la etapa 5. La versión para revisión va sin tienda, premium ni ranking simulados (pregunta 18, decidida). Edad mínima 13+ y publicación como persona natural, decididas.

### Cómo encajan las etapas (trabajo en paralelo)

Las etapas 1, 2 y 3 pueden avanzar al mismo tiempo con tres condiciones:

1. La prueba de juego usa una versión congelada de la app, con los 20 casos actuales.
2. La prueba de concepto usa una copia fija del generador de hoy. Si después cambia el formato de los casos, se adapta.
3. Alejandro es el cuello de botella: jugar, reclutar personas, aprobar arte y contratar planes necesita su tiempo. Conviene escalonar el arranque, por ejemplo empezar con la prueba de juego y sumar la prueba de concepto unos días después.

**El arte grande espera a las dos pruebas.** Ninguna inversión grande en arte (etapa 4, ilustrador o animador) arranca antes de tener los resultados de la prueba de juego y de la prueba de concepto. Si la prueba de juego falla, se corrige primero el juego (reglas y dificultad). Si falla la prueba de concepto, se aplica el plan alterno del informe gráfico.

**Trámites que conviene empezar ya**, porque no dependen del código:

- ~~decidir si se publica como persona natural o como empresa (pregunta 17);~~ (DECIDIDO 06-11-2026: persona natural)
- ~~crear la cuenta de desarrollador de Google Play;~~ (HECHO: Alejandro ya la tiene pagada, 06-11-2026)
- publicar la política de privacidad.

Los 14 días de la prueba cerrada de Google Play no se pueden acelerar. Por eso la auditoría propone lanzarla con una versión estable de la Fase 1, sin la tienda ni el ranking simulado, apenas termine la etapa 1. Las reglas de Google cambian: hay que confirmarlas en Play Console antes de planificar (H-24).

### Decisiones pendientes que afectan a este plan

Solo quedan las preguntas abiertas. Las decididas el 04-11-2026 (5, 9, 10, 11, 20 y 21) están en "Decisiones de Alejandro del 04-11-2026". Las preguntas son las de la sección 5 de la [auditoría](../production/revisiones/2026-11-04-auditoria-proyecto.md).

| Pregunta | Tema | Qué parte del plan toca |
|---|---|---|
| ~~6~~ | ~~Vidas de premium~~ **DECIDIDA 06-11-2026:** premium con vidas ilimitadas | Etapa 5B (vidas) |
| ~~7~~ | ~~Hora del reto diario~~ **DECIDIDA 06-11-2026:** medianoche local de cada jugador, mismo caso para todos en la misma fecha | Etapa 3 (30 días de reto) y etapa 5B |
| ~~8~~ | ~~Representación de la víctima~~ **DECIDIDA 06-11-2026:** ficha normal con †, sin cuerpo ni sangre | Documentos y etapa 4 |
| 12 | Ayudas y puntuación | Etapa 3 |
| 13 | Si Experto y Élite entran al lanzamiento | Etapa 3 (prueba de generación) |
| 14 | Contenido de lanzamiento | Etapa 3 |
| 15 | Inglés y formato de las pistas | Antes de la etapa 3 |
| ~~16~~, ~~17~~ | ~~Edad mínima; identidad legal~~ **DECIDIDAS 06-11-2026:** 13 años o más; persona natural | Etapa 6 |
| ~~18~~ | ~~Qué se ve en el build de tiendas~~ **DECIDIDA 06-11-2026:** sin tienda, premium ni ranking simulados y sin ajustes que no hacen nada | Etapa 6 |
| ~~19~~ | ~~Uso del arma~~ **DECIDIDA 05-11-2026** (ADR-0014): se mantiene en mansion-08 a 10 y en 9 de los 30 retos | Etapa 3 |
| 22 | **RESUELTA 09-11-2026:** Alejandro pidió subir la app a la App Store, así que el iPhone entra (primero por TestFlight, ADR-0017). Texto anterior: solo si el iPhone entra al lanzamiento (el Mac ya está confirmado, y desde el 06-11-2026 también la cuenta de Apple pagada) | Etapa 6 |
| ~~23 (nueva)~~ | ~~Si se muestran los mundos bloqueados~~ **DECIDIDA 06-11-2026:** se muestran con candado (doc 06 corregido) | Etapa 4 y doc 06 |

> ACTUALIZACIÓN 06-11-2026: se tacharon las preguntas 6, 7, 8, 16, 17, 18 y 23, decididas ese día (ver "Decisiones de Alejandro del 06-11-2026"). La 19 ya estaba decidida el 05-11-2026 en el [ADR-0014](adr/0014-alcance-de-contenido-de-la-v1.md); el arquitecto la quitó de las pendientes y del plan del 06-11-2026.

~~Versión anterior de esta tabla (SUPERADA 04-11-2026): incluía además las preguntas 5, 9, 10, 11, 20 y 21 como pendientes, y la 22 como "iPhone y Mac".~~

## Historial del plan original (10-06-2026)

> ACTUALIZACIÓN 04-11-2026: lo que sigue es el roadmap original, conservado completo. Está **superado como plan de trabajo** por el plan por etapas de arriba, pero sirve para ver qué se hizo y por qué. Se marcó qué entregables se hicieron según `git log` y se corrigieron las cifras viejas (cada corrección va en una nota "ACTUALIZACIÓN").
>
> Correspondencia aproximada con las etapas nuevas, según la auditoría: la Fase 1 pasa a ser la etapa 1 (medir el juego); el servidor, las cuentas, el reto diario real, el ranking, las vidas y las compras (Fases 2 y 3) pasan a la etapa 5; el Mundo 1 y el reto diario pasan a la etapa 3; el arte, el sonido, la accesibilidad y los textos traducibles pasan a la etapa 4; los trámites legales y la publicación (Fase 4) pasan a la etapa 6. Los mundos 2 a 5, la localización completa al inglés, la analítica completa y las herramientas internas no tienen etapa asignada todavía.

> **Fase actual: FASE 0**
>
> ACTUALIZACIÓN 04-11-2026: esa línea ya no es cierta. Ver "Estado verificado al 04-11-2026": la Fase 0 está cerrada y la Fase 1 está en curso.

### FASE 0 — El corazón: spec + solver (sin app, sin backend)

La apuesta del proyecto es que se pueden generar casos con solución única y dificultad calibrada. Si esto no funciona, no hay juego. Se demuestra primero.

Entregables:

- [x] Cerrar preguntas abiertas de `16-spec-puzzle.md` (sección 7) — 2026-06-10
- [x] Modelo de datos en Dart puro (`tools/`): mapa, área, celda, personaje, pista, caso
- [x] Motor de deducción (8 técnicas en 4 niveles, resuelve sin adivinar)
- [x] Verificador de unicidad (backtracking exhaustivo con poda)
- [x] Contador de pasos de deducción + métricas por caso
- [x] Generador de casos (pool de pistas verdaderas → minimización a conjunto irreducible)
- [x] Suite de tests deterministas (38 tests: semántica de pistas, validador, doble solución, caso que requiere adivinar, determinismo por semilla)
- [x] CLI: `generate` / `show` / `validate` (`tools/bin/enigmatrix.dart`)

> ACTUALIZACIÓN 04-11-2026: los 8 entregables se hicieron (commits `5ea74da` y `dd9abf9`, 10-06-2026). El motor se rediseñó el 11-06-2026 (`6af707a`, `21b2f87`, `954a3fd`). La suite tiene hoy **54 tests** en `tools/test`, no 38.

Criterio de salida: ✅ CUMPLIDO (2026-06-10) — 20 casos generados (8 principiante 4×4, 7 casual 5×5 —uno con arma—, 5 intermedio 6×6), todos con solución única verificada y deducción pura. Hojas imprimibles en `production/fase0-casos/`. **Pendiente: que el usuario juegue algunos en papel y valide que se sienten bien.**

> ACTUALIZACIÓN 04-11-2026: los 20 casos se regeneraron el 11-06-2026 (`954a3fd`) con mapas únicos y los tamaños nuevos: hoy son 8 Principiante 6×6, 7 Casual 8×8 y 5 Intermedio 9×9 (los tamaños 4×4, 5×5 y 6×6 ya no existen en el generador). Las hojas imprimibles de `production/fase0-casos/` son de los casos viejos y usan los mismos ids que otros casos (H-51). Lo de "jugar algunos en papel y validar" sigue sin registro de cumplimiento (H-22): lo cubre la prueba de juego de la etapa 1.

Hallazgos de Fase 0 (detalle en spec 16 §3.2): las pistas solo de área nunca dan unicidad (se requieren pistas de celda en toda dificultad); rangos de pistas reales: 4×4≈4-6, 5×5≈8-9, 6×6≈10-12 (el doc 05 quedó corto y se recalibrará con playtest).

> ACTUALIZACIÓN 04-11-2026: esos rangos son de los tableros viejos (4×4, 5×5 y 6×6). Con la regla del mínimo 2 del 11-06-2026 los pasos de deducción subieron de 3-7 a 5-14. Los rangos definitivos para los tamaños actuales se fijan con los datos de la prueba de juego (etapa 3).

### FASE 1 — Vertical slice jugable (app local, sin cuentas)

Una app Flutter que se instala en el teléfono del usuario y se juega. Sin Firebase, sin login: casos empaquetados localmente. El objetivo es validar la experiencia de juego y la UI del tablero.

Entregables:

- [x] Proyecto Flutter (`app/`) con Riverpod + go_router — 2026-06-10, corre como web local (banco de pruebas)
- [x] Tablero jugable: áreas con paredes, objetos, armas visibles, avatares (widgets por celda; CustomPainter se evaluará para animaciones)
- [x] Interacción: candidato/confirmado/X parcial/fuerte, tap y arrastre, papelera, mini panel de borrado, deshacer/rehacer (límite 50), limpiar con confirmación
- [~] Modos de notas: toggle Mapa/Notas básico (la versión definitiva con mockups)
- [x] Pistas visibles con ciclo normal→destacada→tachada
- [x] Botón Resolver con validación local + resaltado de casillas incorrectas + bloqueo temporal (throwaway aceptado; en Fase 2 valida el servidor)
- [x] Pantallas: lista de casos, partida, resumen con revelación de asesino/arma
- [x] Instrumentación de playtest: cronómetro, contador de errores, feedback por caso, exportar feedback al portapapeles
- [x] Tutorial guiado (versión simple)
- [~] Design System: colores/tipografía base integrados; UI definitiva cuando lleguen los mockups
- [x] Versión Android instalada en el teléfono del usuario

> ACTUALIZACIÓN 04-11-2026, según `git log` y la bitácora:
> - Se marcaron como hechos dos entregables que estaban sin marcar. **Tutorial guiado:** hecho en versión simple (diálogo de 5 páginas, `86f5925`, y tutorial jugable de 7 pasos, `6cdd9f6`). **Versión Android instalada:** el APK se compiló (`561c11e`), el AAB firmado con la llave de subida también (`28bbde9`), y Alejandro ya dio feedback jugándolo en su teléfono (12-07-2026).
> - **Tablero:** hoy es una cuadrícula de widgets con un contenedor por casilla (`board_view.dart`) y los muebles se dibujan con `CustomPainter` (`furniture_painters.dart`). Si la prueba de concepto de la etapa 2 lo aprueba, el tablero pasaría a una escena de Flame con Rive.
> - **Modos de notas:** el toggle Mapa/Notas existe; "la versión definitiva con mockups" quedó sin sentido, porque los mockups de Claude Design se abandonaron el 11-07-2026.
> - **Design System:** superado. Claude Design se abandonó y el 12-07-2026 se eligió el estilo Paper Craft, aplicado en toda la app. Desde el 01-11-2026 la dirección gráfica está en revisión (etapa 2).
> - **DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo cuántas casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
>   - (SUPERADO 04-11-2026) Versión anterior: el botón Resolver marca exactamente las casillas erróneas con 3 segundos de bloqueo. Así funciona el código hasta que se haga la versión de prueba de la etapa 1.
> - **DECIDIDO 04-11-2026** (auditoría, pregunta 11; ver ADR-0012): el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1; enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
>   - (SUPERADO 04-11-2026) Versión anterior: hay dos tutoriales y los dos se pueden omitir; los documentos piden uno obligatorio.
> - **Lo adelantado además de esta lista** (excepción del 12-07-2026): shell de navegación con Inicio, Mundos, Reto, Ranking y Perfil, tienda y premium simulados, logo, splash, icono y cumplimiento de tiendas (firma, permisos, política de privacidad en borrador, checklist `docs/20-checklist-tiendas.md`).

Cómo probar: doble clic en `JUGAR.bat` (sirve la web compilada en http://localhost:8123). Tests: `flutter test` en `app/` (9 tests de reglas del tablero).

> ACTUALIZACIÓN 04-11-2026: hay **26 tests** en `app/test` (no 9): reglas del tablero y pantallas. Para compilar el APK está `COMPILAR-ANDROID.bat`.

Criterio de salida: el usuario juega 10 casos y el loop se siente bien. Feedback de UX documentado.

> ACTUALIZACIÓN 04-11-2026: este criterio no tiene registro de cumplimiento (H-22). Lo reemplaza la etapa 1 del plan por etapas, con umbrales medibles que se fijan antes de empezar.

### FASE 2 — Online: cuentas, reto diario y ranking (el MVP mínimo publicable)

Entra Firebase. La validación se mueve al servidor (el cliente deja de conocer la solución).

Entregables:

- [ ] Firebase Auth: Google + email/contraseña + verificación de correo
- [ ] Perfil: nickname único, avatar, bandera
- [ ] Firestore: colecciones users, maps, cases, attempts (doc 07)
- [ ] Cloud Functions: entregar caso sin solución, validar solución, puntos (fórmula doc 08)
- [ ] Reto diario: calendario en servidor, intento oficial único, ventana por hora de servidor
- [ ] Ranking diario + racha básica (sin protectores aún)
- [ ] Partida pendiente única global (regla doc 01)
- [ ] Campaña Mundo 1 (Mansión, ~10 mapas) con progresión secuencial
- [ ] Anti-trampa base: solución solo en servidor, FLAG_SECURE, rotación de mapa
- [ ] Reglas de seguridad de Firestore revisadas por agente `seguridad`

Criterio de salida: build cerrada en Google Play (testing interno) con amigos/familia jugando el reto diario real durante 2 semanas.

> ACTUALIZACIÓN 04-11-2026: ningún entregable de esta fase está hecho (no existe servidor). Lo que tocaba a esta fase se reparte así: la campaña del Mundo 1 pasa a la etapa 3 (como contenido, sin servidor); la parte de servidor (cuentas, validación, casos sin la solución dentro, ranking, reto diario real) pasa a la etapa 5 (5A y 5B). Hay versiones simuladas del perfil, el reto diario y el ranking (excepción del 12-07-2026).
>
> - **DECIDIDO 06-11-2026** (auditoría, pregunta 7): el reto diario cambia a la medianoche local de cada jugador, con la fecha calculada por el servidor según la zona guardada en la cuenta. ~~(SUPERADO) PENDIENTE DE DECISIÓN: "ventana por hora de servidor" contradecía a otro documento que decía "día local".~~
> - **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 14): con cuánto contenido se lanza (el roadmap pone el Mundo 1 con ~10 mapas en esta fase; el plan por etapas incluye el Mundo 1 con 10 casos y 30 días de reto diario en la etapa 3).
> - El criterio de salida (testing interno con amigos y familia) **no cubre** los trámites de las tiendas: en Google Play, una cuenta personal nueva necesita, según lo investigado, 12 probadores durante 14 días (H-24). Pasa a la etapa 6.

### FASE 3 — Economía y retención

- [ ] Vidas (5 máx, recarga por hora, autoridad de servidor)
- [ ] Protectores de racha + hitos
- [ ] Ranking semanal + ranking por mapa
- [ ] Práctica y "mapa sin resolver"
- [ ] Anuncios (intersticial + recompensados) con frecuencias del doc 08
- [ ] Premium mensual/anual + packs (Google Play Billing, validación de recibos en servidor)
- [ ] Tienda
- [ ] Compartir resultados
- [ ] Notificaciones push (FCM): reto disponible, racha en peligro

Criterio de salida: economía completa funcionando en testing cerrado; ninguna compra entrega nada sin validación de recibo en servidor.

> ACTUALIZACIÓN 04-11-2026: ningún entregable real está hecho. Existen versiones simuladas (DEMO) de las vidas (4 de 5, fijas), la racha, el ranking, la tienda y el premium (excepción del 12-07-2026), sin cobros reales. Lo real (vidas, compras, ranking) pasa a la etapa 5B.
>
> - **DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
>   - (SUPERADO 04-11-2026) Versión anterior: qué pasa al quedar con 0 vidas no estaba definido.
> - **DECIDIDO 06-11-2026** (auditoría, pregunta 6): premium con vidas ilimitadas. ~~(SUPERADO) PENDIENTE DE DECISIÓN: ilimitadas o tope de 5 con recarga instantánea.~~

### FASE 4 — Contenido y lanzamiento

- [ ] Mundos 2-5 (Hotel, Museo, Tren, Hospital): mapas + arte + arquetipos narrativos (doc 13)
- [ ] Stock de reto diario: mínimo 60 días aprobados (meta 120, doc 05)
- [ ] Herramientas internas mínimas: visor de casos para revisión, calendario de retos
- [ ] Localización EN completa
- [ ] Accesibilidad V1 (doc 11): contraste, modo daltónico, escala de texto, alternativa al arrastre
- [ ] Analítica completa (doc 14) + consentimiento
- [ ] Legal: política de privacidad, términos, eliminación de cuenta (doc 15)
- [ ] Checklist Google Play + lanzamiento abierto Android

> ACTUALIZACIÓN 04-11-2026: ningún entregable está hecho del todo. Hay un borrador de política de privacidad (`docs/legal/politica-privacidad.md`, faltan el responsable y el correo) y un checklist por tienda (`docs/20-checklist-tiendas.md`), ambos incompletos. Hoy no hay traducciones, soporte para lectores de pantalla ni audio.
>
> - **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 14): contenido de lanzamiento. Este roadmap pide un stock de 60 días de reto diario y los mundos 2 a 5; la auditoría recomienda lanzar con el Mundo 1 y 30 días de reto diario. No se resuelve aquí.
> - **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 15): si hay inglés desde el lanzamiento y cómo se guardan las pistas (hoy el motor las escribe directamente en español).
> - **DECIDIDO 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". Hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto.
>   - (SUPERADO 04-11-2026) Versión anterior: la alternativa al arrastre estaba sin decidir (hoy confirmar una ficha exige mantener oprimido o arrastrar).
> - **DECIDIDO 06-11-2026** (auditoría, preguntas 16 y 17): edad mínima de 13 años o más y publicación como persona natural. ~~(SUPERADO) PENDIENTE DE DECISIÓN: 12+ contra 13, y persona natural contra empresa.~~

## Fuera de roadmap (post-lanzamiento)

iOS, amigos, rankings por país, temporadas, eventos, logros, moneda interna, anti-cheat avanzado — ver `04-futuro.md`.

> ACTUALIZACIÓN 04-11-2026: el 12-07-2026 Alejandro confirmó que tiene acceso a un Mac. **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 22, reducida): solo si el iPhone entra al lanzamiento (este roadmap lo deja fuera; el proyecto iOS ya se generó pero nunca se ha compilado). CLAUDE.md dice "Android primero, iOS después".

## Decisiones de recorte respecto al doc 01 (aprobadas por el usuario, 2026-06-10)

- El MVP se construye por fases; la "V1" del doc 01 equivale a completar Fase 4.
- Monetización pospuesta a Fase 3 (no bloquea validar el juego).
- 5 mundos pospuestos a Fase 4 (Fase 2 sale con Mundo 1).
- Herramientas internas reducidas al mínimo (JSON a mano + CLI hasta Fase 4).

> ACTUALIZACIÓN 04-11-2026: el 12-07-2026 Alejandro aprobó incluir ya la monetización **simulada** (tienda y premium DEMO), sin cobros reales; la monetización real sigue en la etapa 5B. La "V1" equivale ahora a completar la etapa 6 del plan por etapas.

## Riesgos vigilados

| Riesgo | Señal de alarma | Mitigación |
|---|---|---|
| El solver no genera casos Elite interesantes | Fase 0 produce solo casos triviales | Subir tamaño de grilla/pistas compuestas antes de seguir |
| Scope creep | Una fase lleva >2× lo previsto | Recortar la fase, no extenderla |
| Arte de 5 mundos | Sin fuente de assets clara en Fase 2 | Decidir en Fase 2: IA generativa vs comisión (ADR) |
| Costos Firestore | Lecturas disparadas en testing | Agregaciones precalculadas desde el día 1 (doc 07) |

> ACTUALIZACIÓN 04-11-2026: el riesgo "Arte de 5 mundos" se atiende ahora con las etapas 2 (prueba de concepto gráfica) y 4 (producción visual); la decisión de la fuente del arte (ilustración, IA curada o kit) sigue abierta y requiere un ADR. El riesgo "El solver no genera casos Elite interesantes" sigue sin medirse: Experto y Élite nunca se han generado (se mide en la etapa 3, y la pregunta 13 decide si entran al lanzamiento).

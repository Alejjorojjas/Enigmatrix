# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito. Se mantiene corto a propósito: el historial completo está en [historial.md](historial.md).

## Estado hoy (04-11-2026)

- **Etapa actual:** etapa 0, "Orden y protección", del plan por etapas 0 a 6 (aprobado; detalle en [docs/17-roadmap.md](../../docs/17-roadmap.md)). Sin tocar código.
- **Dónde está el proyecto:** Fase 0 cerrada; Fase 1 hecha en gran parte (app Flutter con 20 casos, tutorial, shell con pantallas simuladas DEMO, Paper Craft). Último commit: `84835be` (12-07-2026). Hay cambios sin commit del 01-11-2026.
- **Protección:** Alejandro creó el repositorio privado `https://github.com/Alejjorojjas/Enigmatrix` y autorizó los commits el 04-11-2026. Los commits llevan solo su autoría, sin coautoría de Claude. Siguen sin autorizar: sacar el proyecto de OneDrive, versionar `app/pubspec.lock` y cambiar la firma.
- **Documentos:** puestos al día el 04-11-2026 y revisados por el arquitecto y por dos verificadores independientes. El índice con el estado de cada documento está en [docs/README.md](../../docs/README.md) y hay registros de decisión nuevos (ADR 0003 a 0012).
- **Decididas el 04-11-2026:** reglas 5, 9, 10, 11 y 20; pregunta 21 (3 a 5 personas); prueba de concepto gráfica autorizada con ambos estilos y arte gratuito; Mac confirmado desde el 12-07-2026 (ver "Decisiones vigentes").
- **Preguntas abiertas:** 6, 7, 8, 12, 13, 14, 15, 16, 17, 18, 19, 22 (solo el iPhone) y 23 (nueva). Detalle en la [sección 5 de la auditoría](../revisiones/2026-11-04-auditoria-proyecto.md#5-decisiones-que-necesito-de-ti) y abajo.
- **Cómo se juega hoy:** `JUGAR.bat` abre http://localhost:8123 (web local). `COMPILAR-ANDROID.bat` genera el APK.
- **Estado verificado en el código:** 54 tests en `tools/test` y 26 en `app/test`; tableros 6×6, 8×8, 9×9, 12×12 y 16×16 (solo los tres primeros tienen casos); `shared_preferences`; sin audio, vibración, traducciones ni lectores de pantalla.
- **Próximos pasos:**
  1. ~~Alejandro crea el repositorio privado en GitHub y Claude sube el historial.~~ Hecho el 04-11-2026.
  2. Alejandro consigue sus propias referencias visuales: las 5 sugeridas no le gustaron.
  3. Preparar la versión de prueba de la etapa 1 (cambios pequeños de código que hay que autorizar, con las reglas decididas) y la guía de la prueba de juego.
  4. Arrancar la prueba de concepto gráfica (etapa 2), escalonada unos días después de la prueba de juego.

### Preguntas abiertas (sin decidir; ninguna se resuelve en los documentos)

Cada número es el de la [sección 5 de la auditoría](../revisiones/2026-11-04-auditoria-proyecto.md#5-decisiones-que-necesito-de-ti).

- **Después de las pruebas:** 12 (ayudas y puntuación), 13 (si Experto y Élite entran al lanzamiento).
- **Cuando quiera:** 6 (vidas de premium), 7 (hora del reto diario), 8 (representación de la víctima), 14 (contenido de lanzamiento), 15 (inglés y formato de las pistas), 16 (edad mínima), 17 (identidad legal), 18 (qué se ve en el build de tiendas), 19 (uso del arma), 22 (solo si el iPhone entra al lanzamiento).
- **PENDIENTE DE DECISIÓN (pregunta 23, nueva):** si se muestran los mundos bloqueados. Hoy la app muestra los 5 mundos, 4 con candado, y el doc 06 dice que solo se muestran los desbloqueados.
- **Pendiente sin número:** referencias visuales para la prueba de concepto. El 04-11-2026 se le mostraron Lumino City, Paper Trail, Hidden Folks, The Case of the Golden Idol y Monument Valley, y **ninguna le gustó**. Él va a conseguir sus propias referencias. La dirección de arte de la prueba de concepto espera a esas referencias.

## Decisiones vigentes

Las decisiones técnicas importantes se registran como ADR en [docs/adr/](../../docs/adr/); los ADR retroactivos de decisiones ya tomadas empiezan en el número 0003. Todo lo anterior a esta lista está en el [historial](historial.md).

- 10-06-2026: Flutter y Riverpod como base de la app (ADR 0001 y 0002 en [docs/adr/](../../docs/adr/); el resto del stack ha cambiado, ver CLAUDE.md).
- 10-06-2026: el proyecto avanza por fases; monetización, 5 mundos y herramientas internas se recortaron a fases posteriores ([docs/17-roadmap.md](../../docs/17-roadmap.md)).
- 10-06-2026: la grilla es de N×N casillas y hay tantos personajes como casillas por lado ([spec 16](../../docs/16-spec-puzzle.md)).
- 11-06-2026: rediseño "Murdoku" del motor: vocabulario de muebles, una pista por tarjeta, sin pistas mecánicas; regla del mínimo 2 (ninguna pista deja sola una casilla posible); mapas únicos generados por caso; tamaños 6×6, 8×8, 9×9, 12×12 y 16×16; Auto-X opcional (spec 16).
- 11-07-2026: se abandona Claude Design y la interfaz se hace directo en Flutter.
- 12-07-2026: estilo Paper Craft elegido entre los mockups de `docs/mockups/estilos/`. Desde el 01-11-2026 la dirección gráfica está en revisión (etapa 2, [informe gráfico](../revisiones/2026-11-04-investigacion-grafica.md)).
- 12-07-2026: pantallas completas primero con datos locales simulados (DEMO), Firebase después. La monetización entra ya simulada. La campaña es solo el Mundo 1 (La Mansión, 10 casos) para calibrar. Es una excepción explícita a "no adelantar fases" (ver [docs/17-roadmap.md](../../docs/17-roadmap.md)).
- 12-07-2026: riesgo aceptado de la Fase 1: la solución viaja dentro del JSON del caso y se valida en el teléfono ([doc 18](../../docs/18-revision-seguridad-fase1.md)). Caduca en la etapa 5.
- 12-07-2026: Android primero, iPhone después; se juega y corrige ahora y se publica al final ([doc 20](../../docs/20-checklist-tiendas.md)). **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 22, reducida el 04-11-2026): solo si el iPhone entra al lanzamiento; el acceso a un Mac ya está confirmado (ver abajo).
- 12-07-2026: ajustes de la partida pedidos por Alejandro jugando en el teléfono: Resolver arriba junto al contador de errores, barra de pistas fija bajo el tablero y pistas como tarjetas de personaje compactas.
- 01-11-2026: la sesión principal es el arquitecto (Opus); todo lo delegado corre en Sonnet, o Haiku para lo mecánico. Claude Code se abre siempre en la carpeta del proyecto, no en la carpeta padre.
- 04-11-2026: plan por etapas 0 a 6 aprobado por Alejandro: protección y documentos, prueba de juego, prueba de concepto gráfica, motor y contenido, producción visual, servidor y tiendas. El arte grande espera a las dos pruebas.
- 04-11-2026: las excepciones de la Fase 1 quedan escritas en CLAUDE.md (solución local, datos simulados DEMO, sin servidor) y caducan en la etapa 5.
- 04-11-2026: Alejandro aprobó el **plan por etapas 0 a 6** (ya registrado arriba) y autorizó **poner los documentos al día**.
- 04-11-2026: **protección autorizada solo en parte.** Autorizó el repositorio privado en GitHub, que aún no existe (lo crea él en github.com). **No** autorizó todavía el commit, sacar el proyecto de OneDrive, versionar `app/pubspec.lock` ni cambiar la configuración de firma.
- 04-11-2026: **prueba de concepto gráfica (etapa 2) autorizada** con estas condiciones: meta visual "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match; la prueba muestra **ambas** opciones (papel recortado tipo maqueta e ilustración 2D sin papel) para compararlas; arte provisional gratuito (CC0, por código o con texturas de papel fotografiadas por Alejandro), el arte de pago se decide después. Las referencias visuales están **pendientes**: Alejandro pidió ver ejemplos (ADR-0005).
- 04-11-2026: teléfono de prueba: Alejandro tiene un Android de gama media.
- 04-11-2026: **pregunta 21 resuelta:** Alejandro puede conseguir de 3 a 5 personas para la prueba de juego.
- 04-11-2026: **Mac confirmado.** El 12-07-2026 Alejandro confirmó que tiene acceso a uno. La pregunta 22 queda reducida a si el iPhone entra al lanzamiento (sigue pendiente).
- 04-11-2026: **reglas decididas** (aceptó las recomendaciones de la auditoría; ver [ADR-0012](../../docs/adr/0012-reglas-decididas-antes-de-la-prueba-de-juego.md)):
  - **Pregunta 5:** con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
  - **Pregunta 9:** al fallar en Resolver se muestra solo cuántas casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
  - **Pregunta 10:** la partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y se revisa antes de la etapa 5. Reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03 (SUPERADO 04-11-2026).
  - **Pregunta 11:** el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1; enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
  - **Pregunta 20:** al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". Hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto.

## Historial

Todo lo anterior (entradas de sesión, decisiones y hallazgos desde el 10-06-2026, estado del motor y comandos útiles) está en [historial.md](historial.md).

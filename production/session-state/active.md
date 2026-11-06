# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito. Se mantiene corto a propósito: el historial completo está en [historial.md](historial.md).

## Estado hoy (05-11-2026, noche)

- **Versión actual: `0.7.0+7`**, con el APK en `Proyecto Enigmatrix/APKs/enigmatrix-0.7.0+7-arm64.apk`, compilado con `ENX_DEV=true`. Sobre la 0.6.0+6 trae lo que se decidió con la prueba de juego n.º 1 (ADR-0015):
  - muebles sin ambigüedad (un tipo por familia en cada mapa);
  - habitaciones coherentes;
  - perchero, bañera, nevera y chimenea;
  - el Mundo 1 y los 30 retos regenerados.

  Pruebas: tools 335 y app 627, todas pasan. FPS: 60 estables en el Galaxy A52 de Alejandro (medido con la 0.6.0+6). Detalle en [bitacora-cuentas.md](bitacora-cuentas.md).
- **Prueba de juego n.º 1: HECHA** con la 0.3.0+3. Resultados: la dificultad está bien por ahora (los rangos se mantienen); hubo confusión silla/sillón/sofá y extrañeza con las habitaciones, ya resuelto en la 0.7.0+7 (ADR-0015).
- **Hecho del plan** ([production/planes/2026-11-05-etapas-3-y-4.md](../planes/2026-11-05-etapas-3-y-4.md)): rondas 3.1, 3.2, 4.1, 4.2, 4.3a y 4.3b.
- **Pendiente técnico:**
  - Probar TalkBack real. (FPS medidos el 05-11-2026: 60 fps estables en el Galaxy A52 de Alejandro.)
  - El texto de la partida tiene un tope de 1,3.
  - Experto y Élite necesitan trabajo de motor para la V2 (ver `production/revisiones/2026-11-05-medicion-12x12-16x16.md`).
- **Compilación:** hay que usar `JAVA_HOME=C:/Program Files/Java/jdk-17`. Los APK entregables se copian con nombre y versión a `Proyecto Enigmatrix/APKs/`.
- **Protección:** repositorio privado `https://github.com/Alejjorojjas/Enigmatrix`. Los commits van solo con la autoría de Alejandro. Siguen sin autorizar: sacar el proyecto de OneDrive, versionar `app/pubspec.lock` y cambiar la firma.
- **Decisiones del 05-11-2026:**
  - ADR-0013: dos pieles por código en la V1.
  - ADR-0015: muebles sin ambigüedad y habitaciones coherentes (tras la prueba de juego).
  - ADR-0014: V1 hasta Intermedio, Mundo 1 con 10 casos y 30 días de reto, solo Android, sin arrastrar retratos, el arma como quedó (pregunta 19) y tipografías incluidas.
- **Preguntas abiertas:** 6 (premium), 7 (hora del reto), 8 (víctima), 12 (ayudas y puntos), 16 (edad), 17 (identidad legal), 18 (qué ve la tienda) y 23 (mundos bloqueados; hoy se muestran como "Próximamente"). Antes de publicar también falta decidir el servidor (etapa 5) y los trámites de tienda (etapa 6).
- **Próximos pasos:**
  1. Alejandro prueba la 0.7.0+7 y TalkBack.
  2. Decidir si el Mundo 1 lleva baño (para la bañera) y si se pone un tope a mesas y sillas repetidas por habitación.
  3. Planear las etapas 5 (Firebase) y 6 (tiendas) y responder las preguntas abiertas de publicación.

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

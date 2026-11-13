# Estado de sesión — Enigmatrix

> Archivo de checkpoint. Toda sesión de trabajo lo lee al empezar y lo actualiza al cerrar un hito. Se mantiene corto a propósito: el historial completo está en [historial.md](historial.md).

## Pendientes anotados por Alejandro (11-11-2026)

- **Mapas más lógicos (para revisar después, no es rígido):** a Alejandro no le parece lógica la distribución. Por ejemplo, un "Salón" con varios sofás, cuando debería tener uno solo. Hay que revisar las reglas de muebles por habitación (`tools/lib/src/map_rules.dart`, ADR-0015, hoy máximo 2 del mismo tipo) y los muebles que tiene cada habitación en `tools/data/mundos/mansion.json`, y proponerle opciones antes de regenerar casos.
- **Correcciones de la prueba con amigos** (en curso, rama `fix/tablero-resuelto-victima-y-reglas`):
  - poder mirar el tablero ya resuelto;
  - la víctima siempre con la letra V;
  - aclarar "junto a" cuando hay una alfombra.
- **Datos reales y reto diario para los amigos:** es la etapa 5A.3. Ver el plan en el chat del 11-11-2026 y las condiciones en `production/planes/2026-11-07-etapa-5a-diseno.md`.

## Estado al 10-11-2026 (lo más reciente)

- **Versión 0.8.1+11, "Murdoku Diario"** (`com.murdokudiario.app`).
- **Google Play:** la versión 10007 está en la prueba interna y Alejandro la está probando. La subida automática espera la cuenta de servicio (paso 5 de la guía de Play).
- **App Store:** el workflow de TestFlight está en `main` (PR n.º 1). Alejandro va en el paso 2 de `production/guias/2026-11-09-app-store-github-actions.md`.
- **Reglas:** ramas `feature/`, `fix/`, `release/` y `docs/`, y PR que aprueba Alejandro.
- **Detalle:** en [TRASPASO.md](TRASPASO.md), sección "ESTADO AL 10-11-2026".

## Estado hoy (05-11-2026, noche)

- **Versión actual: `0.8.0+10`** (0.7.2+9 más la conexión al servidor tras `ENX_BACKEND`; antes: (0.7.0+7 más el baño en la Mansión y un máximo de 2 del mismo mueble por habitación), con el APK en `Proyecto Enigmatrix/APKs/enigmatrix-0.7.2+9-arm64.apk`, compilado con `ENX_DEV=true`. Sobre la 0.6.0+6 trae lo que se decidió con la prueba de juego n.º 1 (ADR-0015):
  - muebles sin ambigüedad (un tipo por familia en cada mapa);
  - habitaciones coherentes;
  - perchero, bañera, nevera y chimenea;
  - el Mundo 1 y los 30 retos regenerados.

  Pruebas: tools 342 y app 627, todas pasan. FPS: 60 estables en el Galaxy A52 de Alejandro (medido con la 0.6.0+6). Detalle en [bitacora-cuentas.md](bitacora-cuentas.md).
- **Prueba de juego n.º 1: HECHA** con la 0.3.0+3. Resultados: la dificultad está bien por ahora (los rangos se mantienen); hubo confusión silla/sillón/sofá y extrañeza con las habitaciones, ya resuelto en la 0.7.0+7 (ADR-0015).
- **Hecho del plan** ([production/planes/2026-11-05-etapas-3-y-4.md](../planes/2026-11-05-etapas-3-y-4.md)): rondas 3.1, 3.2, 4.1, 4.2, 4.3a y 4.3b.
- **Etapas 5 y 6 (06-11-2026):** plan en [production/planes/2026-11-06-etapas-5-y-6.md](../planes/2026-11-06-etapas-5-y-6.md). Alejandro ya tiene las cuentas de Google Play y de Apple, publica como persona natural y el reto cambia a la medianoche local. ADR-0016 aceptado (07-11-2026). **5A.1 hecha:** servidor en el emulador (`backend/`, 95 pruebas, auditoría de seguridad sin críticos). **5A.2 hecha (0.8.0+10):** la app se conecta al servidor detrás de la bandera `ENX_BACKEND` (por defecto `none`, igual que antes); app 707 pruebas. Lo siguiente: la 5A.3, que necesita el proyecto real de Firebase de Alejandro. Esperan respuesta de Alejandro: si el iPhone entra al lanzamiento y la fecha de su cuenta de Google Play.
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
  1. Alejandro prueba la 0.7.2+9 y TalkBack.
  2. Planear las etapas 5 (Firebase) y 6 (tiendas) y responder las preguntas abiertas de publicación.

### Preguntas abiertas (sin decidir; ninguna se resuelve en los documentos)

Cada número es el de la [sección 5 de la auditoría](../revisiones/2026-11-04-auditoria-proyecto.md#5-decisiones-que-necesito-de-ti).

- **Después de las pruebas:** 12 (ayudas y puntuación), 13 (si Experto y Élite entran al lanzamiento).
- **Cuando quiera:** 22 (solo si el iPhone entra al lanzamiento) y la sección 4 del plan de las etapas 5 y 6. Las 6, 7, 8, 16, 17, 18 y 23 se decidieron el 06-11-2026 y la 19 el 05-11-2026.
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

## 12-11-2026: servidor real encendido (5A.3), rama `feature/firebase-real`

- **Proyecto de Firebase** `murdoku-diario`, de la cuenta de Alejandro.
  - Plan Blaze: alerta de 5.000 COP; los créditos de prueba vencen el 10-02-2027 y hay recordatorio en el calendario.
  - Firestore en `southamerica-east1`.
  - Registro con correo, Google, Apple y anónimo (invitados).
  - App Check registrado: Play Integrity y App Attest.
  - Huellas SHA-1 y SHA-256 de la firma de Play.
- **Desplegado el 12-11-2026:**
  - 6 funciones (`getDailyChallenge`, `startCase`, `submitSolution`, `setNickname`, `deleteAccount`, `dailyCleanup`);
  - reglas e índice;
  - política de limpieza de imágenes.
  - Comando: `cd backend && firebase deploy --only functions,firestore:rules,firestore:indexes --project murdoku-diario`. Usa Java 21 para las pruebas del emulador (`C:\Program Files\Java\jdk-21.0.10.7-hotspot`).
- **Producto:**
  - los invitados juegan el tutorial y `mansion-01` y `mansion-02`; el resto y el reto exigen registro;
  - el reto exige además el correo verificado;
  - el apodo se pide tras registrarse;
  - el ranking diario usa el tiempo del servidor más 30 s por error;
  - el ciclo de retos empieza el 16-11-2026.
- **Seguridad:**
  - las soluciones salieron de la app; están en `tools/data/casos-servidor/` y las funciones las incluyen al compilar;
  - por defecto `ENX_BACKEND=firebase`;
  - los secretos de GitHub `GOOGLE_SERVICES_JSON_B64` y `GOOGLE_SERVICE_INFO_PLIST_B64` están creados;
  - el App ID de Apple `com.murdokudiario.app` está creado con App Attest y Sign In with Apple.
- **Pruebas:** app 864, tools 356, backend 200.
- **Pendientes:**
  - Enforce de App Check en Firestore y Auth, después de probar en el teléfono;
  - plantillas de correo de Firebase en español;
  - revocar el token de Apple al borrar la cuenta (necesita una clave .p8 de Apple);
  - limpieza de usuarios anónimos (Identity Platform);
  - prueba flaky de 20 envíos en paralelo bajo carga;
  - publicar la política en una URL y agregar el enlace en la app;
  - formularios de datos de Play y de App Store;
  - pasos 1 a 8 de la guía de Apple para TestFlight;
  - mapas más lógicos.

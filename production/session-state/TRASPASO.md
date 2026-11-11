# TRASPASO entre cuentas de Claude Code (actualizado 10-11-2026)

Si eres una sesión de Claude Code que retoma Enigmatrix, lee este archivo completo antes de hacer nada.

## Quién y cómo

- **El usuario** es Alejandro (Diego Alejandro Rojas Corredor). Llámalo Alejandro. No programa: explícale todo en español claro.
- **Idioma**: todo lo que él vea va en español, incluidas las descripciones de los comandos. El código y los nombres técnicos van en inglés.
- **Fechas**: en formato dd-mm-yyyy.
- **Commits**: solo cuando él lo autorice (ya autorizó hacerlos al cerrar cada tarea verificada), con su autoría (Alejjorojjas). **Sin "Co-Authored-By" ni ninguna mención a Claude.** El repositorio es `https://github.com/Alejjorojjas/Enigmatrix` (privado). **Desde el 09-11-2026 no se hace push a main:** ver "OBLIGATORIO: ramas y PR".
- **Llave de firma**: nunca leas, copies ni muestres `app/android/key.properties` ni los `.jks`.
- **Agentes BBVA**: no toques `C:/Users/alejo/.claude/agents/`, que son de su trabajo en BBVA.
- **Forma de trabajo**: la sesión principal es el arquitecto, decide y verifica, y delega en los agentes de `.claude/agents/` con modelos económicos (Sonnet, o Haiku para lo mecánico). Lo que entrega un agente no se acepta sin correr las pruebas uno mismo.
- **Decisiones**: las de producto y de dinero las toma Alejandro. Preséntale opciones con tu recomendación.
- **Gasto**: los créditos de Alejandro se acaban rápido. Sigue al pie de la letra la sección "Orquestación y control de gasto" de `CLAUDE.md` (Sonnet o Haiku para los agentes, máximo 2 a la vez, sin ultracode).
- **Límite de uso**: el plan tiene límite de 5 horas. Usa pocos agentes a la vez. Si un agente se corta, retómalo desde lo que dejó hecho, revisando git status y git diff.

## Dónde está todo

- **Proyecto (abre Claude Code AQUÍ)**: `D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\Enigmatrix version final Claude`
- **Reglas**: `CLAUDE.md`, en la raíz.
- **Estado detallado**: `production/session-state/active.md`.
- **Planes**: `production/planes/` (el vigente es `2026-11-06-etapas-5-y-6.md`; el diseño del servidor, `2026-11-07-etapa-5a-diseno.md`).
- **Decisiones**: `docs/adr/` (0011 plan por etapas, 0012 reglas, 0013 dirección visual, 0014 alcance de la V1).
- **Auditoría e investigación gráfica**: `production/revisiones/`.
- **Índice de documentos**: `docs/README.md`.
- **APK entregables**: `D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\APKs\`. Cada versión se copia ahí con su nombre para que no la pise la siguiente compilación.
- **Compilar Android**: requiere `JAVA_HOME="C:/Program Files/Java/jdk-17"` (el JDK por defecto del PC es 11): `cd app && JAVA_HOME="C:/Program Files/Java/jdk-17" flutter build apk --release --split-per-abi --dart-define=ENX_DEV=true`. Compila en la carpeta principal, no en un worktree: solo allí está la firma. Sin `ENX_DEV=true` no aparecen el banco de pruebas, el feedback ni el medidor de FPS (para la tienda se compila sin la bandera).
- **Pruebas**:
  - motor: `cd tools && dart test` (342 pasan);
  - servidor: `cd backend && npm test` (95 pasan; necesita Java 21 y `npm install` la primera vez);
  - app: `cd app && flutter analyze && flutter test` (707 pasan).

## ESTADO AL 10-11-2026 (lo primero que hay que leer)

**Versión:** 0.8.1+11. La app se llama **"Murdoku Diario"** y el paquete es `com.murdokudiario.app` en Android y en iOS. Se publica en las cuentas de Google Play y de Apple de un amigo de Alejandro (ADR-0017).

**Google Play.** La primera versión, 10007 (0.8.1), está publicada en la **prueba interna**, con la lista de probadores "Equipo Murdoku". Alejandro ya la está probando en su teléfono.
- La subida automática **sigue apagada**: falta el paso 5 de `production/guias/2026-11-09-google-play-github-actions.md`.
  - Crear la cuenta de servicio en Google Cloud y activar la Google Play Android Developer API.
  - Que el amigo (administrador) invite a esa cuenta en Play Console con permiso de pistas de prueba.
  - Crear el secreto `PLAY_SERVICE_ACCOUNT_JSON`.
  - Crear las variables `PLAY_UPLOAD=true`, `PLAY_TRACK=internal` y `PLAY_RELEASE_STATUS=completed`.
- Hallazgos de Play Console:
  - falta la declaración de comerciante en la cuenta del amigo;
  - para producción hace falta una prueba cerrada.

**App Store (TestFlight).** El PR n.º 1 (`claude/ios-app-store`) ya está fusionado en `main`. Trae:
- el workflow `.github/workflows/ios-testflight.yml` (macOS, solo en push a `main` o a mano, apagado hasta `IOS_UPLOAD=true`);
- el identificador iOS `com.murdokudiario.app`, el mínimo en iOS 15 y el `Podfile`;
- la guía `production/guias/2026-11-09-app-store-github-actions.md`, con 8 pasos.

Por dónde va Alejandro con la guía de Apple:
- **Paso 1 (registrar el App ID en developer.apple.com):** le di las instrucciones. No confirmó explícitamente que lo terminó: pregúntale.
- **Paso 2 (crear la app en App Store Connect):** se lo di y está **en curso**. Es la cuenta del amigo y Alejandro tiene las credenciales; las contraseñas y los códigos los escribe él.
- **Pasos 3 a 8:** faltan. Son el certificado con OpenSSL desde PowerShell, el perfil, la llave de API, los 6 secretos más `IOS_UPLOAD`, el primer run a mano y TestFlight en su iPhone.
- **No hace falta Mac.** El amigo creía que sí; se le explicó que el Mac lo pone GitHub y que el certificado se hace con OpenSSL en Windows.
- **El proyecto iOS nunca se ha compilado.** Es probable que el primer run falle: se corrige con la captura que mande Alejandro.

**Lo que quiere Alejandro:** que todo quede enlazado. Cada cambio va en una rama y un PR; cuando él aprueba el PR y llega a `main`, se sube solo a la prueba interna de Android y a TestFlight. Después de los pasos de Apple y de la cuenta de servicio de Play, hay que hacer una prueba completa con un cambio pequeño.

**Riesgos antes de la revisión pública de Apple o de producción en Play:**
- la tienda y el premium simulados (DEMO), pregunta 18;
- falta la URL de la política de privacidad;
- falta el formulario de seguridad o privacidad de datos;
- falta la ficha;
- hay que corregir los docs 15 y 20 por el permiso INTERNET.

**Otros pendientes:**
- pasar las acciones de GitHub a versiones nuevas (setup-java v5, Node 24);
- la 5A.3 (proyecto real de Firebase);
- probar TalkBack.

## OBLIGATORIO: nombres de rama (desde 09-11-2026)

Las ramas **no** se llaman `claude/...`. La convención la eligió Alejandro:
- `feature/…`: algo nuevo o mejor en el juego;
- `fix/…`: corrige un error;
- `release/…`: publicación y tiendas;
- `docs/…`: solo documentos.

Si la app crea el worktree con una rama `claude/...`, crea una rama con el nombre correcto antes del primer commit.

No hay `gh` instalado. Se hace push de la rama y se le pasa a Alejandro el enlace `https://github.com/Alejjorojjas/Enigmatrix/pull/new/<rama>`; él crea el PR, espera el verde y lo fusiona.

## Estado al 05-11-2026 (noche)

- **Versión actual:** 0.7.2+9 (la 0.7.0+7 más un baño en la Mansión y un máximo de 2 del mismo mueble por habitación). Sobre la 0.6.0+6 (textos en `.arb`, valores de juego en configuración y herramientas de desarrollo tras `ENX_DEV`) trae lo que se decidió con la prueba de juego n.º 1:
  - muebles sin ambigüedad y habitaciones coherentes (ADR-0015);
  - objetos nuevos: perchero, bañera, nevera y chimenea;
  - Mundo 1 y los 30 retos regenerados.
- **Prueba de juego n.º 1: hecha.** La dificultad está bien por ahora; los rangos se mantienen.
- **FPS:** 60 estables en el Galaxy A52 de Alejandro.

## Qué sigue, en orden

1. **Que Alejandro pruebe la 0.7.2+9** y TalkBack en su teléfono.
2. **Decisiones de contenido:** ya resueltas (baño y tope de 2 por habitación).
3. **Etapas 5 (Firebase) y 6 (Google Play):** el plan está en `production/planes/2026-11-06-etapas-5-y-6.md`. El 06-11-2026 se decidieron las preguntas 6, 7, 8, 16, 17, 18 y 23. Falta que Alejandro responda la sección 4 del plan (iPhone, orden y fecha de la cuenta de Google Play, puntos y ayudas). La 19 (arma) ya estaba decidida en el ADR-0014. La partida sin conexión se decidió el 07-11-2026: el ADR-0016 quedó aceptado completo ese día. **5A.1 hecha** (servidor en el emulador, `backend/`, 95 pruebas; diseño en `production/planes/2026-11-07-etapa-5a-diseno.md`). **5A.2 hecha** (0.8.0+10): la app se conecta al servidor con `--dart-define=ENX_BACKEND=emulator`. Por defecto (`none`) sigue validando en el teléfono. Lo siguiente es la 5A.3, el corte al proyecto real; sus condiciones están en el diseño.
   - **09-11-2026:** Alejandro priorizó publicar en Google Play con GitHub Actions (ADR-0017). Hay que seguir la guía `production/guias/2026-11-09-google-play-github-actions.md`. Después irán App Store y otras tiendas.
4. **Restos menores:**
   - de H-66: la versión con `package_info_plus`, el vocabulario "Caso Nº"/"Expediente", una pantalla de error con Reintentar y lints más estrictos;
   - quitar el interruptor `tools/test/support/regeneracion_pendiente.dart`.

## OBLIGATORIO: ramas y PR (desde 09-11-2026)

Desde la primera subida a Google Play, **nada va directo a `main`**. Cada push a `main` sube la app a Play por GitHub Actions (ADR-0017).
- El trabajo va en una rama, con un pull request hacia `main`.
- Alejandro revisa y aprueba el PR, y solo entonces se fusiona.
- Los PR corren las pruebas y compilan el AAB, pero no suben nada.
- Nunca hagas `merge`, `--ff-only` ni push a `main` por tu cuenta.

## OBLIGATORIO: la bitácora compartida

Todo lo que hagas lo anotas en `production/session-state/bitacora-cuentas.md`: fecha, qué hiciste, archivos que tocaste, commit y resultado de las pruebas. Así la otra cuenta, al volver, puede revisar y corregir sin conflictos. Al terminar, deja todo con commit y push, y el árbol de trabajo limpio.

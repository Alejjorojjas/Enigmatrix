# TRASPASO entre cuentas de Claude Code (05-11-2026)

Si eres una sesión de Claude Code que retoma Enigmatrix, lee este archivo completo antes de hacer nada.

## Quién y cómo

- **El usuario** es Alejandro (Diego Alejandro Rojas Corredor). Llámalo Alejandro. No programa: explícale todo en español claro.
- **Idioma**: todo lo que él vea va en español, incluidas las descripciones de los comandos. El código y los nombres técnicos van en inglés.
- **Fechas**: en formato dd-mm-yyyy.
- **Commits**: solo cuando él lo autorice (ya autorizó hacerlos al cerrar cada tarea verificada), con su autoría (Alejjorojjas). **Sin "Co-Authored-By" ni ninguna mención a Claude.** Después del commit, haz push a `https://github.com/Alejjorojjas/Enigmatrix`, rama main, que es privado.
- **Llave de firma**: nunca leas, copies ni muestres `app/android/key.properties` ni los `.jks`.
- **Agentes BBVA**: no toques `C:/Users/alejo/.claude/agents/`, que son de su trabajo en BBVA.
- **Forma de trabajo**: la sesión principal es el arquitecto, decide y verifica, y delega en los agentes de `.claude/agents/` con modelos económicos (Sonnet, o Haiku para lo mecánico). Lo que entrega un agente no se acepta sin correr las pruebas uno mismo.
- **Decisiones**: las de producto y de dinero las toma Alejandro. Preséntale opciones con tu recomendación.
- **Límite de uso**: el plan tiene límite de 5 horas. Usa pocos agentes a la vez. Si un agente se corta, retómalo desde lo que dejó hecho, revisando git status y git diff.

## Dónde está todo

- **Proyecto (abre Claude Code AQUÍ)**: `D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\Enigmatrix version final Claude`
- **Reglas**: `CLAUDE.md`, en la raíz.
- **Estado detallado**: `production/session-state/active.md`.
- **Plan técnico**: `production/planes/2026-11-05-etapas-3-y-4.md`.
- **Decisiones**: `docs/adr/` (0011 plan por etapas, 0012 reglas, 0013 dirección visual, 0014 alcance de la V1).
- **Auditoría e investigación gráfica**: `production/revisiones/`.
- **Índice de documentos**: `docs/README.md`.
- **APK entregables**: `D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\APKs\`. Cada versión se copia ahí con su nombre para que no la pise la siguiente compilación.
- **Compilar Android**: requiere `JAVA_HOME="C:/Program Files/Java/jdk-17"` (el JDK por defecto del PC es 11): `cd app && JAVA_HOME="C:/Program Files/Java/jdk-17" flutter build apk --release --split-per-abi --dart-define=ENX_DEV=true`. Compila en la carpeta principal, no en un worktree: solo allí está la firma. Sin `ENX_DEV=true` no aparecen el banco de pruebas, el feedback ni el medidor de FPS (para la tienda se compila sin la bandera).
- **Pruebas**:
  - motor: `cd tools && dart test` (342 pasan);
  - app: `cd app && flutter analyze && flutter test` (627 pasan).

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
3. **Etapas 5 (Firebase) y 6 (Google Play):** el plan está en `production/planes/2026-11-06-etapas-5-y-6.md`. El 06-11-2026 se decidieron las preguntas 6, 7, 8, 16, 17, 18 y 23. Falta que Alejandro responda la sección 4 del plan (partida sin conexión, iPhone, orden, puntos y ayudas). La 19 (arma) ya estaba decidida en el ADR-0014. Después viene el ADR-0016 y la 5A.
4. **Restos menores:**
   - de H-66: la versión con `package_info_plus`, el vocabulario "Caso Nº"/"Expediente", una pantalla de error con Reintentar y lints más estrictos;
   - quitar el interruptor `tools/test/support/regeneracion_pendiente.dart`.

## OBLIGATORIO: la bitácora compartida

Todo lo que hagas lo anotas en `production/session-state/bitacora-cuentas.md`: fecha, qué hiciste, archivos que tocaste, commit y resultado de las pruebas. Así la otra cuenta, al volver, puede revisar y corregir sin conflictos. Al terminar, deja todo con commit y push, y el árbol de trabajo limpio.

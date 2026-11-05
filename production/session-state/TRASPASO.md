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
  - motor: `cd tools && dart test` (279 pasan);
  - app: `cd app && flutter analyze && flutter test` (625 pasan).

## Estado al 05-11-2026 (después de la ronda 4.3b)

- **Versión actual**: 0.6.0+6. Incluye todo lo de la 0.5.0+5:
  - tablero de Flame con dos pieles (Ilustrada y Papel) en modo claro y oscuro;
  - Mundo 1 "La Mansión" con 10 casos y el reto diario de 30 días (DEMO);
  - tipografías incluidas, sin permiso INTERNET;
  - accesibilidad básica.

  Y además:
  - textos en `app/lib/l10n/app_es.arb`;
  - valores de juego en `app/assets/config/game_config.json`;
  - herramientas de desarrollo detrás de `ENX_DEV`.
- **Prueba de juego n.º 1**: la hace Alejandro con la versión **0.3.0+3 congelada** y la guía de `production/prueba-de-juego/guia-prueba-1.md`. No cambies esa versión.

## Qué sigue, en orden

1. **Medir FPS** en el teléfono de Alejandro con la 0.6.0+6 (medidor en el menú de la partida) y probar TalkBack.
2. **Cuando Alejandro traiga los resultados de la prueba de juego**: recalibrar los rangos de dificultad en `tools/lib/src/difficulty_ranges.dart` (son provisionales) y, si hace falta, regenerar casos con `build-plan` y los planes de `tools/data/mundos/`.
3. **Planear las etapas 5 (Firebase) y 6 (Google Play)** con Alejandro. Preguntas abiertas: 6, 7, 8, 12, 16, 17, 18 y 23 (ver la sección 5 de la auditoría en `production/revisiones/2026-11-04-auditoria-proyecto.md`).
4. Restos menores de H-66 sin hacer: versión con `package_info_plus`, vocabulario "Caso Nº"/"Expediente", pantalla de error con Reintentar y lints más estrictos.

## OBLIGATORIO: la bitácora compartida

Todo lo que hagas lo anotas en `production/session-state/bitacora-cuentas.md`: fecha, qué hiciste, archivos que tocaste, commit y resultado de las pruebas. Así la otra cuenta, al volver, puede revisar y corregir sin conflictos. Al terminar, deja todo con commit y push, y el árbol de trabajo limpio.

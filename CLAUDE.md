# Enigmatrix

> **SESIÓN NUEVA U OTRA CUENTA:** antes de hacer nada, lee `production/session-state/TRASPASO.md`. Anota todo lo que hagas en `production/session-state/bitacora-cuentas.md`.

App móvil de puzzles de deducción visual. El jugador resuelve casos de misterio colocando sospechosos sobre un mapa con habitaciones, guiándose por pistas lógicas. Compite por tiempo y puntos en rankings. Android primero, iOS después.

**Referencia jugable**: existe una versión web del juego en https://murdoku.com/play (nombre anterior del producto). El core es el mismo; Enigmatrix es la evolución móvil con campaña, reto diario, vidas, rachas y arma homicida.

## Regla de oro del juego

- Tablero = grilla de celdas; las celdas pertenecen a **áreas** (habitaciones); algunas celdas tienen objetos y **no son ocupables**.
- **Una persona por fila y por columna** (restricción tipo sudoku).
- El jugador ubica a TODOS los personajes, **incluida la víctima**.
- **El asesino es quien queda a solas con la víctima en la misma área.** El sistema lo revela al resolver; el jugador no acusa manualmente.
- Solo se gana con **todo el tablero correcto**. Solución única siempre, deducción pura, nunca adivinanza.
- La especificación formal completa está en `docs/16-spec-puzzle.md`.

## El usuario (contexto de trabajo)

- No es programador. Claude desarrolla todo el código.
- Idioma de trabajo: **español**. Código y nombres técnicos en inglés.
- Explica las decisiones técnicas en lenguaje claro antes de implementarlas.
- Las decisiones de producto/diseño las toma el usuario: presenta opciones con recomendación, no decidas por él en silencio.
- **Dirección visual (ADR-0013, 05-11-2026).** Hay dos pieles que el jugador elige en Configuración: "Ilustrada" (cualidades de `docs/referencias-visuales/`, con diseño propio) y "Papel". Las dos tienen modo claro y oscuro, que sigue al teléfono. La V1 lleva arte hecho por código y el arte de ilustrador o IA se revisa en la V2. Nunca se calcan dibujos, nombres ni pantallas de las referencias de terceros.
- **Alcance de la V1 (ADR-0014).** Solo Android; dificultades Principiante, Casual e Intermedio; Mundo 1 "La Mansión" con 10 casos y 30 días de reto diario.

## Stack (ver ADRs en docs/adr/; estado real al 04-11-2026)

| Capa | Tecnología |
|---|---|
| App móvil | Flutter (Dart) |
| Estado | Riverpod (ADR-0002) |
| Navegación | go_router |
| Tablero | Escena de Flame en `app/lib/src/board/`, con dos pieles (Ilustrada y Papel) en modo claro y oscuro, director de feedback, sonido y vibración (ADR-0013, desde la 0.3.0+3). El arte de la V1 está hecho por código |
| Cache local | shared_preferences (progreso y preferencias; solo cache, nunca fuente de verdad) |
| Backend | Firebase: Auth, Firestore, Cloud Functions, FCM, Remote Config. **En construcción (etapa 5A, desde 07-11-2026):** `backend/` corre solo en el emulador (proyecto `demo-enigmatrix`, Java 21); la app aún no se conecta |
| i18n | intl + archivos .arb (ES por defecto, EN secundario). **Planificado para la etapa 4; hoy los textos están fijos en español** |

## Principios técnicos innegociables

1. **El servidor es la autoridad** para todo lo oficial: solución, puntos, ranking, vidas, racha, reto diario.
2. **El cliente NUNCA recibe la solución del caso** durante la partida. Se valida en Cloud Functions.
3. **Valores de juego en configuración externa**, nunca hardcodeados (balance en `docs/08-balance.md` → Remote Config / archivos de datos).
4. Toda decisión arquitectónica significativa se registra como **ADR** en `docs/adr/`.
5. Todo caso publicado pasa por el **solver**: solución única + deducción pura + dificultad en rango.
6. Tiempo oficial, día del reto y regeneración de vidas se calculan con **hora del servidor**.

### Excepciones vigentes de la Fase 1 (aprobadas; caducan en la etapa 5)

Mientras no exista servidor, estos principios se incumplen a propósito y con conocimiento del usuario. No agregues excepciones nuevas sin acuerdo.
- **Principio 2:** la solución viaja dentro del JSON local del caso y la validación es local. Es un riesgo aceptado, ver doc 18.
- **Principios 1 y 6:** vidas, racha, ranking, tienda, premium y reto diario son **datos simulados (DEMO)**, aprobados el 12-07-2026. Las pantallas de fases futuras existen como simulación: es una excepción explícita a "no implementar features de fases futuras".
- **Principio 3:** quedan valores de juego escritos en el código (hallazgo H-65 de la auditoría). Se sacan a configuración en la etapa 4. No agregues más.

## Los 5 pillars (filtro de toda decisión — detalle en docs/09-pillars.md)

1. **Deducción pura** — nunca se gana adivinando.
2. **Ranking limpio** — nada se compra; premium da comodidad, no ventaja.
3. **Cabe en un trayecto** — sesiones de minutos, entrada y salida limpias.
4. **Justos con el jugador** — nunca castigar por fallos que no controla.
5. **El mapa cuenta la historia** — la deducción es visual; el texto es soporte.

## Fuente de verdad documental

Los documentos en `docs/` mandan. **Primero lee `docs/README.md`**: dice qué documento está vigente, cuál en revisión y cuál superado. Lo marcado como **PENDIENTE DE DECISIÓN** no se resuelve por tu cuenta: es una pregunta abierta al usuario (auditoría del 04-11-2026, sección 5). Orden de lectura recomendado para contexto:

| Doc | Contenido |
|---|---|
| README.md | **Índice y estado de cada documento** |
| production/revisiones/ | Auditoría del proyecto e investigación gráfica (04-11-2026) |
| 16-spec-puzzle.md | **Especificación formal del puzzle y el solver** (leer antes de tocar el core) |
| 17-roadmap.md | Fases de desarrollo y fase actual |
| 01-mvp-v1.md | Alcance del MVP completo |
| 02-flujo.md / 06-pantallas-ui.md | Flujos y las ~50 pantallas |
| 03-reglas-del-juego.md | Reglas de juego e interacción |
| 05-pipeline-puzzles.md | Generación y publicación de contenido |
| 07-arquitectura.md | Arquitectura técnica completa |
| 08-balance.md | Números: puntos, vidas, precios, límites |
| 09 a 15 | Pillars, arte, accesibilidad, audio, narrativa, analítica, legal |
| 18 a 20 | Revisión de seguridad de la Fase 1, guía de pruebas y checklist de tiendas |

Si detectas una contradicción entre docs: no la resuelvas en silencio — repórtala con ambas referencias y propone cuál manda.

## Estructura del repo

```
docs/         Diseño completo (fuente de verdad) + ADRs + mockups
app/          Proyecto Flutter (la app)
backend/      Cloud Functions + reglas Firestore
tools/        Solver, generador de casos, herramientas internas (Dart puro)
production/   Estado de sesión y seguimiento
```

## Orquestación (desde 01-11-2026)

- **La sesión principal es el ARQUITECTO** (Opus, esfuerzo máximo, ultracode): diseña, decide lo técnico reversible, presenta opciones con recomendación al usuario para lo caro o de producto, reparte el trabajo y verifica lo que vuelve. No se configura con `--agent` ni con el setting `agent`.
- **Todo lo delegado corre en modelos económicos**: cada agente declara `model` y `effort` en su frontmatter (Sonnet por defecto, Haiku para lo mecánico). `.claude/settings.json` fija `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` como piso para cualquier agente sin modelo. En workflows, cada `agent()` lleva `model: 'sonnet'` o `'haiku'`. Escalada excepcional: si Sonnet falla dos veces la misma tarea, el arquitecto la retoma o relanza ese agente una vez con `model: opus` y lo informa.
- **Abrir Claude Code en esta carpeta** (`Enigmatrix version final Claude`), nunca en la carpeta padre: los agentes del proyecto solo se cargan subiendo desde la carpeta de trabajo. Las carpetas hermanas (`Enigmatrix`, `Enigmatrix - claude`, `Claude-Code-Game-Studios`) son archivo de solo lectura.
- **Los agentes globales de BBVA están ocultos en este proyecto** (`permissions.deny` en `.claude/settings.json`).
- **Cómo se delega**: un encargo = una tarea, con objetivo, archivos a leer, qué NO tocar, criterios de aceptación y evidencia esperada. Solo en paralelo trabajos que no editen los mismos archivos.
- **Qué NO se delega**: decisiones de producto y de dirección gráfica (del usuario); aceptar ADR o cambiar pillars, balance o semántica de pistas; cerrar hallazgos críticos de seguridad; claves, cuentas de tiendas y compras; commits, publicación y acciones irreversibles; el resumen final al usuario.
- **Verificación antes de dar algo por bueno**: el resumen de un agente es una afirmación, no una prueba. El arquitecto lee el diff, hace correr los comandos (`ejecutor-pruebas`) y compara números, exige captura en cambios visuales y que `qa` (que no implementó) valide el core.

## Agentes (.claude/agents/)

| Agente | Modelo | Cuándo usarlo |
|---|---|---|
| `puzzle-engineer` | Sonnet · high | Motor lógico del puzzle: solver, generador, spec 16 |
| `contenido-puzzles` | Sonnet · medium | Generar y curar casos por mundo, nombres y textos temáticos, calibración |
| `frontend` | Sonnet · high | Flutter: pantallas, tablero, gestos, navegación, i18n |
| `backend` | Sonnet · medium | Firebase: Cloud Functions, Firestore, Auth, rankings. **Activo desde la 5A (07-11-2026)** |
| `qa` | Sonnet · medium | Tests nuevos, verificación independiente, criterios de aceptación |
| `seguridad` | Sonnet · high | Privacidad, tiendas y firma, y auditoría antes de cada build que salga a probadores. Las tareas de servidor (Firestore, compras, anti-trampa) están inactivas hasta la etapa 5 |
| `revisor-docs` | Sonnet · medium | Consistencia de docs, borradores de ADR, mantener active.md y roadmap |
| `ejecutor-pruebas` | Haiku · low | Correr tests, analyze, compilar y greps; devuelve solo números |

Pendientes de crear cuando se decida la nueva dirección gráfica: un agente de arte técnico y animación (game feel) y uno de audio.

## Flujo de trabajo de sesión

- Al iniciar una sesión de trabajo: leer `production/session-state/active.md` para recuperar contexto.
- Al cerrar un hito: actualizar ese archivo (tarea actual, decisiones, archivos tocados, pendientes).
- Etapa actual del proyecto: ver `docs/17-roadmap.md`, que tiene el plan por etapas 0 a 6 aprobado el 04-11-2026. **No implementar features de etapas futuras** sin acuerdo explícito, salvo las excepciones vigentes de la Fase 1 descritas arriba.
- El prototipo `prototipos/tablero-flame/` quedó congelado como referencia; el código del tablero vive en `app/lib/src/board/`. El plan técnico de las etapas 3 y 4 está en `production/planes/2026-11-05-etapas-3-y-4.md`.
- Los APK que se entregan a Alejandro se copian con nombre y versión a `Proyecto Enigmatrix/APKs/`, para que una compilación nueva no los pise. Para compilar Android se usa `JAVA_HOME=C:/Program Files/Java/jdk-17`.
- Tests: el solver y toda lógica de juego llevan tests unitarios deterministas. Sin tests no se cierra una tarea del core.

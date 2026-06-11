# Enigmatrix

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
- Los mockups visuales los está haciendo el usuario aparte (Claude Design); cuando lleguen van en `docs/mockups/`.

## Stack (decidido — ver ADRs en docs/adr/)

| Capa | Tecnología |
|---|---|
| App móvil | Flutter (Dart) |
| Estado | Riverpod (ADR-0002) |
| Navegación | go_router |
| Tablero | CustomPainter + GestureDetector |
| Cache local | Hive o Isar (solo cache, nunca fuente de verdad) |
| Backend | Firebase: Auth, Firestore, Cloud Functions, FCM, Remote Config |
| i18n | intl + archivos .arb (ES por defecto, EN secundario) |

## Principios técnicos innegociables

1. **El servidor es la autoridad** para todo lo oficial: solución, puntos, ranking, vidas, racha, reto diario.
2. **El cliente NUNCA recibe la solución del caso** durante la partida. Se valida en Cloud Functions.
3. **Valores de juego en configuración externa**, nunca hardcodeados (balance en `docs/08-balance.md` → Remote Config / archivos de datos).
4. Toda decisión arquitectónica significativa se registra como **ADR** en `docs/adr/`.
5. Todo caso publicado pasa por el **solver**: solución única + deducción pura + dificultad en rango.
6. Tiempo oficial, día del reto y regeneración de vidas se calculan con **hora del servidor**.

## Los 5 pillars (filtro de toda decisión — detalle en docs/09-pillars.md)

1. **Deducción pura** — nunca se gana adivinando.
2. **Ranking limpio** — nada se compra; premium da comodidad, no ventaja.
3. **Cabe en un trayecto** — sesiones de minutos, entrada y salida limpias.
4. **Justos con el jugador** — nunca castigar por fallos que no controla.
5. **El mapa cuenta la historia** — la deducción es visual; el texto es soporte.

## Fuente de verdad documental

Los documentos en `docs/` mandan. Orden de lectura recomendado para contexto:

| Doc | Contenido |
|---|---|
| 16-spec-puzzle.md | **Especificación formal del puzzle y el solver** (leer antes de tocar el core) |
| 17-roadmap.md | Fases de desarrollo y fase actual |
| 01-mvp-v1.md | Alcance del MVP completo |
| 02-flujo.md / 06-pantallas-ui.md | Flujos y las ~50 pantallas |
| 03-reglas-del-juego.md | Reglas de juego e interacción |
| 05-pipeline-puzzles.md | Generación y publicación de contenido |
| 07-arquitectura.md | Arquitectura técnica completa |
| 08-balance.md | Números: puntos, vidas, precios, límites |
| 09 a 15 | Pillars, arte, accesibilidad, audio, narrativa, analítica, legal |

**Conflicto conocido**: `08-balance.md` dice que en Principiante las ayudas no penalizan; `03-reglas-del-juego.md` dice que siempre penalizan. Manda el 08 (posterior y más específico) — pendiente de confirmación final del usuario.

## Estructura del repo

```
docs/         Diseño completo (fuente de verdad) + ADRs + mockups
app/          Proyecto Flutter (la app)
backend/      Cloud Functions + reglas Firestore
tools/        Solver, generador de casos, herramientas internas (Dart puro)
production/   Estado de sesión y seguimiento
```

## Agentes (.claude/agents/)

| Agente | Cuándo usarlo |
|---|---|
| `arquitecto` | Decisiones técnicas, ADRs, revisión de consistencia con docs y pillars |
| `puzzle-engineer` | Modelo lógico del puzzle, solver, generador, calibración de dificultad |
| `backend` | Cloud Functions, Firestore, Auth, validación oficial, rankings |
| `frontend` | Flutter: UI, tablero, gestos, navegación, i18n |
| `qa` | Tests, evidencia, regresión, validación de criterios de aceptación |
| `seguridad` | Anti-trampa, reglas de Firestore, IAP, datos personales, legal técnico |

## Flujo de trabajo de sesión

- Al iniciar una sesión de trabajo: leer `production/session-state/active.md` para recuperar contexto.
- Al cerrar un hito: actualizar ese archivo (tarea actual, decisiones, archivos tocados, pendientes).
- Fase actual del proyecto: ver `docs/17-roadmap.md`. **No implementar features de fases futuras** sin acuerdo explícito (el alcance del MVP completo es grande; vamos por fases).
- Tests: el solver y toda lógica de juego llevan tests unitarios deterministas. Sin tests no se cierra una tarea del core.

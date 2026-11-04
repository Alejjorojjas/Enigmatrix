# ADR-0007: Pantallas de fases futuras simuladas (DEMO) y monetización simulada

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 12-07-2026
- **Decisores**: Alejandro (usuario), respondiendo preguntas de alcance en la sesión del 12-07-2026.

## Contexto

El roadmap del 10-06-2026 (doc 17) deja el reto diario, el ranking, las vidas, la tienda y el premium para las Fases 2 y 3, y dice "monetización pospuesta a Fase 3" y "no implementar features de fases futuras sin acuerdo explícito". El 12-07-2026 Alejandro quiso ver la app completa para poder juzgarla, antes de tener servidor.

## Decisión

Alejandro decidió, con ese acuerdo explícito:

1. Construir **las pantallas completas primero, con datos locales simulados**, y dejar Firebase para después (ver ADR-0010).
2. **Incluir ya la monetización, pero simulada**: tienda y premium "de mentira", con los precios del doc 08.
3. Resultado: el shell de navegación (`app/lib/src/ui/home_shell.dart`, commit `f6f2d1d`) con Inicio, Mundos, Reto, Ranking y Perfil, más Tienda, Premium y Configuración como hojas modales.

Es una **excepción escrita** a la regla "no adelantar fases". Hoy figura en CLAUDE.md, sección "Excepciones vigentes de la Fase 1".

## Condición de salida

La excepción caduca en la **etapa 5** del plan (ver ADR-0011). Mientras dura:

- Se permite solo la **simulación local**: sin pagos reales, sin validación de servidor y sin ranking real.
- Todo lo simulado debe verse como **DEMO** o estar oculto. Hoy el rótulo es incompleto: tienda, premium, ranking y puntos semanales lo llevan, pero las vidas, la racha y las estadísticas del perfil no, y cuatro ajustes (Sonido, Música, Vibración, Notificaciones) se guardan sin que nada los lea (H-62).
- Al llegar la etapa 5B (ranking, reto diario real, vidas y compras) cada simulación se **reemplaza por la versión real o se elimina**. Quedó la intención de aislar los datos detrás de repositorios, pero hoy están como constantes al inicio de `home_shell.dart` (`mockLives`, `mockStreak`, `mockBots` y otras), lo que obliga a cazar cada una al conectar el servidor.
- No hay que invertir más en estas pantallas hasta tener el sistema visual nuevo (ver ADR-0005 y la etapa 2), porque es muy probable que se rehagan.

## Alternativas consideradas

- **Seguir el orden del roadmap**: terminar la campaña y recién después Firebase, ranking, vidas y tienda. No: Alejandro quería ver el producto completo y juzgar la experiencia.
- **Solo los datos reales ya posibles en local**: vidas y racha locales verdaderas. Se dejó como siguiente bloque ("vidas funcionales locales", "reto diario con estado real local"), no como alternativa descartada.
- **No mostrar monetización hasta la Fase 3**. No: el usuario pidió incluirla simulada.

## Consecuencias

- Se gana una maqueta navegable completa para decidir diseño y flujo.
- Riesgo de dar una **falsa sensación de producto avanzado**, y de que probadores o revisores de tienda tomen el relleno por errores (H-62). Hay que decidir qué se ve en el build que va a las tiendas.
- Las pantallas se escribieron antes de fijar la dirección visual y se tendrán que reescribir si cambia (ver ADR-0005).
- Se rompen en la práctica los principios técnicos 1 y 6 de CLAUDE.md (el servidor como autoridad, hora del servidor) hasta la etapa 5, pero por excepción escrita.

**DECIDIDO 04-11-2026** (auditoría, pregunta 5; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.

(SUPERADO 04-11-2026) Versión anterior, conservada como historial: ~~PENDIENTE DE DECISIÓN (pregunta 5): qué pasa con 0 vidas. Versión A (hoy): no está definido en ningún documento. Versión B (recomendación de la auditoría): no se puede pulsar Resolver ni empezar casos nuevos; la partida queda guardada hasta recuperar una vida o ver un anuncio.~~

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 6): vidas de Premium. Versión A: premium elimina el límite de 5 y da vidas ilimitadas (`docs/01-mvp-v1.md`, `docs/08-balance.md`, sección "Vidas extra"). Versión B: sigue existiendo el tope de 5, con recarga instantánea (`docs/08-balance.md`, sección "Beneficios premium").

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 7): hora en que cambia el reto diario. Versión A: "dentro del día local" (`docs/03-reglas-del-juego.md`). Versión B: hora del servidor (`docs/07-arquitectura.md`, `docs/08-balance.md`). Hoy la pantalla de Reto es una simulación DEMO que elige el caso con la fecha del teléfono y promete "un intento oficial" y "mismo caso para todos".

**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 18): qué se ve en el build que va a revisión de las tiendas. Versión A (hoy): el build incluye tienda, premium, ranking simulado y ajustes sin efecto. Versión B (recomendación de la auditoría): ocultarlos en ese build.

Este ADR no resuelve ninguna de las cuatro.

## Fuentes

- `production/session-state/active.md`, entradas "2026-07-12 — LOGO + SPLASH + TUTORIAL" (decisiones del usuario del 12-07-2026), "2026-07-12 — SHELL DE NAVEGACIÓN" y "PLAN DEL PRÓXIMO BLOQUE".
- Commits `86f5925` (12-07-2026) y `f6f2d1d` (12-07-2026, "Shell de navegacion completo ... (datos quemados)").
- `app/lib/src/ui/home_shell.dart` (constantes simuladas al inicio y etiqueta DEMO).
- `docs/17-roadmap.md` (Fases 2 y 3 y la regla de no adelantar fases) y `CLAUDE.md`, "Excepciones vigentes de la Fase 1".
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-18, H-26, H-27, H-62.

# ADR-0006: Abandono de Claude Design y UI hecha directamente en Flutter

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 11-07-2026
- **Decisores**: Alejandro (usuario).

## Contexto

Al arrancar el proyecto (10-06-2026), CLAUDE.md decía que los mockups visuales los haría Alejandro aparte con Claude Design y llegarían a `docs/mockups/`. El roadmap dejaba la tarea "Design System: UI definitiva cuando lleguen los mockups" abierta, y existe un archivo `docs/Enigmatrix Design System - Standalone.html`. Al 11-07-2026 la app tenía una interfaz provisional (el "banco de pruebas" de la Fase 1) y la bitácora no registra que se hubiera incorporado ningún mockup de Claude Design.

## Decisión

El 11-07-2026 Alejandro decidió **abandonar Claude Design** y hacer la interfaz **directamente en Flutter**, iterando con él sobre la app corriendo (primero con el lenguaje visual de Duolingo adaptado al tema detective, luego con identidad propia y por último Paper Craft, ver ADR-0005). Los mockups en HTML de `docs/mockups/` pasan a ser material de referencia, no una especificación a seguir.

## Alternativas consideradas

- **Seguir esperando los mockups de Claude Design** y construir la interfaz sobre ellos. No: Alejandro prefirió ver y juzgar pantallas reales en su teléfono. El motivo exacto no quedó escrito; esto es lo que se deduce de la bitácora.
- **Usar el Design System standalone** (`docs/Enigmatrix Design System - Standalone.html`) como guía. No hay registro de que se haya usado como fuente para la interfaz.
- **Contratar o comisionar un artista desde el principio**. No hay registro de que se haya considerado en ese momento; cómo se produce el arte final sigue abierto (ver Consecuencias).

## Consecuencias

- Se avanzó rápido y Alejandro pudo reaccionar a pantallas reales, con cinco cambios de estilo en un mes (11-06-2026 a 12-07-2026).
- Quedaron referencias viejas: CLAUDE.md (ya corregido en la etapa 0), el agente `frontend`, el documento 10 y el roadmap siguen hablando de mockups y de Design System (H-14, H-19, H-23, H-37). Se corrigen en otras tareas de la etapa 0.
- Conviven dos sistemas de colores y estilos; la pantalla de partida sigue en el viejo (H-59).
- Nadie quedó como responsable de la calidad visual y de la experiencia, que es justo lo que más preocupa a Alejandro.
- **Decisiones que siguen abiertas y pedirán su propio ADR** cuando se resuelvan: (1) de dónde sale el arte final (comisión a un artista, IA curada, kit de piezas); (2) qué herramientas gráficas se usan (Flame, Rive u otras, según la prueba de concepto de la etapa 2). Este ADR no las decide.

## Fuentes

- `production/session-state/active.md`, entrada "2026-07-11 — PASE DUO" (11-07-2026): "el usuario decidió abandonar Claude Design y hacer la UI directo en Flutter".
- Commit `9095290` (11-07-2026, "Pase Duo: camino de nodos y pantalla de victoria estilo Duolingo").
- `CLAUDE.md` (versión original del 10-06-2026 y versión actual, sección "El usuario").
- `docs/17-roadmap.md`, Fase 1 ("Design System: ... cuando lleguen los mockups").
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-14, H-17, H-19, H-23, H-37, H-59.

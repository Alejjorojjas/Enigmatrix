# ADR-0005: Estilo visual Paper Craft (papel recortado)

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente. **Vigente pero en revisión**: se reevaluará en la etapa 2 del plan (ver ADR-0011).
- **Fecha**: 12-07-2026
- **Decisores**: Alejandro (usuario), eligiendo entre 6 mockups; implementó el arquitecto.

## Contexto

Entre el 11-06-2026 y el 12-07-2026 la app cambió de estilo visual cinco veces: dorado oscuro inicial, "pase Duo" (11-07-2026, descartado por parecerse demasiado a Duolingo), "pase Enx" con cinco ambientes de color, muebles ilustrados estilo caricatura y, por último, Paper Craft. El 12-07-2026 Alejandro dijo que el estilo cartoon plano no le convencía y pidió "gráficos complejos, modernos, de última tecnología" con al menos 6 mockups. Se hicieron 6 mockups en `docs/mockups/estilos/` (Luxe Royal, Painterly Deco, Diorama isométrico, Neón Noir, Paper Craft, Toon Premium) con la misma pantalla de partida, y Alejandro eligió el número 5.

## Decisión

Aplicar **Paper Craft** a toda la app: tema claro kraft y tinta, una sola paleta ("Papel"), tablero con marco de corcho y hoja de papel, pisos pastel, paredes en tinta, X marcadora color carmesí, muebles con sombra dura de recorte y tipografía manuscrita Patrick Hand. Quedó implementado en el commit `561c11e`.

## Alternativas consideradas

- **Luxe Royal** (brillante, tipo Royal Match), **Painterly Deco** (pintura de los años 20, tipo June's Journey), **Diorama isométrico** (tipo Monument Valley), **Neón Noir** y **Toon Premium** (contorno grueso). Eran las otras cinco opciones de los mockups. El motivo exacto de la elección no quedó escrito; la bitácora solo dice que Alejandro eligió el estilo 5.
- **Mantener el estilo Enx de medianoche con cinco ambientes**. Se reemplazó al elegir Paper Craft: el selector de ambientes se eliminó y la infraestructura quedó con un solo preset.

## Consecuencias

- La app tiene una identidad visual coherente en el menú, el camino y la victoria. La pantalla de partida todavía conserva el sistema de estilos viejo (dos sistemas conviven, H-59).
- **El estilo se hizo con código, no con arte real**: el papel es una paleta de colores y no una textura ni un comportamiento (informe de investigación gráfica, sección 2). Alejandro sigue sintiendo que "no parece un juego".
- El informe gráfico del 04-11-2026 recomienda mantener el estilo papel pero redefinido como maqueta de papel recortado y fotografiado, y deja abierta la pregunta 3 de su sección 10 ("¿mantienes el estilo papel?"). La etapa 2 (prueba de concepto gráfica) evalúa si la ejecución con Flame y Rive alcanza ese nivel. Hasta entonces no hay que invertir en arte definitivo ni dar este estilo por congelado.
- El documento 10 (arte) todavía describe "cartoon limpio", paleta por mundo y otras tipografías: no refleja Paper Craft. Se marca como parcialmente superado en otra tarea de la etapa 0 (H-37).
- **Autorizado el 04-11-2026:** Alejandro autorizó la prueba de concepto gráfica (etapa 2) con estas condiciones: la prueba muestra **ambas** opciones (papel recortado tipo maqueta e ilustración 2D sin papel) para compararlas; el arte es provisional y gratuito (CC0, por código o con texturas de papel fotografiadas por Alejandro) y el arte de pago se decide después; la meta es "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match. Las referencias visuales están pendientes: Alejandro pidió ver ejemplos antes de elegir. Esto responde a la pregunta 3 del informe gráfico solo en parte: el estilo sigue sin decidirse hasta que se vea la comparación.
- Si la prueba de concepto lo cambia, este ADR se reemplaza por uno nuevo.

## Fuentes

- `production/session-state/active.md`, entradas "2026-07-12 — PAPER CRAFT + ANDROID/iOS" y "2026-07-12 — 6 MOCKUPS DE ESTILO VISUAL" (12-07-2026), y "2026-07-11 — PASE DUO" y "PASE ENX v2" (11-07-2026).
- Commits `561c11e` (12-07-2026, "Paper Craft en toda la app + plataformas Android/iOS...") y `02d1e26` (12-07-2026, "6 mockups de estilos visuales").
- `docs/mockups/estilos/` (los 6 mockups) y `CLAUDE.md`, sección "El usuario" (dirección visual en revisión desde el 01-11-2026).
- `production/revisiones/2026-11-04-investigacion-grafica.md`: secciones 2, 5.1 y 10.
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-23, H-37, H-59.

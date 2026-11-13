# Revisión de diseño: resto de docs/ (vigencia contra el código)

- **Fecha:** 11-11-2026
- **Skill:** `/design-review` (modo `solo`, rigor `minimal`, sin agentes especialistas)
- **Código revisado:** la copia `Enigmatrix-revision-ccgs` (versión 0.8.1+11, más nueva que esta rama).
- **Alcance:** solo revisión. No se modificó ningún archivo del proyecto. Este informe no tiene commit.
- **Complementa a:** `2026-11-11-design-review-03-y-16.md` (revisión detallada de los docs 03 y 16).

## Cómo se revisó

Esta es una revisión de **vigencia**, no de calidad de diseño sección por sección:

- El índice `docs/README.md` es el que dice qué documento manda. Se contrastaron sus columnas "Estado" y "Última verificación", y las cifras de "hoy" de cada documento, con lo que hay en el código hoy (`app/pubspec.yaml`, `app/lib`, `app/assets`, `backend/`, `tools/`).
- Se contaron los marcadores de cada documento (PENDIENTE DE DECISIÓN, NO IMPLEMENTADO, SUPERADO) y se cruzaron con las decisiones ya tomadas en los ADR 0012 a 0017 y en el CLAUDE.md.
- Los cuerpos de los docs 04, 09, 12 y 14 no se leyeron completos.

## Veredicto global: NEEDS REVISION

El diseño en sí no tiene problemas graves nuevos. El problema es de **vigencia**: entre el 04-11 y el 11-11 el proyecto avanzó varias etapas (servidor 5A, dos pieles, sonido, i18n, 62 casos, la subida a Play y el iPhone), pero el índice y el roadmap siguen describiendo el estado del 04-11. Quien abra los documentos hoy recibe una foto de hace una semana como si fuera "estado verificado".

## Hallazgos que bloquean el uso de los docs como fuente de verdad

### 1. `docs/17-roadmap.md`: el "Estado verificado al 04-11-2026" quedó muy atrás

| Lo que dice el roadmap (líneas 9 a 34) | Lo que hay hoy |
|---|---|
| "Etapa actual del plan: la etapa 0" | La app está en la prueba interna de Google Play, el servidor va en la etapa 5A y el iPhone por TestFlight (CLAUDE.md, `active.md`) |
| Tests del motor: 54; de la app: 26 | Según Alejandro: 342 del motor, 715 de la app y 95 del servidor (no los ejecuté) |
| Casos en la app: 20 (8, 7 y 5) | 62 archivos en `app/assets/cases`: 11 de Principiante, 23 de Casual, 26 de Intermedio y 1 tutorial |
| Tablero: cuadrícula de widgets con `CustomPainter` | Escena de Flame (`flame: ^1.37.0` en `pubspec.yaml`, `app/lib/src/board/scene/`) |
| Audio, vibración, traducciones y lectores de pantalla: no existen | Hay 13 sonidos en `app/assets/sonidos`, textos en `app/lib/l10n/app_es.arb` (308 claves) y `Semantics(` en 11 archivos |
| Servidor: no existe (`backend/` vacío) | `backend/` tiene funciones, reglas de Firestore y pruebas Vitest; la app depende de `firebase_core`, `firebase_auth` y `cloud_functions` |
| Último commit `84835be`, sin repositorio remoto | Hay remoto privado en GitHub, PR n.º 1 fusionado y workflows de Play y TestFlight (ADR-0017) |

**Propuesta:** agregar arriba un bloque "Estado verificado al 11-11-2026" con las cifras nuevas y dejar el del 04-11 como historial, igual que se hizo con el plan original.

### 2. `docs/README.md`: estados que ya no son ciertos

| Documento | Lo que dice el índice | Realidad | Propuesta |
|---|---|---|---|
| 07 Arquitectura | "`backend/` está vacío" | Backend en el emulador (5A) | Pasarlo a EN REVISIÓN y remitir a los ADR 0016 y 0017 |
| 10 Arte | EN REVISIÓN, "se reescribirá cuando Alejandro decida" | Alejandro decidió el 05-11 (ADR-0013: dos pieles, Ilustrada y Papel, hechas por código) y ya existen en `app/lib/src/board/scene/illustrated_skin.dart` | Reescribir el 10 desde el ADR-0013 o marcarlo SUPERADO por él |
| ADR-0005 Paper Craft | EN REVISIÓN | Lo reemplaza el ADR-0013 | Marcarlo SUPERADO por el ADR-0013 |
| 12 Audio | "hoy la app no tiene audio ni vibración" | Tiene sonido y vibración desde la 0.3.0 (CLAUDE.md) y 13 archivos de sonido | Pasarlo a PARCIALMENTE OBSOLETO |
| 14 Analítica | "no hay Firebase ni analítica en `pubspec.yaml`" | Firebase ya está, sin analítica | Corregir la frase |
| 11 Accesibilidad | "el prototipo casi no los cumple; arreglo en la etapa 4" | Hay `Semantics` en 11 archivos; sin medir | Volver a verificar (lo cubre el informe de UX) |
| 16 Spec | "preguntas 12 y 13 siguen marcadas" | La 13 está decidida por el ADR-0014 | Ver el punto 3 |
| 18, 19 y 20 | Última verificación: 04-11 o 06-11 | Los tres cambiaron después (la copia de revisión tiene versiones del 11-11) | Actualizar la fecha de verificación |

### 3. Pendientes que ya se decidieron pero siguen abiertos en los docs

| Pregunta | Dónde sigue como PENDIENTE | Dónde se decidió |
|---|---|---|
| 13: Experto y Élite en el lanzamiento | 01 (línea 99), 08 (línea 16), 16 §1.1 | ADR-0014 y CLAUDE.md: la V1 lleva solo Principiante, Casual e Intermedio |
| 14: contenido del lanzamiento | 01 (línea 101) | ADR-0014: Mundo 1 "La Mansión" con 10 casos y 30 días de reto |
| 22: iPhone en la V1 | 01 (línea 46) | Alejandro, 09-11-2026: iPhone por TestFlight (CLAUDE.md) |
| 8: víctima | 03 (línea 41) | Decidida el 06-11 (roadmap, línea 200): ficha con † |

Son cambios de texto. No hace falta ninguna decisión nueva, solo propagar las que ya se tomaron.

## Pendientes que siguen siendo de Alejandro (no se resuelven aquí)

1. **Pregunta 12, ayudas y puntuación** (docs 01, 02, 03, 06 y 08). La app no tiene ayudas ni puntos. Para la V1 de tienda hay que decir si salen sin ayudas, y si la pantalla de victoria muestra puntos o solo tiempo y errores.
2. **Pregunta 19, uso del arma.** El contenido ya la usa en Intermedio (12 casos). Falta confirmarlo.
3. **Cierre del ranking semanal con fechas locales** (doc 08). Sigue sin definirse, y la etapa 5B lo necesita.
4. **Perder el intento oficial al borrar datos o cerrar sesión** (doc 03). Choca con el pilar 3 y estaba previsto para "antes de la etapa 5", que ya empezó.

## Revisiones recomendadas (no bloquean)

- **Doc 05, pipeline** (EN REVISIÓN desde el 04-11, con 5 NO IMPLEMENTADO). Con 62 casos publicados y `build-plan` en uso, conviene una pasada que diga qué se implementó en la etapa 3: la puerta de contenido y el tope de tiempo, sí; el detector de redundancia, no.
- **Doc 06, pantallas** (unas 50). Ver el informe de UX de esta misma fecha para lo que se ve en la versión de tienda.
- **Doc 09, pilares.** Siguen vigentes. Dos riesgos de pilar quedan abiertos: el pilar 1, porque la dificultad no está garantizada por pasos (H-40), y el pilar 3, por el intento oficial que se pierde.
- **`Enigmatrix Design System - Standalone.html`.** Está marcado SUPERADO pero sigue dentro de `docs/`. Se podría mover a un archivo histórico; es opcional.

## Escala estimada de la corrección

**S a M.** Es solo texto, en unos 8 documentos más el índice. No hace falta ningún ADR nuevo. Lo puede hacer el agente `revisor-docs` con una lista cerrada (esta), y debe verificarlo el arquitecto.

## Lo que no se pudo verificar

- Las cifras de pruebas: no se ejecutaron.
- Lo que se ve en la versión de tienda frente a la versión de desarrollo (`ENX_DEV`): no se abrió la app.
- El contenido completo de los docs 04, 09, 12 y 14, y de los ADR (solo se usaron sus títulos y el índice).

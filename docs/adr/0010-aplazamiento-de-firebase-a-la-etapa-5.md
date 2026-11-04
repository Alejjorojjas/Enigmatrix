# ADR-0010: Aplazamiento de Firebase: la Fase 1 corre sin servidor y el servidor llega en la etapa 5

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 12-07-2026 (se confirma "pantallas primero, Firebase después") y 04-11-2026 (el plan por etapas fija el servidor en la etapa 5)
- **Decisores**: Alejandro (usuario), con el arquitecto.

## Contexto

El ADR-0001 eligió Firebase como backend (Auth, Firestore, Cloud Functions, Remote Config y demás). El roadmap del 10-06-2026 ya situaba a Firebase en la Fase 2 ("Entra Firebase"), no en la Fase 1. El 12-07-2026 Alejandro pidió construir primero las pantallas completas con datos locales simulados (ver ADR-0007) y dejar el servidor para después. Hoy la carpeta `backend/` está vacía, `app/pubspec.yaml` no tiene ninguna dependencia de Firebase y los datos simulados viven en constantes de `app/lib/src/ui/home_shell.dart`, marcadas en un comentario como "se reemplazan por Firebase en Fase 2". El 04-11-2026 la auditoría propuso, y Alejandro aprobó, mover el servidor al final del plan, después de las pruebas de juego y de la prueba de concepto gráfica (ver ADR-0011).

## Decisión

**Firebase no se integra hasta la etapa 5 del plan por etapas.** Mientras tanto:

1. La app funciona sin cuentas, sin red y sin servidor, con los casos empaquetados como archivos.
2. El estado oficial (puntos, vidas, racha, ranking, reto diario) se simula en local y se rotula DEMO (ADR-0007).
3. La solución viaja en el archivo del caso y Resolver valida en el teléfono, como riesgo aceptado con fecha de caducidad (ADR-0008).
4. **La elección de Firebase como backend del ADR-0001 sigue vigente**; lo que cambia es el momento, no la herramienta. Lo que sí queda abierto es cómo se valida en el servidor (ver Consecuencias).

La etapa 5 se divide en dos: **5A** (cuentas, validación de la solución en el servidor y casos sin la solución dentro) y **5B** (ranking, reto diario real, vidas y compras).

## Alternativas consideradas

- **Montar Firebase desde la Fase 1** y validar en el servidor desde el principio. No: obliga a construir cuentas y servidor antes de saber si el juego es divertido y justo (la etapa 1 del plan lo mide), y antes de fijar la dirección visual.
- **Otro backend** (Supabase o servidor propio con Postgres, que ya contemplaba el ADR-0001). No se reabre ahora; el ADR-0001 deja prevista la migración si los rankings en Firestore resultan incómodos.
- **Hacer el servidor en la etapa 2 o 3** (antes del arte definitivo). No: el servidor no desbloquea ninguna de las dos incógnitas grandes del proyecto, que son si el juego engancha y si el arte alcanza el nivel buscado.

## Consecuencias

- Se evita invertir en infraestructura antes de validar el juego.
- Todo lo "online" que Alejandro ve hoy es simulación. Hay riesgo de falsa sensación de producto avanzado (ver ADR-0007, H-62).
- Los datos simulados están como constantes sueltas en un archivo (`mockLives`, `mockStreak`, `mockWeeklyPoints`, `mockBots`), no detrás de repositorios, así que conectar el servidor obliga a localizarlas una por una.
- **Decisión técnica pendiente para la etapa 5 (H-41)**: el servidor debe reutilizar el validador de la app, que está en Dart. La documentación de Firebase indicaba, en una fuente externa aún no confirmada, que Dart en Cloud Functions es experimental. Opciones que sugiere la auditoría: (A) Cloud Run con un contenedor Dart, que reutiliza el validador y el modelo y mantiene una sola fuente de verdad; (B) reescribir el validador en TypeScript, con el riesgo de que cliente y servidor se desvíen; (C) usar Dart experimental solo para prototipar. **Hay que escribir un ADR propio sobre esto antes de empezar la etapa 5.** Este ADR no lo decide.
- El documento 07 (arquitectura) quedó desfasado respecto de la realidad (pide Hive o Isar, y describe una app "online de extremo a extremo"); tiene un banner desde el 04-11-2026; se reescribe en la etapa 5 (H-41).
- Cuando llegue Firebase habrá que actualizar el manifiesto de privacidad de iPhone y revisar el inicio de sesión con Apple si se ofrece Google en iOS (anexo de la auditoría).
- El agente `backend` queda inactivo hasta la etapa 5.

## Fuentes

- `docs/17-roadmap.md`, Fase 2 ("Entra Firebase", con banner de actualización del 04-11-2026) y etapa 5 del plan.
- `docs/adr/0001-stack-flutter-firebase.md` y `docs/07-arquitectura.md`, sección "Recomendacion principal para V1: Firebase".
- `production/session-state/active.md`, decisión del 12-07-2026 ("pantallas completas primero con datos locales simulados, Firebase después") y del 04-11-2026 (plan por etapas).
- `app/pubspec.yaml` (sin Firebase), `backend/` (vacío) y `app/lib/src/ui/home_shell.dart` (comentarios y constantes simuladas).
- `CLAUDE.md`, tabla de stack ("Planificado para la etapa 5; hoy no existe backend").
- `production/revisiones/2026-11-04-auditoria-proyecto.md`, sección 4 (etapa 5) y sección 6.
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-17, H-18, H-41.

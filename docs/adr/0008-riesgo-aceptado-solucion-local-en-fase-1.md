# ADR-0008: Riesgo aceptado en la Fase 1: la solución del caso viaja en el archivo local

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito una decisión ya tomada; falta que se acepte formalmente.
- **Fecha**: 10-06-2026 (aceptado en el roadmap, doc 17, Fase 1) y 12-07-2026 (documentado como riesgo en el doc 18)
- **Decisores**: Alejandro (usuario) y el arquitecto.

## Contexto

CLAUDE.md fija como principio innegociable que el cliente nunca recibe la solución del caso y que el servidor valida. Pero la Fase 1 es una app local sin cuentas ni servidor: para que el botón Resolver funcione, la app necesita saber la solución. Los casos son archivos en `app/assets/cases/` y cada uno trae la solución.

## Decisión

**En la Fase 1, la solución viaja dentro del JSON local del caso y Resolver valida en el teléfono.** Se acepta el riesgo porque el banco de pruebas no es competitivo: no hay ranking, ni puntos oficiales, ni racha real. Cualquiera que abra el APK puede leer la solución, y eso no daña a nadie hoy.

## Condición de caducidad

La excepción **caduca en la Fase 2 del roadmap, que en el plan por etapas del 04-11-2026 es la etapa 5, subetapa 5A** (cuentas, validación de la solución en el servidor y casos sin la solución dentro; ver ADR-0011). La regla de `docs/18-revision-seguridad-fase1.md` para esa fase es innegociable:

- el cliente nunca recibe la solución;
- valida el servidor;
- los puntos, las vidas y la racha solo se actualizan después de que el servidor valide.

Antes de la etapa 5 **no puede haber ranking, puntos oficiales ni compras reales** que dependan de una partida validada en el teléfono.

## Alternativas consideradas

- **Servidor desde la Fase 1** (validar en Cloud Functions desde el principio). No: obliga a montar Firebase antes de saber si el juego es divertido (ver ADR-0010).
- **Ofuscar el código** (`--obfuscate`). No por ahora: el doc 18 dice que hoy no aporta, porque la solución local ya es un riesgo aceptado. Se retoma cuando el binario contenga lógica sensible.

## Consecuencias

- Se pueden jugar y probar casos sin servidor.
- **No son aceptables en la Fase 1**: leaderboards, medallas oficiales o cualquier dato que alguien pueda falsear con el APK abierto.
- El resaltado exacto de las casillas incorrectas al pulsar Resolver solo es posible porque la solución está en el cliente. Cuando valide el servidor, esa información dejará de estar disponible a menos que el servidor la devuelva (H-60). (Nota 04-11-2026: por la regla 9 del ADR-0012, fuera del tutorial ya no se muestra qué casillas fallan, solo cuántas.)
- La validación en el servidor necesita su propia decisión técnica: reusar el validador en Dart (por ejemplo con Cloud Run) o reescribirlo en TypeScript. **Hay que escribir ese ADR antes de empezar la etapa 5** (H-41).
- Hay que reflejar el riesgo y su caducidad en CLAUDE.md (ya incluido en "Excepciones vigentes de la Fase 1") y en el roadmap.

**DECIDIDO 04-11-2026** (auditoría, pregunta 9; ver ADR-0012): al fallar en Resolver se muestra solo cuántas casillas no cuadran; el resaltado exacto y el parpadeo de la pista quedan solo para el tutorial. En la etapa 5 el servidor solo tendrá que devolver ese conteo.

(SUPERADO 04-11-2026) Versión anterior, conservada como historial: ~~PENDIENTE DE DECISIÓN (pregunta 9): cómo se muestran los errores al resolver. Versión A (hoy): al fallar se marcan exactamente las casillas erróneas, con 3 segundos de bloqueo. Versión B (recomendación de la auditoría): mostrar solo cuántas casillas no cuadran y dejar el resaltado exacto solo en el tutorial. La decisión condiciona lo que tendrá que devolver el servidor en la etapa 5. Este ADR no la resuelve.~~

## Fuentes

- `docs/18-revision-seguridad-fase1.md`, apartado "Riesgo aceptado" (12-07-2026).
- `docs/17-roadmap.md`, Fase 1 ("throwaway aceptado", del 10-06-2026) y Fase 2.
- `CLAUDE.md`, principios 1 y 2 y "Excepciones vigentes de la Fase 1".
- `production/session-state/active.md`, entrada "2026-07-12 — PAPER CRAFT + ANDROID/iOS" (riesgo aceptado Fase 1 = solución en JSON local).
- Commit `561c11e` (12-07-2026).
- `production/revisiones/2026-11-04-auditoria-proyecto.md`, secciones 2, 4 y 5 (pregunta 9).
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-14, H-41, H-60.

# ADR-0011: Plan por etapas 0 a 6, aprobado el 04-11-2026

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026. Aprobado por Alejandro en chat el mismo día; falta solo la aceptación formal de este registro.
- **Fecha**: 04-11-2026
- **Decisores**: Alejandro (usuario), a propuesta del arquitecto a partir de la auditoría del proyecto.

## Contexto

El roadmap original (`docs/17-roadmap.md`, 10-06-2026) ordenaba el trabajo en fases: Fase 1 banco de pruebas, Fase 2 servidor (Firebase), Fase 3 monetización y Fase 4 arte. Desde el 01-11-2026 el proyecto está en una fase de reestructuración sin tocar código. La auditoría del 04-11-2026 encontró que ese orden ya no sirve:

- la queja principal de Alejandro es el arte, que el roadmap dejaba para el final (H-23);
- no hay registro de que se haya medido si el juego engancha (H-22);
- lo que el roadmap llama "MVP publicable" no incluye los trámites de las tiendas (H-24);
- el trabajo de la Fase 1 se extendió con pantallas simuladas y cinco cambios de estilo (ver ADR-0005, ADR-0006 y ADR-0007).

## Decisión

Alejandro aprobó el 04-11-2026 este **orden de etapas**:

| Etapa | Qué incluye | Termina cuando |
|---|---|---|
| 0. Orden y protección | Proteger el trabajo, documentos al día y decisiones de reglas del primer grupo | El proyecto está en GitHub, los documentos dicen la verdad o están marcados "en revisión" |
| 1. ¿Es divertido y justo? | Versión de prueba con arreglos mínimos; prueba de juego con 10 casos propios y 3 a 5 personas externas con Android | Se cumplen los umbrales fijados antes de empezar (por ejemplo, 3 de 4 terminan el tercer caso Principiante sin ayuda y 3 de 4 lo volverían a jugar) |
| 2. Prueba de concepto gráfica | La del informe gráfico, aislada del juego actual y con una copia fija del generador | Se cumplen los 7 criterios de la sección 9 del informe gráfico; si falla, plan alterno de ese informe |
| 3. Motor y contenido | Arreglar el generador y controlar la dificultad, puerta automática de contenido, catálogo con id único, prueba de generación en 12×12 y 16×16, Mundo 1 con 10 casos y 30 días de reto diario | `qa` verifica el Mundo 1 completo |
| 4. Producción visual | Solo si pasan la prueba de juego y la prueba de concepto: estilo en todas las pantallas, game feel, sonido, vibración, guardado completo, accesibilidad y textos listos para traducir | El Mundo 1 con el estilo definitivo pasa la lista de verificación fijada al cerrar la etapa 2 |
| 5. Servidor (Firebase) | 5A: cuentas, validación en servidor y casos sin la solución; 5B: ranking, reto diario real, vidas y compras. Antes, un ADR sobre cómo validar en el servidor (H-41) | La validación en el servidor funciona |
| 6. Tiendas | Trámites legales, prueba cerrada en Google Play, iPhone solo si se decide | Publicación |

Reglas de encaje, también aprobadas:

- Las etapas 1, 2 y 3 pueden avanzar en paralelo si la prueba de juego usa una versión congelada de la app (con los 20 casos actuales) y la prueba de concepto usa una copia fija del generador. Alejandro es el cuello de botella, así que conviene escalonar el arranque.
- **Ninguna inversión grande en arte arranca antes de los resultados de la prueba de juego** y de la prueba de concepto.
- Las excepciones de la Fase 1 (solución local, datos simulados DEMO, sin servidor) **caducan en la etapa 5** (ADR-0007, ADR-0008, ADR-0010).
- Estimaciones de tiempo y costo de la auditoría: sin verificar (la etapa 2, de 1 a 2 semanas y de 50 a 200 USD en herramientas; la etapa 4, de 12 a 16 semanas y de 2.000 a 8.500 USD por mundo con la opción A del informe gráfico).

### Qué autorizó Alejandro el 04-11-2026 (decidido, no pendiente)

- **El plan por etapas**, tal como está arriba.
- **Protección del trabajo**: autorizó **solo** el repositorio privado en GitHub, que **aún no está creado**. **No** autorizó todavía hacer el commit del trabajo del 01-11-2026, sacar el proyecto de OneDrive ni cambiar la configuración de firma.
- **Poner los documentos al día** sin tocar el código (esta tarea de la etapa 0).
- **La prueba de concepto gráfica (etapa 2)**, con estas condiciones:
  - meta visual: "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match;
  - estilo: la prueba debe mostrar **ambas** opciones, papel como maqueta e ilustración 2D sin papel, para compararlas (ver ADR-0005);
  - el arte provisional de la prueba es gratuito (CC0 o hecho por código); el arte de pago se decide después;
  - las referencias visuales **siguen pendientes**: Alejandro pidió ver ejemplos antes de fijarlas.
- **Mac**: el 12-07-2026 Alejandro confirmó que tiene acceso a un Mac. La pregunta 22 de la auditoría queda reducida a si el iPhone entra al lanzamiento.

## Alternativas consideradas

- **Mantener el roadmap original por fases** (servidor, luego monetización, luego arte). No: deja la mayor preocupación de Alejandro, el arte, para el final, y sigue sin medir si el juego engancha.
- **Empezar ya por el arte con inversión grande** (ilustrador o animador). No: sin la prueba de juego y la prueba de concepto se arriesga a pagar arte para un juego o una técnica que no funcionan.
- **Hacer el servidor antes de las pruebas**. No: ver ADR-0010.

## Consecuencias

- El roadmap (`docs/17-roadmap.md`) lleva banners de actualización que remiten a este plan; las fases viejas se conservan como historial.
- **Siguen pendientes de decisión de Alejandro** (preguntas de la sección 5 de la auditoría). No las resuelve este ADR:
  - ~~antes de la prueba de juego, porque cambian lo que se mide: 5 (qué pasa con 0 vidas), 9 (cómo se muestran los errores al resolver), 10 (salir de la partida y reloj), 11 (tutorial), 20 (gesto de confirmar) y 21 (personas para la prueba);~~ (SUPERADO 04-11-2026: las reglas 5, 9, 10, 11 y 20 quedaron decididas en el ADR-0012, y la 21 se resolvió: Alejandro consigue de 3 a 5 personas);
  - después de las pruebas: 12 (ayudas y puntuación) y 13 (si Experto y Élite entran al lanzamiento);
  - cuando quiera: 6 (vidas de premium), 7 (hora del reto diario), 8 (representación de la víctima), 14 (contenido de lanzamiento), 15 (inglés y formato de las pistas; debe resolverse antes de la etapa 3), 16 (edad mínima), 17 (identidad legal), 18 (qué se ve en el build de tiendas), 19 (uso del arma) y 22 (si el iPhone entra al lanzamiento; el acceso a un Mac está confirmado desde el 12-07-2026);
  - nueva: 23 (si se muestran los mundos bloqueados).
- Quedan además sin decidir: la protección completa (commit, ubicación fuera de OneDrive, firma), las referencias visuales y quién paga los planes de herramientas de pago. (Nota 04-11-2026: para la prueba de concepto se decidió arte provisional gratuito; el arte de pago se decide después.)
- Si la prueba de juego falla, se corrige primero el juego (reglas y dificultad). Si falla la prueba de concepto, se aplica el plan alterno del informe gráfico. En ambos casos este plan se revisa y, si cambia el orden, se reemplaza por un ADR nuevo.
- El plan deja abiertas dos decisiones que pedirán su propio ADR: de dónde sale el arte final y qué herramientas gráficas se usan (ADR-0006), más el ADR de validación en el servidor (ADR-0010).

## Fuentes

- `production/revisiones/2026-11-04-auditoria-proyecto.md`, secciones 3, 4 (plan por etapas, aprobado el 04-11-2026) y 5 (decisiones pendientes).
- `production/revisiones/2026-11-04-investigacion-grafica.md`, secciones 9 y 10 (criterios de la prueba de concepto y preguntas).
- `docs/17-roadmap.md` (fases originales del 10-06-2026 y banners de actualización del 04-11-2026).
- `production/session-state/active.md`, decisión del 04-11-2026 (plan por etapas 0 a 6 aprobado).
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-22, H-23, H-24, H-41.
- Respuestas de Alejandro en el chat del 04-11-2026 (autorizaciones y condiciones de la prueba de concepto) y confirmación del 12-07-2026 sobre el acceso a un Mac.

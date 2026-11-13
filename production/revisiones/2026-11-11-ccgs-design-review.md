# Revisión de diseño de docs/ con Claude Code Game Studios (CCGS)

- **Fecha:** 11-11-2026
- **Herramienta:** skill `/design-review` de CCGS v1.3.0 (modo `solo`, rigor `minimal`, automatización `collaborative`, sin agentes especialistas)
- **Código revisado:** la copia `Enigmatrix-revision-ccgs` (rama `docs/revision-ccgs`, versión 0.8.1+11, "Murdoku Diario"). Es más nueva que la rama de esta sesión (`25bcadb`): trae los commits de la versión de tienda sin pantallas simuladas, la política de privacidad y el control de gasto. Las rutas citadas valen para las dos copias, pero los números de línea son los de la copia de revisión.
- **Alcance:** solo revisión. No se modificó ningún documento, código ni configuración del proyecto. Este informe no tiene commit.
- **Revisión previa con CCGS:** no hay. Esta es la primera.
- **Informes del mismo día:**
  - `2026-11-11-design-review-03-y-16.md`: detalle de los docs 03 y 16.
  - `2026-11-11-design-review-resto-de-docs.md`: detalle del resto.
  - `2026-11-11-ux-review-app.md`: revisión de UX.
  - `2026-11-11-checklist-lanzamiento-play-y-app-store.md`: lista de lanzamiento.

  Este informe reúne los dos primeros en un solo documento.

---

## 1. Resumen

| Documento o grupo | Veredicto | Motivo principal |
|---|---|---|
| 03 Reglas del juego | **NEEDS REVISION** | Varias frases de "hoy la app…" describen como pendiente lo que ya está hecho |
| 16 Spec del puzzle | **NEEDS REVISION** (leve) | El modelo lógico es sólido; fallan datos de estado que ya cambiaron |
| 17 Roadmap y README (índice) | **NEEDS REVISION** | Describen el estado del 04-11-2026 como si fuera el actual |
| 01, 05, 06, 07, 08, 10, 11, 12, 14, 20 | **NEEDS REVISION** (texto) | Pendientes ya decididos que siguen abiertos y estados de "hoy" desfasados |
| 09 Pilares | Sin cambios | Siguen vigentes. Dos riesgos de pilar abiertos (ver 5.3) |

**Veredicto global: NEEDS REVISION.**

El diseño del juego no tiene problemas graves nuevos. El problema es de **vigencia**: entre el 04-11 y el 11-11 el proyecto avanzó varias etapas (servidor 5A, dos pieles, sonido, i18n, 62 casos, la subida a Play y el iPhone), pero la documentación sigue describiendo el estado de hace una semana. Quien use `docs/` como fuente de verdad hoy recibe información equivocada sobre qué existe y qué falta.

**Escala de la corrección: S a M.** Es solo texto, en unos 10 documentos más el índice, y no hace falta ningún ADR nuevo. Lo puede hacer el agente `revisor-docs` con este informe como lista cerrada, y debe verificarlo el arquitecto.

---

## 2. Cómo se revisó

- Se leyeron completos los docs 03, 11, 16 y 20, y el índice `docs/README.md`. Del resto se leyeron los marcadores (PENDIENTE DE DECISIÓN, NO IMPLEMENTADO, SUPERADO) y las secciones de estado.
- Cada afirmación de "hoy la app hace / no hace" se contrastó con el código: `app/lib`, `app/pubspec.yaml`, `app/assets`, `tools/lib` y `backend/`.
- En rigor `minimal` CCGS no exige las 8 secciones de un GDD de plantilla (Overview, Player Fantasy, Formulas, etc.). Su ausencia **no** es un hallazgo: los documentos del proyecto usan su propia estructura en español, que es válida.
- El registro de entidades de CCGS (`design/registry/entities.yaml`) no tiene datos de este juego, así que los valores se cruzaron con el código y con los ADR de `docs/adr/`.
- No se leyeron completos los cuerpos de los docs 04, 09, 12 y 14 ni de los ADR (solo sus títulos y el índice).

---

## 3. Documento 03: reglas del juego

### 3.1 Necesario antes de usarlo como fuente de verdad

Son frases que contradicen el código de hoy.

1. **Aviso "Elige primero a un sospechoso" y modo de tocar dos veces** (línea 218). El documento dice: "Hasta que se implemente, la app de hoy sigue sin dar respuesta." Ya existe: `boardPickSuspectFirst` en `app/lib/l10n/app_es.arb`, `PlacementProblem.noSuspect` en `src/board/feedback/feedback_director.dart` y `doubleTapConfirm = true` en `app/lib/src/game/board_interaction.dart`.
2. **Las pistas sí se guardan al salir** (línea 355). El documento dice: "hoy el estado de las pistas no se guarda al salir". Se guardan: `clueMarks` en `app/lib/src/game/saved_game.dart`, restauradas en `game_controller.dart`.
3. **El error ya se muestra como conteo** (línea 305). El documento dice: "hoy el resaltado es exacto". La app ya muestra cuántas casillas no cuadran (`boardWrongCells`) y deja el resaltado exacto solo para el tutorial (`tutorialCoachStep14`).
4. **Uso del arma** (línea 52, PENDIENTE DE DECISIÓN H-52). El documento dice: "nunca por encima de Casual". De los 14 casos con arma en `app/assets/cases`, **12 son Intermedio** y 2 son Casual. El contenido ya respondió la pregunta: falta que Alejandro lo confirme y cerrar el pendiente.
5. **Aviso del prototipo** (línea 9). Señala `home_shell.dart` como el lugar de los datos simulados. Hoy están en `mock_data.dart`, `v1_scope.dart`, `home_tabs.dart` y `home_sheets.dart`, y la copia más nueva tiene una "versión de tienda sin pantallas simuladas". Hay que decir qué queda DEMO en la versión que va a la tienda.
6. **Sección "Conexión"** (líneas 541 a 551). Dice "Todo el juego es online" y bloquea el tablero sin red. El ADR-0016 (aceptado, 07-11-2026) dice que la partida se juega sin conexión y que Resolver espera a que vuelva la señal. **Es una contradicción.** Propuesta: manda el ADR-0016, que es posterior y está aceptado.

### 3.2 Revisiones recomendadas

7. **Reto diario DEMO** (línea 455). "Elige el caso por la fecha del teléfono (cualquier dificultad)". Hoy existe el ciclo de 30 días en `tools/data/mundos/mansion-reto.json` y `v1_scope.dart`. La descripción quedó vieja.
8. **Víctima** (línea 41). Sigue como PENDIENTE DE DECISIÓN (H-35), pero se decidió el 06-11-2026 (roadmap, línea 200): ficha normal con †, sin cuerpo ni sangre. Hay que cerrarla aquí.
9. **Perder el intento oficial al borrar la caché o cerrar sesión** (línea 537). Choca con el pilar 3 y estaba marcado para revisar "antes de la etapa 5". **La etapa 5A ya empezó**, así que la pregunta es urgente. Con el ADR-0016 probablemente desaparece el problema, pero hay que decirlo de forma explícita.
10. **Estructura.** El documento mezcla lo vigente, la visión de la Fase 2 y lo superado, con unos 13 bloques intercalados. Propuesta: separarlo en "Reglas vigentes (V1)", "Visión Fase 2+" e "Historial", como ya hace el doc 16.

### 3.3 Nice-to-have

11. La papelera (línea 271) admite "X pequeñas / X grandes", pero el doc 16 decidió "X grandes" (ver el hallazgo 14). Hay que unificar.
12. La lista de armas por mundo (líneas 121 a 152) no se contrastó con `tools/data/mundos/mansion.json`.

---

## 4. Documento 16: especificación del puzzle

### 4.1 Necesario antes de usarlo como fuente de verdad

13. **Tope de tiempo del solver** (§6.2, línea 242). Está marcado **NO IMPLEMENTADO (H-42)**, pero ya existe: `GenerationLimits.maxCaseTime` en `tools/lib/src/generator.dart`, el corte en `case_factory.dart` y `limits.maxTime` en `uniqueness.dart`. Hay que cerrar esa parte del H-42.
14. **X parcial y X fuerte** (§4, línea 168). Contradice la decisión del 11-06 de la línea 287 ("X grandes"). Hay que dejar una sola versión, la que haga el código hoy.
15. **Aviso y toque doble** (§4, línea 167). Dice "hoy la app aún no lo tiene", y ya lo tiene (ver el hallazgo 1).
16. **Conteo de casos** (§1.1, línea 21, y §3.1, línea 144). Dice "8 Principiante, 7 Casual, 5 Intermedio" y "los 20 casos". Hoy hay 62 archivos: 11 de Principiante, 23 de Casual, 26 de Intermedio y 1 tutorial.

### 4.2 Revisiones recomendadas

17. **Detector de redundancia** (§6.1). Sigue sin implementarse: buscar "redundan" en `tools/` no encuentra nada. Si no entra en la V1, hay que marcarlo "diferido".
18. **Filtro de dificultad por pasos (H-40)** (§6.2, §6.3 y §6.5). `_stronger` sigue en `generator.dart`, y la tabla de calibración por dificultad sigue "no definida" con 62 casos publicados. No verifiqué si el aplanamiento se corrigió en la etapa 3. Si no se corrigió, es un riesgo para el pilar 1.
19. **Excepción de la Fase 1** (§5.2). La solución viaja en el JSON local (60 de los 62 archivos tienen `solution`) y la excepción "caduca en la etapa 5". Hay que decir su estado ahora que la 5A está en curso y el ADR-0016 está aceptado.
20. **Criterio de aceptación sin número** (§6.2). "Pasos dentro del rango de la etiqueta" no se puede probar sin la tabla de §6.5. Propuesta medible: "Principiante: pasos entre A y B y `maxTier` ≤ 2; …", con los valores sacados de las pruebas de juego.

### 4.3 Nice-to-have

21. Pregunta abierta 2 de §7 (áreas siempre contiguas). Se puede cerrar con una regla en `map_rules.dart`.
22. **Lo mejor del conjunto:** §2 (restricciones globales), §3.1 (semántica formal de las 16 pistas, verificada contra `clue.dart`) y §1.3.1 (coherencia del mapa). Son precisos y se pueden programar sin adivinar.

---

## 5. Resto de docs/

### 5.1 `docs/17-roadmap.md`: el "Estado verificado al 04-11-2026" quedó muy atrás

| Lo que dice (líneas 9 a 34) | Lo que hay hoy |
|---|---|
| "Etapa actual: la etapa 0" | Prueba interna de Google Play publicada, servidor en la 5A e iPhone por TestFlight |
| Tests del motor: 54; de la app: 26 | 342 del motor, 715 de la app y 95 del servidor (según Alejandro; no se ejecutaron en esta revisión) |
| 20 casos (8, 7 y 5) | 62 archivos en `app/assets/cases` |
| Tablero de widgets con `CustomPainter` | Escena de Flame (`flame: ^1.37.0`, `app/lib/src/board/scene/`) |
| Sin audio, vibración, traducciones ni lector de pantalla | 13 sonidos, 308 claves en `app_es.arb` y `Semantics` en 11 archivos |
| `backend/` vacío | Funciones, reglas de Firestore y pruebas Vitest; la app depende de `firebase_core`, `firebase_auth` y `cloud_functions` |
| Sin remoto; último commit `84835be` | Remoto privado en GitHub, PR n.º 1 fusionado y workflows de Play y TestFlight (ADR-0017) |

**Propuesta:** agregar arriba un bloque "Estado verificado al 11-11-2026" y dejar el del 04-11 como historial.

### 5.2 `docs/README.md`: estados que ya no son ciertos

| Documento | Dice el índice | Realidad | Propuesta |
|---|---|---|---|
| 07 Arquitectura | "`backend/` está vacío" | Backend en el emulador (5A) | EN REVISIÓN, remitir a los ADR 0016 y 0017 |
| 10 Arte | EN REVISIÓN, "se reescribirá cuando Alejandro decida" | Decidido el 05-11 (ADR-0013, dos pieles) e implementado (`illustrated_skin.dart`) | Reescribir desde el ADR-0013 o marcarlo SUPERADO |
| ADR-0005 Paper Craft | EN REVISIÓN | Reemplazado por el ADR-0013 | SUPERADO por el ADR-0013 |
| 11 Accesibilidad | "el prototipo casi no los cumple" | Casi todo hecho (ver el informe de UX) | Reescribir el bloque "Estado real hoy" |
| 12 Audio | "hoy la app no tiene audio ni vibración" | Los tiene desde la 0.3.0 | PARCIALMENTE OBSOLETO |
| 14 Analítica | "no hay Firebase en `pubspec.yaml`" | Firebase ya está, sin analítica | Corregir la frase |
| 16 Spec | "preguntas 12 y 13 siguen marcadas" | La 13 la decidió el ADR-0014 | Ver 5.3 |
| 20 Tiendas | "hoy no se puede subir nada", `com.enigmatrix.app`, "iOS nunca se compiló" | Prueba interna publicada, `com.murdokudiario.app` y workflow de TestFlight | Actualizar (ver la lista de lanzamiento) |
| 18, 19 y 20 | Verificados el 04-11 o el 06-11 | Cambiaron el 11-11 | Actualizar la fecha |

### 5.3 Pendientes ya decididos que siguen abiertos en los docs

| Pregunta | Sigue como PENDIENTE en | Se decidió en |
|---|---|---|
| 8: víctima | 03 (línea 41) | 06-11-2026 (roadmap, línea 200): ficha con † |
| 13: Experto y Élite | 01 (línea 99), 08 (línea 16) y 16 §1.1 | ADR-0014: la V1 lleva solo Principiante, Casual e Intermedio |
| 14: contenido del lanzamiento | 01 (línea 101) | ADR-0014: Mundo 1 con 10 casos y 30 días de reto |
| 22: iPhone en la V1 | 01 (línea 46) y 20 (línea 57) | 09-11-2026: iPhone por TestFlight (CLAUDE.md) |

Solo hay que propagar decisiones ya tomadas. No hace falta decidir nada nuevo.

### 5.4 Otros

- **Doc 05, pipeline.** Lleva EN REVISIÓN desde el 04-11, con 5 NO IMPLEMENTADO. Falta decir qué entró en la etapa 3: la puerta de contenido y el tope de tiempo sí; el detector de redundancia no.
- **Doc 06, pantallas.** Describe unas 50 pantallas de la visión completa. Para la tienda conviene una lista corta de lo que ve el jugador en la 0.8.x (ver el informe de UX).
- **Doc 09, pilares.** Siguen vigentes. Hay dos riesgos abiertos: el pilar 1 (la dificultad no está garantizada por pasos, H-40) y el pilar 3 (el intento oficial se pierde al borrar datos).
- **`Enigmatrix Design System - Standalone.html`.** Está SUPERADO pero sigue en `docs/`. Se puede mover a un archivo histórico; es opcional.

---

## 6. Contradicciones entre documentos (para que decida Alejandro)

| Tema | Fuente A | Fuente B | Propuesta |
|---|---|---|---|
| Jugar sin conexión | Doc 03, "Conexión": todo online; sin red se bloquea | ADR-0016: partida sin conexión | Manda el ADR-0016 |
| Tamaños de X | Doc 16 §4 y doc 03: X parcial y X fuerte | Doc 16 §7 (11-06): X grandes | Lo que haga el código; unificar |
| Arma por dificultad | Doc 03, línea 52, y doc 01, línea 120: nunca por encima de Casual | Contenido: 12 casos Intermedio con arma | Confirmar y cerrar el H-52 |
| Estado del proyecto | Roadmap e índice: etapa 0, sin servidor | CLAUDE.md, `active.md` y `TRASPASO.md`: Play, 5A, TestFlight | Mandan `active.md` y `TRASPASO.md`; actualizar el roadmap |

---

## 7. Pendientes que siguen siendo de Alejandro

1. **Pregunta 12, ayudas y puntuación** (docs 01, 02, 03, 06 y 08). La app no tiene ninguna de las dos. Hay que decir si la V1 de tienda sale sin ayudas y qué muestra la pantalla de victoria.
2. **Pregunta 19, uso del arma.** El contenido ya la usa en Intermedio. Falta confirmarlo.
3. **Cierre del ranking semanal con fechas locales** (doc 08). La etapa 5B lo necesita.
4. **Intento oficial perdido al borrar datos o cerrar sesión** (doc 03). Choca con el pilar 3, y la etapa 5 ya empezó.

---

## 8. Lo que no se pudo verificar

- Las cifras de pruebas: no se ejecutaron.
- El comportamiento en pantalla y lo que se ve en la versión de tienda: no se abrió la app.
- Si el H-40 (dificultad plana) se corrigió en la etapa 3.
- El contenido de los ADR línea por línea: solo se usaron sus títulos y el índice.
- Los cuerpos completos de los docs 04, 09, 12 y 14.

## 9. Siguiente paso sugerido

Encargar a `revisor-docs` (Sonnet) la corrección de texto de las secciones 3 a 5, con este informe como lista cerrada y sin tocar código. Después, que el arquitecto lea el diff. Las decisiones de las secciones 6 y 7 son de Alejandro, y conviene tomarlas antes de esa corrección para no hacerla dos veces.

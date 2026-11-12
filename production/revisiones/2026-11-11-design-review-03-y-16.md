# Revisión de diseño: docs/03-reglas-del-juego.md y docs/16-spec-puzzle.md

- **Fecha:** 11-11-2026
- **Skill:** `/design-review` (modo `solo`, rigor `minimal`, sin agentes especialistas)
- **Código revisado:** la copia `Enigmatrix-revision-ccgs` (rama `docs/revision-ccgs`, versión 0.8.1+11). Es más nueva que esta rama (`25bcadb`): incluye los commits de la versión de tienda sin pantallas simuladas, la política de privacidad y el control de gasto. Las rutas de archivo citadas valen para las dos copias, pero los números de línea son los de la copia de revisión.
- **Alcance:** solo revisión. No se modificó ningún documento, código ni configuración del proyecto. Este informe no tiene commit.
- **Revisión previa:** no hay (primera revisión con esta skill).

## Cómo se revisó

Se leyeron los dos documentos completos y cada afirmación de "hoy la app hace / no hace" se contrastó con el código (`app/lib`, `tools/lib`, `app/assets/cases`). En rigor `minimal` no se exigen las 8 secciones de un GDD de plantilla (Overview, Player Fantasy, etc.): su ausencia **no** es un hallazgo. Los dos documentos usan su propia estructura en español, que es válida para este proyecto.

No existe `design/registry/entities.yaml` con entradas para este juego, así que los valores se cruzaron con el código y con los ADR de `docs/adr/`, no con un registro.

## Veredicto

| Documento | Veredicto | Motivo principal |
|---|---|---|
| 03 Reglas del juego | **NEEDS REVISION** | Varias frases de "hoy la app…" quedaron viejas: describen como pendiente lo que ya está hecho. Un programador que lo lea como fuente de verdad se equivoca. |
| 16 Spec del puzzle | **NEEDS REVISION** (leve) | El modelo lógico es sólido y preciso. Lo que falla son datos de estado (conteo de casos, tope de tiempo) que ya cambiaron. |

**Escala estimada de la corrección:** S (solo texto; no hace falta ningún ADR nuevo). La decide quien planifique.

---

## Documento 03: reglas del juego

### Necesario antes de usarlo como fuente de verdad

Son frases que contradicen el código de hoy.

1. **Aviso "Elige primero a un sospechoso" y modo de tocar dos veces** (línea 218). El documento dice: "Hasta que se implemente, la app de hoy sigue sin dar respuesta." El código ya lo tiene: el texto `boardPickSuspectFirst` en `app/lib/l10n/app_es.arb` y `doubleTapConfirm = true` en `app/lib/src/game/board_interaction.dart`.
2. **Las pistas sí se guardan al salir** (línea 355). El documento dice: "hoy el estado de las pistas no se guarda al salir". El código las guarda: `clueMarks` en `app/lib/src/game/saved_game.dart`, restauradas en `game_controller.dart`.
3. **El error ya se muestra como conteo** (línea 305). El documento dice: "hoy el resaltado es exacto". La app ya muestra cuántas casillas no cuadran (`boardWrongCells` en `app_es.arb`) y deja el resaltado exacto solo para el tutorial (`tutorialCoachStep14`). La decisión del 04-11 ya está aplicada.
4. **Uso del arma** (línea 52, PENDIENTE DE DECISIÓN H-52). El documento dice: "el arma aparece… nunca por encima de Casual". Hoy, de los 14 casos con arma en `app/assets/cases`, **12 son Intermedio** y 2 son Casual. La pregunta parece respondida por el contenido. Alejandro debe confirmarlo y cerrar el pendiente.
5. **Aviso del prototipo** (línea 9). Señala `home_shell.dart` como el lugar de los datos simulados. Hoy están repartidos en `mock_data.dart`, `v1_scope.dart`, `home_tabs.dart` y `home_sheets.dart`. Además, la copia más nueva habla de una "versión de tienda sin pantallas simuladas". Hay que decir qué pantallas DEMO quedan en la versión que va a la tienda.
6. **Sección "Conexión"** (líneas 541 a 551). Dice "Todo el juego es online" y "el prototipo funciona sin conexión; servidor en la etapa 5". Hoy existen el ADR-0016 ("validación en servidor y partida sin conexión"), un backend en el emulador y la bandera `ENX_BACKEND` en `app/lib/src/backend/backend_config.dart`. **Hay una posible contradicción entre el doc 03 y el ADR-0016:** el doc 03 bloquea el tablero sin conexión y el ADR-0016 permite jugar sin conexión. Propuesta: manda el ADR-0016 (es posterior y está aceptado) y el doc 03 debe remitir a él.

### Revisiones recomendadas

7. **Reto diario DEMO** (línea 455). Dice que hoy el reto elige el caso "por la fecha del teléfono (cualquier dificultad)". Hoy existe `tools/data/mundos/mansion-reto.json` con los 30 días del alcance de la V1 (ADR-0014). La descripción del modo DEMO probablemente quedó vieja. No lo verifiqué en la pantalla.
8. **Víctima** (línea 41, PENDIENTE DE DECISIÓN H-35). Sigue abierta en el doc. Si el ADR-0012 o el ADR-0013 ya la cerraron (ficha con †), hay que cerrarla aquí. Si no, sigue siendo una pregunta para Alejandro.
9. **Perder el intento oficial al borrar la caché o cerrar sesión** (línea 537). El propio documento reconoce que choca con el pilar 3, y está marcado para revisarse "antes de la etapa 5". **Ya estamos en la etapa 5A**, así que esta pregunta pasó a ser urgente. Con el ADR-0016 (partida en el servidor) probablemente desaparece el problema. Conviene decidirlo explícitamente.
10. **Estructura.** El documento mezcla tres capas: lo vigente, la visión de la Fase 2 y lo superado. Tiene 13 bloques SUPERADO, DECIDIDO o PENDIENTE intercalados. Leído de corrido, un lector no distingue la regla actual. Recomendación: separar en "Reglas vigentes (V1)", "Visión Fase 2+" e "Historial", como ya hace el doc 16.

### Nice-to-have

11. La papelera (línea 271) admite "X pequeñas / X grandes", pero el doc 16 decidió el 11-06 "X grandes" (ver el hallazgo 14). Hay que unificar el vocabulario de la X.
12. La lista de armas por mundo (líneas 121 a 152) no se contrastó con `tools/data/mundos/mansion.json`. Conviene una verificación automática.

---

## Documento 16: especificación del puzzle

### Necesario antes de usarlo como fuente de verdad

13. **Tope de tiempo del solver** (§6.2, línea 242). Está marcado **NO IMPLEMENTADO (H-42)**: "no hay Stopwatch, límite de tiempo ni tope de nodos". **Ya está implementado:** `GenerationLimits.maxCaseTime` en `tools/lib/src/generator.dart`, el corte por tiempo en `case_factory.dart` y `limits.maxTime` en `uniqueness.dart`. Hay que actualizar el texto y cerrar esa parte del H-42.
14. **X parcial y X fuerte** (§4, línea 168). Sigue listando dos tamaños de X, pero la decisión del 11-06 (línea 287) es "X grandes". Es una contradicción interna, y el doc 03 arrastra la misma. Hay que confirmar en el código qué existe hoy y dejar una sola versión.
15. **Aviso y toque doble** (§4, línea 167). Dice: "hoy la app aún no lo tiene". Ya lo tiene (ver el hallazgo 1).
16. **Conteo de casos** (§1.1, línea 21). Dice: "hoy hay 8 de Principiante, 7 de Casual y 5 de Intermedio". Hoy `app/assets/cases` tiene 62 archivos: 11 de Principiante, 23 de Casual, 26 de Intermedio y 1 tutorial. Las frases de §3.1 (línea 144) sobre "los 20 casos" también quedaron viejas.

### Revisiones recomendadas

17. **Detector de redundancia** (§6.1, línea 235). Sigue sin implementarse: buscar "redundan" en `tools/lib` y `tools/bin` no encuentra nada. Si no entra en la V1, hay que marcarlo "diferido", como el propio documento propone.
18. **Filtro de dificultad por pasos (H-40)** (§6.2 y §6.3). `_stronger` sigue en `generator.dart`. No verifiqué si el aplanamiento de dificultad se corrigió en la etapa 3. Si se corrigió, hay que cerrarlo aquí. Si no, la tabla de calibración de §6.5 sigue "no definida" con 62 casos ya publicados, y es un riesgo para el pilar 1, porque la etiqueta de dificultad no se garantiza.
19. **Excepción de la Fase 1** (§5.2). Dice que la solución viaja en el JSON local y "caduca en la etapa 5". Con la etapa 5A en curso y el ADR-0016, hay que decir cuál es el estado: la versión de tienda 0.8.1, ¿sigue llevando la solución dentro del APK?
20. **Criterio de aceptación sin número.** "Pasos de deducción dentro del rango de la etiqueta" (§6.2) no se puede probar mientras la tabla de §6.5 no tenga números. Propuesta de redacción medible: "Principiante: pasos entre A y B y `maxTier` ≤ 2; Casual: …". Los valores salen de los datos de las pruebas de juego.

### Nice-to-have

21. La pregunta abierta 2 de §7 (áreas siempre contiguas, "validar en Fase 4") se puede cerrar con una regla en `map_rules.dart`, si es que no existe ya.
22. Lo que está bien hecho: §2 (restricciones globales), §3.1 (semántica formal de las 16 pistas, verificada contra `clue.dart`) y §1.3.1 (coherencia del mapa) son precisos y se pueden programar sin adivinar. Son lo mejor del conjunto.

---

## Contradicciones entre documentos (para que decida Alejandro)

| Tema | Fuente A | Fuente B | Propuesta |
|---|---|---|---|
| Jugar sin conexión | Doc 03, "Conexión": todo online; sin red se bloquea el tablero | ADR-0016: partida sin conexión | Manda el ADR-0016 |
| Tamaños de X | Doc 16 §4 y doc 03: X parcial y X fuerte | Doc 16 §7 (11-06): X grandes | Lo que haga el código hoy; unificar |
| Arma por dificultad | Doc 03, línea 52: nunca por encima de Casual | Contenido: 12 casos Intermedio con arma | Confirmar el contenido y cerrar el H-52 |

## Lo que no se pudo verificar

- El comportamiento en pantalla (no se abrió la app).
- Si el H-40 (dificultad plana) se corrigió en la etapa 3.
- El contenido de los ADR 0012 a 0016 línea por línea: solo se usaron sus títulos.
- El número total de pruebas: no se ejecutaron. Según Alejandro son 715 de la app, 342 del motor y 95 del servidor.

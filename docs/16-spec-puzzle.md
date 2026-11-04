# Enigmatrix - Especificación formal del puzzle

> ACTUALIZACIÓN 04-11-2026 (auditoría H-33, H-39, H-40, H-42, H-43): este documento se puso al día contra el código de `tools/` (comprobado leyendo `generator.dart`, `clue.dart`, `deduction.dart`, `case_factory.dart`, `puzzle_case.dart` y un caso real de `app/assets/cases`). Lo vigente está en el cuerpo. Lo superado quedó marcado **SUPERADO** en su sitio y reunido en la sección final "Historial de decisiones superadas". Lo que la spec prometía y el código no hace está marcado **NO IMPLEMENTADO**. Lo que depende de Alejandro está marcado **PENDIENTE DE DECISIÓN**.

## Objetivo de este documento

Definir SIN ambigüedad el modelo lógico del puzzle: qué es un tablero, qué es un caso, qué significa cada pista, cómo se valida una solución y cómo funciona el solver. Este es el documento que `puzzle-engineer` implementa primero (Fase 0 del roadmap).

Fuentes: versión web jugable (murdoku.com, reglas verificadas contra su código) + docs 03 y 05. Donde la versión web y los docs móviles difieren, se marca como **[DECISIÓN]**.

## 1. Modelo del tablero

### 1.1 Grilla

- El tablero es una grilla **cuadrada de N×N** celdas, donde **N = número de personajes del caso (incluida la víctima)**. [DECISIÓN 2026-06-10]
- Cada celda se identifica por `(col, row)` con origen `(0,0)` arriba-izquierda, o por índice lineal `idx = row * width + col`.
- Tamaños por dificultad (mapeo Murdoku, decidido 2026-06-11 con referencias del usuario): **Principiante 6×6 · Casual 8×8 · Intermedio 9×9 · Experto 12×12 · Elite 16×16**. Vigente y comprobado en `DifficultyProfile` de `tools/lib/src/generator.dart` (04-11-2026). Los tamaños de rondas anteriores (4×4 hasta 7×7/8×8) están **SUPERADOS** (ver historial).
- **Tutorial (decidido 04-11-2026, pregunta 11):** el caso del tutorial (4×4 o 5×5) queda por debajo del perfil Principiante de 6×6 y se crea como caso fijo; ver §7, pregunta 1.
- **Experto y Élite: definidos pero nunca generados (H-39).** Los perfiles de 12×12 y 16×16 existen en el código, pero no hay ningún caso de esos niveles en `app/assets/cases` (hoy hay 8 de Principiante, 7 de Casual y 5 de Intermedio), no se han medido tiempos de generación y no se ha probado que se puedan tocar y leer en un teléfono. Si entran al lanzamiento lo decide Alejandro: **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 13: entran al lanzamiento o se recortan).
- **Cada caso tiene su propio mapa** (decisión 2026-06-11): la distribución de habitaciones, muebles y armas se genera proceduralmente por caso (`tools/lib/src/map_generator.dart`). Los nombres de habitaciones/lugares salen de pools temáticos; el arte por mundo se aplicará como piel encima (Fase 2).

### 1.2 Áreas (habitaciones)

- Toda celda pertenece a exactamente **una área** (habitación, pasillo, jardín...).
- Un área es una región conexa de celdas delimitada visualmente por paredes.
- Las áreas tienen `id` y nombre localizable (Cocina, Biblioteca...).
- **Esquina**: celda de un área donde se encuentran dos o tres paredes del área.

### 1.3 Muebles (modelo Murdoku, decidido 2026-06-11)

- El mapa está **amueblado**: los muebles son protagonistas del vocabulario de pistas (pillar 5).
- Cada mueble tiene **tipo** (silla, sillón, sofá, cama, alfombra, mesa, TV, planta, arbusto, armario, caja, lavadora, piano, barra...) y puede ocupar **varias celdas** (cama de 2 celdas, mesa larga).
- Dos clases de mueble:
  - **Pisables** (silla, sillón, sofá, cama, alfombra): la gente puede estar ENCIMA → pistas "estaba sentada en una silla", "sobre una cama".
  - **Bloqueantes** (mesa, TV, planta, armario, caja...): nadie puede ocupar sus celdas → pistas "junto a la mesa".
- Los tipos se agrupan para las pistas: planta y arbusto comparten el grupo "planta" ("junto a una planta").
- Artículo en los textos: si el mapa tiene UN solo mueble del grupo → "la silla"; si hay varios → "una silla".
- La repetición de muebles es la palanca de dificultad: "junto a una TV" con dos TVs deja más candidatas que con una.
- Las **armas potenciales** son objetos pequeños visibles que NO bloquean; lógicamente pertenecen al **área**, no a una celda exacta (doc 03).

### 1.4 Adyacencia y geografía

- **Adyacente / junto a / beside**: celda directamente arriba, abajo, izquierda o derecha **Y en la misma área**. (Regla verificada en la versión web.)
- **Al norte/sur/este/oeste de X**: comparación estricta de coordenada — "Y al oeste de X" significa `col(Y) < col(X)`, en **cualquier fila y cualquier área** (análogo para norte/sur con filas). Nota: como dos personas nunca comparten fila ni columna (sección 2.2), una versión "directamente al lado en la misma fila" sería imposible entre personas; la comparación estricta es la única semántica consistente.
- **Diagonal**: las 4 celdas diagonales inmediatas.
- **Fila / columna**: línea horizontal / vertical completa de la grilla, referenciable por ordinal ("primera fila") o por extremo ("la fila más al norte").

## 2. Personajes y solución

### 2.1 Personajes

- Un caso tiene N personajes: la **víctima** + (N−1) **sospechosos**.
- La identidad de la víctima es **conocida desde el inicio** (el jugador sabe quién murió); su **posición no** — se deduce como la de cualquier otro.
- En las pistas, "un sospechoso" significa cualquier persona excepto la víctima.

### 2.2 Restricciones globales (invariantes de toda solución)

1. Cada personaje ocupa exactamente una celda ocupable.
2. **Exactamente una persona por fila y exactamente una por columna** (restricción tipo sudoku — es la firma del juego). Como N personajes = N filas = N columnas, ninguna fila ni columna queda vacía, y el jugador puede deducir por completitud ("en esta fila falta alguien"). [DECISIÓN 2026-06-10]
3. Exactamente **una persona acompaña a la víctima en su área: el asesino**. Toda otra área contiene cualquier número de personas (0, 1 o varias) salvo lo que digan las pistas.
4. En casos con arma: el **arma homicida** está en la misma área que asesino y víctima.

### 2.3 Condición de victoria y revelación

- El jugador gana cuando TODOS los personajes están en su celda correcta (validación de tablero completo, doc 03).
- El asesino **no se acusa manualmente**: al validar correcto, el sistema lo revela (quien estaba a solas con la víctima).
- El arma homicida también se revela automáticamente en el resumen (doc 03).

## 3. Vocabulario de pistas

Cada pista es una restricción formal con representación textual localizable. El generador produce la estructura; el texto se renderiza por plantilla (ES/EN).

### 3.1 Tipos de pista V1 (vocabulario Murdoku, decidido 2026-06-11)

**Formato: UNA pista por personaje** (vive en su tarjeta, bajo su retrato) + pistas sueltas ("extras": área vacía, arma) según el perfil de dificultad. Los textos usan el género del personaje ("sentada"/"sentado").

**Máximo de pistas extra por dificultad (vigente, comprobado en `DifficultyProfile`, 04-11-2026):** Principiante 0 · Casual 0 · Intermedio 2 · Experto 2 · Élite 3. La frase anterior "solo desde Intermedio (máx. 2)" quedó **SUPERADA** porque Élite admite 3 (ver historial).

| Tipo | Forma textual ejemplo | Semántica formal |
|---|---|---|
| `in_area` | "Estaba en la Cocina" | pos(X) ∈ celdas(área) |
| `not_in_area` | "No estaba en la Cocina" | pos(X) ∉ celdas(área) |
| `on_object` | "Estaba sobre una cama / sentada en la silla" | pos(X) ∈ celdas de muebles pisables del grupo |
| `beside_object` | "Estaba junto a una planta" | pos(X) adyacente-ortogonal a celda de mueble del grupo, misma área, sin estar encima de ese mueble |
| `only_one_on` | "Era la única persona sobre una alfombra" | X sobre el grupo ∧ nadie más sobre ningún mueble del grupo |
| `compound` | "Estaba junto a una planta y sobre una cama" | conjunción de condiciones unarias del mismo sujeto |
| `victim_filler` | "Estaba en la última casilla libre" | sin información (solo la víctima; el caso se resuelve con el resto) |
| `beside` | "Estaba junto a Bruno" | pos(X) adyacente-ortogonal a pos(Y), misma área |
| `same_area` | "Estaba con Clara" | área(X) = área(Y) |
| `not_same_area` | "No estaba con la víctima" | área(X) ≠ área(Y) |
| `alone` | "Estaba sola" | área(X) no contiene a nadie más (ni a la víctima) |
| `alone_with` | "Estaba a solas con Elena" | área(X) contiene exactamente {X, Y} |
| `area_empty` | "Nadie estaba en la Biblioteca" | (extra) ninguna persona en ese área |
| `weapon_area` | "El arma homicida está en la Cocina" | (extra) área(arma) = Cocina |
| `weapon_category` | "El arma homicida es un veneno" | (extra) categoría(arma) |
| `weapon_exact` | "El arma homicida es el abrecartas" | (extra) arma = abrecartas |

Categorías de arma (doc 03, no visibles en UI): cortante, contundente, veneno, asfixia/atadura.

**Tipos de pista vigentes (comprobado en `tools/lib/src/clue.dart`, 04-11-2026):** los 16 de la tabla existen y el generador los usa. Los extras salen de `area_empty`, `weapon_area` y `weapon_category`, y de `weapon_exact` cuando el arma sigue ambigua tras la categoría. En los 20 casos de `app/assets/cases` aparecen `in_area`, `on_object`, `beside_object`, `only_one_on`, `compound`, `alone`, `alone_with`, `same_area` y `victim_filler`; los demás tipos están definidos en el código pero no aparecen en esos casos.

**Eliminadas de V1** (decisión 2026-06-11): las pistas mecánicas de fila/columna, esquina y cardinales ("al oeste de"). Las TÉCNICAS de fila/columna siguen siendo el corazón del juego (el jugador tacha la fila y columna de cada persona ubicada, como en el video del cuadernillo); lo que no existe son pistas que las mencionen. Si un caso difícil no logra unicidad, se amuebla más el mapa — no se recurre a pistas mecánicas.

### 3.2 Reglas de composición de pistas

- **Regla del mínimo 2** (2026-06-11): ninguna pista de tarjeta puede dejar una sola casilla posible por sí sola — mínimo 2 candidatas. La posición exacta SIEMPRE nace de cruzar la pista con el tachado de filas/columnas de otros personajes; ninguna pista "regala" a su personaje. Aplica también a las compuestas. Garantizado por test (`REGLA MURDOKU` en `generator_test.dart`).
- Ninguna pista contradice a otra.
- Ninguna relación de "misma área" (`same_area`, `beside`, `alone_with`) conecta jamás a la víctima con el asesino: delataría el final.
- `Principiante`: sin pistas vagas (`not_in_area`, `not_same_area`); sin arma. Las compuestas se permiten desde principiante (apuntan mejor, como en el cuadernillo).
- La víctima lleva relleno ("última casilla libre") siempre que el caso se resuelva sin su pista; pista real solo si hace falta.
- Pistas de arma solo en casos con arma; en `Casual` (sin extras) el área del crimen tiene UNA sola arma para que sea deducible sin pista adicional.

### Hallazgos del motor (Fase 0, 2026-06-10/11)

- **Toda dificultad necesita pistas a nivel de celda**. Con pistas solo de área la unicidad es matemáticamente imposible: intercambiar a las dos personas de un área produce siempre otra solución válida, y víctima + asesino comparten área SIEMPRE. Tras el rediseño Murdoku, ese nivel de celda lo aportan los MUEBLES (sobre/junto a), no las pistas mecánicas. Demostrado en `tools/test/deduction_uniqueness_test.dart`.
- Con una pista por tarjeta, la deducción descansa en cruzar cada pista con la exclusión de filas/columnas de los ya ubicados — exactamente el loop del Murdoku original.

## 4. Interacción del jugador (estado del tablero en cliente)

Estados de marca sobre una celda (docs 02/03 + reglas 2026-06-12):

- **Candidato**: letra del personaje (anotación). Varios candidatos coexisten.
- **Confirmado**: círculo con avatar (mantener oprimido o arrastrar). Colocar confirmado limpia la celda; una celda con confirmado rechaza candidatos y X. **DECIDIDO 04-11-2026** (auditoría, pregunta 20; ver ADR-0012): además de mantener oprimido o arrastrar, hay un modo alternativo de tocar dos veces (elegir y tocar el destino), y al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". El diseño exacto se hace en la prueba de concepto (etapa 2); hoy la app aún no lo tiene.
- **X parcial / X fuerte**: descarte del jugador (X pequeña / X grande).
- **Reglas de convivencia (2026-06-12)**: X y candidatos NO conviven — una celda con X rechaza candidatos (mensaje), y la X manual limpia los candidatos de la celda (acto deliberado). La **auto-X** (al confirmar se tachan fila y columna) solo marca celdas vacías: nunca pisa candidatos ni confirmados, y se retira si se borra su confirmado.
- **Un confirmado por personaje**: confirmar a alguien que ya está fijado en otra celda se rechaza con mensaje; al confirmarse, sus candidatos desaparecen de todo el tablero.
- **Borrado**: herramienta borrador (toca casillas y las limpia por completo), papelera (arrastrar marcas) y mini panel (tocar celda sin herramienta seleccionada).
- ~~Modos de notas: cuadrícula lógica separada o superpuesta al mapa; ambas comparten el mismo estado lógico.~~ (SUPERADO 04-11-2026: hoy es un selector Mapa / Notas sobre un único tablero y un único estado; ver `docs/03-reglas-del-juego.md`)
- Opción de calidad de vida heredable de la web: **auto-X** en fila/columna al confirmar a alguien (configurable).

Estas marcas son presentación del cliente: la validación oficial solo compara **posiciones confirmadas** contra la solución (en servidor).

## 5. Formato de datos (vigente, comprobado el 04-11-2026)

Fuente: `PuzzleCase.toJson` y `GameMap.toJson` en `tools/lib/src/`, y un caso real, `app/assets/cases/caso-intermedio-s1.json`. El borrador original (mapa autorado + caso por separado) quedó **SUPERADO**; se conserva en el historial al final.

### 5.1 Un caso = un solo archivo JSON con su mapa embebido

Cada caso es un archivo único; el mapa viaja dentro (`map`), porque cada caso tiene su propio mapa. Las celdas se identifican por índice lineal (`idx = fila * size + columna`).

```json
{
  "caseId": "caso-intermedio-s1",
  "mapId": "mapa-intermedio-s1-v3",
  "map": {
    "id": "mapa-intermedio-s1-v3",
    "name_es": "El Casino",
    "size": 9,
    "areas": [{ "id": "porche", "name_es": "el Porche", "cells": [39, 48, 49] }],
    "objects": [{ "id": "sofa-4", "type": "sofa", "cells": [57, 48] }],
    "weapons": [{ "id": "cuerda", "name_es": "la cuerda", "category": "asfixia", "area": "biblioteca" }]
  },
  "difficulty": "intermedio",
  "hasWeapon": false,
  "victim": "c1",
  "characters": [{ "id": "c1", "name_es": "Adela", "female": true }],
  "clues": [
    { "type": "beside_object", "subject": "c2", "group": "tv" },
    { "type": "alone_with", "a": "c3", "b": "c4" },
    { "type": "compound", "subject": "c1", "parts": [
      { "type": "in_area", "subject": "c1", "area": "salon" },
      { "type": "on_object", "subject": "c1", "group": "alfombra" } ] }
  ],
  "solution": { "positions": { "c1": 5, "c2": 13 }, "murderer": "c2" },
  "metrics": { "deductionSteps": 7, "maxTier": 3, "clueCount": 9 }
}
```

(El ejemplo está recortado: el caso real tiene 9 personajes, 9 pistas y todas las áreas y objetos.)

Notas sobre el formato real:
- La víctima se indica con `victim` (id de un personaje); los personajes no llevan campo `role`.
- La solución es `solution.positions` (id de personaje a celda), `murderer` y, solo en casos con arma, `lethalWeapon`.
- Las armas visibles están en `map.weapons` (cada una con su categoría y su área); no existe `weapons.visible` ni `weapons.lethal`.
- No existen en el formato real los campos del borrador: `world`, `type` (oficial, práctica, diario, tutorial), `version`, `width` y `height`, `weaponSlots`, el campo `blocks` de los objetos ni `name_en`. Si se necesitan (mundo, tipo de caso, estado, fecha), son parte del catálogo pendiente (H-43, ver doc 05).
- Los muebles pisables o bloqueantes se deducen del tipo de mueble, no de un campo del JSON.

### 5.2 Entrega al cliente

**Regla de entrega (principio vigente):** el cliente recibe el caso SIN `solution`, sin `lethalWeapon` y sin `metrics` (`PuzzleCase.toClientJson`, que el comando `validate` del CLI comprueba). El payload va comprimido y firmado (doc 07, etapa 5).

**Excepción vigente de la Fase 1 (aprobada, caduca en la etapa 5):** los JSON de `app/assets/cases` son el formato completo, con `solution` y `metrics`, y la validación es local. Es un riesgo aceptado (doc 18).

## 6. Solver (Fase 0 — el primer código del proyecto)

### 6.1 Componentes

1. **Motor de deducción**: aplica propagación de restricciones imitando a un jugador humano: cada pista reduce dominios (celdas posibles por personaje); las restricciones globales (fila/columna, ocupabilidad, asesino-a-solas) propagan descartes.
2. **Verificador de unicidad**: búsqueda exhaustiva (backtracking) que demuestra que existe exactamente una asignación válida.
3. **Contador de pasos de deducción**: un "paso" = una inferencia que fija una posición o elimina la última alternativa de una celda. Define la dificultad (rangos en doc 05, hoy **en recalibración**; ver 6.5 y H-40). El motor devuelve además `maxTier`, el nivel de la técnica más difícil que hizo falta (T1 a T4).
4. **Detector de redundancia**: una pista es redundante si al quitarla el caso sigue teniendo solución única con los mismos pasos. **NO IMPLEMENTADO (H-42):** no existe en `tools/lib` ni en `tools/bin` (la búsqueda de "redundan" no encuentra nada). Hoy nada garantiza que cada pista sea necesaria. Es un pendiente técnico sin decisión de Alejandro de por medio; si se decide no hacerlo, se marca "diferido".

### 6.2 Criterio de aceptación de un caso

- Solución única (verificada por búsqueda exhaustiva).
- Resoluble por deducción pura: el motor de deducción llega a la solución sin ramificar (sin "probar y ver").
- Pasos de deducción dentro del rango de la etiqueta de dificultad (doc 05). **NO IMPLEMENTADO como filtro (H-40):** el generador calcula los pasos y los guarda en `metrics`, pero no rechaza ni reclasifica un caso que quede fuera del rango. La dificultad real depende del sorteo y los rangos del doc 05 están desactualizados para los tamaños 6/8/9. Primero se recalibran los rangos con los datos de la prueba de juego y después se imponen en el generador (etapas 1 y 3).
- Tiempo de solver acotado (límite configurable; caso descartado si lo excede). **NO IMPLEMENTADO (H-42):** no hay `Stopwatch`, límite de tiempo ni tope de nodos en `UniquenessChecker.countSolutions` ni en `CaseFactory`. El único tope es de intentos (hasta 40 mapas con 8 intentos de caso cada uno), no de tiempo. Sin límite, un caso difícil (sobre todo 12×12 y 16×16, H-39) puede colgar la generación.

### 6.3 Generador

- Entrada vigente: etiqueta de dificultad objetivo + semilla. `CaseFactory` (`tools/lib/src/case_factory.dart`) genera un mapa propio por caso (`map_generator.dart`) y sobre él el caso. Una semilla = un caso reproducible. (La entrada "mapa autorado" quedó **SUPERADA**, ver historial.)
- Proceso: coloca personajes respetando invariantes → elige asesino/arma → genera pool de pistas verdaderas → selecciona subconjunto mínimo+margen que produzca unicidad → valida con solver → calcula métricas.
- Salida: caso candidato para revisión editorial (doc 05). En código, la salida es un archivo JSON por semilla (ver doc 05, "Flujo real de generación").
- Elección de la pista de reparación: cuando la deducción se atasca, el generador salta a la pista candidata más fuerte en vez de la inmediatamente más fuerte (`_stronger` en `generator.dart`), lo que aplana la dificultad. Es el hallazgo H-40, pendiente de arreglo en la etapa 3.

### 6.4 Implementación

- Dart puro en `tools/` (sin Flutter, sin Firebase) — el mismo código de modelo se reutiliza en la app (prevalidación local) y se porta la validación a Cloud Functions.
- Tests deterministas obligatorios: casos fixture con solución conocida, casos con doble solución (deben rechazarse), casos que requieren adivinar (deben rechazarse).

### 6.5 Técnicas de deducción y pasos medidos (comprobado en `tools/lib/src/deduction.dart`, 04-11-2026)

El motor aplica siempre la técnica más simple que pode algo; cada aplicación con poda real cuenta como un paso. Las técnicas, por nivel:

| Nivel | Técnicas |
|---|---|
| T1 | pista directa |
| T2 | exclusión fila/columna |
| T3 | soporte entre pares · single oculto fila/columna · confinamiento fila/columna |
| T4 | conteo de áreas · regla del asesino · cadena del arma |

`metrics` de cada caso guarda `deductionSteps` (pasos), `maxTier` (técnica más alta) y `clueCount`. Ejemplo real: `caso-intermedio-s1` tiene 9 pistas, 7 pasos y `maxTier` 3. La tabla de calibración por dificultad (pasos mínimo y máximo, número de pistas, extras, uso de arma) **no está definida**: depende de los datos de la prueba de juego (etapa 1) y del arreglo del generador (etapa 3; H-40). Los rangos del doc 05 no sirven de referencia hasta entonces.

## 7. Decisiones tomadas y preguntas abiertas

### [DECISIÓN] cerradas (2026-06-10, confirmadas con el usuario)

- La víctima se ubica como cualquier personaje y su identidad es pública desde el inicio (modelo de la versión web).
- "Junto a" exige misma área además de adyacencia ortogonal (regla de la web).
- Norte/sur/este/oeste NO exigen misma área salvo que la pista lo diga (regla de la web).
- **Grilla cuadrada N×N con N = personajes (incluida la víctima); exactamente una persona por fila y por columna; ninguna fila/columna vacía.** Tamaño escala con dificultad ~~(4×4 → 7×7/8×8)~~ **SUPERADO**: vigente 6×6 → 16×16 (ver §1.1).
- **Ayudas en Principiante y Tutorial: NO penalizan.** Desde Casual: todas penalizan. Manda `08-balance.md`; `03-reglas-del-juego.md` fue corregido. Nota 04-11-2026: las ayudas no existen en la app hoy y su especificación y puntuación están abiertas: **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 12).
- **SUPERADO (ver "La rotación anti-trampa quedó SIN pistas que rotar texto direccional", ronda del 11-06-2026):** **La rotación del mapa también rota las pistas**: la pista lógica se guarda en coordenadas canónicas; el renderizador de texto la transforma según la orientación del jugador. Bajo rotación de 90°/270° las referencias de fila/columna se intercambian ("primera fila" → "primera columna") y las cardinales se remapean (oeste→norte, etc.). El servidor valida siempre en coordenadas canónicas; la rotación nunca toca la lógica.
- "Island" en la versión web es solo vocabulario de resaltado (nombre de zona/objeto de mapas concretos), no una regla del motor. En Enigmatrix los nombres de áreas y objetos son **datos del mapa**, no palabras clave del motor: el renderizador de pistas los toma del mapa autorado.
- Nomenclatura de marcas del jugador: la del doc 03 (candidato/confirmado/X parcial/X fuerte).

### [DECISIÓN] cerradas (2026-06-11, segunda ronda de playtest)

- **Mapas únicos por caso**: habitaciones, muebles y armas generados proceduralmente; dos casos jamás comparten distribución. Reemplaza el "mapas autorados a mano" del doc 05 — el autorado pasa a ser la piel artística por mundo.
- **Tamaños = Murdoku**: 6×6 / 8×8 / 9×9 / 12×12 / 16×16 para las 5 dificultades.
- **Auto-X**: opción del jugador (activada por defecto): al confirmar a alguien se tachan automáticamente su fila y columna; las X automáticas se retiran si se borra el confirmado.
- **Marcas visuales**: candidato = solo la letra del personaje; confirmado = círculo con avatar (mantener oprimido o arrastrar); X grandes.

### [DECISIÓN] cerradas (2026-06-11, rediseño Murdoku tras playtest del usuario)

- **Una pista por personaje** (en su tarjeta), incluida la víctima; pistas sueltas extra según el perfil (Intermedio 2, Experto 2, Élite 3; ver §3.1). La frase original decía "solo desde Intermedio (máx. 2)".
- **Muebles estilo Murdoku**: pisables (silla, sillón, sofá, cama, alfombra) y bloqueantes (mesa, TV, planta, armario, caja...); multi-celda; grupos (planta+arbusto); artículo según cantidad.
- **Pistas mecánicas eliminadas de V1** (fila/columna, esquina, cardinales). El vocabulario es áreas + muebles + personas.
- **Tamaño de grilla crece con dificultad** (~~4×4 principiante → 6×6+ en difíciles~~ **SUPERADO**: 6×6 en Principiante y 16×16 en Élite, ver §1.1); la dificultad también escala por vaguedad de pistas y muebles repetidos.
- **Víctima con relleno** ("estaba en la última casilla libre") siempre que sea posible; pista real solo si el caso la necesita.
- **Pistas compuestas desde principiante** (el cuadernillo las usa en casos fáciles).
- La rotación anti-trampa quedó SIN pistas que rotar texto direccional (las cardinales ya no existen): solo rota la presentación del mapa.

### Preguntas abiertas

1. ¿El tutorial usa la mecánica completa en grilla pequeña o una versión reducida? **DECIDIDO 04-11-2026** (auditoría, pregunta 11; ver ADR-0012): el tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible. Esto sustituye la nota anterior "decidir en Fase 1".
   - **Consecuencia técnica (nota 04-11-2026):** un caso de 4×4 o 5×5 queda **por debajo del perfil Principiante de 6×6**, que hoy es el más pequeño de `DifficultyProfile` en `tools/lib/src/generator.dart`; el generador no tiene perfil de 4×4 ni 5×5. Habrá que crear el tutorial como **caso fijo** (hecho a mano o generado una sola vez y revisado). No se cambia la semántica de las pistas: el tutorial usa los mismos tipos de pista de la sección 3.1.
   - (SUPERADO 04-11-2026) Versión anterior, conservada como historial: 1. ¿El tutorial usa la mecánica completa en grilla pequeña o una versión reducida? Antes pendiente (auditoría 04-11-2026, pregunta 11). Dos versiones en conflicto: (a) la propuesta por defecto de esta spec, mecánica completa en 4×4 con pasos guiados; (b) la recomendación de la auditoría, un caso propio pequeño (4×4 o 5×5) que no cuente como Caso 1, que enseñe también la X, las notas, la papelera y un Resolver fallido, obligatorio la primera vez con botón Saltar visible. Hoy la app tiene dos tutoriales (un diálogo de 5 páginas y uno jugable de 7 pasos), ambos omitibles, y el generador no tiene perfil de 4×4 ni 5×5. No se decide aquí; la respuesta de Alejandro sustituye la nota anterior "decidir en Fase 1".
2. ¿Las celdas de un área deben ser siempre contiguas? → asumimos que sí; el autor de mapas lo respeta como convención. Validarlo como regla del editor en Fase 4.

## Historial de decisiones superadas

Texto conservado a propósito (regla de no borrar). Nada de lo que está aquí manda; la versión vigente está en el cuerpo del documento.

### Tamaños y extras de rondas anteriores

- Ronda del 10-06-2026: "Tamaño escala con dificultad (4×4 → 7×7/8×8)". Superado el 11-06-2026 por 6×6 / 8×8 / 9×9 / 12×12 / 16×16.
- Ronda del 11-06-2026 (rediseño Murdoku): "Tamaño de grilla crece con dificultad (4×4 principiante → 6×6+ en difíciles)". Superado por el mapeo Murdoku, vigente.
- "Pistas sueltas extra solo desde Intermedio (máx. 2)". Superado: máximo por perfil, Élite 3.
- Pregunta abierta 1 sobre el tutorial: "decidir en Fase 1 (cuando se diseñe el tutorial guiado). Propuesta por defecto: mecánica completa en 4×4 con pasos guiados." Sustituida por la pregunta 11 de la auditoría, ya DECIDIDA el 04-11-2026 (ver §7).

### Rotación que también rotaba las pistas

Decisión del 10-06-2026: la pista lógica se guardaba en coordenadas canónicas y el renderizador de texto la transformaba según la orientación del jugador (bajo 90°/270° "primera fila" pasaba a "primera columna" y las cardinales se remapeaban). Superada el 11-06-2026: al eliminar las pistas mecánicas, la rotación solo afecta a la presentación del mapa. El servidor sigue validando en coordenadas canónicas.

### Entrada del generador "mapa autorado"

§6.3 decía "Entrada: mapa autorado + etiqueta de dificultad objetivo". Superado el 11-06-2026 por mapas procedurales únicos por caso.

### Borrador original del formato de datos

**(SUPERADO el 04-11-2026; ver §5)**

#### Borrador 5.1 Mapa (autorado, reutilizable)

```json
{
  "mapId": "mansion-01",
  "world": "mansion",
  "width": 5, "height": 5,
  "areas": [{ "id": "kitchen", "name_es": "Cocina", "name_en": "Kitchen", "cells": [0,1,5,6] }],
  "objects": [{ "id": "table-1", "type": "table", "cell": 6, "blocks": true }],
  "weaponSlots": [{ "areaId": "kitchen", "allowed": ["kitchen-knife", "scissors"] }],
  "version": 1
}
```

#### Borrador 5.2 Caso (generado y validado por solver)

```json
{
  "caseId": "mansion-01-c042",
  "mapId": "mansion-01",
  "difficulty": "casual",
  "type": "official",
  "characters": [{ "id": "s1", "role": "suspect" }, { "id": "v", "role": "victim" }],
  "clues": [{ "id": "c1", "type": "in_area", "subject": "s1", "area": "kitchen" }],
  "weapons": { "visible": ["letter-opener", "rope"], "lethal": "rope" },
  "solution": { "s1": 7, "v": 13, "murderer": "s2" },
  "metrics": { "deductionSteps": 6, "clueCount": 6 }
}
```

**Regla de entrega**: el cliente recibe el caso SIN `solution`, sin `weapons.lethal` y sin métricas de dependencias (doc 05). El payload va comprimido y firmado (doc 07).

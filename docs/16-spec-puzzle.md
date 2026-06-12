# Enigmatrix - Especificación formal del puzzle

## Objetivo de este documento

Definir SIN ambigüedad el modelo lógico del puzzle: qué es un tablero, qué es un caso, qué significa cada pista, cómo se valida una solución y cómo funciona el solver. Este es el documento que `puzzle-engineer` implementa primero (Fase 0 del roadmap).

Fuentes: versión web jugable (murdoku.com, reglas verificadas contra su código) + docs 03 y 05. Donde la versión web y los docs móviles difieren, se marca como **[DECISIÓN]**.

## 1. Modelo del tablero

### 1.1 Grilla

- El tablero es una grilla **cuadrada de N×N** celdas, donde **N = número de personajes del caso (incluida la víctima)**. [DECISIÓN 2026-06-10]
- Cada celda se identifica por `(col, row)` con origen `(0,0)` arriba-izquierda, o por índice lineal `idx = row * width + col`.
- Tamaños por dificultad (mapeo Murdoku, decidido 2026-06-11 con referencias del usuario): **Principiante 6×6 · Casual 8×8 · Intermedio 9×9 · Experto 12×12 · Elite 16×16**.
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

**Formato: UNA pista por personaje** (vive en su tarjeta, bajo su retrato) + pistas sueltas ("extras": área vacía, arma) solo desde Intermedio (máx. 2). Los textos usan el género del personaje ("sentada"/"sentado").

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
- **Confirmado**: círculo con avatar (mantener oprimido o arrastrar). Colocar confirmado limpia la celda; una celda con confirmado rechaza candidatos y X.
- **X parcial / X fuerte**: descarte del jugador (X pequeña / X grande).
- **Reglas de convivencia (2026-06-12)**: X y candidatos NO conviven — una celda con X rechaza candidatos (mensaje), y la X manual limpia los candidatos de la celda (acto deliberado). La **auto-X** (al confirmar se tachan fila y columna) solo marca celdas vacías: nunca pisa candidatos ni confirmados, y se retira si se borra su confirmado.
- **Un confirmado por personaje**: confirmar a alguien que ya está fijado en otra celda se rechaza con mensaje; al confirmarse, sus candidatos desaparecen de todo el tablero.
- **Borrado**: herramienta borrador (toca casillas y las limpia por completo), papelera (arrastrar marcas) y mini panel (tocar celda sin herramienta seleccionada).
- Modos de notas: cuadrícula lógica separada o superpuesta al mapa; ambas comparten el mismo estado lógico.
- Opción de calidad de vida heredable de la web: **auto-X** en fila/columna al confirmar a alguien (configurable).

Estas marcas son presentación del cliente: la validación oficial solo compara **posiciones confirmadas** contra la solución (en servidor).

## 5. Formato de datos (borrador para Fase 0 — `puzzle-engineer` lo cierra)

### 5.1 Mapa (autorado, reutilizable)

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

### 5.2 Caso (generado y validado por solver)

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

## 6. Solver (Fase 0 — el primer código del proyecto)

### 6.1 Componentes

1. **Motor de deducción**: aplica propagación de restricciones imitando a un jugador humano: cada pista reduce dominios (celdas posibles por personaje); las restricciones globales (fila/columna, ocupabilidad, asesino-a-solas) propagan descartes.
2. **Verificador de unicidad**: búsqueda exhaustiva (backtracking) que demuestra que existe exactamente una asignación válida.
3. **Contador de pasos de deducción**: un "paso" = una inferencia que fija una posición o elimina la última alternativa de una celda. Define la dificultad (rangos en doc 05).
4. **Detector de redundancia**: una pista es redundante si al quitarla el caso sigue teniendo solución única con los mismos pasos.

### 6.2 Criterio de aceptación de un caso

- Solución única (verificada por búsqueda exhaustiva).
- Resoluble por deducción pura: el motor de deducción llega a la solución sin ramificar (sin "probar y ver").
- Pasos de deducción dentro del rango de la etiqueta de dificultad (doc 05).
- Tiempo de solver acotado (límite configurable; caso descartado si lo excede).

### 6.3 Generador

- Entrada: mapa autorado + etiqueta de dificultad objetivo.
- Proceso: coloca personajes respetando invariantes → elige asesino/arma → genera pool de pistas verdaderas → selecciona subconjunto mínimo+margen que produzca unicidad → valida con solver → calcula métricas.
- Salida: caso candidato para revisión editorial (doc 05).

### 6.4 Implementación

- Dart puro en `tools/` (sin Flutter, sin Firebase) — el mismo código de modelo se reutiliza en la app (prevalidación local) y se porta la validación a Cloud Functions.
- Tests deterministas obligatorios: casos fixture con solución conocida, casos con doble solución (deben rechazarse), casos que requieren adivinar (deben rechazarse).

## 7. Decisiones tomadas y preguntas abiertas

### [DECISIÓN] cerradas (2026-06-10, confirmadas con el usuario)

- La víctima se ubica como cualquier personaje y su identidad es pública desde el inicio (modelo de la versión web).
- "Junto a" exige misma área además de adyacencia ortogonal (regla de la web).
- Norte/sur/este/oeste NO exigen misma área salvo que la pista lo diga (regla de la web).
- **Grilla cuadrada N×N con N = personajes (incluida la víctima); exactamente una persona por fila y por columna; ninguna fila/columna vacía.** Tamaño escala con dificultad (4×4 → 7×7/8×8).
- **Ayudas en Principiante y Tutorial: NO penalizan.** Desde Casual: todas penalizan. Manda `08-balance.md`; `03-reglas-del-juego.md` fue corregido.
- **La rotación del mapa también rota las pistas**: la pista lógica se guarda en coordenadas canónicas; el renderizador de texto la transforma según la orientación del jugador. Bajo rotación de 90°/270° las referencias de fila/columna se intercambian ("primera fila" → "primera columna") y las cardinales se remapean (oeste→norte, etc.). El servidor valida siempre en coordenadas canónicas; la rotación nunca toca la lógica.
- "Island" en la versión web es solo vocabulario de resaltado (nombre de zona/objeto de mapas concretos), no una regla del motor. En Enigmatrix los nombres de áreas y objetos son **datos del mapa**, no palabras clave del motor: el renderizador de pistas los toma del mapa autorado.
- Nomenclatura de marcas del jugador: la del doc 03 (candidato/confirmado/X parcial/X fuerte).

### [DECISIÓN] cerradas (2026-06-11, segunda ronda de playtest)

- **Mapas únicos por caso**: habitaciones, muebles y armas generados proceduralmente; dos casos jamás comparten distribución. Reemplaza el "mapas autorados a mano" del doc 05 — el autorado pasa a ser la piel artística por mundo.
- **Tamaños = Murdoku**: 6×6 / 8×8 / 9×9 / 12×12 / 16×16 para las 5 dificultades.
- **Auto-X**: opción del jugador (activada por defecto): al confirmar a alguien se tachan automáticamente su fila y columna; las X automáticas se retiran si se borra el confirmado.
- **Marcas visuales**: candidato = solo la letra del personaje; confirmado = círculo con avatar (mantener oprimido o arrastrar); X grandes.

### [DECISIÓN] cerradas (2026-06-11, rediseño Murdoku tras playtest del usuario)

- **Una pista por personaje** (en su tarjeta), incluida la víctima; pistas sueltas extra solo desde Intermedio (máx. 2).
- **Muebles estilo Murdoku**: pisables (silla, sillón, sofá, cama, alfombra) y bloqueantes (mesa, TV, planta, armario, caja...); multi-celda; grupos (planta+arbusto); artículo según cantidad.
- **Pistas mecánicas eliminadas de V1** (fila/columna, esquina, cardinales). El vocabulario es áreas + muebles + personas.
- **Tamaño de grilla crece con dificultad** (4×4 principiante → 6×6+ en difíciles); la dificultad también escala por vaguedad de pistas y muebles repetidos.
- **Víctima con relleno** ("estaba en la última casilla libre") siempre que sea posible; pista real solo si el caso la necesita.
- **Pistas compuestas desde principiante** (el cuadernillo las usa en casos fáciles).
- La rotación anti-trampa quedó SIN pistas que rotar texto direccional (las cardinales ya no existen): solo rota la presentación del mapa.

### Preguntas abiertas

1. ¿El tutorial usa la mecánica completa en grilla pequeña o una versión reducida? → decidir en Fase 1 (cuando se diseñe el tutorial guiado). Propuesta por defecto: mecánica completa en 4×4 con pasos guiados.
2. ¿Las celdas de un área deben ser siempre contiguas? → asumimos que sí; el autor de mapas lo respeta como convención. Validarlo como regla del editor en Fase 4.

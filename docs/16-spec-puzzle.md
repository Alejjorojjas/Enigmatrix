# Enigmatrix - Especificación formal del puzzle

## Objetivo de este documento

Definir SIN ambigüedad el modelo lógico del puzzle: qué es un tablero, qué es un caso, qué significa cada pista, cómo se valida una solución y cómo funciona el solver. Este es el documento que `puzzle-engineer` implementa primero (Fase 0 del roadmap).

Fuentes: versión web jugable (murdoku.com, reglas verificadas contra su código) + docs 03 y 05. Donde la versión web y los docs móviles difieren, se marca como **[DECISIÓN]**.

## 1. Modelo del tablero

### 1.1 Grilla

- El tablero es una grilla **cuadrada de N×N** celdas, donde **N = número de personajes del caso (incluida la víctima)**. [DECISIÓN 2026-06-10]
- Cada celda se identifica por `(col, row)` con origen `(0,0)` arriba-izquierda, o por índice lineal `idx = row * width + col`.
- Tamaños derivados de los rangos del doc 05 (sospechosos + víctima): Principiante 4×4, Casual 5×5, Intermedio 6×6, Experto 7×7, Elite 7×7 u 8×8.

### 1.2 Áreas (habitaciones)

- Toda celda pertenece a exactamente **una área** (habitación, pasillo, jardín...).
- Un área es una región conexa de celdas delimitada visualmente por paredes.
- Las áreas tienen `id` y nombre localizable (Cocina, Biblioteca...).
- **Esquina**: celda de un área donde se encuentran dos o tres paredes del área.

### 1.3 Celdas ocupables y objetos

- Una celda puede contener un **objeto** (mesa, cama, planta, sofá...).
- Las celdas con objeto **no son ocupables**: ningún personaje puede colocarse ahí.
- Los objetos son parte del mapa autorado (doc 05) y pueden ser referidos por pistas ("junto a la mesa").
- Las **armas potenciales** son objetos pequeños visibles que NO bloquean la celda; lógicamente pertenecen al **área**, no a una celda exacta (doc 03).

### 1.4 Adyacencia y geografía

- **Adyacente / junto a / beside**: celda directamente arriba, abajo, izquierda o derecha **Y en la misma área**. (Regla verificada en la versión web.)
- **Al norte/sur/este/oeste de X**: en alguna celda arriba/abajo/derecha/izquierda de X (misma columna o fila según el eje), **en cualquier área** salvo que la pista especifique área.
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

### 3.1 Tipos de pista V1 (consolidado docs 05 + versión web)

| Tipo | Forma textual ejemplo | Semántica formal |
|---|---|---|
| `in_area` | "X está en la Cocina" | pos(X) ∈ celdas(área) |
| `not_in_area` | "X no está en la Cocina" | pos(X) ∉ celdas(área) |
| `beside` | "X está junto a Y / junto a la mesa" | pos(X) adyacente-ortogonal a pos(Y) u objeto, misma área |
| `same_area` | "X está con Y" | área(X) = área(Y) |
| `not_same_area` | "X no está con Y" | área(X) ≠ área(Y) |
| `alone` | "X estaba solo" | área(X) no contiene a nadie más (ni a la víctima) |
| `alone_with` | "X estaba a solas con Y" | área(X) contiene exactamente {X, Y} |
| `area_empty` | "La Biblioteca estaba vacía" | ninguna persona en ese área |
| `cardinal` | "X está al oeste de Y" | col(X) < col(Y) (misma fila NO requerida; ver 1.4) |
| `row_col` | "X está en la primera fila" | row(X) = k |
| `corner` | "X está en una esquina del Salón" | pos(X) ∈ esquinas(área) |
| `victim_loc` | "La víctima está en el Estudio" | pos(víctima) ∈ celdas(área) |
| `weapon_area` | "El arma está en la Cocina" | área(arma) = Cocina |
| `weapon_type` | "El arma es cortante" | categoría(arma) = cortante |
| `weapon_exact` | "El arma es el abrecartas" | arma = abrecartas |

Categorías de arma (doc 03, no visibles en UI): cortante, contundente, veneno, asfixia/atadura.

### 3.2 Reglas de composición de pistas (doc 05)

- Ninguna pista contradice a otra; ninguna es trivialmente deducible de otra.
- Redundancia limitada a un margen permitido (parámetro del generador).
- `Principiante`: solo `in_area`, `not_in_area` y `same_area` simples; sin arma.
- Pistas de arma solo en casos con arma homicida.

## 4. Interacción del jugador (estado del tablero en cliente)

Estados de marca sobre una celda (docs 02/03):

- **Candidato**: avatar pequeño + "?" (equivale a "nota" en la versión web).
- **Confirmado**: avatar grande + flecha verde. Colocar confirmado limpia la celda; una celda con confirmado rechaza candidatos y X.
- **X parcial / X fuerte**: descarte del jugador (X pequeña / X grande).
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

### Preguntas abiertas

1. ¿El tutorial usa la mecánica completa en grilla pequeña o una versión reducida? → decidir en Fase 1 (cuando se diseñe el tutorial guiado). Propuesta por defecto: mecánica completa en 4×4 con pasos guiados.
2. ¿Las celdas de un área deben ser siempre contiguas? → asumimos que sí; el autor de mapas lo respeta como convención. Validarlo como regla del editor en Fase 4.

# Contenido de la V1: Mundo 1 "La Mansión" y reto diario (05-11-2026)

Ronda 3.2. Autor: agente de contenido. Todos los casos salen del CLI de `tools/` con semilla explícita, el mundo `tools/data/mundos/mansion.json` y los planes `mansion-casos.json` (campaña) y `mansion-reto.json` (reto). La puerta de contenido (`catalog-check`) pasa con los 61 casos (20 del banco de pruebas, 10 de campaña, 30 de reto y el tutorial). Una prueba regenera cada archivo desde su plan y comprueba que sea idéntico.

## Cómo leer las columnas

- **Pasos:** pasos de deducción que necesita el solver (métrica del caso). Rangos provisionales de `difficulty_ranges.dart`: Principiante 3 a 12, Casual 4 a 14, Intermedio 4 a 16 (con técnica T3 o más).
- **Técnica:** la más avanzada que el caso exige. T3 = soporte entre pares, únicos ocultos y confinamiento. T4 = conteo de áreas, regla del asesino y cadena del arma.
- **Arma:** si el caso incluye el arma homicida.

## Campaña: Mundo 1 "La Mansión" (10 casos)

| Id | Título | Dificultad | Tamaño | Pasos | Técnica | Arma |
|---|---|---|---|---|---|---|
| mansion-01 | Cena de bienvenida | Principiante | 6x6 | 3 | T3 (pares, únicos ocultos, confinamiento) | no |
| mansion-02 | El testamento sellado | Principiante | 6x6 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| mansion-03 | Tormenta en la colina | Principiante | 6x6 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| mansion-04 | La noche del piano | Casual | 8x8 | 6 | T3 (pares, únicos ocultos, confinamiento) | no |
| mansion-05 | El retrato cambiado de pared | Casual | 8x8 | 8 | T4 (conteo de áreas, regla del asesino, cadena del arma) | no |
| mansion-06 | Té de las cinco | Casual | 8x8 | 11 | T4 (conteo de áreas, regla del asesino, cadena del arma) | no |
| mansion-07 | Baile de máscaras | Intermedio | 9x9 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| mansion-08 | La llave desaparecida | Intermedio | 9x9 | 9 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| mansion-09 | El último invitado | Intermedio | 9x9 | 11 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| mansion-10 | El reloj de las doce | Intermedio | 9x9 | 12 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |

Semillas (todas explícitas y reproducibles): mansion-01 = 21, mansion-02 = 3, mansion-03 = 17, mansion-04 = 8, mansion-05 = 10, mansion-06 = 12, mansion-07 = 11, mansion-08 = 29, mansion-09 = 27, mansion-10 = 30.

**Curva.** Pasos por caso: 3, 5, 8, 6, 8, 11, 8, 9, 11, 12. Media por tramo: Principiante 5.3, Casual 8.3, Intermedio 10.0. Dentro de cada dificultad los pasos no bajan de un caso al siguiente, y la técnica T4 aparece desde el caso 5. El caso 7 (Intermedio sin arma) es la rampa hacia los de arma, que son los casos 8, 9 y 10.

**Arma homicida (CAMBIABLE).** Va en 3 de los 4 casos Intermedio (casos 8, 9 y 10). Es la recomendación de la pregunta 19 de la auditoría, que sigue PENDIENTE DE DECISIÓN de Alejandro. Para cambiarla basta poner `"arma"` en `true` o `false` en `tools/data/mundos/mansion-casos.json`, regenerar con `build-plan` y volver a agregar el caso al catálogo. Ojo: cambiar el arma cambia el caso completo (otro sorteo), así que las semillas de arma se midieron aparte.

## Reto diario (30 días)

Los 30 retos son del mundo "mansion", tipo `reto`, con `dia` del 1 al 30. Cada semana de 7 días sube de Casual a Intermedio y cierra con arma en los dos últimos días (6 y 7, 13 y 14, 20 y 21, 27 y 28). Los días 29 y 30 cierran el mes (Casual y el más largo, con arma). La hora de cambio del reto está pendiente (pregunta 7): solo se guarda el número de día. El arma en el reto sigue la misma pregunta 19 y también es cambiable.

| Id | Día | Título | Dificultad | Tamaño | Pasos | Técnica | Arma |
|---|---|---|---|---|---|---|---|
| reto-001 | 1 | Flores frescas | Casual | 8x8 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-002 | 2 | El eco en la escalera | Casual | 8x8 | 6 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-003 | 3 | Una carta sin remitente | Casual | 8x8 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-004 | 4 | El vals interrumpido | Intermedio | 9x9 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-005 | 5 | Lluvia de otoño | Intermedio | 9x9 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-006 | 6 | La partida de ajedrez | Intermedio | 9x9 | 9 | T3 (pares, únicos ocultos, confinamiento) | sí |
| reto-007 | 7 | El gato inquieto | Intermedio | 9x9 | 11 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-008 | 8 | Cena a oscuras | Casual | 8x8 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-009 | 9 | La subasta privada | Casual | 8x8 | 6 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-010 | 10 | Bodas de plata | Casual | 8x8 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-011 | 11 | Junto al fuego | Intermedio | 9x9 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-012 | 12 | Un secreto en el desayuno | Intermedio | 9x9 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-013 | 13 | Campanas fuera de hora | Intermedio | 9x9 | 10 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-014 | 14 | El sombrero olvidado | Intermedio | 9x9 | 11 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-015 | 15 | El carruaje retrasado | Casual | 8x8 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-016 | 16 | Tarde de poesía | Casual | 8x8 | 6 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-017 | 17 | Perfume de jazmín | Casual | 8x8 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-018 | 18 | El espejo partido | Intermedio | 9x9 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-019 | 19 | Concierto de cámara | Intermedio | 9x9 | 8 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-020 | 20 | El paraguas negro | Intermedio | 9x9 | 10 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-021 | 21 | El álbum de familia | Intermedio | 9x9 | 11 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-022 | 22 | Día de carreras | Casual | 8x8 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-023 | 23 | Hojas secas | Casual | 8x8 | 6 | T4 (conteo de áreas, regla del asesino, cadena del arma) | no |
| reto-024 | 24 | El tapiz torcido | Casual | 8x8 | 7 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-025 | 25 | Excursión al lago | Intermedio | 9x9 | 8 | T4 (conteo de áreas, regla del asesino, cadena del arma) | no |
| reto-026 | 26 | Partida de cartas | Intermedio | 9x9 | 9 | T4 (conteo de áreas, regla del asesino, cadena del arma) | no |
| reto-027 | 27 | Eclipse de luna | Intermedio | 9x9 | 12 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-028 | 28 | Una herencia en disputa | Intermedio | 9x9 | 12 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |
| reto-029 | 29 | El invitado madrugador | Casual | 8x8 | 5 | T3 (pares, únicos ocultos, confinamiento) | no |
| reto-030 | 30 | La gran noche | Intermedio | 9x9 | 13 | T4 (conteo de áreas, regla del asesino, cadena del arma) | sí |

Resumen del reto: 13 Casual, 17 Intermedio, 9 con arma. Ninguna semilla se repite con la campaña ni entre retos (las del reto parten de 104 y las de campaña son de 3 a 30 con otra combinación de dificultad y arma), y una prueba compara pistas y solución de los 60 casos para confirmar que no hay dos iguales.

## Semillas descartadas y su motivo

Ninguna semilla explorada falló en el generador: en todos los lotes salió caso (0 "SIN CASO"). Por eso los descartes son de tres tipos:

1. **Descartes internos del generador** (mapa o reparto que no sirve y se reintenta dentro de la misma semilla; quedan registrados y no afectan al caso final). Totales por lote en el anexo.
2. **No calza en la curva:** la semilla da un caso válido, pero sus pasos o su técnica no son los que pedía esa plaza de la curva (por ejemplo, 3 pasos cuando se buscaba 8). Es el motivo de casi todas las semillas del anexo.
3. **Texto:** ningún título o premisa fue rechazado por la puerta (sin palabras prohibidas, dentro del largo). Las premisas no nombran personajes, habitaciones ni armas, porque salen del sorteo de cada semilla y la narrativa no puede dar información que las pistas no den (doc 13).

Nota de honestidad: la elección de semillas se hizo mirando estas listas de pasos y técnica; no se jugó ningún caso con personas. Los rangos siguen siendo provisionales hasta la prueba de juego, y algunos casos podrían regenerarse (ADR-0014).

### Anexo: lotes explorados

**Principiante, semillas 1 a 40** (40 explorada(s), 0 sin caso). Usadas: 3, 17, 21.
Descartes internos: 134 × sin reparaciones posibles; 21 × sin pareja víctima-asesino viable; 1 × pasos por debajo del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 3 pasos T3: 2, 11, 22, 25, 26, 27, 28, 32, 34, 40
- 4 pasos T3: 1, 10, 12, 16, 18, 31, 38
- 5 pasos T3: 6, 9, 13, 19, 23, 37, 39
- 6 pasos T3: 7
- 7 pasos T3: 5, 8, 20, 29, 30, 33, 35, 36
- 7 pasos T4: 14, 24
- 8 pasos T4: 15
- 9 pasos T4: 4

**Casual, semillas 1 a 40** (40 explorada(s), 0 sin caso). Usadas: 8, 10, 12.
Descartes internos: 293 × sin reparaciones posibles; 24 × sin pareja víctima-asesino viable; 1 × pasos por debajo del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 4 pasos T3: 5, 15, 24
- 5 pasos T3: 9, 29, 31, 38
- 6 pasos T3: 1, 2, 17, 19, 20, 25, 34
- 6 pasos T4: 26
- 7 pasos T3: 6, 14, 21, 32, 35, 36, 40
- 8 pasos T3: 7, 22, 33, 39
- 8 pasos T4: 28
- 9 pasos T3: 3, 11, 13, 37
- 9 pasos T4: 4, 27
- 10 pasos T3: 16
- 10 pasos T4: 23, 30
- 12 pasos T4: 18

**Casual, semillas 101 a 160** (60 explorada(s), 0 sin caso). Usadas: 104, 106, 112, 115, 116, 117, 132, 138, 140, 141, 145, 149, 154.
Descartes internos: 33 × sin pareja víctima-asesino viable; 527 × sin reparaciones posibles; 2 × pasos por debajo del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 4 pasos T3: 121, 122, 125, 143, 160
- 5 pasos T3: 153
- 6 pasos T3: 126
- 6 pasos T4: 113, 119
- 7 pasos T3: 130, 134, 142, 146, 155, 156
- 7 pasos T4: 102, 103, 124, 128
- 8 pasos T3: 108, 114, 118, 127, 131, 144, 150, 157
- 8 pasos T4: 101, 107, 123, 129, 151
- 9 pasos T3: 136
- 9 pasos T4: 105, 133, 158
- 10 pasos T3: 109, 110
- 10 pasos T4: 120, 137, 148, 152
- 11 pasos T4: 135
- 12 pasos T3: 139
- 12 pasos T4: 111, 147
- 13 pasos T4: 159

**Intermedio, semillas 1 a 40** (40 explorada(s), 0 sin caso). Usadas: 11.
Descartes internos: 407 × sin reparaciones posibles; 24 × sin pareja víctima-asesino viable; 1 × pasos por debajo del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 5 pasos T3: 17, 27
- 6 pasos T3: 1, 9, 22, 39
- 7 pasos T3: 7, 14, 15, 20, 24, 25, 38
- 7 pasos T4: 31, 35
- 8 pasos T3: 4, 8, 12, 21, 28, 33, 34, 36, 37
- 9 pasos T3: 23, 26, 30
- 9 pasos T4: 10, 19, 40
- 10 pasos T3: 2, 3
- 10 pasos T4: 16
- 11 pasos T3: 29, 32
- 11 pasos T4: 5, 18
- 12 pasos T4: 6, 13

**Intermedio, semillas 101 a 150** (50 explorada(s), 0 sin caso). Usadas: 110, 122, 123, 127, 133, 139, 142, 148.
Descartes internos: 581 × sin reparaciones posibles; 40 × sin pareja víctima-asesino viable.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 4 pasos T3: 113, 130, 145
- 5 pasos T3: 106, 109, 116, 117, 120, 126, 138, 140
- 6 pasos T3: 104, 135, 143, 149, 150
- 7 pasos T3: 115, 118, 119, 132, 141
- 7 pasos T4: 105, 147
- 8 pasos T3: 111, 128, 131
- 8 pasos T4: 108, 121, 136
- 9 pasos T3: 103, 114, 144
- 10 pasos T3: 134, 146
- 10 pasos T4: 101, 124, 125
- 11 pasos T4: 107, 137
- 12 pasos T4: 112, 129
- 15 pasos T4: 102

**Intermedio con arma, semillas 1 a 40** (40 explorada(s), 0 sin caso). Usadas: 27, 29, 30.
Descartes internos: 388 × sin reparaciones posibles; 227 × sin pareja víctima-asesino viable; 1 × pasos por debajo del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 4 pasos T3: 16, 17
- 5 pasos T3: 1
- 6 pasos T3: 12, 15, 18, 33, 35
- 7 pasos T3: 4, 14, 22, 26, 36
- 8 pasos T3: 23
- 8 pasos T4: 10, 11, 20, 28, 32
- 9 pasos T3: 3, 21, 24
- 9 pasos T4: 5, 40
- 10 pasos T3: 34
- 10 pasos T4: 9, 31, 37
- 11 pasos T3: 6
- 11 pasos T4: 2, 7, 8, 25, 39
- 12 pasos T3: 13
- 14 pasos T4: 19
- 16 pasos T4: 38

**Intermedio con arma, semillas 101 a 150** (50 explorada(s), 0 sin caso). Usadas: 104, 105, 108, 114, 116, 117, 125, 130, 132.
Descartes internos: 235 × sin pareja víctima-asesino viable; 531 × sin reparaciones posibles; 1 × pasos por encima del rango.

No usadas, agrupadas por pasos y técnica (motivo: no calza en la curva): 

- 4 pasos T3: 106, 111
- 5 pasos T3: 103, 119, 121, 128, 134, 137, 141, 143
- 6 pasos T3: 107, 140, 145, 148, 150
- 7 pasos T3: 115, 118, 120, 131, 146
- 8 pasos T3: 126, 129, 139, 147
- 8 pasos T4: 123, 136, 142
- 9 pasos T3: 101
- 9 pasos T4: 113, 122
- 10 pasos T3: 109
- 10 pasos T4: 133, 144, 149
- 11 pasos T4: 127
- 12 pasos T4: 110, 135
- 13 pasos T4: 112, 138
- 14 pasos T4: 102, 124

## Dónde está todo

- Datos del mundo: `tools/data/mundos/mansion.json` (36 personajes con arquetipo, 11 habitaciones, 10 armas, ninguna de fuego).
- Planes con semillas, títulos y premisas: `tools/data/mundos/mansion-casos.json` y `tools/data/mundos/mansion-reto.json`.
- Regenerar: `dart run bin/enigmatrix.dart build-plan data/mundos/mansion-casos.json --out out/mansion`, luego `catalog-add out/mansion/mansion-*.json --mundo mansion --tipo campana` (y para el reto `--tipo reto --dia-inicio 1`).
- Casos publicados: `app/assets/cases/mansion-01.json` a `mansion-10.json` y `reto-001.json` a `reto-030.json`, más sus entradas en `catalogo.json` (órdenes 21 a 60). `index.json` no cambia: solo lista el banco de pruebas.

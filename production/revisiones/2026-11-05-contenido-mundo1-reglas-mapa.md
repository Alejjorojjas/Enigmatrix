# Contenido del Mundo 1 regenerado con las reglas de mapa (05-11-2026, actualizado 06-11-2026)

Los 40 casos de La Mansión (10 de campaña y 30 de reto) se regeneraron con `build-plan` y el motor con las reglas de mapa (spec 16, sección 1.3.1), el baño añadido al mundo y el tope de 2 muebles del mismo tipo por habitación. Los rangos de dificultad no se tocaron. Los 40 pasan el solver (solución única, deducción pura) y la puerta de contenido con las reglas de mapa exigidas también a la Mansión. Ningún texto se reescribió: cuando una premisa no encajaba con el mapa se cambió la semilla.

## Tope de 2 por habitación (06-11-2026)

Decisión de Alejandro: como máximo 2 muebles del mismo tipo por habitación (`kMaxSameTypePerRoom = 2` en `tools/lib/src/map_rules.dart`; los objetos únicos por habitación siguen en 1). Los mapas cambiaron otra vez y se rehízo la selección de semillas.

- Semillas cambiadas respecto al estado con baño (12 de 40):
  - Campaña: mansion-02 13 a 6; 04 8 a 6; 05 21 a 8; 06 38 a 4; 07 3 a 40; 08 1 a 12; 09 6 a 4; 10 57 a 16.
  - Reto: reto-008 124 a 120; reto-011 166 a 144; reto-012 127 a 121; reto-020 135 a 141.
  - Se conservan mansion-01 (74) y mansion-03 (46), y 26 semillas del reto.
- Motivos: con el tope la curva de campaña se rompía (Casual 7, 7, 6; Intermedio 11, 14, 7, 12) y cuatro retos perdieron algo que nombra su premisa: reto-008 y 012 el Comedor, reto-011 la chimenea, reto-020 el Vestíbulo con perchero.
- Máximo de muebles del mismo tipo en una misma habitación, medido en los 40 casos: 2.
- Máximo de mesas en un mismo mapa: 8 (mansion-08, un 9x9 con 7 habitaciones).
- Semillas del reto (104 a 174) sin repetir con las de la campaña (74 como máximo).

Curva de pasos de la campaña: Principiante 4, 6, 7 (media 5,67); Casual 6, 7, 8 (media 7,0); Intermedio 9, 10, 11, 14 (media 11,0). Dentro de cada tramo no baja y las medias crecen. El arma sigue en mansion-08, 09 y 10.

## Con baño

Se añadió a `tools/data/mundos/mansion.json` la habitación `bano` ("el Baño") con bañera, planta y alfombra. No se añadió lavadora: con tres muebles el baño ya tiene variedad y la lavadora (familia de electrodomésticos, junto a la nevera) obligaría a elegir un solo tipo por mapa y competiría con la nevera de la Cocina sin aportar a ninguna premisa.

- Casos con baño en el mapa: 15 de 40.
- Casos con bañera: 13 de 40 (32,5 %): 3 de la campaña (mansion-01, 05 y 10) y 10 del reto. Dentro del 25 a 40 % pedido.
- El baño puede salir sin bañera (2 casos): la bañera es un mueble que el generador coloca o no.
- Objetos nuevos en los 40 casos: chimenea 21 casos (26 unidades), perchero 28 casos (34), nevera 15 casos (15), bañera 13 casos (13).

## Premisas y mapas

Revisadas las 40 (chequeo automático de estos requisitos). Encajan todas:

- mansion-01 tiene Comedor (y planta y sillón, que exige la prueba QA). mansion-03 tiene Dormitorio con cama. mansion-04 tiene piano.
- reto-011 tiene chimenea. reto-014 y reto-020 tienen perchero; reto-020 además Vestíbulo.
- reto-004 y 019 tienen piano. reto-008 y 012 tienen Comedor. reto-025 tiene Dormitorio. reto-005, 006 y 026 tienen mesa. reto-001 y 017 tienen planta.

Sin premisas pendientes. Las demás son atmosféricas y no nombran nada que el mapa pudiera mostrar.

## Tabla de los 40 casos

Columnas: id, dificultad, semilla antes (estado previo al tope de 2) y después, pasos del solver (nivel máximo de técnica), arma, tipo de asiento (un solo tipo de la familia por mapa), si el mapa tiene baño y si tiene bañera.

| id | dificultad | semilla | pasos | arma | asiento | baño | bañera |
|---|---|---|---|---|---|---|---|
| mansion-01 | principiante | 74 (igual) | 4 (T3) | no | sillon | si | si |
| mansion-02 | principiante | 13->6 | 6 (T3) | no | silla | no | no |
| mansion-03 | principiante | 46 (igual) | 7 (T3) | no | sillon | no | no |
| mansion-04 | casual | 8->6 | 6 (T3) | no | sillon | no | no |
| mansion-05 | casual | 21->8 | 7 (T3) | no | silla | si | si |
| mansion-06 | casual | 38->4 | 8 (T3) | no | silla | no | no |
| mansion-07 | intermedio | 3->40 | 9 (T4) | no | sillon | no | no |
| mansion-08 | intermedio | 1->12 | 10 (T3) | si | silla | no | no |
| mansion-09 | intermedio | 6->4 | 11 (T4) | si | sillon | no | no |
| mansion-10 | intermedio | 57->16 | 14 (T4) | si | silla | si | si |
| reto-001 | casual | 106 (igual) | 5 (T2) | no | silla | no | no |
| reto-002 | casual | 117 (igual) | 8 (T3) | no | sillon | si | si |
| reto-003 | casual | 104 (igual) | 7 (T3) | no | silla | no | no |
| reto-004 | intermedio | 110 (igual) | 8 (T3) | no | sillon | no | no |
| reto-005 | intermedio | 122 (igual) | 12 (T4) | no | silla | si | si |
| reto-006 | intermedio | 114 (igual) | 10 (T4) | si | silla | si | si |
| reto-007 | intermedio | 108 (igual) | 6 (T3) | si | sillon | no | no |
| reto-008 | casual | 124->120 | 6 (T3) | no | sofa | no | no |
| reto-009 | casual | 132 (igual) | 9 (T3) | no | silla | si | si |
| reto-010 | casual | 112 (igual) | 6 (T3) | no | sillon | si | no |
| reto-011 | intermedio | 166->144 | 7 (T3) | no | silla | no | no |
| reto-012 | intermedio | 127->121 | 9 (T3) | no | silla | no | no |
| reto-013 | intermedio | 116 (igual) | 10 (T3) | si | silla | si | si |
| reto-014 | intermedio | 119 (igual) | 11 (T4) | si | silla | no | no |
| reto-015 | casual | 140 (igual) | 8 (T3) | no | silla | no | no |
| reto-016 | casual | 151 (igual) | 6 (T3) | no | silla | no | no |
| reto-017 | casual | 115 (igual) | 9 (T4) | no | silla | no | no |
| reto-018 | intermedio | 133 (igual) | 6 (T3) | no | silla | no | no |
| reto-019 | intermedio | 139 (igual) | 6 (T3) | no | silla | no | no |
| reto-020 | intermedio | 135->141 | 12 (T4) | si | sillon | no | no |
| reto-021 | intermedio | 125 (igual) | 6 (T3) | si | sillon | si | si |
| reto-022 | casual | 145 (igual) | 7 (T3) | no | sillon | si | si |
| reto-023 | casual | 154 (igual) | 8 (T3) | no | sillon | no | no |
| reto-024 | casual | 116 (igual) | 8 (T3) | no | sillon | si | si |
| reto-025 | intermedio | 142 (igual) | 12 (T4) | no | sofa | si | si |
| reto-026 | intermedio | 148 (igual) | 7 (T3) | no | silla | no | no |
| reto-027 | intermedio | 132 (igual) | 8 (T4) | si | silla | no | no |
| reto-028 | intermedio | 104 (igual) | 8 (T3) | si | silla | no | no |
| reto-029 | casual | 174 (igual) | 5 (T3) | no | sillon | si | no |
| reto-030 | intermedio | 105 (igual) | 6 (T3) | si | sillon | si | si |

## Cambios de pruebas

`tools/test/support/regeneracion_pendiente.dart`: `kMundo1PendienteDeRegenerar = false`. La puerta de contenido exige las reglas de mapa a la Mansión y corren los 2 tests de reproducibilidad. Se conserva el interruptor (a false) porque `content_gate_test.dart` lo usa en su prueba de coherencia. `qa_mapa_independiente_test.dart` no se editó: depende de mansion-01 (planta y sillón), mansion-03 (último objeto fuera del baño) y mansion-04 (piano en una habitación con otro mueble), y las semillas elegidas lo cumplen.

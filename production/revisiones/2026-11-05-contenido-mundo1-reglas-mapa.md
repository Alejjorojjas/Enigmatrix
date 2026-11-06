# Contenido del Mundo 1 regenerado con las reglas de mapa (05-11-2026)

Los 40 casos de La Mansión (10 de campaña y 30 de reto) se regeneraron con `build-plan` y el motor con las reglas de mapa (spec 16, sección 1.3.1) y, en la última pasada, con el baño añadido al mundo. Los rangos de dificultad no se tocaron. Los 40 pasan el solver (solución única, deducción pura) y la puerta de contenido con las reglas de mapa exigidas también a la Mansión. Ningún texto se reescribió: cuando una premisa no encajaba con el mapa se cambió la semilla.

## Con baño

Se añadió a `tools/data/mundos/mansion.json` la habitación `bano` ("el Baño") con bañera, planta y alfombra. No se añadió lavadora: con tres muebles el baño ya tiene variedad y la lavadora (familia de electrodomésticos, junto a la nevera) obligaría a elegir un solo tipo por mapa y competiría con la nevera de la Cocina sin aportar a ninguna premisa.

Como el baño es una habitación más, cambió el reparto aleatorio de habitaciones y todos los mapas salieron distintos; se regeneraron los 40 casos y se rehizo la curva.

- Casos con baño en el mapa: 20 de 40.
- Casos con bañera: 15 de 40 (37,5 %): 3 de la campaña (mansion-01, 05 y 10) y 12 del reto. Está dentro del 25 a 40 % pedido. El baño puede salir sin bañera (5 casos): la bañera es un mueble que el generador coloca o no.
- Para no pasar del 40 %, en el reto se eligieron sin bañera las semillas nuevas de reto-008, 014, 016, 020 y 029.

Semillas cambiadas respecto al estado anterior al baño (15 de 40):

- Campaña: mansion-01 50 a 74; 02 9 a 13; 03 67 a 46; 04 4 a 8; 05 15 a 21; 06 12 a 38; 07 11 a 3; 08 8 a 1; 09 12 a 6; 10 33 a 57.
- Reto: reto-008 138 a 124; reto-014 161 a 119; reto-016 141 a 151; reto-020 155 a 135; reto-029 149 a 174. Las otras 25 semillas del reto se conservan.
- Las semillas del reto (104 a 174) no chocan con las de la campaña (menores que 80).

Curva de pasos de la campaña: Principiante 4, 6, 7 (media 5,67); Casual 6, 7, 8 (media 7,0); Intermedio 9, 10, 11, 13 (media 10,75). Dentro de cada tramo no baja y las medias crecen.

Cambios en pruebas: `map_rules_test.dart` (la tabla pactada del Mundo 1 incluye `bano`; "La Mansión no tiene bañeras" pasó a "la bañera aparece"). `qa_mapa_independiente_test.dart` no se editó: sus comprobaciones dependen del contenido de mansion-01 (necesita planta y sillón), mansion-03 (último objeto fuera del baño) y mansion-04 (piano en una habitación con otro mueble), por lo que las semillas de esos casos se eligieron para cumplirlas.

## Premisas y mapas

Revisadas las 40 (chequeo automático de estos requisitos). Encajan todas:

- mansion-01 tiene Comedor. mansion-03 tiene Dormitorio con cama. mansion-04 tiene piano.
- reto-011 tiene chimenea. reto-014 y reto-020 tienen perchero; reto-020 además Vestíbulo.
- reto-004 y 019 tienen piano. reto-008 y 012 tienen Comedor. reto-025 tiene Dormitorio. reto-005, 006 y 026 tienen mesa. reto-001 y 017 tienen planta.

Sin premisas pendientes. Las demás son atmosféricas y no nombran nada que el mapa pudiera mostrar.

## Tabla de los 40 casos

Columnas: id, dificultad, semilla antes (estado previo al baño) y después, pasos del solver (nivel máximo de técnica), arma, tipo de asiento (un solo tipo de la familia por mapa), si el mapa tiene baño y si tiene bañera.

| id | dificultad | semilla | pasos | arma | asiento | baño | bañera |
|---|---|---|---|---|---|---|---|
| mansion-01 | principiante | 50->74 | 4 (T3) | no | sillon | si | si |
| mansion-02 | principiante | 9->13 | 6 (T4) | no | sillon | no | no |
| mansion-03 | principiante | 67->46 | 7 (T3) | no | sillon | no | no |
| mansion-04 | casual | 4->8 | 6 (T3) | no | silla | no | no |
| mansion-05 | casual | 15->21 | 7 (T3) | no | sofa | si | si |
| mansion-06 | casual | 12->38 | 8 (T3) | no | sillon | si | no |
| mansion-07 | intermedio | 11->3 | 9 (T3) | no | sillon | no | no |
| mansion-08 | intermedio | 8->1 | 10 (T3) | si | silla | no | no |
| mansion-09 | intermedio | 12->6 | 11 (T4) | si | silla | no | no |
| mansion-10 | intermedio | 33->57 | 13 (T4) | si | silla | si | si |
| reto-001 | casual | 106 (igual) | 6 (T3) | no | sillon | si | si |
| reto-002 | casual | 117 (igual) | 6 (T4) | no | sillon | no | no |
| reto-003 | casual | 104 (igual) | 11 (T3) | no | silla | no | no |
| reto-004 | intermedio | 110 (igual) | 7 (T3) | no | silla | no | no |
| reto-005 | intermedio | 122 (igual) | 8 (T4) | no | sillon | no | no |
| reto-006 | intermedio | 114 (igual) | 5 (T3) | si | silla | no | no |
| reto-007 | intermedio | 108 (igual) | 6 (T3) | si | sillon | no | no |
| reto-008 | casual | 138->124 | 6 (T3) | no | silla | si | no |
| reto-009 | casual | 132 (igual) | 9 (T3) | no | silla | si | si |
| reto-010 | casual | 112 (igual) | 9 (T4) | no | silla | no | no |
| reto-011 | intermedio | 166 (igual) | 8 (T3) | no | sillon | no | no |
| reto-012 | intermedio | 127 (igual) | 8 (T3) | no | silla | si | si |
| reto-013 | intermedio | 116 (igual) | 8 (T4) | si | sillon | si | si |
| reto-014 | intermedio | 161->119 | 7 (T3) | si | sillon | no | no |
| reto-015 | casual | 140 (igual) | 4 (T2) | no | silla | no | no |
| reto-016 | casual | 141->151 | 6 (T3) | no | silla | si | no |
| reto-017 | casual | 115 (igual) | 7 (T3) | no | silla | no | no |
| reto-018 | intermedio | 133 (igual) | 7 (T3) | no | sillon | no | no |
| reto-019 | intermedio | 139 (igual) | 5 (T3) | no | silla | si | si |
| reto-020 | intermedio | 155->135 | 12 (T4) | si | silla | no | no |
| reto-021 | intermedio | 125 (igual) | 9 (T4) | si | silla | si | si |
| reto-022 | casual | 145 (igual) | 7 (T3) | no | sillon | si | si |
| reto-023 | casual | 154 (igual) | 8 (T3) | no | sillon | si | si |
| reto-024 | casual | 116 (igual) | 7 (T3) | no | silla | si | si |
| reto-025 | intermedio | 142 (igual) | 7 (T4) | no | sofa | si | si |
| reto-026 | intermedio | 148 (igual) | 8 (T4) | no | silla | si | si |
| reto-027 | intermedio | 132 (igual) | 5 (T3) | si | silla | no | no |
| reto-028 | intermedio | 104 (igual) | 7 (T3) | si | silla | si | no |
| reto-029 | casual | 149->174 | 5 (T3) | no | sillon | si | no |
| reto-030 | intermedio | 105 (igual) | 12 (T4) | si | sillon | si | si |

## Objetos nuevos en los 40 casos

- Chimenea: 28 casos (30 unidades).
- Perchero: 15 casos (18 unidades).
- Bañera: 15 casos (15 unidades).
- Nevera: 12 casos (12 unidades).

## Cambios de pruebas (resto)

`tools/test/support/regeneracion_pendiente.dart`: `kMundo1PendienteDeRegenerar = false`. La puerta de contenido exige ya las reglas de mapa a la Mansión y corren los 2 tests de reproducibilidad. Se conserva el interruptor (a false) porque `content_gate_test.dart` lo usa en su prueba de coherencia.

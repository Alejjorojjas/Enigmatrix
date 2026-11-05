# Contenido del Mundo 1 regenerado con las reglas de mapa (05-11-2026)

Los 40 casos de La Mansión (10 de campaña y 30 de reto) se regeneraron con `build-plan` y el motor con las reglas de mapa (spec 16, sección 1.3.1). Los rangos de dificultad no se tocaron. Los 40 pasan el solver (solución única, deducción pura) y la puerta de contenido con las reglas de mapa exigidas también a la Mansión. Ningún texto se reescribió: cuando una premisa no encajaba con el mapa se cambió la semilla.

## Cambios de semilla

Campaña (`tools/data/mundos/mansion-casos.json`), para recuperar la curva creciente y para que cada premisa encaje con su mapa:

- mansion-01: 21 a 50 (Comedor para "Cena de bienvenida")
- mansion-02: 3 a 9
- mansion-03: 17 a 67 (Dormitorio con cama para "Tormenta en la colina")
- mansion-04: 8 a 4 (piano y Sala de Música para "La noche del piano")
- mansion-05: 10 a 15
- mansion-08: 29 a 8 (con arma)
- mansion-09: 27 a 12 (con arma)
- mansion-10: 30 a 33 (con arma)

Sin cambio: mansion-06 (12) y mansion-07 (11).

Reto (`tools/data/mundos/mansion-reto.json`), solo 3 de 30, por premisa que nombra algo que el mapa no tenía:

- reto-011 "Junto al fuego": 123 a 166 (el mapa tiene chimenea).
- reto-014 "El sombrero olvidado": 117 a 161 (el mapa tiene perchero, antes no).
- reto-020 "El paraguas negro": 130 a 155 (el mapa tiene Vestíbulo y perchero; "en la entrada" antes no tenía dónde).

Las 27 semillas restantes del reto se conservan. Las semillas del reto (104 a 214) no chocan con las de la campaña (menores que 70).

Curva de pasos del solver: Principiante 4, 6, 8 (media 6,0); Casual 6, 7, 8 (media 7,0); Intermedio 9, 10, 12, 14 (media 11,25).

## Tabla de los 40 casos

Columnas: id, dificultad, semilla antes y después, pasos del solver (nivel máximo de técnica), arma, tipo de asiento usado en el mapa (cada mapa usa un solo tipo de la familia).

| id | dificultad | semilla | pasos | arma | asiento |
|---|---|---|---|---|---|
| mansion-01 | principiante | 21->50 | 4 (T3) | no | sillon |
| mansion-02 | principiante | 3->9 | 6 (T3) | no | silla |
| mansion-03 | principiante | 17->67 | 8 (T3) | no | silla |
| mansion-04 | casual | 8->4 | 6 (T3) | no | silla |
| mansion-05 | casual | 10->15 | 7 (T3) | no | silla |
| mansion-06 | casual | 12 (igual) | 8 (T3) | no | sillon |
| mansion-07 | intermedio | 11 (igual) | 9 (T3) | no | sillon |
| mansion-08 | intermedio | 29->8 | 10 (T4) | si | sillon |
| mansion-09 | intermedio | 27->12 | 12 (T4) | si | silla |
| mansion-10 | intermedio | 30->33 | 14 (T4) | si | silla |
| reto-001 | casual | 106 (igual) | 6 (T3) | no | silla |
| reto-002 | casual | 117 (igual) | 5 (T3) | no | silla |
| reto-003 | casual | 104 (igual) | 6 (T3) | no | silla |
| reto-004 | intermedio | 110 (igual) | 5 (T3) | no | silla |
| reto-005 | intermedio | 122 (igual) | 5 (T3) | no | silla |
| reto-006 | intermedio | 114 (igual) | 9 (T3) | si | silla |
| reto-007 | intermedio | 108 (igual) | 9 (T3) | si | sillon |
| reto-008 | casual | 138 (igual) | 9 (T3) | no | silla |
| reto-009 | casual | 132 (igual) | 7 (T3) | no | sillon |
| reto-010 | casual | 112 (igual) | 9 (T4) | no | sillon |
| reto-011 | intermedio | 123->166 | 11 (T3) | no | silla |
| reto-012 | intermedio | 127 (igual) | 8 (T3) | no | silla |
| reto-013 | intermedio | 116 (igual) | 12 (T4) | si | silla |
| reto-014 | intermedio | 117->161 | 13 (T3) | si | silla |
| reto-015 | casual | 140 (igual) | 11 (T4) | no | silla |
| reto-016 | casual | 141 (igual) | 9 (T3) | no | silla |
| reto-017 | casual | 115 (igual) | 11 (T3) | no | sillon |
| reto-018 | intermedio | 133 (igual) | 9 (T4) | no | silla |
| reto-019 | intermedio | 139 (igual) | 8 (T3) | no | silla |
| reto-020 | intermedio | 130->155 | 12 (T4) | si | sillon |
| reto-021 | intermedio | 125 (igual) | 13 (T4) | si | silla |
| reto-022 | casual | 145 (igual) | 8 (T3) | no | sillon |
| reto-023 | casual | 154 (igual) | 11 (T4) | no | silla |
| reto-024 | casual | 116 (igual) | 6 (T3) | no | silla |
| reto-025 | intermedio | 142 (igual) | 5 (T3) | no | sillon |
| reto-026 | intermedio | 148 (igual) | 10 (T3) | no | sillon |
| reto-027 | intermedio | 132 (igual) | 10 (T4) | si | silla |
| reto-028 | intermedio | 104 (igual) | 13 (T4) | si | sillon |
| reto-029 | casual | 149 (igual) | 6 (T3) | no | silla |
| reto-030 | intermedio | 105 (igual) | 9 (T3) | si | sillon |
## Objetos nuevos en los 40 casos

- Perchero: 23 casos (31 unidades en total).
- Chimenea: 17 casos (19 unidades).
- Nevera: 16 casos (16 unidades).
- Bañera: 0 casos. La Mansión no tiene habitación de baño en `mansion.json`, así que la regla de habitación coherente la deja fuera. Si Alejandro la quiere en el Mundo 1, hace falta añadir un baño al mundo (decisión de contenido, no se ha tocado).

## Premisas y mapas

Revisadas las 40. Con las semillas actuales, las premisas de la campaña y del reto con elementos concretos encajan con su mapa (piano, Comedor, Dormitorio, chimenea, Vestíbulo, perchero, mesa). Sin pendientes.

Las premisas que quedan sin objeto exacto son atmosféricas (una carta, un eco en la escalera, el gato, un espejo, campanas) y no nombran nada que el mapa pudiera mostrar, por lo que no se tocaron.

## Cambios de pruebas

`tools/test/support/regeneracion_pendiente.dart`: `kMundo1PendienteDeRegenerar = false`. La puerta de contenido exige ya las reglas de mapa a la Mansión y corren los 2 tests de reproducibilidad. Se conserva el interruptor (a false) porque `content_gate_test.dart` lo usa en su prueba de coherencia.

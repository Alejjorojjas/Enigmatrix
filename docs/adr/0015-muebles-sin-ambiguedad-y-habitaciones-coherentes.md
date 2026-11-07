# ADR-0015: Muebles sin ambigüedad y habitaciones coherentes

- **Estado**: Aceptado
- **Fecha**: 05-11-2026
- **Decisores**: usuario (Alejandro) / arquitecto

## Contexto

La prueba de juego n.º 1 se hizo con la 0.3.0+3 y amigos de Alejandro.

- **Dificultad:** les pareció bien "por ahora".
- **Confusión con "silla":** una pista como "al lado de una silla" se puede entender también como un sillón o un sofá. Casi todos los casos mezclaban esos asientos en el mismo mapa: 8 de 10 del Mundo 1, 27 de 30 retos y 18 de 21 casos de prueba.
- **Habitaciones incoherentes:** a los probadores les extrañó ver dos camas en una misma habitación y les pareció ver una cama en una cocina. En los casos de la 0.6.0+6 no había ninguna cama fuera del dormitorio, así que lo más probable es que leyeran la barra o la alfombra como una cama.

## Decisión

1. **Familias de muebles parecidos.** Un mapa usa como mucho un tipo de cada familia:
   - asientos: silla, sillón y sofá;
   - superficies: mesa y barra;
   - plantas: planta y arbusto;
   - almacenaje: armario y caja;
   - electrodomésticos: nevera y lavadora.

   Repetir el mismo tipo sí está permitido, por ejemplo varias sillas.
2. **Únicos por habitación.** En un área no puede haber dos de estos: cama, alfombra, TV, lavadora, piano, barra, perchero, bañera, nevera y chimenea.
3. **Muebles coherentes con la habitación.** La tabla de habitación y muebles permitidos está en `tools/lib/src/map_rules.dart` (`kRoomFurniture`). Por ejemplo, la cama solo va en el dormitorio.
4. **Objetos nuevos**, todos bloquean su casilla:
   - perchero (vestíbulo, dormitorio, pasillo);
   - bañera (baño);
   - nevera (cocina);
   - chimenea (salón, biblioteca).
5. **Dibujos más claros:**
   - la silla es de madera, sin cojín;
   - la barra tiene tapa de piedra;
   - la alfombra lleva guarda y medallón, para no confundirse con una cama.
6. **Rangos de dificultad:** no se tocan.
7. **Puerta de contenido.** Exige estas reglas a todo el contenido publicado. Quedan exentos el banco de pruebas y el tutorial, que no se regeneraron.
8. Como máximo 2 del mismo mueble por habitación (decisión del 06-11-2026).

## Alternativas consideradas

- **Juntar silla, sillón y sofá en un solo "asiento" para las pistas.** Elimina la confusión, pero quita variedad al mapa.
- **Solo mejorar los dibujos.** No hacía falta regenerar, pero la palabra "silla" seguía siendo ambigua.

## Consecuencias

- **Casos regenerados.** Se regeneraron los 10 casos del Mundo 1 y los 30 retos. En 6 casos de la campaña y 3 retos se cambió la semilla para conservar la curva de pasos y para que cada premisa encaje con su mapa. El detalle está en `production/revisiones/2026-11-05-contenido-mundo1-reglas-mapa.md`.
- **Bañera.** ~~La Mansión no tiene baño, así que la bañera no aparece en el Mundo 1.~~ ACTUALIZACIÓN 05-11-2026: se agregó "el Baño" a la Mansión (0.7.1+8). En la 0.7.2+9 hay bañera en 13 de los 40 casos.
- **Élite.** Con las reglas nuevas, el generador no saca casos Élite (16×16) en la medición. Ya estaba fuera de la V1 (ADR-0014) y necesita trabajo de motor para la V2.
- **Especificación.** La spec 16 (sección 1.3.1) recoge las reglas. Es la versión 0.7.0+7.

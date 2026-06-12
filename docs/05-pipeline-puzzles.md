# Enigmatrix - Pipeline de puzzles

## Objetivo de este documento
Definir como se crean, validan y publican los casos de Enigmatrix.

Cubre:

- estrategia general de generacion
- solver y validacion de unicidad
- calibracion de dificultad
- volumen de contenido necesario para V1
- pipeline editorial y de publicacion
- almacenamiento y entrega

## Estrategia general

> **ACTUALIZACIÓN 2026-06-11 (decisión del usuario en playtest):** los mapas
> TAMBIÉN se generan proceduralmente — cada caso tiene su propia distribución
> de habitaciones, muebles y armas (dos casos nunca comparten mapa). Lo que
> se "autora a mano" pasa a ser la PIEL artística de cada mundo (paletas,
> sprites de muebles, texturas) que se aplica sobre el mapa generado en
> Fase 2 con los mockups. Los roles editoriales y el resto del pipeline de
> este documento siguen vigentes. Spec del generador de mapas:
> `docs/16-spec-puzzle.md` §1.3 y `tools/lib/src/map_generator.dart`.

### Modelo original (superado, se conserva como referencia)
- Mapas visuales: `autorados a mano`
- Casos sobre cada mapa: `generados proceduralmente y validados por solver`

### Por que hibrido
- Los mapas son arte visual con identidad de mundo, deben hacerse a mano.
- Los casos son combinaciones logicas de quien-donde-arma-pistas, escalan mal a mano y bien a generador.
- El solver garantiza que cada caso generado tiene `solucion unica` y `se resuelve por deduccion pura`.

### Lo que un mapa autorado define
- layout de habitaciones
- objetos visibles fijos
- conexiones logicas entre habitaciones si aplica
- armas potenciales visibles que pueden aparecer
- arte y estilo visual del mundo

### Lo que el generador procedural decide
- numero de sospechosos del caso
- numero de habitaciones activas en el caso
- ubicacion de cada sospechoso
- ubicacion de la victima
- arma homicida correcta cuando aplica
- conjunto de pistas
- dificultad final segun metricas

## Solver y validacion

### Reglas que todo caso debe cumplir antes de publicarse
- tiene `exactamente una` solucion completa
- la solucion se alcanza por `deduccion pura`, sin adivinanza
- todas las pistas son `consistentes` con la solucion
- ninguna pista es `redundante` mas alla de un margen permitido
- el numero minimo de pasos de deduccion cae dentro del rango de su etiqueta de dificultad

### Componentes del solver
- motor logico que resuelve el caso simulando al jugador
- verificador de unicidad que prueba que no existe otra solucion valida
- analizador de dependencias entre pistas
- contador de pasos de deduccion necesarios
- detector de pistas redundantes

### Politica ante fallos del solver
- caso descartado si admite mas de una solucion
- caso descartado si requiere adivinanza en algun punto
- caso descartado si fuera del rango de dificultad objetivo
- caso registrado con su razon de descarte para mejorar el generador

## Calibracion de dificultad

### Etiquetas oficiales
- Principiante
- Casual
- Intermedio
- Experto
- Elite

### Metricas que definen dificultad
- numero de sospechosos en el caso
- numero de habitaciones activas
- numero de pistas
- distribucion de tipos de pista
- numero de pasos de deduccion
- profundidad maxima de razonamiento encadenado
- presencia de arma homicida
- numero de armas potenciales visibles
- numero de pistas dedicadas al arma

### Rangos base por etiqueta
Estos son rangos de partida, se ajustan con datos reales tras playtest.

#### Principiante
- sospechosos: 3
- habitaciones activas: 3
- pistas: 4 a 5
- pasos de deduccion: hasta 4
- arma: no

#### Casual
- sospechosos: 4
- habitaciones activas: 4
- pistas: 5 a 7
- pasos de deduccion: 5 a 8
- arma: opcional, simplificada

#### Intermedio
- sospechosos: 5
- habitaciones activas: 4 a 5
- pistas: 7 a 9
- pasos de deduccion: 9 a 14
- arma: opcional, normal

#### Experto
- sospechosos: 6
- habitaciones activas: 5 a 6
- pistas: 9 a 12
- pasos de deduccion: 15 a 22
- arma: opcional, con mas armas potenciales visibles

#### Elite
- sospechosos: 6 a 7
- habitaciones activas: 6
- pistas: 11 a 14
- pasos de deduccion: 23 o mas
- arma: opcional, varias armas potenciales y pistas por categoria

### Reajuste con datos
Tras lanzamiento se reajustan rangos usando:

- tiempo medio real por etiqueta
- tasa de error real
- tasa de uso de ayudas
- tasa de abandono

## Tipos de pista

### Categorias de pista soportadas en V1
- ubicacion directa: `X esta en Y`
- ubicacion negativa: `X no esta en Y`
- ubicacion relativa: `X esta junto a Y`
- relacion entre personas: `X esta en la misma habitacion que Y`
- exclusion: `X no esta con Y`
- pista de arma por habitacion: `el arma esta en Y`
- pista de arma por tipo: `el arma es de tipo Z`
- pista de arma especifica: `el arma es W`
- pista de victima: `la victima esta en Y`

### Reglas de uso de pistas
- el generador balancea tipos para que la dificultad coincida con la etiqueta
- en `Principiante` solo se usan pistas directas y negativas simples
- pistas de arma solo en casos que incluyen arma homicida
- ninguna pista debe contradecir otra
- ninguna pista debe ser deducible trivialmente de otra ya dada

## Volumen de contenido para V1

### Mapas autorados por mundo
Recomendacion inicial:

- Mundo 0 Tutorial: 1 mapa guiado
- Mundo 1 Mansion: 10 mapas
- Mundo 2 Hotel: 10 mapas
- Mundo 3 Museo: 10 mapas
- Mundo 4 Tren: 10 mapas
- Mundo 5 Hospital: 10 mapas

Total V1: 1 mapa tutorial + 50 mapas de campana

### Variaciones por mapa
Cada mapa autorado debe poder generar al menos:

- 1 caso oficial de campana
- N casos de practica con casos distintos sobre el mismo mapa
- M casos elegibles para el reto diario

Numero exacto de N y M se define al cerrar el generador, pero el objetivo es:

- mapa autorado reutilizable para muchos casos sin que se sienta repetido
- casos distintos por sospechosos, victima, arma y pistas

### Reto diario en V1
- 1 caso por dia
- meta minima: stock listo y aprobado para `60 dias` antes del lanzamiento
- meta saludable: stock listo para `120 dias`
- tras lanzamiento: la cola de reto diario se mantiene como minimo a 30 dias por delante

### Distribucion de dificultad del reto diario
Recomendacion:

- 2 dias por semana: Casual
- 3 dias por semana: Intermedio
- 1 dia por semana: Experto
- 1 dia por semana: Elite

Sin Principiante. La distribucion se revisa con datos reales.

## Pipeline editorial

### Roles
- autor de mapas: crea el layout visual y logico de cada mapa
- generador automatico: produce candidatos de caso sobre cada mapa
- solver: valida unicidad y dificultad de cada candidato
- revisor: aprueba o rechaza casos antes de publicacion
- programador de reto diario: arma el calendario diario

### Flujo de creacion de un mapa
1. Autor define layout, habitaciones, objetos, armas potenciales visibles.
2. Mapa se registra en el catalogo con metadatos: mundo, identificador, lista de armas posibles.
3. Generador produce un primer lote de casos candidatos.
4. Solver filtra los validos.
5. Revisor escoge cuales pasan a publicacion.
6. Mapa queda disponible como base para casos oficiales, practica y reto diario.

### Flujo de creacion de un caso
1. Generador toma un mapa base y una etiqueta de dificultad objetivo.
2. Genera distribucion de sospechosos, victima, arma si aplica, y pistas.
3. Solver valida unicidad y dificultad.
4. Si pasa, queda en cola de candidatos aprobados.
5. Revisor confirma calidad subjetiva.
6. Caso pasa a uno de los buckets:
   - oficial de campana
   - practica
   - elegible para reto diario

### Flujo de publicacion del reto diario
1. Programador toma de la cola elegible.
2. Asigna un caso por dia segun la distribucion semanal.
3. Calendario queda visible solo para el equipo, no para jugadores.
4. La app obtiene el caso del dia desde servidor.
5. Una vez publicado, el caso queda fuera del pool de practica y oficial.

### Reglas de exclusion
- un caso oficial de campana no se reutiliza como reto diario
- un caso de reto diario no vuelve a campana
- un caso usado en practica puede repetirse para otro jugador, pero nunca para el mismo
- un caso descartado por solver nunca se publica

## Validacion en cliente y servidor

### Generacion
- offline en pipeline propio del equipo, no en cliente
- el cliente nunca genera casos

### Almacenamiento del caso
- definicion completa del caso vive en servidor
- el cliente recibe solo lo necesario para jugar el caso actual
- el cliente no recibe la solucion durante la partida

### Validacion de la solucion al pulsar Resolver
- el resultado oficial se valida en servidor
- el cliente puede hacer una validacion previa rapida para feedback inmediato
- el ranking, los puntos, las vidas y la racha solo se actualizan tras validacion del servidor
- en caso de discrepancia, manda el servidor

### Rotacion del mapa
- la rotacion es solo visual y de presentacion, no cambia la solucion
- el cliente aplica la rotacion sobre la misma definicion logica
- el servidor no necesita conocer la rotacion para validar

## Almacenamiento y datos del caso

### Definicion de un caso
Cada caso almacena al menos:

- identificador unico
- mapa base
- mundo
- etiqueta de dificultad
- tipo: oficial, practica, reto diario, tutorial
- lista de sospechosos
- ubicacion de cada sospechoso
- ubicacion de la victima
- arma homicida si aplica
- lista de armas potenciales visibles
- lista de pistas en orden
- metricas calculadas: pasos de deduccion, conteo de pistas, dependencias

### Datos derivados que el cliente nunca recibe en partida
- solucion explicita
- arma homicida correcta
- mapa de dependencias entre pistas
- categoria exacta del arma

Estos solo se envian al cliente al cerrar el caso correctamente o al revelarlos en el resumen.

## Herramientas internas

### Necesarias para V1
- editor de mapas para autores
- runner del generador con seleccion de mapa y dificultad objetivo
- visor de casos candidatos para el revisor
- panel del calendario de reto diario
- visor de metricas por caso

### Pueden esperar a post V1
- editor visual web del calendario
- analitica avanzada de dificultad real vs etiquetada
- panel de salud de stock
- generador con feedback de jugador

## Riesgos y mitigaciones

### Riesgo: stock de reto diario insuficiente
Mitigacion:

- empezar a generar reto diario antes que campana
- meta de 120 dias listos antes del lanzamiento
- alarma cuando la cola caiga de 30 dias

### Riesgo: dificultad real desalineada con la etiqueta
Mitigacion:

- analitica de tiempo real por caso
- recalibracion de rangos por etiqueta cada cierto tiempo
- bucket de casos `mal calibrados` que se revisan y se re etiquetan

### Riesgo: percepcion de repeticion sobre el mismo mapa
Mitigacion:

- limite por jugador a casos por mapa visto
- variacion fuerte de sospechosos, victima y arma entre casos del mismo mapa
- rotacion del mapa visual ya ayuda aunque no es suficiente sola

### Riesgo: solver lento ante casos complejos en Elite
Mitigacion:

- limite de tiempo por intento del solver
- generador descarta candidatos no resueltos en el limite
- optimizacion del solver con poda y heuristicas si se vuelve cuello de botella

### Riesgo: filtrado del banco de casos
Mitigacion:

- nunca se entrega la solucion al cliente
- validacion oficial siempre en servidor
- ofuscacion del payload del caso enviado al cliente
- rotacion de mapa por jugador como capa adicional

## Pendientes que dependen de otras decisiones

- numero exacto N de casos por mapa
- limites concretos de tiempo del solver
- formato exacto del payload de caso enviado al cliente
- politica de versionado de un caso si se corrige tras publicacion
- politica de retirada de un caso si se detecta error post publicacion
- regla exacta de cuanto tiempo de reto diario expirado sigue siendo jugable

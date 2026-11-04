# Enigmatrix - Pipeline de puzzles

> ACTUALIZACIÓN 04-11-2026 (auditoría H-33, H-40, H-42, H-43, H-51), vale para TODO el cuerpo de este documento: este documento está **en revisión**. Se escribió antes de que existiera el generador y describe un pipeline editorial ideal. Lo que hay hoy en el código es más simple: el CLI de `tools/` genera un JSON por semilla, ese JSON se copia a mano a `app/assets/cases` y se lista en `index.json` (ver "Flujo real de generación" más abajo). Concretamente:
> - Todo lo que habla de **mapas autorados a mano, editor de mapas, catálogo de mapas o "50 mapas de campaña"** está **SUPERADO** desde el 11-06-2026: cada caso lleva su propio mapa generado. Se conserva como historia.
> - Los **rangos de dificultad** de este documento quedan marcados como "recalibración pendiente con los datos de la prueba de juego (etapa 1) y el arreglo del generador (etapa 3; H-40)". No los uses como referencia.
> - Lo que prometía el solver y el código no hace (detector de redundancia, límite de tiempo) está marcado **NO IMPLEMENTADO (H-42)**.
> - **No hay catálogo ni id único de caso (H-43)**, y las hojas imprimibles de `production/fase0-casos` no corresponden a los casos de la app (H-51).
> - La parte de servidor (casos en servidor, validación oficial, reto diario) es la **etapa 5**; hoy no existe backend.
> - El volumen de contenido y el reto diario están **PENDIENTES DE DECISIÓN** (ver más abajo).
>
> Fuentes verificadas: `tools/bin/enigmatrix.dart`, `tools/lib/src/case_factory.dart`, `generator.dart`, `app/lib/src/data/case_repository.dart` y `app/assets/cases`. La spec vigente del motor es `docs/16-spec-puzzle.md`.

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
>
> Nota 04-11-2026: la frase "el resto del pipeline de este documento siguen vigentes" queda matizada por el aviso del 04-11-2026 al inicio del documento: los roles y herramientas editoriales descritos más abajo son diseño, no algo que exista hoy.

### Flujo real de generación (comprobado el 04-11-2026)

Esto es lo que se hace hoy, de punta a punta:

1. **Generar.** Desde `tools/` se corre el CLI: `dart run bin/enigmatrix.dart generate --difficulty principiante|casual|intermedio|experto|elite [--count N] [--seed S] [--weapons] [--out DIR]`. (El texto de ayuda del CLI solo nombra tres dificultades, pero el código acepta las cinco.) Por cada semilla (`S`, `S+1`, ...) `CaseFactory` genera un mapa propio y un caso, y el CLI escribe **un archivo JSON por semilla** en la carpeta `--out` (por defecto `tools/out`), con nombre `caso-<dificultad>-s<semilla>.json`.
2. **Revisar.** `dart run bin/enigmatrix.dart show ARCHIVO.json` imprime la hoja del caso (con `--solution` muestra la solución) y `validate ARCHIVO.json` comprueba el caso: validador, deducción pura, unicidad de la solución y que el payload del cliente no filtre la solución. Es la única "revisión" que existe; no hay visor de candidatos ni cola de aprobación.
3. **Publicar en la app.** El JSON aprobado se **copia a mano** a `app/assets/cases/` y su nombre se **agrega a mano** a la lista de `app/assets/cases/index.json`. La app carga esa lista al arrancar (`case_repository.dart`) y ordena los casos por dificultad y luego por id como texto.
4. Hoy hay 20 casos en la app: 8 Principiante, 7 Casual (2 con arma) y 5 Intermedio. No hay casos de Experto ni Élite (H-39).

Límites de este flujo, todos pendientes de la etapa 3:
- **No hay catálogo ni id único (H-43).** El id del caso es `caso-<dificultad>-s<semilla>`, derivado de la semilla. No hay manifiesto con estado (candidato, aprobado, campaña, práctica, diario), fecha programada, mundo, huella (hash) del JSON ni versión del motor. Dos casos generados con la misma dificultad y semilla en momentos distintos del motor pueden tener el mismo id y contenido diferente, y nada impide usar como reto diario un caso ya usado en campaña. El campo `world` que el borrador de la spec 16 mostraba no existe en el JSON real.
- **No hay generación por lotes con filtro.** Un comando `generate` produce casos, pero ningún paso filtra por dificultad ni registra el motivo de descarte por caso (solo muestra totales de descartes internos al final).
- **Las hojas imprimibles de `production/fase0-casos` son casos distintos a los de la app, con los mismos ids (H-51).** `casos-para-jugar.txt` y `casos-con-soluciones-SPOILERS.txt` se hicieron antes de los cambios de coherencia de muebles y de la regeneración de casos: por ejemplo, la hoja de `caso-casual-s1` habla del mapa "La Villa" con víctima Greta y el JSON de la app es "La Galería" con otra víctima. Por eso el feedback en papel no se puede atribuir a los casos de la app. No se usan esas hojas para validar; hay que regenerarlas desde `app/assets/cases` con el comando `show` (anotando fecha y commit de origen) o descartarlas.

### Modelo original (superado, se conserva como referencia)
- Mapas visuales: `autorados a mano`
- Casos sobre cada mapa: `generados proceduralmente y validados por solver`

### Por que hibrido
- Los mapas son arte visual con identidad de mundo, deben hacerse a mano.
- Los casos son combinaciones logicas de quien-donde-arma-pistas, escalan mal a mano y bien a generador.
- El solver garantiza que cada caso generado tiene `solucion unica` y `se resuelve por deduccion pura`.

### Lo que un mapa autorado define
> SUPERADO (11-06-2026): lo genera `map_generator.dart` por caso. Se conserva como referencia.

- layout de habitaciones
- objetos visibles fijos
- conexiones logicas entre habitaciones si aplica
- armas potenciales visibles que pueden aparecer
- arte y estilo visual del mundo

### Lo que el generador procedural decide
> Nota 04-11-2026: hoy el generador también decide el mapa. El número de sospechosos es el tamaño de la grilla menos la víctima (6, 8, 9, 12 o 16 personajes en total).

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
- ninguna pista es `redundante` mas alla de un margen permitido (**NO IMPLEMENTADO, H-42**: el detector no existe)
- el numero minimo de pasos de deduccion cae dentro del rango de su etiqueta de dificultad (**NO IMPLEMENTADO como filtro, H-40**: los pasos se calculan y se guardan, pero el generador no rechaza casos fuera de rango)

### Componentes del solver
- motor logico que resuelve el caso simulando al jugador
- verificador de unicidad que prueba que no existe otra solucion valida
- analizador de dependencias entre pistas
- contador de pasos de deduccion necesarios
- detector de pistas redundantes (**NO IMPLEMENTADO, H-42**)

Hoy existen: motor de deducción con contador de pasos y de nivel (T1 a T4), verificador de unicidad y validador de coherencia de pistas. No existe el analizador de dependencias entre pistas ni el detector de redundancia. Detalle en `docs/16-spec-puzzle.md` §6.

### Politica ante fallos del solver
- caso descartado si admite mas de una solucion
- caso descartado si requiere adivinanza en algun punto
- caso descartado si fuera del rango de dificultad objetivo
- caso registrado con su razon de descarte para mejorar el generador (hoy solo se muestran totales de descartes por motivo al terminar el comando; no se guardan por caso)
- **NO IMPLEMENTADO (H-42):** no hay límite de tiempo por intento ni tope de nodos; el único tope es de intentos (hasta 40 mapas con 8 intentos cada uno)

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
> ACTUALIZACIÓN 04-11-2026: **recalibración pendiente con los datos de la prueba de juego (etapa 1) y el arreglo del generador (etapa 3; H-40).** Estos rangos NO coinciden con el código: el generador define tamaños de 6, 8, 9, 12 y 16 personajes (todos ellos con una pista por personaje), así que "sospechosos: 3" a "6 a 7", "habitaciones activas" y "pistas" de abajo están desactualizados. Hoy el número de pistas es igual al tamaño de la grilla más las extras (Principiante 0, Casual 0, Intermedio 2, Experto 2, Élite 3), y el generador no impone ningún rango de pasos. Se conservan como historia.

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

> Nota 04-11-2026: lista resumida y desactualizada. El vocabulario vigente (16 tipos: áreas, muebles y personas, sin pistas mecánicas) está en `docs/16-spec-puzzle.md` §3.1. La "pista de víctima" de esta lista no existe como tipo propio: la víctima lleva el relleno "última casilla libre" o una pista normal. En Principiante el generador no usa pistas vagas (`not_in_area`, `not_same_area`), así que la frase "solo directas y negativas simples" de abajo es incorrecta: las negativas no se usan allí, y sí se usan pistas compuestas. Si Principiante lleva arma es una opción de la generación (`--weapons`), no del perfil.

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
> SUPERADO (11-06-2026) en cuanto a mapas autorados: no hay catálogo de 50 mapas, cada caso trae el suyo. **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 14): con cuánto contenido se lanza. Dos versiones en conflicto: (a) esta recomendación, tutorial más 5 mundos de 10 y reto diario de 60 a 120 días; (b) la recomendación de la auditoría, el Mundo 1 (La Mansión) con 10 casos más 30 días de reto diario Casual e Intermedio, hasta decidir la pregunta 13. Mientras tanto hay 20 casos en la app y ninguno es de mundo.

Recomendacion inicial:

- Mundo 0 Tutorial: 1 mapa guiado (nota 04-11-2026, **DECIDIDO** en la auditoría, pregunta 11; ver ADR-0012: el tutorial es un caso propio pequeño de 4×4 o 5×5, que no cuenta como Caso 1 ni como parte de los casos de campaña. Queda por debajo del perfil Principiante de 6×6, así que se crea como caso fijo y no sale del generador habitual; ver `docs/16-spec-puzzle.md`, §7)
- Mundo 1 Mansion: 10 mapas
- Mundo 2 Hotel: 10 mapas
- Mundo 3 Museo: 10 mapas
- Mundo 4 Tren: 10 mapas
- Mundo 5 Hospital: 10 mapas

Total V1: 1 mapa tutorial + 50 mapas de campana (el total de campaña depende de la pregunta 14, pendiente; el tutorial es aparte)

### Variaciones por mapa
Cada mapa autorado debe poder generar al menos:

- 1 caso oficial de campana
- N casos de practica con casos distintos sobre el mismo mapa
- M casos elegibles para el reto diario

Numero exacto de N y M se define al cerrar el generador, pero el objetivo es:

- mapa autorado reutilizable para muchos casos sin que se sienta repetido
- casos distintos por sospechosos, victima, arma y pistas

### Reto diario en V1
> Nota 04-11-2026: las metas de stock dependen de la pregunta 14 (contenido de lanzamiento) y la hora del reto es la pregunta 7: **PENDIENTE DE DECISIÓN**. La distribución semanal de abajo incluye Experto y Élite, que dependen de la pregunta 13 (si entran al lanzamiento).

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
> Nota 04-11-2026: hoy solo existen el generador (CLI) y el revisor humano (Alejandro, a mano). No existen autor de mapas, programador de reto diario ni herramientas dedicadas. El resto de esta sección describe el pipeline ideal y queda como diseño; ver "Flujo real de generación".

- autor de mapas: crea el layout visual y logico de cada mapa
- generador automatico: produce candidatos de caso sobre cada mapa
- solver: valida unicidad y dificultad de cada candidato
- revisor: aprueba o rechaza casos antes de publicacion
- programador de reto diario: arma el calendario diario

### Flujo de creacion de un mapa
> SUPERADO (11-06-2026): no se crean mapas por separado ni se registran en un catálogo; el mapa nace con el caso.

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

> Nota 04-11-2026: esto es el diseño objetivo (etapa 5). Hoy no hay servidor: los casos viajan completos, con la solución, dentro de la app (excepción vigente de la Fase 1, riesgo aceptado, doc 18) y la validación es local. Las vidas y la racha son simuladas. ~~Qué pasa al quedarse sin vidas (pregunta 5), las vidas de premium (6) y cómo se muestran los errores al resolver (9) son PENDIENTES DE DECISIÓN de Alejandro.~~ (SUPERADO 04-11-2026) **DECIDIDO 04-11-2026** (ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos (pregunta 5), y al fallar en Resolver solo se muestra cuántas casillas no cuadran (pregunta 9). Las vidas de premium (pregunta 6) siguen **PENDIENTE DE DECISIÓN**.

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
> Nota 04-11-2026: de esta lista solo existe el runner del generador (el CLI, sin selección de mapa porque el mapa se genera). El editor de mapas queda superado por los mapas procedurales; el visor de candidatos, el panel de calendario y el visor de métricas no existen (el comando `show` imprime una hoja de texto).

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

> Nota 04-11-2026: el "formato exacto del payload" ya tiene una primera versión real (ver `docs/16-spec-puzzle.md` §5) y el "limite de tiempo del solver" es el hallazgo H-42, no implementado. El identificador único y el manifiesto del caso (H-43) quedan como trabajo de la etapa 3.

- numero exacto N de casos por mapa
- limites concretos de tiempo del solver
- formato exacto del payload de caso enviado al cliente
- politica de versionado de un caso si se corrige tras publicacion
- politica de retirada de un caso si se detecta error post publicacion
- regla exacta de cuanto tiempo de reto diario expirado sigue siendo jugable

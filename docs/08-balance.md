# Enigmatrix - Balance numerico

> ACTUALIZACIÓN 06-11-2026: Alejandro decidió las preguntas 6 (premium con vidas ilimitadas) y 7 (el reto diario cambia a la medianoche local de cada jugador); ver las dos marcas DECIDIDO 06-11-2026 más abajo. Siguen pendientes la 12 y la 13. **(SUPERADO 11-11-2026) La 13 se decidió el 05-11-2026 (ADR-0014) y la 12 el 11-11-2026: la V1 sale sin ayudas ni puntos; ver las marcas DECIDIDO más abajo.**
>
> ACTUALIZACIÓN 04-11-2026: **documento EN REVISIÓN.** Los números de abajo siguen siendo propuestas y no se cambió ninguno. Cuatro temas estaban en conflicto o sin definir; el 04-11-2026 Alejandro decidió el de 0 vidas (pregunta 5) y quedaban pendientes los otros tres (preguntas 6, 7 y 13; las 6 y 7 se decidieron el 06-11-2026), que no se resuelven aquí porque los decide Alejandro (auditoría 04-11-2026, sección 5, en `production/revisiones/2026-11-04-auditoria-proyecto.md`):
>
> - **DECIDIDO 04-11-2026** (auditoría, pregunta 5, H-26; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
> - ~~Versión anterior~~ (SUPERADO 04-11-2026): ~~este documento no definía qué pasa al quedar con 0 vidas; solo decía que un error de Resolver cuesta 1 vida y que el cronómetro oficial no se detiene. No decía si se podía seguir jugando, si se bloqueaba solo Resolver o si se esperaba la recarga.~~
> - Regla relacionada, **DECIDIDO 04-11-2026** (auditoría, pregunta 10; ver ADR-0012): la partida se guarda siempre; al salir, el reloj se pausa y el tablero se oculta durante la pausa. Vale mientras no haya ranking real y se revisa antes de la etapa 5. Esto supera lo de "el cronómetro oficial no se detiene" de este documento.
> - **DECIDIDO 06-11-2026** (auditoría, pregunta 6, H-26; plan `production/planes/2026-11-06-etapas-5-y-6.md`): premium da **vidas ilimitadas**. Vale la versión A ("premium elimina el limite de 5", igual que `docs/01-mvp-v1.md`). La versión B de "Beneficios premium" ("recarga de vidas instantanea hasta el cap") queda SUPERADA: con vidas ilimitadas no hay tope que recargar.
>   - ~~(SUPERADO 06-11-2026) Versión anterior: PENDIENTE DE DECISIÓN entre vidas ilimitadas (versión A) y tope de 5 con recarga instantánea (versión B).~~
> - **DECIDIDO 06-11-2026** (auditoría, pregunta 7, H-27): el reto diario cambia a la **medianoche local de cada jugador** y es el mismo caso para todos los que juegan esa fecha. El servidor calcula la fecha con su propia hora y con la zona horaria guardada en la cuenta (solo se puede cambiar cada cierto tiempo, por ejemplo cada 7 días, valor en Remote Config) y no entrega retos con fecha posterior a la del huso más adelantado (UTC+14). La racha también se cuenta por fecha local con la zona guardada. Esto reemplaza la recomendación de la auditoría (medianoche de Colombia). Detalle: sección 1 del plan de las etapas 5 y 6.
>   - ~~(SUPERADO 06-11-2026) Versión anterior: PENDIENTE DE DECISIÓN; aquí la semana cierra "en hora del servidor", recomendado domingo 23:59 UTC, y `docs/03-reglas-del-juego.md` decía "dentro del día local".~~
>   - **Sigue sin definir:** el cierre del ranking **semanal** (sección "Balance del ranking semanal", domingo 23:59 UTC) no se tocó, porque la decisión del 06-11-2026 habla del reto diario. Con fechas locales hay que decidir si la semana cierra en UTC o según la fecha local de cada jugador. Pregunta nueva para el arquitecto y Alejandro (etapa 5B).
> - Distribución del reto (sigue en revisión, no depende de la hora): la distribución semanal ("Casual x2, Intermedio x3, Experto x1, Elite x1, sin Principiante") no se puede cumplir hoy: la app trae solo 20 casos (8 Principiante, 7 Casual y 5 Intermedio, ninguno Experto ni Élite) (SUPERADO 11-11-2026: hoy son 60 casos, 11 de Principiante, 23 de Casual y 26 de Intermedio, y el reto de la V1 son 30 días de Casual e Intermedio; Experto y Élite no entran en la V1, ADR-0014) y la pantalla de Reto del juego elige el caso según los días transcurridos desde el 01-01-2026 (con la hora local del teléfono) sin mirar la dificultad (hoy es una simulación DEMO).
> - **DECIDIDO 05-11-2026** (pregunta 13, ADR-0014): la V1 lleva solo **Principiante, Casual e Intermedio**. Experto y Élite llegan en una actualización, cuando el motor los genere de forma confiable.
>
> - **(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 13, H-39): si Experto (12×12) y Élite (16×16) entran al lanzamiento. El generador define esos tamaños pero nunca se han generado casos de ese tamaño. Mientras no se decida, todo lo que aquí dependa de ellos (bases, pisos, tiempos objetivo y la distribución del reto) queda sin comprobar.
>
> Otros dos puntos en revisión que no cambian ningún número:
> - **Rangos de dificultad por recalibrar.** Hoy el generador no controla la dificultad de cada caso (H-40): hay un caso Principiante que el solver resuelve en 10 pasos y uno Intermedio en 4. Los tiempos objetivo y la tabla de factor de velocidad de este documento se recalibran con los datos de la prueba de juego (etapa 1) y el motor se ajusta en la etapa 3.
> - **DECIDIDO 11-11-2026** (pregunta 12, ADR-0014, "Decisiones de Alejandro (11-11-2026)"): la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan en la **etapa 5B**, con el ranking del servidor.
>
> - **Ayudas y puntuación.** (**(SUPERADO 11-11-2026, versión anterior conservada como historial) antes PENDIENTE DE DECISIÓN**, auditoría 04-11-2026, pregunta 12, H-30.) La sección "Penalizacion por ayudas" describe ayudas que la app no tiene hoy, ni tampoco puntuación: la especificación (`docs/16-spec-puzzle.md`) no define cómo se calculan. La prueba de juego se hará sin ayudas.
>
> Lo demás (vidas, anuncios, tienda, protectores) es la intención de la Fase 2 en adelante; en el juego de hoy esas pantallas son simuladas.

## Objetivo de este documento
Cerrar los numeros que estaban como `pendiente` en docs anteriores para que el juego sea construible y testeable.

Cubre:

- formula de puntos
- bonus por velocidad
- penalizacion por error
- penalizacion por ayuda
- balance del reto diario
- balance del ranking semanal
- balance de vidas
- balance de anuncios
- precios de tienda
- balance de protectores de racha
- limites tecnicos pendientes

Todos los numeros aqui son `valores propuestos de salida`. Se ajustan con datos de playtest y de jugadores reales.

## Formula general de puntos

### Estructura
Puntos finales de un caso resuelto correctamente:

`puntos = base_dificultad * factor_velocidad - penalizacion_errores - penalizacion_ayudas`

Reglas:

- el resultado nunca baja de un piso minimo definido por dificultad
- si el caso no se resuelve correctamente, no entrega puntos oficiales
- los puntos solo se asignan tras validacion del servidor

### Piso minimo por dificultad
- Principiante: 10
- Casual: 25
- Intermedio: 50
- Experto: 100
- Elite: 200

### Base por dificultad
- Principiante: 100
- Casual: 250
- Intermedio: 500
- Experto: 1000
- Elite: 2000

## Bonus por velocidad

### Tiempo objetivo por dificultad
Tiempo de referencia para calcular el bonus.

- Principiante: 90 segundos
- Casual: 180 segundos
- Intermedio: 360 segundos
- Experto: 600 segundos
- Elite: 900 segundos

### Tabla de factor de velocidad
Se compara el tiempo real con el tiempo objetivo de la dificultad.

- menor o igual al 50 por ciento del objetivo: factor 1.50
- entre 51 y 75 por ciento: factor 1.30
- entre 76 y 100 por ciento: factor 1.15
- entre 101 y 150 por ciento: factor 1.00
- entre 151 y 200 por ciento: factor 0.85
- mayor a 200 por ciento: factor 0.70

### Reglas
- el factor maximo es 1.50
- el factor minimo es 0.70
- el tiempo se cuenta desde inicio oficial hasta resolver correcto
- el tiempo durante bloqueo por error sigue contando

## Penalizacion por errores de resolver

### Reglas
- solo penaliza pulsar `Resolver` con tablero incorrecto
- marcar mal antes de validar no penaliza
- la penalizacion se acumula por cada error oficial

### Tabla
- 1er error: 5 por ciento de la base
- 2do error: 10 por ciento de la base
- 3er error: 15 por ciento de la base
- 4to error o mas: 20 por ciento de la base por error

### Limite
- la suma total de penalizacion por errores no puede dejar el resultado por debajo del piso minimo

## Penalizacion por ayudas

### Costo por tipo de ayuda
Aplica como porcentaje de la base de la dificultad jugada.

- resaltar pista importante: 5 por ciento
- eliminar opciones imposibles en una casilla: 10 por ciento
- autodescartar para un personaje: 15 por ciento
- explicar una deduccion parcial: 20 por ciento
- revelar una casilla correcta: 30 por ciento

### Reglas
- cada ayuda usada se descuenta de los puntos finales
- si una misma ayuda se usa varias veces en la partida, cada uso descuenta
- la suma total de penalizacion por ayudas no puede dejar el resultado por debajo del piso minimo
- el costo exacto no se muestra al jugador antes de usar la ayuda
- el resumen final si muestra cuantos puntos se descontaron en total por ayudas

### Disponibilidad por dificultad
- Tutorial: solo ayudas guiadas, no penalizan
- Principiante: todas disponibles, sin penalizar
- Casual y arriba: todas disponibles, todas penalizan

## Balance del reto diario

### Puntos del reto diario
- usa la misma formula general
- la dificultad del reto del dia esta declarada antes de iniciar

### Distribucion semanal de dificultad
Como se programa la dificultad del reto durante la semana:

- 2 dias por semana: Casual
- 3 dias por semana: Intermedio
- 1 dia por semana: Experto
- 1 dia por semana: Elite

Sin Principiante. Se ajusta con datos.

### Bonus por completar el reto del dia
- ganar el reto del dia entrega un bonus fijo: 100 puntos
- el bonus solo aplica si el reto se completa dentro de la ventana valida del dia

### Reto fuera de tiempo
- si se termina fuera de la ventana:
  - no entrega bonus diario
  - no suma a ranking diario
  - no suma a ranking semanal
  - no afecta racha
  - permite cerrar el caso solo a nivel personal

## Balance del ranking semanal

### Como se acumula
- suma puntos finales de cada reto diario completado dentro de la ventana valida
- suma el bonus diario de cada reto valido

### Cierre
- la semana cierra en hora del servidor en un dia y hora declarados
- recomendado: domingo a las 23:59 UTC
- > ACTUALIZACIÓN 06-11-2026: el reto diario ahora cambia a la medianoche local de cada jugador (pregunta 7, DECIDIDA). Cómo cierra la semana con fechas locales queda sin definir; no se cambia esta propuesta por cuenta propia.
- el snapshot del top semanal se guarda al cerrar
- la nueva semana arranca con el contador en cero

### Empates
- en caso de empate por puntos, gana quien tenga menor tiempo total acumulado en sus retos diarios validos de la semana
- en caso de empate doble, ordena alfabetico por nickname

## Balance de vidas

### Reglas base
- maximo de vidas activas gratis: 5
- recarga: 1 vida por hora
- el conteo de tiempo es del servidor

### Costos
- iniciar tablero: 0 vidas
- error oficial al pulsar Resolver: 1 vida en oficial, practica y reto diario
- tutorial: nunca cuesta vida

### Recuperacion por anuncio
- ver anuncio recarga 1 vida activa
- limite: hasta 3 anuncios de vida por hora
- si esta en 5 de 5, el boton se deshabilita
- si esta en limite por hora, el boton se deshabilita y muestra cuanto falta

### Vidas extra
- solo por compra
- primero rellenan vidas activas hasta 5
- el sobrante va a reserva extra
- las extra se consumen automaticamente para mantener la barra activa
- premium elimina el limite de 5
- > DECIDIDO 06-11-2026 (pregunta 6): premium da vidas ilimitadas.

## Balance de anuncios

### Tipos
- intersticial entre tableros al terminar partida
- recompensado para recuperar vida
- recompensado para desbloquear siguiente mundo

### Reglas de frecuencia
- intersticial: aparece tras cada caso completado, oficial o practica
- intersticial: no aparece al terminar el tutorial despues del primer caso
- intersticial: no aparece para usuarios premium
- recompensado de vida: a peticion del usuario, hasta 3 por hora
- recompensado de mundo: una sola vez por mundo nuevo desbloqueado

### Tiempo de carga
- precarga del proximo anuncio durante la partida para no bloquear el flujo
- si el anuncio no carga, se omite y se continua sin bloquear

## Precios de tienda

### Moneda de referencia
- USD como referencia interna
- la tienda muestra siempre el precio local entregado por Google Play o App Store
- los precios reales por pais los entrega el store, no la app

### Premium
- mensual: 4.99 USD
- anual: 29.99 USD
- el anual debe mostrar el ahorro visible:
  - texto sugerido: ahorra 50 por ciento frente al mensual

### Beneficios premium
- sin anuncios
- sin limite de 5 vidas activas (DECIDIDO 06-11-2026, pregunta 6: vidas ilimitadas)
- ~~recarga de vidas instantanea hasta el cap~~ (SUPERADO 06-11-2026: con vidas ilimitadas no hay tope que recargar)
- los limites por hora del recompensado dejan de aplicar
- no entrega ventajas de ranking ni multiplicadores de puntos

### Packs de vidas
- pack pequeno: 0.99 USD por 10 vidas
- pack mediano: 2.99 USD por 35 vidas
- pack grande: 4.99 USD por 70 vidas
- pack mega: 9.99 USD por 160 vidas

### Protectores de racha
- pack 3 protectores: 0.99 USD
- pack 10 protectores: 2.99 USD
- pack 25 protectores: 4.99 USD

## Balance de protectores de racha

### Recordatorio de regla
- protege 1 dia perdido por cada protector consumido
- se activa automaticamente al detectar dia perdido
- pueden acumularse sin limite por ahora

### Hitos definidos
- dia 50: 1 protector entregado
- dia 100: 1 protector entregado
- dia 150: 2 protectores entregados
- dia 200: 2 protectores entregados

### Hitos adicionales propuestos
- dia 7: 1 protector
- dia 14: 1 protector
- dia 30: 1 protector
- dia 250: 2 protectores
- dia 365: 3 protectores

### Reglas de entrega
- los protectores por hito se entregan en el siguiente acceso a la app tras alcanzar el hito
- los protectores comprados se entregan inmediatamente tras validar la compra

## Tabla resumen de penalizacion total maxima

Limite duro: el total de penalizaciones nunca deja los puntos por debajo del piso minimo de la dificultad jugada.

| Dificultad | Base | Piso minimo |
| --- | --- | --- |
| Principiante | 100 | 10 |
| Casual | 250 | 25 |
| Intermedio | 500 | 50 |
| Experto | 1000 | 100 |
| Elite | 2000 | 200 |

## Limites tecnicos pendientes ya cerrados

### Tiempo offline maximo en partida
- 60 segundos
- si supera ese tiempo, bloqueo del tablero hasta recuperar conexion

### Ventana de verificacion de email
- 24 horas para usar el enlace
- pasado ese tiempo, el enlace queda invalido y debe pedirse otro

### Limite de reenvio de verificacion
- 1 envio cada 5 minutos
- maximo 5 envios por dia por cuenta

### Limite de deshacer y rehacer
- historial de 50 acciones por partida
- al exceder, se borra la accion mas antigua

### Cambio de nickname
- 1 cambio cada 15 dias
- si el nickname elegido esta tomado, no se gasta el cooldown

## Pendientes que dependen de pruebas reales

- ajustes finos de la tabla de factor de velocidad
- ajuste real del bonus diario
- ajustes a precios tras observar conversion real
- distribucion final de dificultad del reto diario
- frecuencia exacta de intersticiales si causa fricción

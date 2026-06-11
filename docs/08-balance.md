# Enigmatrix - Balance numerico

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
- sin limite de 5 vidas activas
- recarga de vidas instantanea hasta el cap
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

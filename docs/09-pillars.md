# Enigmatrix - Pillars de diseño

## Objetivo de este documento
Definir los principios filtro que sirven para tomar decisiones de diseño, producto y tecnica.

Cada vez que aparezca una pregunta tipo:

- agregamos esta feature
- cambiamos esta regla
- aceptamos este hack tecnico
- ajustamos este balance

la respuesta debe pasar por estos pillars. Si una decision rompe un pillar, se rechaza, se replantea o se justifica explicitamente.

## Como se usan
- Toda propuesta de feature pasa por la pregunta: ¿respeta los 5 pillars?
- Si rompe uno, debe replantearse hasta cumplirlos o documentarse como excepcion consciente
- Los pillars no se votan caso por caso, son anclas estables del producto
- Solo se revisan los pillars en hitos mayores, no por feature individual

## Los 5 pillars

### 1. Deduccion pura
> El jugador siempre puede llegar a la solucion razonando. Nunca se gana adivinando.

#### Lo que obliga
- todo caso debe tener solucion unica verificable por solver
- todo paso de deduccion debe ser justificable con las pistas dadas
- la dificultad sube por mas pasos logicos, no por mas suerte
- las ayudas existen para asistir el razonamiento, no para sustituirlo

#### Lo que prohibe
- casos con multiples soluciones validas
- casos que requieran adivinar para avanzar
- mecanicas tipo lottery o RNG en el resultado oficial
- pistas vagas sin valor logico

### 2. Ranking limpio
> En el ranking solo sube quien razona mejor. Nada se compra.

#### Lo que obliga
- premium da comodidad, nunca puntos ni multiplicadores
- todo el balance es igual para gratis y premium
- las vidas extras pagadas solo evitan esperar, no mejoran el resultado
- la validacion oficial siempre vive en el servidor

#### Lo que prohibe
- boosters de puntos, tiempo o ayudas como producto pagado
- ventajas exclusivas premium dentro del juego
- compras que reduzcan dificultad efectiva
- casos pagados con mejor recompensa

### 3. Cabe en un trayecto
> Una sesion de juego termina en minutos, no en horas.

#### Lo que obliga
- los casos por defecto se resuelven en sesiones cortas
- el reto diario es una sola partida, no una serie
- la entrada al juego es directa: pocos pasos hasta jugar
- la salida es limpia: cerrar la app no rompe el progreso

#### Lo que prohibe
- mecanicas que exijan jornadas largas para tener sentido
- friccion de carga o anuncios entre cada accion pequena
- features que obliguen a hacer varias cosas para terminar lo iniciado
- progreso que se invalide solo porque el usuario cerro la app

### 4. Justos con el jugador
> El juego nunca castiga al jugador por cosas que no controla.

#### Lo que obliga
- caidas de internet no consumen vida ni puntos por sí mismas
- tiempos de carga del servidor no afectan el cronometro oficial
- bugs reportados deben tener via clara de reembolso o restauracion
- los limites tecnicos se comunican antes, no a posteriori

#### Lo que prohibe
- penalizar por cerrar la app si el sistema fallo
- castigar por anuncios que no cargaron
- bloquear contenido por errores del servidor sin compensacion
- mensajes de error que culpan al usuario por problemas tecnicos

### 5. El mapa cuenta la historia
> La deduccion es visual. El mapa, los objetos y los avatares son protagonistas. El texto es soporte.

#### Lo que obliga
- las pistas se entienden mirando el mapa
- los simbolos del tablero son inmediatos y consistentes
- los mundos tienen identidad visual fuerte propia
- la UI deja respirar el mapa, no lo tapa

#### Lo que prohibe
- pistas que dependan de leer parrafos largos
- iconos ambiguos o que requieran instructivo
- mundos que se vean iguales entre sí
- chrome de UI que ocupe mas que el tablero

## Reglas de conflicto entre pillars

### Caso: deduccion pura vs cabe en un trayecto
- Si una mecanica de deduccion alarga la partida, gana deduccion pura
- Pero el caso debe poderse pausar y retomar
- Nunca se sacrifica unicidad por brevedad

### Caso: ranking limpio vs justos con el jugador
- Si compensar a un jugador por fallo tecnico podria afectar el ranking, gana ranking limpio
- La compensacion se da en otra moneda: vidas, protectores, no en puntos
- Nunca se editan resultados oficiales individuales

### Caso: el mapa cuenta la historia vs cabe en un trayecto
- Si el mapa requiere mas tiempo de carga para verse bien, vale la pena
- Pero la primera partida debe arrancar rapido
- La segunda y siguientes pueden aprovechar cache

## Decisiones existentes que validan los pillars

### Decisiones que cumplen
- solver garantiza solucion unica en pipeline: pillar 1
- premium no da ventaja en ranking: pillar 2
- una sola partida oficial pendiente global: pillar 3
- bloqueo del tablero al perder conexion sin penalizar: pillar 4
- panel de sospechosos siempre visible, mapa dominante: pillar 5

### Decisiones que merecen revision a la luz de los pillars
- tiempo siempre corre, sin pausa manual: tension entre pillar 3 y pillar 4
  - decision: el tiempo oficial corre, pero no se penaliza por bloqueo de servidor
- bloqueo de capturas en partida oficial: tension con accesibilidad
  - decision: se mantiene en oficial, no aplica en tutorial, practica y como jugar
- castigo fuerte al abandonar partida pendiente para abrir otra: tension con pillar 3
  - decision: se mantiene como regla anti acumulacion, pero se avisa claramente

## Como aplicar los pillars en discusiones futuras

### Plantilla de revision rapida
Para cada propuesta nueva escribir:

- nombre de la propuesta
- por cada pillar:
  - cumple
  - lo rompe y como
  - es neutro
- decision final
- justificacion si rompe alguno

### Cuando ignorar un pillar
- excepciones existen, pero se documentan
- nunca se ignora un pillar de forma silenciosa
- si una excepcion se vuelve patron, los pillars deben revisarse formalmente

## Pendientes
- alinear los pillars con el manifiesto de marca cuando exista
- traducir los pillars a frases cortas usables en pantallas internas para el equipo

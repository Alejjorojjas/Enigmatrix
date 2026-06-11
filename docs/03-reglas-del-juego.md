# Enigmatrix - Reglas del juego

## Identidad del juego
Enigmatrix es un juego de deduccion visual y logica espacial. El jugador resuelve casos colocando sospechosos y marcas sobre un mapa con habitaciones y objetos, a partir de pistas textuales.

## Regla general de victoria
El jugador solo gana cuando `todo el tablero` esta correcto.

- No basta con acertar el asesino.
- No basta con acertar la victima o una parte del mapa.
- Todo el caso debe quedar bien resuelto.

## Estructura del caso
Cada caso tiene:

- mapa grafico
- habitaciones
- objetos
- sospechosos
- pistas
- una solucion unica

De forma opcional segun dificultad, un caso tambien puede incluir:

- armas potenciales visibles
- una arma homicida correcta

## Reglas del tablero
- El tablero se resuelve sobre el mapa
- La victima no aparece al inicio
- Al final, todas las personas deben estar ubicadas correctamente
- El jugador puede usar notas o no

## Sistema de arma homicida

### Presencia por dificultad
- `Tutorial`: no usa arma homicida
- `Principiante`: no usa arma homicida
- `Casual`: algunos casos pueden incluir arma homicida en una version simplificada
- `Intermedio`, `Experto` y `Elite`: el arma homicida puede formar parte normal del caso

### Regla general
- El arma homicida agrega complejidad al caso
- El arma homicida no se acusa manualmente en V1
- El sistema la deduce automaticamente cuando el tablero esta correctamente resuelto
- El arma homicida se revela en el resumen final del caso
- No aparece en ranking

### Representacion en el mapa
- El arma se muestra como un objeto potencial pequeno dentro de una habitacion
- No ocupa el mismo papel estructural que cama, mesa o sofa
- Visualmente puede verse en un punto del mapa
- Logicamente pertenece a una `habitacion`, no a una casilla exacta

### Relacion con la solucion
En los casos con arma homicida:

- el asesino
- la victima
- y el arma homicida

pertenecen a la misma habitacion

### Multiples armas potenciales
- En dificultades bajas con arma, puede haber muy pocas armas potenciales visibles
- En dificultades altas pueden existir varias armas potenciales visibles
- Solo una es la correcta por caso

### Pistas sobre el arma
Las pistas pueden hablar de:

- la habitacion donde esta el arma
- el tipo de arma
- el arma especifica

### Categorias logicas del arma
Las categorias existen para deduccion, pero no se muestran explicitamente en la UI.

Categorias base:
- cortante
- contundente
- veneno
- asfixia o atadura

Cada arma especifica pertenece a una sola categoria.

### Reglas de dificultad del arma
- En `Casual` con arma:
  - debe haber pocas pistas de arma
  - la deduccion se centra mas en la habitacion
- En `Intermedio` en adelante:
  - pueden entrar mas pistas por tipo o categoria
  - puede haber mayor variedad de armas potenciales visibles

### Lista base oficial de armas V1
- Cuchillo de cocina
- Tijeras
- Abrecartas
- Candelabro
- Estatua pequena
- Busto decorativo
- Martillo de servicio
- Botella rota
- Cable
- Cuerda
- Frasco de veneno
- Jeringa

### Distribucion base de armas por mundo
- Mansion:
  - Abrecartas
  - Candelabro
  - Estatua pequena
  - Cuerda
  - Frasco de veneno
  - Tijeras
- Hotel:
  - Cuchillo de cocina
  - Tijeras
  - Botella rota
  - Cable
  - Frasco de veneno
  - Martillo de servicio
- Museo:
  - Abrecartas
  - Estatua pequena
  - Busto decorativo
  - Cuerda
  - Frasco de veneno
- Tren:
  - Cuchillo de cocina
  - Botella rota
  - Cable
  - Martillo de servicio
- Hospital:
  - Cuchillo de cocina
  - Tijeras
  - Cable
  - Martillo de servicio
  - Jeringa

## Regla global de partida oficial pendiente
- El jugador solo puede tener `una` partida oficial incompleta en toda la app.
- Aplica tanto para mapas normales como para reto diario.
- Si intenta iniciar otro contenido oficial teniendo una pendiente:
  - recibe advertencia
  - puede volver a la pendiente
  - o puede abandonarla para iniciar la nueva
- Si la abandona:
  - pierde el intento oficial anterior
  - el contenido anterior queda sin validez oficial

## Modos de notas

### Modo 1
- Cuadricula logica separada

### Modo 2
- Cuadricula logica superpuesta al mapa

### Regla comun
- Ambos modos comparten el mismo estado logico
- El jugador puede cambiar entre ellos en partida
- Tambien puede jugar sin usar notas

## Elementos visuales del tablero

### Candidato
- `avatar pequeno + signo de interrogacion`

### Confirmado
- `avatar grande + flecha verde`

### Descarte parcial
- `X pequena`

### Descarte fuerte
- `X grande`

### Colores base
- error: rojo
- exito/confirmacion: verde
- informativo/destacado: azul
- X: negro oscuro o gris muy oscuro

## Reglas de colocacion

### Desde panel fijo
- El panel fijo muestra solo avatar y nombre
- Tocar avatar una vez: candidato
- Tocar avatar otra vez: confirmado
- Se arrastra al mapa

### Para X
- Tocar una vez: X pequena
- Tocar otra vez: X grande
- Se arrastra al mapa

### Reglas de convivencia
- Si el mismo elemento ya existe, no hace nada
- Si llega la misma entidad en otro estado, reemplaza
- Si es una entidad distinta, coexiste

### Regla de confirmado
Si se coloca un confirmado:

- borra automaticamente todo lo anterior en esa casilla
- deja solo el confirmado

Si una casilla ya tiene un confirmado:

- no se pueden poner candidatos
- no se pueden poner X
- muestra mensaje:
  - `Esta casilla ya tiene una decision confirmada, borra primero para colocar candidato`

Si se coloca otro confirmado sobre un confirmado:

- pide confirmacion
- reemplaza al anterior

## Reglas de borrado

### Mini panel
- aparece al tocar una casilla con varios elementos
- sirve solo para borrar
- muestra los elementos de manera simple
- se cierra al borrar un elemento

### Papelera
- siempre visible en partida
- se puede arrastrar cualquier elemento para borrarlo
- admite:
  - candidatos
  - confirmados
  - X pequenas
  - X grandes
- tiene feedback visual al pasar por encima
- borrar puede recuperarse con `deshacer`

## Resolver

### Al pulsar Resolver
- No pide confirmacion
- Valida de inmediato

### Si la solucion esta mal
- muestra alerta
- resalta casillas incorrectas
- bloquea edicion por unos segundos
- tiempo sigue corriendo
- pierde puntos
- en partidas con vidas, pierde una vida
- luego se desbloquea para seguir jugando

### Si la solucion esta bien
- muestra mensaje de completado exitoso
- no cambia de pantalla inmediatamente
- bloquea la edicion
- habilita boton `Continuar`

## Errores
- Los errores solo cuentan al pulsar `Resolver`
- Confirmar o marcar mal antes de validar no penaliza
- El error resalta solo las `casillas incorrectas`
- No se resaltan sospechosos en el panel fijo

## Puntos
La logica base de puntuacion es:

- base por dificultad
- bonus por velocidad
- penalizacion por intentos fallidos de resolver
- penalizacion por ayudas usadas

Numeros exactos: `pendiente`

## Ayudas

### Ayudas V1
- resaltar pista importante
- eliminar opciones imposibles en una casilla
- autodescartar para un personaje
- revelar una casilla correcta
- explicar una deduccion parcial

### Reglas de ayudas
- siempre penalizan
- la penalizacion exacta no se muestra antes
- hay boton visible de `Ayudas`
- se pide confirmacion simple antes de usarlas
- algunas ayudas son contextuales
- las no disponibles se ven deshabilitadas
- se pueden tocar para explicar por que no estan disponibles
- al usarlas:
  - aparece feedback temporal rojo de perdida de puntos

## Pistas
- Siempre visibles durante la partida
- El jugador puede tacharlas manualmente
- El jugador puede destacarlas manualmente
- El estado de la pista queda guardado si abandona la partida
- El cambio de estado funciona en ciclo:
  - normal
  - destacada
  - tachada
  - normal

## Tiempo
- El tiempo siempre esta visible
- Sigue corriendo incluso si la app se minimiza
- No hay pausa manual

## Deshacer y rehacer
- Existen ambos botones
- Solo afectan acciones del mapa
- No afectan pistas
- Limite tecnico pendiente

## Limpiar tablero
- Existe boton `Limpiar tablero`
- Pide confirmacion
- Borra estado visual/manual de la partida
- Borra marcas del mapa
- Borra pistas marcadas
- Mantiene:
  - tiempo
  - errores
  - ayudas usadas
  - penalizaciones acumuladas

## Vidas

### Regla base
- Maximo de vidas activas gratis: 5
- Recarga de 1 vida por hora
- Una sola bolsa global

### Perdida de vidas
- Solo se pierde vida al `Resolver` mal
- Aplica en:
  - mapas normales
  - reto diario
  - practica
- No aplica en:
  - tutorial

### Recuperacion
- anuncios recargan vidas activas
- anuncios nunca crean vidas extra
- si ya esta en 5/5, no pasa nada visible

### Vidas extra
- solo por compra
- primero rellenan activas
- el resto va a reserva extra
- se consumen automaticamente 1x1 para rellenar activas

## Publicidad
- entre tableros al terminar
- para recuperar vida
- para desbloquear mundo
- premium elimina anuncios

## Practica
- Un mapa puede jugarse en practica cuando:
  - ya tuvo su intento oficial
  - y se completo todo su mundo
- Practica no afecta ranking
- Practica no afecta promedio global
- Practica muestra resumen completo
- Practica muestra tambien el puntaje oficial registrado

## Mapa oficial
- Tiene un solo intento oficial puntuable
- Si se pierde ese intento oficial:
  - el mapa ya no cuenta para ranking
  - pero debe completarse para avanzar

## Mapa sin resolver
Un mapa queda `sin resolver` cuando pierde su intento oficial.

- sigue siendo necesario para progresar
- no cuenta para ranking ni estadisticas oficiales

## Reto diario

### Reglas
- un intento oficial
- no repetible oficialmente
- al abrirlo por primera vez en el dia:
  - aparece advertencia de intento oficial
  - al confirmar, se registra el intento oficial del dia
- si no se completa dentro del dia local:
  - puede terminarse despues
  - pero no cuenta para ranking, puntos semanales ni racha
- si se pierde la validez oficial:
  - ya no se puede volver a abrir

### Ranking del reto
- ranking separado
- muestra tiempo y puntos
- se ordena por tiempo

### Badge del reto diario
- se muestra mientras el reto del dia siga pendiente y jugable
- desaparece al completar el reto
- desaparece si el reto deja de ser jugable para el resto del dia

## Ranking semanal
- suma puntos de retos diarios validos
- si un dia no juega, no suma
- sigue participando el resto de la semana

## Racha
- Solo cuenta el reto diario
- Sube solo si lo completa correctamente
- Si falla:
  - revisa protectores disponibles
  - si hay, consume uno por cada dia perdido
  - si no hay, la racha vuelve a cero
- Se muestra mejor racha historica

## Protectores de racha
- compra directa
- eventos
- hitos de racha
- se activan automaticamente
- pueden acumularse sin limite por ahora
- en la pantalla diaria se muestran los ultimos 3 usados con fecha

### Hitos definidos
- dia 50: 1 protector
- dia 100: 1 protector
- dia 150: 2 protectores
- dia 200: 2 protectores

## Antitrampa

### Captura y grabacion
- bloqueo en partidas oficiales
- no aplica a tutorial, practica o como jugar

### Rotacion de mapa
- aplica en:
  - mapas normales
  - reto diario
  - practica
- no aplica en:
  - tutorial
  - como jugar
- una de 4 orientaciones:
  - 0
  - 90
  - 180
  - 270
- el mapa rota, pero los textos e imagenes quedan orientados hacia el usuario
- cada mapa recibe una orientacion fija por jugador
- el reto diario usa orientacion aleatoria por jugador

### Partidas incompletas
- Se guardan solo en cache local
- si se borra cache o datos, se pierde el intento oficial
- si se cierra sesion con una partida pendiente, se pierde el intento oficial

## Conexion
- Todo el juego es online
- si se pierde conexion durante una partida oficial:
  - puede seguir un tiempo
  - luego se bloquea
  - no deja ver tablero ni pistas
- al volver la conexion:
  - reintento automatico

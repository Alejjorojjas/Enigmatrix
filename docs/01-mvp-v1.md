# Enigmatrix - MVP V1

## Vision
Enigmatrix busca ser una app mobile de puzzles logicos centrada en investigaciones visuales sobre mapas con habitaciones, objetos y sospechosos, donde el jugador resuelve casos por deduccion y compite con tiempo, puntos y rankings.

## Objetivo del MVP
Lanzar una primera version jugable y competitiva de Enigmatrix enfocada en el modo principal del juego, con:

- tutorial obligatorio
- campana por mundos
- reto diario
- ranking
- racha
- vidas
- premium
- tienda basica
- sistema antitrampa inicial
- compartir resultados

## Nombre del producto
- Nombre actual: `Enigmatrix`
- El nombre anterior `Murdoku` ya no se usa como nombre del producto.

## Alcance del MVP

### Modo principal
- Solo existira `Enigmatrix` como juego principal.
- No entran en V1 otros modos como Sudoku, Queen, Caballos o Tango.

### Plataformas
- Prioridad inicial: `Android`
- Se deja preparada la definicion para llevarlo despues a `iOS`

### Cuenta y acceso
- Inicio de sesion con `Google`
- Inicio de sesion con `email y contrasena`
- Usuario con `nickname unico`
- `avatar`
- `bandera/pais`
- Usuarios con Google quedan verificados automaticamente.
- Usuarios con email deben verificar correo para acceder a `Reto diario` y `Rankings`.

### Onboarding
- Pantallas breves de bienvenida antes del tutorial
- Tutorial obligatorio la primera vez
- Tutorial rejugable desde `Como jugar`

### Campana
- `Mundo 0`: Tutorial
- `Mundo 1`: Mansion
- `Mundo 2`: Hotel
- `Mundo 3`: Museo
- `Mundo 4`: Tren
- `Mundo 5`: Hospital
- Los mundos tienen tema fijo.
- La distribucion de los mapas y los objetos cambia dentro de cada mundo.
- Los mapas dentro de un mundo se juegan en secuencia.
- El siguiente mapa se desbloquea al completar el anterior.
- El siguiente mundo se desbloquea al completar todo el mundo actual.

### Tipos de mapa
- Mapa oficial
- Mapa sin resolver
- Modo practica
- Tutorial
- Reto diario

### Dificultad
La dificultad del juego se organizara con estas etiquetas:

- Principiante
- Casual
- Intermedio
- Experto
- Elite

La dificultad puede subir dentro de un mismo mundo.

### Sistema de arma homicida
- `Tutorial` e `Principiante`: no usan arma homicida
- `Casual`: algunos casos pueden incluir arma homicida en una version simplificada
- `Intermedio`, `Experto` y `Elite`: el arma homicida puede formar parte normal del caso
- El arma homicida agrega complejidad al caso
- El arma homicida se deduce automaticamente por el sistema al resolver correctamente el tablero
- El jugador no acusa el arma manualmente en V1
- El arma homicida es visible en el mapa como objeto potencial pequeno dentro de una habitacion
- Logicamente el arma pertenece a la `habitacion`, no a una casilla exacta
- En los casos con arma:
  - asesino
  - victima
  - arma homicida
  quedan en la misma habitacion
- Puede haber varias armas potenciales visibles en dificultades altas, pero solo una es la correcta
- El jugador sabe desde la pantalla previa si el caso incluye arma homicida

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

### Juego base
- Mapa grafico con habitaciones y objetos
- Pistas visibles
- Panel fijo de sospechosos
- Sistema de notas opcional
- Dos modos de notas:
  - notas separadas
  - superposicion sobre el mapa
- El jugador puede jugar tambien sin usar notas

### Reglas principales del tablero
- Todo el tablero debe quedar correcto para ganar
- El boton `Resolver` valida todo el tablero
- Si hay error:
  - alerta
  - resaltado temporal de errores
  - perdida de puntos
  - perdida de vida en partidas oficiales y practica
- Si esta correcto:
  - mensaje de completado en la misma pantalla
  - se bloquea la edicion
  - se habilita `Continuar`

### Regla global de partida pendiente
- El jugador solo puede tener `una` partida oficial incompleta en toda la app al mismo tiempo.
- Si intenta abrir otro mapa oficial o el reto diario teniendo una partida oficial pendiente:
  - aparece una advertencia
  - puede volver a la partida pendiente
  - o puede abandonar la pendiente para iniciar la nueva
- Si abandona la pendiente para iniciar otra:
  - pierde el intento oficial anterior
  - el contenido anterior queda sin validez oficial

### Vidas
- Una sola bolsa global de vidas para todo Enigmatrix
- Maximo de vidas activas gratis: `5`
- Recarga de `1 vida cada 1 hora`
- Ver anuncio puede recargar vidas activas
- Si ya esta en `5/5`, el anuncio no agrega nada
- Las `vidas extra` solo se consiguen por compra
- Una compra primero rellena vidas activas y el sobrante va a reserva extra
- Las vidas extra se consumen automaticamente `1x1` para mantener la barra activa
- Iniciar tablero no consume vida
- Solo se pierde vida al pulsar `Resolver` y estar mal
- El tutorial no quita vidas

### Publicidad
- Anuncio entre tableros al terminar una partida
- Anuncio para desbloquear el siguiente mundo en usuarios no premium
- Anuncio para recuperar vidas
- Premium elimina anuncios

### Premium
- Plan `mensual`
- Plan `anual`
- Beneficios:
  - sin anuncios
  - sin limite de vidas
- No da ventajas directas de ranking

### Reto diario
- Disponible tras completar tutorial
- Visible aunque el usuario de email no verificado lo tenga bloqueado
- Un solo intento oficial
- No repetible oficialmente
- Mismo caso para todos
- Orientacion aleatoria por jugador
- Tiene ranking diario
- Suma al ranking semanal
- Tiene racha asociada
- Al abrirlo por primera vez en el dia:
  - se advierte que se registrara el intento oficial
  - al confirmar, queda consumido el intento oficial del dia

### Ranking
- Ranking por mapa
- Ranking de reto diario
- Ranking semanal
- En mapas y reto diario se ordena por tiempo
- En semanal se ordena por puntos
- En todos se muestran tiempo y puntos

### Resumenes
- Resumen normal
- Resumen de reto diario
- Resumen del tutorial
- Resumen del mundo

### Compartir resultados
- Compartir resultado de mapa
- Compartir resultado de reto diario
- Compartir racha
- Formato visual con:
  - avatar
  - nickname
  - resultado
  - tiempo y puntos
  - branding del juego

### Perfil
- Perfil propio editable
- Perfil publico visible
- Avatar, nickname, bandera/pais
- Estadisticas publicas de racha, retos y progreso

### Tienda
- Premium
- Packs de vidas
- Protectores de racha
- Espacio preparado para futuro

### Antitrampa V1
- Bloqueo de capturas en partidas oficiales
- Bloqueo de grabacion en partidas oficiales si es posible
- Mapa rotado aleatoriamente por jugador
- Cada mapa conserva una orientacion fija por jugador
- Reto diario con orientacion distinta por jugador
- La partida oficial sigue corriendo aunque la app se minimice
- El progreso de partida incompleta se guarda solo en cache local

## Lo que no entra al MVP
- Otros juegos logicos
- Sistema de amigos
- Rankings por pais
- Temporadas
- Moneda interna
- Eventos visibles como seccion
- Historial de partidas
- Busqueda
- Logros
- Moderacion avanzada de avatar
- Anti-cheat avanzado
- Variaciones musicales por mundo
- Mini ejemplos interactivos en `Como jugar`

## Pendientes tecnicos o de balance
- Formula exacta de puntuacion
- Penalizaciones numericas por error y ayuda
- Balance exacto por dificultad
- Tiempo offline maximo permitido antes de bloqueo
- Limite de reenvio de correo de verificacion
- Reglas tecnicas del historial de deshacer/rehacer
- Validacion final en servidor
- Detecciones avanzadas de fraude

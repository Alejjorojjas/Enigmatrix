# Enigmatrix - Arquitectura

## Objetivo de este documento
Definir las decisiones tecnicas base para construir Enigmatrix V1.

Cubre:

- stack mobile
- backend
- modelo de datos
- API principal
- autenticacion y verificacion
- arquitectura antitrampa
- conectividad y modo online
- reto diario y autoridad de tiempo
- vidas y autoridad de servidor
- rankings y leaderboards
- notificaciones push
- analitica
- localizacion
- build, release y configuracion remota
- riesgos y mitigaciones

## Principios base

### Principios tecnicos
- el servidor es la autoridad para todo lo oficial: solucion, ranking, vidas, racha, reto diario
- el cliente nunca conoce la solucion del caso durante la partida
- la app es online de extremo a extremo
- el cliente puede hacer prevalidaciones rapidas para feedback, pero el servidor manda
- preferimos servicios manejados antes que infra propia para llegar al MVP rapido
- toda decision se evalua por: time to market, costo en escala temprana, capacidad de migrar despues

## Stack mobile

### Recomendacion principal: Flutter
Razones:

- una sola base de codigo para Android y iOS
- desempeno suficiente para UI con drag, animaciones de tablero y notas
- ecosistema maduro de paquetes para Firebase, anuncios, IAP y notificaciones
- buena experiencia de animacion y gestos para el tipo de interaccion del juego
- compatible con la estrategia Android primero, iOS despues, sin reescritura

### Alternativas consideradas
- Kotlin nativo Android: mejor desempeno bruto, pero obliga a reescribir para iOS
- React Native: peor para gestos finos y animacion continua tipo arrastre
- Unity o Godot: utiles si el juego fuera mas grafico, sobreestructura para esta UI
- Godot 4: opcion seria si despues se necesita render mas custom

### Stack del proyecto Flutter
- gestion de estado: `Riverpod` o `Bloc`
- enrutamiento: `go_router`
- animaciones de tablero: framework propio sobre `CustomPainter` y `GestureDetector`
- almacenamiento local: `Hive` o `Isar` para cache de partida pendiente
- internacionalizacion: `intl` con archivos `arb`

## Backend

### Recomendacion principal para V1: Firebase
Razones:

- Auth con Google y email integrado de fabrica
- Firestore como base de datos sincronizable
- Cloud Functions para logica oficial de validacion
- FCM para notificaciones push
- Remote Config para activar y ajustar parametros sin actualizar la app
- Crashlytics y Analytics integrados
- plan gratuito cubre los primeros usuarios sin costo

### Riesgos de Firebase y como mitigarlos
- vendor lock in: aislar la logica del backend tras una capa de servicios en la app
- costos en escala: monitorizar lecturas de Firestore desde el inicio
- consultas pobres para rankings: usar agregaciones precalculadas y un servicio dedicado para top N

### Alternativas consideradas
- Supabase: Postgres + Auth + Edge Functions, mejor para queries SQL de ranking, mas trabajo inicial
- Backend custom Node o Go en Cloud Run con Postgres: maximo control, no recomendado para MVP

## Servicios de servidor

### Cloud Functions
Responsables de:

- entregar el caso del dia segun calendario
- entregar mapa y caso oficial sin la solucion
- recibir y validar la solucion oficial al pulsar Resolver
- actualizar puntos, ranking, vidas, racha, intentos
- registrar uso de ayudas y errores
- validar compras y activar premium
- regenerar vidas
- gestionar el bloqueo de partida pendiente

### Servicio de leaderboards
- en V1 puede vivir como coleccion agregada en Firestore con escritura desde Cloud Functions
- si crece, migrar a un servicio dedicado tipo Redis sorted sets sobre Cloud Run
- nunca calcular el ranking entero en cliente

### Almacenamiento de assets
- Cloud Storage para mapas, sprites y avatares
- CDN delante para reducir latencia
- versionado por hash para invalidar cache cuando cambie un asset

## Modelo de datos

### Coleccion users
- id de usuario
- proveedor: google o email
- email
- email verificado
- nickname
- fecha de cambio de nickname
- avatar
- bandera o pais
- fecha de creacion
- fecha de ultimo acceso
- estado premium
- tipo de plan premium
- fecha de expiracion premium
- vidas activas
- vidas extra
- timestamp de ultima recarga
- racha actual
- mejor racha
- protectores de racha disponibles
- mundo actual desbloqueado
- partida oficial pendiente si existe
- preferencias: idioma, modo de notas por defecto, sonido, musica, vibracion, notificaciones

### Coleccion maps
- id de mapa
- mundo
- orden dentro del mundo
- layout y habitaciones
- objetos visibles fijos
- armas potenciales visibles posibles
- assets visuales referenciados por hash
- version

### Coleccion cases
- id de caso
- mapa base
- tipo: oficial, practica, reto diario, tutorial
- etiqueta de dificultad
- definicion completa: sospechosos, victima, arma si aplica, pistas
- solucion: solo accesible desde Cloud Functions
- metricas: pasos de deduccion, conteo de pistas, dependencias

### Coleccion daily_challenges
- fecha
- caso asignado
- estado: programado, activo, cerrado
- ventana valida en hora servidor

### Coleccion attempts
- id de intento
- usuario
- caso
- tipo: oficial, practica, reto diario, tutorial
- estado: en progreso, completado, abandonado, invalido
- timestamp de inicio
- timestamp de cierre
- tiempo transcurrido oficial
- errores de resolver
- ayudas usadas
- puntos finales
- orientacion del mapa para ese jugador
- razon de invalidacion si aplica

### Coleccion rankings_map
- mapa
- usuario
- mejor tiempo oficial
- puntos asociados
- timestamp del registro

### Coleccion rankings_daily
- fecha
- usuario
- tiempo
- puntos

### Coleccion rankings_weekly
- semana
- usuario
- puntos acumulados de retos diarios validos en la semana

### Coleccion purchases
- id de compra
- usuario
- producto
- proveedor: Google Play o App Store
- token de validacion
- estado: pendiente, valida, fallida, reembolsada
- timestamp

### Coleccion live_ops
- protectores de racha entregados
- eventos manuales aplicados a un usuario
- ajustes manuales de soporte

## API principal

### Auth
- registro con email y contrasena
- login con email y contrasena
- login con Google
- envio y verificacion de correo
- cambio de contrasena
- cierre de sesion
- eliminacion de cuenta

### Perfil
- crear o actualizar nickname y bandera
- subir o cambiar avatar predeterminado
- consultar perfil propio
- consultar perfil publico de otro usuario

### Contenido
- obtener lista de mundos desbloqueados
- obtener lista de mapas de un mundo
- obtener pantalla previa de un mapa
- obtener caso oficial de un mapa para iniciar
- obtener caso de practica disponible
- obtener caso de reto diario del dia
- continuar caso pendiente

### Partida
- iniciar intento oficial
- continuar intento oficial pendiente
- enviar solucion para validacion
- registrar uso de ayuda
- registrar abandono explicito
- registrar perdida de validez por desconexion prolongada

### Vidas
- consultar estado de vidas
- recargar vidas con anuncio
- consumir vida tras error oficial
- aplicar paquete de vidas comprado

### Ranking
- top N por mapa
- top N reto diario por dia
- top N semanal
- bloque alrededor del usuario

### Tienda
- listar productos disponibles
- iniciar compra
- validar compra y entregar contenido
- restaurar compras

### Soporte y configuracion remota
- obtener parametros remotos de balance, anuncios y feature flags
- enviar mensaje de soporte
- consultar estado de cuenta para soporte

## Autenticacion y verificacion

### Login
- Google: confianza directa, usuario queda verificado
- Email y contrasena: requiere verificacion para reto diario y rankings

### Verificacion de correo
- correo de verificacion al registro
- enlace caduca tras un tiempo razonable
- limite de reenvio para evitar abuso, valor exacto pendiente
- la app permite jugar tutorial, campana y practica sin verificar
- bloquea reto diario y rankings hasta verificar

### Eliminacion de cuenta
- soft delete inicial: cuenta marcada como eliminada, datos personales anonimizados
- hard delete tras un periodo definido
- el nickname queda reservado un tiempo para evitar suplantacion inmediata
- politica concreta de tiempos: pendiente

### Vinculacion entre proveedores
- no entra en V1
- definido en futuro

## Arquitectura antitrampa

### Reglas base
- el cliente nunca recibe la solucion del caso durante la partida
- la validacion oficial siempre se hace en Cloud Functions
- el ranking, los puntos, las vidas y la racha solo se actualizan tras validacion del servidor
- el servidor controla los timestamps oficiales de inicio y cierre del intento
- el cliente puede mostrar un cronometro local, pero el oficial es el del servidor

### Manipulacion de hora del dispositivo
- el dia del reto diario se calcula con hora del servidor
- la regeneracion de vidas se calcula con hora del servidor
- la racha se evalua con hora del servidor
- la app ignora cambios manuales de hora local para todo lo oficial

### Multidevice
- una sola sesion oficial activa por usuario
- iniciar sesion en otro dispositivo con partida pendiente:
  - se mantiene la pendiente vinculada al usuario, no al dispositivo
  - se sincroniza el estado al iniciar
- el caso pendiente vive en servidor, no solo en cache local

### Captura y grabacion
- bloqueo de capturas en partidas oficiales con `FLAG_SECURE` en Android
- en iOS bloqueo equivalente cuando exista
- no aplica a tutorial, practica, como jugar

### Rotacion del mapa
- aplicada en cliente solo como presentacion visual
- la solucion no depende de la rotacion
- el servidor recibe la solucion en coordenadas logicas, no rotadas

### Ofuscacion del payload
- payload del caso comprimido y firmado
- ids internos rotativos
- no es seguridad criptografica fuerte, es disuasion contra sniffing trivial

### Detecciones avanzadas
- no entran a V1
- definidas en futuro: tiempos imposibles, patrones sospechosos, validacion mas profunda

## Conectividad y modo online

### Reglas de partida online
- toda partida oficial requiere conexion para iniciar
- partida en curso puede tolerar perdida de conexion por un tiempo limitado
- valor exacto del tiempo tolerado: pendiente
- al superar el limite:
  - bloqueo del tablero
  - no se ven pistas
  - mensaje de sin conexion
- al recuperar conexion: reintento automatico

### Cache local
- cache local para partida pendiente y estado de UI
- en `Isar` o `Hive`
- no es fuente de verdad oficial
- si se borra, el intento oficial puede invalidarse y el caso queda como `mapa sin resolver`

### Sincronizacion
- al iniciar la app, el cliente sincroniza con servidor:
  - estado de cuenta
  - vidas reales
  - partida pendiente real
  - reto diario activo
- los conflictos los resuelve el servidor

## Reto diario y autoridad de tiempo

### Reglas
- el dia se calcula con hora del servidor en zona horaria del juego
- zona horaria del juego: pendiente, se recomienda UTC con corte fijo
- el reto del dia esta listo en servidor antes del corte
- el cliente solicita el reto del dia y lo recibe sin solucion

### Estados
- programado en cola
- activo dentro de la ventana del dia
- cerrado tras la ventana

### Caso fuera de tiempo
- si el usuario juega un reto cuya ventana ya cerro:
  - puede terminarlo si tiene intento iniciado
  - no cuenta para ranking, racha ni puntos semanales

## Vidas y autoridad de servidor

### Estado oficial
- el estado de vidas vive en servidor
- el cliente lo consulta y lo refleja, pero no lo dicta

### Recarga
- tabla de regeneracion: una vida por hora
- se calcula con hora del servidor
- si el cliente intenta consumir mas vidas de las que tiene, el servidor rechaza

### Vidas extra
- compradas y validadas con el proveedor de pagos
- entregadas por Cloud Functions tras validar el recibo
- nunca se entregan vidas extra solo por mensaje del cliente

## Rankings y leaderboards

### Estrategia para V1
- escritura unica desde Cloud Functions tras validar partida
- Firestore como almacenamiento principal
- documentos de top N por mapa, dia y semana, mantenidos por funciones programadas
- bloque alrededor del usuario calculado en query con orden por el campo correspondiente

### Estrategia si no escala
- migrar a un servicio dedicado tipo Redis sorted sets en Cloud Run
- mantener API estable para que el cliente no se entere

### Limites a aceptar
- el ranking puede tener latencia de algunos segundos tras enviar la partida
- el ranking semanal cierra en una hora exacta del servidor

## Notificaciones push

### Canales en V1
- recordatorio de reto diario disponible
- aviso de racha en peligro al final del dia
- aviso de vidas llenas tras recarga total
- aviso de cierre del reto del dia proximo

### Reglas
- todas opt in
- respetan el toggle de la app
- ninguna es comercial pura en V1
- horario por zona horaria del usuario, definido al iniciar sesion

## Analitica

### Eventos minimos en V1
- registro completado
- verificacion de correo completada
- tutorial iniciado
- tutorial completado
- partida iniciada por tipo
- partida completada por tipo
- partida abandonada por tipo
- error de resolver
- ayuda usada
- compra iniciada
- compra completada
- compra fallida
- racha incrementada
- racha rota
- protector de racha consumido
- desconexion durante partida
- intento invalidado por desconexion

### KPIs base
- DAU
- MAU
- D1, D7, D30
- conversion a premium
- ARPDAU
- tasa de completado de tutorial
- tasa de completado de mundo 1
- intentos diarios por usuario
- ratio de exito por etiqueta de dificultad

## Localizacion

### V1
- idioma principal: `espanol`
- idioma secundario disponible: `ingles`
- el espanol es el por defecto del juego
- el ingles se ofrece como opcion en configuracion
- archivos `arb` por idioma
- contenido textual del juego separado del codigo
- pistas y reglas localizables
- nombres de armas y mundos localizables
- nicknames no se traducen

### Reglas de calidad
- ninguna pista debe perder coherencia logica al traducirse
- los textos con variables siempre usan placeholders
- los textos largos se revisan por longitud en pantallas pequenas

## Build, release y configuracion remota

### Pipelines
- CI por cada push a rama principal
- build interno automatico para QA
- build de pruebas cerradas en Google Play Console
- build de produccion solo desde rama de release

### Versionado
- semver para la app
- bandera de version minima soportada en servidor
- la app revisa su version al arrancar y obliga a actualizar si es menor que la minima

### Remote Config
- tasas de regeneracion de vidas
- precios mostrados
- ventanas exactas de reto diario
- feature flags para anuncios, premium y secciones nuevas
- listas de armas y distribuciones por mundo si se quieren ajustar sin release

### Tienda y compras
- Google Play Billing para Android
- App Store para iOS cuando aplique
- validacion de recibos en Cloud Functions
- restauracion de compras desde el cliente

## Riesgos y mitigaciones

### Riesgo: costo de Firestore con muchos jugadores
Mitigacion:

- agregar lecturas en documentos resumen
- evitar consultas en tiempo real para rankings
- cache fuerte en cliente para datos casi estaticos

### Riesgo: latencia de validacion oficial al pulsar Resolver
Mitigacion:

- prevalidacion local rapida para feedback inmediato
- spinner corto y mensaje claro mientras llega la validacion oficial
- region del backend cercana al mercado principal

### Riesgo: bloqueo de captura impacta accesibilidad
Mitigacion:

- mantener bloqueo solo en pantalla de partida oficial
- permitir captura en tutorial, como jugar y practica
- documentar limitacion para usuarios de lectores de pantalla

### Riesgo: vendor lock in en Firebase
Mitigacion:

- aislar acceso a Firebase tras una capa de servicios en la app
- mantener un schema portable a Postgres
- definir desde el inicio que el modelo de datos podria migrarse

### Riesgo: ataque por manipulacion de cliente
Mitigacion:

- nada oficial se decide en cliente
- toda accion oficial pasa por Cloud Functions
- payload del caso sin solucion
- validacion de compras siempre en servidor

### Riesgo: zona horaria y reto diario
Mitigacion:

- corte fijo en hora del servidor
- mostrar al usuario la hora local equivalente del proximo cierre
- nunca dejar la decision del dia al cliente

## Pendientes que dependen de otras decisiones

- proveedor exacto de anuncios y formatos
- precios reales de premium, packs de vidas y protectores
- tiempo exacto de tolerancia offline durante partida
- ventana de validez del enlace de verificacion de email
- limite de reenvio de email de verificacion
- politica exacta de retencion del nickname tras eliminar cuenta
- region principal del backend

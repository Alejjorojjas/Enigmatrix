# Enigmatrix - Audio

> ACTUALIZACIÓN 04-11-2026: **hoy la app no tiene audio.** No hay sonidos, música ni vibración, y `app/pubspec.yaml` no incluye ningún paquete de audio ni de vibración (comprobado el 04-11-2026). En Configuración existen los interruptores "Sonido", "Música" y "Vibración", pero solo guardan la preferencia y no controlan nada todavía.
>
> El audio entra en la **etapa 4 (producción visual)** del plan aprobado el 04-11-2026, junto con el game feel, y solo si pasan la prueba de juego y la prueba de concepto gráfica. La estrategia de costo casi cero (10 a 15 sonidos clave, vibración, motor de audio y presupuesto estimado) está en la [sección 6 del informe de investigación gráfica](../production/revisiones/2026-11-04-investigacion-grafica.md). Cuando se llegue a esa etapa, este documento se revisa contra ese informe; mientras tanto, lo de abajo es la intención original (junio de 2026), no algo construido.

## Objetivo de este documento
Definir la direccion de audio de Enigmatrix V1, los efectos minimos necesarios y la estrategia de produccion.

Cubre:

- direccion sonora general
- musica por mundo
- musica de pantallas no jugables
- efectos de juego SFX
- reglas de mezcla y volumen
- accesibilidad de audio
- formatos y peso
- pipeline de produccion
- pendientes

## Direccion sonora general

### Tono
- discreto, no invasivo
- elegante, en linea con la identidad visual
- atmosferico mas que melodico en partida
- melodico en pantallas de salida y celebracion

### Reglas
- la musica de partida no compite con el razonamiento del jugador
- los SFX son cortos, claros y consistentes
- el silencio es valido, no se rellena por miedo a un vacio
- ningun audio comunica informacion critica sin reforzador visual

## Musica por mundo

### Estrategia
- cada mundo tiene un loop musical propio
- el loop dura entre 60 y 120 segundos antes de repetir
- el cambio de mundo cambia la musica
- los retos diarios usan una variante propia con un tema reconocible

### Mansion
- instrumentos: clavecin, cuerdas suaves, piano
- estilo: barroco ligero, elegante, tension contenida
- tempo: lento

### Hotel
- instrumentos: piano, contrabajo suave, cepillos en bateria
- estilo: jazz lounge, sofisticado
- tempo: medio bajo

### Museo
- instrumentos: cuerdas, arpa, ambient electronico discreto
- estilo: contemplativo, casi minimalista
- tempo: muy lento

### Tren
- instrumentos: guitarra acustica, percusion ligera evocando ritmo de via, contrabajo
- estilo: jazz blues con sensacion de viaje
- tempo: medio

### Hospital
- instrumentos: piano filtrado, ambient electronico, cuerdas largas
- estilo: minimalista, levemente clinico, no incomodo
- tempo: lento, casi sin pulso

### Reto diario
- variante con un tema reconocible que vive en todos los retos diarios
- mezcla con instrumentacion neutra que no pertenezca a ningun mundo en particular
- crea identidad propia del reto del dia

## Musica de pantallas no jugables

### Inicio y mundos
- musica suave continua
- volumen bajo
- no compite con tarjetas y CTA

### Resumen y celebracion
- pista corta de cierre con caracter
- variantes para mapa, mundo y reto diario
- la celebracion de desbloqueo de mundo permite hasta 2 segundos con caracter mas intenso

### Tienda y configuracion
- musica neutra calma
- volumen menor que en inicio

### Tutorial
- musica calma con mas presencia que en partida normal para ambientar
- no incluye tema fuerte para no distraer

## Efectos de juego SFX

### Lista base V1

#### Interaccion con elementos
- tap en avatar del panel: tono breve discreto
- tap en X del panel: tono breve discreto distinto
- inicio de arrastre: tono muy corto
- soltar elemento en casilla: tono suave de confirmacion
- soltar elemento en papelera: tono ligero de borrado
- ciclo de estado de pista: tono muy breve

#### Tablero
- error al pulsar Resolver: tono claro de error
- exito al pulsar Resolver: tono claro de exito con caracter
- ayuda usada: tono breve neutro
- limpiar tablero: tono medio neutro
- deshacer: tono muy breve
- rehacer: tono muy breve diferenciado de deshacer

#### Cuenta y vidas
- ganar vida por anuncio: tono positivo corto
- perder vida: tono negativo corto pero no agresivo
- compra exitosa: tono claro positivo
- vidas llenas: tono breve no destacado

#### Reto diario y racha
- abrir reto diario: tono identitario reconocible
- racha mantenida: tono positivo corto
- racha protegida: variante con caracter de salvamento
- racha rota: tono neutro, nunca punitivo

#### Sistema y navegacion
- entrada a una pantalla mayor: tono muy discreto
- aparicion de modal: tono breve
- error de conexion: tono neutro discreto
- recuperacion de conexion: tono neutro positivo

### Reglas de uso de SFX
- cada SFX tiene una unica funcion en toda la app
- ningun SFX se reutiliza para una accion distinta
- la duracion de cualquier SFX no supera 600 milisegundos
- la cola de SFX nunca apila mas de 3 sonidos en simultaneo

## Reglas de mezcla y volumen

### Niveles base
- musica: nivel medio bajo
- SFX: nivel medio
- voz si existiera: nivel medio alto, prioritario

### Reglas
- al sonar un SFX critico, la musica baja un poco automaticamente
- los SFX de ciclo nunca son mas fuertes que los SFX de Resolver
- el silencio total esta permitido cuando el jugador asi lo configure

### Toggles del jugador
- musica on off
- SFX on off
- vibracion on off
- los toggles persisten entre sesiones

## Accesibilidad de audio

### Reglas
- ningun audio comunica informacion critica sin reforzador visual
- el feedback de error siempre tiene refuerzo visual y de SFX, pero el visual basta por si solo
- jugar con todo el audio apagado es una experiencia completa, no degradada
- las animaciones de celebracion no requieren musica para entenderse

### Subtitulos
- no aplican en V1 porque no hay narracion hablada
- si en futuro hay narracion, subtitulos obligatorios

## Formatos y peso

### Formatos
- musica: OGG o AAC comprimido
- SFX: OGG corto o WAV ligero

### Tamano objetivo
- musica por mundo: hasta 1 megabyte por loop principal
- variante de reto diario: hasta 1 megabyte
- SFX completos: hasta 2 megabytes en total
- presupuesto total de audio en V1: hasta 12 megabytes

### Estrategia de carga
- audio de pantallas comunes incluido en el binario inicial
- musica por mundo cargada al desbloquearse el mundo
- SFX siempre disponibles desde el binario inicial

## Pipeline de produccion

### Roles
- compositor o proveedor de musica
- diseñador de SFX o curaduria de libreria
- responsable de mezcla y mastering
- integrador en la app

### Flujo
1. brief de mood por mundo y por pantalla
2. boceto musical por mundo
3. revision contra direccion visual y pillars
4. produccion final
5. mastering uniforme entre mundos
6. exportacion en formato y peso objetivo
7. integracion con triggers definidos en codigo
8. revision en dispositivo real con auriculares y altavoz movil

### Origen de la musica
Decision V1: sin presupuesto de composicion. Se usa libreria licenciada con derechos comerciales, priorizando opciones gratuitas verificadas.

Estrategia:

- curaduria de pistas con licencia comercial libre o muy economica
- fuentes recomendadas:
  - Pixabay Music: musica con licencia gratuita uso comercial
  - Free Music Archive: pistas Creative Commons compatibles
  - YouTube Audio Library: musica sin royalties
  - Incompetech de Kevin MacLeod: con atribucion CC BY
  - Uppbeat: gratis con cuenta, plan pago opcional
- evitar pistas que solo permitan uso no comercial
- evitar pistas que exijan atribucion en pantalla si no hay creditos

### Reglas de licencia gratuita
- guardar prueba escrita de la licencia de cada pista en banco interno
- guardar fecha de descarga y URL de origen
- preferir CC0 o licencia comercial libre sin atribucion
- si la licencia exige atribucion, agregar a la seccion de creditos en `Como jugar` o `Soporte`

### Cuando aparezca presupuesto
- pasar a libreria pagada tipo Epidemic Sound o Soundstripe para mayor calidad y consistencia
- evaluar composicion original solo para el tema del reto diario
- migrar pistas reemplazando una por una sin romper la integracion existente

### Origen de SFX
Decision V1: SFX 100 por ciento gratuitos con licencia comercial verificada.

Fuentes recomendadas:

- Freesound: gran banco con filtros por licencia, preferir CC0
- Pixabay Sound Effects: gratis para uso comercial
- Zapsplat: gratis con cuenta, atribucion opcional segun plan
- Mixkit: gratis para uso comercial sin atribucion

### Reglas para SFX
- guardar prueba escrita de la licencia de cada SFX en banco interno
- preferir CC0 o equivalente sin atribucion
- evitar SFX con licencia ambigua o sin documento de respaldo
- normalizar volumen entre SFX descargados de fuentes distintas

## Pendientes
- curaduria final de las pistas concretas por mundo desde libreria gratuita
- decidir si el reto diario usa un jingle distintivo o solo variante de tema
- decidir si las pistas tienen lectura sintetica en futuro
- definir loops alternativos para sesiones largas en un mismo mundo
- evaluar migracion a libreria pagada cuando exista presupuesto

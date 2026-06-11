# Enigmatrix - Art Bible

## Objetivo de este documento
Definir la direccion visual de Enigmatrix para que el equipo de arte, diseno y producto tomen decisiones consistentes.

Cubre:

- mood e identidad visual general
- paleta de color
- tipografia
- estilo de mapas
- estilo de avatares
- estilo de objetos y armas
- identidad por mundo
- simbolos del tablero
- iconografia de UI
- modos claro y oscuro
- animaciones y feedback visual
- pipeline de assets
- especificaciones tecnicas

Este doc se subordina a los `pillars`. Si una decision visual rompe un pillar, manda el pillar.

## Mood e identidad

### Tono
- misterio detectivesco contemporaneo
- cartoon limpio con calidez
- ilustrado con personalidad propia
- accesible para audiencia amplia
- visualmente vendedor sin caer en saturacion casino

### Referencias inspiracionales
- estilo grafico de juegos de mesa modernos para mobile, tipo apps de Clue Mystery o Hidden Folks
- ilustracion estilo storybook moderno
- Stardew Valley por la calidez y la calidad de la ilustracion top-down
- Animal Crossing por el equilibrio entre cartoon y elegancia
- Toca Boca por la claridad cartoon sin ser infantil
- Monument Valley por la composicion limpia y la profundidad ligera

### Lo que no es Enigmatrix visualmente
- no es realismo fotografico
- no es horror ni thriller oscuro
- no es pixel art
- no es flat extremo sin sombras ni vida
- no es cartoon infantil tipo bebe
- no es chrome casino tipo Parchis Star, Coin Master o Candy Crush
- no es minimalismo vacio sin personalidad

## Paleta de color

### Paleta base neutra
Para fondos, mapas y UI base.

- crema oscuro: usado en fondos calidos generales
- gris piedra: usado en superficies y separadores
- marfil: usado en areas de UI clara
- carbon: usado en texto principal y bordes
- gris carbon: usado en texto secundario y deshabilitados

### Paleta de feedback
Estos colores tienen significado funcional fijo y nunca se reasignan.

- rojo error: feedback de error y penalizacion
- verde exito: feedback de confirmado y completado
- azul informativo: tooltips, estados destacados, ayudas
- amarillo alerta: avisos previos a accion irreversible
- morado especial: reto diario y elementos de racha

### Paleta tematica por mundo
Cada mundo tiene una paleta secundaria propia que tine fondos, ilustraciones y headers.

- Mansion: ocres calidos, vino, madera oscura
- Hotel: dorados, navy profundo, beige
- Museo: marmol claro, piedra, azul polvo
- Tren: verde oliva, latón, marron tabaco
- Hospital: blanco hueso, menta clinica, gris azulado

### Reglas de uso
- la paleta tematica nunca pisa los colores de feedback
- el contraste entre texto y fondo cumple WCAG AA en todos los modos
- el feedback de color siempre va acompanado de forma o icono para accesibilidad

## Tipografia

### Familia principal
- recomendacion: una sans serif geometrica con personalidad media
- candidatas a probar: `Inter`, `DM Sans`, `Manrope`
- decision final: pendiente tras prueba en pantallas reales

### Familia secundaria
- recomendacion: una serif con caracter editorial para titulos y nombre del juego
- candidatas: `Fraunces`, `Playfair Display`
- usada solo en titulos, headers de mundo y nombre del juego

### Familia terciaria manuscrita
- recomendacion: una manuscrita o script con personalidad para los nombres de sospechosos en sus polaroids
- candidatas: `Caveat`, `Patrick Hand`, `Kalam`
- usada exclusivamente para nombres de sospechosos y firmas decorativas
- nunca se usa para texto funcional ni botones

### Reglas
- jerarquia clara con como mucho 4 tamanos por pantalla
- pueden coexistir hasta 3 familias en pantalla cuando hay polaroid de sospechoso
- el numero del cronometro y los puntos usan la sans en peso medio
- los nombres de caso y mundo pueden usar la serif
- los nombres de sospechosos usan exclusivamente la manuscrita

## Estilo de mapas

### Perspectiva
- top down con leve perspectiva 3/4
- las habitaciones se ven desde arriba como planos abiertos
- los objetos tienen volumen claro, ilustrados estilo cartoon
- el conjunto se siente como una maqueta o tablero de juego de mesa modernizado

### Acabado
- cartoon limpio con sombras suaves
- bordes definidos, lineas con peso visible
- texturas amables para materiales: madera, marmol, tela, metal, plantas
- colores calidos y saturados con cuidado, sin chillar
- cada habitacion tiene identidad clara por color de piso, mobiliario y luz

### Composicion
- el mapa ocupa el espacio principal de la pantalla de partida
- las habitaciones llevan nombre visible en mayusculas dentro de su area
- las paredes se sugieren con bordes oscuros gruesos, no se dibujan como muros
- la casilla seleccionada se resalta con borde acento navy y fondo claro
- la habitacion seleccionada se contornea con borde acento navy
- el mapa entero tiene una sombra inferior que da profundidad de tablero

### Mobiliario y objetos
- ilustrados claramente, reconocibles de un vistazo
- escalados al espacio de su habitacion
- consistentes con el tema del mundo
- las armas potenciales son objetos concretos visibles, integrados en su habitacion
- las plantas, alfombras, mesas y sofas tienen estilo unificado entre mundos pero variantes propias

### Reglas
- la rotacion del mapa por jugador no debe deformar la lectura
- los textos dentro del mapa siempre se mantienen orientados al usuario
- las casillas son comprensibles sin contar cuadricula
- las armas potenciales son discretas pero claramente identificables al acercarse

## Estilo de avatares

### Direccion
- retratos ilustrados estilo cartoon limpio
- presentados en formato `polaroid`: marco oscuro grueso, retrato en tarjeta
- cada avatar tiene fondo de color solido distintivo para reforzar identidad y memoria
- el color de fondo del avatar se reutiliza en su card de pista asociada
- nombre debajo del retrato en tipografia manuscrita o script, con personalidad
- expresivos, identificables de un vistazo
- silueta unica por sospechoso para distinguirse a baja resolucion
- proporciones ligeramente estilizadas, no caricatura extrema

### Reglas de uso en el panel y el tablero
- en el panel fijo: polaroid completa con marco, fondo de color y nombre script
- avatar grande sobre tablero: cuando esta confirmado, mantiene el fondo de color y agrega flecha verde distintiva
- avatar pequeno sobre tablero: cuando esta como candidato, version reducida con signo de interrogacion
- color y silueta deben funcionar en `90 por ciento` de gris
- el fondo de color del avatar nunca usa los colores funcionales rojos, verdes ni amarillos para evitar conflicto con feedback

### Diversidad
- diversidad real de tonos de piel, edades, generos y rasgos
- sin estereotipos ofensivos
- vestuario apropiado al mundo donde aparecen
- cada mundo tiene su propio set de avatares con vestuario coherente

### Pistas asociadas
- cada pista vive en una card pastel que toma el color de fondo del sospechoso al que se refiere
- las palabras clave en la pista van en negrita
- las cards de pistas se alinean visualmente con su sospechoso correspondiente cuando es posible

## Estilo de objetos y armas

### Objetos del mapa
- ilustrados con el mismo estilo del mapa
- proporcionados al espacio de su habitacion
- contribuyen a identificar el mundo
- sirven como anclajes visuales para pistas

### Armas potenciales
- discretas en el mapa, claramente identificables al acercarse
- visualmente coherentes con el mundo donde aparecen
- la misma arma puede tener variantes visuales por mundo
- siempre del mismo tamano dentro de un mismo mundo

## Identidad por mundo

### Reglas comunes
- cada mundo tiene una `ilustracion principal del edificio` que lo representa, en estilo cartoon limpio
- esa ilustracion aparece en la pantalla de Mundos como protagonista del mundo
- cada mundo tiene paleta secundaria propia que tine fondos, headers y mobiliario interno
- cada mundo tiene una clase de mobiliario y materiales caracteristicos
- la silueta del edificio se reconoce sin leer el nombre
- los mundos NO se representan como islas flotantes ni dioramas 3D pesados, sino como ilustraciones cartoon claras del edificio

### Mansion
- materiales: madera oscura, terciopelo, oro envejecido
- atmosfera: aristocratica, calida, decadente
- elementos comunes: candelabros, retratos, alfombras gruesas
- iluminacion: amarilla calida

### Hotel
- materiales: marmol pulido, metal dorado, tapizados firmes
- atmosfera: lujosa, ordenada, levemente impersonal
- elementos comunes: lobby, ascensor, recepcion, suites
- iluminacion: blanca calida con acentos puntuales

### Museo
- materiales: piedra, marmol blanco, vitrinas de cristal
- atmosfera: silenciosa, monumental, organizada
- elementos comunes: vitrinas, esculturas, paneles informativos
- iluminacion: blanca neutra dirigida

### Tren
- materiales: madera barnizada, latón, cuero gastado
- atmosfera: cerrada, en movimiento, intima
- elementos comunes: vagones conectados, ventanas con paisaje, mesas plegables
- iluminacion: amarilla baja y desigual

### Hospital
- materiales: blanco hueso, acero inoxidable, vinilo claro
- atmosfera: clinica, ordenada, levemente fria
- elementos comunes: camillas, biombos, carros medicos
- iluminacion: blanca clinica plana

## Simbolos del tablero

### Reglas universales
- cada simbolo es identificable sin color
- cada simbolo es identificable sin tamano
- la diferencia entre estados es clara incluso a baja resolucion
- el mismo simbolo siempre significa lo mismo en toda la app

### Candidato
- avatar pequeno con un signo de interrogacion superpuesto
- el simbolo de interrogacion es visible aunque el color falle

### Confirmado
- avatar grande con una flecha verde indicadora
- la silueta es clara
- la flecha tiene una forma distintiva, no solo color

### Descarte parcial X pequena
- X delgada de tamano reducido
- color por defecto: negro o gris muy oscuro

### Descarte fuerte X grande
- X gruesa de tamano mayor
- color por defecto: negro o gris muy oscuro

### Reglas de accesibilidad
- el feedback de exito y error nunca depende solo del color
- las casillas resaltadas por error usan tambien una textura o borde
- el modo daltonico se contempla con paleta alterna

## Iconografia de UI

### Estilo
- linear con grosor consistente
- tamano normalizado a una grilla base
- esquinas suaves
- relleno solo cuando representa estado activo

### Conjunto base
- ayudas
- limpiar tablero
- deshacer
- rehacer
- papelera
- notas separadas
- notas superpuestas
- ranking
- tienda
- premium
- configuracion
- compartir
- vidas
- racha
- protector
- reto diario

### Reglas
- ningun icono debe necesitar texto explicativo en su uso normal
- la papelera tiene feedback visual claro al pasar elementos por encima
- los iconos de estado tienen variante activa, inactiva y deshabilitada

## Modos de tema

### Modo claro
- fondo crema o marfil
- texto carbon
- mapas con su paleta tematica natural
- modo por defecto

### Modo oscuro
- fondo carbon profundo
- texto marfil
- mapas con paleta tematica adaptada para no brillar de mas
- los acentos de feedback bajan saturacion 1 paso
- protege la lectura nocturna

### Reglas
- el cambio de tema no rompe la coherencia de la paleta tematica
- ningun mundo se ve casi igual a otro en ningun modo
- las animaciones funcionan igual en ambos modos

## Animaciones y feedback visual

### Principios
- toda accion tiene respuesta visual inmediata
- las animaciones nunca bloquean al jugador mas tiempo del necesario
- el cuerpo del feedback respeta la paleta funcional
- ninguna animacion supera 600 milisegundos

### Lista base
- arrastre de avatar al tablero
- colocacion de candidato y confirmado
- borrado por papelera con feedback de hover
- error de resolver con casillas pulsando rojo
- exito de resolver con luz verde sobre el tablero
- desbloqueo de mundo con animacion celebratoria mas larga, hasta 2 segundos

## Pipeline de assets

### Roles
- artista de fondos y mapas
- artista de avatares
- artista de objetos y armas
- artista de UI
- director de arte para coherencia

### Flujo de creacion
1. brief con mundo, paleta y referencias
2. boceto en blanco y negro
3. revision interna
4. paso a color con la paleta tematica
5. exportacion en los formatos requeridos
6. registro en el catalogo de assets con version

### Formatos
- ilustraciones de mapa: vector cuando sea posible, raster a 3 resoluciones
- avatares: vector y raster a 3 resoluciones
- iconos UI: vector
- todos exportados a formato moderno comprimido
- nombres con convencion estricta: mundo, tipo, identificador, version

### Convencion de nombres
- patron base: `mundo_tipo_id_version.ext`
- ejemplos: `mansion_avatar_butler_v1.png`, `museo_arma_busto_v2.svg`

## Especificaciones tecnicas

### Resoluciones objetivo
- baja: pantallas pequenas, equivalente a 1x
- media: pantallas medianas, equivalente a 2x
- alta: pantallas grandes y tablets, equivalente a 3x

### Formatos
- vectorial: SVG cuando sea posible
- raster: WebP comprimido para entrega final
- raster fuente: PNG sin compresion

### Tamano del paquete
- ilustraciones empacadas en bundles por mundo
- carga inicial trae solo el mundo activo
- los mundos siguientes se cargan al desbloquearse
- recomendacion: mantener el binario inicial por debajo de 80 megabytes

### Tema oscuro
- variantes empacadas como overrides, no como assets totalmente separados, cuando sea posible
- el cambio de tema no requiere descargar nuevos assets

## Pendientes
- decision final de tipografia tras prueba en pantalla
- definir paleta exacta en valores hex con nombres oficiales
- ajustar set de iconos a la familia tipografica elegida
- definir personajes recurrentes una vez que exista el doc de narrativa
- guia oficial de modo daltonico con paleta alterna

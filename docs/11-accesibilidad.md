# Enigmatrix - Accesibilidad

## Objetivo de este documento
Definir los requisitos minimos de accesibilidad de Enigmatrix V1, para que el juego sea jugable por la mayor cantidad posible de personas sin sacrificar el diseno.

Cubre:

- estandar de referencia
- color y contraste
- daltonismo
- texto y escala
- objetivos de toque y motricidad
- navegacion por lectores de pantalla
- subtitulos y audio alternativo
- preferencias de movimiento
- tensiones con el sistema antitrampa
- opciones del jugador
- pendientes

## Estandar de referencia
- WCAG 2.1 nivel AA como meta para V1
- WCAG 2.2 nivel AA como meta a futuro
- guias de accesibilidad de Material 3 para Android
- guias de accesibilidad de Apple para iOS cuando aplique

## Color y contraste

### Reglas
- todo texto contra su fondo cumple ratio de contraste 4.5 a 1 minimo
- texto grande cumple ratio 3 a 1 minimo
- elementos interactivos cumplen ratio 3 a 1 minimo contra su entorno
- el feedback de exito y error nunca depende solo del color

### Reforzadores no cromaticos
- exito: color verde mas icono de confirmacion mas mensaje
- error: color rojo mas borde grueso mas icono mas mensaje
- destacado: color azul mas borde mas icono
- alerta: color amarillo mas icono mas mensaje

## Daltonismo

### Tipos cubiertos
- protanopia
- deuteranopia
- tritanopia

### Estrategia
- la paleta funcional se valida contra simuladores de los 3 tipos
- se ofrece un modo daltonico alterno como opcion en configuracion
- el modo daltonico cambia los colores de feedback por una paleta de alto contraste con formas distintivas

### Modo daltonico
- exito: azul saturado mas icono de confirmacion
- error: naranja saturado mas borde dentado
- alerta: amarillo neutro mas icono de exclamacion
- destacado: morado saturado

### Reglas de juego asociadas
- las casillas con error siempre se diferencian con borde y patron, no solo color
- los avatares confirmados siempre llevan flecha, no solo verde
- las pistas destacadas siempre llevan icono, no solo color

## Texto y escala

### Tamanos minimos
- texto principal: equivalente a 14 puntos en pantallas medianas
- numeros del cronometro y puntos: legibles sin zoom
- texto de pistas: equivalente a 16 puntos

### Escala dinamica
- la app respeta el escalado de fuente del sistema operativo
- la UI se adapta sin romperse a 130 por ciento de escala
- la UI sigue siendo usable a 150 por ciento aunque algunos elementos pierdan elegancia
- a 200 por ciento o mas se garantiza el funcional, no el estetico

### Reglas
- ningun texto critico se trunca sin acceso al completo
- los tooltips son tocables, no solo visibles al pasar
- los nombres de los sospechosos no se cortan si caben en su panel

## Objetivos de toque y motricidad

### Tamanos
- area minima de toque: 48 por 48 puntos
- separacion minima entre elementos tocables adyacentes: 8 puntos
- la papelera es siempre suficientemente grande para arrastrar sin precision fina

### Arrastre
- el arrastre tolera variacion en la trayectoria
- al soltar cerca de una casilla valida, el sistema asume la intencion del jugador
- los gestos rapidos no descartan elementos por accidente

### Alternativa al arrastre
- toque para seleccionar mas toque para colocar es valido como alternativa al arrastre
- la opcion se activa desde configuracion y no penaliza al jugador
- esta opcion debe estar disponible en V1

### Tap repetido
- los ciclos de estado para sospechoso y X tienen feedback inmediato
- doble tap accidental no provoca acciones destructivas sin confirmacion

## Navegacion por lectores de pantalla

### Compatibilidad
- TalkBack en Android
- VoiceOver en iOS cuando aplique

### Cobertura V1
- pantallas de cuenta, login, registro, configuracion accesibles
- pantallas de inicio, mundos, ranking, tienda accesibles
- pantalla de partida con cobertura basica:
  - sospechosos del panel anunciados con nombre y estado
  - casillas anunciadas con su contenido actual
  - boton resolver, ayudas, papelera anunciados
  - mensaje de error y de exito anunciados

### Limites aceptables en V1
- la lectura completa del tablero como mapa visual queda como una experiencia limitada
- el jugador con lector de pantalla puede entender la informacion, pero no se garantiza la misma fluidez de juego que en visual

### Etiquetado
- todos los elementos interactivos tienen etiqueta accesible
- los iconos sin texto tienen descripcion accesible
- los avatares de sospechosos tienen nombre asociado

## Subtitulos y audio alternativo

### Reglas
- ningun audio comunica informacion critica sin reforzador visual
- la musica y los efectos pueden silenciarse desde configuracion
- las animaciones celebratorias no dependen del audio para entenderse

### Si en futuro hay narracion hablada
- subtitulos obligatorios sincronizados
- subtitulos toggle desde configuracion
- contraste y tamano cumpliendo el resto de reglas de texto

## Preferencias de movimiento

### Reduccion de movimiento
- opcion en configuracion: reducir animaciones
- al activarse:
  - desaparece la animacion de desbloqueo de mundo larga
  - las transiciones largas se reemplazan por fades cortos
  - el feedback de error pulsante se reemplaza por un parpadeo unico
- las animaciones esenciales para entender una accion se mantienen

### Vibracion y haptics
- toggle independiente desde configuracion
- nunca se asume que la vibracion comunica informacion critica
- la vibracion es siempre un refuerzo, nunca un canal exclusivo

## Tensiones con el sistema antitrampa

### Bloqueo de capturas
- aplica solo en partida oficial y reto diario
- no aplica en tutorial, practica ni como jugar
- documentar publicamente que las capturas estan bloqueadas en partida oficial
- si un usuario depende de capturas para accesibilidad, se le ofrece practica como alternativa
- los lectores de pantalla siguen funcionando aunque la captura este bloqueada

### Rotacion del mapa
- la rotacion puede ser dificil para personas con motricidad reducida o con dispositivos asistidos
- opcion en configuracion: desactivar rotacion del mapa
- al desactivarla:
  - la partida sigue siendo oficial y puntuable
  - los textos del mapa se mantienen orientados al jugador como ya hacen por defecto
  - se mantiene el resto de antitrampa
- la opcion se documenta como ayuda de accesibilidad, no como ventaja

### Tiempo siempre corriendo
- el tiempo no se pausa, pero el sistema reconoce automaticamente bloqueos del propio servidor y los descuenta
- nunca se descuenta tiempo manualmente por peticion

## Opciones del jugador en configuracion

### Opciones nuevas que entran a V1
- modo daltonico
- alternativa al arrastre por toque
- reducir animaciones
- desactivar rotacion del mapa
- vibracion y haptics
- escala de texto del sistema respetada por defecto

### Opciones que mantenemos
- sonido
- musica
- vibracion y haptics
- idioma
- notificaciones

## Validacion antes del lanzamiento

### Pruebas obligatorias
- contraste validado con herramientas automaticas
- daltonismo validado con simuladores en las 3 variantes
- TalkBack validado en pantallas principales
- escala de fuente probada al 130 y 150 por ciento
- tamano de toque medido con grilla en pantallas pequenas
- tiempo de respuesta del feedback validado para no superar 100 ms en interacciones criticas

### Pruebas con usuarios reales
- sesiones con jugadores con baja vision
- sesiones con jugadores con motricidad reducida
- sesiones con jugadores daltonicos
- sesiones con jugadores que usen TalkBack o VoiceOver
- documentar hallazgos y priorizar fixes antes de release

## Pendientes
- definir paleta exacta del modo daltonico en hex
- decidir si la lectura del tablero por TalkBack mejora a un modo dedicado en futuro
- explorar alternativa de juego por teclado o gamepad
- decidir si las pistas tienen lectura sintetica como ayuda futura

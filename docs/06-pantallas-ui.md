# Enigmatrix - Pantallas UI

## Objetivo de este documento
Este documento aterriza Enigmatrix en pantallas concretas de interfaz para que despues sea mas facil:

- diseñar wireframes
- crear mockups
- dividir trabajo de frontend
- definir navegacion real
- pasar a codigo sin ambiguedades

## Navegacion general

### Navegacion principal
- Menu inferior:
  - Inicio
  - Mundos
  - Reto diario
  - Ranking

### Navegacion secundaria
- Menu lateral o secundario:
  - Perfil
  - Tienda
  - Premium
  - Configuracion
  - Como jugar

### Elementos persistentes
- Barra superior visible en pantallas principales con:
  - vidas actuales
  - tiempo para la proxima vida
  - nickname
  - avatar
  - bandera/pais

## Lista de pantallas

### 01. Splash / carga inicial
Funcion:
- cargar estado base de la app
- revisar sesion
- revisar conexion
- revisar desbloqueos pendientes

Muestra:
- logo de Enigmatrix
- indicador de carga

Estados especiales:
- reconexion automatica
- flujo pendiente de anuncio para desbloqueo de mundo

### 02. Login y acceso
Funcion:
- permitir entrar con Google o email

Muestra:
- boton Google
- boton login email
- boton registro email
- links a terminos y politica

### 03. Registro con email
Funcion:
- crear cuenta con email y contrasena

Muestra:
- email
- contrasena
- aceptar terminos
- aceptar politica
- boton crear cuenta

### 04. Login con email
Funcion:
- iniciar sesion con email y contrasena

Muestra:
- email
- contrasena
- boton iniciar sesion
- recuperar contrasena

### 05. Configuracion inicial de perfil
Funcion:
- completar los datos obligatorios antes del tutorial

Version Google:
- avatar cargado desde Google por defecto
- nickname unico obligatorio
- bandera/pais obligatoria
- opcion de cambiar avatar

Version email:
- elegir avatar predeterminado
- nickname unico obligatorio
- bandera/pais obligatoria

### 06. Bienvenida 1
Funcion:
- explicar que es Enigmatrix

Muestra:
- mensaje corto del concepto central
- ilustracion o apoyo visual
- continuar

### 07. Bienvenida 2
Funcion:
- explicar reto diario

Muestra:
- mensaje corto
- ilustracion
- continuar

### 08. Bienvenida 3
Funcion:
- explicar rankings y racha

Muestra:
- mensaje corto
- ilustracion
- continuar

### 09. Tutorial guiado
Funcion:
- enseñar el juego con un caso facil

Muestra:
- mapa simplificado
- pistas
- panel de sospechosos
- notas
- boton resolver
- ayudas

Comportamientos:
- pasos obligatorios
- acciones bloqueadas hasta completar lo correcto
- prueba de ambos modos de notas
- demostracion de error al resolver
- demostracion de ayuda

### 10. Eleccion de modo preferido
Funcion:
- dejar configurado el modo de notas por defecto

Muestra:
- opcion notas separadas
- opcion superposicion
- boton confirmar

### 11. Resumen del tutorial
Funcion:
- cerrar el tutorial

Muestra:
- tiempo
- errores
- ayudas
- puntuacion visual
- continuar

Primera vez:
- anuncio si no es premium
- desbloqueo de Mundo 1

Rejugado:
- vuelve a Como jugar

### 12. Inicio
Funcion:
- pantalla central del usuario

Muestra tarjetas en prioridad:
1. Verifica tu correo
2. Reto diario
3. Continuar partida pendiente
4. Mundo actual

Adicional:
- accesos de navegacion
- barra superior persistente
- indicador de sin conexion si aplica

### 13. Modulo de verificacion de correo
Funcion:
- explicar bloqueo por correo no verificado

Muestra:
- mensaje de verificacion requerida
- correo actual
- reenviar correo
- cambiar correo

### 14. Mundos
Funcion:
- mostrar mundos desbloqueados

Muestra:
- lista o carrusel de mundos
- nombre del mundo
- miniatura del mundo
- solo mundos desbloqueados visibles

### 15. Detalle de mundo
Funcion:
- mostrar progreso del mundo actual

Muestra:
- nombre del mundo
- barra o texto de progreso
- mapas en orden fijo
- miniatura por mapa
- nombre del mapa
- estado del mapa

Estados visuales por mapa:
- no iniciado
- en progreso
- completado
- completado, practica bloqueada
- practica disponible
- mapa sin resolver

### 16. Pantalla previa del mapa
Funcion:
- presentar el caso antes de jugar

Muestra:
- nombre del mapa
- mundo
- dificultad
- tipo de intento
- etiqueta si el caso incluye arma homicida
- aviso de intento oficial
- boton comenzar

Casos especiales:
- mapa sin resolver
- practica disponible

### 17. Advertencia por partida pendiente
Funcion:
- gestionar conflicto cuando ya existe otra partida oficial pendiente

Muestra:
- mensaje explicando que perdera el progreso guardado
- boton volver a partida pendiente
- boton iniciar nueva y perder anterior

### 18. Pantalla intermedia de mapa pendiente
Funcion:
- decidir que hacer al volver a un mapa en progreso

Muestra:
- continuar intento oficial
- jugar en practica deshabilitado
- volver

### 19. Pantalla de partida principal
Funcion:
- resolver el caso

Estructura:
- mapa grafico
- pistas visibles
- panel fijo de sospechosos
- acceso a notas
- papelera siempre visible
- boton ayudas
- boton resolver
- boton limpiar tablero
- boton deshacer
- boton rehacer

Header de partida:
- tiempo
- ayudas usadas
- intentos fallidos de resolver
- puntos actuales estimados

### 20. Modo notas separadas
Funcion:
- mostrar la cuadricula logica separada

Muestra:
- cuadricula logica
- estado sincronizado con el mapa

### 21. Modo notas superpuestas
Funcion:
- mostrar la cuadricula logica sobre el mapa

Muestra:
- mapa atenuado
- logica superpuesta
- estado sincronizado con el mapa

### 22. Mini panel de casilla
Funcion:
- borrar elementos de una casilla con varios contenidos

Muestra:
- lista simple o rejilla pequena con elementos
- al tocar uno:
  - lo elimina
  - cierra el panel

### 23. Panel de ayudas
Funcion:
- listar ayudas disponibles

Muestra:
- ayudas activas
- ayudas deshabilitadas
- confirmacion simple antes de usar

No muestra:
- penalizacion numerica exacta

### 24. Panel de vidas
Funcion:
- explicar estado de vidas

Muestra:
- vidas activas
- tiempo para proxima vida
- vidas extra
- ver anuncio
- comprar pack de vidas
- boton reglas de vida

### 25. Panel reglas de vida
Funcion:
- explicar solo reglas de vidas

Muestra:
- como se pierden
- como se recuperan
- como funcionan extras

### 26. Error de resolver
Funcion:
- feedback cuando el tablero esta mal

Muestra:
- texto de error
- casillas incorrectas resaltadas
- bloqueo temporal de edicion
- feedback rojo de penalizacion

### 27. Exito de resolver
Funcion:
- feedback cuando el tablero esta correcto

Muestra:
- mensaje de completado exitoso
- tablero bloqueado
- boton continuar

### 28. Resumen de mapa oficial
Funcion:
- cerrar partida oficial de campana

Muestra:
- nombre del caso
- mundo
- tiempo
- errores de resolver
- ayudas usadas
- puntuacion
- posicion global
- promedio historico del mapa
- mejor marca anterior
- si aplica:
  - arma homicida revelada
- compartir
- continuar

### 29. Resumen de practica
Funcion:
- cerrar partida de practica

Muestra:
- tiempo
- errores
- ayudas
- puntuacion de practica
- puntaje oficial registrado
- compartir
- continuar

### 30. Resumen del mundo
Funcion:
- cerrar un mundo cuando termina su ultimo mapa

Muestra:
- mapas completados
- tiempo total del mundo
- puntuacion total del mundo
- ayudas totales
- errores totales
- continuar

Flujo posterior:
- anuncio si no es premium
- animacion de desbloqueo del siguiente mundo

### 31. Animacion de desbloqueo de mundo
Funcion:
- celebrar y confirmar nuevo acceso

Muestra:
- nombre del mundo desbloqueado
- efecto visual
- continuar

### 32. Modulo de reto diario
Funcion:
- centro de informacion del reto del dia

Muestra:
- estado del reto
- racha actual
- mejor racha historica
- puntos semanales acumulados
- protectores disponibles
- tiempo restante para el siguiente reto
- ranking del dia
- ranking semanal
- dificultad
- nombre del caso
- badge mientras no se complete

Estados:
- no iniciado
- en progreso
- completado
- invalido/fuera de tiempo

### 33. Advertencia de intento oficial del reto diario
Funcion:
- confirmar inicio del intento diario

Muestra:
- mensaje de que abrirlo registra el intento oficial del dia
- confirmar
- cancelar

### 34. Resumen del reto diario
Funcion:
- cerrar el reto diario jugado

Muestra:
- nombre del reto
- dificultad
- tiempo
- errores
- ayudas
- puntos
- posicion
- promedio del reto
- puntos ganados hoy
- acumulado semanal
- si aplica:
  - arma homicida revelada
- compartir
- continuar

### 35. Pantalla de racha y progreso diario
Funcion:
- mostrar el resultado diario ampliado

Muestra:
- racha actual
- mejor racha historica
- puntos ganados hoy
- acumulado semanal
- posicion en ranking diario
- protectores disponibles
- fechas de los ultimos 3 protectores usados
- acceso a ranking diario
- acceso a ranking semanal

Si aplica:
- racha protegida
- racha perdida
- motivo del fallo

### 36. Ranking principal
Funcion:
- elegir tipo de ranking

Pestanas:
- Mapas
- Reto diario
- Semanal

### 37. Ranking de mapas - selector
Funcion:
- elegir mundo y mapa

Muestra:
- selector de mundo
- selector de mapa

### 38. Vista de ranking
Funcion:
- mostrar ranking concreto

Muestra:
- podio visual top 3
- tabla puestos 4 al 10
- bloque del usuario con 3 anteriores y 3 siguientes

Comportamientos:
- si el usuario esta en top 10, no muestra bloque extra
- tocar avatar o nickname abre perfil publico
- tocar puntos abre detalle del resultado

### 39. Perfil publico
Funcion:
- mostrar perfil publico de otro jugador

Muestra:
- avatar
- nickname
- bandera/pais
- racha actual
- mejor racha historica
- retos iniciados
- retos completados
- retos fallados
- porcentaje de exito
- retos disponibles desde el registro
- mundos completados
- mapas completados

### 40. Detalle de resultado
Funcion:
- mostrar detalle de un resultado oficial concreto

Muestra:
- mapa o reto jugado
- tiempo
- puntos
- errores
- ayudas usadas
- fecha
- posicion obtenida

### 41. Perfil propio
Funcion:
- mostrar y editar datos del jugador

Muestra:
- avatar
- nickname
- bandera/pais
- estadisticas

Acciones:
- cambiar avatar
- cambiar nickname
- cambiar bandera/pais

### 42. Cambio de nickname
Funcion:
- editar nickname con validacion

Muestra:
- nickname actual
- campo nuevo
- validacion de disponibilidad
- sugerencias si ya existe

Restriccion:
- solo cada 15 dias

### 43. Tienda
Funcion:
- monetizacion basica

Muestra:
- premium
- packs de vidas
- protectores de racha

No muestra aun:
- eventos
- cosmeticos futuros

### 44. Premium
Funcion:
- vender planes premium

Muestra:
- comparacion gratis vs premium mensual vs premium anual
- beneficios
- ahorro visible en anual

### 45. Configuracion
Funcion:
- administrar preferencias del jugador

Muestra:
- sonido
- musica
- vibracion/haptics
- idioma
- notificaciones
- restaurar compras
- cerrar sesion
- eliminar cuenta
- soporte

### 46. Como jugar
Funcion:
- explicar el juego sin necesidad de jugar una partida real

Muestra:
- indice arriba
- pagina unica con scroll

Secciones:
- Que es Enigmatrix
- Reglas basicas
- Pistas
- Notas
- Simbolos del tablero
- Tutorial

Contenido:
- texto
- apoyos visuales
- mockups simplificados
- boton para jugar el tutorial

### 47. Soporte
Funcion:
- dar ayuda basica y acceso legal

Muestra:
- correo o contacto de soporte
- FAQ
- politica de privacidad
- terminos

### 48. Confirmacion de cerrar sesion
Funcion:
- advertir perdida de partida pendiente

Muestra:
- mensaje fuerte si existe partida oficial pendiente
- confirmar cerrar sesion
- cancelar

### 49. Confirmacion de eliminar cuenta
Funcion:
- advertir perdida total de datos

Muestra:
- progreso que se perdera
- rankings
- racha
- compras
- perfil
- confirmacion fuerte

### 50. Pantalla sin conexion
Funcion:
- informar bloqueo cuando falta internet

Casos:
- ranking offline
- tienda offline
- partida oficial bloqueada por falta de conexion

Muestra:
- mensaje de sin conexion
- reintento automatico o estado de espera

## Pantallas derivadas o futuras
Estas no entran todavia como modulos completos visibles, pero pueden existir despues:

- Eventos
- Historial de partidas
- Logros
- Amigos
- Rankings por pais
- Temporadas

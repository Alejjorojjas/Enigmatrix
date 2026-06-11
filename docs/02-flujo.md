# Enigmatrix - Flujo de la app

## Flujo general
El recorrido principal del usuario en Enigmatrix es:

1. Registro o login
2. Configuracion inicial de cuenta
3. Pantallas de bienvenida
4. Tutorial obligatorio
5. Acceso a Inicio
6. Campana o reto diario
7. Resumen de partida
8. Ranking, progreso, racha o siguiente desbloqueo

## Flujo de acceso

### Registro y login
- Google
- Email y contrasena

### Flujo con Google
1. Login con Google
2. Se carga avatar de Google por defecto
3. Se pide nickname unico
4. Se pide bandera/pais
5. Puede cambiar avatar si quiere
6. Pasa a bienvenida

### Flujo con email
1. Registro con email y contrasena
2. Aceptacion de terminos y politica
3. Se pide nickname unico
4. Se pide avatar predeterminado
5. Se pide bandera/pais
6. Pasa a bienvenida

### Restricciones de email no verificado
- Puede jugar tutorial, campana y practica
- No puede entrar a reto diario
- No puede ver rankings
- Ve avisos para verificar correo

## Flujo inicial

### Bienvenida
Antes del tutorial se muestran 2 o 3 pantallas que explican:

- que es Enigmatrix
- que existe el reto diario
- que existen rankings y racha

No se pueden saltar por completo la primera vez.

### Tutorial obligatorio
1. Caso guiado muy facil
2. Explica reglas base
3. Explica los dos modos de notas
4. Obliga a probar ambos modos
5. Muestra error de resolver
6. Muestra uso de ayuda
7. Muestra resumen
8. Permite escoger modo preferido por defecto
9. Al completar:
   - resumen
   - continuar
   - anuncio si no es premium
   - desbloqueo de Mundo 1
   - entrada a Inicio

## Inicio

### Prioridad de tarjetas
De arriba hacia abajo:

1. Verifica tu correo
2. Reto diario
3. Continuar partida pendiente
4. Mundo actual

El jugador puede ver varias tarjetas al mismo tiempo.

### Inicio muestra
- tarjeta de verificacion si aplica
- tarjeta de reto diario
- tarjeta de partida pendiente si existe
- tarjeta del mundo actual
- acceso a menus principales

## Navegacion principal

### Menu inferior
- Inicio
- Mundos
- Reto diario
- Ranking

### Menu secundario
- Perfil
- Tienda
- Premium
- Configuracion
- Como jugar

### Menu superior persistente
- vidas actuales
- tiempo para la proxima vida
- nickname
- avatar
- bandera/pais

## Flujo de mundos

### Detalle de mundo
Muestra:

- nombre del mundo
- indicador de progreso
- lista de mapas en orden fijo
- miniatura por mapa
- nombre de mapa
- estado del mapa

### Estados posibles del mapa
- No iniciado
- En progreso
- Completado
- Completado, practica bloqueada
- Practica disponible
- Mapa sin resolver

### Entrada a un mapa no iniciado
1. Pantalla previa del mapa
2. Muestra:
   - nombre
   - mundo
   - dificultad
   - tipo de intento
   - etiqueta si el caso incluye arma homicida
   - aviso de intento oficial
3. Boton comenzar

### Mapa oficial
1. Se abre el tablero
2. Se fija la orientacion aleatoria del mapa para ese jugador
3. El tiempo empieza a correr
4. El jugador resuelve
5. Si abandona:
   - el intento oficial queda iniciado
   - puede volver a continuarlo
6. Si sale del mapa:
   - se le muestra aviso de que su intento oficial ya fue registrado
7. Si vuelve a un mapa pendiente:
   - aparece pantalla intermedia:
     - Continuar intento oficial
     - Jugar en practica (deshabilitado mientras exista intento oficial pendiente)
     - Volver
   - Practica queda bloqueada si el intento oficial no ha terminado

### Si ya hay una partida oficial pendiente
Si intenta abrir otro mapa oficial o reto diario:

1. aparece advertencia
2. puede escoger:
   - continuar partida pendiente
   - iniciar la nueva
3. si inicia la nueva:
   - pierde el progreso de la anterior
   - la anterior queda sin validez oficial

### Mapa sin resolver
Sucede cuando se pierde el intento oficial por:

- borrar cache
- cerrar sesion con partida pendiente
- perder datos locales
- abandonar la pendiente para abrir otra

Ese mapa:

- ya no cuenta para ranking ni estadisticas oficiales
- pero debe completarse para avanzar

## Flujo dentro de partida

### Vista principal
Durante una partida se muestran:

- mapa
- pistas visibles
- panel fijo de sospechosos
- acceso a notas
- tiempo
- ayudas usadas
- intentos fallidos de resolver
- puntos actuales estimados
- papelera siempre visible
- boton de ayudas
- boton resolver
- boton limpiar tablero
- deshacer
- rehacer

### Interaccion con sospechosos
- tap 1 en avatar: candidato `avatar pequeno + ?`
- tap 2: confirmado `avatar grande + flecha verde`
- se arrastra al tablero

### Interaccion con X
- tap 1: X pequena
- tap 2: X grande
- se arrastra al tablero

### Reglas de colocacion
- si el mismo elemento ya existe, no hace nada
- si es la misma entidad con otro estado, reemplaza
- si es entidad distinta, coexiste
- si se pone confirmado en una casilla:
  - borra automaticamente todo lo demas de esa casilla
- si una casilla ya tiene confirmado:
  - no permite poner candidatos ni X
  - muestra mensaje
- si se pone otro confirmado encima:
  - pide confirmacion
  - reemplaza al anterior

### Borrado
- mini panel al tocar casillas con varios elementos
- mini panel sirve solo para borrar
- papelera siempre visible para cualquier elemento arrastrable

### Limpiar tablero
- pide confirmacion
- borra estado manual del tablero
- borra marcas de pistas
- borra historial visual de tablero
- mantiene tiempo
- mantiene errores
- mantiene ayudas ya contadas
- mantiene penalizacion ya aplicada

### Resolver
Si el tablero esta mal:

- valida de una vez, sin confirmacion
- mensaje de error
- resalta casillas incorrectas
- bloquea edicion por unos segundos
- pierde puntos
- pierde vida si aplica
- luego permite seguir

Si el tablero esta bien:

- mensaje de completado en la misma pantalla
- bloquea tablero
- habilita boton `Continuar`

## Flujo de salida de partida correcta

### Mapa normal
1. Resolver correcto
2. Boton `Continuar`
3. Anuncio si no es premium
4. Resumen del mapa
5. Continuar
6. Si es ultimo mapa del mundo:
   - resumen del mundo
   - continuar
   - anuncio si no premium
   - animacion de desbloqueo
   - siguiente mundo desbloqueado

### Entrada a reto diario
1. Estado previo en el modulo de reto diario
2. Si el estado es `No iniciado`:
   - se muestra advertencia de intento oficial
   - al confirmar, se registra el intento oficial del dia
3. Se abre el tablero
4. Se juega normalmente

### Salida de reto diario correcto
1. Resolver correcto
2. Boton `Continuar`
3. Anuncio si no es premium
4. Resumen del reto diario
5. Pantalla de racha y progreso diario

### Tutorial
1. Resolver correcto
2. Resumen del tutorial
3. Continuar
4. Anuncio si no es premium
5. Desbloqueo de Mundo 1 la primera vez
6. Entrada a Inicio

## Resumenes

### Resumen normal
Muestra:

- estado de la partida
- nombre del caso
- mundo
- tiempo final
- intentos fallidos de resolver
- ayudas usadas
- puntuacion
- posicion global del mapa
- promedio historico global del mapa
- mejor marca anterior
- si el caso tenia arma:
  - arma homicida revelada
- opcion de compartir

### Resumen de practica
Muestra:

- datos de esa partida de practica
- puntaje oficial ya registrado
- comparte resultado de practica no oficial solo como visual, pero sin tocar ranking

### Resumen diario
Muestra:

- nombre del reto
- dificultad
- tiempo
- intentos fallidos
- ayudas
- puntos
- posicion del reto diario
- promedio del reto
- puntos ganados hoy
- acumulado semanal
- si el caso tenia arma:
  - arma homicida revelada
- opcion de compartir

### Pantalla de racha y progreso diario
Muestra:

- racha actual
- mejor racha historica
- puntos ganados hoy
- acumulado semanal
- posicion en ranking del reto diario
- protectores disponibles
- fecha de los ultimos 3 protectores usados
- acceso a ranking diario
- acceso a ranking semanal
- si aplica:
  - racha protegida
  - racha perdida
  - motivo del fallo

### Resumen del mundo
Muestra:

- mapas completados
- tiempo total del mundo
- puntuacion total del mundo
- ayudas totales
- errores totales

No muestra competencia global del mundo.

## Reto diario

### Modulo de reto diario
Antes de empezar o continuar muestra:

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

### Estados del reto diario
- No iniciado
- En progreso
- Completado
- Invalido/fuera de tiempo

### Badge de reto diario
- se muestra mientras el reto del dia siga pendiente y jugable
- si el reto se abre pero no termina, sigue visible
- desaparece al completarlo
- desaparece si el reto ya no puede abrirse el resto del dia

## Ranking

### Estructura
- pestana Mapas
- pestana Reto diario
- pestana Semanal

### Ranking de mapas
1. elegir mundo
2. elegir mapa
3. ver ranking especifico

### Ranking diario
- abre primero el ranking del dia
- permite revisar dias anteriores

### Ranking semanal
- abre primero la semana actual
- permite revisar semanas anteriores

### Layout de ranking
- podio visual con top 3
- tabla del 4 al 10
- bloque del usuario con 3 anteriores y 3 siguientes
- si el usuario esta en top 10, se oculta el bloque extra

### Acciones dentro del ranking
- tap en avatar o nickname: perfil publico
- tap en puntos: detalle del resultado

## Perfil

### Perfil publico
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

### Perfil propio
Puede editar:

- avatar
- nickname
- bandera/pais

## Tienda
- premium
- packs de vidas
- protectores de racha

## Premium
- comparacion entre Gratis, Premium mensual y Premium anual
- anual muestra ahorro visible

## Configuracion
- sonido
- musica
- vibracion/haptics
- idioma
- notificaciones
- restaurar compras
- cerrar sesion
- eliminar cuenta
- soporte

## Como jugar
- pagina unica
- indice arriba
- secciones:
  - Que es Enigmatrix
  - Reglas basicas
  - Pistas
  - Notas
  - Simbolos del tablero
  - Tutorial
- usa texto + apoyos visuales
- mockups simplificados
- el tutorial se puede rejugar desde aqui

Nota:
- los casos con arma homicida no se explican a fondo al inicio
- el tutorial solo los menciona brevemente
- el jugador aprende ese sistema al llegar a esos casos

## Conectividad
- Toda la app es online
- Si se pierde internet durante una partida oficial:
  - puede seguir un tiempo limitado
  - si supera ese tiempo:
    - partida bloqueada
    - no puede ver tablero ni pistas
    - debe recuperar conexion
- Al volver la conexion:
  - reintento automatico

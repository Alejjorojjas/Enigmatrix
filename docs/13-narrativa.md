# Enigmatrix - Narrativa

## Objetivo de este documento
Definir el tono narrativo, los personajes y el rol de la historia en Enigmatrix V1.

Cubre:

- rol de la narrativa en el juego
- tono general
- estructura de los casos
- voz de las pistas
- el jugador y el rol del detective
- arquetipos de sospechosos
- victimas y armas
- resumen y revelacion
- moderacion de contenido
- coherencia con los pillars
- futuro narrativo
- pendientes

## Rol de la narrativa en V1
- la narrativa existe para dar contexto y atmosfera, no para conducir la jugabilidad
- los casos son episodicos: cada mapa es un caso autocontenido
- no hay metahistoria principal en V1
- la deduccion siempre es lo principal, la historia es decoracion estructurada

## Tono general

### Caracter
- cozy mystery: misterio amable, no horror
- elegante, contemporaneo, con humor seco ocasional
- no graphic, no gore
- no cinico, no nihilista
- accesible para audiencia amplia mayor de 12 anos
- **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 16, H-09): edad mínima. Este documento dice "mayor de 12 años"; `docs/15-legal.md` dice a la vez "mayores de 12" y "no dirigido a menores de 13". Ver ese documento.

### Inspiraciones
- novela detectivesca clasica modernizada
- comedias de misterio reciente tipo Knives Out
- series tipo Only Murders in the Building
- relato corto al estilo Chesterton para los casos individuales

### Lo que no es Enigmatrix narrativamente
- no es thriller psicologico oscuro
- no es horror sobrenatural
- no es procedural policial duro
- no es comedia bufa

## Estructura de los casos

### Caso individual
Cada caso tiene:

- titulo corto
- una linea de premisa
- conjunto de sospechosos con perfiles minimos
- una victima
- escenario dentro de un mundo
- pistas
- resolucion

### Reglas de coherencia
- el titulo y la premisa nunca dan informacion no presente en las pistas
- los perfiles de sospechosos no influyen logicamente en la solucion
- los perfiles existen para sabor y para que el jugador recuerde quien es quien
- una vez resuelto, el resumen revela tambien la motivacion en una frase

### Distribucion narrativa por mundo
- cada mundo tiene un tono particular dentro del cozy mystery
- Mansion: misterio aristocratico clasico
- Hotel: misterio cosmopolita
- Museo: misterio cultural con referencias artisticas suaves
- Tren: misterio de viaje, encierro elegante
- Hospital: misterio clinico, no medico tecnico

## Voz de las pistas

### Reglas
- siempre tercera persona neutra
- frases cortas, declarativas
- sin adornos literarios largos
- sin ambiguedad que no sea logica
- las pistas son verificables contra el tablero

### Patrones aceptados
- afirmacion directa de ubicacion
- negacion directa de ubicacion
- relacion entre personajes
- relacion entre persona y arma
- referencia a la habitacion del arma

### Patrones evitados
- pistas que requieren cultura especifica para entender
- pistas que dependen de juegos de palabras del idioma
- pistas con referencias temporales largas
- pistas que asumen conocimiento del mundo real fuera del juego

## El jugador y el rol del detective

### En V1
- el jugador es un detective sin nombre, sin rostro, sin voz
- no hay narrador omnipresente
- no hay dialogos del jugador con otros personajes
- la app habla en segunda persona neutra cuando es necesario instructiva

### En futuro
- posibilidad de un detective con identidad propia
- posibilidad de personalizacion del detective vinculada al perfil del jugador
- posibilidad de un narrador que aparezca en momentos celebratorios
- todo esto queda fuera de V1

## Arquetipos de sospechosos

### Reglas
- cada mundo tiene un set propio de arquetipos coherentes con su ambiente
- los arquetipos son base, los nombres y matices cambian entre casos
- ningun arquetipo carga una culpa intrinseca
- el asesino se determina por la logica, no por el arquetipo

### Mansion
- el heredero
- la institutriz
- el mayordomo
- la artista invitada
- el medico de familia
- el vecino curioso
- el primo lejano

### Hotel
- el huesped misterioso
- la concierge
- el botones
- la cantante del bar
- el empresario
- la critica de viajes
- el huesped habitual

### Museo
- la conservadora
- el donante
- el guia
- el restaurador
- el visitante experto
- el periodista
- el guardia

### Tren
- el revisor
- la pasajera de primera
- el pasajero misterioso
- el cocinero del vagon restaurante
- el escritor de viaje
- la familia en vacaciones
- el guardia ferroviario

### Hospital
- la doctora jefa
- el residente
- la enfermera senior
- el paciente recurrente
- la administradora
- el visitante frecuente
- el tecnico de mantenimiento

## Victimas y armas

### Reglas para victimas
- las victimas son adultos
- nunca son ninos
- nunca son grupos
- la causa de muerte se enuncia neutra: hallada sin vida, fallecida en circunstancias sospechosas
- ninguna descripcion grafica
- el jugador no ve representacion grafica de la victima en el mapa

> ACTUALIZACIÓN 04-11-2026: **PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta 8, H-35): cómo se representa a la víctima.
> - **Versión de este documento:** la víctima no se ve en el mapa (línea de arriba). Lo mismo dicen `docs/15-legal.md` y `docs/20-checklist-tiendas.md`, y el segundo la usa para responder el cuestionario de clasificación de edad.
> - **Lo que hace hoy el juego** (comprobado en `app/lib/src/ui/board_view.dart` y `app/lib/src/ui/game_screen.dart`): el jugador ubica a la víctima en el tablero como a cualquier otro personaje, porque así lo exigen la regla de oro del juego y la especificación (`docs/16-spec-puzzle.md`, sección 2.1). Su ficha es un círculo de color con una † en lugar de la inicial, y su tarjeta en el panel lleva la cinta roja "LA VÍCTIMA". No se muestra cuerpo, sangre ni escena del crimen.
> - Las dos descripciones no coinciden y no se resuelven aquí. La redacción final (por ejemplo, "la víctima es un personaje con ficha normal marcada con †; nunca se muestra cuerpo, sangre ni escena del crimen") la decide Alejandro, y debe quedar igual en los documentos 13, 15 y 20 y en el cuestionario de la tienda.

### Reglas para armas
- las armas son objetos cotidianos del mundo
- nunca armas de fuego
- nunca armas militares
- nunca dispositivos explosivos
- las armas se nombran y muestran como objetos, sin enfasis morboso
- el resumen revela el arma de manera sobria

### Lista oficial de armas
Ya definida en `03-reglas-del-juego.md` y replicada en `01-mvp-v1.md`. Esta narrativa la respeta sin agregar variantes graficas.

## Resumen y revelacion

### Estructura del resumen narrativo
Tras resolver bien un caso, el resumen muestra:

- nombre del caso
- una frase de cierre que enuncia quien fue
- una frase de motivacion en tono novela ligera
- arma homicida revelada si aplica
- tono no triunfal sobre la victima, mas bien sobrio

### Reglas del cierre
- nunca se ridiculiza a la victima
- nunca se celebra la violencia
- el tono celebra al jugador por la deduccion, no la muerte ficticia
- la frase de motivacion no inventa hechos no implicados por las pistas
- la motivacion es generica si no hay pistas para inferir una especifica

## Moderacion de contenido

### Politicas
- no se incluyen referencias a personas reales
- no se incluyen referencias a marcas reales
- no se incluyen escenarios sensibles reales
- ningun caso es politico, religioso, etnico ni geopolitico
- ningun caso utiliza identidades reales ofensivas

### Sensibilidad de identidad
- los sospechosos no se definen por etnia, religion ni orientacion como rasgo deductivo
- la diversidad visual es real, pero nunca informa la solucion
- las pistas nunca discriminan por categorias sensibles

### Lenguaje
- sin lenguaje vulgar
- sin slurs
- sin slang ofensivo
- en localizacion, mantener equivalentes aceptables culturalmente

## Coherencia con los pillars

### Pillar 1 deduccion pura
- la narrativa nunca aporta informacion necesaria que no este en las pistas
- los arquetipos no determinan la solucion
- la motivacion del resumen no genera nuevas reglas para futuros casos

### Pillar 2 ranking limpio
- la narrativa no entrega puntos
- los casos con narrativa mas elaborada no valen mas

### Pillar 3 cabe en un trayecto
- la premisa de cada caso se entiende en una frase
- la lectura no obliga a parar la deduccion
- el resumen es corto, no es un capitulo

### Pillar 4 justos con el jugador
- la narrativa no oculta informacion logica detras de un texto largo
- ninguna pista se vuelve trampa por adornos literarios

### Pillar 5 el mapa cuenta la historia
- la narrativa subordina al mapa, no lo reemplaza
- los textos son cortos, la imagen pesa mas

## Futuro narrativo
- detective con identidad propia
- mini arcos opcionales que conectan casos de un mundo
- personajes recurrentes a lo largo de mundos
- temporadas con casos vinculados
- eventos narrativos atados a fechas
- variaciones musicales por mundo en linea con la narrativa
- todo lo anterior queda fuera de V1

## Pendientes
- definir el set inicial de nombres por mundo
- definir el catalogo de motivaciones genericas
- definir el estilo concreto de la frase de cierre
- decidir si el detective gana identidad propia post V1
- definir politica de revision narrativa de casos antes de publicar

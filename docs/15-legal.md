# Enigmatrix - Legal y compliance

## Objetivo de este documento
Definir los requisitos legales y de cumplimiento que Enigmatrix debe cubrir para lanzar V1.

Este documento es una guia tecnica y de producto. No reemplaza asesoria legal real. Antes de publicar es obligatorio revisar todo con un abogado en la jurisdiccion correspondiente.

Cubre:

- audiencia objetivo y edad
- COPPA y politica con menores
- GDPR, UK GDPR y LGPD
- CCPA y politicas estado USA
- politica de privacidad
- terminos y condiciones
- consentimiento de cookies y analitica
- compras dentro de la app
- anuncios y consentimiento publicitario
- publicacion en tiendas
- permisos del sistema
- propiedad intelectual y musica
- moderacion de contenido del usuario
- soporte y contacto
- proceso de eliminacion de cuenta
- seguridad y reporte de incidentes
- pendientes a confirmar con abogado

## Audiencia objetivo y edad

### Audiencia oficial
- Enigmatrix es para mayores de 12 anos
- la categoria PEGI sugerida es 12
- la categoria ESRB sugerida es Teen
- la categoria Google Play sugerida es Teen
- la categoria App Store sugerida es 12 o superior

### Justificacion
- el juego es de misterio detectivesco con violencia ficticia implicita
- no hay sangre, no hay representacion grafica de victimas
- no hay lenguaje vulgar, no hay contenido sexual
- las armas son objetos cotidianos, no armas reales

### Etiquetas de dificultad
- la etiqueta mas accesible se llama `Principiante`
- nunca se usa la palabra `Infantil` ni equivalentes que sugieran audiencia menor de 12 anos
- esta clarificacion figura en la pagina del store y en la documentacion publica

## COPPA y politica con menores

### Regla principal
- Enigmatrix no esta dirigido a menores de 13 anos
- esto debe declararse en la consola del store y en la politica de privacidad

### Salvaguardas
- bloqueo de registro a usuarios que declaren ser menores de 13 anos durante el flujo
- ningun campo del registro pide informacion de menores
- ninguna funcion del juego promueve recoleccion de datos de menores
- la pantalla de bienvenida menciona la edad minima de uso

### Si se decide incluir audiencia mixta en futuro
- requerira flujo separado con consentimiento parental
- requerira modo restringido sin chat, sin compartir y sin ranking
- esta decision queda fuera de V1

## Mercados objetivo de lanzamiento V1

### Lista oficial
- Colombia como mercado de origen
- resto de paises de Latinoamerica
- Estados Unidos
- Union Europea
- en general, todos los paises disponibles en Google Play y App Store
- excepciones unicamente cuando una regulacion local lo impida o exija un proceso especial costoso

### Implicaciones legales por mercado
- Colombia: Ley 1581 de 2012 de Proteccion de Datos Personales y Decreto 1377 de 2013
- Mexico, Argentina, Chile, Peru y resto de Latinoamerica: leyes locales de proteccion de datos, equivalentes con matices
- Brasil: LGPD si se incluye en la lista de paises Latinoamerica
- Estados Unidos: CCPA para residentes de California, otras leyes estatales en aumento
- Union Europea: GDPR
- Reino Unido: UK GDPR cuando aplique

### Estrategia
- la app cumple por defecto con las normas mas estrictas a nivel global
- los textos legales se redactan tomando GDPR como base
- se ajustan menciones especificas para Colombia y California
- se traducen las politicas a espanol e ingles desde el inicio

## GDPR, UK GDPR y LGPD

### Aplicacion
- aplica a usuarios en la Union Europea, Reino Unido, Brasil y otras jurisdicciones equivalentes
- la app respeta estos requisitos por defecto a nivel global

### Derechos cubiertos
- acceso a datos personales
- rectificacion
- eliminacion
- portabilidad
- limitacion de tratamiento
- oposicion al tratamiento

### Implementacion
- formulario o flujo en la app para solicitar cualquiera de estos derechos
- contacto de soporte siempre visible
- plazo de respuesta a solicitudes: 30 dias maximo
- politica de retencion clara para cada tipo de dato

### Bases legales del tratamiento
- ejecucion del contrato: cuenta, partidas, ranking
- consentimiento: analitica no esencial, comunicaciones de marketing si existen
- interes legitimo: antitrampa, seguridad

## Ley 1581 de 2012 Colombia

### Aplicacion
- aplica a usuarios en territorio colombiano y al tratamiento de datos por parte de cualquier responsable establecido en Colombia
- la app respeta estos requisitos como base local

### Derechos cubiertos
- conocer, actualizar y rectificar datos personales
- solicitar prueba de la autorizacion otorgada
- ser informado del uso dado a sus datos
- presentar quejas ante la Superintendencia de Industria y Comercio
- revocar la autorizacion y solicitar supresion del dato

### Implementacion
- politica de tratamiento de datos accesible desde la app
- correo de contacto del responsable del tratamiento publicado
- registro interno de la autorizacion del titular al crear cuenta
- proceso de eliminacion de cuenta cubre tambien la supresion bajo Ley 1581

### Pendiente clave para Colombia
- registro de bases de datos ante la Superintendencia de Industria y Comercio si la operacion lo requiere segun umbrales legales vigentes
- decision pendiente segun forma juridica del responsable

## CCPA y politicas estado USA

### Aplicacion
- aplica a residentes de California
- requisitos similares aplican en otros estados con leyes propias en aumento

### Derechos cubiertos
- saber que datos se recolectan
- pedir eliminacion
- optar fuera de la venta de datos
- no ser discriminado por ejercer estos derechos

### Implementacion
- enlace `Do Not Sell or Share My Personal Information` en politica
- proceso de eliminacion identico al GDPR
- claridad sobre que ningun dato personal se vende a terceros

## Responsable del tratamiento de datos

### Que es
- el responsable del tratamiento es la persona o entidad que decide que datos se recogen, para que y como
- en el caso de Enigmatrix es quien publica oficialmente la app en los stores
- esta figura es exigida tanto por GDPR como por la Ley 1581 de 2012 de Colombia
- debe figurar con nombre, contacto y direccion en la politica de privacidad

### Opciones para V1
- persona natural: el creador firma la app a su nombre, con su correo y direccion
- sociedad: una SAS o equivalente firma la app, con su NIT, correo y direccion
- recomendacion: arrancar con persona natural si la operacion es pequena, migrar a sociedad cuando crezca

### Implicaciones de cada opcion
- persona natural: mas simple y rapido para lanzar, responsabilidad personal sobre obligaciones legales y fiscales
- sociedad SAS en Colombia: mejor proteccion patrimonial, mas tramites, costo de constitucion y mantenimiento

### Contacto requerido en politica
- correo dedicado para temas de privacidad, tipo `privacidad@dominio.com`
- direccion fisica de contacto
- pais de residencia o constitucion
- responsable de proteccion de datos cuando aplique segun GDPR

### Decisiones tomadas para V1
- figura juridica: persona natural, el creador firma la app a su nombre
- nombre comercial publico en los stores: `Enigmatrix`
- mercados V1: todos los paises disponibles en Google Play y App Store, salvo restricciones tecnicas o legales

### Aun por definir
- correo dedicado para temas de privacidad: pendiente, recomendado registrar dominio propio
- direccion fisica de contacto publico

## Politica de privacidad

### Contenido obligatorio
- identidad y contacto del responsable del tratamiento
- datos personales recogidos y para que
- bases legales del tratamiento
- terceros que reciben datos: Firebase, proveedor de anuncios, tiendas
- transferencias internacionales y salvaguardas
- plazos de retencion
- derechos del usuario y como ejercerlos
- politica con menores
- proceso de eliminacion de cuenta
- politica de cookies y tecnologias similares
- contacto del responsable de proteccion de datos cuando aplique
- fecha de ultima actualizacion

### Reglas de presentacion
- accesible desde el primer arranque sin tener que registrarse
- accesible desde configuracion en cualquier momento
- accesible desde el flujo de registro
- escrita en lenguaje claro, no solo legal
- traducida a cada idioma soportado por el juego

## Terminos y condiciones

### Contenido obligatorio
- aceptacion del usuario al registrarse
- descripcion del servicio
- requisitos de cuenta y verificacion
- reglas de comportamiento del usuario
- politica de nicknames y avatares
- consecuencias por trampas o uso indebido
- politica de compras y reembolsos
- limitacion de responsabilidad
- ley aplicable y jurisdiccion
- cambios en los terminos y como se notifican
- eliminacion de cuenta por parte del usuario y por parte de la empresa

### Reglas
- aceptacion explicita en registro con email
- en login con Google se asume aceptacion al continuar pero se hace visible el enlace
- archivos accesibles desde configuracion permanentemente

## Consentimiento de cookies y analitica

### Aplicacion
- en la app movil no hay cookies, pero hay tecnologias equivalentes: identificadores, analitica, atribucion publicitaria
- el consentimiento se solicita al primer arranque

### Reglas
- el banner es claro y accionable
- separa analitica esencial de no esencial
- separa publicidad personalizada de no personalizada
- el rechazo es tan facil como la aceptacion
- el consentimiento se puede cambiar luego desde configuracion
- nunca se asume consentimiento por defecto

### Implementacion
- usar un Consent Management Platform compatible con Google y Apple
- registrar el consentimiento con timestamp
- respetar la senal de transparencia de Apple en iOS

## Compras dentro de la app

### Reglas
- todas las compras se realizan a traves de Google Play o App Store
- los precios se muestran en moneda local del store
- la politica de reembolsos sigue las reglas de la tienda correspondiente
- la app no puede ofrecer reembolsos directos

### Comunicacion al usuario
- pantalla de tienda muestra precio, descripcion y beneficios claramente
- premium muestra ciclo de facturacion y politica de cancelacion
- el usuario puede gestionar la suscripcion desde la tienda

### Politica de soporte
- soporte puede aplicar compensaciones en producto del juego: vidas, protectores
- soporte no procesa reembolsos de dinero, redirige al store

## Anuncios y consentimiento publicitario

### Reglas
- el proveedor de anuncios cumple con las regulaciones de privacidad aplicables
- los anuncios respetan el consentimiento del usuario
- los anuncios no son personalizados si el usuario no consintio
- los anuncios para menores estan deshabilitados ya que la app es para mayores de 12

### Tipos de anuncios prohibidos
- anuncios enganosos
- anuncios que parezcan parte del juego
- anuncios de juegos de azar reales
- anuncios de productos prohibidos en la jurisdiccion

### Reglas internas
- el premium elimina los anuncios
- los anuncios recompensados son siempre opt in
- el intersticial no aparece durante una partida activa

## Publicacion en tiendas

### Google Play
- declarar correctamente la edad recomendada
- declarar el uso de anuncios
- declarar el uso de IAP
- declarar las practicas de datos en la seccion de seguridad de datos
- enlace a politica de privacidad obligatorio

### App Store cuando aplique
- declarar correctamente la edad
- completar los nutrition labels de privacidad
- declarar el uso de tracking si aplica
- enlace a politica de privacidad obligatorio
- soporte de cuenta y eliminacion accesible desde la app

### Otros stores
- mismas reglas de claridad si aplica

## Permisos del sistema

### Permisos solicitados
- internet: requerido para todo el juego
- notificaciones: opcional, opt in
- almacenamiento solo para datos propios de la app
- en Android, FLAG_SECURE para bloqueo de capturas en partida oficial

### Permisos no solicitados
- ubicacion
- camara
- microfono
- contactos
- almacenamiento ampliado
- bluetooth
- cualquier permiso que no se justifique con un uso visible al usuario

### Reglas
- todos los permisos solicitados se justifican en pantalla
- el rechazo de un permiso opcional no bloquea el juego

## Propiedad intelectual y musica

### Activos propios
- todo el arte original es propiedad de la empresa
- los avatares y mapas se generan internamente o se contratan con cesion completa
- el codigo fuente es propiedad de la empresa

### Activos licenciados
- toda libreria de codigo de terceros respeta su licencia
- toda fuente tipografica licenciada se documenta con prueba de licencia
- toda musica y SFX licenciados se documentan con prueba de licencia
- ninguna referencia a personajes reales sin autorizacion
- ninguna referencia a marcas reales sin autorizacion

### Banco de evidencias
- carpeta interna con licencias de cada asset
- contrato de cesion para artistas externos
- documentacion de origen para libreria de musica y SFX

## Moderacion de contenido del usuario

### Aplicacion en V1
- el unico contenido generado por el usuario en V1 es el nickname
- el avatar es una seleccion entre opciones predefinidas, no es contenido libre

### Reglas de nickname en V1
- lista de palabras prohibidas en los idiomas soportados
- bloqueo de combinaciones obvias de slurs
- bloqueo de impersonificacion oficial: nombres tipo `admin`, `support`, `enigmatrix`
- bloqueo de cadenas con caracteres confusos masivos
- la lista se versiona y se mejora con el tiempo

### Reportes
- en V1 no hay reporte de jugadores en la app
- soporte puede recibir reportes externos por email
- soporte puede forzar cambio de nickname en casos validos

## Soporte y contacto

### Canales V1
- email de soporte declarado
- formulario de contacto en la app
- FAQ accesible sin login

### Tiempos
- primera respuesta: 5 dias habiles maximo
- escalamiento por casos urgentes: 2 dias habiles

## Proceso de eliminacion de cuenta

### Acceso
- accesible desde configuracion sin necesidad de contactar a soporte
- requiere reautenticacion

### Efectos
- bloqueo inmediato de la cuenta
- soft delete: datos personales anonimizados, ranking historico se mantiene anonimizado
- hard delete completo tras 30 dias
- el nickname queda reservado por 90 dias para evitar suplantacion

### Comunicacion
- correo de confirmacion al pedir la eliminacion
- correo final al ejecutar el hard delete
- el usuario puede cancelar la eliminacion dentro de los primeros 7 dias

## Seguridad y reporte de incidentes

### Reglas internas
- los datos personales viajan cifrados en transito y en reposo
- las contraseñas no se almacenan en texto plano
- las claves de acceso a servicios viven en sistemas de secretos, no en el codigo

### En caso de incidente
- evaluacion interna inmediata
- notificacion a usuarios afectados si aplica
- notificacion a autoridades cuando la jurisdiccion lo exija
- registro interno del incidente y aprendizaje

## Pendientes a confirmar con abogado
- forma juridica del responsable: persona natural o sociedad
- correo y direccion oficiales para politicas
- ley aplicable y tribunal competente para los terminos: recomendado Colombia como base
- versiones traducidas oficiales de politicas: como minimo espanol e ingles
- politica de manejo de menores que se cuelan pese a la regla de edad
- relacion con DPO si aplica bajo GDPR
- decision final sobre el periodo exacto de soft delete y reserva de nickname
- evaluar registro ante la Superintendencia de Industria y Comercio en Colombia
- validar paises con restricciones especiales tipo China, Corea del Sur, Iran, India y decidir si se excluyen o se gestionan aparte

# Investigación gráfica de Enigmatrix: cómo acercarse a un juego de empresa grande

Fecha: 04-11-2026. Para: Alejandro.
Fuente única: el archivo de datos de la investigación (10 temas con fuentes, 5 opciones técnicas y 3 jueces). No se buscó nada más en internet.

Aviso importante sobre las cifras. Todos los costos y tiempos de las 5 opciones técnicas son **estimaciones de los agentes que hicieron las propuestas. No están verificadas**: casi ninguna viene de páginas oficiales de precios y hay que pedir cotizaciones reales antes de gastar. Lo mismo vale para las duraciones de las animaciones (son propuestas de diseño que se ajustan probando en un teléfono) y para los umbrales de la prueba de concepto (los propusieron los agentes, no una fuente).

Revisión del arquitecto (04-11-2026). Contrasté el diagnóstico de la sección 2 con el código actual de la app, y se confirma:
- El tablero es una columna de filas con un contenedor por casilla (`app/lib/src/ui/board_view.dart`, 608 líneas).
- Los muebles se dibujan con código (`FurniturePainter`).
- Los sospechosos son círculos con degradado y texto.
- `pubspec.yaml` no tiene ningún paquete de audio ni de vibración.

Un verificador independiente revisó cifras, puntajes y URLs contra el archivo de datos, y sus 13 correcciones ya están aplicadas.

## 1. Resumen en un minuto

**Por qué hoy no parece un juego.** La investigación apunta a ejecución y método, no al estilo "papel recortado" que tú elegiste. Hoy el tablero es una grilla de widgets (un cuadro de app por cada casilla), el arte está dibujado con código, los sospechosos son círculos con una letra, casi no hay animación, no hay sonido ni vibración, y los botones son planos como los de una app. La investigación apunta (con pistas indirectas, sobre todo ofertas de empleo) a que un juego de estudio grande se siente vivo por respuesta en capas a cada toque (movimiento, destello, partículas, sonido, vibración), por personajes con cara y por un arte ilustrado de verdad.

**Qué usan los estudios grandes.** Unity es el motor dominante entre los estudios que se pudieron verificar (el motor de Royal Match y de Monument Valley 3), arte hecho en Blender y Spine (según las ofertas citadas; Photoshop e Illustrator los menciona solo el resumen del agente), animación de personajes con Spine, y partículas y efectos dentro del motor. Los equipos de referencia son de 60 a 100 personas o más. Con una persona más IA no se iguala el volumen: se gana con pocas pantallas muy pulidas.

**Qué recomiendan los jueces.** Tres jueces con lentes distintas puntuaron de 0 a 10 las cinco opciones. La opción A (quedarse en Flutter y subir el nivel con Flame y Rive) obtuvo 6 en techo visual, 8,5 en viabilidad con el equipo real y 8 en costo y riesgo. Unity (B) obtuvo 9, 3,5 y 4. Dos jueces eligieron A como ganadora; el juez de techo visual eligió Unity, pero admite que cambiaría a A si una prueba corta no muestra una diferencia visible a favor de Unity.

**Qué decisión tienes que tomar.** Si autorizas una prueba de concepto de 1 a 2 semanas de la opción A (un tablero de 6x6 y otro de 8x8 de la Mansión, con medición en un teléfono Android real), y con qué presupuesto de arte. El arte (ilustrador y animador) es la ruta crítica sea cual sea el motor. Las preguntas concretas están en la sección 10.

**Palabras que conviene saber**
- **Motor de juego:** programa con editor visual que trae cámara, partículas, animación y sonido listos (Unity, Godot). Flame es una librería que da eso dentro de Flutter.
- **Game feel o "juice":** el conjunto de pequeñas respuestas (rebotes, temblores, destellos, sonidos) que hacen satisfactorio tocar el juego.
- **Rig:** el esqueleto de capas de un personaje que permite animarlo; con una plantilla única, cada sospechoso cambia el dibujo y no la animación.
- **Rive y Spine:** programas para animar personajes 2D. Rive es gratis para empezar; Spine cuesta una licencia única.
- **Prueba de concepto (vertical slice):** una porción pequeña del juego terminada de punta a punta para decidir con datos.
- **APK y fps:** el peso del archivo de la app, y los cuadros por segundo (cuanto más alto, más fluido se ve el movimiento).

## 2. Por qué Enigmatrix no parece un juego hoy

Estas son las causas que la investigación encuentra. Ninguna prueba por sí sola que la causa sea el motor: es una inferencia razonable que la prueba de concepto debe validar.

1. **El arte está dibujado con código.** Los estudios top no hacen el arte con widgets ni con formas vectoriales en código: usan arte ilustrado en herramientas de dibujo y 3D. Hoy el aspecto de papel es solo "color pastel y borde grueso", por eso se ve como plantilla.
2. **El papel es una paleta y no un comportamiento.** En los referentes de papel (Tearaway, Paper Trail) el papel se dobla, se rasga, se arruga y se pliega. En Lumino City y Kirby's Epic Yarn la textura es fotografiada de materiales reales. En Enigmatrix no hay textura real ni sombra real.
3. **Interfaz de app y no de juego.** Los juegos top simulan volumen con gradientes y trazos y usan colores primarios de alto contraste (respaldado parcialmente por una guía de botones y un análisis de UX de Royal Match). La receta concreta de botón (borde inferior oscuro, brillo superior, sombra) es práctica general de la industria que la investigación no pudo verificar. Las apps usan superficies planas, como hoy. Tampoco hay un mapa de progreso con identidad propia por mundo.
4. **Falta de game feel.** Hoy el juego responde con un cambio de estado. Debería responder con un evento: escala, destello, partícula, sonido y vibración en los mismos 100 milisegundos (propuesta de diseño de los agentes, no cifra de una fuente).
5. **Sin personajes vivos.** Los sospechosos son círculos con letra. En June's Journey, un directivo de Wooga dice que el apego a los personajes es parte clave del enganche (no hay fuente que lo atribuya a la ilustración). Cluedo digital vende paquetes de sospechosos con personajes reconocibles, según una nota de prensa promocional, sin datos de retención. Duolingo se distingue de una app genérica por sus personajes ilustrados con estados.
6. **Sin sonido ni vibración.** El audio hoy no existe en el proyecto. Hidden Folks, uno de los referentes, tiene más de 2.000 efectos hechos con la boca (según las fichas de tienda; no se pudo confirmar quién los grabó): el sonido es parte de su identidad.
7. **La grilla de widgets limita lo técnico.** Con un contenedor por casilla es difícil hacer partículas, cámara, sacudidas y capas. Esto es una inferencia técnica de los agentes, no una cifra de las fuentes.
8. **Lo que dicen los referentes.** Tu frase "no es interactiva" coincide con la investigación: ningún referente de culto gana por realismo; todos ganan por un estilo cerrado, legibilidad de lo que se toca, sonido y respuesta al toque.

## 3. Qué usan los estudios grandes

**Motores.** Unity domina los juegos móviles comerciales. Royal Match figura con Unity (https://en.wikipedia.org/wiki/Royal_Match) y Monument Valley 3 también (https://unity.com/resources/monument-valley-3-blurring-art-and-design). Rovio y Moon Active piden Unity más Spine en sus ofertas de empleo. King usa Unity y herramientas propias como Defold, aunque ese dato es de una charla de 2016 y puede estar desactualizado (http://www.pocketgamer.biz/what-tools-does-king-use-to-develop-its-hugely-successful-games/). Unity afirma que más del 70 % de los 1.000 mejores juegos móviles lo usa (cifra propia; otras páginas dan números distintos, https://unity.com/mobile). No se pudo confirmar el motor de Playrix, Peak ni Wooga.

**Otros motores.** Godot 4 es gratis y tiene éxitos en PC (Slay the Spire 2), pero no se encontró un puzzle móvil grande hecho con él. Unreal es excesivo para un puzzle 2D. Defold y Cocos quedan como secundarios. De Flutter con Flame no hay ningún éxito comercial grande verificado; solo demos de Google (I/O Pinball, I/O FLIP y Super Dash, hecho por dos personas en seis semanas, https://verygood.ventures/blog/how-we-built-the-new-super-dash-demo-in-flutter-and-flame-in-just-six-weeks). Unity cobra 0 USD de licencia mientras los ingresos o la financiación no pasen 200.000 USD (https://unity.com/products/pricing-updates); el cobro por instalación (Runtime Fee) fue cancelado (https://unity.com/runtime-fee).

**Pipeline de arte y animación.** Se mezclan ilustración 2D, 3D en Blender y animación 2D con Spine, más partículas hechas dentro del motor. Lo muestran ofertas de empleo: una oferta de una agencia (WonderBrains) para animar al personaje King Robert de Royal Match, sin confirmar que el cliente sea Dream Games (https://djinni.co/jobs/839176-2d-3d-gameplay-animator/), Playrix (https://hitmarker.net/jobs/playrix-senior-3d-2d-artist-playables-1543023) y Rovio (https://www.rovio.com/open-positions/senior-technical-artist). Cuidado: casi toda la evidencia son ofertas de trabajo, que muestran lo que buscan y no el proceso real. Los estudios tienen roles dedicados a animación 2D, efectos (VFX) y artista técnico, y subcontratan lo cinematográfico: Dream Games trabajó con Psyop en los films de Royal Kingdom (https://shots.net/news/view/dream-games-teams-with-psyop-for-launch-of-royal-kingdom).

**Tamaño de equipos (datos parciales y de distintos años).** Gardenscapes: más de 100 especialistas (https://www.articy.com/en/showcase/gardenscapes/). Homescapes: de unas 10 a 60-80 personas y unos 18 meses de desarrollo. June's Journey: unas 60 durante el desarrollo y cerca de 24 después (ambos en GamesBeat: https://gamesbeat.com/?p=147473 y https://gamesbeat.com/?p=146927). Dream Games: 30 personas en 2021 y 80 a inicios de 2022 (dato de fiabilidad baja, https://tech.eu/2022/01/18/royal-match-maker-dream-games-levels-up-with-225-million-raise-now-valued-at-2-75-billion/). Ninguna fuente dice cuántos son artistas o animadores.

**Uso de IA.** El archivo no trae datos verificados sobre cómo usan IA los estudios grandes. Sí trae el flujo realista de estudios pequeños en 2025-2026 (https://inkration.com/ai-art-tools-for-game-studios-in-2026-what-actually-works-for-production/): una herramienta para explorar ideas (Midjourney), un modelo de estilo entrenado con tus propias referencias para producir en serie (Scenario, Layer), y retoque humano obligatorio. Casi todas esas fuentes son de vendedores de herramientas, sin casos verificados de juegos publicados.

**Qué se puede imitar con una persona más IA**

| Lo que hacen los grandes | Cómo se imita |
|---|---|
| Kit de piezas reutilizables colocadas por herramienta (Monument Valley 3, https://www.designweek.co.uk/how-monument-valley-3-came-to-life/) | El generador de mapas de Enigmatrix coloca muebles ilustrados como "pinceles": cada nivel sale con aspecto de ilustración sin dibujarlo a mano |
| Subcontratar lo caro y puntual (Psyop) | Freelancers por encargo para personajes, icono, capturas de tienda y un tráiler corto |
| Animación esquelética con editor | Rive (gratis para empezar) y que Claude solo lo integre |
| Roles de feedback y VFX | Un "director de feedback" en el código que dispara animación, sonido y vibración desde un solo evento |
| Equipos de 60 a 100 personas | No igualarlos: una pantalla (el tablero) y 4 o 5 momentos muy pulidos |

## 4. Lo que hace que se sienta de estudio grande

Principios con respaldo en las fuentes: cada acción produce una respuesta inmediata, en capas y proporcional a su importancia (Juice it or lose it, https://gamedeveloper.com/design/video-is-your-game-juicy-enough-); las capas se apilan sobre una sola acción y la sacudida sube y decae rápido (The Art of Screenshake, https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects); en Royal Match la moneda vuela desde donde se gana hasta donde se guarda y el retrato del Rey reacciona al estado de la partida (https://www.funovus.com/blogs/royal-match-dominates-match-3-what-can-all-designers-learn/). De Juice it or lose it y The Art of Screenshake solo se pudieron consultar resúmenes y recreaciones de terceros; la sede y el año del primero varían según la fuente. La idea de reservar lo más intenso para los hitos viene de artículos que advierten contra el exceso de juice. Ninguna animación debe bloquear el siguiente toque.

**Las duraciones, tamaños y conteos de la tabla son propuestas de diseño, no cifras de las fuentes.** Sonido y vibración arrancan en el primer cuadro del mismo evento.

| Momento | Qué se anima | Sonido (y vibración) | Duración aprox. |
|---|---|---|---|
| Tocar un sospechoso | Se hunde un poco, rebota y se asienta; anillo de selección; el retrato pasa a "atento"; filas y columnas candidatas se iluminan levemente | Tick corto y suave; vibración mínima | 120 ms |
| Anotar candidato (lápiz) | La marca aparece con aplastamiento y 3 grados de giro; sin partículas | Rasguño de lápiz con 3 variaciones; vibración suave, máximo una cada 80 ms | 140 ms |
| Confirmar en una casilla | La ficha cae con estiramiento y aterriza aplastada; onda de papel; 6 a 8 trozos de confeti; destello de un cuadro; la cámara da un pequeño golpe | Golpe de sello o madera con tono ascendente; vibración de clic y golpe leve | 350 ms |
| Tachar fila y columna | Una barra de luz recorre fila y columna casilla a casilla (efecto dominó); cada X se dibuja con trazo animado | Arpegio descendente de 4 a 6 notas; pulsos separados 50 ms o más | 450 ms |
| Error al resolver (ver la decisión 9 de la auditoría: quizá solo se muestre cuántas casillas fallan) | Sacudida amortiguada del tablero; la pista en conflicto parpadea en rojo tinta dos veces; el detective duda; si se pierde vida, el corazón se agrieta | Zumbido grave y mate, nunca humillante; dos pulsos cortos. Siempre se explica por qué falló | 500 ms |
| Resolver y revelar al asesino | Pausa y viñeta oscura; ola de luz fila por fila; los inocentes saltan en cascada; silencio breve; zoom hacia el asesino; golpe dramático; estrellas con rebote, confeti y monedas que vuelan al contador; botón "Siguiente caso" | Redoble, golpe dramático de 1 s y fanfarria cálida; golpe fuerte en la revelación. Se puede saltar tras el primer segundo | 3 a 4 s |
| Racha diaria | El contador rueda como odómetro y la llama crece; en hitos (7 y 30 días) se estampa un sello grande; si se rompe, la llama se apaga con opción de salvarla | Crepitar creciente y "ding" cálido; vibración al caer el número | 1,5 a 2 s |
| Desbloquear un mundo | El candado tiembla, se abre y cae; puertas o cortinas se abren con 2 o 3 capas de profundidad; el nombre del mundo entra con rebote; partículas propias del mundo (polvo en la mansión) | Llave y cerradura, acorde ambiental propio de cada mundo; vibración al abrir | 4 a 5 s |

**Lo que más separa una app de un juego es el reposo vivo.** Los sospechosos respiran (escala de 1,00 a 1,02 cada 3 segundos) y parpadean cada 4 a 7 segundos; las velas titilan; hay polvo muy tenue; el detective cambia entre 2 o 3 poses; el botón de la acción recomendada pulsa suave. Todo con poca amplitud.

**Reglas de proporción.** Micro (toque, nota): menos de 150 ms y sin partículas. Medio (confirmar, tachar): 250 a 450 ms. Mayor (resolver, mundo): 2 a 4 s con botón de saltar. Un juego de deducción es de pensar: lo frecuente debe ser sutil o cansa, y lo grande se reserva para los hitos. No hay estudios que prueben que esto mejore la retención en puzzles de deducción, por eso se propone probarlo con 5 a 8 jugadores reales.

**No negociables.** Ajuste "reducir movimiento" que cambia sacudidas y destellos por fundidos, nada de más de 3 destellos por segundo, interruptores separados de sonido, música y vibración, y un tope de partículas por tipo de teléfono (por ejemplo 20 en gama baja y 80 en alta, valores a medir).

**Orden de implementación sugerido por impacto y costo:** 1) sonido y vibración base (menos de 10 efectos); 2) aplastamiento y anticipación al tocar y confirmar; 3) tachado en ola; 4) secuencia de resolver y revelar; 5) reposo vivo; 6) racha y mundos. Cada paso se prueba en un teléfono real.

## 5. El arte

### 5.1 Papel premium frente a papel amateur

Tres cosas separan el papel premium del amateur en los referentes:
1. **Materialidad real capturada.** Lumino City fotografió una maqueta de papel y cartón de unos 3 metros (https://mcvuk.com/development-news/crafting-the-lumino-city); Kirby's Epic Yarn fotografió telas reales (https://en.wikipedia.org/wiki/Kirby%27s_Epic_Yarn). Ese nivel de producción no es replicable aquí, pero sí la idea: fotografiar o escanear materiales con el teléfono y luz difusa.
2. **El papel como comportamiento.** Tearaway se basó en doblar, rasgar y arrugar (https://gameinformer.com/b/news/archive/2013/03/28/media-molecule-talks-about-crafting-the-world-of-tearaway). Paper Trail (2024; consolas, PC, iOS y Android; equipo pequeño) integra el plegado en la mecánica (https://www.gonintendo.com/contents/30090-paper-trails-devs-look-back-on-how-the-game-s-unique-mechanic-was-birthed).
3. **Densidad de respuesta con sonido propio.** Hidden Folks logra un estilo muy reconocible y responde al toque en muchos elementos (la cifra de más de 500 interacciones es de un listado no oficial de Android) (https://hiddenfolks.com/press).

**¿Conviene mantener el estilo papel? Sí.** Razones: lo elegiste entre 6 mockups; Paper Trail muestra que el papel se puede llevar a móvil con un equipo pequeño (salió también en consolas y PC; no hay datos de ventas); y tu queja (no es interactiva, no parece juego) apunta a falta de materialidad, animación y sonido, no al concepto. La recomendación es redefinirlo como "maqueta de papel recortado y fotografiado": piezas con borde recortado, grosor, sombra proyectada y textura de fibra real; luz cálida por habitación; paleta apagada por mundo con un color de acento (como Darkside Detective, según una fuente; Golden Idol se cita por resaltar claramente lo que se toca). La regla de reservar el acento a pistas, selección y sospechosos es propuesta de los agentes. Bordes rasgados, parallax y stop-motion son hipótesis de diseño razonables, no hechos verificados de esos juegos. Además la competencia directa (apps Murdoku) está poco documentada visualmente, lo que deja espacio para diferenciarse por calidad.

### 5.2 Personajes animados

- **De círculos a retratos.** Cada sospechoso necesita rostro, nombre, mini-biografía y 2 o 3 expresiones (neutral, atento, nervioso, descartado). En June's Journey (más de mil millones de dólares de ingresos), un directivo de Wooga dice que el apego a los personajes es parte clave del enganche; no hay fuente que lo atribuya a la ilustración (https://www.globalgamesforum.com/news/how-wooga-turned-rewarded-ads-into-an-80-engagement-machine). Cluedo digital vende paquetes de sospechosos con personajes reconocibles, según una nota de prensa promocional, sin datos de retención (https://www.prnewswire.co.uk/news-releases/hasbro-and-marmalade-game-studio-extend-their-relationship-with-the-introduction-of-cluecluedo-game-for-mobile-616129844.html).
- **Rive es la ruta recomendada.** Runtime gratis (licencia MIT), paquete oficial para Flutter, y una "máquina de estados" que permite cambiar la expresión (neutral, sospecha, sorpresa, culpable) sin tocar el código. El plan gratis permite 3 archivos; el plan Cadet permite exportar a producción. Sobre su precio: la página oficial muestra 17 USD por asiento al mes y también 108 USD al año; las dos cifras no cuadran entre sí (17 x 12 = 204), así que hay que confirmar en rive.app cuál es el precio real. Máximo 3 asientos (https://rive.app/docs/account-admin/pricing). Duolingo construye así a su personaje Lily, con un archivo de menos de 1 MB (https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life).
- **Spine es el plan B.** Es el estándar de la industria con runtime para Flutter y Flame, pero exige licencia del editor: pago único de unos 369 a 439 USD (sin confirmar cuál plan cuesta cuánto) y plan anual Enterprise si la empresa factura más de 500.000 USD (https://esotericsoftware.com/spine-purchase).
- **Se descartan** Live2D (sin soporte para Flutter encontrado y pago al publicar), el cuadro a cuadro (pesa mucho con 6 a 16 sospechosos) y el 3D.
- **Plantilla de rig única.** Un solo esqueleto de capas (cabeza, ojos, cejas, boca, pelo, ropa, accesorio) y una máquina de estados común: cada sospechoso cambia el arte y no la animación, así el costo de animar se paga una vez.
- **Límites.** Rive suma unos 15 MB al paquete en un caso medido (https://phabricator.wikimedia.org/T433250) y su cinemática inversa es menos profunda que la de Spine. Las animaciones menores (respirar, parpadear, rebotar) se pueden programar sin Rive, y Rive se reserva para expresiones clave.
- **La IA sirve para el dibujo, no para animar.** La consistencia entre poses sigue sin estar resuelta: hace falta retoque manual de las piezas separadas.

### 5.3 Cómo producir el arte con IA y freelancers

**Flujo recomendado (modelo híbrido).**
1. Dirección de arte: tus 6 mockups aprobados más 10 a 15 capturas de referencia por pantalla (Game UI Database, https://www.gameuidatabase.com/about.php, tiene más de 55.000 capturas filtrables).
2. Núcleo humano: un ilustrador freelance hace logo, 6 a 8 sospechosos con expresiones en capas, el kit de interfaz y 15 a 30 imágenes de referencia.
3. Volumen con IA: se entrena un modelo de estilo privado con esas referencias para producir muebles, armas, fondos e íconos; Midjourney solo para explorar; Recraft para íconos vectoriales.
4. Retoque obligatorio (limpieza, fondo transparente, paleta, borde recortado), que Claude puede automatizar con scripts.

**Herramientas de pago.** Los precios vienen de blogs comparadores, se contradicen entre sí y hay que verificarlos en cada sitio oficial.

| Herramienta | Costo aproximado | Para qué |
|---|---|---|
| Midjourney | 10 a 120 USD al mes; los planes de pago incluyen derechos comerciales | Explorar ideas y arte clave |
| Scenario | Desde unos 15 USD al mes (niveles de 15, 45 y 75) | Modelo de estilo propio |
| Recraft Basic | 12 USD al mes, derechos comerciales | Íconos y piezas vectoriales |
| Rive Cadet | La página oficial muestra 17 USD por asiento al mes y también 108 USD al año; las dos cifras no cuadran (17 x 12 = 204), hay que confirmar en rive.app cuál es el precio real. Máximo 3 asientos | Exportar animaciones |
| Spine | Pago único de unos 369 a 439 USD | Plan B de animación |
| 3D con IA (Meshy y otros) | Unos 12 a 30 USD al mes | Se desaconseja salvo que se elija vista 3D |

Un conjunto mínimo (exploración, modelo de estilo e íconos) cuesta del orden de 30 a 80 USD al mes.

**Freelancers.** No se encontraron tarifas fiables de Latinoamérica. Referentes globales de marketplaces (fuentes débiles): 100 a 1.000 USD por diseño de personaje 2D y 25 a 60 USD por hora (https://juegostudio.com/blog/character-design-cost). Hay que cotizar en Colombia, México, Argentina y Brasil. Rangos de trabajo de los agentes, no verificados, para un mundo (la Mansión) con la opción A:

| Concepto | Rango estimado (USD) |
|---|---|
| Ilustrador: logo, 6 a 8 sospechosos, referencias | 1.000 a 4.000 |
| Animador de Rive: plantilla y estados | 500 a 2.000 |
| Herramientas de IA durante 3 a 4 meses | 150 a 500 |
| Audio | 0 a 400 |
| Pruebas con jugadores y tráiler corto | 200 a 800 |
| Icono y capturas de tienda | 100 a 400 |
| Rive Cadet (108 USD, ver nota de precio) y cuentas de tienda (Google Play unos 25 USD únicos, Apple unos 99 USD al año; cifras de conocimiento general no verificadas en la investigación) | unos 230 |
| **Total aproximado de un mundo** | **2.000 a 8.500** |

El total incluye partidas que no aparecen en las filas de arriba y redondea hacia arriba (es aproximado). Cada mundo adicional con el mismo método costaría unos 800 a 2.500 USD (estimación). Los paquetes de assets comprados (de 1 a 15 USD) sirven solo de relleno temporal porque dan un aspecto genérico.

**Derechos y reglas de las tiendas.** En Estados Unidos el arte puramente generado por IA no es protegible; el retoque humano sustancial mejora la protección (informe de la Oficina de Derechos de Autor del 29-01-2025, https://blogs.loc.gov/copyright/2025/02/inside-the-copyright-offices-report-copyright-and-artificial-intelligence-part-2-copyrightability/). Por eso el logo y los personajes clave deben ser hechos o intervenidos por una persona, guardando prompts y versiones. Google Play no prohíbe el arte hecho con IA si va fijo dentro del juego (https://support.google.com/googleplay/android-developer/answer/14094294); en la App Store la única regla de IA verificada trata de datos personales enviados a IA de terceros. Los planes gratuitos de las herramientas suelen ser solo no comerciales. No se investigó la ley de Colombia ni de la Unión Europea. Hace falta una hoja de licencias (herramienta, plan, fecha, prompt, intervención humana).

## 6. Audio y vibración

**Estrategia de costo casi cero.** Un mismo evento dispara animación, sonido y vibración sincronizados, con sobriedad y con opción de apagarlos (guías de Android y Apple, https://developer.android.com/develop/ui/views/haptics/haptics-principles). Bastan 10 a 15 sonidos clave para dar sensación de juego.

- **Efectos de sonido gratis:** Kenney (licencia CC0, sin atribución), Freesound filtrando solo CC0, Sonniss GDC Bundle gratuito (prohíbe usar el audio para entrenar IA) y Pixabay. Las licencias se confirmaron por guías secundarias: hay que leerlas en los sitios oficiales (https://opengameart.org/content/51-ui-sound-effects-buttons-switches-and-clicks). Se evita GPL y CC-BY-NC.
- **Sonido propio con personalidad:** grabar con el teléfono foley casero de papel (rasgar, doblar, deslizar), al estilo de los más de 2.000 efectos hechos con la boca de Hidden Folks (según las fichas de tienda; no se pudo confirmar quién los grabó). Es la parte más barata y la que más "parece juego".
- **Motor de audio:** flutter_soloud, recomendado en la documentación de Flutter para baja latencia y varios sonidos a la vez (https://docs.flutter.dev/cookbook/audio/soloud). Un servicio de audio con canales separados de efectos y música.
- **Música:** un tema ambiental por mundo en 2 o 3 capas que se activan según el estado (base, tensión al final o con pocas vidas, y un golpe de victoria). Opciones: pistas CC0 revisadas o un mes de un generador de IA con licencia comercial (Suno Pro, a confirmar precio; ElevenLabs para efectos, unos 6 USD al mes según una comparativa de terceros). Los términos de la IA cambian y hay litigios abiertos: mejor para ambientes que para el tema principal.
- **Vibración en Android:** composiciones con primitivas (clic, tic, golpe, subida lenta, caída rápida), no una vibración larga que suena a zumbido. Hay que comprobar si el teléfono las soporta y bajar a una vibración simple si no (https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects). Entre golpes que deban distinguirse, al menos 50 ms.
- **Vibración en iPhone (más adelante):** Core Haptics con archivos de patrón, solo en dispositivo físico (https://developer.apple.com/documentation/corehaptics/chhapticpattern.md).
- **Un servicio propio de vibración** tras una interfaz estable, para poder cambiar de paquete (los que existen son jóvenes) sin tocar el juego. Un catálogo corto de 3 a 4 patrones.
- **Orden y control:** ajustes separados de sonido, música y vibración, respetar el modo silencio, y una hoja CSV con archivo, fuente, URL, licencia, autor y fecha de cada audio, más una pantalla de créditos.
- **Presupuesto estimado:** de 0 a 400 USD con todo lo anterior. Un tema identitario encargado a un músico se cotiza después de validar el juego (no hay precio verificado).

## 7. Las 5 opciones técnicas

Tres jueces puntuaron cada opción con una lente distinta (de 0 a 10; más es mejor). Los costos y tiempos son estimaciones de los agentes (no verificadas) y **no son del todo comparables**: A estima un mundo; B, uno o dos; C, un mundo más un segundo parcial; D, un mundo; E, dos. La columna de suma la agregué para este informe y no es una cifra de los jueces.

| Opción | Idea en una frase | Costo estimado hasta un MVP (USD) | Tiempo estimado | Juez techo visual | Juez equipo real | Juez costo y riesgo | Suma |
|---|---|---|---|---|---|---|---|
| A. Flutter + Flame + Rive | Quedarse en Flutter y reemplazar la grilla por una escena de juego con arte ilustrado y personajes animados | 2.000 a 8.500 (un mundo) | 12 a 16 semanas | 6 | 8,5 | 8 | 22,5 |
| B. Unity 6 | Reconstruir toda la app en el motor de Royal Match, con Spine para personajes | 3.500 a 10.000 (uno o dos mundos) | 5 a 7 meses | 9 | 3,5 | 4 | 16,5 |
| C. Godot 4 | Reconstruir el cliente en un motor gratis con escenas en texto; el generador de casos queda en Dart como herramienta aparte | 2.500 a 6.500 (austero 1.000 a 2.000) | 5 a 6 meses | 7 | 5 | 4 | 16 |
| D. Híbrido | Menús y cuentas en Flutter, y Unity embebido solo para dibujar el tablero | 4.000 a 7.000 (mínimo 1.500 a 2.500; alto 9.000 a 12.000) | 18 a 28 semanas | 7 | 3 | 3 | 13 |
| E. Flutter sin motor | Quedarse en Flutter puro con arte ilustrado y animación hecha a mano por código | 2.500 a 7.000 (dos mundos) | 14 a 18 semanas | 4 | 7 | 6,5 | 17,5 |

**A. Flutter + Flame + Rive.** Principal ventaja: conserva todo el Dart (motor de puzzles, solver, generador, unos 60 tests y las unas 600 líneas del tablero) sin portar nada, sin segundo programa de construcción ni puente, así que es el camino más barato y corto a un tablero de nivel alto. Principal riesgo: no hay ningún éxito comercial grande verificado hecho con Flutter y Flame ni mediciones de rendimiento en gama media, y el nivel de Royal Match no es alcanzable (el objetivo realista es el de Paper Trail o Hidden Folks en pequeño).

**B. Unity 6.** Principal ventaja: techo visual más alto y herramientas estándar de la industria (luces 2D, partículas, Spine y Firebase oficiales, talento y assets fáciles de conseguir). Principal riesgo: cuesta de 6 a 10 semanas reconstruir lo que ya existe sin que el jugador vea mejora, hay que portar solver, generador y validador a C# (dos códigos que mantener), y es el flujo más incómodo para Claude (escenas difíciles de editar a mano y editor que debe estar abierto).

**C. Godot 4.** Principal ventaja: gratis y el mejor encaje con cómo trabaja Claude (escenas en texto, ejecución sin pantalla, capturas automáticas); además el solver y el generador se quedan como herramienta aparte y no se portan. Principal riesgo: hay que rehacer el meta-juego (cuentas, vidas, compras, anuncios, ranking), Firebase iría por una conexión propia sin caché sin conexión, y no hay un puzzle móvil grande hecho en Godot.

**D. Híbrido.** Principal ventaja: techo visual de Unity en el tablero sin reescribir menús, cuentas ni el Dart. Principal riesgo: es la más compleja para una persona más IA: dos programas de construcción, Unity solo admite pantalla completa y una instancia, retiene entre 80 y 180 MB de memoria, y el puente depende de plugins comunitarios sin mantenimiento verificado.

**E. Flutter sin motor de juego.** Principal ventaja: menor cambio técnico, reversible, y la prueba de concepto cuesta solo unos 60 a 150 USD. Principal riesgo: sin Flame hay que construir a mano cámara, partículas, sacudidas y atlas (un mini motor propio), y es la opción de menor techo visual (4 de 10).

## 8. Recomendación

**Ganó la opción A (Flutter + Flame + Rive).** Obtiene la mayor suma (22,5 frente a 17,5 de E y 16,5 de B). Gana en dos de las tres lentes (viabilidad con el equipo real y costo y riesgo). En techo visual queda cuarta (6), detrás de Unity (9), y hay que decirlo claro.

**Por qué, aun así.** (1) La investigación no demuestra que Flutter sea la causa del problema: lo que separa a Enigmatrix de un juego grande es arte ilustrado, animación, sonido, vibración y game feel, y eso hay que producirlo igual en cualquier motor. (2) Cambiar de motor cuesta de 6 a 10 semanas sin mejora visible. (3) Es reversible: con un contrato de datos en JSON, si Flame falla se prueba Godot con los mismos assets y el mismo motor de puzzles. (4) Es lo que mejor encaja con cómo trabaja Claude (código en texto, un solo lenguaje).

**Bajo qué condiciones cambiaría (según los jueces)**
- **Juez de techo visual (eligió Unity):** pasaría a A si la prueba con los mismos assets no muestra una diferencia visible a favor de Unity, o si tú no percibes un salto que justifique 6 a 10 semanas. Iría a Godot si Unity falla en rendimiento o peso en un Android de 3 a 4 GB, si el trabajo de Claude con el editor es inmanejable o si no puedes instalar y mantener Unity. Elegiría el híbrido solo si el cliente Flutter ya tuviera tanto meta-juego terminado que reescribirlo fuera inaceptable. Sin presupuesto de ilustrador, el techo baja con cualquier motor. Si el SDK de Firebase para Unity da conflictos en Android que no se resuelven en la prueba, reconsideraría A.
- **Juez de equipo real (eligió A):** pasaría a Godot, no a Unity, si la prueba mide menos de 45 a 55 fps en la secuencia de revelación en un Android de gama media, incluso reduciendo partículas. Si Rive resulta inestable o no hay animador, se bajaría a capas de imagen animadas por código (se acerca a E). El híbrido solo si se exige un diorama con profundidad real y Flame no puede. Si el problema fuera solo el arte, la prioridad es el ilustrador antes que el código. Si Flame se queda corto en cámara o efectos pero el rendimiento general es bueno, se cae a E. iOS exige un Mac usado o servicio en la nube con cualquier opción, así que no cambia el orden.
- **Juez de costo y riesgo (eligió A):** pasaría a Godot si hay menos de 55 fps sostenidos al confirmar y resolver (o menos de 30 en gama baja con efectos reducidos) o si Rive es inestable o pesa demasiado. Si no puedes financiar un ilustrador (unos 1.000 a 4.000 USD, estimación del juez, no verificada) y un animador de Rive (unos 500 a 2.000 USD, estimación del juez, no verificada), la opción de menor riesgo sería E reducida. Si el APK de la prueba supera el tope acordado (unos 40 MB, propuesta del juez, a validar), se recortan efectos antes de aceptar un motor más pesado. Solo iría a Unity o al híbrido si el mismo corte se ve claramente mejor allí y aceptas 6 a 10 semanas, un Mac para iPhone y doble mantenimiento.

**Ideas de las otras opciones que conviene injertar**
- Contrato de datos en JSON versionado (casos y eventos del motor) desde el día uno, para poder cambiar de motor sin perder el motor de puzzles (de C, D y B).
- Tablero en tres capas: fija y guardada en memoria, interactiva y de efectos (de E).
- Rive solo en momentos principales (detective, retrato ampliado, revelación); los sospechosos del tablero con capas de imagen movidas por código (de E).
- Solver y generador como herramienta aparte que produce casos en JSON con solución única, y reto diario precalculado (de C).
- Bucle visual para Claude: un script que lanza la app, captura una imagen y la lee (de C).
- Director de feedback y "biblia de feedback" (tabla evento, animación, duración, sonido, vibración, partículas, versión reducida), con modo reducir movimiento (de A, B, C, D y E).
- Kit de piezas como pinceles del generador, más texturas de papel fotografiadas por ti (de B, C, D y E).
- Prueba de 8 muebles: pre-render en Blender (grosor y sombra consistentes) frente a sombra por programa en tiempo real (de C y D).
- Ilustrador humano para logo, sospechosos y kit de interfaz desde la semana 1; IA con modelo de estilo solo para volumen; hoja CSV de licencias (de A y E).
- Un teléfono de gama media y otro de gama baja desde el día uno, y tope de partículas por gama (de A, D y E).
- Salir con 1 o 2 mundos y anunciar el resto; Mansión completa antes de abrir otros (de D y E). No contratar nada hasta pasar el punto de decisión de la prueba (de D).

**Lo que la investigación no pudo verificar**
- Rendimiento y tamaño de la app en Android de gama media para cualquier motor: solo hay anécdotas de foros.
- Ejemplos comerciales grandes de Flutter con Flame o de un puzzle móvil grande en Godot.
- Cómo anima Dream Games a su Rey o Wooga a sus retratos (solo ofertas de empleo).
- Precios oficiales de arte, herramientas y freelancers de Latinoamérica.
- Versiones y estabilidad actuales (2026) de Flame, Rive y spine-flutter con el renderizador nuevo de Flutter.

## 9. Prueba de concepto propuesta

**Qué es.** Una porción jugable de 1 a 2 semanas de la opción A, hecha en una carpeta o rama aparte sin tocar el motor de puzzles. Como el proyecto está en fase de reestructuración sin cambios de código desde el 01-11-2026, necesita tu autorización.

> **ACTUALIZACIÓN 04-11-2026. Alejandro autorizó la prueba con estas condiciones**, que mandan sobre lo que dice esta sección:
> - **Meta:** "pocas pantallas muy pulidas", al nivel de Paper Trail o Hidden Folks, sin intentar igualar a Royal Match.
> - **Dos estilos:** la misma sala se hace como **papel recortado tipo maqueta** y como **ilustración 2D sin papel**, para compararlas en el teléfono.
> - **Arte provisional gratuito:** piezas con licencia CC0, formas y sombras hechas por código, y texturas de papel que puedes fotografiar con tu teléfono. No se gasta en herramientas de IA.
> - **Lo que mide y lo que no:** la prueba mide sobre todo fluidez, game feel, sonido y cuál de los dos estilos va mejor. No responde todavía si el juego "se ve de estudio grande", porque eso depende del arte definitivo. El criterio de percepción de 5 a 8 personas se usa para comparar los dos estilos y la sensación al tocar.
> - **Costo en herramientas:** 0 USD. Solo el teléfono de prueba, si no tienes uno.
> - **Referencias:** pendientes. Alejandro pidió ver ejemplos de cada juego.

**Alcance.** Mundo Mansión, un tablero de 6x6 y otro de 8x8, alimentado por una copia fija del generador actual:
1. Tablero como una sola escena de Flame: piso con textura escaneada, paredes con sombra, 8 a 10 muebles ilustrados colocados por el generador, una luz con viñeta y un leve efecto de profundidad.
2. Tres sospechosos con retrato completo: de preferencia en Rive (4 estados); si aún no hay animador, retratos fijos con respiración, parpadeo y aplastamiento hechos por código. El resto de los personajes del tablero (6 en el 6x6, 8 en el 8x8) llevan un retrato fijo sencillo, y se avisa a los jugadores que es provisional.
3. Los momentos de confirmar, tachar en ola, resolver y revelar, y error, orquestados por un director de feedback.
4. 10 a 15 sonidos CC0 y 5 vibraciones, con alternativa simple, más un modo "reducir movimiento".
5. Arte provisional con Midjourney o Recraft a partir de tus mockups, con retoque mínimo (basta con que sea creíble).

**Criterios de éxito (umbrales propuestos por los agentes, a ajustar contigo)**

| Qué se mide | Meta |
|---|---|
| Fluidez en un Android real de gama media (3 a 4 GB de RAM) al confirmar y resolver | 55 fps o más sostenidos |
| Fluidez en gama baja con efectos reducidos | 30 fps o más |
| Peso de la app de la prueba (APK) | Por debajo de un tope acordado (propuesta: unos 40 MB, a validar) |
| Arranque en frío | Menos de 3 segundos (propuesta) |
| Bloqueo de toques | Ninguna animación impide el siguiente toque |
| Percepción de 5 a 8 personas ajenas al proyecto, en su propio teléfono y sin explicación | Califican la pieza como "se ve y se siente como un juego", comparada con la interfaz actual |
| Tu veredicto al tocarla en tu teléfono | Dices que va en la dirección correcta |

**Criterios de fracaso.** Fluidez bajo el umbral en gama media incluso con menos partículas; Rive inestable con el renderizador nuevo de Flutter; o arte generado que no mantiene consistencia entre piezas tras un retoque razonable.

**Qué se compararía.**
- **Contra la interfaz actual**, en video lado a lado y con los jugadores de prueba.
- **Contra un control hecho en Godot:** los jueces de equipo y de costo proponen repetir el mismo corte con los mismos assets en 2 a 3 días y comparar peso de la app, fps y arranque con datos y no con opinión. El juez de techo visual propone en cambio comparar con Unity. Mi recomendación como arquitecto es no construir ninguno de los dos controles de entrada. Primero se hace la prueba de A. Si falla en fluidez, el mismo corte se repite en Godot. Si funciona bien pero no te convence cómo se ve con el mismo arte, se repite en Unity. Así no se paga una comparación que tal vez no haga falta. La decisión es tuya.
- **Con y sin efectos** en la secuencia de resolver, para saber si el exceso de juice cansa.
- Un panel que arma Claude (pieza propuesta, referencia y tablero real) para que apruebes el arte sin usar ningún editor.

**Si algo falla.** Si falla solo Rive: capas por código o Spine. Si falla Flame en fluidez: el mismo corte en Godot con el mismo contrato de datos. Si falla el arte: se frena el motor y se invierte primero en el ilustrador.

**Qué entrega y cuánto cuesta.** Un APK que puedes instalar y tocar, una tabla de mediciones y una lista de decisiones (estilo, presupuesto de arte, ilustrador y animador a contratar). Costo estimado: 50 a 200 USD (un mes de herramientas de IA, Rive gratis con 3 archivos, sonidos CC0), más un teléfono Android de gama media de unos 100 a 200 USD si no tienes uno (estimación).

## 10. Decisiones que necesito de ti

1. **Meta visual.** ¿Aceptas que la meta sea "pocas pantallas muy pulidas, al nivel de Paper Trail o Hidden Folks", y no igualar a Royal Match, que se hace con 60 a 100 personas? Conviene acordarlo por escrito para que no vuelva el "no parece de empresa grande".
2. **Referencias.** ¿Qué 3 a 5 juegos te gustan visualmente (Paper Trail, Hidden Folks, Monument Valley u otros)? Con eso se calibra el arte antes de contratar.
3. **Estilo papel.** ¿Mantienes el estilo papel, redefinido como maqueta de papel recortado y fotografiado?
4. **Presupuesto de arte.** ¿Cuánto puedes invertir? Con la opción A, un mundo cuesta unos 2.000 a 8.500 USD (estimación). Sin ilustrador (unos 1.000 a 4.000 USD) ni animador de Rive (unos 500 a 2.000 USD), la calidad queda media con cualquier motor.
5. **Prueba de concepto.** ¿Autorizas la prueba de 1 a 2 semanas en una carpeta aparte, con un gasto de 50 a 200 USD?
6. **Cambio de motor.** ¿Aceptas migrar a otro motor (Godot, o Unity si lo pides) solo si la prueba falla con los números acordados?
7. **Teléfonos de prueba.** ¿Tienes un Android de gama media (3 a 4 GB de RAM) y otro de gama baja para medir? Si no, ¿compras uno usado de unos 100 a 200 USD (estimación)?
8. **Compras.** Claude no puede comprar ni aceptar términos por ti: ¿contratas tú los planes de pago de herramientas (Midjourney o Scenario, Recraft, Rive Cadet)?
9. **Tu rol de aprobación.** ¿Puedes revisar y aprobar cada lote de arte en pocos días? Sin tu curaduría la IA produce algo genérico.
10. **Jugadores de prueba.** ¿Puedes conseguir 5 a 8 personas ajenas al proyecto, de los mercados objetivo, para probar?
11. **Alcance.** ¿Sales con la Mansión y uno o dos mundos y anuncias el resto, en vez de pulir los cinco a la vez?
12. **Autoría y licencias.** ¿Aceptas que logo y personajes clave los haga o intervenga una persona, y que se lleve una hoja de licencias de arte y audio?
13. **iPhone.** ¿Dejamos iPhone para después de Android? Pide un Mac usado o servicio en la nube, sea cual sea el motor.

## 11. Fuentes

Estas son las fuentes del archivo de datos agrupadas por tema (una por hallazgo, más las citadas en el texto; el archivo completo trae unas 290 direcciones). Muchas son ofertas de empleo, blogs y páginas de vendedores: revisa la advertencia de cada tema en el archivo de datos.

**Cómo trabajan los estudios top**
- https://en.wikipedia.org/wiki/Royal_Match
- https://djinni.co/jobs/839176-2d-3d-gameplay-animator/
- https://www.articy.com/en/showcase/gardenscapes/
- https://unity.com/resources/monument-valley-3-blurring-art-and-design
- https://shots.net/news/view/dream-games-teams-with-psyop-for-launch-of-royal-kingdom
- https://builtinlondon.uk/job/senior-game-artist-candy-crush-saga/10433736
- https://eu.esotericsoftware.com/blog/spine-flutter-runtime-released
- http://www.pocketgamer.biz/what-tools-does-king-use-to-develop-its-hugely-successful-games/
- https://hitmarker.net/jobs/playrix-senior-3d-2d-artist-playables-1543023
- https://www.rovio.com/open-positions/senior-technical-artist
- https://gamesbeat.com/?p=147473
- https://gamesbeat.com/?p=146927
- https://tech.eu/2022/01/18/royal-match-maker-dream-games-levels-up-with-225-million-raise-now-valued-at-2-75-billion/
- https://www.designweek.co.uk/how-monument-valley-3-came-to-life/

**Motores y frameworks**
- https://unity.com/runtime-fee
- https://en.wikipedia.org/wiki/Royal_Match
- https://gamingonlinux.com/2026/03/the-godot-powered-slay-the-spire-2-has-already-hit-over-3-million-sales
- https://forum.godotengine.org/t/does-anyone-use-godot-4-for-mobile-games/43673
- https://pypi.org/project/gda/
- https://github.com/godot-x/firebase
- https://esotericsoftware.com/spine-runtime-documentation
- https://flutter.dev/blog/announcing-the-flutter-casual-games-toolkit
- https://forum.defold.com/t/madewithdefold-the-released-games-list/2076
- https://forums.unrealengine.com/t/how-to-reduce-mobile-file-size/349473
- https://unity.com/mobile
- https://unity.com/products/pricing-updates

**Game feel / juice**
- https://gamedeveloper.com/design/video-is-your-game-juicy-enough-
- https://infovore.org/tag/feel/
- https://www.funovus.com/blogs/royal-match-dominates-match-3-what-can-all-designers-learn/
- https://developer.android.com/develop/ui/views/haptics/haptics-principles
- https://pub.dev/packages/flame_flare
- https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects
- https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects

**Producción de arte con IA**
- https://inkration.com/ai-art-tools-for-game-studios-in-2026-what-actually-works-for-production/
- https://www.datastudios.org/post/scenario-custom-trained-ai-game-asset-generation-style-consistency-and-pricing-explained
- https://costbench.com/software/ai-3d-generation/scenario-gg/
- https://www.recraft.ai/blog/when-the-brief-says-commercial-not-just-beautiful
- https://www.krea.ai/blog/best-ai-3d-model-generators-2026
- https://blogs.loc.gov/copyright/2025/02/inside-the-copyright-offices-report-copyright-and-artificial-intelligence-part-2-copyrightability/
- https://adobe.com/content/dam/cc/en/legal/terms/enterprise/pdfs/PSLT-CustomModelsTerms-WW-2025v1.pdf
- https://support.google.com/googleplay/android-developer/answer/14094294
- https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai
- https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use
- https://juegostudio.com/blog/character-design-cost
- https://assetstore.unity.com/packages/2d/gui/icons/mobile-gui-kit-casual-games-168353

**Referentes de deducción y detectives**
- https://blogs.tuni.fi/playlab/game-reviews/the-case-of-the-golden-idol-pixelated-dioramas-of-crime-and-mystery/
- https://puzzculture.com/tag/obra-dinn/
- https://hiddenfolks.com/press
- https://www.globalgamesforum.com/news/how-wooga-turned-rewarded-ads-into-an-80-engagement-machine
- https://www.prnewswire.co.uk/news-releases/hasbro-and-marmalade-game-studio-extend-their-relationship-with-the-introduction-of-cluecluedo-game-for-mobile-616129844.html
- https://mwm.ai/apps/murdoku/6787716218
- https://techraptor.net/gaming/reviews/pictopix-review-puzzling-good-time
- https://forum.quartertothree.com/t/the-case-rise-of-the-golden-idol-cases-of-crime-death-and-depravity-in-the-1970s/162895/81

**Flutter como motor de juego en 2026**
- https://pub.dev/packages/flame
- https://docs.flutter.dev/perf/impeller
- https://docs.flutter.dev/resources/games-toolkit
- https://dev.to/mascotengine/rive-vs-lottie-which-animation-tool-should-flutter-developers-choose-in-2026-lp5
- https://flutter.googlesource.com/mirrors/flutter/+/HEAD/docs/engine/impeller/Flutter-GPU.md
- https://www.phoronix.com/news/Fluorite-Toyota-Game-Engine
- https://flutter.dev/blog/i-o-pinball-powered-by-flutter-and-firebase
- https://dev.to/synfinity-dynamics-pvt-ltd/flutter-game-development-in-2026-can-you-build-real-games-with-flutter-peh
- https://verygood.ventures/blog/how-we-built-the-new-super-dash-demo-in-flutter-and-flame-in-just-six-weeks

**Personajes animados**
- https://docsearch.algolia.com/mcp/docs/repo/rive-app/rive-flutter
- https://rive.app/docs/account-admin/pricing
- https://es.esotericsoftware.com/spine-flutter.md
- https://esotericsoftware.com/spine-purchase
- https://www.esotericsoftware.com/spine-godot
- https://live2d.com/en/?p=586
- https://fast.io/resources/best-ai-character-generators-2026.md
- https://tanyapodolskaia.artstation.com/resume
- https://rive.app/blog/rive-as-a-lottie-alternative
- https://phabricator.wikimedia.org/T433250

**Audio y hápticos**
- https://developer.android.com/develop/ui/views/haptics/haptics-principles
- https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects
- https://developer.apple.com/documentation/corehaptics/chhapticpattern.md
- https://pub.dev/packages/bzzz
- https://docs.flutter.dev/cookbook/audio/soloud
- https://sounddesign.irpr.agency/glossary/vertical-layering/
- https://app.cinevva.com/guides/free-sound-effects-music
- https://elevenlabs.io/sound-effects/commercial
- https://opengameart.org/content/51-ui-sound-effects-buttons-switches-and-clicks

**Papel premium frente a papel amateur**
- https://mcvuk.com/development-news/crafting-the-lumino-city
- https://gameinformer.com/b/news/archive/2013/03/28/media-molecule-talks-about-crafting-the-world-of-tearaway
- https://en.wikipedia.org/wiki/Kirby%27s_Epic_Yarn
- https://hyperallergic.com/gorogoa-jason-roberts/
- https://www.gonintendo.com/contents/30090-paper-trails-devs-look-back-on-how-the-game-s-unique-mechanic-was-birthed
- https://www.suppermariobroth.com/tagged/paper%20mario%20the%20origami%20king
- https://docs.flutter.dev/ui/design/graphics/fragment-shaders
- https://activation.unity3d.com/case-study/monument-valley

**UI de juego frente a UI de app**
- https://thisweekinliveops.substack.com/p/5-simple-ux-lessons-from-royal-match
- https://gameanalytics.com/?p=3400
- https://www.gamedeveloper.com/design/rethinking-progression-in-mobile-puzzle-games
- https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life
- https://docs.flame-engine.org/latest/flame/other/widgets.html
- https://www.gameuidatabase.com/about.php

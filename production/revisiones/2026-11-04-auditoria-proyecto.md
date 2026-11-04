# Auditoría del proyecto Enigmatrix

Fecha: 04-11-2026. Para: Alejandro. La hizo el arquitecto (la sesión principal) con 30 agentes Sonnet.

El detalle completo de los 71 hallazgos está en el [anexo](2026-11-04-auditoria-anexo-hallazgos.md), con códigos de H-01 a H-71. Este informe cita por su código los que requieren una acción o una decisión. Los menores que no se citan aquí (H-04, H-11, H-18, H-31, H-38, H-46, H-47, H-48, H-53, H-54) quedan solo en el anexo y se atienden cuando se toque esa parte.

La investigación gráfica tiene su propio informe: [2026-11-04-investigacion-grafica.md](2026-11-04-investigacion-grafica.md). Allí se explica la "opción A": quedarse en Flutter y usar Flame, una librería para hacer juegos dentro de Flutter, y Rive, un programa para animar personajes.

> **ACTUALIZACIÓN 04-11-2026. Respuestas de Alejandro:**
> - **Plan por etapas:** aprobado.
> - **Protección:** autorizó solo el repositorio privado en GitHub. El commit, sacar el proyecto de OneDrive y el cambio de firma siguen sin autorizar.
> - **Documentos:** autorizó ponerlos al día.
> - **Prueba de concepto gráfica:** autorizada, con estas condiciones:
>   - meta: "pocas pantallas muy pulidas";
>   - mostrar los dos estilos (papel como maqueta e ilustración 2D);
>   - arte provisional gratuito;
>   - las referencias quedan pendientes: pidió ver ejemplos.
> - **Reglas:** aceptó mis recomendaciones de las preguntas 5, 9, 10, 11 y 20 (quedan registradas en el ADR-0012).
> - **Para las pruebas:** tiene un Android de gama media y puede conseguir de 3 a 5 personas (pregunta 21).
> - **Mac:** el 12-07-2026 confirmó que tiene acceso a uno, así que la pregunta 22 queda reducida a si el iPhone entra al lanzamiento.
> - **Pregunta nueva (23):** ¿se muestran los mundos bloqueados? Hoy la app muestra los 5, cuatro de ellos con candado, y el doc 06 dice que solo se ven los desbloqueados.

## Cómo se hizo

- **Nueve áreas revisadas desde el principio**:
  1. reglas del proyecto y agentes;
  2. documentos de producto;
  3. documentos de soporte;
  4. roadmap;
  5. código de la app;
  6. motor de puzzles;
  7. experiencia de juego;
  8. seguridad y tiendas;
  9. pruebas.
- **Dos áreas más**: un agente crítico detectó dos huecos y se agregaron como áreas aparte: los 20 casos que recibe el jugador y el orden del repositorio.
- **Revisión estática**: no se ejecutó ni se compiló nada y no se modificó código.
- **Doble comprobación**: un segundo agente, distinto del que escribió cada hallazgo, lo comprobó contra los archivos reales. Quedaron 71 confirmados y 2 descartados. El verificador bajó la gravedad de muchos: al final hay **11 de gravedad alta, 38 media y 22 baja, ninguno crítico**.
- **Comprobaciones mías**: revisé personalmente los más delicados y se confirman:
  - el repositorio no tiene copia remota y el último commit es del 12-07-2026;
  - el generador tiene un error al ajustar la dificultad;
  - los casos se ordenan como palabras;
  - sin la llave de firma, la compilación de publicación se firma con la llave de pruebas;
  - hay 54 tests del motor y 26 de la app.
- **Verificación del informe**: dos agentes independientes revisaron este mismo informe, uno contra el anexo y otro por coherencia y claridad. Sus correcciones ya están aplicadas.

## 1. Resumen en un minuto

**Lo bueno:**
- La base técnica es sólida. El motor de puzzles (solver, verificador de solución única, generador de mapas y 54 tests) es el activo más valioso del proyecto.
- Las reglas del tablero están separadas de la parte visual. Se puede rehacer la gráfica conservando las reglas, aunque habrá que ajustar la capa de toques y el guardado de partida.

**Lo que preocupa, en cinco puntos:**
1. **No hay copia de seguridad real.** Todo el proyecto vive en este PC y en OneDrive, sin ningún servidor git (H-01). Además, Claude Code se ha estado abriendo en la carpeta padre, donde no carga las reglas ni los agentes del proyecto (H-13).
2. **Los documentos se quedaron en junio y julio** (H-14, H-15, H-33, H-34):
   - el roadmap dice "Fase 0";
   - CLAUDE.md menciona herramientas abandonadas;
   - varios documentos describen reglas que el juego ya no usa, y nada indica cuáles siguen vigentes.
3. **No hay registro de que se haya medido si el juego es divertido y justo.**
   - Las rondas de feedback documentadas fueron sobre la apariencia (H-22).
   - Hoy la dificultad de cada caso depende del azar del generador (H-40).
4. **La pantalla de partida tiene deuda técnica**, y es justo donde va el rediseño gráfico (H-55, H-56, H-57):
   - si sales, pierdes todo el progreso;
   - las pistas pueden cortarse sin forma de leerlas completas;
   - no tiene pruebas automáticas.
5. **Para las tiendas faltan trámites que no dependen del código, y algunos tardan** (H-06, H-08, H-24): publicar la política, definir la identidad legal y, según lo investigado, conseguir 12 probadores durante 14 días en Google Play.

**Lo que propongo** es reordenar el plan por etapas (sección 4):
1. Proteger el trabajo y poner los documentos al día.
2. Preparar una versión de prueba y medir el juego con personas.
3. Al mismo tiempo, hacer la prueba de concepto gráfica y arreglar el motor.
4. Invertir en arte solo si las dos pruebas salen bien.

## 2. Lo que está bien y hay que conservar

- **Motor de puzzles** en Dart puro:
  - 16 tipos de pista;
  - solver por niveles;
  - verificador de solución única;
  - generador con mapas procedurales;
  - 54 tests deterministas.

  Tiene huecos que se tratan en la sección 8: la dificultad no se controla, Experto y Élite no se han generado y los tests cubren casi solo el camino feliz.
- **Especificación formal del puzzle** (spec 16), los 5 pilares y el balance (doc 08). Son el filtro objetivo para decidir.
- **Las decisiones están anotadas con fecha y motivo en la bitácora** (`active.md`), aunque solo hay 2 registros formales de decisión (ADR). Falta pasar las demás a ADR para no perder el porqué (H-17).
- **Las reglas del tablero no dependen de Flutter** (`board_state.dart`). Por eso la opción A del informe gráfico es plausible: las reglas se conservan. Que sea fluida en el teléfono lo dirá la prueba de concepto.
- **El riesgo aceptado de la Fase 1** (la solución viaja dentro del archivo del caso) está documentado en el doc 18, con su regla para la Fase 2. Falta reflejarlo como excepción en CLAUDE.md y en un ADR (H-14, H-17).
- **Secretos fuera de git**: la llave de firma y su archivo de claves no se suben al repositorio.
- **Medición de partidas**: ya existen cronómetro, conteo de errores, comentario por caso y exportación. Faltan registrar los abandonos y la versión de la app en cada comentario (H-70).
- **Datos simulados**: están agrupados al inicio de un solo archivo. Tienda, premium y ranking llevan la etiqueta DEMO, pero las vidas, la racha y las estadísticas del perfil no, y hay cuatro ajustes que parecen funcionar sin hacer nada (H-62).
- **Base para las tiendas**: hay un checklist por tienda y un borrador de política de privacidad, aunque los dos están incompletos (sección 9).

## 3. Lo urgente: proteger el trabajo

Nada de esto toca el juego. Está en el orden en que conviene hacerlo.

| # | Qué | Por qué | Quién | Código |
|---|---|---|---|---|
| 1 | Abrir siempre Claude Code en la carpeta del proyecto (`Enigmatrix version final Claude`), no en la carpeta padre | En la carpeta padre las sesiones arrancan sin las reglas del proyecto, sin los agentes y sin la bitácora. No depende de nada más y se hace desde ya | Tú, al abrir Claude Code | H-13 |
| 2 | Commit del trabajo del 01-11-2026 (agentes, CLAUDE.md, configuración e informes) | Hoy esos cambios solo existen en disco | Yo, cuando me lo autorices | H-02 |
| 3 | Crear un repositorio **privado** en GitHub y subir todo el historial | Si falla el disco o la sincronización de OneDrive, se pierde todo el historial (39 commits). OneDrive no sirve como respaldo de un repositorio git y puede dañar la carpeta `.git` | Tú creas el repositorio con tu cuenta, o me autorizas a crearlo. Yo preparo y ejecuto el resto | H-01 |
| 4 | Verificación automática en GitHub | Que las pruebas del motor y de la app corran solas cada vez que se sube código, sin depender de que alguien se acuerde | Yo, con tu visto bueno | H-01 |
| 5 | Fijar las versiones de las librerías de la app (versionar `app/pubspec.lock`) | Hoy dos compilaciones pueden usar versiones distintas de las librerías sin que nadie lo note | Yo, con tu visto bueno | H-69 |
| 6 | Respaldar la llave de firma de Android | Hoy la app no está publicada, así que perderla aún no sería grave. Se vuelve crítico en cuanto subas la primera versión. Si activas *Play App Signing* desde esa primera subida, una llave perdida se recupera con el soporte de Google, pero cuesta días de trámite. Sin eso, la app no se podría volver a actualizar | **Tú**: copia el archivo `.jks` a un USB o a una bóveda cifrada y la contraseña a un gestor de contraseñas. Después hay que sacar ambos archivos de OneDrive. Yo no leo ni copio esos archivos | H-05 |
| 7 | Que la compilación de publicación falle si falta la llave | Hoy, sin la llave (por ejemplo en otro PC), firma en silencio con la llave de pruebas, y ese archivo no sirve para la tienda | Yo, con tu visto bueno. Es un cambio pequeño de configuración, no del juego | H-05 |
| 8 | Que OneDrive deje de sincronizar las compilaciones | El proyecto acumula unos 1,4 GB de archivos generados, casi todos de compilación, y cada compilación reescribe miles de ellos. Eso vuelve todo lento, bloquea archivos y pone en riesgo el `.git`. Hay dos opciones. **Rápida**: marcar esas carpetas como "no sincronizar". **De fondo**: mover el proyecto a una carpeta local, por ejemplo `C:\dev\enigmatrix`, una vez esté en GitHub | Tú eliges la opción; yo la preparo | H-03 |

**Limpieza de prioridad baja.** Hay tres carpetas hermanas viejas con nombres parecidos a la de trabajo. CLAUDE.md ya avisa de ellas, pero conviene archivarlas sin borrar nada, junto con el material de direcciones abandonadas (H-21).

## 4. Propuesta de reestructuración del plan

El roadmap actual pone el servidor (Firebase) en la Fase 2 y deja el arte para la Fase 4 (H-23). Pero tu queja principal hoy es el arte, y no hay registro de que se haya medido si el juego engancha (H-22). Además, lo que el roadmap llama "MVP publicable" no incluye los trámites de las tiendas (H-24). Propongo este orden:

| Etapa | Qué incluye | Termina cuando | ¿Toca código? | Tiempo y costo (estimaciones sin verificar) |
|---|---|---|---|---|
| **0. Orden y protección** | La sección 3, los documentos al día (sección 6) y las decisiones del grupo "Antes de la prueba de juego" (sección 5) | El proyecto está en GitHub. Los documentos dicen la verdad o están marcados como "en revisión". Las decisiones de ese grupo están escritas | Solo configuración (firma y versiones de librerías) | Sin costo de dinero |
| **1. ¿Es divertido y justo?** | **Versión de prueba**: se arregla lo mínimo para que la medición no salga sucia. **Prueba de juego**: tú juegas 10 casos y 3 a 5 personas externas juegan los suyos. Se registran tiempo por caso, errores, dónde se atasca cada uno y si lo volvería a jugar mañana | Se cumplen los umbrales que fijemos antes de empezar. Por ejemplo: al menos 3 de 4 personas terminan el tercer caso Principiante sin que nadie les explique ni les dé pistas, y 3 de 4 lo volverían a jugar | Poco | Sin costo de dinero; requiere tu tiempo y el de las personas |
| **2. Prueba de concepto gráfica** | La del informe gráfico: opción A, en una carpeta aparte, con una copia fija del generador de hoy | Se cumplen los 7 criterios de la sección 9 del informe gráfico (fluidez, peso, arranque, toques sin bloqueo, opinión de 5 a 8 personas y tu veredicto). Si falla, se aplica el plan alterno de ese informe | Sí, aislado del juego actual | 1 a 2 semanas; 50 a 200 USD en herramientas, más un teléfono de prueba si no tienes |
| **3. Motor y contenido** | Ver detalle debajo de la tabla | `qa` verifica el Mundo 1 completo | Sí: el motor (`tools/`) y cambios pequeños en la app (cómo carga los casos y las claves del progreso) | Sin costo de dinero (trabajo de agentes) |
| **4. Producción visual** | **Solo si pasan la prueba de juego y la prueba de concepto.** Primero, pruebas automáticas de la partida y preparación del tablero (H-57, H-60). Después: el estilo en todas las pantallas, game feel, sonido, vibración, guardado completo de partida, accesibilidad y textos listos para traducir | El Mundo 1 completo con el estilo definitivo pasa la lista de verificación que fijemos al cerrar la etapa 2 | Sí | Según el informe gráfico: 12 a 16 semanas y 2.000 a 8.500 USD por mundo con la opción A |
| **5. Servidor (Firebase)** | **5A**: cuentas, validación de la solución en el servidor y casos sin la solución dentro. **5B**: ranking, reto diario real, vidas y compras. Antes de empezar se escribe un ADR (un registro corto de una decisión técnica, con opciones y motivo) sobre cómo validar en el servidor (H-41) | La validación en el servidor funciona | Sí | Sin estimar |
| **6. Tiendas** | Trámites legales; en Google Play, la prueba cerrada con probadores; iPhone solo si decides que entra al lanzamiento | Publicación | Poco | Cuentas: unos 25 USD únicos en Google Play y unos 99 USD al año en Apple (conocimiento general, a confirmar) |

**Qué incluye la etapa 3:**
- Arreglar el error del generador y el control de dificultad. Los rangos definitivos se fijan con los datos de la prueba de juego.
- Una puerta automática de contenido.
- Un catálogo de casos con id único.
- Una prueba de generación en 12×12 y 16×16, con un prototipo en pantalla para ver si se pueden jugar.
- El Mundo 1 (La Mansión) con 10 casos y narrativa propia.
- 30 días de reto diario.

**Cómo encajan las etapas:**
- **Las etapas 1, 2 y 3 pueden avanzar al mismo tiempo con tres condiciones.**
  1. La prueba de juego usa una versión congelada de la app, con los 20 casos actuales.
  2. La prueba de concepto usa una copia fija del generador de hoy. Si después cambia el formato de los casos, se adapta.
  3. Tú eres el cuello de botella: jugar, reclutar personas, aprobar arte y contratar planes necesita tu tiempo. Conviene escalonar el arranque, por ejemplo empezar con la prueba de juego y sumar la prueba de concepto unos días después.
- **Qué se arregla en la versión de prueba de la etapa 1.** Son defectos que contaminarían la medición:
  - guardar la partida y pedir confirmación al salir (H-55);
  - poder leer la pista completa al tocarla (H-56);
  - ocultar o rotular los datos simulados (H-62);
  - ordenar los casos como números (H-50);
  - poner la versión de la app en el feedback (H-70).

  Lo que quede provisional, como el tutorial y el resaltado de errores, se avisa a los probadores.
- **La prueba de juego no cuesta dinero, pero sí tu tiempo**: necesitas de 3 a 5 personas con Android, porque el iPhone nunca se ha compilado. Sus datos sirven para calibrar los rangos de dificultad de la etapa 3.
- **Ninguna inversión grande en arte** (etapa 4, ilustrador o animador) arranca antes de tener los resultados de la prueba de juego. Si la prueba de juego falla, se corrige primero el juego (reglas y dificultad). Si falla la prueba de concepto, se aplica el plan alterno del informe gráfico.
- **Trámites que conviene empezar ya**, porque no dependen del código:
  - decidir si publicas como persona natural o como empresa (pregunta 17);
  - crear la cuenta de desarrollador de Google Play;
  - publicar la política de privacidad.

  Los 14 días de la prueba cerrada no se pueden acelerar. Por eso propongo lanzarla con una versión estable de la Fase 1, sin la tienda ni el ranking simulado, apenas termine la etapa 1.

## 5. Decisiones que necesito de ti

### Ahora, para arrancar (te las pregunto en el chat)

1. **Plan**: ¿apruebas este orden de etapas?
2. **Protección**:
   - (a) ¿creas tú el repositorio privado en GitHub o me autorizas a crearlo?
   - (b) ¿autorizas el commit del trabajo del 01-11-2026?
   - (c) para OneDrive, ¿mover el proyecto o solo dejar de sincronizar las compilaciones?
3. **Documentos**: ¿los pongo al día? Lo hace `revisor-docs` sin tocar código y yo reviso el resultado.
4. **Prueba de concepto gráfica** (1 a 2 semanas, 50 a 200 USD estimados): ¿la autorizas?
   - Para empezarla necesito las preguntas 1, 2, 3, 5, 7, 8 y 10 de la sección 10 del informe gráfico: meta visual, referencias, estilo papel, autorización, teléfonos, quién contrata los planes de pago y jugadores.
   - Las preguntas 4, 6, 9, 11, 12 y 13 pueden esperar al resultado.

### Antes de la prueba de juego (conviene responder pronto: cambian lo que se va a medir)

| # | Pregunta | Mi recomendación | Código |
|---|---|---|---|
| 5 | ¿Qué pasa al quedar con 0 vidas? Hoy no está definido | No se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio | H-26 |
| 9 | Al fallar en Resolver hoy se marcan exactamente las casillas erróneas, con solo 3 segundos de bloqueo. En tableros pequeños, adivinar cuesta poco y eso debilita el pilar 1 (falta comprobarlo simulando a un jugador que adivina) | Mostrar solo cuántas casillas no cuadran; el resaltado exacto queda solo en el tutorial. **Ojo**: esto cambia la animación de error del informe gráfico, que proponía hacer parpadear la pista en conflicto. Esa animación se quedaría solo en el tutorial | H-28 |
| 10 | Al salir de una partida (botón Atrás, una llamada) hoy se pierde todo | Guardar siempre el progreso. Para el reloj hay dos opciones: (A) pausarlo al salir y ocultar el tablero, más justo para el jugador pero con riesgo de trampas cuando haya ranking; (B) que siga corriendo, como dice el doc 03. Recomiendo A mientras no haya ranking real y revisar la regla antes de la Fase 2 | H-55, H-32 |
| 11 | Tutorial: hoy hay dos (un diálogo de 5 páginas y uno jugable de 7 pasos). Los dos se pueden omitir y el jugable usa el Caso 1. Los documentos piden un tutorial obligatorio | Un caso propio pequeño (4×4 o 5×5) que no cuente como Caso 1. Que enseñe también la X, las notas, la papelera y un Resolver fallido. Obligatorio la primera vez, con un botón Saltar visible | H-29 |
| 20 | Para confirmar una ficha hoy hay que mantenerla oprimida o arrastrarla. Puede parecer que la app no responde y no cumple la alternativa de accesibilidad del doc 11 | Agregar un aviso al tocar una casilla sin sospechoso elegido ("Elige primero a un sospechoso") y un modo alternativo de tocar dos veces. Se diseña en la prueba de concepto | H-25 |
| 21 | ¿Puedes conseguir 3 a 5 personas con Android para la prueba de juego? | Pueden ser las mismas 5 a 8 de la prueba de concepto | H-22 |

### Después de las pruebas

| # | Pregunta | Mi recomendación | Código |
|---|---|---|---|
| 12 | Ayudas y puntuación: hoy no existen en la app y la spec no define cómo se calculan | La prueba de juego se hace sin ayudas y se anota dónde se atasca cada persona. En la etapa 3, `puzzle-engineer` especifica las ayudas, porque podrían requerir cambios en el motor | H-30 |
| 13 | Experto (12×12) y Élite (16×16) nunca se han generado | Decidir si entran al lanzamiento después de la prueba de generación y de verlos en una pantalla de 6 pulgadas | H-39 |

### Cuando quieras (no bloquean nada ahora)

| # | Pregunta | Mi recomendación | Código |
|---|---|---|---|
| 6 | Premium: ¿vidas ilimitadas o tope de 5 con recarga instantánea? Los documentos dicen las dos cosas | Vidas ilimitadas. En la práctica es lo mismo y es más fácil de explicar | H-26 |
| 7 | Reto diario: ¿a qué hora cambia? Un documento dice "día local" y otro "hora del servidor" | Medianoche de Colombia, la misma para todos (en España cambia a las 6:00 en invierno y a las 7:00 en verano). Un solo caso por día en el mundo simplifica el ranking y evita trampas. Mientras no haya servidor, elegir el caso solo entre Casual e Intermedio y quitar o marcar DEMO las promesas "un intento" y "mismo caso para todos" | H-27 |
| 8 | La víctima: tres documentos dicen que no se ve, pero el juego la muestra con una ficha y una † | Confirmar que la víctima es un personaje con ficha normal marcada con †, sin cuerpo ni sangre, y corregir los documentos 13, 15 y 20 | H-35 |
| 14 | ¿Con cuánto contenido se lanza? | El Mundo 1 (La Mansión) con 10 casos, más 30 días de reto diario Casual e Intermedio, hasta decidir la pregunta 13. Esto responde también la pregunta 11 del informe gráfico | H-49 |
| 15 | ¿Inglés desde el lanzamiento? Hoy el motor escribe las pistas directamente en español | No en el lanzamiento, pero dejarlo preparado. **Hay que decidirlo antes de la etapa 3**: recomiendo guardar las pistas como datos (tipo de pista y personajes) y redactarlas aparte en cada idioma, para no rehacer el Mundo 1 cuando llegue el inglés | H-63 |
| 16 | Edad mínima: en un lado dice 12+ y en otro 13 | 13 años o más: así se evitan las reglas de las tiendas para apps infantiles (Familias y COPPA). Falta confirmar con un abogado qué exige la ley de Colombia y la de la Unión Europea. La clasificación final la calcula cada tienda con su cuestionario, y el tema del asesinato puede subirla | H-09 |
| 17 | ¿Publicas como persona natural o como empresa? | Según lo investigado, con compras dentro de la app las tiendas te tratan como comerciante y en la Unión Europea pueden mostrar tus datos de contacto en la ficha. Opciones: (A) persona natural con apartado postal u oficina alquilada (hay que verificar que las tiendas acepten esa dirección); (B) constituir una SAS. Esto afecta también a la regla de los probadores: las cuentas de organización podrían estar exentas. Confirmarlo con un abogado o contador antes de crear las cuentas | H-08, H-06, H-24 |
| 18 | ¿Qué se ve en la versión que va a revisión de las tiendas? | Ocultar Tienda, Premium, el ranking simulado y los ajustes que no hacen nada | H-62 |
| 19 | El arma homicida aparece solo en el 10 % de los casos y nunca por encima de Casual | Usarla más en el Mundo 1, desde Intermedio | H-52 |
| 22 | ¿El iPhone entra al lanzamiento? (El 12-07-2026 confirmaste que tienes acceso a un Mac.) | Primero Android, como dice CLAUDE.md; el iPhone después | H-10, H-24 |

## 6. Documentos y reglas para poner al día

No toca código. Lo haría el agente `revisor-docs` (Sonnet) y yo reviso el resultado antes de dártelo.

- **CLAUDE.md** (H-14):
  - quitar Claude Design;
  - corregir el stack: `shared_preferences` y no Hive o Isar; el tablero es una cuadrícula de widgets y los muebles se dibujan con `CustomPainter`;
  - agregar la sección "Excepciones vigentes de la Fase 1": solución local, pantallas DEMO, sin servidor;
  - completar la tabla de documentos con los 18 a 20.
- **Roadmap** (H-15): el estado real y el plan de etapas que apruebes.
- **active.md** (H-16): un "Estado hoy" de unas 10 líneas y el historial en un archivo aparte, sin perder nada.
- **Índice de documentos** `docs/README.md` (H-34): el estado de cada documento (vigente, parcialmente obsoleto, visión futura o superado).
- **ADR retroactivos** (H-17): entre 5 y 9 registros cortos de decisiones ya tomadas, por ejemplo mapas procedurales, estilo papel, datos simulados, aplazamiento de Firebase y el riesgo aceptado de la solución local, con su caducidad.
- **Documentos 05, 16, 01 y 03** (H-33): limpiar tamaños, pistas y mapas que ya no aplican. Lo superado se marca, no se borra.
- **Reglas de colocación en los documentos 02, 03, 06 y 11** (H-25): que apunten a la sección 4 de la spec 16, que es la vigente. Hay que documentar también la auto-X, el borrador y el significado de Mapa y Notas.
- **Documentos 15, 18, 19 y 20** (H-36): alinearlos con el código actual.
- **Agente `frontend`** (H-19):
  - quitar las referencias al Design System y a los mockups abandonados;
  - aclarar que los textos en `.arb` son una meta de la etapa 4.
- **Agentes `backend` y `seguridad`**: marcarlos como inactivos hasta la Fase 2.
- **Documentos que esperan un resultado**: se marcan "en revisión" y se reescriben cuando llegue ese resultado.
  - El 10 (arte) espera la etapa 2 (H-37).
  - El 05 y el 08 esperan las etapas 1 y 3 para recalibrar la dificultad.
- **Lo que depende de tus respuestas** (vidas, reto, víctima, errores) se corrige cuando decidas.

## 7. Código: qué hay que ordenar y cuándo

Nada de esto se toca hasta que lo autorices.

| Problema, en palabras simples | Cuándo | Código |
|---|---|---|
| Salir de la partida (botón Atrás, una llamada) borra el progreso, y después de cada caso se vuelve a pasar por la pantalla de carga | Arreglo mínimo (guardar y pedir confirmación al salir) en la versión de prueba de la etapa 1. El resto en la etapa 4 | H-55 |
| Accesibilidad casi nula: sin soporte para lectores de pantalla, errores marcados solo por color y pistas que se cortan a 11,5 px | Arreglo mínimo (ver la pista completa al tocarla) en la etapa 1. El resto, con el diseño nuevo, en la etapa 4 | H-56 |
| Restos del banco de pruebas visibles (por ejemplo, el botón "Copiar feedback de playtest") y versión de la app siempre en 1 | Etapa 1, para que el feedback diga de qué versión viene. Los restos se quitan antes de ir a la tienda | H-66, H-70 |
| La partida no tiene pruebas automáticas, y es lo que más se va a cambiar | **Primer paso de la etapa 4**, antes de tocar la partida. La prueba de concepto no lo necesita porque va aparte | H-57 |
| El tablero mezcla geometría, gestos y colores dentro de cada casilla, y la validación de la solución asume que todo es local | Etapa 4, antes de rediseñar: separar la geometría del tablero, la entrada de toques y la validación. La prueba de concepto solo mide si la fluidez es posible | H-60 |
| El tablero entero se redibuja cada segundo por el cronómetro | Tiene un arreglo independiente y barato: sacar el reloj a su propio estado. Si se aprueba la opción A, el tablero nuevo de la etapa 4 lo evita desde el diseño. El impacto en 12×12 y 16×16 se espera, pero no está medido | H-58 |
| Conviven dos sistemas de colores y estilos; la partida sigue en el viejo | Uno solo, en la etapa 4 | H-59 |
| Los botones más usados (X, Borrador, Deshacer) van después del tablero, las pistas y la papelera, y probablemente quedan fuera de la pantalla en un teléfono (estimado por el diseño, falta medirlo) | En el diseño de la prueba de concepto | H-67 |
| Un solo archivo de caso dañado bloquea la carga de todos | Etapa 3, junto con la puerta de contenido | H-64, H-68 |
| Valores de juego escritos en el código y archivos muy grandes | Etapa 4 | H-61, H-65 |
| Más de 130 textos fijos en pantalla (unas 300 frases contando todos los textos), sin preparar para traducción | Etapa 4 | H-63 |

## 8. Motor y contenido

Corresponde a la etapa 3. Lo hacen `puzzle-engineer` (motor) y `contenido-puzzles` (casos); los cambios en la app los hace `frontend`; `qa` verifica.

- **La dificultad no se controla** (H-40):
  - el generador no impone rangos: hay un caso Principiante que el solver resuelve en 10 pasos y uno Intermedio en 4;
  - un paso es un movimiento lógico del solver: sirve como medida aproximada, no como tiempo de una persona;
  - además tiene un error: cuando necesita reforzar una pista, salta directamente a la más fuerte en vez de a la siguiente, y eso aplana la dificultad.
- **No hay una puerta automática de contenido** (H-68): nadie comprueba que los 20 casos incluidos en la app sigan teniendo solución única.
- **Orden de los casos** (H-50): se ordenan como palabras y no como números, así que el caso s20 aparece antes que el s3. Está en la app, así que lo arregla `frontend`.
- **Experto y Élite nunca se han generado** (H-39): no se sabe cuánto tarda el generador con 12×12 y 16×16 ni si esos tableros caben en la pantalla.
- **No hay catálogo de casos** (H-43): el id no es único entre la campaña y el reto diario, y no hay manera de manejar los más de 400 casos que pide el plan.
- **Narrativa pobre** (H-44): siempre el mismo elenco, casos sin título ni premisa, y mapas que no corresponden a "La Mansión".
- **Otros de gravedad media:**
  - la spec promete un límite de tiempo del solver y un detector de pistas redundantes que no existen, y sin ese límite un caso difícil puede colgar la generación (H-42);
  - los tests del motor cubren casi solo el camino feliz, y el validador, que será la puerta del servidor, no se prueba con datos maliciosos (H-45);
  - las hojas imprimibles de la Fase 0 usan los mismos ids que otros casos (H-51).

## 9. Tiendas, privacidad y legal

- **Llave de firma**: ver la sección 3 (H-05).
- **Política de privacidad** (H-06):
  - hay que publicarla en una dirección web pública y completar el responsable y el correo;
  - Apple exige que el enlace también esté dentro de la app, así que hay que agregar un botón en Configuración;
  - si se publica con GitHub Pages, en el plan gratuito tiene que ser desde un repositorio público aparte que solo contenga la política (verificar en GitHub). La alternativa es un alojamiento gratuito sencillo.
- **Fuentes de texto** (H-07):
  - la primera vez que se abre, la app descarga las tipografías de Google. La política lo menciona y dice que no se envían datos personales, pero eso es discutible: Google recibe la dirección IP, y un tribunal alemán la trató como dato personal;
  - si esa primera apertura es sin conexión, la app sale con otra tipografía;
  - hay que incluir las fuentes dentro de la app y reemplazar la fuente "Segoe Script", que no existe en Android ni en iPhone.
- **Identidad legal y edad mínima** (H-08, H-09): ver la sección 5.
- **iPhone** (H-10): la app nunca se ha compilado para iPhone y falta enlazar su manifiesto de privacidad.
- **Requisitos de Apple para la Fase 2** (H-12):
  - si hay inicio de sesión con Google, es probable que Apple exija también "Iniciar sesión con Apple" u otra opción equivalente (guía 4.8, a confirmar antes de la Fase 2);
  - el borrado de cuenta ya está previsto en el doc 15, pero falta revocar el permiso de Apple al borrar la cuenta.
- **Probadores** (H-24):
  - según lo investigado, las cuentas personales nuevas de Google Play deben tener al menos 12 probadores durante 14 días seguidos antes de publicar;
  - las cuentas de organización podrían estar exentas;
  - Google cambia estas reglas, así que hay que confirmarlas en Play Console antes de planificar.

## 10. Sistema de agentes (ya aplicado el 01-11-2026)

- **Ya está hecho:**
  - cada agente declara su modelo: Sonnet, o Haiku para lo mecánico;
  - `.claude/settings.json` fija Sonnet como modelo para cualquier agente que no declare uno;
  - los agentes de BBVA quedaron ocultos en este proyecto;
  - el agente "arquitecto" se eliminó, porque ese papel lo cumple la sesión principal;
  - se crearon `revisor-docs`, `ejecutor-pruebas` y `contenido-puzzles`.
- **Dos hallazgos descartados por el verificador.** Su evidencia era falsa: no había choque de nombres con el arquitecto global y los agentes ya declaraban su modelo.
- **Duda que dejó el verificador.** No está confirmado si la variable `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` cambia a Sonnet el agente `ejecutor-pruebas`, que declara Haiku. Según la documentación oficial que revisamos el 01-11-2026, el modelo declarado en el agente tiene prioridad sobre esa variable, así que debería seguir en Haiku. Lo confirmo en su primera ejecución.
- **Pendiente:**
  - el commit (H-02);
  - abrir Claude Code en la carpeta del proyecto (H-13);
  - actualizar `frontend` y marcar `backend` y `seguridad` como inactivos (H-19, sección 6);
  - crear un agente de arte técnico y game feel (H-19) y otro de audio después de la decisión gráfica.
- **Memoria** (H-20): está duplicada en dos carpetas y una de las copias tiene datos viejos. La consolido cuando definamos la ruta final del proyecto.

## 11. Próximos pasos

1. Respondes las 4 decisiones de "Ahora" (te las pregunto en el chat).
2. Si apruebas, hago la protección de la sección 3, cada paso con tu visto bueno donde corresponda.
3. `revisor-docs` pone al día los documentos y te muestro qué cambió.
4. Con tus respuestas a las preguntas 5, 9, 10, 11, 20 y 21, preparo la versión de prueba y una guía de una página con una hoja para anotar resultados.
5. Si la autorizas, arranca la prueba de concepto gráfica, escalonada respecto a la prueba de juego. En paralelo, otros agentes avanzan el motor (etapa 3).

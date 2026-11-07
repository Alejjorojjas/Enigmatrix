# ADR-0016: Validación en el servidor y partida sin conexión

- **Estado**: Propuesto. El punto 1 lo decidió Alejandro el 07-11-2026; el resto espera su aceptación.
- **Fecha**: 07-11-2026
- **Decisores**: usuario (Alejandro) / arquitecto

## Contexto

- **Qué cambia en la etapa 5.** El servidor pasa a ser la autoridad (principios 1, 2 y 6 de CLAUDE.md) y caduca el riesgo aceptado del ADR-0008: hoy la solución viaja dentro del JSON del caso.
- **Requisito previo.** El ADR-0010 y la auditoría (H-41) piden decidir cómo se valida antes de escribir el servidor.
- **El problema de la señal.** El pilar 3 ("cabe en un trayecto") obliga a que se pueda jugar en un bus o en el metro sin señal. Pero si la solución no está en el teléfono, el teléfono no puede saber si el tablero está bien.
- **Plan de referencia:** `production/planes/2026-11-06-etapas-5-y-6.md`.

## Decisión

1. **Sin conexión se juega, pero Resolver espera la señal** (decisión de Alejandro del 07-11-2026).
   - El tablero, las notas y el reloj funcionan sin internet.
   - Si al pulsar Resolver no hay conexión, el tablero queda guardado como "por validar".
   - En cuanto vuelve la señal, la app lo envía y muestra el resultado: victoria, o cuántas casillas no cuadran (ADR-0012, decisión 9).
   - Mientras no llegue la respuesta, el jugador puede seguir con otro caso de la campaña ya descargado.
2. **La solución solo vive en el servidor.**
   - Cada caso se guarda en dos partes: el caso público (mapa, personajes y pistas) y su solución, en una colección de Firestore que las reglas no dejan leer a ningún cliente.
   - Los JSON incluidos en la app dejan de llevar la solución.
3. **La validación la hace una Cloud Function** (`submitSolution`).
   - Recibe el tablero y compara.
   - Con la hora del servidor, registra el resultado, los puntos, el error, la vida gastada y la racha.
   - La respuesta nunca incluye la solución ni qué casillas fallan, solo cuántas.
4. **Descarga anticipada.**
   - La primera vez que hay conexión, la app descarga los 10 casos del Mundo 1 sin solución.
   - El reto del día se descarga al abrir la app con conexión.
5. **Tiempo oficial y ranking** (propuesta del arquitecto, la confirma Alejandro):
   - Una partida cuenta para el ranking solo si se empezó con conexión, porque el servidor anota la hora de inicio.
   - Las partidas jugadas sin conexión de principio a fin cuentan para el progreso y la campaña, pero no para el ranking de tiempo.
   - El **reto diario** exige conexión para empezar, porque fija la fecha local y la hora de inicio (pregunta 7). Si la señal se cae a mitad de la partida, se puede terminar y Resolver espera.
6. **Vidas sin conexión.** Un Resolver fallido descuenta la vida cuando el servidor lo valida, no antes. Con 0 vidas confirmadas por el servidor se aplica la decisión 5 del ADR-0012.
7. **Anti-trampa.** App Check con Play Integrity en todas las funciones. Se limita la cantidad de intentos de Resolver por caso y por minuto (valor en Remote Config), para que nadie pruebe tableros al azar con un programa.

## Alternativas consideradas

- **(B) Validar la campaña en el teléfono y solo lo oficial en el servidor.** Se juega sin señal sin esperar, pero la solución de la campaña sigue en el teléfono, se puede extraer y los puntos de la campaña no serían limpios (pilar 2). Alejandro eligió la A.
- **(C) Exigir siempre conexión.** Es lo más simple, pero rompe el pilar 3.
- **Hash de la solución dentro del caso.** En tableros de 6×6 a 9×9 las combinaciones posibles se pueden probar todas con un programa, así que el hash revela la solución.
- **Solución cifrada dentro de la app.** La llave tiene que estar en la app, así que se puede extraer.

## Consecuencias

- **Para el jugador.** Sin señal, el jugador no sabe de inmediato si ganó. La app tiene que explicarlo bien con un mensaje claro ("Lo validamos cuando tengas señal") y una marca de "por validar" en la lista de casos.
- **Cambios en la app:**
  - una cola local de envíos pendientes;
  - la caché de casos sin solución;
  - quitar `solution` de los assets;
  - una prueba automática que falle si la palabra `solution` aparece en un asset o en una respuesta del servidor.
- **Cambios en las herramientas.** `tools/` tiene que publicar cada caso en dos partes: la pública y la solución. La puerta de contenido se mantiene.
- **Lo que queda abierto.** El tutorial y el banco de pruebas (solo con `ENX_DEV`) pueden seguir validando en el teléfono, porque no dan puntos ni ranking. Se confirma al implementar.
- **Excepciones que caducan.** Con este ADR aceptado y la etapa 5A terminada caducan el ADR-0008 y la excepción del principio 2 en CLAUDE.md.

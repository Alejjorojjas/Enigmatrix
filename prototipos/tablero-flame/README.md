# Tablero Flame: prueba técnica de la etapa 2

Prototipo aislado. **No es la app** y no toca `app/` ni `tools/`. Sirve para
medir, en un Android de gama media, si un tablero con "game feel" de juego
profesional corre fluido, y para **comparar en el teléfono dos direcciones
de arte** (Ilustrada y Papel) en modo claro y oscuro. El arte es provisional,
gratuito y hecho por código (formas, degradados y texturas procedurales): no
trae imágenes ni sonidos descargados. La dirección sale de las cualidades que
Alejandro eligió el 05-11-2026 (ver `docs/referencias-visuales/README.md`);
no copia dibujos, retratos, nombres ni íconos de ningún juego.

Se instala junto a la app porque tiene otro identificador:
`com.enigmatrix.prototipo` (la app usa `com.enigmatrix.app`).

## Qué trae

- El tablero es **una sola escena de Flame**, sin widgets por casilla, con tres
  capas: fondo fijo (piso y paredes por habitación con sombra, muebles
  colocados según el mapa del caso), fichas (capa interactiva) y efectos.
  Viñeta de luz y sombras proyectadas.
- Dos casos reales copiados de la app: uno 6×6 Principiante y otro 8×8 Casual.
  Las reglas de colocación son una copia fija de `board_state.dart` y la
  validación sale del motor (`enigmatrix_engine`, `Validator`).
- **Toque** = anotar candidato. **Mantener oprimido** (0,38 s, con un anillo que
  se llena) = confirmar. Botón **Resolver**.
- Modo alternativo de tocar dos veces (regla 20 del ADR-0012): tocar de nuevo la
  misma casilla con el mismo sospechoso la confirma. Se apaga en Opciones. Si
  no hay sospechoso elegido, sale "Elige primero a un sospechoso".
- **Director de feedback**: una sola clase recibe los eventos y en el mismo
  cuadro lanza animación, sonido y vibración. Ninguna animación bloquea el
  siguiente toque. Momentos: tocar sospechoso, anotar, confirmar (aplastamiento
  y estiramiento, onda, 6 a 8 partículas, destello de 1 cuadro, golpe de
  cámara), tachar fila y columna en ola, error (sacudida amortiguada y "N
  casillas no cuadran") y resolver y revelar (viñeta, ola fila por fila,
  inocentes en cascada, zoom al asesino, estrellas; se puede saltar tras 1 s).
- **Reposo vivo**: las fichas respiran (escala 1,00 a 1,02 cada 3 s) y parpadean
  cada 4 a 7 s.
- **12 sonidos propios** sintetizados por `tool/generar_sonidos.py` (sin audio de
  internet). Licencia en `assets/sonidos/LICENCIA.txt`.
- **Opciones** (icono de sliders arriba a la izquierda): piel y modo, sonido,
  vibración, reducir movimiento (cambia sacudidas y destellos por fundidos;
  arranca activo si el teléfono pide menos animaciones), tope de partículas
  (0, 20, 40, 80), **medidor de FPS (apagado por defecto)**, doble toque,
  tachado automático. Toda la letra de la interfaz es de 13 px o más.
- **Medidor de FPS**: de depuración, apagado al arrancar. Se enciende en
  Opciones y entonces sale en la barra superior, debajo del cronómetro y fuera
  del tablero (nunca encima), con letra pequeña. Al terminar la secuencia de
  resolver sale un aviso "Resolver: mín X · prom Y" con el botón Copiar (el
  resultado completo queda siempre en Opciones).
- **Pieles**: la interfaz `BoardSkin` (colores, texturas y formas) separa el
  arte de la escena. Hay tres y se cambian en vivo (ver abajo): Ilustrada,
  Papel y Neutra. Todas usan los mismos datos y la misma interacción.
- **Herramientas** (barra bajo el tablero, de unos 56 px de alto): **Anotar**
  (toque = anotar candidato, mantener oprimido = confirmar, como siempre),
  **Tachar** (toque = X a mano; otro toque la quita), **Confirmar** (un toque
  confirma al sospechoso elegido) y **Borrar** (borrador). Elegir un retrato
  desde Tachar o Borrar vuelve a Anotar. (Antes se llamaban Notas / Colocar; el
  comportamiento es el mismo.)
- **Pista**: al elegir un retrato, el recuadro muestra la pista de ese
  personaje (la misma que el caso trae para él). Crece según el texto, hasta 3
  líneas; en pantallas bajas queda en una línea que se expande al tocarla.

## Distribución de la pantalla

El tablero ocupa **todo el ancho disponible menos 12 px a cada lado**: 336 px en
un teléfono de 360 px, tanto en el 6x6 (casilla de **56 px**) como en el 8x8
(casilla de **42 px**). Nada se desplaza. Las medidas viven en
`lib/src/ui/layout_metrics.dart` (`ScreenMetrics`) y se prueban solas.

De arriba abajo: encabezado en dos filas (opciones, cronómetro, deshacer, piel y
modo; luego el nombre del caso con su subtítulo y el selector 6x6 / 8x8), el
escenario del tablero de borde a borde (la mesa se ve en los márgenes), la
barra de herramientas, la fila de retratos de 54 px (retrato de unos 50 px, nombre a 13 px;
si caben todos se reparten el ancho, si no se deslizan), la pista y Resolver.

- **Distribución normal** (700 px de alto o más, p. ej. 360x740): la pista en su
  recuadro (crece hasta 3 líneas) y Resolver en su propia fila, pegado abajo. Lo
  que sobra de alto se usa para mostrar más mesa alrededor del tablero.
- **Distribución compacta** (pantallas más bajas, p. ej. 360x640): se prioriza el
  tablero. La pista queda en **una sola línea con Resolver al lado**; al tocarla
  se expande en una tarjeta que **flota** sobre los retratos (no empuja nada ni
  mueve el tablero) y se pliega al volver a tocarla o al elegir otro personaje.
- Letra: toda la interfaz va a 13 px o más (subtítulo del caso, nombres de los
  retratos, pista y su rótulo, textos de Opciones). Solo el medidor de FPS usa
  letra más chica.
- Los **rótulos de habitación** miden 11 px o más (hasta 14 px si la casilla es
  grande) y se colocan en las casillas libres (sin mueble) de su propia
  habitación, en un tramo horizontal que alcance para el nombre. Si no cabe, se
  abrevia ("Terra."). Por construcción no se montan entre sí ni salen del
  tablero (`lib/src/scene/room_labels.dart`, lo usan las tres pieles).

## Pieles y modos

Se cambian en **Opciones** (ícono de sliders arriba a la izquierda): selector
de **Piel** (Ilustrada / Papel / Neutra) y de **Modo** (Sistema / Claro /
Oscuro). Arriba a la derecha hay dos atajos para comparar sin abrir el menú: el
ícono de paleta pasa a la siguiente piel y el de sol/luna alterna claro y
oscuro. El cambio es inmediato y no pierde la partida.

- **Modo "Sistema"** (el de arranque): usa el claro o el oscuro del teléfono
  (`ThemeMode.system`). Los otros dos lo fuerzan.
- **Claro**: cálido y menos blanco que un blanco de pantalla (papel crema y
  madera). **Oscuro**: cálido y profundo, sin llegar al negro (marrón tostado);
  los pisos y muebles se atenúan.
- Todos los colores (interfaz y tablero) salen de la paleta de la piel en ese
  modo (`SkinPalette`, `lib/src/scene/palette.dart`); ningún widget lleva
  colores sueltos.

### Ilustrada (arranque)

Inspirada en las cualidades de la referencia: muebles vistos desde arriba con
**contorno oscuro**, color base, luz arriba a la izquierda, sombreado y sombra
proyectada; **un piso distinto por habitación** (tablones de madera, losas de
piedra, baldosa y alfombra tejida; el tipo sale del nombre de la habitación o
de su índice); **paredes gruesas y oscuras** entre habitaciones con el nombre en
una pastilla; y **retratos provisionales** (cara, peinado y ropa distintos por
personaje) dentro de un marco redondeado de color, con borde de acento en el
seleccionado. Interfaz: botones grandes redondeados con ícono y texto, el
activo relleno; cronómetro en una pastilla oscura; fila de retratos deslizable;
recuadro amplio para la pista; botón Resolver.

### Papel

Papel recortado tipo maqueta. Se tiene que ver que es papel, y no se parece a
la Ilustrada ni en el piso ni en los bordes:

- **Pisos de cartulina de colores** (mostaza, menta, coral, azul cielo, lila,
  rosa...) con un **estampado simple de papel de regalo**: rayas, lunares,
  cuadros de mantel o zigzag. Nada de madera ni piedra realistas
  (`lib/src/scene/paper_floors.dart`).
- **Bordes de habitación irregulares, como rasgados**: cada habitación es una
  pieza con el contorno de sus casillas y un temblor irregular (siempre el mismo
  para una misma semilla), con un **borde blanco de papel** que asoma de forma
  desigual (`lib/src/scene/paper_edges.dart`).
- **Grosor visible**: de 2 a 3 px más oscuros debajo de cada pieza (habitaciones,
  muebles, fichas y retratos). Las de abajo se dibujan primero, así el grosor de
  una pieza cae sobre la que tiene debajo.
- **Muebles y fichas son recortes**: cada uno lleva un **giro pequeño al azar
  de hasta 1,5 grados** (fijo por mueble o personaje) y un **borde blanco de
  recorte** de unos 2 px.
- **Fibra de papel mucho más marcada**: fibras largas claras y oscuras y motitas
  de grano sobre los pisos, los muebles, la mesa y la interfaz.
- **Mesa de kraft** alrededor del tablero: marrón de papel de embalaje con
  fibras visibles, luz cálida y viñeta; el tablero descansa en una lámina de
  cartón. En modo oscuro la mesa es un kraft tostado.

Los botones y paneles de la interfaz también son recortes (capa inferior más
oscura, borde blanco y fibra).

### Neutra

La prueba técnica original (fichas de colores, formas sobrias), ahora con
paleta clara y oscura y la interfaz nueva.

Los 14 tipos de mueble tienen dibujo en Ilustrada y Papel (mesa, silla, sofá,
sillón, cama, alfombra, planta, arbusto, TV, armario, caja, lavadora, piano y
barra). La **silla** vista desde arriba se lee como silla: respaldo oscuro con
sus montantes (lo más ancho y alto), asiento de madera con un cojín crema y las
patas que asoman; es chica y deja ver el piso. No se confunde con el **sillón**
(morado, redondo y gordo, con brazos abultados, botones y un cojincito mostaza
en diagonal) ni con el **sofá** (verde azulado, largo, con dos cojines). Parten de los tamaños y la lógica de
`app/lib/src/ui/furniture_painters.dart`, con otro acabado. Los dibujos son
listas de piezas (`art_parts.dart`, `furniture_art.dart`, `portrait_art.dart`)
que cada piel pinta a su manera, así que un mueble nuevo se escribe una vez.

## Cómo se instala

1. Compilar (necesita Flutter y JDK 17; en este PC hay que apuntar `JAVA_HOME`
   al JDK 17 porque el que viene por defecto es el 11):

   ```
   cd prototipos/tablero-flame
   JAVA_HOME="C:/Program Files/Java/jdk-17" flutter build apk --release
   ```

   El APK queda en `build/app/outputs/flutter-apk/app-release.apk` (trae las
   librerías de audio para 3 arquitecturas, unos 58 MB). Está firmado con la
   clave de pruebas (sirve para el prototipo, no para publicar). Para el peso
   real en un teléfono moderno:

   ```
   JAVA_HOME="C:/Program Files/Java/jdk-17" flutter build apk --release --split-per-abi
   ```

   genera `app-arm64-v8a-release.apk` (**19,9 MB**, el de casi todos los
   Android de gama media actuales), `app-armeabi-v7a-release.apk` (16,5 MB) y
   `app-x86_64-release.apk` (21,5 MB), todos en esa misma carpeta. Con
   `--split-per-abi` no se genera `app-release.apk`: si aparece uno, es una
   compilación vieja y no hay que instalarlo.
2. Pasarlo al teléfono (cable con depuración USB:
   `adb install -r app-arm64-v8a-release.apk`,
   o copiar el archivo y abrirlo; Android pide permitir "instalar apps
   desconocidas").
3. Abrir **Enigmatrix prototipo**.

Los sonidos ya vienen generados en `assets/sonidos/`. Para regenerarlos:
`python tool/generar_sonidos.py` (usa solo la librería estándar de Python).

## Qué medir

Con el medidor de FPS encendido (Opciones; sale bajo el cronómetro):

1. **Fluidez al confirmar.** Confirma varias fichas seguidas (mantén oprimido).
   Mira que el medidor se mantenga cerca de 55 fps o más. Meta del informe
   gráfico: 55 fps o más sostenidos en gama media, 30 o más en gama baja con
   efectos reducidos (activa "Reducir movimiento" y baja el tope de partículas).
2. **Fluidez al resolver.** La secuencia de resolver se mide sola: al terminar
   aparece "Resolver: mín X · prom Y" y se copia con el botón de copiar. Para no
   tener que deducir el caso cada vez: Opciones, "Llenar el tablero (solo para
   medir)", y luego Resolver. Repite en el 6×6 y en el 8×8, y con distintos topes
   de partículas.
   - *Promedio*: cuadros divididos por la duración.
   - *Mínimo*: el peor tramo de 0,5 s.
   - *Peor cuadro* y *cuadros lentos* (más de 20 ms): van en el texto copiado.
3. **Toques sin bloqueo.** Toca rápido, incluso mientras corre la ola de X o la
   secuencia de resolver: el siguiente toque debe responder siempre.
4. **Sensación.** Sonido y vibración sincronizados con la animación; la
   sacudida de error no marea; "Reducir movimiento" se siente bien sin
   sacudidas.
5. **Peso del APK** y **arranque en frío** (cronométralo a mano, meta menos de 3 s).

### Qué comparar entre pieles y modos

Con la misma partida (cambia de piel y de modo con los atajos de arriba):

1. **Ilustrada vs Papel**: ¿cuál se lee mejor de un vistazo (muebles, habitaciones,
   quién es quién)? ¿cuál se siente más como un juego y menos como un formulario?
2. **Legibilidad en el caso 8×8**: nombres de habitación, notas pequeñas y
   retratos de las fichas con el dedo encima. Fíjate sobre todo en la
   Neutra vs las otras dos.
3. **Claro vs oscuro** en cada piel, en la calle y en un cuarto oscuro: ¿el claro
   cansa por demasiado blanco? ¿el oscuro es demasiado oscuro o frío?
4. **Retratos**: ¿se reconoce a cada personaje en la fila y en el tablero?
   ¿la víctima (cruces en los ojos, tono pálido) se distingue sin leer?
5. **Muebles**: ¿se reconocen al instante? Hay un caso 6×6 y otro 8×8 con
   sillas, sofás, mesas, alfombras, plantas, TV y armarios; los demás tipos
   (cama, sillón, caja, lavadora, piano, barra, arbusto) no aparecen en los casos
   actuales pero están dibujados.
6. **Fluidez**: las pieles nuevas dibujan más. Mira el medidor de FPS con cada
   una (meta: 55 fps o más) y compara con la Neutra.
7. **Barra de herramientas**: ¿se entiende Anotar / Tachar / Confirmar / Borrar?
   ¿el botón activo se nota sin mirar el color?
8. **Tablero a todo el ancho**: en el 8x8, ¿se puede tocar cada casilla (42 px)
   sin errar? ¿se leen los nombres de las habitaciones sin que se monten?
9. **Papel vs Ilustrada**: ¿alguien que las vea dice sin dudar "esta es de
   papel"?

Anota el modelo del teléfono, la versión de Android y los números. El APK no
guarda nada: las opciones (incluida la piel y el modo) vuelven a sus valores al
reiniciar.

## Capturas en el navegador

Para que el arquitecto pueda tomar capturas sin teléfono, el prototipo también
compila para web (el audio se desactiva en el navegador y Opciones lo avisa;
en Android sigue sonando):

```
cd prototipos/tablero-flame
flutter build web --release
dart pub global activate dhttpd      # una sola vez
dart pub global run dhttpd --path build/web --port 8131
```

y se abre `http://localhost:8131/`. Para ver el tamaño de un teléfono, ventana
del navegador de 360 x 740 (distribución normal) o 360 x 640 (compacta). Si el navegador está oculto, Flutter dibuja a
muy pocos cuadros por segundo: hay que traer la pestaña al frente antes de
capturar y esperar uno o dos segundos tras cada toque.

## Pruebas automáticas

```
cd prototipos/tablero-flame
flutter analyze
flutter test
```

Cubren: qué efectos dispara cada evento del director y su versión reducida
(incluido tachar a mano), el tope de partículas, los límites de destellos y de
vibración de lápiz, los gestos (toque y mantener oprimido), el reloj de la
secuencia de revelar, el medidor de FPS, la geometría del tablero, las reglas de
la partida con los dos casos reales y las herramientas (Notas, Tachar, Colocar,
Borrar); que cada piel entrega las paletas de los dos modos (claro no blanco,
oscuro no negro, contraste del texto); que los 14 muebles se dibujan en las dos
pieles nuevas, en horizontal y vertical y en los dos modos; los retratos y los
pisos por habitación; que el selector de Opciones cambia la piel y el modo; y,
nuevas en esta ronda:

- **Pantalla completa a 360x740 y 360x640** (`test/screen_layout_test.dart`): el
  tablero mide 336 px con 12 px a cada lado, la casilla es de 56 px (6x6) o 42 px
  (8x8), no hay desbordes ni listas verticales, la barra de herramientas mide
  unos 56 px, la pista compacta se expande sin mover nada, el medidor de FPS
  arranca apagado y, encendido, queda fuera del tablero, y toda la letra (también
  la de Opciones) es de 13 px o más.
- **Rótulos de habitación** (`test/paper_and_labels_test.dart`): 11 px o más,
  dentro de su habitación, sin tapar muebles, sin montarse y abreviados si no
  caben.
- **Papel**: contornos de las habitaciones y bordes rasgados, estampados y
  colores de cartulina, grosor de 2 a 3 px, borde blanco, giros de hasta 1,5
  grados, y que el mismo tablero se vea muy distinto en Papel y en Ilustrada.
- **Muebles**: la silla tiene respaldo, asiento, cojín y patas, y se distingue
  del sillón y del sofá.

Las pruebas de pantalla cargan la letra Roboto del SDK de Flutter (en pruebas
Flutter usa una letra de cuadrados más ancha que la real).

## Notas técnicas

- `lib/board_state.dart` es una **copia fija** de `app/lib/src/game/board_state.dart`:
  si las reglas cambian en la app, hay que volver a copiarla.
- El caso trae la solución en el JSON (excepción vigente de la Fase 1). El
  prototipo la usa solo para contar "N casillas no cuadran" y para la
  herramienta de medición "Llenar el tablero"; no la muestra.
- Vibración: `HapticFeedback` de Flutter (alternativa simple). No usa
  primitivas de Android; los pulsos múltiples los arma el director con
  separación mínima de 50 ms.
- Audio: `flutter_soloud` (baja latencia). Si no arranca, el prototipo sigue en
  silencio y lo dice en Opciones. En web no se inicia (`kIsWeb`).
- Piel y modo viven en `GameSettings` (`skinId`, `themeMode`); `main.dart` arma
  `theme`/`darkTheme` con `Ui.theme(piel, modo)` y la pantalla reconstruye la
  piel de la escena (`BoardGame.setSkin`) cuando el tema cambia.
- Archivos nuevos de esta ronda: `lib/src/ui/layout_metrics.dart` (medidas de la
  pantalla), `lib/src/scene/room_labels.dart` (rótulos de habitación),
  `lib/src/scene/paper_edges.dart` y `lib/src/scene/paper_floors.dart` (piel
  Papel). El tablero se acomoda con `BoardGeometry.fit(..., margin: 12,
  marginY: 2)`.
- `web/` lo creó `flutter create --platforms=web`; no se usa fuera de las
  capturas.

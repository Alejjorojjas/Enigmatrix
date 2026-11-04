# Enigmatrix - Guía de pruebas (Fase 1)

> ACTUALIZACIÓN 04-11-2026 (auditoría 04-11-2026, H-36): la sección "Qué NO está todavía" estaba desfasada y se corrigió con una nota. Además, la **prueba de juego con personas** (etapa 1 del plan aprobado el 04-11-2026) todavía no se ha hecho: las rondas de feedback documentadas hasta hoy fueron sobre la apariencia, no sobre si el juego es divertido y justo (H-22). **DECIDIDO 04-11-2026** (auditoría, pregunta 21; ver ADR-0012): Alejandro puede conseguir de 3 a 5 personas para la prueba de juego. Su teléfono de prueba es un Android de gama media.

Cómo jugar la versión actual, en qué dispositivo, y cómo fluye una ronda de
correcciones. Publicar en Play Store / App Store es DESPUÉS, cuando el juego
esté pulido (roadmap doc 17).

## Las 3 formas de jugar hoy

### 1. En el PC (la más rápida para iterar)
- Doble clic en `JUGAR.bat` → abre http://localhost:8123 en el navegador.
- Tras cada corrección de Claude: recargar con `Ctrl+F5`.

### 2. En un teléfono Android
- El APK queda en `app\build\app\outputs\flutter-apk\app-release.apk`.
- Pasarlo al teléfono (USB, Drive, WhatsApp a ti mismo) y abrirlo.
- Android pedirá permitir "instalar apps desconocidas": aceptar (normal
  mientras no venga de Play Store).
- Tras cada ronda de correcciones: doble clic en `COMPILAR-ANDROID.bat`
  (recompila y abre la carpeta del APK) y reinstalar en el teléfono.

### 3. En un iPhone (requiere el Mac, cuando se quiera)
> Nota 04-11-2026: el 12-07-2026 Alejandro confirmó que tiene acceso a un Mac. La pregunta 22 queda reducida a si el iPhone entra al lanzamiento, y sigue pendiente de Alejandro. Hasta hoy no hay constancia de que iOS se haya compilado (H-10).

En el Mac, una sola vez:
1. Instalar Xcode (App Store del Mac) y Flutter (flutter.dev/docs/get-started).
2. Clonar/copiar la carpeta del proyecto al Mac.
3. Conectar el iPhone por cable y confiar en el Mac.
4. En la terminal: `cd app && flutter run --release`
   - Xcode pedirá una cuenta Apple (sirve el Apple ID gratis).
   - Con Apple ID gratis la app instalada caduca a los 7 días
     (se vuelve a instalar con el mismo comando). Con cuenta de developer
     (US$99/año, necesaria de todos modos para App Store) no caduca igual
     y habilita TestFlight.

## El circuito de correcciones

1. Juegas (PC o teléfono).
2. Anotas lo que no te gusta — o mejor: al terminar cada caso, escribe en el
   campo de feedback de la pantalla CASO CERRADO.
3. En la pantalla de casos, botón de copiar (arriba a la derecha) →
   copia TODO tu feedback acumulado al portapapeles.
4. Lo pegas en el chat de Claude.
5. Claude corrige, recompila web (automático en JUGAR.bat) y tú relanzas
   `COMPILAR-ANDROID.bat` si quieres probar en el teléfono.

## Qué probar en esta fase (checklist de playtest)

- ¿Las pistas se entienden a la primera?
- ¿La dificultad de cada sección se siente justa?
- ¿El arrastre y el tap responden bien EN EL TELÉFONO (dedos, no mouse)?
- ¿Los muebles se reconocen de un vistazo?
- ¿El estilo paper craft se ve bien en tu pantalla?
- ¿Algo se ve cortado, pequeño o ilegible en el teléfono?

## Qué NO está todavía (a propósito — llega en Fase 2+)

- Cuentas, ranking, reto diario, vidas, racha, tienda, tutorial guiado.
- Los 20 casos actuales son del banco de pruebas, no la campaña final.

> ACTUALIZACIÓN 04-11-2026 (H-36): la lista de arriba es de julio de 2026 y hoy es inexacta en dos puntos, comprobado en el código:
> - **El tutorial guiado SÍ existe**: hay un nodo "TUTORIAL" antes del Caso Nº1 que abre el primer caso paso a paso (`app/lib/src/ui/tutorial_coach.dart`, `app/lib/src/ui/case_list_screen.dart`), y un tutorial de primera vez omitible.
> - **Reto diario, ranking, racha, vidas, tienda y Premium existen como pantallas simuladas**, con datos fijos (Tienda, Premium, Ranking, Configuración y los puntos de la semana del Reto llevan DEMO; vidas, racha y estadísticas del perfil se simulan sin etiqueta (H-62)) (`app/lib/src/ui/home_shell.dart`). Se ven, pero no funcionan de verdad: no hay cuentas, ni servidor, ni compras. No cuentan como probadas. Qué se ve en el build de tiendas es la decisión 18, pendiente de Alejandro.
> - Lo que sí sigue sin existir: cuentas, servidor, audio, vibración y ayudas dentro de la partida. **DECIDIDO 04-11-2026** (auditoría, preguntas 5 y 9; ver ADR-0012): con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos, y la partida queda guardada; al fallar en Resolver se muestra solo cuántas casillas no cuadran, no cuáles (el resaltado exacto queda solo para el tutorial). Falta implementarlo en la app.

## Comando único para verificar el proyecto

Fila agregada el 04-11-2026 (H-36), con los comandos que existen hoy. Se corren desde la carpeta del proyecto, cada uno desde su subcarpeta:

1. Motor de puzzles: `cd tools` y luego `dart test`. Hoy son 54 pruebas automáticas.
2. App: `cd app` y luego `flutter analyze` y `flutter test`. Hoy son 26 pruebas automáticas.

Los dos resultados deben salir sin errores antes de dar por bueno un cambio. Todavía no existe un único archivo `.bat` que corra los dos; si se quiere, se pide como tarea aparte.

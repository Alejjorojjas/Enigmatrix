# Enigmatrix - Guía de pruebas (Fase 1)

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

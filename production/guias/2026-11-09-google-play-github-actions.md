# Guía: Google Play con GitHub Actions

- **Fecha:** 09-11-2026
- **Decisión:** ADR-0017.
- **Workflow:** `.github/workflows/android-play.yml`.

## Qué hace el workflow

Cada push a `main` que toque código pasa por tres pasos. Los cambios que solo tocan `docs/`, `production/`, archivos `.md`, `backend/` o `prototipos/` no lo disparan.

1. **Pruebas.** Corre las del motor (`tools`) y las de la app. Si alguna falla, no sigue.
2. **Compilación.** Compila el `.aab` de tienda y lo firma con tu llave de subida. Es la versión sin las herramientas de desarrollo y con el servidor apagado (`ENX_BACKEND=none`). El `.aab` queda descargable 14 días en la página del run.
3. **Subida.** Lo sube a Google Play, a la **prueba interna**, que no pasa por revisión de Google y llega solo a los correos que pongas. Este paso solo corre cuando actives la variable `PLAY_UPLOAD`.

Se puede lanzar a mano desde GitHub: pestaña **Actions**, workflow "Android a Google Play", botón **Run workflow**.

**El número de versión:** el `versionCode` es 10000 más el número de ejecución del workflow, así que siempre crece. El nombre visible, por ejemplo 0.8.0, sale de `app/pubspec.yaml`.

## Lo que tienes que hacer tú, en orden

Claude no puede hacer estos pasos: tocan tu llave de firma, tus cuentas y tus pagos.

### 1. Subir la llave de firma a GitHub como secretos

Tu llave de subida (el archivo `.jks`) y sus claves (en `app/android/key.properties`) **nunca** van al repositorio. Van como "secretos" de GitHub, que nadie puede leer después de guardarlos, ni siquiera tú.

1. **Convierte la llave a texto.** En PowerShell, en tu PC, ejecuta este comando cambiando la ruta por la de tu archivo `.jks`. Copia el resultado al portapapeles y no lo muestra en pantalla.
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\a\tu-llave.jks")) | Set-Clipboard
   ```
2. **Abre los secretos.** En github.com/Alejjorojjas/Enigmatrix ve a **Settings → Secrets and variables → Actions → New repository secret**.
3. **Crea estos cuatro secretos.** Los valores 2 a 4 los copias de tu `key.properties`:

   | Nombre del secreto | Valor |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | Lo que quedó en el portapapeles en el paso 1 |
   | `ANDROID_KEYSTORE_PASSWORD` | El valor de `storePassword` |
   | `ANDROID_KEY_ALIAS` | El valor de `keyAlias` |
   | `ANDROID_KEY_PASSWORD` | El valor de `keyPassword` |

4. **Comprueba.** Ve a **Actions → Android a Google Play → Run workflow**. Si termina en verde, la compilación y la firma funcionan. Si falta un secreto, el workflow se detiene con un mensaje claro y no sube nada.

### 2. Crear la app en Play Console

1. Entra a play.google.com/console y ve a **Crear app**.
   - **Nombre:** Enigmatrix.
   - **Idioma predeterminado:** Español. Elige entre Latinoamérica (es-419) y España; es tu decisión.
   - **Tipo:** Juego.
   - **Precio:** Gratis.
   - Acepta las declaraciones.
2. Deja activada la **firma de apps de Google Play**, que viene por defecto. Tu llave pasa a ser la "llave de subida" y Google firma lo que llega a los teléfonos.

### 3. Primera subida a mano (Google lo exige una vez)

La API de Google Play no puede crear la primera versión de una app nueva. La primera vez se sube a mano:

1. **Descarga el `.aab`.** En GitHub ve a **Actions**, abre el último run en verde y descarga `enigmatrix-aab-N`. Es un `.zip` con `app-release.aab` adentro.
2. **Crea la versión.** En Play Console ve a **Prueba y lanzamiento → Prueba interna → Crear versión nueva**, sube `app-release.aab` y guarda.
3. **Agrega probadores.** En la pestaña **Testers**, crea una lista con tu correo y los de quienes quieras. La prueba interna admite hasta 100 personas.
4. **Publica.** Pulsa **Revisar versión → Lanzar en prueba interna**. Si Play Console pide completar algo antes (por ejemplo, la sección "Contenido de la app"), complétalo; para la prueba interna suele pedir poco.
5. **Instala.** Abre el enlace de "Unirse a la prueba" desde tu teléfono e instálala desde Play.
   - **Ojo:** como Google firma con otra llave, no se instala encima del APK que te paso yo. Antes hay que desinstalar el APK, y se pierde el progreso local de ese APK.

### 4. Cuenta de servicio para que GitHub suba solo

1. **Activa la API.** En console.cloud.google.com crea un proyecto, por ejemplo "enigmatrix-ci". Más adelante puede ser el mismo de Firebase. Ve a **APIs y servicios → Biblioteca**, busca **Google Play Android Developer API** y pulsa **Habilitar**.
2. **Crea la cuenta de servicio.** Ve a **IAM y administración → Cuentas de servicio → Crear cuenta de servicio**, con el nombre "github-play". No le des roles en Google Cloud.
3. **Descarga la clave.** Dentro de esa cuenta de servicio ve a **Claves → Agregar clave → JSON**. Se descarga un archivo. Trátalo como una contraseña.
4. **Dale acceso en Play Console.** Ve a **Usuarios y permisos → Invitar usuarios** y pon el correo de la cuenta de servicio, el que termina en `iam.gserviceaccount.com`.
   - Dale acceso a la app Enigmatrix con los permisos de **lanzar a pistas de prueba** ("Release to testing tracks").
   - **No** le des permiso de producción por ahora.
5. **Guárdala en GitHub.** Crea el secreto `PLAY_SERVICE_ACCOUNT_JSON`, pegando el contenido completo del archivo JSON. Después borra el JSON de tu carpeta de Descargas.

### 5. Activar la subida automática

En GitHub ve a **Settings → Secrets and variables → Actions**, pestaña **Variables**, y crea:

| Variable | Valor | Para qué |
|---|---|---|
| `PLAY_UPLOAD` | `true` | Enciende la subida |
| `PLAY_TRACK` | `internal` | Prueba interna. Más adelante puede ser `alpha` (prueba cerrada) |
| `PLAY_RELEASE_STATUS` | `completed` | Se publica sola en la pista. Usa `draft` si prefieres revisarla y lanzarla tú |

Desde ahí, cada push a `main` con cambios de código termina en la prueba interna de Play en unos 15 a 20 minutos.

## Antes de pasar a la prueba cerrada o a producción

- **Pantallas simuladas (pregunta 18).** Ocultar la tienda, el premium y el ranking simulados en la versión de tienda. Hoy el `.aab` aún los muestra; para la prueba interna no importa, porque no hay revisión.
- **Privacidad.** Política de privacidad publicada en una URL, formulario de **Seguridad de los datos** y **Contenido de la app**. El APK ya pide permiso de INTERNET por las librerías de Firebase (bitácora del 07-11-2026).
- **Los 12 probadores.** Si tu cuenta de desarrollador es personal y se creó después del 13-11-2023, Google exige una prueba cerrada con 12 o más probadores durante 14 días antes de producción.
- **Ficha de la tienda.** Ícono de 512 px, imagen destacada de 1024×500, capturas y descripciones.

## Costos

- **GitHub Actions:** un repositorio privado tiene 2.000 minutos gratis al mes en el plan Free. Cada ejecución gasta unos 15 a 20 minutos, así que alcanzan unos 100 pushes de código al mes.
- **App Store, más adelante:** los runners de macOS gastan esos minutos 10 veces más rápido.

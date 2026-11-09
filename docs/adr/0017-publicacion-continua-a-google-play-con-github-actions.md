# ADR-0017: Publicación continua a Google Play con GitHub Actions

- **Estado**: Aceptado (09-11-2026)
- **Fecha**: 09-11-2026
- **Decisores**: usuario (Alejandro) / arquitecto

## Contexto

Alejandro quiere que cada push a `main` llegue solo a Google Play. Más adelante quiere lo mismo con App Store y las demás tiendas, pero se empieza por Google Play. Ya tiene pagadas las cuentas de desarrollador de Google Play y de Apple.

Hasta hoy los APK se compilaban a mano en su PC, en la carpeta principal, que es donde está la llave de firma.

## Decisión

1. **Un workflow de GitHub Actions** (`.github/workflows/android-play.yml`) se dispara con cada push a `main` que toque código, y también a mano. Hace cuatro cosas:
   - corre las pruebas del motor y de la app;
   - compila el `.aab` de tienda, sin `ENX_DEV` y con `ENX_BACKEND=none`;
   - lo firma con la llave de subida;
   - lo sube a Google Play.
2. **La llave de subida y sus claves** solo existen en los secretos de GitHub del repositorio privado. Las carga Alejandro.
   - El workflow las escribe en el runner, compila y las borra al terminar.
   - Si faltan, el workflow falla. No firma con la llave de depuración.
3. **Pista de destino:** la prueba interna (`internal`), sin revisión de Google. Pasar a una prueba cerrada o a producción es una decisión manual de Alejandro: se cambia la variable `PLAY_TRACK` o se promueve la versión en Play Console.
4. **`versionCode`** = 10000 + el número de ejecución del workflow. Siempre crece y queda por encima de los APK compilados a mano.
5. **Subida con permisos mínimos.** La hace una cuenta de servicio de Google Cloud con permiso solo para las pistas de prueba, no para producción. La acción usada es `r0adkll/upload-google-play@v1`.
6. **Primera subida a mano.** La primera versión de la app se sube a mano en Play Console, porque la API de Google no puede crear la primera. Hasta tener la cuenta de servicio, la subida automática queda apagada con la variable `PLAY_UPLOAD`.

### Cuenta de publicación (09-11-2026)

Enigmatrix se publica en la cuenta de desarrollador de Google Play de un amigo de Alejandro. Alejandro es colaborador en esa cuenta y con ese amigo ya publicaron otras apps; según Alejandro, "está todo cuadrado" entre ellos.

En la ficha aparece el nombre de desarrollador de esa cuenta y los ingresos van a su perfil de pagos. A futuro piensan separar las cuentas: entonces se usará la transferencia de apps de Google Play, que conserva la app, sus usuarios y la llave de firma.

Esto ajusta la pregunta 17 ("persona natural") mientras dure el arreglo. Los permisos de administración de la cuenta, como invitar a la cuenta de servicio, los puede necesitar el dueño.

### Nombre de la app (09-11-2026)

Alejandro decidió que la app se publique como **"Murdoku Diario"**. Antes del primer envío a Google Play pasan a llevar ese nombre:
- la tienda;
- el texto debajo del ícono;
- la pantalla de carga;
- Configuración.

El identificador del paquete pasa a ser **`com.murdokudiario.app`** y es permanente. Enigmatrix sigue siendo el nombre interno del proyecto, del repositorio y del código.

Se le avisó que "Murdoku" es el nombre de una serie de libros de Manuel Garand y de una app que ya existe en la App Store. Alejandro dijo que no hay problema con usarlo.

## Alternativas consideradas

- **fastlane supply.** Hace lo mismo con más configuración (Ruby, Fastfile). Se reconsidera si se necesita subir la ficha y las capturas desde el repositorio.
- **Subir directo a producción en cada push.** Rompe los pilares 3 y 4: un error llegaría a todos los jugadores sin que nadie lo pruebe.
- **Compilar en el PC y subir a mano.** Es lo de hoy; depende de que Alejandro esté en su PC.

## Consecuencias

- **Llave fuera del PC.** La llave de subida queda guardada también en GitHub, aunque cifrada como secreto. Si se filtra, se puede pedir a Google un cambio de llave de subida, porque la firma de apps de Google Play guarda la llave real de la app.
- **Minutos de GitHub.** Cada ejecución gasta unos 15 a 20 minutos de los 2.000 gratis al mes del repositorio privado. Los cambios solo de documentos no lo disparan.
- **Dos firmas distintas.** El APK que se instala desde Play lo firma Google, con otra llave. No se puede instalar encima de un APK compilado a mano: hay que desinstalar antes.
- **App Store** irá en un workflow aparte, con un runner de macOS, cuando se decida si el iPhone entra (pregunta 22).
- **Guía paso a paso para Alejandro:** `production/guias/2026-11-09-google-play-github-actions.md`.

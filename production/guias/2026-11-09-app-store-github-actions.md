# Guía: App Store (TestFlight) con GitHub Actions

Para Alejandro. Se hace una sola vez. No necesitas Mac: compila una máquina Mac de GitHub. Sí necesitas el iPhone para probar.

Cuando termines, cada PR que apruebes y llegue a `main` se compila para iPhone y se sube a **TestFlight**. Es la prueba de Apple, el equivalente a la prueba interna de Google Play. Pasar a la App Store pública es un paso manual tuyo, con revisión de Apple.

> **Contraseñas y códigos:** los escribes tú. Claude no los ve ni los escribe. La cuenta es la de tu amigo, así que el código de verificación de Apple puede llegarle a su teléfono.

Todo lo que sigue se guarda en una carpeta fuera del repositorio:
`D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\llaves-ios`

---

## Paso 1. Registrar el identificador de la app

1. Entra a https://developer.apple.com/account y ve a **Certificates, Identifiers & Profiles → Identifiers**.
2. Pulsa **+**, elige **App IDs**, luego **App** y pulsa Continue.
3. Llena los campos:
   - **Description:** `Murdoku Diario`
   - **Bundle ID:** **Explicit**, `com.murdokudiario.app`
4. No marques ninguna capacidad extra. Pulsa Continue y luego Register.

Arriba a la derecha aparece el **Team ID** (10 letras y números). No es secreto; el workflow lo lee solo.

## Paso 2. Crear la app en App Store Connect

1. Entra a https://appstoreconnect.apple.com, ve a **Apps** y pulsa **+** y luego **Nueva app**.
2. Llena los campos:
   - **Plataforma:** iOS
   - **Nombre:** `Murdoku Diario`. Si Apple dice que está ocupado, avísame.
   - **Idioma principal:** Español (México)
   - **ID de paquete:** `com.murdokudiario.app`
   - **SKU:** `murdokudiario`
   - **Acceso de usuarios:** Acceso completo

## Paso 3. Certificado de distribución (sin Mac)

Abre **PowerShell** y pega esto. Cambia `TU_CORREO` por tu correo:

```powershell
$o = "C:\Program Files\Git\usr\bin\openssl.exe"
New-Item -ItemType Directory -Force "D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\llaves-ios"
cd "D:\OneDrive\Documentos\Repositorios GitHub\Proyecto Enigmatrix\llaves-ios"
& $o genrsa -out murdoku-dist.key 2048
& $o req -new -key murdoku-dist.key -out murdoku-dist.csr -subj "/emailAddress=TU_CORREO/CN=Murdoku Diario/C=CO"
```

Después, en el portal de Apple:

1. Ve a **Certificates** y pulsa **+**.
2. Elige **Apple Distribution** y pulsa Continue.
3. Sube `murdoku-dist.csr`, pulsa Continue y luego **Download**. Baja un archivo `distribution.cer`; muévelo a la carpeta `llaves-ios`.

Si Apple dice que ya se llegó al máximo de certificados, para y avísame. La cuenta de tu amigo puede tener certificados de sus otras apps, y no se debe borrar ninguno sin preguntarle.

Vuelve a PowerShell, en la misma carpeta:

```powershell
& $o x509 -inform DER -in distribution.cer -out murdoku-dist.pem
& $o pkcs12 -export -inkey murdoku-dist.key -in murdoku-dist.pem -out murdoku-dist.p12 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
```

El segundo comando te pide una contraseña dos veces. **Invéntala y anótala:** es el secreto `IOS_DIST_CERT_PASSWORD`.

## Paso 4. Perfil de aprovisionamiento

1. En el portal de Apple ve a **Profiles** y pulsa **+**.
2. En Distribution, elige **App Store Connect** y pulsa Continue.
3. Elige el App ID `com.murdokudiario.app` y pulsa Continue.
4. Elige el certificado que acabas de crear (el de fecha de hoy) y pulsa Continue.
5. **Nombre:** `Murdoku Diario App Store`. Pulsa Generate y luego Download.
6. Mueve el archivo `.mobileprovision` a `llaves-ios`.

## Paso 5. Llave de API de App Store Connect

1. En App Store Connect ve a **Usuarios y acceso → Integraciones → App Store Connect API → Claves de equipo**.
   - Si es la primera vez en esa cuenta, puede pedir **Solicitar acceso**. Eso solo lo puede aceptar el titular (tu amigo).
2. Pulsa **+** o **Generar clave de API**:
   - **Nombre:** `GitHub Actions Murdoku`
   - **Acceso:** **App Manager**
3. Anota dos datos:
   - el **ID de emisor** (Issuer ID), que aparece arriba de la tabla;
   - el **ID de clave** (Key ID), que aparece en la fila.
4. Pulsa **Descargar**. Baja un archivo `AuthKey_XXXX.p8` y **solo se puede bajar una vez**. Guárdalo en `llaves-ios`.

> Aviso para tu amigo: la llave sirve para todas las apps de su cuenta, no solo para Murdoku. Queda guardada cifrada en los secretos de GitHub. Si algún día se filtra, se revoca en esa misma pantalla.

## Paso 6. Secretos en GitHub

En el repositorio ve a **Settings → Secrets and variables → Actions → New repository secret** y crea estos seis.

Para los tres que son archivos, ejecuta el comando en PowerShell, dentro de `llaves-ios`. El valor queda copiado y solo lo pegas en GitHub:

| Secreto | Valor |
|---|---|
| `IOS_DIST_CERT_P12_BASE64` | `[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\murdoku-dist.p12))) \| Set-Clipboard` |
| `IOS_DIST_CERT_PASSWORD` | la contraseña del paso 3 |
| `IOS_PROVISION_PROFILE_BASE64` | `[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\*.mobileprovision))) \| Set-Clipboard` |
| `APPSTORE_API_KEY_ID` | el ID de clave del paso 5 |
| `APPSTORE_API_ISSUER_ID` | el ID de emisor del paso 5 |
| `APPSTORE_API_PRIVATE_KEY` | `Get-Content (Resolve-Path .\AuthKey_*.p8) -Raw \| Set-Clipboard` |

Después ve a la pestaña **Variables** y crea `IOS_UPLOAD` con el valor `true`.

## Paso 7. Primera compilación

1. Primero tiene que estar aprobado y fusionado el PR que trae el workflow `iOS a TestFlight`.
2. Ve a **Actions → iOS a TestFlight → Run workflow** (rama `main`).
3. Tarda unos 20 a 30 minutos. Si sale en rojo, mándame una captura del paso que falló.
4. Cuando sale en verde, Apple procesa la compilación otros 10 a 30 minutos. Te llega un correo cuando está lista.

## Paso 8. Probar en tu iPhone (TestFlight)

1. Para recibir las compilaciones de prueba interna, tu propio Apple ID tiene que ser usuario del equipo.
   - En App Store Connect ve a **Usuarios y acceso** y pulsa **+**.
   - Invita a tu Apple ID con el rol **Desarrollador**.
   - Acepta la invitación desde tu correo.
2. Entra a la app **Murdoku Diario**, pestaña **TestFlight → Pruebas internas** (pulsa **+**), y crea el grupo `Equipo Murdoku`.
3. Agrégate al grupo y agrega la compilación.
4. En el iPhone instala la app **TestFlight** de la App Store, con tu Apple ID. Ahí aparece Murdoku Diario para instalar.

Desde ahí, cada PR que apruebes llega solo a TestFlight. TestFlight avisa en el iPhone cuando hay una compilación nueva.

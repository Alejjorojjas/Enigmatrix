# Enigmatrix - Checklist de publicación en tiendas

> ACTUALIZACIÓN 05-11-2026 (versión 0.5.0+5, H-07): las tipografías (Baloo 2, Quicksand y Patrick Hand, licencia OFL) ahora van **dentro de la app** y ya no se descargan de Google. El permiso **INTERNET** se quitó del manifiesto principal de Android porque solo lo usaba esa descarga; vuelve en la etapa 5 (Firebase). Donde este documento diga que la app declara INTERNET o descarga las fuentes con google_fonts, eso ya no aplica.

> ACTUALIZACIÓN 04-11-2026 (auditoría 04-11-2026, hallazgos H-36, H-05, H-07, H-09, H-11 y H-35): este checklist se puso al día contra el código. **Hoy no se puede subir nada a las tiendas** y no se declara ninguna edad ni cuestionario mientras estén abiertos los temas de abajo. Lo anterior se conserva; las filas corregidas llevan una nota "04-11-2026".
>
> Condiciones que bloquean la prueba cerrada en Google Play y la revisión de Apple:
> 1. **Lo simulado debe esconderse o etiquetarse claramente.** La Tienda (vidas y protectores con precios), Premium, el Ranking, la racha, los puntos de la semana y el Reto diario son pantallas con datos fijos: Tienda, Premium, Ranking, Configuración y los puntos de la semana del Reto llevan DEMO; vidas, racha y estadísticas del perfil se simulan sin etiqueta (H-62) (`app/lib/src/ui/home_shell.dart`). **DECIDIDO 06-11-2026** (auditoría, pregunta 18): la versión que revisa la tienda va **sin la tienda, el premium ni el ranking simulados, y sin ajustes que no hacen nada**, compilada sin `ENX_DEV`, mientras no exista la etapa 5B. Esa decisión **sigue bloqueando** la subida hasta que el código lo cumpla (no está hecho). ~~Antes: PENDIENTE DE DECISIÓN; la frase "sin compras" no podía declararse tal cual.~~
> 2. **Edad mínima.** **DECIDIDO 06-11-2026** (auditoría, pregunta 16, H-09): **13 años o más**. ~~Antes: PENDIENTE DE DECISIÓN entre "12+" y "no dirigido a menores de 13".~~ La clasificación final la da el cuestionario de cada tienda; el "12+" y el "Everyone 10+/Teen" de este documento quedan SUPERADOS.
> 3. **Víctima.** **DECIDIDO 06-11-2026** (auditoría, pregunta 8, H-35): ficha normal marcada con †, sin cuerpo ni sangre; ver la sección "Reglas de contenido" más abajo.
> 4. **El respaldo de la llave de firma NO está hecho** (H-05). No marcar como resuelto hasta probar una restauración.
> 5. **Identidad legal del responsable.** **DECIDIDO 06-11-2026** (auditoría, pregunta 17, H-08): Alejandro publica como **persona natural**. Siguen pendientes el nombre público, el correo y la dirección de contacto (conviene un apartado postal u oficina virtual, porque con compras la ficha en la UE puede mostrar los datos del comerciante; confirmar en Play Console). ~~Antes: sin definir.~~
>
> ACTUALIZACIÓN 06-11-2026: Alejandro ya tiene **pagadas** la cuenta de desarrollador de Google Play y la de Apple, así que las filas "Cuenta de developer" y "Apple Developer Program" de abajo ya no esperan el pago. La versión web queda para la V2. Plan: `production/planes/2026-11-06-etapas-5-y-6.md`, sección 3 (etapa 6).

Estado al 12-07-2026 (con las notas del 04-11-2026). ✅ = resuelto en el proyecto · 📋 = se hace en la
consola al subir · ⏳ = pendiente de decisión/recurso del usuario.

## Google Play

| Requisito | Estado | Detalle |
|---|---|---|
| App Bundle (.aab) firmado | ✅ | `PUBLICAR-PLAYSTORE.bat` lo genera; firma con keystore de subida |
| Keystore de subida | ✅ creada · ⏳ **respaldo NO hecho** | `app/android/upload-keystore.jks` + `key.properties` (fuera de git). **RESPALDAR ambos fuera del PC — si se pierden se pierde la capacidad de actualizar la app**. Nota 04-11-2026 (H-05): el respaldo sigue SIN hacerse y no se marca como hecho. Los dos archivos están juntos, con las contraseñas en texto plano, dentro de una carpeta sincronizada con OneDrive, y el proyecto no tiene repositorio remoto. Además, si falta `key.properties` (por ejemplo en el Mac o tras reinstalar), `app/android/app/build.gradle.kts` firma el release con la llave de debug sin avisar. Alejandro todavía NO autorizó sacar la llave de OneDrive ni cambiar la configuración de firma |
| Play App Signing | 📋 | Al crear la app en la consola, aceptar que Google gestione la firma (default) |
| applicationId único | ✅ | `com.enigmatrix.app` |
| targetSdk reciente | ✅ | Flutter usa el target actual automáticamente; revisar en cada release |
| Sin permisos innecesarios | ✅ | Solo INTERNET (tipografías / futuro backend). Nota 04-11-2026 (H-07): hoy INTERNET se usa solo porque `google_fonts` descarga las tipografías (Quicksand, Baloo 2, Patrick Hand) la primera vez que se abre la app; sin red en esa primera apertura se ve la fuente por defecto. Empaquetar las tipografías permitiría quitar el permiso hasta la Fase 2; es un cambio de código y no está hecho |
| allowBackup / cleartext | ✅ | Deshabilitados (doc 18) |
| Data Safety form | 📋 | Responder: NO se recolectan datos, NO se comparten, sin SDKs de terceros. Cambia en Fase 2 (Firebase). Nota 04-11-2026 (H-07): antes de responder hay que revisar esa frase, porque cada dispositivo contacta a servidores de Google al descargar las tipografías y la dirección IP llega a Google; según lo investigado, un tribunal alemán la trató como dato personal. Se simplifica si las tipografías se empaquetan en la app |
| Content rating (IARC) | 📋 | Cuestionario: violencia leve implícita en temática de misterio, sin sangre ni imágenes — ~~apunta a Everyone 10+/Teen (docs 13 y 15)~~. Nota 06-11-2026: **DECIDIDO** (preguntas 16 y 8): público de 13 años o más; la víctima es una ficha normal con †, sin cuerpo ni sangre. Con eso ya se puede responder el cuestionario; la clasificación final la calcula la tienda. ~~Nota 04-11-2026: PENDIENTE DE DECISIÓN, no responderlo hasta decidir~~ |
| Política de privacidad (URL pública) | ⏳ | Texto listo en `docs/legal/politica-privacidad.md`; falta: completar nombre/correo del responsable y alojarla (GitHub Pages sirve). Nota 04-11-2026 (H-06, H-08): sigue con corchetes y con una nota interna sin borrar; el responsable depende de la decisión 17 (identidad legal, pendiente de Alejandro); la app no tiene aún ningún botón que abra la política y Apple exige un enlace dentro de la app |
| Cuenta de developer (US$25) | ✅ | Del usuario. Nota 06-11-2026: Alejandro ya la tiene pagada. Revisar la fecha de creación: si es posterior al 13-11-2023, Google exige la prueba cerrada de 12 probadores durante 14 días (confirmar en Play Console) |
| Icono de app (512px + adaptive) | ✅ app · ⏳ ficha | ~~⏳ Hoy usa el icono default de Flutter — hay que diseñar el icono paper craft antes de subir~~ (SUPERADO 04-11-2026). Nota 04-11-2026 (H-36): el icono de la app ya NO es el de Flutter; desde el commit 54dced2 es una lupa de papel, generada en todas las densidades de Android y iOS desde `app/assets/icon/` (1024 × 1024). Falta exportar el icono de 512 px y el gráfico de funciones para la ficha de Play. Puede cambiar si la etapa 2 (prueba de concepto gráfica) cambia la identidad visual |
| Screenshots + feature graphic | ⏳ | Se capturan cuando la UI esté congelada (la dirección gráfica sigue en revisión hasta la etapa 2) |
| Ficha de tienda (título, descripciones ES/EN) | ⏳ | Redactar al final |
| Pruebas cerradas: 12 testers × 14 días | 📋 | Requisito para cuentas personales nuevas antes de producción — planear con amigos/familia. Nota 04-11-2026: **DECIDIDO 04-11-2026** (auditoría, pregunta 21; ver ADR-0012): Alejandro puede conseguir de 3 a 5 personas para la prueba de juego; para las 12 de la prueba cerrada de Play todavía hay que conseguir más |
| Público objetivo y contenido de la ficha (declaración de Play) | ⏳ | Fila agregada el 04-11-2026 (H-11). La edad mínima está **DECIDIDA 06-11-2026** (pregunta 16): 13 años o más. Declarar también el uso de anuncios (hoy no hay) |
| Verificación de desarrollador de Google | ⏳ | Fila agregada el 04-11-2026 (H-11). Confirmar el requisito y los plazos vigentes en la documentación de Google Play antes de crear la cuenta; la identidad legal está **DECIDIDA 06-11-2026** (pregunta 17): persona natural |
| Estado de comerciante (trader, DSA de la Unión Europea) | ⏳ | Fila agregada el 04-11-2026 (H-11, H-08). Con compras o suscripciones se puede considerar comerciante y sus datos de contacto se publican en la ficha en la UE. Nota 06-11-2026: al publicar como persona natural (pregunta 17, DECIDIDA) conviene usar un apartado postal u oficina virtual y confirmar en Play Console que la acepten. Confirmar con un abogado |
| Validar el .aab antes de subirlo | ⏳ | Fila agregada el 04-11-2026 (H-11). Comprobar la firma del bundle (hoy `PUBLICAR-PLAYSTORE.bat` no la verifica, H-05), la alineación de 16 KB de las librerías nativas y el contenido con el explorador de App Bundle. La exigencia de 16 KB es de la documentación de Google: confirmar fecha y prórroga vigentes |
| Probar en Android 16 con pantallas grandes | ⏳ | Fila agregada el 04-11-2026 (H-11). Android 16 (API 36) obliga a dibujar de borde a borde e ignora el bloqueo de orientación en pantallas grandes; no hay constancia de haberlo probado con el .aab real |
| Número de targetSdk esperado | ⏳ | Fila agregada el 04-11-2026 (H-11). La fila "targetSdk reciente" de arriba no tiene número ni método: `build.gradle.kts` toma el valor de Flutter (`flutter.targetSdkVersion`). Anotar el número real al compilar el release y compararlo con el mínimo que exija Play ese día |

## App Store (iOS)

| Requisito | Estado | Detalle |
|---|---|---|
| Bundle ID + nombre visible | ✅ | `com.enigmatrix.enigmatrix` · "Enigmatrix" (unificar con Android en `com.enigmatrix.app` al abrir la cuenta, si se quiere) |
| ATS solo HTTPS | ✅ | Default de iOS, no se tocó |
| Export compliance | ✅ | `ITSAppUsesNonExemptEncryption=false` en Info.plist (evita el cuestionario de cifrado en cada build) |
| Privacy Manifest | ✅* | `ios/Runner/PrivacyInfo.xcprivacy` creado — *en el Mac hay que agregarlo al target Runner en Xcode (File → Add Files)* |
| Nutrition labels (App Privacy) | 📋 | Declarar "Data Not Collected" mientras no haya Fase 2 |
| Política de privacidad (URL) | ⏳ | La misma de Google Play (ver la nota de esa fila: responsable pendiente y falta el enlace dentro de la app) |
| Apple Developer Program (US$99/año) | ✅ | Del usuario; necesario también para TestFlight. Nota 06-11-2026: Alejandro ya tiene la cuenta pagada; que exista no cambia el alcance (ADR-0014: Android primero; el iPhone sigue pendiente, pregunta 22). Nota 04-11-2026: la pregunta 22 queda reducida a si el iPhone entra al lanzamiento (sigue pendiente de Alejandro). El 12-07-2026 Alejandro confirmó que tiene acceso a un Mac, así que ese ya no es el obstáculo |
| Notas para el revisor de Apple (modo sin cuentas) | ⏳ | Fila agregada el 04-11-2026 (H-11). Explicar que la app funciona sin cuenta y qué es simulado, para evitar rechazos |
| Estado de comerciante (trader, DSA) en App Store Connect | ⏳ | Fila agregada el 04-11-2026 (H-11, H-08). Apple pide dirección, teléfono y correo públicos si se es comerciante; la pregunta 17 está DECIDIDA 06-11-2026 (persona natural) |
| Icono 1024px | ✅ origen · ⏳ revisar | ~~⏳ El mismo diseño paper craft~~ (SUPERADO 04-11-2026). Nota 04-11-2026: `app/assets/icon/icon_full.png` ya mide 1024 × 1024 y de él salen los iconos de iOS. Revisar en el Mac que no tenga transparencia, que Apple no acepta |
| Compilación + subida | ⏳ | Requiere el Mac: Xcode → Product → Archive → Distribute. Nota 04-11-2026 (H-10): iOS nunca se ha compilado; no hay constancia de que el Mac se haya usado todavía |

## Reglas de contenido que ya cumplimos por diseño

- Sin sangre ni violencia gráfica; ~~la víctima nunca se representa
  visualmente (doc 13-narrativa)~~ la víctima es una ficha normal marcada con †, sin cuerpo, sin sangre y sin escena del crimen (doc 13-narrativa) → apto para rating bajo.
  > ACTUALIZACIÓN 06-11-2026: **DECIDIDO** (auditoría, pregunta 8, H-35): la redacción de arriba (ficha normal con †, sin cuerpo ni sangre) es la definitiva y es la misma en los docs 13, 15 y 20. Ya se puede usar para responder el cuestionario IARC.
  > ACTUALIZACIÓN 04-11-2026: ~~PENDIENTE DE DECISIÓN~~ (decidida el 06-11-2026) (auditoría 04-11-2026, pregunta 8, H-35). Esta frase no coincide con el juego: hoy la víctima SÍ aparece en el tablero como una ficha (círculo de color con una † en vez de inicial) y su tarjeta lleva la cinta "LA VÍCTIMA" (`app/lib/src/ui/board_view.dart`, `app/lib/src/ui/game_screen.dart`), porque el jugador debe ubicarla como a cualquier personaje (`docs/16-spec-puzzle.md`, sección 2.1). No se muestra cuerpo, sangre ni escena del crimen. La redacción definitiva, igual en los docs 13, 15 y 20, la decide Alejandro; mientras tanto no se usa esta frase para responder el cuestionario IARC.
- Sin compras, publicidad ni enlaces externos en la versión actual.
  > ACTUALIZACIÓN 04-11-2026 (H-36): no es del todo exacto. No hay compras reales, anuncios ni enlaces externos, pero la app sí muestra pantallas de Tienda (con precios en dólares), Premium, Ranking y Reto con datos fijos (Tienda, Premium, Ranking, Configuración y los puntos de la semana del Reto llevan DEMO; vidas, racha y estadísticas del perfil se simulan sin etiqueta (H-62)); el botón de comprar solo muestra un aviso de "función simulada". Antes de la prueba cerrada hay que esconderlas o etiquetarlas claramente (condición 1 del banner superior). **DECIDIDO 06-11-2026** (pregunta 18): la versión que revisa la tienda va sin esas pantallas simuladas y sin ajustes que no hacen nada.
- Sin datos de menores; app declarada para ~~12+~~ 13 años o más.
  > ACTUALIZACIÓN 06-11-2026: **DECIDIDO** (auditoría, pregunta 16, H-09): edad mínima de 13 años o más, coherente con "no dirigido a menores de 13" de `docs/15-legal.md`. La clasificación final la da el cuestionario de cada tienda. Aún no se ha declarado ninguna edad en las consolas.
  > ACTUALIZACIÓN 04-11-2026: ~~PENDIENTE DE DECISIÓN~~ (decidida el 06-11-2026) (auditoría 04-11-2026, pregunta 16, H-09): "12+" estaba en conflicto con "no dirigido a menores de 13" de `docs/15-legal.md`.
- La palabra "Infantil" eliminada de las dificultades (doc 15) para no
  activar políticas de apps para niños (Families/Kids).

## Orden recomendado cuando llegue el momento de subir

1. ~~Completar responsable + correo en la política y alojarla en una URL.~~ (SUPERADO 04-11-2026) Completar responsable + correo en la política (depende de la decisión 17) y alojarla en una URL.
2. ~~Diseñar icono (512/1024) y capturar screenshots.~~ (SUPERADO 04-11-2026) Exportar el icono de 512 px para la ficha (el icono de la app ya existe) y capturar screenshots.
3. Google Play: crear cuenta → crear app → Play App Signing → subir .aab a
   pruebas internas → Data Safety + rating → pruebas cerradas (12 testers,
   14 días) → producción.
4. App Store: cuenta developer → en el Mac agregar PrivacyInfo al target →
   Archive → TestFlight → revisión.

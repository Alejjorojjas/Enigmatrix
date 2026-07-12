# Enigmatrix - Checklist de publicación en tiendas

Estado al 2026-07-12. ✅ = resuelto en el proyecto · 📋 = se hace en la
consola al subir · ⏳ = pendiente de decisión/recurso del usuario.

## Google Play

| Requisito | Estado | Detalle |
|---|---|---|
| App Bundle (.aab) firmado | ✅ | `PUBLICAR-PLAYSTORE.bat` lo genera; firma con keystore de subida |
| Keystore de subida | ✅ | `app/android/upload-keystore.jks` + `key.properties` (fuera de git). **RESPALDAR ambos fuera del PC — si se pierden se pierde la capacidad de actualizar la app** |
| Play App Signing | 📋 | Al crear la app en la consola, aceptar que Google gestione la firma (default) |
| applicationId único | ✅ | `com.enigmatrix.app` |
| targetSdk reciente | ✅ | Flutter usa el target actual automáticamente; revisar en cada release |
| Sin permisos innecesarios | ✅ | Solo INTERNET (tipografías / futuro backend) |
| allowBackup / cleartext | ✅ | Deshabilitados (doc 18) |
| Data Safety form | 📋 | Responder: NO se recolectan datos, NO se comparten, sin SDKs de terceros. Cambia en Fase 2 (Firebase) |
| Content rating (IARC) | 📋 | Cuestionario: violencia leve implícita en temática de misterio, sin sangre ni imágenes — apunta a Everyone 10+/Teen (docs 13 y 15) |
| Política de privacidad (URL pública) | ⏳ | Texto listo en `docs/legal/politica-privacidad.md`; falta: completar nombre/correo del responsable y alojarla (GitHub Pages sirve) |
| Cuenta de developer (US$25) | ⏳ | Del usuario |
| Icono de app (512px + adaptive) | ⏳ | Hoy usa el icono default de Flutter — hay que diseñar el icono paper craft antes de subir |
| Screenshots + feature graphic | ⏳ | Se capturan cuando la UI esté congelada |
| Ficha de tienda (título, descripciones ES/EN) | ⏳ | Redactar al final |
| Pruebas cerradas: 12 testers × 14 días | 📋 | Requisito para cuentas personales nuevas antes de producción — planear con amigos/familia |

## App Store (iOS)

| Requisito | Estado | Detalle |
|---|---|---|
| Bundle ID + nombre visible | ✅ | `com.enigmatrix.enigmatrix` · "Enigmatrix" (unificar con Android en `com.enigmatrix.app` al abrir la cuenta, si se quiere) |
| ATS solo HTTPS | ✅ | Default de iOS, no se tocó |
| Export compliance | ✅ | `ITSAppUsesNonExemptEncryption=false` en Info.plist (evita el cuestionario de cifrado en cada build) |
| Privacy Manifest | ✅* | `ios/Runner/PrivacyInfo.xcprivacy` creado — *en el Mac hay que agregarlo al target Runner en Xcode (File → Add Files)* |
| Nutrition labels (App Privacy) | 📋 | Declarar "Data Not Collected" mientras no haya Fase 2 |
| Política de privacidad (URL) | ⏳ | La misma de Google Play |
| Apple Developer Program (US$99/año) | ⏳ | Del usuario; necesario también para TestFlight |
| Icono 1024px | ⏳ | El mismo diseño paper craft |
| Compilación + subida | ⏳ | Requiere el Mac: Xcode → Product → Archive → Distribute |

## Reglas de contenido que ya cumplimos por diseño

- Sin sangre ni violencia gráfica; la víctima nunca se representa
  visualmente (doc 13-narrativa) → apto para rating bajo.
- Sin compras, publicidad ni enlaces externos en la versión actual.
- Sin datos de menores; app declarada para 12+.
- La palabra "Infantil" eliminada de las dificultades (doc 15) para no
  activar políticas de apps para niños (Families/Kids).

## Orden recomendado cuando llegue el momento de subir

1. Completar responsable + correo en la política y alojarla en una URL.
2. Diseñar icono (512/1024) y capturar screenshots.
3. Google Play: crear cuenta → crear app → Play App Signing → subir .aab a
   pruebas internas → Data Safety + rating → pruebas cerradas (12 testers,
   14 días) → producción.
4. App Store: cuenta developer → en el Mac agregar PrivacyInfo al target →
   Archive → TestFlight → revisión.

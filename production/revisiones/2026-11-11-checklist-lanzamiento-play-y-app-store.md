# Lista de lanzamiento: Murdoku Diario 0.8.1+11 en Google Play y App Store

- **Fecha:** 11-11-2026
- **Skill:** `/release-checklist`. Pediste `/launch-checklist`, pero no existe como skill: es el paso que sigue a esta lista.
- **Código revisado:** la copia `Enigmatrix-revision-ccgs` (0.8.1+11, `com.murdokudiario.app`).
- **Alcance:** solo revisión. No se modificó ningún archivo del proyecto. Este informe no tiene commit. No se ejecutaron pruebas ni compilaciones, y no se consultó GitHub (no hay `gh` en este equipo).
- **Ubicación:** este informe va en `production/revisiones/`, como pediste, y no en `production/releases/`, que es donde lo pone la skill.

## Cómo se acotó la lista

- **Plataformas:** solo móvil (Google Play y App Store), según tu pedido. No hay bloques de PC ni de consola.
- **Certificación:** `platform.cert_tier` no está configurado, y sus valores (`none`, `itch`, `steam`, `console`) no tienen un régimen para móvil. **Se omite la sección de certificación.** Los requisitos de las tiendas móviles van en el bloque "Móvil", que es donde la skill los ubica.
- **Rigor `minimal` y etapa Production:** se quitan los elementos de puro proceso que no aplican a este proyecto: la prueba de resistencia de 4 horas, el parche del primer día, las claves para prensa y el turno de guardia de 72 horas.
- **Dos metas distintas:**
  - (A) la **prueba interna de Play**, que ya está publicada (versión 10007);
  - (B) la **prueba cerrada o producción en Play y la revisión de Apple**, que es lo que evalúa esta lista.

## Estado del código

- **Escaneados:** 102 archivos fuente (`app/lib`, `tools/lib`, `tools/bin` y `backend/functions/src`). Resultado: **1 TODO, 0 FIXME y 0 HACK.**
- **Resultados de pruebas: NOT ASSESSED.** No se ejecutaron ni se leyeron registros de CI. Los workflows `android-play.yml` (líneas 82 y 89) e `ios-testflight.yml` (líneas 73 y 80) corren `dart test` y `flutter test` antes de compilar, así que una compilación publicada implica que esas pruebas pasaron. **Las 95 pruebas del servidor (Vitest) no están en ningún workflow.** Hoy no afecta, porque la versión de tienda va con `ENX_BACKEND=none`, pero hay que agregarlas antes de encender el servidor.
- **Bugs abiertos: NOT ASSESSED.** No existe `production/qa/bugs/`, así que no hay registro de bugs. Los hallazgos de la prueba interna conviene registrarlos con `/bug-report`.

## Compilación

- [x] Versión fijada: `version: 0.8.1+11` en `app/pubspec.yaml`.
- [x] Versión de tienda sin herramientas de desarrollo. `kEnxDev` vale `false` sin `--dart-define=ENX_DEV=true` (`app/lib/src/game/dev_tools.dart:10`), y los workflows compilan sin `ENX_DEV`.
- [x] Servidor apagado en la versión de tienda: `ENX_BACKEND=none` en los dos workflows; el valor por defecto en `backend_config.dart` también es `none`.
- [x] Compilación reproducible desde git: los workflows de GitHub Actions compilan desde la rama (ADR-0017).
- [ ] **Firma de Android con caída silenciosa a debug** (`app/android/app/build.gradle.kts:50-54`). Si falta `key.properties`, el release se firma con la llave de debug sin avisar. Play lo rechazaría al subirlo, pero conviene que el build falle en vez de caer a debug. Es **recomendado**, no bloquea.
- [ ] **Alineación de 16 KB y targetSdk real:** sin verificar (doc 20, líneas 43 y 45).
- [ ] **iOS compilado y en TestFlight:** el workflow existe. Según el traspaso, Alejandro va por el paso 2 de la guía de App Store. **Pendiente.**

## Calidad

- [ ] Cero bugs S1 abiertos: **NOT ASSESSED** (no hay registros).
- [ ] Funciones críticas probadas. Hay pruebas automáticas (715 de la app y 342 del motor, según Alejandro) y Alejandro prueba en su teléfono. No hay registro escrito de la prueba interna.
- [ ] Rendimiento en un teléfono de gama baja: **sin medir.** Para la V1 basta probar en el Android más modesto disponible con un caso Intermedio (9×9).
- [ ] Batería y comportamiento en segundo plano. El código pausa el reloj y guarda la partida al pasar a `paused`, `inactive` o `hidden` (`game_controller.dart:237-243`). Falta probarlo en un teléfono real.

## Contenido

- [x] Contenido de la V1 (ADR-0014): 61 casos jugables en `app/assets/cases` más el tutorial, y el reto de 30 días en `tools/data/mundos/mansion-reto.json`.
- [x] Textos en archivos de traducción (`app_es.arb`, 308 claves). Solo español. El inglés no es requisito de la V1.
- [ ] Revisión ortográfica de todos los textos: sin evidencia.
- [ ] Créditos y licencias de terceros. Las tipografías son OFL (Baloo 2, Quicksand y Patrick Hand), y Flame, Riverpod y Firebase tienen sus licencias. Falta confirmar que la app muestra la pantalla de licencias (`showLicensePage` o similar). No lo verifiqué.

## Móvil: requisitos de Google Play y App Store

| Requisito | Estado | Evidencia o acción |
|---|---|---|
| Política de privacidad completa | ❌ **BLOQUEA** | `docs/legal/politica-privacidad.md` sigue con `[FECHA DE PUBLICACIÓN]`, `[NOMBRE DEL RESPONSABLE]` y `[CORREO DE PRIVACIDAD]` (líneas 13, 19, 20 y 61) |
| Política publicada en una URL | ❌ **BLOQUEA** | No hay constancia de que esté alojada. Play la exige para pasar de la prueba interna y Apple la exige siempre |
| Enlace a la política dentro de la app | ❌ **BLOQUEA (Apple)** | No hay ningún texto de "privacidad" en `app_es.arb` ni enlace en `app/lib/src`, y no está `url_launcher`. Apple pide que la política sea accesible desde la app |
| Responsable legal coherente con la cuenta | ⚠️ Decisión | La app se publica en las cuentas **de un amigo** de Alejandro (ADR-0017), pero el doc 20 y la política suponen a Alejandro como persona natural responsable. Hay que decidir quién figura como responsable del tratamiento y como comerciante (DSA) |
| Formulario de seguridad de datos (Play) y App Privacy (Apple) | 📋 En la consola | El doc 20 (línea 3) ya trae la respuesta correcta: hay permisos de red por las librerías de Firebase, pero con `ENX_BACKEND=none` no se envían datos. No hay SDK de anuncios, analítica ni crashes en `pubspec.yaml` |
| Permisos justificados | ✅ | Los de red (`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, etc.) los agrega Firebase. Ninguno de cámara, ubicación o contactos |
| Privacy Manifest de iOS | ✅ archivo · ⏳ target | `app/ios/Runner/PrivacyInfo.xcprivacy` existe. Hay que confirmar que el build de CI lo incluye en el target |
| Cifrado (export compliance) | ✅ | `ITSAppUsesNonExemptEncryption = false` en `Info.plist` |
| Clasificación por edad | 📋 | Decidido: 13 o más, víctima con † y sin sangre. Ya se puede responder IARC y el cuestionario de Apple |
| Pantallas simuladas fuera de la versión de tienda | ⚠️ **NOT ASSESSED** | Decisión 18 (06-11-2026): sin tienda, premium ni ranking simulados. El código lo apunta (`dev_tools.dart:13`: "la versión de tienda NO muestra pantallas ni datos" de desarrollo), pero los textos `uiDemo` y `uiDemoNotice` siguen en el `.arb`. Hay que **mirarlo en la versión instalada desde Play** antes de pasar a la prueba cerrada |
| Compras dentro de la app | N/A | No hay compras ni anuncios en la V1 |
| Controles táctiles en varios tamaños | ⚠️ Sin probar | Ver el informe de UX: casillas de 9×9 posiblemente por debajo de 48 dp |
| Android 16 de borde a borde y pantallas grandes | ⏳ | Doc 20, línea 44: sin constancia de prueba |
| Prueba cerrada de 12 probadores por 14 días (Play) | ⏳ | Depende de la fecha de creación de la cuenta **del amigo**. Si es posterior al 13-11-2023, es obligatoria antes de producción. Hay que confirmarlo en Play Console |
| Notas para el revisor de Apple | ⏳ | Explicar que funciona sin cuenta y sin conexión, y que el servidor está apagado |
| Tamaño de la app | Sin medir | Apuntarlo del `.aab` y del `.ipa` |

### Riesgo de revisión: el nombre "Murdoku"

El ADR-0017 (línea 46) registra que se le avisó a Alejandro que "Murdoku" es el nombre de una serie de libros y de una app existente en la App Store, y que él decidió usarlo. No se reabre esa decisión. Solo queda anotado como **riesgo de rechazo o reclamo en la revisión pública**. Aplican las reglas de Apple contra apps parecidas o que usan nombres de terceros y la política de suplantación de Google Play, sobre todo porque `murdoku.com` es la referencia jugable del propio proyecto. La prueba interna de Play no pasa por revisión de contenido, así que este riesgo aparece recién en la prueba cerrada, en producción o en TestFlight externo.

## Tienda y distribución

- [ ] Título, descripción corta y descripción larga: sin redactar (doc 20, línea 38).
- [ ] Capturas y gráfico de funciones. Ya hay dirección visual (ADR-0013), así que se pueden capturar. Pendiente.
- [ ] Icono de 512 px para Play y revisión de que el de 1024 px no tenga transparencia (Apple).
- [x] Precio: gratis, sin compras.

## Preparación del lanzamiento

- [ ] Reporte de fallos (crashes). No hay Crashlytics ni equivalente en `pubspec.yaml`. Para una V1 pequeña bastan las estadísticas de fallos de Play Console y de App Store Connect, que no requieren SDK. Es recomendado, no bloquea.
- [ ] Plan de vuelta atrás. Play permite detener el despliegue y subir otra versión con un número mayor. Hay que anotarlo en la guía.
- [ ] Respaldo de la llave de subida de Android (doc 20, condición 4, H-05). **No hay constancia de que se haya hecho.** Con Play App Signing, una llave de subida perdida se puede cambiar pidiéndolo a Google, así que no impide publicar, pero sí retrasa una actualización urgente. Es recomendado.

## Go / No-Go: **NOT READY**

**Para la prueba interna de Play (A):** ya está publicada y puede seguir. Esta lista no la frena.

**Para la prueba cerrada o producción en Play y la revisión de Apple (B): NOT READY.** Bloquean:

1. **Política de privacidad:** completar los datos que faltan, decidir quién es el responsable (Alejandro o el dueño de la cuenta, punto 2) y publicarla en una URL. Unas 2 horas, más la decisión.
2. **Decisión de Alejandro: responsable legal y comerciante (DSA).** Con la app en la cuenta de un amigo, el doc 20 y la política suponen otra cosa.
3. **Enlace a la política dentro de la app** (Configuración → "Política de privacidad"). Es un cambio pequeño de código y requisito de Apple. Unas 2 horas.
4. **Confirmar en el teléfono que la versión de tienda no muestra pantallas simuladas** (decisión 18). Si alguna aparece, hay que quitarla.

**Sin evaluar (no cuentan como aprobados):** el registro de bugs, los resultados de pruebas de esta revisión, el rendimiento en gama baja, la alineación de 16 KB y Android 16.

**Documentación vieja que conviene corregir** (no bloquea): el doc 20 todavía dice `com.enigmatrix.app` y "Enigmatrix" en iOS, que "iOS nunca se ha compilado", que el iPhone está "pendiente, pregunta 22" y que "hoy no se puede subir nada". Todo eso cambió entre el 09-11 y el 11-11.

## Firmas requeridas

Con rigor `minimal` y un solo responsable, la firma es de **Alejandro** como dueño del producto. Los roles de la plantilla (QA Lead, Technical Director, Producer y Creative Director) no aplican a este equipo.

## Siguiente paso, cuando se resuelva lo anterior

`/gate-check release` lee esta lista. Después vienen `/launch-checklist` y `/team-release`. Con rigor `minimal`, `/gate-check` es opcional: la etapa no avanza sola.

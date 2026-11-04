# Anexo: los 71 hallazgos confirmados de la auditoría

Fecha: 04-11-2026. Este anexo acompaña a `2026-11-04-auditoria-proyecto.md`. Lo generé automáticamente a partir del resultado de la auditoría, sin reescribir el texto de los revisores, para que sea fiel a lo que encontraron.

**Cómo leerlo:**
- **Gravedad**: la que dejó el verificador independiente después de comprobar la evidencia. Si la cambió, entre paréntesis aparece la que propuso el revisor.
- **Esfuerzo**: estimación del revisor.
- **Decisión tuya**: indica si el arreglo necesita que decidas algo de producto o de dinero.
- **Nota del verificador**: correcciones a las citas o matices que agregó quien comprobó el hallazgo.

Recuento por gravedad ajustada: Crítica 0, Alta 11, Media 38, Baja 22.

## Respaldo, repositorio y entorno

### H-01. Sin respaldo remoto ni automatización: el proyecto vive solo en este PC y en OneDrive y los tests solo corren si alguien se acuerda

Gravedad: **Alta (revisor: crítica)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `higiene_repo-1`

- **Problema:** El historial completo no está en ningún servidor git; OneDrive no es respaldo de repositorios y puede corromper .git. Además la calidad depende de que Claude recuerde correr los tests antes de cada entrega.
- **Impacto:** Si el disco falla, OneDrive se desincroniza o se borra la carpeta se pierden casi cuatro meses de trabajo e historial; un cambio que rompa reglas o pantallas llega al teléfono sin detectarse.
- **Evidencia:** ['git remote -v vacío, solo rama main, sin tags; 39 commits locales, el último del 12-07-2026; el .git (761 objetos sueltos, sin packs) vive en D:/OneDrive/... con espacios en la ruta; git fsck limpio hoy.', "No existe .github/ ni CI aunque docs/07:466 planea 'CI por cada push'; COMPILAR-ANDROID.bat y PUBLICAR-PLAYSTORE.bat hacen flutter build sin analyze ni test."]
- **Sugerencia:** Crear un repositorio privado en GitHub y hacer push de main (Alejandro crea el repo y autoriza; Claude prepara los comandos); añadir un workflow mínimo de GitHub Actions (dart test en tools/, flutter analyze y flutter test en app/); mientras tanto un VERIFICAR.bat llamado desde los .bat de compilación que se detenga si algo falla; a mediano plazo sacar la carpeta de trabajo de OneDrive.

### H-02. Trabajo de reestructuración de agentes sin commitear y con índice de git mezclado

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `higiene_repo-2`

- **Problema:** La reestructuración del 01-11-2026 existe solo en disco; hay un cambio parcialmente preparado y .claude/settings.json (modelo y ocultar agentes de BBVA) nunca pasó por git.
- **Impacto:** Un git checkout/restore mal puesto o un conflicto de OneDrive puede deshacerla sin aviso y no se puede volver atrás si un agente se equivoca.
- **Evidencia:** ["git status: 'D  .claude/agents/arquitecto.md' ya en el índice junto con ' M' en backend.md, frontend.md, puzzle-engineer.md, qa.md, seguridad.md y CLAUDE.md.", 'Sin seguimiento: contenido-puzzles.md, ejecutor-pruebas.md, revisor-docs.md, .claude/settings.json y production/revisiones/ (JSON de 325 KB con la investigación gráfica); git diff --stat: 70 inserciones y 10 borrados en 6 archivos.']
- **Sugerencia:** Hacer un commit único de reestructuración (agentes + CLAUDE.md + settings.json); decidir si production/revisiones/ se versiona o ignora (volcado grande salida de otro equipo); commit y push los decide Alejandro (CLAUDE.md lo reserva al arquitecto).

### H-03. 1,4 GB de archivos generados dentro de una carpeta sincronizada por OneDrive

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `higiene_repo-4`

- **Problema:** Cada flutter build reescribe miles de archivos que OneDrive intenta sincronizar, con tráfico, lentitud, bloqueos durante builds y riesgo de conflictos en .git.
- **Impacto:** Builds lentos o con errores de archivo bloqueado, cuota de OneDrive consumida y riesgo adicional para el .git.
- **Evidencia:** ['du: app 1,3 GB (app/build 1,2 GB, app/.dart_tool 150 MB, app/android/.gradle 8,8 MB); tools/.dart_tool 29 MB; lo versionado pesa ~4 MB y el resto es regenerable.']
- **Sugerencia:** Opción A: marcar app/build, app/.dart_tool, tools/.dart_tool y app/android/.gradle como 'no sincronizar' en OneDrive. Opción B: mover el repo a una ruta local sin espacios (p. ej. C:/dev/enigmatrix) usando GitHub como sincronización; los .bat usan %~dp0 y la ruta fija de launch.json se corrige a mano.

### H-04. Menores de dependencias y entorno: SDK distintos, test que escribe iconos, saltos de línea y objetos sueltos

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `higiene_repo-11`

- **Problema:** Pequeñas sorpresas para el futuro Mac/iOS y la revisión de tiendas: SDK mínimos distintos, fuentes por red, test con efectos secundarios y saltos de línea cambiantes.
- **Impacto:** Bajo individualmente.
- **Evidencia:** ['app/pubspec.yaml sdk ^3.11.1 vs tools/pubspec.yaml ^3.5.0 para un paquete compartido por path; no se ejecutó pub outdated.', "enx_style.dart:9,102-122 y AndroidManifest:4 (INTERNET 'para descargar tipografías'); generate_icon_test.dart escribe PNG en assets/icon/ desde un test.", "Con autocrlf=true y sin .gitattributes aparecen avisos 'LF will be replaced by CRLF'; git count-objects: 761 sueltos, 0 packs, nunca git gc."]
- **Sugerencia:** Empaquetar fuentes o declararlo en la política, mover generate_icon_test.dart fuera de test/ o marcarlo con skip/tag, añadir .gitattributes con '* text=auto', alinear SDK mínimos, ejecutar git gc y correr flutter pub outdated.

## Seguridad, privacidad y tiendas

### H-05. Llave de firma de Android: respaldo sin resolver, contraseña junto al archivo en OneDrive y fallback silencioso a firma debug

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `seguridad_tiendas-1`

- **Problema:** La llave de subida y su contraseña viven en claro en la misma carpeta sincronizada y no hay copia independiente confirmada; además un .aab de publicación se genera igual, firmado con debug, si falta key.properties (por ejemplo en el Mac o tras reinstalar).
- **Impacto:** Perder la llave deja la app sin poder actualizarse o cuesta días de trámite; una filtración de OneDrive permite firmar versiones a nombre de Enigmatrix; un build mal firmado se detecta tarde, al subir.
- **Evidencia:** ["docs/20:11 'RESPALDAR ambos fuera del PC' sin marcar; app/android/upload-keystore.jks y key.properties (contraseñas en texto plano) están juntos, en una carpeta bajo D:/OneDrive; git remote vacío.", 'build.gradle.kts:54-58 \'else signingConfigs.getByName("debug")\' (comentario \'otra máquina\'); :44 cast \'as String\' truena críptico si key.properties está incompleto; PUBLICAR-PLAYSTORE.bat no comprueba la firma.', 'Con Play App Signing una llave de subida perdida se puede restablecer vía soporte; sin él la app no se puede actualizar nunca.']
- **Sugerencia:** Confirmar Play App Signing desde la primera subida; guardar el .jks en medio aparte (USB o bóveda cifrada) y contraseñas en un gestor, sacar ambos archivos de la carpeta sincronizada apuntando storeFile a ruta externa, probar la restauración y marcar el respaldo hecho en docs/20 solo entonces; que el build appbundle/release falle con mensaje claro si falta key.properties (debug solo para apk de pruebas) y que PUBLICAR verifique la firma con apksigner/keytool.

### H-06. Política de privacidad sin publicar, con responsable en blanco y sin enlace dentro de la app

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `seguridad_tiendas-4`

- **Problema:** Ambas tiendas piden la URL pública de la política y Apple exige enlace accesible dentro de la app (5.1.1(i)); hoy no hay URL, responsable ni botón para abrirla; Play la exige incluso sin recolección de datos.
- **Impacto:** Bloquea la ficha de Play y App Store Connect y el inicio de las pruebas cerradas; una política con corchetes visibles es motivo de rechazo.
- **Evidencia:** ["politica-privacidad.md:14-16 y 53 '[NOMBRE DEL RESPONSABLE]' y '[CORREO DE PRIVACIDAD]'; :5 'NOTA INTERNA (borrar al publicar)'; docs/20:19 ⏳; docs/15:183-184 correo y dirección pendientes.", "grep de 'rivacidad|rivacy|url_launcher' en app/lib y pubspec sin resultados; _ConfigSheet (home_shell.dart ~760-790) sin enlace."]
- **Sugerencia:** Decidir correo y dirección de contacto, publicarla en una URL (GitHub Pages), añadir en Configuración un botón 'Política de privacidad' (url_launcher), quitar la nota interna y mantener copia en inglés.

### H-07. google_fonts descarga tipografías en ejecución: la política dice 'sin datos' y el primer arranque offline sale sin la tipografía de marca

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: no · Origen: `seguridad_tiendas-5`

- **Problema:** Cada dispositivo contacta a Google en la primera apertura y la declaración de privacidad y Data Safety es inexacta; sin internet en esa primera apertura cae a la fuente por defecto con riesgo de desbordes.
- **Impacto:** Declaración inexacta en una política que se publicará y arranque sin red con aspecto roto; es lo único que justifica INTERNET en Fase 1.
- **Evidencia:** ['enx_style.dart:102,113,122 usa GoogleFonts.quicksand/baloo2/patrickHand; pubspec sin fuentes empaquetadas ni allowRuntimeFetching = false fuera de tests; AndroidManifest.xml:2-4 declara INTERNET solo para esto y Fase 2.', "politica-privacidad.md:35-36 'esa conexión no envía datos personales' y 20-25 'Ninguno'; LG München I (20-01-2022) trató la IP enviada a Google Fonts como dato personal.", "main.dart:50-51 y game_screen.dart:643 fallback 'Segoe Script' que no existe en Android ni iOS."]
- **Sugerencia:** Empaquetar Quicksand, Baloo 2 y Patrick Hand (OFL, documentando la prueba de licencia de docs/15:331-336) en assets declarados en pubspec, fijar GoogleFonts.config.allowRuntimeFetching = false, quitar INTERNET del manifest hasta Firebase, reemplazar 'Segoe Script' y simplificar política y Data Safety.
- **Nota del verificador:** google_fonts descarga las tipografías en la primera apertura. La política lo menciona, pero afirma que no se envían datos personales, y esa afirmación es discutible porque la IP llega a Google. Sin red en esa primera apertura se usa la fuente por defecto. Empaquetar las fuentes y quitar INTERNET hasta Fase 2 simplifica la política y la declaración de Data Safety.

### H-08. Identidad legal del desarrollador sin definir y su dirección se publicaría en las fichas de tienda de la UE

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `seguridad_tiendas-9`

- **Problema:** Con compras o suscripciones el desarrollador se considerará comerciante y los datos de contacto pueden hacerse públicos; para persona natural sería su domicilio. La política exige un responsable real.
- **Impacto:** Afecta la privacidad personal del dueño y bloquea política, ficha y registro de cuentas; nombre y contacto se fijan al registrarse.
- **Evidencia:** ["docs/15:177-184 persona natural con dirección pública pendiente y :402-411 puntos para abogado sin tocar desde julio; política :14 '[NOMBRE DEL RESPONSABLE — persona natural], Colombia'.", 'Apple exige estado de trader (DSA) con dirección, teléfono y correo públicos si es comerciante; Play tiene verificación equivalente (formato no confirmado).']
- **Sugerencia:** Presentar opciones con recomendación (persona natural con apartado postal u oficina alquilada, o constituir una SAS), decidir antes de crear las cuentas y confirmar con abogado.

### H-09. Edad mínima inconsistente (12+ vs menores de 13) y política legal con plantillas sin completar

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `seguridad_tiendas-6`

- **Problema:** Hay usuarios de 12 años dentro de la audiencia pero fuera de la regla de 13; 'mayores de 12' es ambiguo y la sugerencia de categoría Apple es imposible.
- **Impacto:** Declarar mal el público objetivo puede obligar a cumplir Familias/COPPA o corregir la ficha tras la revisión; política difícil de defender ante un abogado.
- **Evidencia:** ["docs/15:31 y 51: 'mayores de 12' y 'no dirigido a menores de 13'; política línea 40 'mayores de 12'; docs/20:18,45 'Everyone 10+/Teen' y '12+'.", "Apple reemplazó sus rangos por 4+, 9+, 13+, 16+ y 18+ (plazo 31-01-2026 vencido), por lo que la categoría '12 o superior' de docs/15:35 ya no existe.", "En Play, un usuario de 12 años cae en 'de 9 a 12', lo que activaría Familias y COPPA.", "politica-privacidad.md: '[NOMBRE DEL RESPONSABLE]' y '[CORREO DE PRIVACIDAD]' pendientes y solo en español (doc 07 prevé EN)."]
- **Sugerencia:** Decidir una sola edad mínima (13+ evita COPPA y Familias), reescribir docs 15, 20 y la política, declarar en Play grupos de 13 o más, esperar 13+ o inferior en Apple y actualizar docs/15:35. Completar responsable y correo antes de la primera prueba cerrada pública.
- **Nota del verificador:** Hay una ambigüedad de edad mínima (12+ en docs/15:31, docs/20:45 y la política:40, frente a 'menores de 13' en docs/15:51). Conviene fijar una sola edad (13+ evita COPPA y Familias) antes de rellenar el cuestionario IARC y declarar el público objetivo. Los marcadores pendientes de la política se tratan en el hallazgo 56.

### H-10. iOS nunca se ha compilado: el manifiesto de privacidad no está enlazado y falta validar el SDK obligatorio

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: no · Origen: `seguridad_tiendas-7`

- **Problema:** El archivo no tiene efecto fuera del proyecto de Xcode y pods, firma, Xcode 26 y Archive están sin probar; no hay constancia de que el Mac se haya usado.
- **Impacto:** Posible rechazo o advertencia (ITMS-91053) y descubrir problemas de iOS al final.
- **Evidencia:** ["project.pbxproj sin 'PrivacyInfo'; PrivacyInfo.xcprivacy:5-9 pide agregarlo al target Runner en el Mac; docs/20:33,38 ✅* y ⏳; sin Podfile ni Pods (se generan en el Mac); deployment target 13.0.", 'Desde 28-04-2026 App Store Connect solo acepta builds con Xcode 26 y SDK iOS 26; los manifiestos de shared_preferences y path_provider vienen en los paquetes.']
- **Sugerencia:** Compilar pronto en el Mac (flutter build ios, Xcode 26), agregar PrivacyInfo al target, revisar el Privacy Report al archivar y actualizar el manifiesto cuando Firebase aporte datos y APIs.
- **Nota del verificador:** El manifiesto de privacidad de iOS existe pero no está enlazado en el proyecto Xcode, y iOS nunca se ha compilado. Está documentado como pendiente para cuando se use el Mac, y es mejor compilar en iOS antes del final para descubrir problemas pronto.

### H-11. Checklist de tiendas con vacíos de consola y verificaciones de binario

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `seguridad_tiendas-11`

- **Problema:** El checklist omite requisitos de consola y comprobaciones de binario que aparecen al subir.
- **Impacto:** Sorpresas menores en la subida y la primera revisión.
- **Evidencia:** ["docs/20 sin filas para público objetivo (Play), notas para el revisor de Apple, trader/DSA, verificación de desarrollador de Google ni verificación del .aab; :14 'targetSdk reciente ✅' sin número ni método.", 'Play: fecha límite de 16 KB vencida (mayo 2026, prórroga no confirmada); Android 16 (API 36) obliga edge-to-edge e ignora bloqueo de orientación en pantallas grandes, sin evidencia de prueba con el .aab real.']
- **Sugerencia:** Añadir: validar el .aab con alineación ELF y el explorador de App Bundle, probar en emulador Android 16 con pantallas grandes, declaración de público objetivo y anuncios, notas para el revisor de Apple (modo sin cuentas), estado de trader y verificación de Google y número de targetSdk esperado.
- **Nota del verificador:** Es cierto que el checklist no tiene esas filas. Las exigencias de las tiendas (16 KB, edge-to-edge en Android 16, trader/DSA, verificación de desarrollador) son de fuentes externas y conviene confirmarlas en la documentación vigente antes de añadirlas. Es una mejora de checklist, no un defecto del proyecto.

### H-12. Requisitos de Apple para Fase 2 no previstos: Sign in with Apple y revocación al borrar cuenta

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `seguridad_tiendas-12`

- **Problema:** Con Firebase Auth y Google en iOS se necesitará Sign in with Apple o equivalente y revocar el token de Apple al borrar la cuenta.
- **Impacto:** Rechazo en iOS al llegar la Fase 2 si no se prevé.
- **Evidencia:** ['docs/15:225-227 registro con email y login con Google sin alternativa de Apple; :372-387 eliminación de cuenta con reautenticación y soft delete pero sin revocación de tokens de terceros.', 'Apple 4.8 y 5.1.1(v); la regla de contenido generado con IA no aplica hoy.']
- **Sugerencia:** Añadir ambos puntos a docs/15 y al alcance de Fase 2.
- **Nota del verificador:** Cita ajustada a docs/15-legal.md:225-226 para el registro y el login con Google, y 372-387 para el borrado de cuenta. Es un requisito de Fase 2 sin previsión en la documentación. No afecta a la Fase 1.

## Reglas del proyecto, agentes y memoria

### H-13. Claude Code se abre en la carpeta padre: el CLAUDE.md y los agentes del proyecto no se cargan solos

Gravedad: **Alta** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `reglas-1`

- **Problema:** Claude Code carga CLAUDE.md y .claude/agents/ de la carpeta donde se abre. Abierto en la carpeta padre, no están las reglas del proyecto ni los 6 agentes; solo llegan las instrucciones globales y la memoria. La memoria además cuelga de la carpeta padre.
- **Impacto:** Las sesiones arrancan sin las reglas innegociables, sin la instrucción de leer active.md y sin los agentes. Es la razón principal por la que el sistema de agentes parece no funcionar.
- **Evidencia:** ["En la sesión actual 1382 registros tienen cwd = carpeta padre 'Proyecto Enigmatrix' y solo 33 tienen cwd = 'Enigmatrix version final Claude'; en la otra sesión 421 vs 90.", "El proyecto de memoria activo es 'D--OneDrive-...-Proyecto-Enigmatrix' (la carpeta padre), no el de 'version final Claude'.", "La carpeta padre no tiene CLAUDE.md ni agentes, solo .claude/launch.json; los 6 agentes y el CLAUDE.md están dentro de 'Enigmatrix version final Claude'."]
- **Sugerencia:** Opción A (recomendada): abrir siempre Claude Code en 'Enigmatrix version final Claude' (o mover el repo a una ruta propia como D:/Repositorios/Enigmatrix) y migrar la memoria a ese proyecto. Opción B: mantener la carpeta padre con un CLAUDE.md mínimo que apunte al proyecto y a active.md, y mover o copiar .claude/agents al nivel padre.
- **Nota del verificador:** Los agentes del proyecto son 8, no 6: backend, contenido-puzzles, ejecutor-pruebas, frontend, puzzle-engineer, qa, revisor-docs y seguridad. No existe un agente 'arquitecto' en el proyecto: ese rol lo hace la sesión principal, según la memoria.

### H-14. CLAUDE.md con afirmaciones obsoletas y reglas incumplidas sin excepción documentada

Gravedad: **Alta** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `reglas-3`

- **Problema:** CLAUDE.md es lo primero que se lee en cada sesión y mezcla la intención original del 10-06-2026 con la realidad de julio. Hay reglas 'innegociables' que hoy se incumplen sin excepción registrada y datos falsos sobre Claude Design y el stack.
- **Impacto:** Instrucciones contradictorias: un agente puede esperar mockups, usar Hive/intl, 'corregir' el riesgo aceptado de solución local o rehacer decisiones del dueño. La falta de i18n encarecerá la traducción.
- **Evidencia:** ['CLAUDE.md:22 dice que los mockups los hace el usuario con Claude Design; active.md: Claude Design abandonado, UI directo en Flutter, estilo Paper Craft.', "CLAUDE.md: 'Cache local: Hive o Isar' e 'i18n: intl + .arb' vs app/pubspec.yaml solo con shared_preferences, sin intl ni .arb y unos 130 Text() fijos en español.", "CLAUDE.md:38-40 'el cliente NUNCA recibe la solución' y 'valores nunca hardcodeados' sin mencionar la excepción de Fase 1 (solución local, mocks como mockLives=4 en home_shell.dart:20-26); backend/ está vacío.", "CLAUDE.md:96 'Fase actual: ver docs/17-roadmap.md', que dice Fase 0; la tabla de docs omite 18, 19, 20 y docs/legal."]
- **Sugerencia:** Con visto bueno de Alejandro, actualizar CLAUDE.md: quitar Claude Design y declarar Paper Craft + UI directa; añadir sección 'Excepciones vigentes de Fase 1' con fecha y expiración (solución local, pantallas DEMO, SharedPreferences, backend vacío); corregir el stack; decidir si i18n con .arb va ya o en Fase 4; actualizar la tabla de docs. Puede delegarse a revisor-docs con sección 'Estado real vs. objetivo'.
- **Nota del verificador:** La cita 'CLAUDE.md:96' es incorrecta: la regla sobre fase actual y no implementar fases futuras está en la línea 110. La tabla de docs está en la línea 60 aprox. La parte de la solución local no es un hallazgo nuevo, porque es riesgo aceptado. Lo reportable es que CLAUDE.md no documenta esa excepción.

### H-15. Roadmap desactualizado: dice Fase 0, casillas y cifras viejas, sin criterio de salida vigente de Fase 1

Gravedad: **Alta** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `reglas-4`

- **Problema:** El documento que debería decir dónde está el proyecto quedó en junio. Las decisiones de shell, monetización y ranking simulados y del Mundo 1 nunca se escribieron en él, y no hay criterio de salida actualizado de Fase 1.
- **Impacto:** Un agente nuevo creerá que está en Fase 0 y que shell, tienda DEMO y ranking DEMO son trabajo no autorizado. Alejandro no puede ver qué está terminado ni qué falta para abrir Fase 2.
- **Evidencia:** ["docs/17-roadmap.md:7 'Fase actual: FASE 0' vs active.md 'FASE 1 — EN CURSO'; CLAUDE.md remite al roadmap para saber la fase.", "docs/17: '[ ] Tutorial guiado' y '[ ] Versión Android' sin marcar, pero existen tutorial_coach.dart y APK/AAB compilados (commits 6cdd9f6, 561c11e, 28bbde9).", "docs/17: '38 tests', '9 tests' y casos 4x4/5x5/6x6 vs ~54-57 tests de motor, 26 de app y assets de 6/8/9.", "docs/17: 'Monetización pospuesta a Fase 3' y 'Campaña Mundo 1 en Fase 2' vs decisión del 12-07 (monetización simulada ya incluida; Mundo 1 como siguiente bloque local); 'No se arranca una fase sin cerrar la anterior'.", "active.md 'Preguntas abiertas' sigue pidiendo mockups de Claude Design; docs/17 '[~] Design System: UI definitiva cuando lleguen los mockups'."]
- **Sugerencia:** Reescribir el estado del roadmap proponiendo cambios antes de editar: fase actual real, marcar lo hecho, añadir 'Fase 1b: shell con datos simulados' (o sección 'Adelantado como simulación, aprobado 12-07-2026' con lo que falta para hacerlo real), actualizar cifras de tests y casos, redefinir el criterio de salida de Fase 1 y añadir 'Estado verificado a fecha X' que se actualice en cada hito. Limpiar las preguntas abiertas de active.md.

### H-16. active.md desordenado, con planes obsoletos y sin los últimos commits: no sirve para retomar

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: no · Origen: `reglas-6`

- **Problema:** La bitácora acumuló todo sin compactar; mezcla estado actual, historial y planes, con entradas faltantes y pendientes cerrados. Tras casi 4 meses sin actividad (último trabajo 12-07-2026) retomar depende de este archivo.
- **Impacto:** Un agente puede repetir trabajo (volver a planear navegación ya entregada) o pedir mockups innecesarios; Alejandro no puede leer el estado de un vistazo.
- **Evidencia:** ["production/session-state/active.md ~16.8 KB con párrafos de 800-1500 caracteres; la cabecera 'Fase actual' contiene todo el historial.", "Orden roto: 'LOGO + SPLASH (86f5925)' va primero pero es anterior al shell (f6f2d1d), UX v2 (0bde190) e icono (54dced2).", "'PLAN DEL PRÓXIMO BLOQUE' lista navegación inferior, tienda simulada e icono como pendientes ya entregados; 'Preguntas abiertas' incluye mockups de Claude Design y tutorial 4×4, ya resueltos.", 'git log: faltan 6cdd9f6, c6140c9 (tutorial jugable), 9b7e768 y 84835be (tarjetas de pistas compactas).', "Conteo de tests inconsistente (24, 25, 26, 38, 57-60); la sección 'El motor (tools/)' sigue en '38 tests' y '3 mapas 4×4-6×6'."]
- **Sugerencia:** Reestructurar en: (1) 'Estado hoy' en ~10 líneas (fase, qué corre, qué falta, próximos 3 pasos, preguntas vigentes); (2) decisiones vigentes con fecha y enlace a ADR; (3) historial archivado en production/session-state/historial.md sin perder nada. Reconciliar commits no registrados, cerrar pendientes resueltos, usar dd-mm-yyyy y actualizar 'Estado hoy' en cada hito. Tarea para sonnet con revisión del arquitecto.

### H-17. Decisiones grandes sin ADR: solo existen 2 del 10-06-2026 y el stack de CLAUDE.md no coincide

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `reglas-9`

- **Problema:** El porqué de las decisiones y las alternativas descartadas viven en párrafos de bitácora que se compacta; el ADR existente no refleja la realidad ni cuándo caducan las excepciones.
- **Impacto:** Se pierde el razonamiento, es fácil revertir sin querer decisiones del dueño, favorece repetir ciclos de rediseño y riesgo de perder información al reestructurar active.md.
- **Evidencia:** ['docs/adr/ solo tiene 0001-stack-flutter-firebase, 0002-estado-riverpod y template; CLAUDE.md:41 exige ADR para toda decisión significativa.', 'active.md registra sin ADR: Paper Craft (561c11e), abandono de Claude Design, mapas procedurales y tamaños 6/8/9/12/16 (954a3fd), rediseño Murdoku de pistas (6af707a), shell con datos quemados y monetización simulada, Firebase pospuesto, solución en JSON local (solo en doc 18), tutorial jugable, SharedPreferences en lugar de Hive/Isar.', "docs/17:111 'Decidir en Fase 2: IA generativa vs comisión (ADR)' sigue abierto.", "CLAUDE.md dice 'Hive o Isar' y 'Tablero: CustomPainter' mientras pubspec usa shared_preferences y el tablero real son widgets por celda."]
- **Sugerencia:** Escribir 5-9 ADR cortos y retroactivos con fecha real: mapas procedurales + tamaños; vocabulario de pistas Murdoku; estilo visual (Paper Craft, reemplazable según la investigación gráfica); abandono de Claude Design y UI directa; mocks-primero + monetización simulada DEMO con condición de salida; riesgo aceptado de solución local con caducidad en Fase 2; almacenamiento local y tipografías; aplazamiento de Firebase. Dejar abierto el de fuente del arte y uno nuevo de herramientas gráficas. Actualizar tabla de stack de CLAUDE.md. Tarea para sonnet con revisión del arquitecto antes de reestructurar active.md.
- **Nota del verificador:** Lo comprobable: faltan ADR retroactivos de las decisiones de active.md y la tabla de stack de CLAUDE.md (Hive/Isar, CustomPainter, mockups de Claude Design) no coincide con el código. Algunas decisiones citadas (monetización DEMO, Firebase pospuesto) sí están documentadas en active.md y docs, solo no como ADR.

### H-18. El acuerdo de simular pantallas de fases futuras no está escrito como excepción y la regla 'no adelantar fases' queda ambigua

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `reglas-5`

- **Problema:** El acuerdo existe pero no está redactado en CLAUDE.md ni en el roadmap. Sin una excepción escrita, un agente puede objetar o tratar los mocks como funcionalidad real. Además ~800 líneas de simulaciones se construyeron antes de fijar la dirección visual y sin fecha de reemplazo, con riesgo de scope creep.
- **Impacto:** Ambigüedad sobre qué se permite simular y qué sigue prohibido (cobros reales, validación de servidor, ranking real). Si se rehace lo gráfico, estas pantallas se reescribirán casi con seguridad y dan falsa sensación de producto avanzado.
- **Evidencia:** ["CLAUDE.md:96 'No implementar features de fases futuras sin acuerdo explícito'.", "active.md: decisión del usuario (AskUserQuestion) 'pantallas completas PRIMERO con datos locales simulados... monetización INCLUIDA ya simulada'; el acuerdo vive solo en la bitácora.", 'home_shell.dart (784 líneas): Inicio, Mundos, Reto, Ranking, Perfil, Tienda y Premium con datos quemados (:20-27 mockLives, mockStreak, mockWeeklyPoints, mockBots), etiqueta DEMO en :178, precios en :702-707.', 'docs/17:50-81 ubica reto diario, ranking, vidas, tienda y premium en Fases 2 y 3.']
- **Sugerencia:** Redactar en CLAUDE.md: 'Se permiten pantallas de fases futuras solo como simulación local, etiquetadas DEMO, con datos aislados detrás de repositorios; sin pagos ni lógica oficial hasta su fase'. Registrarlo en el roadmap y en un ADR con condición de salida. Conservarlas como maqueta navegable sin invertir más hasta tener sistema visual nuevo; si se quiere lógica local real, hacerla detrás de repositorios y con valores de un archivo de configuración. Añadir checklist/test que verifique la etiqueta DEMO.
- **Nota del verificador:** Reducir a una recomendación de documentación: registrar el acuerdo de simular pantallas como excepción en CLAUDE.md y en el roadmap. La afirmación de 'riesgo de scope creep' y de reescritura casi segura es especulativa. Conviene fusionarlo con el 3 o el 4.

### H-19. Contenido de los agentes desactualizado y sin agente de diseño visual/UX

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `reglas-8`

- **Problema:** Los agentes se escribieron el 10-06-2026, antes de las decisiones de estilo, y apuntan a un Design System que ya no manda. Nadie es responsable de la calidad visual y de experiencia, justo lo que Alejandro dice que falla.
- **Impacto:** Decisiones con referencias viejas; la ausencia de un dueño del diseño explica parte de por qué la UI 'no parece un juego'; backend y seguridad ocupan espacio de decisión estando inactivos.
- **Evidencia:** ["frontend.md: contexto 'docs/10-arte.md + Design System Standalone.html' y tokens del Design System; la identidad actual es Paper Craft con tokens en app/lib/src/ui/enx_style.dart.", "frontend.md regla 2 'todo string en .arb' vs ~130 Text() fijos y sin intl; frontend y qa exigen screenshots, pero active.md dice que el Browser pane no renderiza Flutter.", 'backend.md y seguridad.md describen Fase 2 (Cloud Functions, reglas Firestore) con backend/ vacío.', 'Solapes: arquitecto/puzzle-engineer comparten spec 16, seguridad/backend reglas Firestore, qa/puzzle-engineer tests del motor; ningún agente es dueño de dirección de arte, game feel, UX ni narrativa (docs 12 y 13).', 'Claude-Code-Game-Studios/.claude/agents tiene 49 agentes de referencia; el proyecto usa 6.']
- **Sugerencia:** Actualizar frontend (contexto enx_style.dart, Paper Craft, sin screenshots automáticos). Añadir un agente único de dirección de arte/UX y game feel en modelo medio-alto, alimentado por la investigación gráfica. Marcar backend/seguridad como 'Fase 2, inactivos'. Fijar dueño de cada documento (spec 16 = puzzle-engineer, reglas Firestore = seguridad).
- **Nota del verificador:** Versión corregida: frontend.md tiene una regla de i18n (.arb) que el código no cumple y referencias residuales al Design System y a mockups y screenshots que ya no aplican. Marcar backend/seguridad como inactivos hasta Fase 2. Crear un agente de arte/UX queda a la espera de la investigación gráfica en curso.

### H-20. La memoria persistente está desactualizada, es un log y existe duplicada en otra carpeta

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: no · Origen: `reglas-10`

- **Problema:** La memoria se carga en cada sesión pero contiene un resumen viejo, redundante con active.md y con un dato clave falso; hay una segunda memoria que afirma que CCGS es la base.
- **Impacto:** Cada sesión recibe un resumen inexacto que contradice CLAUDE.md; el log de la memoria compite con active.md como fuente de verdad.
- **Evidencia:** ["MEMORY.md habla de 'gap crítico: spec formal del puzzle' (la spec 16 existe desde 10-06-2026) y 'CCGS son clones vírgenes'.", "enigmatrix-estado-proyecto.md (8.9 KB): description 'al 2026-06-10' pero cuerpo en log hasta 12-07; no menciona shell, mocks DEMO, tutorial jugable, keystore ni Mundo 1 pendiente.", "~/.claude/projects/D--OneDrive-...-Enigmatrix---claude/memory/project_enigmatrix.md: otra memoria con 'CCGS system in /Enigmatrix subfolder' (obsoleta).", 'Mezcla estado transitorio (commits, tests) con hechos estables ya presentes en active.md.']
- **Sugerencia:** Reducir la memoria a hechos estables: quién es Alejandro y cómo trabaja, fuente de verdad (carpeta del proyecto y active.md), carpetas obsoletas y estilo vigente. Mover el log a active.md/ADR y archivar la memoria duplicada, con la habilidad de consolidar memoria y confirmación de Alejandro.
- **Nota del verificador:** Versión corregida: el índice MEMORY.md está al día, pero el archivo enigmatrix-estado-proyecto.md es un log extenso que repite active.md y quedó atrás respecto a las últimas decisiones; además hay memorias duplicadas/obsoletas en carpetas de proyecto viejas. Candidata a consolidar con la habilidad consolidate-memory, con confirmación de Alejandro.

### H-21. Carpetas hermanas viejas y artefactos de direcciones abandonadas confunden y pueden cargar contexto equivocado

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `reglas-11`

- **Problema:** Cuatro carpetas hermanas con nombres parecidos y contenido solapado, más material de Claude Design y mockups descartados mezclado con la fuente de verdad. No queda claro cuál es el diseño vigente ni cuál banco de casos se edita.
- **Impacto:** Riesgo de editar la copia equivocada, que un agente lea documentos antiguos, replique el estilo oscuro-dorado o espere mockups que no llegarán; al regenerar casos puede quedar un banco desincronizado.
- **Evidencia:** ["Carpeta padre: Claude-Code-Game-Studios (5.9 MB, .git, CLAUDE.md propio y 49 agentes), 'Enigmatrix - claude' (8 MB, copia del template y docs de mayo), 'Enigmatrix' (52 KB, docs de abril) y la carpeta de trabajo; la memoria las describe como clones vírgenes de solo lectura.", 'Abrir una por error carga su propio CLAUDE.md y agentes.', 'docs/Enigmatrix Design System - Standalone.html (1.9 MB, rastreado, sin referencias), docs/mockups/01-inicio.html (oscuro dorado) y docs/mockups/estilos/ (6 estilos), production/fase0-casos/; los casos viven en tres lugares (tools/out, app/assets/cases y txt de Fase 0) sin flujo documentado.', 'CLAUDE.md:22 y doc 06 siguen hablando de mockups como insumo futuro tras abandonar Claude Design.']
- **Sugerencia:** Mover las tres carpetas viejas a '_archivo' (no borrar) o fuera de OneDrive, con un README de una línea. Mover el Design System HTML, los mockups y production/fase0-casos a docs/archivo/ o marcarlos SUPERADO en el índice. Corregir CLAUDE.md (mockups, Hive/Isar, lista de docs) y documentar en doc 05 el flujo tools/out a app/assets/cases. Decidir con Alejandro si se conserva el Design System solo como referencia histórica.
- **Nota del verificador:** Matiz: CLAUDE.md:85 ya advierte de las carpetas hermanas, así que el riesgo está parcialmente mitigado. Lo pendiente es limpieza: archivar hermanas, marcar el Design System HTML y los mockups como superados, corregir CLAUDE.md:22 y documentar el flujo tools/out a app/assets/cases.

## Roadmap y orden de fases

### H-22. El criterio de salida de Fase 1 (loop divertido y dificultad justa) nunca se midió; falta playtest formal

Gravedad: **Alta** · Esfuerzo: medio · Decisión tuya: sí · Origen: `roadmap-2`

- **Problema:** El criterio mide la pregunta más importante (¿es divertido y justo?) pero el trabajo giró en torno a la apariencia; la apuesta de Fase 0 tampoco tiene validación humana registrada.
- **Impacto:** Se construye MVP, tienda e identidad visual sobre una hipótesis no comprobada; si dificultad o duración fallan, se desperdicia arte.
- **Evidencia:** ["docs/17:48 'el usuario juega 10 casos y el loop se siente bien'; docs/17:24 'pendiente que el usuario juegue algunos en papel y valide'.", "active.md: rondas de feedback sobre UI/layout sin registro de 'jugó N casos, dificultad justa'; pregunta abierta 'Jugar 2-3 casos en papel'.", 'git log: 39 commits (10-06 a 12-07-2026); desde el 11-07 casi todo son rediseños de UI; último trabajo 12-07-2026, hoy noviembre de 2026.']
- **Sugerencia:** Definir un playtest formal antes de invertir en arte final: 5-10 casos por Alejandro y 3-5 personas externas, con registro mínimo (tiempo por caso, errores, abandonos, '¿lo volverías a jugar mañana?') y umbrales verificables (p. ej. 70% completa el caso 3 sin ayuda; tiempo de principiante en el rango del doc 08), documentado en archivo propio.
- **Nota del verificador:** El criterio de salida de Fase 1 (10 casos jugados, loop divertido, dificultad justa) y la validación en papel de Fase 0 no tienen registro de cumplimiento. La app ya tiene instrumentación de playtest (cronómetro, errores, feedback exportable) que no se ha usado de forma sistemática; los ciclos de feedback documentados tratan de UI. Recomendar un playtest con umbrales verificables antes de invertir en arte final.

### H-23. El orden de fases no contempla dirección de arte, validación del loop ni contenido antes de servidor: propuesta de reestructuración

Gravedad: **Media (revisor: alta)** · Esfuerzo: alto · Decisión tuya: sí · Origen: `roadmap-4`

- **Problema:** La decisión de pipeline de arte queda para Fase 2 y el arte para Fase 4, pero la queja es que el juego no se ve ni se siente como juego; no hay documento rector estable de dirección visual y las fases carecen de fechas y topes de esfuerzo.
- **Impacto:** Si se construye Firebase, ranking y mundos antes de fijar el sistema visual, las pantallas se rehacen; sin reordenar el nuevo trabajo gráfico se hará en una 'Fase 1' abierta indefinidamente.
- **Evidencia:** ["docs/17:43 '[~] Design System: UI definitiva cuando lleguen los mockups' (mockups abandonados), :111 decidir arte en Fase 2, :85 arte y mundos 2-5 en Fase 4; Fase 2 (docs/17:50-67) mezcla Auth, Firestore, Functions, reto diario, ranking, campaña, anti-trampa y reglas de seguridad.", 'active.md: 5 cambios de estilo en ~10 meses (dorado, Duo, Enx, muebles cartoon, Paper Craft); board_view.dart (608) y furniture_painters.dart (422) son arte procedural en código, app/assets solo tiene cases/ e icon/.', "doc 12 (audio, animación, haptics) sin fase asignada; docs/10 'cartoon limpio' vs Paper Craft."]
- **Sugerencia:** Fase 1A cerrar 'Loop validado' (playtest con umbrales: 10 casos por ≥4 personas, ≥70% termina el caso 3 sin ayuda). Fase 1B nueva 'Dirección de arte + vertical slice': biblia de arte única, ADR de pipeline de assets/animación/audio (Flame/Rive/shaders, ilustración, IA curada o kit), audio/haptics mínimos y UN caso con acabado final; salida: test de impresión de 10 s con 5 personas ajenas y aprobación escrita del estilo congelado. Fase 1C 'Contenido base': spike 12×12/16×16, Mundo 1 de 10 casos verificados. Fase 2A Firebase mínimo (Auth + validación en Cloud Function + casos sin solución en el cliente, auditoría de seguridad). Fase 2B reto/ranking diario/racha con 2 semanas de testers. Fase 3 economía con validación de recibos. Fase 4 mundos 2-5, EN, accesibilidad, analítica, lanzamiento. Cada fase con fecha estimada y tope de esfuerzo.
- **Nota del verificador:** El roadmap (docs/17) quedó desactualizado frente a las decisiones recientes: sigue esperando 'mockups' que se abandonaron, difiere el pipeline de arte a Fase 2 y el arte a Fase 4, no asigna fase a audio/animación (docs/12), y docs/10 ('cartoon limpio') contradice el estilo Paper Craft elegido. Hubo ~5 cambios de estilo visual en aproximadamente un mes (11-06 a 12-07-2026), no en 10 meses. Sugerencia: antes de Firebase, fijar dirección de arte y un vertical slice, y actualizar docs 10/12/17; el reordenamiento detallado de sub-fases es una propuesta para decidir con Alejandro.

### H-24. La Fase 2 es demasiado grande y 'MVP publicable' no incluye los trámites de tienda (12 testers x 14 días, iOS, cuentas)

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `roadmap-7`

- **Problema:** El roadmap llama publicable a un hito que no es publicación y omite los trámites obligatorios; un MVP con campaña, reto, ranking y vidas abarca realmente Fases 2 y 3. El reloj de 14 días no ha empezado y no se puede acelerar.
- **Impacto:** Calendario irreal, bloqueos de tienda descubiertos al final y al menos 14 días de retraso (más si algún tester se sale).
- **Evidencia:** ["docs/17:50 'Fase 2: MVP mínimo publicable' con 10 entregables y criterio 'testing interno 2 semanas' (:67); docs/17:96 iOS 'fuera de roadmap' pese a proyecto iOS generado y Mac disponible.", 'docs/20:24 pruebas cerradas 12 testers × 14 días (📋) y cuenta developer US$25 pendiente; docs/15 figura persona natural; Data Safety cambia al entrar Firebase.', 'Play: cuentas personales posteriores al 13-11-2023 requieren ≥12 testers inscritos de forma continua 14 días (organizaciones con D-U-N-S exentas); fuentes comerciales mencionan controles en 2026 sin confirmar oficialmente.']
- **Sugerencia:** Definir 'MVP publicable' (Mundo 1 + reto + ranking diario + cuentas + validación en servidor + política y ficha listas) y adelantar en paralelo cuenta developer, 12 testers (15-20 con margen) y política alojada, arrancando la prueba cerrada con un build estable aun en Fase 1; decidir ya si iOS entra al lanzamiento; verificar la regla vigente en Play Console.
- **Nota del verificador:** El roadmap llama 'publicable' a la Fase 2 pero omite que, para una cuenta personal, Google Play exige pruebas cerradas con 12 testers durante 14 días (docs/20:24, aún sin iniciar) y la cuenta developer sigue pendiente. Conviene adelantar esos trámites en paralelo y definir qué incluye 'MVP publicable'. iOS está fuera de roadmap y el acceso a un Mac sigue siendo pregunta abierta (no confirmado). Verificar la regla vigente en Play Console.

## Documentos de producto (reglas del juego)

### H-25. Reglas de colocación y gesto principal: docs 02/03/06/11 describen otro juego y el gesto es poco descubrible

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_producto-2`

- **Problema:** Los docs de producto conservan el modelo de doble toque y la regla de convivencia contraria a la spec. Además el gesto de mantener oprimido es poco descubrible y puede confundirse con 'la app no responde', y no cumple la alternativa de accesibilidad exigida.
- **Impacto:** Diseñadores, QA y tutorial documentan o prueban reglas inexistentes; fricción en los primeros minutos del jugador; posible incumplimiento de doc 11.
- **Evidencia:** ['docs 02:204-205, 03:169-172,190-191 y 06 hablan de doble toque (tap 1 candidato con ?, tap 2 confirmado con flecha verde); spec 16 §4/§7 y game_controller.dart/board_view.dart:321-333: toque = candidato, mantener oprimido o arrastrar = confirmado.', "docs 03:202 y 02:216 'una entidad distinta coexiste' vs spec 16 §4 y board_state.dart: X y candidatos no conviven.", "Borrador y auto-X (EraserTool, autoXFrom) existen en spec y app, no en docs 02/03/06; docs 06 llama 'notas separadas/superpuestas' a lo que la app llama 'Mapa / Notas'.", "docs/11:93-94 acepta 'toque para seleccionar más toque para colocar' como alternativa al arrastre; en la app confirmar exige mantener presionado.", 'Tocar una casilla sin sospechoso elegido no da respuesta; la única explicación es un párrafo de 11 px gris (game_screen.dart:423-430).']
- **Sugerencia:** Hacer de spec 16 §4 la fuente única; reescribir 'Reglas de colocación' en docs 02, 03 y 06 apuntando a ella y documentar auto-X, borrador y el significado de Mapa/Notas. Mostrar un aviso ('Elige primero a un sospechoso') al tocar vacío y una pista la primera vez que se selecciona una tarjeta. Decidir si se añade un gesto alternativo (botón 'Confirmar') para cumplir doc 11.

### H-26. Vidas: no se define qué pasa con 0 vidas y hay contradicciones sobre premium y anuncios

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_producto-3`

- **Problema:** La regla que más condiciona economía y retención no está definida y premium tiene dos descripciones incompatibles.
- **Impacto:** Al implementar vidas locales se inventará la regla; una mala decisión viola el pilar 4 o deja al jugador atascado con el reloj corriendo.
- **Evidencia:** ["docs/01:200 premium 'sin límite de vidas' vs docs/08:217-218 'sin límite de 5 vidas activas' y recarga instantánea hasta el cap.", 'Ningún doc define qué ocurre con 0 vidas (si se puede pulsar Resolver, seguir jugando o esperar), con cronómetro oficial que no se detiene (doc 03).', "docs/08:192-193 intersticial tras cada caso y 'no aparece al terminar el tutorial después del primer caso' (ambiguo); docs 01 y 02 dicen anuncio tras el tutorial si no es premium.", "'Ver anuncio recarga vidas' sin cantidad ni límite (el límite de 3 por hora solo en doc 08); en la app las vidas son mock fijo (home_shell.dart:20)."]
- **Sugerencia:** Definir en doc 08: comportamiento con 0 vidas (bloquear solo Resolver y congelar o seguir el reloj), premium como tope fijo 5 con recarga instantánea o vidas infinitas, cantidad por anuncio y política de intersticial del tutorial; alinear docs 01, 02 y 03.

### H-27. Reto diario: 'día local' vs hora de servidor, calendario de dificultad imposible y el prototipo elige cualquier caso (incluido Principiante)

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_producto-4`

- **Problema:** No está decidido si el día del reto es local o de servidor, lo que rompe el cierre semanal y el ranking global. El calendario de dificultad no se puede cumplir con el contenido existente y el prototipo contradice la documentación y promete reglas que no se cumplen.
- **Impacto:** Riesgo de construir la Fase 2 sobre reglas contradictorias: tramposos por zona horaria, rachas rotas injustamente, rankings inconsistentes; testers y revisores de tienda confundidos por textos falsos.
- **Evidencia:** ["docs/03:395 'dentro del día local' vs docs/08:150-151 cierre semanal en hora del servidor, recomendado domingo 23:59 UTC; docs/17 Fase 2 'ventana por hora de servidor'.", "docs/08: semana 'Casual x2, Intermedio x3, Experto x1, Elite x1, sin Principiante'; app/assets/cases solo tiene 20 casos principiante/casual/intermedio, sin experto ni elite.", 'home_shell.dart:254-259 y :437-441: cases[day % cases.length] con DateTime.now() local y fecha base 01-01-2026, sin considerar dificultad; el 04-11-2026 daría caso-principiante-s8 y el mismo caso se repite cada 20 días.', "La tarjeta dice 'Un intento oficial · mismo caso para todos' y 'cierra a medianoche' sin insignia DEMO, aunque se puede rejugar sin límite."]
- **Sugerencia:** Decidir una sola regla de día (UTC o zona fija del servidor), con margen de tolerancia si aplica, y corregir doc 03. Hasta tener servidor, elegir el caso del día solo entre Casual e Intermedio según el calendario de doc 08 y marcar la tarjeta como DEMO o quitar las promesas ('un solo intento', 'mismo caso para todos').
- **Nota del verificador:** El hallazgo es válido. El bloque de gravedad real es la contradicción local vs servidor y que el prototipo promete 'un intento' y 'mismo caso para todos' sin cumplirlo. Como la Fase 1 es un prototipo con datos simulados, el impacto inmediato es bajo.

### H-28. Resolver: tablero incompleto sin documentar y el resaltado exacto de errores permite resolver por ensayo y error

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_producto-6`

- **Problema:** La regla de Resolver con tablero a medias es solo decisión de implementación, y marcar exactamente las casillas erróneas convierte cada pulsación en una pista gratuita.
- **Impacto:** En tableros pequeños el ensayo y error cuesta poco, debilitando el pilar 1 y el ranking; el servidor de Fase 2 podría tratar distinto los casos incompletos.
- **Evidencia:** ['game_controller.dart:304 devuelve incompleteBoard sin penalizar y game_screen.dart:86 muestra un snackbar; ningún doc cubre el caso.', 'game_controller.dart:321-331: al fallar, errorCells marca con exactitud cada casilla distinta de la solución y bloquea solo 3 s.', "docs/08: penalización de 5-20% y 5 vidas; docs/09 pilar 1 'Nunca se gana adivinando'."]
- **Sugerencia:** Documentar que Resolver incompleto no cuenta como error. Decidir si el resaltado es parcial (solo cuántas fallan, o solo en práctica y tutorial) o si el error cuesta más desde el 2.º intento. Simular el abuso con un bot en casos principiante.

### H-29. Tutorial: dos tutoriales saltables que no cumplen los docs, no enseñan mecánicas clave, consumen el Caso 1 y no tienen pruebas

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_producto-7`

- **Problema:** El jugador nuevo puede saltarse toda la enseñanza y llegar a un 6×6 real sin conocer los gestos, el error de Resolver ni las ayudas; la tarjeta puede tapar lo que explica, hay riesgo de saltar pasos y el progreso del Caso 1 queda distorsionado.
- **Impacto:** Es el momento de mayor pérdida de jugadores; el primer error de Resolver se vivirá como injusto (pilar 4); al reemplazar el banco por el Mundo 1 el tutorial dejará de apuntar a un caso fácil; el onboarding final se rehará con el nuevo sistema visual.
- **Evidencia:** ["Docs 01, 02 y 06: tutorial obligatorio, ambos modos de notas, error de Resolver, ayuda, modo preferido, desbloqueo de Mundo 1; tutorial_coach.dart tiene 7 pasos sin modos, error, ayudas, X manual ni borrador, con botón 'Saltar', y tutorial_dialog.dart 5 páginas con 'Omitir' (claves 'tutorial:seen' y 'tutorial:played').", "El diálogo termina en Inicio con '¡A investigar!' que solo cierra; Inicio dice 'Continuar investigando' con 0 casos; el tutorial jugable es un nodo en /casos y usa list.first (principiante-s1, 6×6 con 6 personajes), por lo que consume el Caso Nº1 (victory_screen.dart:26-33 guarda done: sin distinguir modo tutorial).", 'tutorial_coach.dart:102-108: la tarjeta (bottom:12) tapa pistas y controles mientras el paso 2 pide tocar una tarjeta; los pasos no bloquean acciones; :90-96 agenda addPostFrameCallback en cada build y puede saltar pasos; sin pruebas de TutorialCoach.', "spec 16:216 y active.md mantienen abierta '¿4×4 guiado o mecánica completa?'; tutorial:seen se guarda antes de mostrar el diálogo."]
- **Sugerencia:** Decidir si el tutorial es obligatorio (con Saltar) y su contenido; unificar los dos flujos (el último paso del diálogo ofrece 'Jugar el tutorial ahora' y en Inicio 'Empezar tutorial' para quien tiene 0 casos); crear un caso fijo 4×4 o 5×5 que no cuente como Caso Nº1 y unificar claves; añadir pasos para Mapa/Notas, X, papelera y un Resolver erróneo controlado; subir la tarjeta o resaltar en vez de tapar; proteger el avance con un flag y añadir un test de widget que recorra los 7 pasos; actualizar docs 02/06 y cerrar la pregunta de spec 16; diseñar el onboarding completo dentro del vertical slice y medirlo en el playtest.

### H-30. Ayudas, puntuación y rotación anti-trampa sin especificación técnica ni implementación (y sin decisión de aplazarlas)

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_producto-10`

- **Problema:** Tres sistemas centrales (ayudas, puntos, rotación) existen solo como reglas de producto; no hay forma de pedir una pista al atascarse y no se ha decidido explícitamente aplazarlos. Si las pistas sueltas son necesarias, el jugador que no abre la leyenda no puede resolver.
- **Impacto:** Ranking y monetización los necesitan y las ayudas pueden obligar a cambiar el motor; descubrirlo en Fase 3 es caro; sesiones cortas peor atendidas.
- **Evidencia:** ['docs/03 define 5 ayudas y docs/08 sus costos (5-30%); spec 16 no define cómo se calcula ninguna ni qué paso del DeductionEngine corresponde; docs/06 pantallas 19, 23 y 28 piden botón de ayudas, ayudas usadas y puntos estimados.', "game_screen.dart _Header solo muestra tiempo y errores; victory_screen.dart:191-206 solo Tiempo y Errores (docs/02 incluye puntuación, posición, mejor marca y compartir); sin 'ayuda', 'puntos' ni 'rota' en el código.", 'docs 03/01: orientaciones 0/90/180/270 por jugador y por mapa sin implementación ni estudio en 16×16.', "Pantalla 16 (previa del mapa con aviso de intento oficial) reducida a una hoja con chips (case_list_screen.dart:624-699); la 'Información adicional' queda tras el icono de libro; las ayudas no figuran en 'PENDIENTE PRÓXIMO' de active.md."]
- **Sugerencia:** Escribir un anexo en spec 16 con el algoritmo de cada ayuda, fórmula de puntos con ejemplo numérico y diseño de la rotación; decidir con Alejandro qué ayudas existen en V1 (doc 08); implementar puntos y ayudas locales en Fase 1 para calibrar con playtest; mostrar las pistas sueltas en una tarjeta visible; anotar en active.md qué piezas de las pantallas 16, 19, 23 y 28 se aplazan a Fase 2.
- **Nota del verificador:** Matizar: spec 16 solo define cuándo penalizan las ayudas (línea 194), no cómo se calcula cada una ni la fórmula de puntos. Falta decidir con Alejandro si ayudas, puntos y rotación entran en V1 o se aplazan, y anotarlo en active.md. Eliminar la afirmación de que 'el jugador que no abre la leyenda no puede resolver', que no está probada.

### H-31. Navegación implementada (5 pestañas, solo íconos, mundos bloqueados visibles) no coincide con docs 02/06

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_producto-8`

- **Problema:** La estructura aprobada se aplicó en la app pero no en los docs; algunas decisiones contradicen explícitamente los docs y la barra de solo íconos puede incumplir accesibilidad sin etiquetas.
- **Impacto:** Los docs de pantallas dejan de servir como checklist de pendientes y no queda claro qué fue decisión consciente.
- **Evidencia:** ['docs 02 y 06:15-24 definen menú inferior de 4 y Perfil/Tienda/Premium/Config/Cómo jugar en menú secundario; active.md: 5 pestañas, barra solo íconos y hojas modales dentro de Perfil.', "docs/06:206 'solo mundos desbloqueados visibles' vs pestaña Mundos con Mansión y 4 bloqueados; menú superior persistente con vidas ausente (vidas solo en Inicio).", "docs/11:121-122 exige etiqueta accesible en todo elemento interactivo; doc 06 pantalla 46 'Cómo jugar' como página única vs diálogo paginado de 5 hojas."]
- **Sugerencia:** Actualizar docs 02 y 06 con la navegación real y ubicación de Tienda/Premium/Config, decidir si se muestran los mundos bloqueados y verificar Semantics/tooltip en cada ícono de la barra.
- **Nota del verificador:** Es en gran parte una divergencia documentada de una decisión ya tomada (active.md). El problema real es que los docs no se actualizaron. La parte de accesibilidad no está confirmada: hay que revisar la clase _PaperNavBar antes de afirmar que faltan etiquetas.

### H-32. Cronómetro por ticks, partida pendiente y modo offline: reglas de docs 01/03 sin respaldo y en tensión con los pilares 3 y 4

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_producto-9`

- **Problema:** Un temporizador por ticks se detiene cuando el sistema suspende la app, al revés de lo que dice doc 03; no se define si el reloj corre durante el bloqueo offline; borrar caché o cerrar sesión pierde el intento oficial, que el pilar 3 prohíbe.
- **Impacto:** Se puede trampear minimizando la app, el tiempo del ranking no es fiable y la pérdida de intento choca con los pilares.
- **Evidencia:** ["docs/03: el tiempo 'sigue corriendo incluso si la app se minimiza'; game_controller.dart:132 usa Timer.periodic de 1 s sin reloj de pared ni manejo de ciclo de vida.", "docs 01:166-172 y 03:142,465: una sola partida oficial pendiente y 'si se cierra sesión con una partida pendiente se pierde el intento oficial'; no existe en la app.", 'docs 09 pilares 3 y 4 prohíben invalidar progreso por cerrar la app y que caídas de internet consuman vida o puntos; docs/08: offline máximo 60 s y el tiempo durante bloqueo por error sigue contando; la sección de tensiones de doc 09 no menciona borrar caché ni cerrar sesión.']
- **Sugerencia:** Calcular el tiempo con timestamps de inicio y fin, definir en doc 03 si el reloj se congela offline, añadir a doc 09 la tensión pérdida-por-caché con decisión explícita y reflejar la persistencia local de la partida pendiente en el plan de Fase 2.
- **Nota del verificador:** Reformular: (1) el cronómetro por ticks se congela cuando Android suspende la app, contradiciendo docs/03:312 y permitiendo trampa al minimizar (hoy sin ranking real, impacto bajo; relevante al llegar a Fase 2); (2) la regla de pérdida del intento oficial por borrar caché o cerrar sesión (docs/03:464-465) choca con el pilar 3 de docs/09 y debe resolverse como decisión de producto antes de Fase 2. Ya no presentar como falta de implementación actual la partida pendiente y el modo offline.

## Documentos de soporte (arte, narrativa, legal, specs)

### H-33. Docs 05, 16, 01 y 03 con secciones obsoletas: tamaños, pistas, mapas autorados y pendientes ya cerrados

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: no · Origen: `docs_soporte-4`

- **Problema:** El spec 16 se contradice a sí mismo y delega la calibración de dificultad en rangos obsoletos del doc 05; la definición vigente de cada dificultad no está escrita en ningún sitio ni las técnicas de deducción.
- **Impacto:** Un ingeniero o agente puede construir grillas 4×4 o un catálogo de mapas reutilizables que ya no existe; calibrar el Mundo 1 'a ojo' puede producir una curva injusta (pilar 4); el servidor de Fase 2 podría portar una semántica distinta.
- **Evidencia:** ["docs/05 'Rangos base': Principiante 3 sospechosos / 4-5 pistas / hasta 4 pasos, Experto 6, Elite 6-7 vs generator.dart:44-53 (6, 8, 9, 12, 16) y pasos medidos 4-12; el banner del doc 05 cubre solo el modelo 'mapas a mano'.", "doc 05: 9 tipos de pista y 'solo directas y negativas simples' en Principiante vs spec 16 §3.1 con 16 tipos y §3.2 sin vagas; doc 05:160-171 '1 mapa tutorial + 50 de campaña' y editor de mapas.", "spec 16 §1.1 (6/8/9/12/16) vs §7 línea 193 '4×4 → 7×7/8×8' y 211; extras 'máx. 2' vs elite maxExtras 3; §5 'Mapa autorado reutilizable mapId mansion-01' vs mapa embebido; §6.2/6.3 remiten al doc 05 y a 'mapa autorado'; §1.4 cardinales eliminados en §3.1; decisión de rotar pistas sigue 'cerrada'.", 'Las técnicas T1-T4 solo están en active.md; la pregunta abierta del tutorial ya se resolvió; docs 01:278-285 y 03:276,319 mantienen pendientes cerrados en doc 08; hitos extra de protectores de doc 08 sin decisión; docs/04 y 17 discrepan sobre herramientas internas.']
- **Sugerencia:** Pasada de limpieza antes de generar el Mundo 1: mover decisiones superadas a 'Historial' o marcarlas SUPERADO, dejar la versión vigente (tamaños 6/8/9/12/16, tipos de pista del spec, pasos medidos), actualizar §5 al formato JSON real, añadir anexo con T1-T4 y tabla de calibración por dificultad (pasos mín-máx, nº de pistas, extras, uso de arma), cerrar la pregunta del tutorial, quitar pendientes cerrados y decidir si los hitos de protectores pasan a oficiales.

### H-34. docs/ no indica qué está vigente, superado o es solo visión

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_soporte-1`

- **Problema:** Varios docs están desfasados frente a decisiones posteriores (arte, mapas, pistas, monetización, roadmap) y nada indica cuáles; cada sesión y agente debe adivinar qué creer.
- **Impacto:** Riesgo de implementar contra un doc obsoleto o de re-decidir lo ya decidido; el dueño no sabe qué leer.
- **Evidencia:** ["CLAUDE.md afirma que los docs 'mandan' pero su tabla omite docs 18, 19, 20, docs/legal y los mockups por estilo.", 'Ningún doc 01-15 tiene cabecera de estado o fecha de vigencia; solo docs/05 tiene un banner parcial y docs/16 fecha decisiones.', 'No existe docs/README.md ni índice con estado por documento.']
- **Sugerencia:** Crear docs/README.md con tabla documento | estado (VIGENTE / PARCIALMENTE OBSOLETO / VISIÓN FUTURA / SUPERADO) | última verificación | qué lo reemplaza; cabecera de 2 líneas en cada doc; regla de actualizar el doc en la misma sesión que la decisión o marcarlo 'obsoleto desde X'; apuntar la tabla de CLAUDE.md al índice.

### H-35. Contradicción sobre la víctima: docs 13, 15 y 20 dicen que no se ve, pero el juego la coloca en el tablero

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_soporte-3`

- **Problema:** La regla central exige ubicar a la víctima como cualquier personaje, pero tres docs afirman lo contrario como argumento de contenido. Lo que hay es un avatar/marcador, no una imagen de cadáver.
- **Impacto:** El cuestionario de clasificación de edad con la frase del doc 20 no coincidiría con el producto; un rediseño gráfico podría quitar a la víctima del tablero y romper la mecánica.
- **Evidencia:** ["docs/13:172 'el jugador no ve representación gráfica de la víctima'; docs/15:39 'no hay representación gráfica de víctimas' (justifica PEGI 12/Teen); docs/20:42 'la víctima nunca se representa visualmente' (cuestionario IARC).", "board_view.dart:514-572 y :659: la víctima es una ficha propia con marca '†' y cinta 'LA VÍCTIMA'.", 'CLAUDE.md regla de oro y spec 16 §2.1: el jugador ubica a TODOS los personajes, incluida la víctima.']
- **Sugerencia:** Fijar una frase: 'la víctima es un personaje con avatar normal marcado con †; nunca se muestra cuerpo, sangre ni escena del crimen'; corregir docs 13, 15, 20 y la guía de arte; confirmar con el dueño que el marcador † es lo deseado.
- **Nota del verificador:** Corregir citas: board_view.dart:547 y :572; game_screen.dart:582 y :659. El problema es de redacción del doc/cuestionario IARC, no de contenido gráfico.

### H-36. Docs de cumplimiento, pruebas y tiendas (15, 18, 19, 20) desactualizados y contradictorios con el código

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: sí · Origen: `docs_soporte-8`

- **Problema:** El checklist y la revisión de seguridad son lo primero que se lee al publicar, y varias filas están desfasadas respecto a lo hecho y a lo que hay en la app; no hay un comando único de verificación documentado.
- **Impacto:** Declaraciones inexactas en las consolas (por ejemplo 'sin compras'), trabajo duplicado (icono) y baja confianza en los docs como fuente de verdad.
- **Evidencia:** ["docs/20:21 'icono default de Flutter' vs commit 54dced2 con icono generado; docs/20:44 'Sin compras, publicidad ni enlaces externos' vs Tienda/Premium DEMO con precios.", "docs/18:21-22 'INTERNET llega con el template de debug' vs AndroidManifest.xml:4 (INTERNET declarado, como dice doc 20); docs/18:44 'APK usa firma de debug' vs keystore de subida configurado (28bbde9).", "docs/15:306 'internet requerido para todo el juego' vs Fase 1 sin red; docs/15:35 categoría Apple '12 o superior' inexistente.", "docs/19 'Qué NO está: vidas, racha, tienda, tutorial guiado' y 54 'tutorial guiado no existe'; docs/17:46 '9 tests' (hoy 26); active.md '38 tests' (hoy 54 en tools/test).", 'La checklist no tiene filas para público objetivo, notas para el revisor, trader/DSA, verificación de .aab ni condición de esconder lo simulado.']
- **Sugerencia:** Actualizar docs 15, 18, 19 y 20 y active.md con el estado real (icono hecho, firma de subida, INTERNET declarada y por qué, tests, tutorial). Añadir al checklist una condición bloqueante antes de la prueba cerrada en Play: esconder o etiquetar claramente tienda/premium/ranking simulados. Que revisor-docs repita la pasada en cada release y que cada cierre de hito liste qué docs quedaron viejos; documentar en docs/19 el comando único de verificación.

### H-37. El doc 10 (arte) no describe la identidad visual real ni sirve de guía para la dirección visual que viene

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `docs_soporte-6`

- **Problema:** El Art Bible describe una estética nunca implementada y no hay documento que registre por qué se eligió Paper Craft ni qué criterios debe cumplir una dirección más profesional.
- **Impacto:** Tres fuentes visuales en conflicto (doc 10, mockups, código); si se rehace la UI sin actualizarlo se repite el ciclo de rediseños.
- **Evidencia:** ["docs/10 referencias (Clue Mystery, Hidden Folks, storybook, Stardew...) sin Paper Craft; paleta temática por mundo vs EnxPalette reducida al preset 'Papel'; cabecera con 'modos claro y oscuro' sin sección.", "Tipografías del doc (Inter/DM Sans/Manrope + Fraunces/Playfair + Caveat) vs enx_style.dart (Quicksand, Baloo 2, Patrick Hand); 'top down con leve perspectiva 3/4' vs CustomPainter vectorial.", 'docs/mockups/estilos/ (6) y docs/19:50 muestran que la decisión visual real vive fuera del doc 10.']
- **Sugerencia:** No editar el doc 10 aún; marcarlo 'SUPERADO PARCIALMENTE: pendiente de nueva dirección visual'. Cuando el usuario decida, reescribirlo como Art Bible vigente (referencias, paleta, tipografía, perspectiva, pipeline) enlazado desde un ADR de estilo; conservar feedback funcional de color, accesibilidad por forma/icono y paletas por mundo como idea.
- **Nota del verificador:** Quedarse en el aspecto documental: el doc 10 no refleja Paper Craft ni la tipografía implementada. No evaluar estética.

### H-38. Menores de documentación y contenido: docs de visión sin etiqueta, narrativa vs elenco y llave dentro de OneDrive

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `docs_soporte-13`

- **Problema:** Detalles que se acumulan: documentos sin etiqueta de visión, catálogo narrativo que no escala al elenco de Experto/Elite y gestión de la clave sin resolver.
- **Impacto:** Bajo ahora; la clave será relevante el día de la primera subida.
- **Evidencia:** ['docs 11, 12 y 14 describen requisitos V1 sin marcar visión futura; app/lib no usa Semantics ni escala de texto y los switches Sonido/Vibración (home_shell.dart:759-761) solo se persisten.', "docs/13: 7 arquetipos por mundo y 'definir el set inicial de nombres' pendiente; generator.dart:80 permite hasta 16 personajes con pool genérico.", "upload-keystore.jks y key.properties se sincronizan a la nube dentro de OneDrive (excluidos de git); docs/10 cabecera 'modos claro y oscuro' sin sección."]
- **Sugerencia:** Etiquetar 11, 12 y 14 como VISIÓN (Fase 4) en el índice; ampliar pool de nombres/arquetipos al generar Experto/Elite; mover el respaldo de la clave a un gestor de contraseñas o disco externo.

## Motor de puzzles y generador

### H-39. Experto 12×12 y Elite 16×16 nunca se han generado ni probado (rendimiento del generador y jugabilidad móvil)

Gravedad: **Alta** · Esfuerzo: medio · Decisión tuya: sí · Origen: `motor-1`

- **Problema:** Las dos dificultades más altas están definidas pero no hay evidencia de que se puedan generar en tiempo razonable ni de que quepan y se puedan tocar en un teléfono; los tiempos y rangos de pasos de los docs no tienen sentido para esos tamaños.
- **Impacto:** Podrían ser injustas, injugables o no generables, bloqueando el reto diario y comprometiendo la fórmula de puntos, los pilares y la campaña de 5 mundos; mejor saberlo antes de gastar arte.
- **Evidencia:** ['generator.dart:44-53 define perfiles de 6, 8, 9, 12 y 16; los tests solo cubren hasta 9×9, el CLI solo lista principiante|casual|intermedio y app/assets/cases tiene 20 casos sin experto ni elite; active.md lo lista como pendiente.', 'uniqueness.dart:82-101: backtracking en orden fijo sin propagación ni heurística de variable más restringida; el número de asignaciones parciales crece explosivamente (no se ejecutó: es estimación).', 'Doc 11:84 exige toque mínimo 48×48 pt; una grilla 16×16 en ~360 dp da celdas de ~21-22 dp.', "docs 05, 08 y 17 siguen calibrados para 3-7 sospechosos (tiempos objetivo 90-900 s sin referencia al tamaño); spec 16 §1.1 usa 6-16; doc 05 pide 2 de 7 días de reto como Experto/Elite y roadmap vigila 'solver no genera Elite interesantes' sin verificar tras el cambio de tamaños."]
- **Sugerencia:** Hacer un spike de contenido: generar lotes de 10 casos por dificultad en 12×12 y 16×16 midiendo tiempos, causas de descarte, pasos y legibilidad en pantalla de 6 pulgadas (prototipo con zoom/desplazamiento); usar los dominios del motor como poda en countSolutions o ponerle tope de nodos/tiempo; añadir tests con tope de tiempo; decidir si Experto/Elite entran al MVP o se recortan; corregir docs 05, 08 y 17 con la tabla real tamaño/sospechosos/pasos.
- **Nota del verificador:** El backtracking de uniqueness.dart usa orden fijo de personajes con poda parcial (partialOk), sin heurística de variable más restringida; el crecimiento para 12x12 y 16x16 es una estimación no medida. Doc 05 define Experto/Elite con 6-7 sospechosos, contradiciendo los perfiles de 12 y 16.

### H-40. La dificultad no se controla: el generador no impone rangos y los casos se solapan entre etiquetas, con bug en _stronger

Gravedad: **Alta** · Esfuerzo: medio · Decisión tuya: sí · Origen: `motor-4`

- **Problema:** La dificultad real depende de la suerte del sorteo; deductionSteps no mide esfuerzo humano y cada reparación salta a la pista más fuerte, aplanando la dificultad. Entre niveles solo crece la grilla y el número de pistas (=N).
- **Impacto:** No se pueden construir la campaña con curva ni el reto por día de semana; un novato puede toparse con un muro en Principiante y aburrirse en Intermedio; rompe la progresión y distorsiona puntos y tiempos objetivo de docs 05 y 08.
- **Evidencia:** ["spec 16:172 exige 'pasos dentro del rango de la etiqueta (doc 05)' pero generator.dart solo guarda deductionSteps en CaseMetrics (:356-360); DifficultyProfile (:24-63) solo varía tamaño, allowVague y maxExtras.", 'Pasos por caso: principiante s1-s8 = 4,4,3,6,10,4,6,8; casual 4,4,5,9,7,12,7; intermedio 7,5,4,12,9; principiante-s5 (10 pasos, maxTier 4) y s4 más duros que intermedio-s3 (4 pasos) y casual-s1 (4); 4 de 8 principiante superan los 4 pasos de doc 05 y 3 de 5 intermedio quedan bajo 9.', 'Candidatas medias por pista sin tendencia clara (2,5-4,5; 3,1-5,9; 3,7-6,4); el orden dentro de cada nivel es alfabético, sin rampa.', "generator.dart:391-396 (_stronger) recorre la lista ordenada de menor a mayor y devuelve la primera, o sea la pista MÁS fuerte, no 'la siguiente más fuerte'; deduction.dart:92-111 un 'paso' puede podar cualquier cantidad de celdas (_unaryClues cuenta como uno)."]
- **Sugerencia:** Fijar con el dueño qué mide la dificultad (técnica máxima, celdas descartadas por cruce, tamaño), con criterio cuantificable (p. ej. Principiante ≤6 pasos y técnica ≤3); hacer que _attempt rechace o reclasifique casos fuera de rango; corregir _stronger para devolver el candidato inmediatamente más fuerte; medir pasos por técnica de una en una; reordenar o regenerar el banco y actualizar docs 05 y 08 tras el próximo playtest.
- **Nota del verificador:** Añadir que los rangos de doc 05 están desactualizados respecto a los tamaños 6/8/9 actuales, por lo que primero hay que recalibrar los rangos y luego imponerlos en el generador.

### H-41. Validación en servidor sin decisión técnica: Dart en Cloud Functions es experimental y el doc 07 está desfasado

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `motor-2`

- **Problema:** El plan asume 'portar' el validador y el verbo oculta la decisión real: apostar por Dart experimental o reescribir en TypeScript duplicando la semántica y abriendo divergencia cliente/servidor. El doc de arquitectura quedó como propuesta inicial.
- **Impacto:** Es la decisión técnica más cara de Fase 2: si se descubre tarde se rehace el modelo de datos y la validación oficial, y se pierde el principio de una sola semántica y de 'el servidor es la autoridad'.
- **Evidencia:** ["spec 16:183 y validator.dart:4-5 'se porta la validación a Cloud Functions'; docs/adr solo tiene 0001 y 0002; backend/ está vacío; docs/07 no fija lenguaje del backend.", 'Firebase Blog 06-05-2026 y pub.dev firebase_functions: Dart en Functions es experimental tras flag (solo HTTPS y callable en producción, SDK Admin experimental); no se confirmó cambio posterior.', "docs/07: 'Riverpod o Bloc' (ADR-0002 eligió Riverpod), 'Hive o Isar' (app usa shared_preferences), 'online de extremo a extremo' (Fase 1 es local), colección 'maps' reutilizable vs mapa embebido; sus 'Pendientes' sin dueño ni fecha.", 'app/pubspec.yaml depende de enigmatrix_engine por path ../tools (Dart puro).']
- **Sugerencia:** Antes de Fase 2 escribir un ADR de validación con opciones: (A) Cloud Run con contenedor Dart (reutiliza validador y modelo, recomendado para una sola fuente de verdad), (B) reescribir Validator y Clue.holds en TypeScript en Cloud Functions Node, (C) Dart experimental solo para prototipar; exportar casos 'dorados' y correrlos contra ambas implementaciones. Actualizar doc 07 con almacenamiento, estado y modelo reales y convertir sus pendientes en lista con dueño.
- **Nota del verificador:** Es una decisión pendiente de Fase 2 (no bloquea ahora). La parte sobre Dart experimental en Cloud Functions viene de fuente externa no verificada aquí y debe confirmarse antes de decidir.

### H-42. Spec 16 promete detector de redundancia y límite de tiempo del solver que no existen

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: no · Origen: `motor-5`

- **Problema:** Dos criterios de aceptación no se implementan; sin límite un caso difícil puede colgar la tubería y sin detector no hay garantía de que las pistas sean necesarias.
- **Impacto:** La tubería de ~365 retos al año no puede correr desatendida y no hay medida objetiva de calidad.
- **Evidencia:** ["docs/16:166 y 173 'Detector de redundancia' y 'Tiempo de solver acotado'; docs/05:57 y 328-333 'ninguna pista es redundante' y límite por intento.", "grep 'redundan|Stopwatch|Duration|timeout' en tools/lib y tools/bin sin resultados; case_factory.dart:22 hasta 40 mapas × 8 intentos sin tope de tiempo."]
- **Sugerencia:** Añadir Stopwatch con límite configurable en CaseFactory.generate y countSolutions registrando el motivo de descarte, e implementar el detector (quitar una pista y re-correr el motor); si el dueño decide no hacerlo, marcarlo 'diferido' en la spec.

### H-43. No hay pipeline de lotes ni catálogo: el CLI escribe archivos sueltos y el id del caso no es único

Gravedad: **Media (revisor: alta)** · Esfuerzo: alto · Decisión tuya: no · Origen: `motor-6`

- **Problema:** Hoy se puede generar un caso pero no gestionar 415+ (50 de campaña y ~365 al año de reto): falta id estable, manifiesto con estado, manejo de colisiones (un mismo caso-casual-s1 sería campaña y diario) y vinculación mundo-mapa-nombres.
- **Impacto:** El trabajo editorial se hace a mano sobre carpetas con riesgo de duplicados o de publicar como diario un caso ya usado.
- **Evidencia:** ['enigmatrix.dart:45-96: generate --count N escribe un JSON por semilla sin curación, estados (candidato/aprobado/publicado) ni calendario; index.json manual de 20 archivos; .gitignore ignora tools/out/.', "case_factory.dart:25-26 y generator.dart:255: caseId = 'caso-<dificultad>-s<semilla>' sin mundo, tipo ni fecha; MapGenerator no recibe mundo (los 5 mundos no se diferencian).", 'docs/05:187-199 y 229-240: exclusiones entre campaña, diario y práctica, cola de 60-120 días y distribución semanal; spec 16 §5.2 campos mundo y tipo inexistentes; Random(seed) de Dart no se promete estable entre versiones del SDK.']
- **Sugerencia:** Definir un manifiesto (id estable, mundo, tipo, dificultad, fecha programada, estado, hash del JSON, versión de motor y SDK) y un comando batch que genere, filtre por solver y escriba en cola; tratar el JSON aprobado como fuente de verdad y la semilla solo como ayuda.
- **Nota del verificador:** Cita corregida: el caseId se asigna en case_factory.dart:41 (caseIdOverride). El campo 'world' aparece en la spec 16 (ejemplo línea 132) pero no existe en el generador.

### H-44. Poca variedad narrativa: elenco, vocabulario y nombres fijos, casos sin título ni premisa y mapas que no coinciden con 'Mansión'

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `motor-7`

- **Problema:** Los casos son lógicamente correctos pero narrativamente vacíos y repetitivos; el texto 'Mundo 1 La Mansión' no concuerda con el mapa.
- **Impacto:** Un jugador diario verá el mismo elenco más de 300 veces al año; parte de por qué la progresión 'no parece un juego'; pocos muebles en tableros grandes reducen los tipos de pista útiles.
- **Evidencia:** ["generator.dart:80-97: 16 nombres fijos por índice (Adela, Bruno... siempre en el mismo orden; 'Dario' sin tilde); map_generator.dart:10-51 con 14 habitaciones, 10 lugares y 10 armas y de 1 a 4 muebles por habitación incluso en 16×16.", "Los 20 casos no tienen título, premisa, mundo ni motivo (docs/13 los exige); victory_screen.dart solo dice 'El asesino era X'; mapas 'El Casino' ×5, 'El Teatro' ×4, 'La Galería', 'La Posada'... y solo 2 'La Mansión', pero home_shell.dart:268-275 los cuenta todos como '🗺️ MUNDO 1 · LA MANSIÓN' (20).", "docs/05:321-326 ya identifica 'percepción de repetición' como riesgo; un 'Teatro' con Baño, Bodega y Comedor y sin escenario."]
- **Sugerencia:** Antes de generar el Mundo 1 añadir al esquema un bloque narrativo ('world', 'title', 'premise', 'motive'); pasar nombres, armas, habitaciones y lugares a archivos de datos por mundo con elenco al azar de un banco grande; subir el tope de muebles con el tamaño; coordinar con contenido-puzzles y el dueño; mientras tanto cambiar la tarjeta a algo neutral ('Banco de pruebas').
- **Nota del verificador:** Sin cambios de fondo. Detalle de los mapas en los JSON: El Casino 5, El Teatro 4, La Mansión 2, La Posada 2, El Club 2, La Villa 1. El texto fijo 'Mundo 1 · La Mansión' no coincide con la mayoría de los casos. La parte de pocos muebles en tableros grandes no la verifiqué.

### H-45. Tests del motor cubren solo la ruta feliz y el Validator con entradas hostiles casi no se prueba

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: no · Origen: `motor-8`

- **Problema:** Pocos casos dan confianza débil en volumen y el validador, futuro punto de entrada del servidor, no tiene pruebas de entradas hostiles.
- **Impacto:** Una regresión silenciosa en la semántica de una pista puede publicar casos mal formados sin que falle ningún test.
- **Evidencia:** ["generator_test.dart usa 3-5 semillas por dificultad sin comparar DeductionEngine contra fuerza bruta; las ramas de rechazo ('reparación agotada', 'sin reparaciones posibles', 'arma ambigua') no se prueban.", 'validator_test.dart: 8 tests sobre un mapa 4×4, sin personaje faltante o desconocido, celda negativa o fuera de grilla ni cadenas por enteros; spec 16 §6.4 exige casos con doble solución y casos que requieren adivinar, solo cubiertos con el fixture 4×4.', 'No existe .github/ ni CI.']
- **Sugerencia:** Test de propiedad con 200 semillas pequeñas (motor vs búsqueda exhaustiva), pruebas de entradas hostiles al Validator, casos dorados compartidos con el futuro backend y CI con dart test en tools/.

### H-46. Un validador aislado en el servidor no impide que un bot resuelva el caso: pistas públicas y solver en la app

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `motor-3`

- **Problema:** Aun quitando la solución del payload, quien tenga las pistas puede resolver con el propio motor Dart; el principio protege contra copiar la respuesta, no contra automatizarla.
- **Impacto:** El ranking por tiempo (pilar 2) no se sostiene solo con validar posiciones en el servidor.
- **Evidencia:** ['uniqueness.dart y deduction.dart se exportan en enigmatrix_engine.dart:7-14 y los consume la app (pubspec.yaml:16-17).', "puzzle_case.dart:139-151: el payload del cliente ya incluye todas las pistas y el mapa; con eso el solver encuentra la solución sin ver 'solution'.", 'game_controller.dart:306,323: validación local y comparación contra pc.solution (riesgo aceptado de Fase 1).']
- **Sugerencia:** En el ADR de backend añadir tiempo mínimo plausible por dificultad y caso (calculable con deductionSteps), tiempo medido por el servidor y revisión de patrones; opcionalmente mover Generator, UniquenessChecker y DeductionEngine fuera del paquete que consume la app dejando solo modelo y Validator.
- **Nota del verificador:** Reformular como consideración para el ADR de backend de Fase 2: la protección por no enviar la solución no impide la automatización con el solver; considerar tiempo mínimo plausible. No es problema actual.

### H-47. La semántica de pistas está implementada tres veces (Clue.holds, motor de deducción y poda de unicidad)

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `motor-9`

- **Problema:** Añadir un tipo de pista exige tocar tres archivos y olvidar uno no se detecta hasta que un caso lo use.
- **Impacto:** Riesgo de deriva cuando el vocabulario crezca.
- **Evidencia:** ['clue.dart:70 (holds) vs deduction.dart:127-140 (_allowedOf) y 220-229 (_relationOf): misma semántica escrita dos veces; uniqueness.dart:12-30 tercera lista de sujetos con comentario de monotonía solo verificado indirectamente.', 'Los switch usan default/_ => null en deduction y uniqueness, de modo que olvidar un tipo nuevo no da error de compilación.']
- **Sugerencia:** Extender la prueba de propiedad con cada tipo nuevo y quitar los default/_ de los switch sobre Clue para que el compilador obligue a tratar cada caso.

### H-48. Menores del motor: costos evitables en deducción, fila vacía sin contradicción y presupuestos sin tope

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `motor-10`

- **Problema:** Ninguno bloquea hoy pero son fricción para escalar a 16×16 y confunden la documentación.
- **Impacto:** Costo extra en tableros grandes y documentos contradictorios.
- **Evidencia:** ['deduction.dart:92-111 recalcula _allowedOf de todas las pistas en cada paso sin memoria y el generador repite el motor hasta 4n+8 veces por intento (generator.dart:272).', "deduction.dart:243-260: _hiddenSingles no marca contradicción si ningún personaje puede ocupar una fila (lo reporta 'atascado').", 'generator.dart:116 maxAttempts 300 y CaseFactory 8×40 sin presupuesto global; el CLI no menciona experto ni elite; spec 16:190 aún dice 4×4 → 7×7/8×8.']
- **Sugerencia:** Guardar en caché los conjuntos permitidos por pista dentro de una ejecución del motor, tratar fila vacía como contradicción, fijar un presupuesto global de intentos y limpiar las menciones de tamaños antiguos.
- **Nota del verificador:** La cita de la spec 16 es la línea 193, no la 190. Es un hallazgo menor de limpieza y de rendimiento potencial, no un bloqueo.

## Contenido: los 20 casos

### H-49. Volumen y definición de contenido insuficientes: 20 casos de prueba (~1 h), sin Mundo 1 ni curva por mundo

Gravedad: **Media** · Esfuerzo: alto · Decisión tuya: sí · Origen: `contenido_casos-3`

- **Problema:** Ningún documento fija la progresión de dificultad dentro de un mundo ni los volúmenes de contenido, y lo que existe es un banco de pruebas que se agota en una o dos sesiones.
- **Impacto:** Los playtesters no pueden validar hábito diario ni retención y el siguiente bloque obliga a inventar la curva sin base; si Experto/Elite resultan inviables, la campaña de 5 mundos pierde sentido.
- **Evidencia:** ['index.json: 20 casos (8 principiante, 7 casual, 5 intermedio); a tiempos objetivo 8×90+7×180+5×360 = 3780 s (63 min); un novato lo termina en 2-3 h.', 'docs/17: Mundo 1 ~10 mapas en Fase 2 y Fase 4 con 60-120 días de reto; docs/05: 50 mapas de campaña; el tutorial consume el primer caso real.', 'docs/01 y 05 no fijan tabla mundo → dificultad → tamaño, casos por dificultad, reparto campaña/reto ni qué mapas llevan arma; solo 2 de 20 con hasWeapon; map_generator no está atado a la lista de armas por mundo.', "active.md: 'generar Mundo 1 real (10 casos Mansión)' pendiente."]
- **Sugerencia:** Fijar una meta de contenido por fase (Mundo 1 con 10 casos de curva real en Fase 1 y plan de volumen del reto diario, p. ej. 30 días al lanzar); añadir a doc 05 o 17 la tabla 'Mundo 1: caso 1 a 10 → dificultad, tamaño, con/sin arma' y volúmenes totales; validarla con Alejandro antes de generar.

### H-50. El orden de los casos es alfabético: casual-s20 y s21 aparecen antes que s3

Gravedad: **Media (revisor: alta)** · Esfuerzo: bajo · Decisión tuya: no · Origen: `contenido_casos-1`

- **Problema:** El orden de las fichas sale de comparar ids como texto, así que los dos casos con arma quedan en posiciones 3 y 4 y la numeración depende de un orden accidental.
- **Impacto:** Los casos con arma aparecen en medio de la curva; el Mundo 1 fallará igual (s10 entre s1 y s2) y la progresión no está bajo control.
- **Evidencia:** ['case_repository.dart:27-29 ordena con a.caseId.compareTo(b.caseId) (texto); index.json lista casual-s1, s2, s20, s21, s3, s4, s5.', "case_list_screen.dart:~375 'number: i + 1' numera según ese orden; los ids s6-s19 son huecos de generación."]
- **Sugerencia:** Añadir un campo explícito de orden o mundo a cada caso o a index.json y ordenar por él (como mínimo por el número del id); renumerar de forma continua al regenerar el Mundo 1.
- **Nota del verificador:** El orden dentro de cada dificultad es alfabético (casual-s20 y s21 quedan antes de s3), lo que desordena la numeración. Pasará igual con los ids s10 en adelante del Mundo 1. Es fácil de corregir con orden numérico o un campo de orden.

### H-51. Las hojas imprimibles de production/fase0-casos son otros casos que los de la app, con los mismos ids

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: no · Origen: `contenido_casos-5`

- **Problema:** Hojas y JSON comparten ids pero describen puzzles distintos tras 'Coherencia de muebles' y la regeneración.
- **Impacto:** El feedback del dueño en papel queda mal atribuido y la validación pendiente se haría sobre contenido obsoleto.
- **Evidencia:** ["casos-para-jugar.txt 'caso-casual-s1 / Mapa La Villa, víctima Greta' vs caso-casual-s1.json 'La Galería', víctima c5 (Elena); 18 de 20 ids tienen mapa distinto y casi todas las víctimas difieren.", 'La hoja se actualizó por última vez en 21b2f87 (11-06-2026) y los assets en 5fd6f9d (12-06-2026); docs/17:24 sigue pidiendo validación en papel.']
- **Sugerencia:** Regenerar las hojas desde app/assets/cases con la CLI de tools (show) o borrarlas, anotando fecha y commit de origen en el encabezado.

### H-52. El arma homicida casi no se usa y el vocabulario de pistas es estrecho

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: sí · Origen: `contenido_casos-7`

- **Problema:** La mecánica distintiva aparece en el 10% del banco y nunca por encima de Casual; en el resto las armas visibles no cumplen papel y la mayoría de pistas sigue la misma plantilla.
- **Impacto:** El playtest no valida lo que diferencia al juego, el jugador puede creer que las armas son pistas y el juego se siente repetitivo.
- **Evidencia:** ['hasWeapon=true solo en casual-s20 y s21 (2 de 20); ningún intermedio tiene arma; docs/03:40 dice que en Intermedio forma parte normal del caso y CLAUDE.md:5 la presenta como diferencial.', 'Ningún caso usa pistas extra (clues = N en todos); solo 9 de 16 tipos usados (ausentes not_in_area, not_same_area, beside, area_empty y las tres de arma).', "board_view.dart:311-368 muestra 'Armas: ...' también en los 18 casos sin arma homicida."]
- **Sugerencia:** Para el Mundo 1 incluir casos con arma desde Intermedio, alguna pista extra (máx. 2) y más tipos (not_in_area, beside entre personas, area_empty); ocultar o atenuar armas en casos sin arma homicida o explicar que son decorativas.

### H-53. El significado de 'junto a' y 'única persona sobre' solo se explica en un diálogo omitible y una pista del banco es confusa

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: no · Origen: `contenido_casos-8`

- **Problema:** Tres cuartas partes de las pistas dependen de reglas sutiles (sin diagonales, misma habitación, 'junto a' no incluye estar encima) que no están en la leyenda, y la pista de Hugo suena a contradicción.
- **Impacto:** Quien se saltó el tutorial interpreta mal pistas legítimas y siente injusto el juego (pilar 4).
- **Evidencia:** ["tutorial_dialog.dart:46 explica 'junto a' (casilla vecina arriba, abajo, izquierda o derecha de la misma habitación) en un diálogo que se muestra una vez y se puede omitir; la sección REGLAS de la leyenda (game_screen.dart ~869-874) no lo menciona.", "caso-casual-s2.json:391-405: pista compuesta de c8 = on_object alfombra + beside_object alfombra, mostrada como 'Estaba sobre una alfombra y junto a una alfombra.'; 'junto a' aparece en 14-16 de 20 pistas de un caso típico."]
- **Sugerencia:** Añadir a la leyenda una mini-guía de expresiones de pista con ejemplo gráfico por tipo y redactar 'sobre una alfombra, junto a otra alfombra' o evitar que el generador combine el mismo grupo de mueble.
- **Nota del verificador:** El significado de 'junto a' solo se explica en el tutorial (tutorial_dialog.dart:46) y no aparece en la leyenda de reglas. La redacción de pistas compuestas con el mismo mueble puede confundir. Las cifras exactas de frecuencia no se verificaron.

### H-54. Menores de contenido: archivo de soluciones versionado, ortografía y predictibilidad del reparto

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `contenido_casos-11`

- **Problema:** Ninguno bloquea; el SPOILERS sería un problema real si el repo se publica en GitHub o se comparte.
- **Impacto:** Bajo hoy; resta pulido y predictibilidad.
- **Evidencia:** ['production/fase0-casos/casos-con-soluciones-SPOILERS.txt está versionado (git ls-files) con soluciones de un banco anterior; git remote vacío pero la carpeta vive en OneDrive.', "generator.dart:84 'Dario' sin tilde en los 20 casos; puzzle_case.dart:90-91 nameOf devuelve 'La víctima' con mayúscula que se usaría en medio de frases.", 'c5 (Elena) es víctima en 7 de 20 casos y en 4 de 8 principiante; el asesino es c6 (Franco) en 4 de 20.']
- **Sugerencia:** Mover los SPOILERS fuera del repositorio o ignorarlos (production/**/*SPOILERS*) y quitarlos del índice con git rm --cached cuando se decida; corregir 'Darío', usar 'la víctima' en minúscula y sortear la víctima con más variedad al regenerar.

## Código de la app

### H-55. Salir de la partida (Atrás, flecha, llamada) pierde todo el progreso y la navegación usa go() pasando por el splash

Gravedad: **Alta** · Esfuerzo: medio · Decisión tuya: sí · Origen: `codigo_app-2`

- **Problema:** Tablero, marcas, cronómetro y errores viven solo en memoria; un toque accidental, llamada o cierre del sistema borra 10-20 minutos de deducción sin aviso. Con go() no hay pila: tras cada caso el jugador ve el splash y vuelve a Inicio, no a su pestaña o camino.
- **Impacto:** Rompe los pilares 3 y 4 y es la forma más rápida de generar abandono y quejas en testers; el bucle caso a caso, lo más repetido, exige demasiados pasos.
- **Evidencia:** ["case_list_screen.dart:493,558,692 y home_shell.dart:259,438 entran con context.go('/play/...'), que reemplaza la pila; no hay PopScope ni WillPopScope en app/lib.", "game_screen.dart:141 y victory_screen.dart:268-271 usan context.go('/'), que pasa por el splash con espera fija de 1700 ms (splash_screen.dart:25-35) y cae en la pestaña Inicio; el botón Atrás de Android en /casos o /play cierra la app.", "game_controller.dart:119-135: autoDispose y sin guardado; solo se escriben done:, fb:, profile:nick, cfg:, tutorial:, enx:palette; docs 07:337 y 02:77 piden 'Continuar partida pendiente'; sin 'Siguiente caso' en la victoria (victory_screen.dart:264-279)."]
- **Sugerencia:** Usar push/pop (o ShellRoute) para que Atrás vuelva a la pantalla anterior, mostrar el splash solo en arranque en frío, añadir PopScope con diálogo 'Tu avance queda guardado, ¿salir?' y guardar localmente la partida (celdas, marcas, tiempo, errores) en cada cambio con tarjeta 'Continuar' en Inicio; añadir 'Siguiente caso' y 'Volver al camino' en la victoria. Decidir con Alejandro si el cronómetro se pausa al salir.
- **Nota del verificador:** Corregir citas: entradas a partida con go() en case_list_screen.dart:692 y :757 (home_shell usa go('/casos')); quitar docs/07:337 salvo que se verifique. Lo sustancial se mantiene: sin PopScope, sin guardado de partida en curso, victoria y salir vuelven por el splash.

### H-56. Accesibilidad de la partida muy por debajo del doc 11: sin Semantics, errores solo por color y pistas truncables a 11,5 px

Gravedad: **Alta** · Esfuerzo: alto · Decisión tuya: sí · Origen: `codigo_app-9`

- **Problema:** Ninguno de los mínimos de accesibilidad de V1 está implementado y la información más importante, el texto de las pistas, puede cortarse sin forma de leerlo.
- **Impacto:** Excluye a jugadores con daltonismo, baja visión o lector de pantalla, puede motivar rechazo de tienda y vulnera 'deducción pura' sin culpa del jugador (pilar 1).
- **Evidencia:** ['0 ocurrencias de Semantics, semanticLabel, ExcludeSemantics, textScaler o disableAnimations en app/lib; docs/11 exige cobertura TalkBack, no depender solo del color y modo daltónico.', 'board_view.dart:276,338-345: la casilla errónea solo cambia a degradado rojo (doc 11 pide borde, patrón, texto e icono); 16 colores de personaje similares identificados por una inicial.', 'game_screen.dart:431-432 y :700-703: tira de pistas con SizedBox(height:118), tarjetas de 205 px, maxLines:3 con ellipsis a 11,5 pt (doc 11 exige 16 pt y no truncar a 130%); no hay forma de ver la pista completa (_InfoPanel solo muestra extraClues, :765); 75 pistas compuestas en los 20 casos son las más expuestas.', 'Notas de ayuda a 10-11 px en gris; en 16×16 sobre ~360 px cada celda mide ~21 px frente a los 48 px de doc 11.']
- **Sugerencia:** Hacer que las pistas ocupen el alto necesario o abrir el texto completo al tocar y mantener y subir su tamaño; añadir icono y borde a las celdas con error; poner Semantics a celdas, tarjetas y botones; definir en el tema modo alto contraste y daltonismo; probar con textScaler 1,3; planificar las opciones de configuración del doc 11; decidir cómo se resuelve el toque en cuadrículas grandes (zoom o lupa) antes de diseñar el nuevo tablero.

### H-57. El corazón de la partida no tiene pruebas y las existentes son frágiles (router global, esperas fijas, test que escribe iconos)

Gravedad: **Alta** · Esfuerzo: medio · Decisión tuya: no · Origen: `codigo_app-11`

- **Problema:** Lo que más se tocará en el rediseño (la partida y su interacción) es lo menos probado, y los tests de pantallas fallarán por razones ajenas a un bug sin detectar desbordes de layout en móvil.
- **Impacto:** Una regresión (Resolver sin validar, bloqueo que no se levanta, ganar sin guardar) solo la descubriría Alejandro jugando; falsos rojos y falsos verdes; la suite reescribe los iconos sin aviso.
- **Evidencia:** ['app/test/ tiene board_state_test.dart (16), enx_screens_smoke_test.dart (5) y generate_icon_test.dart; cero referencias a GameScreen, GameController, VictoryScreen ni al guardado de done:; game_controller.dart:285-335 (solve, bloqueo 3 s, resaltado) y board_view.dart:321-335 (tap, long-press, DragTarget) sin pruebas.', 'game_screen.dart fue modificado en 5 commits seguidos del 12-07-2026 (561c11e, 6cdd9f6, 0bde190, 9b7e768, 84835be) sin tocar app/test.', 'main.dart: GoRouter global compartido entre tests (el propio test lo admite); pumps fijos de 2000 ms + 5×300 ms para el splash de 1700 ms; aserciones sobre copy exacto y find.byIcon(...).last, warnIfMissed:false; tests a 800×600 sin textScale; smoke test carga solo names.take(4).', 'generate_icon_test.dart:41-60 ESCRIBE assets/icon/icon_full.png e icon_fg.png con cada flutter test.']
- **Sugerencia:** Probar GameController con ProviderContainer y fake_async (flujo incompleto→error→bloqueo→desbloqueo→solución→solved, deshacer/rehacer con límite 50) inyectando el reloj; 5-6 widget tests de GameScreen a 360×640 (tap con herramienta, long-press, arrastre, Resolver mal y bien con escritura de done:); crear el GoRouter por instancia (buildRouter()); reemplazar pumps fijos por pumpUntilFound o splash inyectable; usar Keys; helper a 360×640 y 320×568 con textScale 1,3 que falle ante overflow; mover la generación de iconos a tool/ o taggearla 'manual'.

### H-58. Todo el tablero se reconstruye cada segundo por el cronómetro

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: no · Origen: `codigo_app-1`

- **Problema:** El cronómetro vive en el mismo estado que el tablero y cada segundo se redibujan todas las celdas aunque ninguna cambió.
- **Impacto:** En 12×12 y 16×16 en un móvil de gama media se esperan tirones y mayor consumo, riesgo directo para los niveles que más retienen.
- **Evidencia:** ['game_controller.dart:130-134: Timer.periodic de 1 s con state = state.copyWith(elapsedSeconds) sobre el estado completo.', 'board_view.dart:111 y :270, y game_screen.dart:41: ref.watch del estado completo sin .select, de modo que BoardView, cada _Cell y _GameView se reconstruyen en cada tick; cada celda recalcula indexWhere, objectAt, weaponsInArea, bordes, gradientes y un DragTarget con Tooltip.', 'No hay casos 12×12 ni 16×16, por lo que 144 y 256 celdas nunca se han medido.']
- **Sugerencia:** Sacar el tiempo a su propio provider o ValueNotifier observado solo por el chip del reloj; usar .select por celda; precalcular geometría por caso; añadir RepaintBoundary; considerar pintar el tablero en una sola capa CustomPainter; medir casos 12×12 y 16×16 en teléfono real antes de construir sobre ese render.
- **Nota del verificador:** Citar game_controller.dart:132-135 (no 130-134) y aclarar que _CellMarks (board_view.dart:448) ya usa .select; el impacto en 12x12/16x16 es esperado, no medido.

### H-59. Dos sistemas de diseño en paralelo: la partida no se migró, hay import circular, literales sueltos y fuentes no empaquetadas

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `codigo_app-3`

- **Problema:** Dos conjuntos de tokens con nombres que mienten y la pantalla donde se pasa el 90% del tiempo sigue en el sistema viejo; el jugador percibe 'dos apps' y los tokens viven en main.dart creando un ciclo.
- **Impacto:** Un rediseño profundo tocaría ~10 archivos con literales sueltos y dejaría pantallas inconsistentes; en Android el tester no verá la tipografía manuscrita que ve Alejandro en el PC.
- **Evidencia:** ["main.dart Brand y enx_style.dart Enx duplican colores (Brand.cream = 0xFF3D2F1C = Enx.text = Enx.ink; el nombre 'cream' ya miente); game_screen.dart: 53 usos de Brand.* y ninguno de Enx.font/display/hand.", "game_screen.dart:11, board_view.dart:15 y case_list_screen.dart:18 importan '../../main.dart' para Brand y difficultyColor mientras main.dart importa esas pantallas (ciclo); 45 literales Color en board_view.dart, 46 en furniture_painters.dart y 17 en home_shell.dart.", 'La partida usa Brand.*, FilledButton, SegmentedButton y AlertDialog Material con Roboto, mientras shell, camino y victoria usan EnxButton, Baloo 2/Patrick Hand y paleta Enx; cuatro sistemas de diálogo distintos; la barra del camino pinta una lupa genérica en vez de PaperLogo.', "EnxPalette con un solo preset (paletteProvider.notifier.select nunca se llama, 11 ref.watch); pubspec no empaqueta fuentes (google_fonts descarga en runtime); game_screen.dart:643-644 y main.dart:50-57 usan 'Segoe Script', fuente solo de Windows."]
- **Sugerencia:** Antes del rediseño crear UN tema (ThemeData + ThemeExtension con tokens semánticos) en su archivo, eliminar Brand o dejarlo como alias temporal, mover difficultyColor y paletas de personaje/habitación/mueble, extraer un kit de componentes compartidos (botón, tarjeta, chip, diálogo, tipografías), empaquetar las fuentes finales, eliminar 'Segoe Script' y migrar game_screen como primera pantalla.
- **Nota del verificador:** Quitar la cita game_screen.dart:643-644; 'Segoe Script' aparece solo en main.dart:51 (definido como Brand.scriptFont).

### H-60. El tablero mezcla geometría, gestos, colores y drag & drop en un widget por celda; la validación es síncrona y local

Gravedad: **Media (revisor: alta)** · Esfuerzo: alto · Decisión tuya: sí · Origen: `codigo_app-4`

- **Problema:** BoardState y GameController son reutilizables, pero falta la capa intermedia que traduce toque o arrastre a celda y celda a apariencia, y solve() asume validación local síncrona.
- **Impacto:** Un cambio a CustomPainter, Flame o Rive obliga a reescribir board_view y el drag & drop; la validación de servidor en Fase 2 cambiaría la firma de solve() a asíncrona y el resaltado de errores hoy solo es posible con la solución en el cliente.
- **Evidencia:** ['board_view.dart (608 líneas) junta paleta de áreas, personajes, iconos de muebles, layout, etiquetas, paredes por celda y gestos; game_screen.dart importa charColor, areaPalette, objectIcon y objectColor de él.', "CLAUDE.md y docs/07:55 dicen 'CustomPainter + GestureDetector' pero el tablero real es una grilla de Column/Row con N² widgets cada uno con DragTarget, Draggable, Tooltip y GestureDetector.", 'game_controller.dart:314-336: solve() síncrono con Validator.validate y errorCells contra state.pc.solution; GameState mezcla estado de partida con preferencias de vista (mapMode, autoX) y herramienta seleccionada.']
- **Sugerencia:** Antes de rediseñar definir BoardGeometry, un modelo de presentación por celda y una capa de entrada única (un solo detector de gestos que resuelve la celda por coordenadas); poner un contrato abstracto SolutionChecker con Future (local ahora, servidor en Fase 2) y sacar mapMode y autoX a un estado de preferencias.
- **Nota del verificador:** Citar CLAUDE.md:31 (no docs/07:55) para la discrepancia CustomPainter vs widgets, y game_controller.dart:317-319 para la validación local. Presentarlo como deuda a considerar antes del rediseño, no como defecto actual.

### H-61. Archivos gigantes con varias responsabilidades y claves de SharedPreferences repartidas

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: no · Origen: `codigo_app-5`

- **Problema:** No hay capa de datos de progreso; cada pantalla lee y escribe con su propia clave y formato y los tres archivos más grandes mezclan interfaz, datos y lógica.
- **Impacto:** Cambiar una pantalla puede romper otra; migrar a Firestore o caché local en Fase 2 toca cada pantalla; un rediseño obliga a reabrir archivos de 800-1000 líneas.
- **Evidencia:** ['game_screen.dart 979 líneas con ~12 clases privadas (_SuspectPanel solo contiene herramientas); home_shell.dart 784 líneas con 5 pestañas, 3 hojas modales, mocks y prefs directas; case_list_screen.dart 764 líneas con exportación de feedback, resultados y animaciones.', "Claves 'done:', 'fb:', 'profile:nick', 'cfg:', 'tutorial:seen', 'tutorial:played' como strings sueltos en case_list_screen:65, victory_screen:28, home_shell:531/745, tutorial_dialog:12 y tutorial_coach:15; prefsProvider definido en case_list_screen.dart:24 y varios archivos llaman SharedPreferences.getInstance() directamente."]
- **Sugerencia:** Crear un ProgressRepository (resultados, ajustes, perfil, banderas de tutorial) con claves y formato versionado en un solo archivo y consumirlo por provider; trocear game_screen, home_shell y case_list_screen en carpetas por pantalla con widgets de 100-200 líneas, junto con el tema único.

### H-62. Datos simulados mezclados en la UI con etiquetado DEMO incompleto y ajustes sin efecto, riesgo de rechazo en tiendas

Gravedad: **Media (revisor: alta)** · Esfuerzo: medio · Decisión tuya: sí · Origen: `codigo_app-6`

- **Problema:** Unas cosas son DEMO honestamente y otras aparentan ser reales; los ajustes parecen funcionar y no hacen nada, los textos de reto prometen reglas que no se cumplen y el build que va a testers y tiendas incluye compras y ranking falsos.
- **Impacto:** Testers de Play (12 durante 14 días) reportarán 'bugs' que son relleno y el feedback sobre racha, vidas y reto será ruido; un revisor puede rechazar o marcar la app; al conectar Firebase habrá que cazar cada mock disperso.
- **Evidencia:** ["home_shell.dart:20-35 mocks en el archivo de UI; chip de vidas '4/5 +1 en 23:41' (:187-193), racha 'L-M-X' (:383-420), 'mejor racha 7' y estadísticas del Perfil (:571-578) y '🇨🇴 · detective desde julio 2026' (:564) sin DEMO; solo tienda, premium, ranking y puntos semanales lo llevan.", "Ranking incoherente: el jugador aparece en el puesto 11 con 1840 pts bajo 7 bots con 1495-2450 (:497-511); el reto dice 'Un intento oficial' pero es rejugable y abre sin la advertencia de la pantalla 33; el caso del reto se calcula dos veces con la misma fórmula copiada (:256, :435).", 'Los 4 interruptores Sonido, Música, Vibración y Notificaciones guardan cfg:* (:744-750, :759-762) pero ningún archivo los lee, no hay audio ni haptics y no llevan DEMO.', "Tienda y Premium con precios ($0.99, $4.99/mes, $29.99/año) cuyos botones solo muestran 'Función simulada' (:645-720); Apple 2.1(a)/(b) y Play (funcionalidad mínima, comportamiento engañoso) permiten rechazar; docs/17:101 pospone monetización a Fase 3."]
- **Sugerencia:** Mover todos los mocks a un MockProfileRepository con la interfaz del real y marcar DEMO todo lo que venga de él (vidas, racha, puntos) o esconderlo; ordenar el ranking o quitar el '11'; quitar o marcar 'próximamente' los ajustes sin efecto; unificar el cálculo del reto y ajustar sus textos; para tiendas, separar un build con --dart-define=STORE_BUILD=true que oculte Tienda, Premium, ranking simulado y ajustes sin efecto (o al menos rotularlos y explicarlo en las notas para el revisor).
- **Nota del verificador:** Matizar: los datos simulados son decisión del usuario; el problema es el etiquetado DEMO incompleto y los 4 ajustes sin efecto. El riesgo de tiendas aplica a futuros builds de testers/publicación, no al estado actual.

### H-63. Sin internacionalización: unas 300 cadenas fijas y pistas compuestas en español por el motor

Gravedad: **Media** · Esfuerzo: alto · Decisión tuya: sí · Origen: `codigo_app-8`

- **Problema:** No hay base para traducir y el texto de las pistas, contenido central, lo fabrica el motor con gramática fija, por lo que traducir no es solo cambiar cadenas.
- **Impacto:** Añadir inglés obliga a reescribir toda la app y rediseñar las pistas; cuanto más crezca la UI antes, más caro; los casos publicados quedarían ligados al idioma.
- **Evidencia:** ['pubspec.yaml sin intl ni flutter_localizations, sin l10n.yaml ni .arb; docs/07:56 y :448-452 exigen intl con ES por defecto y EN secundario.', 'Texto literal en game_screen.dart:55-95, home_shell y tutorial_dialog.dart:35-60; clue.dart:84-89 y :138 (cardTextEs, predicateEs) componen las frases en español con género y artículos; modelos usan nameEs/name_es; board_view.dart:227-229 quita artículos con regex en español.']
- **Sugerencia:** Extraer cadenas a .arb ya, junto con las pantallas nuevas; decidir pronto si las pistas se guardan como datos estructurados con plantillas por idioma (recomendado) o el motor genera ambos idiomas; si EN no entra en V1, al menos centralizar los textos.

### H-64. Manejo de errores débil: splash o spinner infinitos y un solo JSON malo detiene la carga de todos los casos

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: no · Origen: `codigo_app-10`

- **Problema:** Varios caminos donde un dato inesperado detiene la app sin mensaje o la rompe en build y no existe pantalla de error con reintento; es un riesgo concreto al editar index.json con el Mundo 1.
- **Impacto:** Un solo JSON mal formado deja la app sin arrancar para todos; con casos descargados en Fase 2 un fallo de red produciría pantalla colgada; para Alejandro es un bloqueo total sin pista del motivo.
- **Evidencia:** ["splash_screen.dart:31-35: await Future.wait([load, delay]) sin try/catch; si casesProvider falla, context.go('/home') nunca corre y el splash queda eterno; no hay FlutterError.onError ni runZonedGuarded.", 'case_repository.dart:14-26: un caso corrupto (pasó con BOM) hace fallar loadAll de todos; game_screen.dart:27-29 caseByIdProvider devuelve null tanto si carga como si el id no existe (spinner infinito); case_list_screen.dart:66 jsonDecode sin protección y :91 list.first sobre lista posiblemente vacía; home_shell.dart:204-205,529 oculta fallos con valueOrNull ?? [].']
- **Sugerencia:** Envolver la carga con manejo de errores y pantalla 'No se pudieron cargar los casos' con Reintentar y copiar diagnóstico; cargar cada caso en try/catch omitiendo y registrando el defectuoso; diferenciar 'cargando' de 'no existe'; proteger la lectura de resultados y evitar .first sobre listas vacías; cubrirlo con un test que inyecte un asset corrupto.

### H-65. Valores de juego escritos en el código (incumple el principio 3 de CLAUDE.md)

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: no · Origen: `codigo_app-7`

- **Problema:** Los números de balance viven en el código en vez de una fuente de configuración.
- **Impacto:** Cambiar bloqueo, límite de deshacer o dificultades exige recompilar y publicar; con Remote Config habrá que perseguir cada número disperso.
- **Evidencia:** ["game_controller.dart:331 bloqueo de 3 s (docs/03:250 solo dice 'unos segundos') y :120 _undoLimit = 50.", 'case_repository.dart:28 orden de dificultades fijo y main.dart:56-63 colores por dificultad por texto.', 'home_shell.dart:256,435 fecha base DateTime(2026,1,1) y mockMaxLives = 5; splash_screen.dart:33 espera artificial de 1700 ms; doc 08 define puntos, vidas y tiempos objetivo sin archivo de configuración.']
- **Sugerencia:** Crear una clase GameConfig inmutable con defaults de doc 08 inyectada por provider y alimentada luego desde Remote Config; dificultades como enum en el motor; fijar el valor del bloqueo en doc 08.
- **Nota del verificador:** Hay valores de balance dispersos en el código (bloqueo de 3 s, dificultades, vidas/fecha mock, espera del splash). El límite de deshacer coincide con el doc 08. Son retoques de bajo impacto en Fase 1; conviene centralizarlos antes de Remote Config.

### H-66. Restos del banco de pruebas y menores de pulido y estados de error

Gravedad: **Baja** · Esfuerzo: bajo · Decisión tuya: no · Origen: `codigo_app-12`

- **Problema:** Restos del vertical slice y del pase de diseño anterior que no deberían llegar a producción o confunden a un tester externo.
- **Impacto:** Bajo individualmente; juntos dan sensación de prototipo y puede filtrarse texto de pruebas a las tiendas.
- **Evidencia:** ["main.dart:80 title 'Enigmatrix — banco de pruebas'; pubspec description 'Fase 1 (vertical slice, web local)'; home_shell 'v0.1.0 · hecho en papel' duplica la versión; case_list_screen.dart:121-143,235-240 y victory_screen.dart:224-261 muestran 'Copiar feedback de playtest' y recuadro 'FEEDBACK DE PLAYTEST' en el flujo normal.", "Brand.displayFont ('Georgia') sin uso, Brand.backgroundDeep casi sin uso, PaletteNotifier.select sin llamadas, parámetro shrink siempre igual en _InfoPanel/_SuspectPanel; analysis_options solo con flutter_lints.", "Numeración ambigua: carpeta 'EXPEDIENTE Nº1/2' y fichas 'Nº 1..N' por sección, pero la hoja dice 'Caso Nº${number}' (case_list_screen.dart:287,563,652); 'Error cargando casos: $e' técnico sin reintento (:61).", "home_shell.dart:253-260,433-440 botones del reto sin efecto con lista vacía; victory_screen.dart:27-33 pierde el mejor tiempo al repetir; mundos bloqueados solo dicen 'Bloqueado'; Inicio dice 'La Mansión' con 20 casos de 3 dificultades."]
- **Sugerencia:** Antes de testers externos ocultar las herramientas de playtest tras un indicador de depuración, unificar el vocabulario (Caso Nº global vs Expediente), traducir errores a mensajes humanos con Reintentar, conservar el mejor tiempo, explicar cómo se desbloquea el siguiente mundo, leer la versión desde package_info_plus, limpiar código muerto al migrar al tema único y subir el nivel de lints (strict-casts, const) cuando el código esté ordenado.

## Experiencia de juego (UX)

### H-67. En teléfono, X, Borrador, Deshacer y Limpiar quedan bajo el pliegue mientras la papelera ocupa lugar visible

Gravedad: **Media** · Esfuerzo: medio · Decisión tuya: no · Origen: `ux_flujo-6`

- **Problema:** Las acciones más frecuentes al deducir están en la parte baja de una pantalla con scroll, obligando a desplazarse arriba y abajo.
- **Impacto:** Rompe el ritmo de juego y la sensación de 'un trayecto cabe en minutos'.
- **Evidencia:** ['game_screen.dart:110-133 y 193-204: orden vertical en móvil = cabecera, tablero (hasta 620), nota+pistas (~164 px), papelera (52) y solo después HERRAMIENTAS (X, Borrador) y controles; _SuspectPanel solo contiene las herramientas (:474-486).', 'Estimación por layout (sin ejecutar) supera ~740 px de alto de un teléfono; docs/09 pilar 5 prohíbe chrome mayor que el tablero y docs/02 pide papelera, deshacer y rehacer en la vista principal.']
- **Sugerencia:** Fijar una barra compacta (X, Borrador, Deshacer, Rehacer) pegada al tablero y relegar Limpiar, Mapa/Notas y Auto-X a un menú; verificar en dispositivo real 360×740 antes de fijar el reparto.
- **Nota del verificador:** Las herramientas X y Borrador, y los controles de _Controls, están después del tablero, las pistas y la papelera en una columna con scroll (game_screen.dart:193-204). En un teléfono de unos 360x740 probablemente quedan en el límite o bajo el pliegue. Esto es una estimación y falta medirlo en dispositivo real. La parte sobre docs/09 y docs/02 no fue verificada.

## Pruebas y calidad

### H-68. Nadie verifica que los 20 casos empaquetados siguen siendo válidos ni se tolera un archivo malo

Gravedad: **Alta** · Esfuerzo: bajo · Decisión tuya: no · Origen: `qa-3`

- **Problema:** El contenido que realmente ve el jugador no pasa por ninguna puerta automática; hoy son correctos (verificado a mano) pero no por una barrera permanente.
- **Impacto:** Al generar el Mundo 1 un caso con doble solución o malformado puede colarse; para un juego de deducción un caso sin solución única es el peor bug posible.
- **Evidencia:** ['Los tests del motor generan casos al vuelo con semillas 1-5 (generator_test.dart:33); ningún test lee app/assets/cases/*.json; enx_screens_smoke_test.dart:19-24 carga solo names.take(4) y no valida unicidad ni index.json.', "CLAUDE.md principio 5 'Todo caso publicado pasa por el solver'; el CLI tiene validate pero nadie lo ejecuta; casos generados 11-12-06 y el motor cambió después; index.json se lista a mano; tools/out/ contiene copias de los 20 casos.", 'case_repository.dart:15-24 sin try/catch por caso: un JSON roto hace fallar toda la lista.']
- **Sugerencia:** Test 'puerta de contenido' en tools/test que recorra app/assets/cases, valide cada JSON con Validator, UniquenessChecker.countSolutions == 1 y DeductionEngine resuelto y compruebe que index.json lista exactamente los archivos; requisito para cada lote nuevo; try/catch por caso en CaseRepository que omita y registre el defectuoso.

### H-69. pubspec.lock ignorado en la app: versiones de dependencias no reproducibles

Gravedad: **Media** · Esfuerzo: bajo · Decisión tuya: no · Origen: `qa-11`

- **Problema:** Para una app conviene versionar pubspec.lock; sin él cada máquina o limpieza puede resolver versiones distintas y no queda registro de qué versión salió en el APK probado.
- **Impacto:** Un build futuro puede cambiar de comportamiento o romperse sin que cambie el código y es difícil reproducir un bug de un APK anterior.
- **Evidencia:** [".gitignore:13 'pubspec.lock' (aplica a app/ y tools/, confirmado con git check-ignore); app/pubspec.lock existe en disco con go_router 16.3.0, flutter_riverpod 2.6.1, google_fonts 6.3.3.", 'Dependencias con rango caret; Flutter 3.41.4 instalado sin versión fijada en el repo; se planea compilar en un Mac aparte.']
- **Sugerencia:** Quitar 'pubspec.lock' del .gitignore para app/ (opcionalmente mantenerlo ignorado en tools/ por ser librería), commitear app/pubspec.lock y anotar en docs la versión de Flutter (3.41.4).

### H-70. Scripts .bat: JUGAR.bat sirve una versión vieja, PUBLICAR no prueba, sin versionado real y configuración con rutas fijas

Gravedad: **Baja (revisor: media)** · Esfuerzo: bajo · Decisión tuya: no · Origen: `qa-6`

- **Problema:** Tras la primera compilación Alejandro puede probar un build antiguo creyendo que es el nuevo; se puede generar un .aab de código roto o mal firmado; no se sabe qué build tiene el teléfono ni se puede subir un número de versión creciente.
- **Impacto:** Feedback sobre código ya cambiado, rondas desperdiciadas, bloqueo en el primer upload a Play y vista previa rota si se mueve la carpeta.
- **Evidencia:** ["JUGAR.bat solo compila si no existe build\\web\\index.html y requiere dhttpd global no documentado; docs/19:46 dice 'recompila web (automático en JUGAR.bat)'.", 'PUBLICAR-PLAYSTORE.bat solo hace flutter build appbundle --release; no corre dart test, flutter analyze ni flutter test, no verifica key.properties (cae a firma debug) y no publica nada.', "pubspec.yaml version 0.1.0+1 constante; sin tags git ni CHANGELOG; home_shell.dart:779 'v0.1.0' fijo; _copyFeedback sin versión; versionCode siempre 1 (Play exige creciente).", '.claude/launch.json (y copia en carpeta padre) usa ruta absoluta con espacios a app\\build\\web y no compila antes.', 'Fechas ISO en bitácora y docs vs preferencia dd-mm-yyyy de Alejandro.']
- **Sugerencia:** Hacer que JUGAR.bat siempre recompile (1-2 min) o compare fechas; crear VERIFICAR.bat (dart test en tools, flutter analyze y flutter test en app) y llamarlo desde COMPILAR y PUBLICAR; renombrar PUBLICAR a GENERAR-AAB; compilar con --build-name/--build-number desde git, mostrar versión y build en Perfil y en el encabezado del feedback, etiquetar cada APK instalado y mantener CHANGELOG.md; documentar dhttpd en doc 19; usar ruta relativa en launch.json; adoptar dd-mm-yyyy en la bitácora nueva.
- **Nota del verificador:** Quitar o rebajar el punto de fechas ISO (trivial). Aclarar que la firma debug solo ocurre si falta key.properties; el riesgo de versionCode fijo solo aplica al primer upload a Play.

### H-71. Sin pruebas en dispositivo real ni de integración de punta a punta

Gravedad: **Baja (revisor: media)** · Esfuerzo: medio · Decisión tuya: no · Origen: `qa-9`

- **Problema:** Los gestos delicados (long-press, arrastre, victoria a pantalla completa) se validan a ojo en un único teléfono y sin lista fija de pasos.
- **Impacto:** Regresiones específicas de dispositivo pasan desapercibidas y los 12 testers de Play reportarán problemas irreproducibles.
- **Evidencia:** ['No existe app/integration_test/ ni dependencia integration_test; docs/19:43-50 checklist solo con preguntas subjetivas.', 'Un solo teléfono Android, iOS jamás probado; sin manejo global de errores ni reporte de crashes.']
- **Sugerencia:** Un integration_test de 'camino dorado' (abrir app → tutorial → jugar caso → resolver mal → resolver bien → victoria) corrido antes de cada APK entregado; checklist de regresión de 8-10 pasos en docs/19 (gestos, rotación, volver atrás, sin red); evaluar Crashlytics al entrar a Fase 2.
- **Nota del verificador:** Presentarlo como mejora de bajo-medio impacto para Fase 1; priorizar un checklist de regresión corto antes que un integration_test completo.

## Descartados por el verificador

- **Choque de nombre: agente global 'arquitecto' de BBVA y agente 'arquitecto' del proyecto**: La evidencia clave es falsa. En .claude/agents del proyecto no hay arquitecto.md (head falla con 'No such file'). Hay 8 agentes y ninguno se llama igual que los 6 globales (apx-batch, apx-online, arquitecto, aso, documentador, lrba). No hay choque de nombres. Queda solo el riesgo menor de que la descripción genérica del arquitecto global se active por error.
- **Agentes sin modelo asignado y posible anulación del modelo por la variable de subagentes**: La premisa central es falsa. Los agentes del proyecto SÍ declaran model y effort en el frontmatter (backend, contenido-puzzles, frontend, puzzle-engineer, qa, revisor-docs, seguridad = sonnet; ejecutor-pruebas = haiku). Hay 8 agentes, no 6, y no existe .claude/agents/arquitecto.md en el proyecto (el arquitecto es la sesión principal; el arquitecto global está denegado en settings.json). CLAUDE.md:84 describe bien el diseño. Lo único que queda es la duda no verificada sobre si CLAUDE_CODE_SUBAGENT_MODEL=sonnet anula el haiku del ejecutor; es una especulación del propio revisor, sin evidencia.

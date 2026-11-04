# Enigmatrix - Revisión de seguridad Fase 1

> ACTUALIZACIÓN 04-11-2026 (auditoría 04-11-2026, hallazgos H-36, H-05 y H-07): esta revisión es del 12-07-2026 y se conserva. Dos de sus frases quedaron desfasadas respecto al código y se corrigen con notas debajo: (1) el permiso INTERNET ya no "llega con el template de debug", el manifiesto principal lo declara; (2) el build de publicación ya no usa la firma de debug por defecto, pero sigue pudiendo caer en ella si falta `key.properties`. Revisión actual de seguridad de la auditoría: `production/revisiones/2026-11-04-auditoria-proyecto.md`.

Fecha: 2026-07-12. Alcance: app local (banco de pruebas), sin backend, sin
cuentas, sin pagos. La superficie de ataque real llega en Fase 2 (Firebase);
esta revisión cubre lo que existe hoy y deja listo el terreno.

## Hallazgos y correcciones aplicadas

### 1. Backup de Android exponía las preferencias — CORREGIDO
- Riesgo: con `allowBackup` activo (default), `adb backup` permite extraer y
  restaurar las SharedPreferences → manipulación trivial de progreso local.
- Fix: `android:allowBackup="false"` en el manifest.

### 2. Tráfico en claro no prohibido explícitamente — CORREGIDO
- Riesgo: si en Fase 2 una librería intentara HTTP plano, Android lo
  permitiría en configuraciones antiguas.
- Fix: `android:usesCleartextTraffic="false"` en el manifest. Todo el
  tráfico futuro debe ser HTTPS.

### 3. Sin permisos innecesarios — VERIFICADO
- El manifest no pide ubicación, cámara, contactos ni almacenamiento
  externo. Solo lo que Flutter requiere (INTERNET llega con el template de
  debug; el release no declara permisos extra).
- ACTUALIZACIÓN 04-11-2026 (H-36, H-07): la frase anterior ya no es cierta.
  El manifiesto principal (`app/android/app/src/main/AndroidManifest.xml`)
  declara INTERNET, así que lo incluye también el release (el commit
  28bbde9 de cumplimiento de tiendas lo añadió). Se usa solo para que
  `google_fonts` descargue las tipografías la primera vez que se abre la app
  y para el futuro backend de la Fase 2; sigue sin pedir ubicación, cámara,
  contactos ni almacenamiento externo. Ver `docs/15-legal.md` y
  `docs/20-checklist-tiendas.md` sobre la política de privacidad.

### 4. La solución del caso NO se registra en logs — VERIFICADO
- `grep print(` sobre `app/lib` y `tools/lib`: sin salidas que expongan
  la solución, el asesino o el arma.

## Riesgo aceptado (decisión de diseño, no bug)

### La solución viaja dentro del JSON del caso local
- En Fase 1 los casos son assets locales CON solución, y el botón Resolver
  valida en el cliente. Cualquiera que descomprima el APK puede leerla.
- Esto está aceptado y documentado en el roadmap (17, Fase 1: "throwaway
  aceptado") porque el banco de pruebas no es competitivo: no hay ranking,
  puntos oficiales ni racha.
- REGLA para Fase 2 (innegociable, ya en CLAUDE.md y doc 07): el cliente
  NUNCA recibe la solución; valida Cloud Functions; puntos/vidas/racha solo
  se actualizan tras validación del servidor.

## Pendientes de seguridad para fases siguientes
- Fase 2: reglas de Firestore restrictivas por usuario; App Check;
  validación de recibos de compra en servidor (Fase 3).
- Firma de release: el APK actual usa la firma de debug. Antes de publicar:
  keystore propio guardado FUERA del repositorio + `signingConfigs` de
  release. Nunca commitear el keystore ni sus contraseñas.
  - ACTUALIZACIÓN 04-11-2026 (H-36, H-05): ya existe una llave de subida y
    `app/android/app/build.gradle.kts` firma el release con ella cuando
    encuentra `key.properties` (commit 28bbde9); los dos archivos están
    fuera de git (`.gitignore`). Lo que sigue SIN resolverse: (a) el
    respaldo de la llave en un medio independiente no está hecho; (b) la
    llave y su contraseña (en texto plano) están juntas en una carpeta
    sincronizada con OneDrive y el proyecto no tiene repositorio remoto; (c)
    si falta `key.properties` (otro PC, el Mac), el build firma con la llave
    de debug sin avisar. Mover la llave y cambiar la configuración de firma
    todavía NO están autorizados por Alejandro.
- `FLAG_SECURE` (bloqueo de capturas) aplica cuando existan partidas
  oficiales (Fase 2), no en el banco de pruebas.
- Ofuscación Dart (`--obfuscate --split-debug-info`) cuando el binario
  contenga lógica sensible; hoy no aporta porque la solución local es
  riesgo aceptado.

# ADR-0009: Almacenamiento local con shared_preferences (en vez de Hive o Isar) y tipografías con google_fonts

> ACTUALIZACIÓN 05-11-2026 (versión 0.5.0+5, H-07): las tipografías (Baloo 2, Quicksand y Patrick Hand, licencia OFL) ahora van **dentro de la app** y ya no se descargan de Google. El permiso **INTERNET** se quitó del manifiesto principal de Android porque solo lo usaba esa descarga; vuelve en la etapa 5 (Firebase). Donde este documento diga que la app declara INTERNET o descarga las fuentes con google_fonts, eso ya no aplica.

- **Estado**: Propuesto (retroactivo). Escrito el 04-11-2026 para dejar por escrito dos decisiones ya tomadas en el código; falta que se acepten formalmente.
- **Fecha**: 10-06-2026 (almacenamiento local, primer commit de la app) y 11-07-2026 (tipografías con `google_fonts`)
- **Decisores**: el arquitecto (decisión técnica reversible, delegada); Alejandro no participó en la elección de estas librerías.

## Contexto

El doc 07 (arquitectura) y CLAUDE.md decían que el cache local sería `Hive` o `Isar`. Al construir la Fase 1 hacía falta guardar solo cosas pequeñas: casos resueltos, el nombre del jugador, ajustes y marcas como "tutorial visto". Para las fuentes, el pase de diseño del 11-07-2026 necesitó tipografías con carácter, y la forma más rápida de tenerlas fue la librería `google_fonts`.

## Decisión

1. **Almacenamiento local = `shared_preferences`** (pares clave-valor sencillos). Se usa desde el primer commit de la app (10-06-2026, `e920fe0`) y no se agregó ni Hive ni Isar. Sigue siendo "solo cache, nunca fuente de verdad".
2. **Tipografías con `google_fonts`**: Quicksand para el cuerpo, Baloo 2 para titulares y Patrick Hand para lo manuscrito (`app/lib/src/ui/enx_style.dart`). No están incluidas dentro de la app: se descargan de Google la primera vez que se abre.

## Alternativas consideradas

- **Hive o Isar** (bases de datos locales, lo que decían doc 07 y CLAUDE.md). No: para guardar progreso y preferencias en la Fase 1 sobran. No se usaron.
- **Empaquetar las fuentes dentro de la app**. No se hizo en su momento por rapidez. La auditoría lo recomienda (H-07), ver Consecuencias.
- **Las candidatas del doc 10** (Inter, DM Sans o Manrope; Fraunces o Playfair; Caveat). No: el doc 10 las dejaba "pendientes tras prueba en pantallas reales" y nunca se hizo la prueba.

## Consecuencias

- Se gana simplicidad: cero configuración y una sola dependencia.
- `shared_preferences` no está pensada para datos grandes o con estructura. Guardar la partida completa (que la auditoría pide, H-55) puede obligar a reevaluar el almacenamiento en la etapa 4. Eso se decidirá entonces; este ADR no lo anticipa.
- Las claves están repartidas por varios archivos (H-61).
- Los documentos 07 (líneas 55 y 337) y 10 siguen diciendo Hive o Isar y otras tipografías; se corrigen en otras tareas de la etapa 0 (H-41, H-37). CLAUDE.md ya quedó corregido.
- **Problemas de las fuentes descargadas** (H-07, H-59):
  - cada instalación contacta a Google en la primera apertura. La política de privacidad dice que no se envían datos personales, pero Google recibe la dirección IP, que un tribunal alemán trató como dato personal;
  - si esa primera apertura es sin conexión, la app usa otra tipografía y puede verse rota;
  - por eso el manifiesto de la versión de publicación declara el permiso de Internet (commit `28bbde9`), el único que necesita hoy;
  - la fuente de respaldo "Segoe Script" (`app/lib/main.dart`) no existe en Android ni en iPhone.
- La auditoría recomienda empaquetar las tres fuentes (licencia OFL), dejar de descargarlas, quitar el permiso de Internet hasta que haya servidor, reemplazar Segoe Script y simplificar la política. **Eso aún no se hizo** y no tiene etapa asignada en el plan del 04-11-2026. La tipografía final depende además de la dirección visual (ver ADR-0005).

## Fuentes

- `app/pubspec.yaml` (`shared_preferences`, `google_fonts`; sin Hive ni Isar) y `app/lib/src/ui/enx_style.dart`.
- Commits `e920fe0` (10-06-2026, primera app con `shared_preferences`), `9095290` (11-07-2026, primera aparición de `google_fonts`) y `28bbde9` (12-07-2026, INTERNET en el manifiesto).
- `docs/07-arquitectura.md` (líneas 55 y 337) y `docs/10-arte.md`, sección "Tipografia".
- `production/session-state/active.md`, entradas "2026-07-11 — PASE ENX v2" y "2026-07-12 — CUMPLIMIENTO DE TIENDAS".
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-07, H-14, H-37, H-55, H-59, H-61.

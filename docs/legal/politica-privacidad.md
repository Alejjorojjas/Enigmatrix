# Política de Privacidad — Enigmatrix

> PENDIENTE ANTES DE PUBLICAR (11-11-2026): este texto está desactualizado. La app ya no descarga tipografías de Google (van dentro de la app) y sí declara permisos de red por las librerías de Firebase, aunque hoy no envía datos. Hay que reescribir "Qué datos recolectamos" y "Conexión a internet", poner el nombre "Murdoku Diario" y completar responsable y correo.

Última actualización: 12 de julio de 2026

> ACTUALIZACIÓN INTERNA 04-11-2026 (auditoría 04-11-2026, hallazgos H-06, H-07, H-08 y H-09). Este borrador NO está listo para publicar y esta nota se borra al publicar, igual que la nota interna de abajo. Lo que sigue pendiente:
>
> - **Nombre del responsable y correo de privacidad: SIGUEN SIN COMPLETARSE.** Dependen de la decisión 17 (identidad legal), que todavía no ha tomado Alejandro (**PENDIENTE DE DECISIÓN**, auditoría 04-11-2026, pregunta 17). No se rellenan los corchetes hasta entonces.
> - **Edad mínima:** el texto dice "mayores de 12 años". **DECIDIDO 06-11-2026** (pregunta 16, H-09): 13 años o más. El texto ya está alineado.
> - **Tipografías:** las secciones "Qué datos recolectamos" y "Conexión a internet" dicen que no se recolecta nada y que la descarga de tipografías "no envía datos personales". La app sí descarga las tipografías de Google Fonts (`google_fonts`) la primera vez que se abre, y con esa conexión la dirección IP del dispositivo llega a Google; según lo investigado, un tribunal alemán (2022) la trató como dato personal (H-07). Hay que revisar esas dos frases, o empaquetar las tipografías dentro de la app para que no haya descarga; ese cambio de código no está hecho.
> - **Enlace dentro de la app:** hoy la app no tiene ningún botón que abra esta política (H-06), y Apple exige uno.
> - **Solo está en español.** Falta la versión en inglés (`docs/07-arquitectura.md` la prevé).
> - Estado de la app hoy: no hay cuentas, anuncios ni compras reales; la Tienda, Premium y el Ranking son pantallas simuladas marcadas "DEMO". Ver `docs/15-legal.md` y `docs/20-checklist-tiendas.md`.

> NOTA INTERNA (borrar al publicar): ambas tiendas exigen esta política
> alojada en una URL pública (sirve GitHub Pages). Este texto cubre la
> versión actual de la app (sin cuentas ni recolección de datos). Cuando
> entre la Fase 2 (cuentas, ranking, Firebase) DEBE actualizarse con las
> secciones marcadas [FASE 2]. Revisión por abogado recomendada antes del
> lanzamiento comercial (ver docs/15-legal.md).

## Quiénes somos

Enigmatrix es un juego móvil de deducción lógica. Responsable del
tratamiento: [NOMBRE DEL RESPONSABLE — persona natural], Colombia.
Contacto: [CORREO DE PRIVACIDAD].

## Qué datos recolectamos

**Ninguno.** La versión actual de Enigmatrix:

- No requiere cuenta ni registro.
- No recolecta datos personales, identificadores ni ubicación.
- No usa publicidad ni SDKs de terceros de análisis o rastreo.
- No comparte ni vende información de ningún tipo.

## Qué se guarda en tu dispositivo

Tu progreso de juego (casos resueltos, tiempos y notas de práctica) se
guarda únicamente en el almacenamiento local de tu dispositivo. Se elimina
al desinstalar la app y nunca sale de tu teléfono.

## Conexión a internet

La app puede descargar tipografías desde servidores de Google Fonts la
primera vez que se abre. Esa conexión no envía datos personales.

## Menores de edad

Enigmatrix está dirigida a personas de 13 años o más y no recolecta datos de
ningún usuario, incluidos menores.

## Cambios a esta política

Publicaremos cualquier cambio en esta misma página, actualizando la fecha
del encabezado. Si en el futuro el juego añade cuentas, rankings en línea u
otras funciones que traten datos personales, esta política se actualizará
ANTES de activar esas funciones, detallando qué datos se tratan, con qué
base legal y cómo ejercer tus derechos (acceso, rectificación, supresión).

## Contacto

Para cualquier pregunta sobre privacidad: [CORREO DE PRIVACIDAD].

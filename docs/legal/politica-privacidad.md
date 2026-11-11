# Política de Privacidad — Murdoku Diario

> NOTA INTERNA (borrar las notas al publicar). Reescrita el 11-11-2026 para la versión 0.8.1 que está en las tiendas.
>
> **Sigue pendiente:**
> - **Responsable y correo:** completar los dos corchetes. La app se publica en la cuenta de desarrollador del socio de Alejandro (ADR-0017), así que hay que acordar quién figura como responsable y qué correo atiende la privacidad.
> - **Publicarla en una URL pública:** las dos tiendas la exigen. Sirve GitHub Pages desde un repositorio PÚBLICO aparte que solo contenga esta página, o cualquier alojamiento gratuito.
> - **Botón en la app:** Apple exige un enlace a esta política dentro de la app (H-06).
> - **Inglés:** falta la versión en inglés.
> - **Cuando se encienda el servidor** (etapa 5A.3, Firebase real), esta política DEBE actualizarse ANTES con la sección "Cuando el juego tenga funciones en línea", que hoy está como borrador al final.
> - Se recomienda revisarla con un abogado antes del lanzamiento comercial (`docs/15-legal.md`).

Última actualización: [FECHA DE PUBLICACIÓN]

## Quiénes somos

Murdoku Diario es un juego móvil de deducción lógica.

- Responsable del tratamiento: [NOMBRE DEL RESPONSABLE], Colombia.
- Contacto: [CORREO DE PRIVACIDAD].

## Qué datos recolectamos

**Ninguno.** La versión actual de Murdoku Diario:

- no requiere cuenta ni registro;
- no recolecta datos personales, identificadores de publicidad ni ubicación;
- no usa publicidad ni herramientas de análisis o rastreo de terceros;
- no comparte ni vende información de ningún tipo;
- no tiene compras dentro de la app.

## Qué se guarda en tu dispositivo

Tu progreso de juego se guarda únicamente en el almacenamiento local de tu teléfono y nunca sale de él. Incluye:

- los casos resueltos;
- las partidas en curso;
- los tiempos;
- tus preferencias de apariencia, sonido y vibración.

Se elimina al desinstalar la app.

## Permisos y conexión a internet

La app declara permisos de red (acceso a internet y estado de la red). Los incluyen las librerías que el juego usará en una versión futura con funciones en línea.

**En la versión actual el juego funciona completamente sin conexión y no envía datos a ningún servidor.** Las tipografías van incluidas dentro de la app y no se descargan.

## Menores de edad

Murdoku Diario está dirigido a personas de 13 años o más. No recolecta datos de ningún usuario, incluidos menores.

## Cambios a esta política

Publicaremos cualquier cambio en esta misma página y actualizaremos la fecha del encabezado.

Si el juego añade cuentas, rankings en línea u otras funciones que traten datos, esta política se actualizará ANTES de activarlas. Detallará qué datos se tratan, para qué, con qué base legal y cómo ejercer tus derechos: acceso, rectificación y supresión, incluido el borrado de la cuenta desde la app.

## Contacto

Para cualquier pregunta sobre privacidad: [CORREO DE PRIVACIDAD].

---

> BORRADOR INTERNO, no publicar hasta la etapa 5A.3. Sección "Cuando el juego tenga funciones en línea", según el diseño `production/planes/2026-11-07-etapa-5a-diseno.md`:
>
> - **Identificador anónimo:** se crea un identificador anónimo de Firebase Authentication (Google), sin correo ni nombre.
> - **Datos de cada partida:** el servidor guarda el caso, el tiempo, los errores y si fue resuelta, para validar la solución, calcular puntos y armar el ranking.
> - **Verificación del dispositivo:** se usa Firebase App Check (Google) para comprobar que las solicitudes vienen de la app original.
> - **Ubicación de los servidores:** Google Cloud, región `southamerica-east1` (São Paulo).
> - **Borrado de cuenta:** desde la app, con eliminación de esos datos.

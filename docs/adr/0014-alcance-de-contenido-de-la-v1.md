# ADR-0014: Alcance de contenido y dificultades de la V1, y versión de la prueba de juego

- **Estado**: Aceptado
- **Fecha**: 05-11-2026
- **Decisores**: usuario (Alejandro) / arquitecto

## Contexto

- **Generador.** La medición de la ronda 3.1 (`production/revisiones/2026-11-05-medicion-12x12-16x16.md`) mostró que el generador solo saca 2 de 5 casos Experto (12×12) y ninguno Élite (16×16). Casi todos los descartes son "sin reparaciones posibles", así que el motor necesita trabajo antes de soportar esos tamaños.
- **Contenido pendiente.** Faltaba decidir con cuánto contenido sale la V1 (pregunta 14 de la auditoría) y si entran Experto y Élite (pregunta 13).
- **Versión para la prueba.** La versión 0.3.0+3 (commit `c98f7ca`) ya trae el tablero nuevo (ADR-0013) además de todo lo de la 0.2.0+2. La prueba de juego con personas aún no había empezado.

## Decisión

1. **Dificultades de la V1:** Principiante, Casual e Intermedio. **Experto y Élite llegan en una actualización** cuando el motor los genere de forma confiable.
2. **Contenido de lanzamiento:** el **Mundo 1, "La Mansión", con 10 casos** de dificultad creciente y su narrativa propia, más **30 días de reto diario** con casos Casual e Intermedio.
3. **Prueba de juego n.º 1:** se hace con la **versión 0.3.0+3**, que queda congelada para la prueba. La copia está en `Proyecto Enigmatrix/APKs/enigmatrix-0.3.0+3-arm64.apk`.
4. **Arrastrar un retrato a una casilla no se recupera.** Para confirmar quedan tres formas: la herramienta Confirmar, mantener oprimido y tocar dos veces. Esto precisa el ADR-0013, que mencionaba "o arrastrar".

## Alternativas consideradas

- **Incluir Experto o Élite en la V1.** Exige trabajo de motor de resultado incierto y retrasa el lanzamiento.
- **Más contenido (60 días o dos mundos).** Retrasa el lanzamiento. Se puede agregar por actualizaciones.
- **Prueba de juego con la 0.2.0+2.** No mediría la sensación de juego del tablero nuevo, que es justo lo que se quiere validar.

## Consecuencias

- **Ronda 3.2:** genera el Mundo 1 y los 30 días de reto dentro de los rangos provisionales. Esos rangos se ajustan con los datos de la prueba de juego, así que algunos casos podrían regenerarse.
- **Interfaz:** la app no debe mostrar Experto ni Élite como disponibles en la V1, o debe marcarlos "Próximamente".
- **Documentos:** el roadmap y los docs 05 y 08 deben reflejar estas dificultades de lanzamiento.
- **Guía de la prueba:** `production/prueba-de-juego/guia-prueba-1.md` pasa a la versión 0.3.0+3.

## Actualización 05-11-2026

- **Pregunta 19 (arma homicida), decidida por Alejandro:** se mantiene como quedó en la ronda 3.2. El arma aparece en 3 de los 4 casos Intermedio del Mundo 1 (mansion-08 a mansion-10) y en 9 de los 30 retos, los últimos de cada semana.
- **Tipografías:** Alejandro autorizó descargar Baloo 2, Quicksand y Patrick Hand (licencia OFL) desde el repositorio oficial de Google Fonts para incluirlas dentro de la app (H-07).

## Nota 06-11-2026

- **Cuentas de tienda:** Alejandro ya tiene pagadas la cuenta de desarrollador de Google Play y la de Apple (`production/planes/2026-11-06-etapas-5-y-6.md`, sección 1). Esto **no cambia el alcance** de esta decisión. Android sigue siendo lo único decidido para la V1; si el iPhone entra al lanzamiento sigue siendo la pregunta 22 y está pendiente de Alejandro.
- La versión web queda para la V2 (decisión del mismo día).

## Actualización 09-11-2026: entra el iPhone

Alejandro pidió subir la app también a la App Store. Con eso la V1 deja de ser solo Android y queda resuelta la pregunta 22. El contenido no cambia (dificultades, Mundo 1, 30 días de reto). La publicación va primero por TestFlight, en la cuenta de Apple del mismo amigo de la cuenta de Google Play (ADR-0017, sección App Store).

## Decisiones de Alejandro (11-11-2026), tras la revisión con Claude Code Game Studios

- **Pregunta 12 (ayudas y puntuación):** la V1 de tienda sale **sin ayudas ni puntos**. La victoria muestra tiempo y errores. Las ayudas y los puntos llegan con el ranking del servidor (etapa 5B).
- **Modo daltónico:** se aplaza a la **V1.1**. Antes de la publicación abierta hay que validar con un simulador de daltonismo (los tres tipos) que las habitaciones se distinguen también por paredes y nombres. Si no se distinguen, se corrige antes de esa publicación.
- **Casillas del 9×9:** se acepta como **excepción documentada** al mínimo de 48 px del doc 11 (unos 37 px en un teléfono de 360 de ancho). Se apoya en la confirmación por toque doble. Alejandro lo prueba en su teléfono y, si resulta incómodo, se corrige.
- **Responsable de la política de privacidad:** Alejandro (Diego Alejandro Rojas Corredor), aunque la app se publique en las cuentas de su socio (ADR-0017). Falta el correo de contacto.

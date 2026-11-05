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

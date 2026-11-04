# ADR-0012: Reglas decididas antes de la prueba de juego

- **Estado**: Aceptado 04-11-2026 (decisión explícita del dueño). Alejandro aceptó en chat las recomendaciones de la sección 5 de la auditoría para las preguntas 5, 9, 10, 11 y 20.
- **Fecha**: 04-11-2026
- **Decisores**: Alejandro (usuario), a propuesta del arquitecto a partir de la auditoría del proyecto.

## Contexto

La etapa 1 del plan (ADR-0011) mide si el juego es divertido y justo. Para que la medición no salga sucia hacían falta cinco reglas que los documentos dejaban sin definir o contradictorias. La auditoría del 04-11-2026 las agrupó en el bloque "Antes de la prueba de juego" de su sección 5:

- **Vidas (pregunta 5; H-26).** Ningún documento dice qué pasa al quedar con 0 vidas. Al implementar las vidas se inventaría la regla, y una mala decisión viola el pilar 4 (sin castigo injusto) o deja al jugador atascado con el reloj corriendo.
- **Resolver (pregunta 9; H-28).** Hoy el botón marca exactamente las casillas erróneas con 3 segundos de bloqueo. Cada pulsación es una pista gratuita y se puede resolver por ensayo y error, lo que debilita el pilar 1 (deducción pura).
- **Salir de la partida y reloj (pregunta 10; H-55 y H-32).** El tablero, las marcas, el cronómetro y los errores viven solo en memoria: un toque accidental o una llamada borran 10 a 20 minutos de deducción. El doc 03 dice que el tiempo sigue corriendo si la app se minimiza, pero el cronómetro por ticks se detiene cuando Android suspende la app. Choca con los pilares 3 y 4.
- **Tutorial (pregunta 11; H-29).** Hay dos tutoriales, los dos se pueden saltar, no enseñan mecánicas clave y el jugable consume el Caso 1. El momento de mayor pérdida de jugadores es el primero.
- **Gesto de colocar (pregunta 20; H-25).** Confirmar una ficha exige mantener oprimido o arrastrar, un gesto poco descubrible que puede confundirse con "la app no responde". Tocar una casilla sin sospechoso elegido no da respuesta, y el doc 11 pide una alternativa al arrastre.

## Decisión

Se adoptan estas cinco reglas:

1. **Regla 5, vidas.** Con 0 vidas no se puede pulsar Resolver ni empezar casos nuevos. La partida queda guardada para seguir cuando se recupere una vida o se vea un anuncio.
2. **Regla 9, errores al resolver.** Al fallar en Resolver se muestra solo cuántas casillas no cuadran, no cuáles. El resaltado exacto y el parpadeo de la pista en conflicto quedan solo para el tutorial.
3. **Regla 10, salir y reloj.** La partida se guarda siempre. Al salir, el reloj se pausa y el tablero se oculta durante la pausa. Esto vale mientras no haya ranking real y la regla se revisa antes de la etapa 5. Reemplaza lo de "el tiempo sigue corriendo si la app se minimiza" del doc 03.
4. **Regla 11, tutorial.** El tutorial es un caso propio pequeño (4×4 o 5×5) que no cuenta como Caso 1. Enseña también la X, las notas, la papelera y un Resolver fallido. Es obligatorio la primera vez, con un botón Saltar visible.
5. **Regla 20, gesto de colocar.** Al tocar una casilla sin sospechoso elegido aparece el aviso "Elige primero a un sospechoso". Hay un modo alternativo de tocar dos veces (elegir y tocar el destino) además de mantener oprimido o arrastrar. Se diseña en la prueba de concepto (etapa 2).

## Alternativas consideradas

> Nota del arquitecto: Alejandro aceptó las recomendaciones de la sección 5 de la auditoría. Las alternativas de esta sección las redactó el agente a partir de esa auditoría, como contexto; no son opciones que Alejandro haya evaluado una por una.

- **Regla 5:** dejar seguir jugando sin vidas, o permitir Resolver con 0 vidas. No: el jugador podría resolver por ensayo y error sin costo, o quedaría atascado con el reloj corriendo.
- **Regla 9:** mantener el resaltado exacto en toda la app, o mostrarlo solo en la práctica. No: convierte cada Resolver en una pista gratuita. Queda para el tutorial, donde sí conviene enseñar.
- **Regla 10:** que el reloj siga corriendo al salir, como decía el doc 03. No: castiga una llamada o un cierre accidental (pilares 3 y 4) y no se puede cumplir con el cronómetro actual. Se oculta el tablero durante la pausa para que no se pueda pensar con el reloj detenido.
- **Regla 11:** tutorial opcional como los dos actuales, o un tutorial sobre el Caso 1. No: se salta o consume el primer caso real.
- **Regla 20:** dejar solo mantener oprimido y arrastrar, o cambiarlo todo a doble toque. No: lo primero incumple el doc 11 y lo segundo cambia el gesto que ya existe. Se conservan ambos.

## Consecuencias

- Las reglas quedan decididas, pero **no están implementadas**: los cambios de código de la versión de prueba (etapa 1) los autoriza Alejandro aparte.
- Los documentos afectados se corrigieron el 04-11-2026 (01, 02, 03, 05, 06, 08, 10, 11, 16, 17, 19 y 20, y los ADR 0007, 0008 y 0011). Lo anterior quedó marcado como superado, sin borrarlo.
- **La animación de error del informe gráfico se reserva para el tutorial**, porque la regla 9 impide mostrar en la partida qué casillas fallan.
- La regla 10 es provisional: se revisa antes de la etapa 5, cuando haya ranking real y el tiempo importe para la clasificación. Hay que decidir entonces si el tiempo pausado cuenta.
- La regla 5 depende de que existan vidas funcionales en la versión de prueba; hoy son datos simulados fijos (ADR-0007). La pregunta 6 (vidas de premium) sigue abierta.
- El modo de tocar dos veces de la regla 20 se diseña en la prueba de concepto gráfica, de modo que su forma final no se fija hasta la etapa 2.

## Fuentes

- `production/revisiones/2026-11-04-auditoria-proyecto.md`, sección 5 (preguntas 5, 9, 10, 11 y 20).
- `production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md`: H-25, H-26, H-28, H-29, H-32 y H-55.
- `docs/17-roadmap.md`, sección "Decisiones de Alejandro del 04-11-2026" y etapa 1.
- `docs/adr/0011-plan-por-etapas-aprobado-el-04-11-2026.md`.
- `production/session-state/active.md`, decisiones del 04-11-2026.

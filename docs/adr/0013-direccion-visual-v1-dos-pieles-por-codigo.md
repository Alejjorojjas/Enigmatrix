# ADR-0013: Dirección visual de la V1 con tablero en Flame, dos pieles elegibles y arte hecho por código

- **Estado**: Aceptado
- **Fecha**: 05-11-2026
- **Decisores**: usuario (Alejandro) / arquitecto

## Contexto

El 01-11-2026 Alejandro rechazó el aspecto del juego ("no parece un juego"). La investigación gráfica (`production/revisiones/2026-11-04-investigacion-grafica.md`) recomendó la opción A: seguir en Flutter con el tablero como escena de Flame, más game feel, sonido y vibración. Para decidir con datos se construyó un prototipo técnico (`prototipos/tablero-flame/`, etapa 2).

El 05-11-2026 Alejandro dio unas referencias visuales (`docs/referencias-visuales/`) y pidió comparar dos pieles: "Ilustrada" y "Papel". Las dos tienen modo claro y oscuro, que sigue al teléfono, y el arte provisional está hecho por código. Tras una ronda de corrección (tablero a todo el ancho, letra de 13 px o más, rótulos que no se montan, Papel claramente distinta, sillas reconocibles) Alejandro las vio y las probó en su Android de gama media.

## Decisión

1. **El juego completo adopta el tablero del prototipo**: escena de Flame, director de feedback, sonidos propios y vibración, con **dos pieles elegibles en Configuración, "Ilustrada" y "Papel"**, cada una en **modo claro y oscuro** (arranca según el teléfono, con interruptor).
2. **La versión 1 sale con arte hecho por código**: muebles, pisos y retratos provisionales mejorados. Si se pasa a ilustración (ilustrador, IA o mixto) se revisa en la **V2**.
3. **Las herramientas de la partida son Anotar, Tachar, Confirmar y Borrar**:
   - Anotar = candidato.
   - Tachar = X a mano.
   - Confirmar = un toque fija al sospechoso; mantener oprimido o arrastrar también confirma. Esto cumple el gesto alternativo de la regla 20 del ADR-0012.
   - Borrar = borrador.

## Evidencia

- **Fluidez**: Alejandro instaló el prototipo y reporta que "se ve fluido" en su Android de gama media. No dio una cifra de cuadros por segundo. Se pide medirla con el medidor del prototipo antes de cerrar la etapa 4.
- **Calidad del prototipo**: 160 tests pasan, el analizador no reporta problemas y una revisión independiente no encontró copia textual de la referencia.

## Alternativas consideradas

- **Una sola piel.** Es menos trabajo, pero Alejandro quiere ofrecer las dos.
- **Arte final de ilustrador o IA ya en la V1.** Mejoraría los retratos, pero cuesta dinero y tiempo. Se pospone a la V2 para lanzar antes.
- **Otro motor (Unity o Godot).** No hace falta: el prototipo en Flame se ve fluido en el teléfono de prueba.

## Consecuencias

- **Etapa 4.** Hay que llevar el tablero de Flame y las dos pieles a la app (`app/`) y retirar el tablero de widgets. Antes van las pruebas automáticas de la partida (H-57) y la separación de geometría, toques y validación (H-60). Los colores, los tokens y las pantallas del resto de la app (Inicio, lista de casos, perfil, configuración) también deben salir del tema de cada piel y modo.
- **Doble trabajo visual.** Cada mueble y cada elemento nuevo se dibuja dos veces, una por piel. Las dos pieles comparten los datos, la interacción y el director de feedback.
- **Retratos.** Los provisionales por código son agradables pero no llegan a ilustración. Para la V2 queda abierta la decisión sobre el arte final.
- **Reemplazos.** Este ADR reemplaza parcialmente al ADR-0005 (Paper Craft como estilo del juego actual): el estilo pasa a ser estas dos pieles. El doc 10 (arte) debe reescribirse con esta dirección.

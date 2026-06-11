# ADR-0002: Gestión de estado con Riverpod

- **Estado**: Aceptado
- **Fecha**: 2026-06-10
- **Decisores**: arquitecto (decisión técnica delegada; el doc 07 dejaba "Riverpod o Bloc" abierto)

## Contexto

El doc 07 no cerró la elección entre Riverpod y Bloc. El proyecto lo desarrolla Claude con un dueño de producto no programador: pesa más la legibilidad y menos el boilerplate que las convenciones de equipo grande.

## Decisión

**Riverpod** (con generación de código `riverpod_generator` donde aporte).

## Alternativas consideradas

- Bloc — excelente trazabilidad evento→estado, pero mucho más boilerplate por feature; su beneficio principal (disciplina en equipos grandes) no aplica aquí.
- Provider — antecesor de Riverpod, sin razones para preferirlo hoy.
- setState/InheritedWidget puro — insuficiente para estado compartido (sesión, vidas, partida).

## Consecuencias

- Menos código por pantalla; testabilidad buena (providers sobrescribibles en tests).
- El estado del tablero en partida (dominio puro, deshacer/rehacer) se modela como clase inmutable propia en `tools/`/dominio y Riverpod solo lo expone — la lógica de juego no se acopla al framework de estado.

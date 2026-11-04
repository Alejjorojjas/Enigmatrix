# Enigmatrix - Índice de la documentación

Última actualización de este índice: 04-11-2026 (decisiones de Alejandro del 04-11-2026 y ADR-0012; etapa 0 del plan aprobado ese día; hallazgo H-34 de la auditoría).

Este índice dice qué documentos hay en `docs/`, para qué sirve cada uno, **si se puede confiar en él hoy** y qué lo reemplaza o lo complementa. Antes de usar un documento, mira su estado aquí.

Auditoría que originó el índice: [production/revisiones/2026-11-04-auditoria-proyecto.md](../production/revisiones/2026-11-04-auditoria-proyecto.md). Detalle de cada hallazgo (H-xx): [anexo de hallazgos](../production/revisiones/2026-11-04-auditoria-anexo-hallazgos.md).

## Qué significa cada estado

| Estado | Significado |
|---|---|
| **VIGENTE** | Describe lo que se decidió o lo que existe hoy. Se puede usar como guía. |
| **PARCIALMENTE OBSOLETO** | Una parte ya no es cierta (código distinto, decisión cambiada). Lo superado está marcado con un banner o con la palabra SUPERADO, y los temas que decide Alejandro llevan la marca PENDIENTE DE DECISIÓN. Se usa lo que no está marcado. |
| **EN REVISIÓN** | Se está reescribiendo o recalibrando. No se usa como referencia hasta que termine la revisión; sus propuestas no son definitivas. |
| **VISIÓN FUTURA** | Describe lo que se quiere construir en el lanzamiento completo, no lo que la app hace hoy. Sirve como meta, no como descripción. |
| **SUPERADO** | Ya no manda. Se conserva solo como historia. |

La columna "Última verificación" indica cuándo se contrastó el documento con el código y con la auditoría. **04-11-2026** es la fecha de la puesta al día de la etapa 0. Los documentos marcados "Leído 04-11-2026, sin contrastar con el código" no tienen aviso de la auditoría y no se han comprobado contra el código: tómalos con cuidado.

## Documentos de docs/

| Documento | Para qué sirve | Estado | Última verificación | Qué lo reemplaza o lo complementa |
|---|---|---|---|---|
| [01-mvp-v1.md](01-mvp-v1.md) | Alcance del MVP completo (la visión del producto) y pendientes técnicos. Lleva las decisiones que Alejandro tomó el 04-11-2026. | VISIÓN FUTURA (con pendientes técnicos cerrados y abiertos marcados) | 04-11-2026 | Lo que existe hoy está en [17-roadmap.md](17-roadmap.md) (estado verificado) y en `production/session-state/active.md`. |
| [02-flujo.md](02-flujo.md) | Flujo objetivo de la app completa (registro, partida, resultados). | PARCIALMENTE OBSOLETO (navegación vieja SUPERADA; pregunta 11 DECIDIDA 04-11-2026, ver ADR-0012; pregunta 23 de los mundos bloqueados PENDIENTE DE DECISIÓN) | 04-11-2026 | Navegación real: [06-pantallas-ui.md](06-pantallas-ui.md). Colocación en el tablero: [16-spec-puzzle.md](16-spec-puzzle.md), sección 4. |
| [03-reglas-del-juego.md](03-reglas-del-juego.md) | Reglas del juego: victoria, colocación, errores, vidas, ayudas, puntos, reto diario. | PARCIALMENTE OBSOLETO (varias reglas SUPERADAS; preguntas 5, 9, 10, 11 y 20 DECIDIDAS 04-11-2026, ver ADR-0012; preguntas 6, 7, 12, 19 y otras marcadas como PENDIENTE DE DECISIÓN) | 04-11-2026 | Fuente única de la colocación: [16-spec-puzzle.md](16-spec-puzzle.md), sección 4. Números de balance: [08-balance.md](08-balance.md). |
| [04-futuro.md](04-futuro.md) | Lista de ideas para después del lanzamiento (otros juegos, social, cosméticos, temporadas). | VISIÓN FUTURA | Leído 04-11-2026, sin contrastar con el código | Lo que entra al lanzamiento se define en el plan por etapas de [17-roadmap.md](17-roadmap.md). |
| [05-pipeline-puzzles.md](05-pipeline-puzzles.md) | Cómo se crean, validan y publican los casos. | EN REVISIÓN (pensado antes de existir el generador; rangos de dificultad por recalibrar; partes NO IMPLEMENTADO) | 04-11-2026 | Proceso real y formato: [16-spec-puzzle.md](16-spec-puzzle.md) y la sección "Flujo real de generación" del propio 05. Arreglo del generador: etapa 3. |
| [06-pantallas-ui.md](06-pantallas-ui.md) | Lista de las unas 50 pantallas de la app completa y su comportamiento. | PARCIALMENTE OBSOLETO (navegación vieja SUPERADA; diseño visual EN REVISIÓN hasta la etapa 2; pregunta 23 de los mundos bloqueados PENDIENTE DE DECISIÓN) | 04-11-2026 | Dirección visual: [10-arte.md](10-arte.md) y [investigación gráfica](../production/revisiones/2026-11-04-investigacion-grafica.md). Pantallas con datos simulados: [ADR-0007](adr/0007-pantallas-simuladas-demo-y-monetizacion-simulada.md). |
| [07-arquitectura.md](07-arquitectura.md) | Arquitectura técnica objetivo: Flutter, Firebase, modelo de datos, antitrampa, vidas y rankings en servidor. | PARCIALMENTE OBSOLETO. **Tiene banner desde el 04-11-2026** (lo agrega otro agente de la etapa 0; se reescribe en la etapa 5). Contradice el código en: almacenamiento local (dice Hive o Isar; el código usa `shared_preferences`) y estado ("Riverpod o Bloc", ya cerrado). El servidor (Firebase) es visión: `backend/` está vacío. | 04-11-2026 (banner puesto; el cuerpo no se contrastó con el código) | [ADR-0001](adr/0001-stack-flutter-firebase.md), [ADR-0002](adr/0002-estado-riverpod.md), [ADR-0009](adr/0009-almacenamiento-local-shared-preferences-y-tipografias.md) y [ADR-0010](adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md). |
| [08-balance.md](08-balance.md) | Números del juego: puntos, vidas, tiempos objetivo, ranking. | EN REVISIÓN (los números son propuestas; pregunta 5 DECIDIDA 04-11-2026, ver ADR-0012; preguntas 6, 7 y 13 PENDIENTE DE DECISIÓN) | 04-11-2026 | Datos de la prueba de juego (etapa 1) para recalibrar. Reglas: [03-reglas-del-juego.md](03-reglas-del-juego.md). |
| [09-pillars.md](09-pillars.md) | Los 5 principios de diseño que filtran cualquier decisión (deducción pura, ranking limpio, sesiones cortas, sin castigo injusto, deducción visual). | VIGENTE (son principios, no describen código) | Leído 04-11-2026, sin contrastar con el código | Se aplican a todos los demás documentos. Alejandro no ha pedido cambiarlos. |
| [10-arte.md](10-arte.md) | Dirección visual (Art Bible). | EN REVISIÓN (SUPERADO PARCIALMENTE: describe el "cartoon limpio" de junio, que nunca se implementó tal cual) | 04-11-2026 | [Investigación gráfica](../production/revisiones/2026-11-04-investigacion-grafica.md) y la prueba de concepto gráfica (etapa 2). Se reescribirá cuando Alejandro decida la dirección. |
| [11-accesibilidad.md](11-accesibilidad.md) | Requisitos de accesibilidad de la V1 final. | VISIÓN FUTURA (el prototipo casi no los cumple; el arreglo va en la etapa 4; pregunta 20 DECIDIDA 04-11-2026, ver ADR-0012) | 04-11-2026 | [10-arte.md](10-arte.md) (colores y feedback) y [06-pantallas-ui.md](06-pantallas-ui.md). |
| [12-audio.md](12-audio.md) | Plan de sonido, música y vibración. | VISIÓN FUTURA (hoy la app no tiene audio ni vibración) | 04-11-2026 | Estrategia de costo casi cero: sección 6 de la [investigación gráfica](../production/revisiones/2026-11-04-investigacion-grafica.md). Entra en la etapa 4. |
| [13-narrativa.md](13-narrativa.md) | Tono, mundos, personajes y reglas de contenido de la historia. | PARCIALMENTE OBSOLETO (pregunta 8, representación de la víctima, PENDIENTE DE DECISIÓN) | 04-11-2026 | Debe quedar igual que [15-legal.md](15-legal.md) y [20-checklist-tiendas.md](20-checklist-tiendas.md) cuando Alejandro decida. |
| [14-analitica.md](14-analitica.md) | Qué se mide y con qué herramientas (eventos, KPIs, embudos). | VISIÓN FUTURA. **Tiene banner desde el 04-11-2026** (lo agrega otro agente de la etapa 0). Hoy la app no mide nada: no hay Firebase ni analítica en `app/pubspec.yaml`. | 04-11-2026 (banner puesto; el cuerpo no se contrastó con el código) | Depende de [ADR-0010](adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md) (servidor en la etapa 5) y del consentimiento de [15-legal.md](15-legal.md). |
| [15-legal.md](15-legal.md) | Intención legal para el lanzamiento: edad, privacidad, anuncios, compras. | VISIÓN FUTURA (preguntas 8, 16, 17 y 18 PENDIENTE DE DECISIÓN; el abogado aún no lo revisa) | 04-11-2026 | [legal/politica-privacidad.md](legal/politica-privacidad.md) y [20-checklist-tiendas.md](20-checklist-tiendas.md). |
| [16-spec-puzzle.md](16-spec-puzzle.md) | Especificación formal del puzzle: tamaños, pistas, colocación, formato JSON, solver. **Fuente única de la colocación.** | VIGENTE (puesto al día contra `tools/`; lo NO IMPLEMENTADO está marcado; la pregunta 11 está DECIDIDA 04-11-2026 (ver ADR-0012) y las preguntas 12 y 13 siguen marcadas; lo superado va al historial del propio documento) | 04-11-2026 | [05-pipeline-puzzles.md](05-pipeline-puzzles.md) (flujo de creación) y [ADR-0003](adr/0003-mapas-procedurales-unicos-por-caso.md) y [ADR-0004](adr/0004-vocabulario-de-pistas-murdoku-y-regla-del-minimo-2.md). |
| [17-roadmap.md](17-roadmap.md) | Plan de trabajo: estado verificado, plan por etapas 0 a 6 (aprobado el 04-11-2026), excepción de pantallas simuladas e historial del roadmap original. | VIGENTE (el roadmap original por fases, abajo, está SUPERADO como plan y se conserva como historial) | 04-11-2026 | Estado día a día: `production/session-state/active.md`. Decisión: [ADR-0011](adr/0011-plan-por-etapas-aprobado-el-04-11-2026.md). |
| [18-revision-seguridad-fase1.md](18-revision-seguridad-fase1.md) | Revisión de seguridad de la Fase 1 (12-07-2026). | VIGENTE (dos frases desfasadas corregidas con notas; respaldo de la llave de firma NO hecho, H-05) | 04-11-2026 | [20-checklist-tiendas.md](20-checklist-tiendas.md) y [ADR-0008](adr/0008-riesgo-aceptado-solucion-local-en-fase-1.md). |
| [19-guia-de-pruebas.md](19-guia-de-pruebas.md) | Cómo probar la app en el teléfono y comando único para verificar tests. | VIGENTE (la prueba de juego con personas, etapa 1, aún no se hace; pregunta 22 sobre iPhone) | 04-11-2026 | Plan de la prueba de juego: etapa 1 de [17-roadmap.md](17-roadmap.md). |
| [20-checklist-tiendas.md](20-checklist-tiendas.md) | Lista de control para publicar en Google Play y App Store. | VIGENTE (hoy no se puede subir nada; 5 condiciones bloqueantes y preguntas 8, 16, 17 y 18 PENDIENTE DE DECISIÓN) | 04-11-2026 | [15-legal.md](15-legal.md), [18-revision-seguridad-fase1.md](18-revision-seguridad-fase1.md). |
| [Enigmatrix Design System - Standalone.html](Enigmatrix%20Design%20System%20-%20Standalone.html) | Sistema de diseño exportado de Claude Design (herramienta ya abandonada). | SUPERADO | 04-11-2026 (según [10-arte.md](10-arte.md): "referencia histórica, no manda") | [10-arte.md](10-arte.md) y `app/lib/src/ui/enx_style.dart`. |

## Decisiones técnicas (docs/adr/)

Las decisiones de arquitectura se registran una por archivo con [la plantilla](adr/template.md). Los ADR 0003 a 0011 son **retroactivos**: se escribieron el 04-11-2026 para dejar por escrito decisiones ya tomadas, y figuran como "Propuesto (retroactivo)" hasta que Alejandro los acepte formalmente (0011 ya está aprobado en chat, falta solo la aceptación formal del registro). Que figuren como "Propuesto (retroactivo)" **no** significa que la decisión esté en duda: describen decisiones que ya están en uso en el código o en el trabajo. El ADR-0012 nació ya como "Aceptado 04-11-2026" por decisión explícita del dueño.

| Documento | Para qué sirve | Estado | Última verificación | Qué lo reemplaza o lo complementa |
|---|---|---|---|---|
| [adr/template.md](adr/template.md) | Plantilla para nuevos ADR. | VIGENTE | Leído 04-11-2026 | Su estructura la usan todos los ADR. |
| [adr/0001-stack-flutter-firebase.md](adr/0001-stack-flutter-firebase.md) | Elección de Flutter y Firebase. | PARCIALMENTE OBSOLETO (Hive/Isar reemplazado por `shared_preferences`; Firebase aplazado, la elección sigue vigente) | 04-11-2026 | [ADR-0009](adr/0009-almacenamiento-local-shared-preferences-y-tipografias.md) y [ADR-0010](adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md). |
| [adr/0002-estado-riverpod.md](adr/0002-estado-riverpod.md) | Elección de Riverpod para el estado de la app. | VIGENTE (`flutter_riverpod` está en `app/pubspec.yaml`) | 04-11-2026 | Cierra la duda "Riverpod o Bloc" de [07-arquitectura.md](07-arquitectura.md). |
| [adr/0003-mapas-procedurales-unicos-por-caso.md](adr/0003-mapas-procedurales-unicos-por-caso.md) | Cada caso lleva su propio mapa generado; tamaños tipo Murdoku. | VIGENTE (retroactivo) | 04-11-2026 | [16-spec-puzzle.md](16-spec-puzzle.md); supera los mapas autorados de [05-pipeline-puzzles.md](05-pipeline-puzzles.md). |
| [adr/0004-vocabulario-de-pistas-murdoku-y-regla-del-minimo-2.md](adr/0004-vocabulario-de-pistas-murdoku-y-regla-del-minimo-2.md) | Vocabulario de pistas y regla del mínimo 2. | VIGENTE (retroactivo) | 04-11-2026 | [16-spec-puzzle.md](16-spec-puzzle.md). |
| [adr/0005-estilo-visual-paper-craft.md](adr/0005-estilo-visual-paper-craft.md) | Estilo visual Paper Craft (papel recortado), elegido el 12-07-2026. | EN REVISIÓN (se reevalúa en la etapa 2) | 04-11-2026 | Prueba de concepto gráfica (etapa 2) con ambas opciones: papel como maqueta e ilustración 2D sin papel. [10-arte.md](10-arte.md). |
| [adr/0006-abandono-de-claude-design-y-ui-directa-en-flutter.md](adr/0006-abandono-de-claude-design-y-ui-directa-en-flutter.md) | Por qué se dejó Claude Design y la UI se hace en Flutter. | VIGENTE (retroactivo) | 04-11-2026 | [10-arte.md](10-arte.md). |
| [adr/0007-pantallas-simuladas-demo-y-monetizacion-simulada.md](adr/0007-pantallas-simuladas-demo-y-monetizacion-simulada.md) | Pantallas de fases futuras con datos simulados (DEMO). | VIGENTE (retroactivo; su condición de salida está en la etapa 5; qué se ve en el build de tiendas es la pregunta 18) | 04-11-2026 | Sección "Excepción aprobada" de [17-roadmap.md](17-roadmap.md). |
| [adr/0008-riesgo-aceptado-solucion-local-en-fase-1.md](adr/0008-riesgo-aceptado-solucion-local-en-fase-1.md) | Riesgo aceptado: la solución del caso viaja en el archivo local. | VIGENTE (retroactivo; dura hasta tener servidor) | 04-11-2026 | [ADR-0010](adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md) y [18-revision-seguridad-fase1.md](18-revision-seguridad-fase1.md). |
| [adr/0009-almacenamiento-local-shared-preferences-y-tipografias.md](adr/0009-almacenamiento-local-shared-preferences-y-tipografias.md) | Almacenamiento local con `shared_preferences` y tipografías con `google_fonts`. | VIGENTE (retroactivo) | 04-11-2026 | Reemplaza lo que dicen [07-arquitectura.md](07-arquitectura.md) y [ADR-0001](adr/0001-stack-flutter-firebase.md) sobre Hive o Isar. |
| [adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md](adr/0010-aplazamiento-de-firebase-a-la-etapa-5.md) | La Fase 1 corre sin servidor; el servidor llega en la etapa 5. | VIGENTE (retroactivo; exige un ADR propio antes de la etapa 5) | 04-11-2026 | Complementa [ADR-0001](adr/0001-stack-flutter-firebase.md) y [07-arquitectura.md](07-arquitectura.md). |
| [adr/0011-plan-por-etapas-aprobado-el-04-11-2026.md](adr/0011-plan-por-etapas-aprobado-el-04-11-2026.md) | Plan por etapas 0 a 6 y las decisiones que Alejandro ya tomó el 04-11-2026. | VIGENTE (aprobado en chat; falta la aceptación formal del registro) | 04-11-2026 | [17-roadmap.md](17-roadmap.md) tiene el plan completo. |
| [adr/0012-reglas-decididas-antes-de-la-prueba-de-juego.md](adr/0012-reglas-decididas-antes-de-la-prueba-de-juego.md) | Cinco reglas decididas por Alejandro el 04-11-2026: 0 vidas, errores al resolver, salir y reloj, tutorial y gesto de colocar. | VIGENTE (Aceptado 04-11-2026; las reglas aún no están implementadas) | 04-11-2026 | Sección 5 de la auditoría y [17-roadmap.md](17-roadmap.md). |

## Documentos legales (docs/legal/)

| Documento | Para qué sirve | Estado | Última verificación | Qué lo reemplaza o lo complementa |
|---|---|---|---|---|
| [legal/politica-privacidad.md](legal/politica-privacidad.md) | Borrador de la política de privacidad. | EN REVISIÓN (no está listo para publicar: faltan responsable y correo, pregunta 17; edad, pregunta 16; descarga de tipografías; enlace dentro de la app; versión en inglés) | 04-11-2026 | [15-legal.md](15-legal.md). Debe revisarlo un abogado antes de publicar. |

## Maquetas visuales (docs/mockups/)

Son archivos HTML que se abren en el navegador. Se hicieron antes de tener la interfaz en Flutter. **Ninguno manda hoy**; sirven como referencia histórica (fuente: [10-arte.md](10-arte.md) y [ADR-0006](adr/0006-abandono-de-claude-design-y-ui-directa-en-flutter.md)).

| Documento | Para qué sirve | Estado | Última verificación | Qué lo reemplaza o lo complementa |
|---|---|---|---|---|
| [mockups/01-inicio.html](mockups/01-inicio.html) | Maqueta de la pantalla de Inicio (13-06-2026). | SUPERADO | 04-11-2026 (existe; título leído) | La pantalla real en `app/lib/src/ui/home_shell.dart`. |
| [mockups/estilos/index.html](mockups/estilos/index.html) | Galería que reúne los 6 estilos visuales comparados el 12-07-2026. | SUPERADO | 04-11-2026 (existe; título leído) | Prueba de concepto gráfica (etapa 2). |
| [mockups/estilos/01-luxe-royal.html](mockups/estilos/01-luxe-royal.html) | Estilo 1: Luxe Royal (brillante, premium). | SUPERADO | 04-11-2026 (título leído) | Etapa 2. |
| [mockups/estilos/02-painterly-deco.html](mockups/estilos/02-painterly-deco.html) | Estilo 2: pintura Art Déco. | SUPERADO | 04-11-2026 (título leído) | Etapa 2. |
| [mockups/estilos/03-diorama-iso.html](mockups/estilos/03-diorama-iso.html) | Estilo 3: diorama isométrico. | SUPERADO | 04-11-2026 (título leído) | Etapa 2. |
| [mockups/estilos/04-neon-noir.html](mockups/estilos/04-neon-noir.html) | Estilo 4: neo-noir holográfico. | SUPERADO | 04-11-2026 (título leído) | Etapa 2. |
| [mockups/estilos/05-paper-craft.html](mockups/estilos/05-paper-craft.html) | Estilo 5: Paper Craft, el que Alejandro eligió el 12-07-2026. | EN REVISIÓN (el estilo se reevalúa en la etapa 2; la maqueta en sí es histórica) | 04-11-2026 (título leído) | [ADR-0005](adr/0005-estilo-visual-paper-craft.md) y etapa 2. |
| [mockups/estilos/06-toon-premium.html](mockups/estilos/06-toon-premium.html) | Estilo 6: Toon Premium (contorno grueso). | SUPERADO | 04-11-2026 (título leído) | Etapa 2. |

## Orden de lectura recomendado

Para alguien que llega nuevo (o para una sesión nueva de trabajo):

1. [../CLAUDE.md](../CLAUDE.md) y `production/session-state/active.md`: qué se está haciendo hoy y qué decisiones están vigentes.
2. [Auditoría del 04-11-2026](../production/revisiones/2026-11-04-auditoria-proyecto.md): el diagnóstico, el plan por etapas (sección 4) y las decisiones pendientes de Alejandro (sección 5).
3. [17-roadmap.md](17-roadmap.md): el plan por etapas y el estado verificado.
4. [09-pillars.md](09-pillars.md): los principios que filtran cualquier decisión.
5. [16-spec-puzzle.md](16-spec-puzzle.md): cómo funciona el puzzle (la parte mejor verificada).
6. [03-reglas-del-juego.md](03-reglas-del-juego.md) y [02-flujo.md](02-flujo.md): reglas y recorrido del jugador (leer sus banners primero).
7. [06-pantallas-ui.md](06-pantallas-ui.md) y [10-arte.md](10-arte.md): pantallas y dirección visual (esta última en revisión).
8. [05-pipeline-puzzles.md](05-pipeline-puzzles.md), [07-arquitectura.md](07-arquitectura.md) y los [ADR](adr/): cómo se hace por dentro y por qué.
9. Según el tema: [08-balance.md](08-balance.md), [11-accesibilidad.md](11-accesibilidad.md), [12-audio.md](12-audio.md), [13-narrativa.md](13-narrativa.md), [14-analitica.md](14-analitica.md), [04-futuro.md](04-futuro.md).
10. Para publicar: [15-legal.md](15-legal.md), [legal/politica-privacidad.md](legal/politica-privacidad.md), [18-revision-seguridad-fase1.md](18-revision-seguridad-fase1.md), [19-guia-de-pruebas.md](19-guia-de-pruebas.md) y [20-checklist-tiendas.md](20-checklist-tiendas.md).

Regla práctica: si dos documentos se contradicen, manda el que tiene fecha de verificación más reciente en la tabla de arriba, y si ninguno resuelve el conflicto, se busca la marca **PENDIENTE DE DECISIÓN** (la decide Alejandro, no se adivina).

## Regla de mantenimiento

1. **Se actualiza el documento en la misma sesión en que se toma la decisión.** Quien cambie código, reglas o planes revisa qué documentos de esta tabla quedan afectados y los corrige antes de cerrar la sesión.
2. **Si no hay tiempo de actualizarlo, se marca como obsoleto desde una fecha.** Se pone al inicio del documento un banner con el formato `> OBSOLETO desde dd-mm-yyyy: <qué ya no es cierto y dónde está lo vigente>`, y se cambia su estado en este índice.
3. **No se borra información.** Lo superado se marca (banner "ACTUALIZACIÓN dd-mm-yyyy" o sección "Historial" al final del mismo documento) y el texto se conserva.
4. **Los temas que decide Alejandro no se resuelven en silencio.** Si hay contradicción, se escribe "**PENDIENTE DE DECISIÓN** (auditoría 04-11-2026, pregunta N): <las dos versiones>" hasta que él decida; cuando decide, se anota la fecha y se quita la marca en todos los documentos que la tengan.
5. **Los hechos sobre el código se comprueban en el código**, no se copian de otro documento (tamaños, número de tests, librerías, cómo funciona algo).
6. **Cada documento nuevo se agrega a este índice** con su estado y fecha, y cada cambio de estado actualiza la columna "Última verificación".
7. Fechas siempre en formato dd-mm-yyyy.

## Pendientes de este índice

- [04-futuro.md](04-futuro.md) y [09-pillars.md](09-pillars.md) no recibieron banner en la puesta al día de la etapa 0. Los estados de arriba salen de leerlos hoy; falta contrastarlos con el código. [07-arquitectura.md](07-arquitectura.md) y [14-analitica.md](14-analitica.md) tienen banner desde el 04-11-2026, pero su cuerpo sigue sin contrastarse con el código.
- Los ADR 0003 a 0011 siguen como "Propuesto (retroactivo)" hasta que Alejandro los acepte formalmente; describen decisiones ya en uso.

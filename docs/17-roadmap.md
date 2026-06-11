# Enigmatrix - Roadmap por fases

## Objetivo de este documento

Ordenar el MVP del doc 01 en fases construibles. El MVP completo es grande (~50 pantallas, 5 mundos, monetización, anti-trampa); intentarlo de una vez es el riesgo #1 del proyecto. Cada fase tiene criterio de salida verificable. **No se arranca una fase sin cerrar la anterior.**

> **Fase actual: FASE 0**

## FASE 0 — El corazón: spec + solver (sin app, sin backend)

La apuesta del proyecto es que se pueden generar casos con solución única y dificultad calibrada. Si esto no funciona, no hay juego. Se demuestra primero.

Entregables:

- [ ] Cerrar preguntas abiertas de `16-spec-puzzle.md` (sección 7)
- [ ] Modelo de datos en Dart puro (`tools/`): mapa, área, celda, personaje, pista, caso
- [ ] Motor de deducción (resuelve como humano, sin adivinar)
- [ ] Verificador de unicidad (backtracking exhaustivo)
- [ ] Contador de pasos de deducción + clasificador de dificultad
- [ ] Generador de casos sobre un mapa de prueba
- [ ] Suite de tests deterministas (fixtures: caso válido, caso doble solución, caso que requiere adivinar)
- [ ] CLI mínimo: `generar caso → imprimir tablero y pistas en consola → validar`

Criterio de salida: generar 20 casos válidos de dificultades Principiante/Casual/Intermedio sobre 1 mapa de prueba, todos con solución única verificada, y poder jugarlos a mano en papel.

## FASE 1 — Vertical slice jugable (app local, sin cuentas)

Una app Flutter que se instala en el teléfono del usuario y se juega. Sin Firebase, sin login: casos empaquetados localmente. El objetivo es validar la experiencia de juego y la UI del tablero.

Entregables:

- [ ] Proyecto Flutter (`app/`) con Riverpod + go_router
- [ ] Tablero jugable: render del mapa (CustomPainter), áreas, objetos, avatares
- [ ] Interacción completa: candidato/confirmado/X, arrastre, papelera, deshacer/rehacer, limpiar
- [ ] Los dos modos de notas (separada y superpuesta)
- [ ] Pistas visibles con tachado/destacado
- [ ] Botón Resolver con validación local (en esta fase el cliente sí valida — es throwaway aceptado)
- [ ] Pantallas mínimas: selección de caso, partida, error/éxito, resumen
- [ ] Tutorial guiado (versión simple)
- [ ] Integración del Design System (colores, tipografía de `docs/Enigmatrix Design System - Standalone.html` y mockups cuando existan)

Criterio de salida: el usuario juega 10 casos en su Android y el loop se siente bien. Feedback de UX documentado.

## FASE 2 — Online: cuentas, reto diario y ranking (el MVP mínimo publicable)

Entra Firebase. La validación se mueve al servidor (el cliente deja de conocer la solución).

Entregables:

- [ ] Firebase Auth: Google + email/contraseña + verificación de correo
- [ ] Perfil: nickname único, avatar, bandera
- [ ] Firestore: colecciones users, maps, cases, attempts (doc 07)
- [ ] Cloud Functions: entregar caso sin solución, validar solución, puntos (fórmula doc 08)
- [ ] Reto diario: calendario en servidor, intento oficial único, ventana por hora de servidor
- [ ] Ranking diario + racha básica (sin protectores aún)
- [ ] Partida pendiente única global (regla doc 01)
- [ ] Campaña Mundo 1 (Mansión, ~10 mapas) con progresión secuencial
- [ ] Anti-trampa base: solución solo en servidor, FLAG_SECURE, rotación de mapa
- [ ] Reglas de seguridad de Firestore revisadas por agente `seguridad`

Criterio de salida: build cerrada en Google Play (testing interno) con amigos/familia jugando el reto diario real durante 2 semanas.

## FASE 3 — Economía y retención

- [ ] Vidas (5 máx, recarga por hora, autoridad de servidor)
- [ ] Protectores de racha + hitos
- [ ] Ranking semanal + ranking por mapa
- [ ] Práctica y "mapa sin resolver"
- [ ] Anuncios (intersticial + recompensados) con frecuencias del doc 08
- [ ] Premium mensual/anual + packs (Google Play Billing, validación de recibos en servidor)
- [ ] Tienda
- [ ] Compartir resultados
- [ ] Notificaciones push (FCM): reto disponible, racha en peligro

Criterio de salida: economía completa funcionando en testing cerrado; ninguna compra entrega nada sin validación de recibo en servidor.

## FASE 4 — Contenido y lanzamiento

- [ ] Mundos 2-5 (Hotel, Museo, Tren, Hospital): mapas + arte + arquetipos narrativos (doc 13)
- [ ] Stock de reto diario: mínimo 60 días aprobados (meta 120, doc 05)
- [ ] Herramientas internas mínimas: visor de casos para revisión, calendario de retos
- [ ] Localización EN completa
- [ ] Accesibilidad V1 (doc 11): contraste, modo daltónico, escala de texto, alternativa al arrastre
- [ ] Analítica completa (doc 14) + consentimiento
- [ ] Legal: política de privacidad, términos, eliminación de cuenta (doc 15)
- [ ] Checklist Google Play + lanzamiento abierto Android

## Fuera de roadmap (post-lanzamiento)

iOS, amigos, rankings por país, temporadas, eventos, logros, moneda interna, anti-cheat avanzado — ver `04-futuro.md`.

## Decisiones de recorte respecto al doc 01 (aprobadas por el usuario, 2026-06-10)

- El MVP se construye por fases; la "V1" del doc 01 equivale a completar Fase 4.
- Monetización pospuesta a Fase 3 (no bloquea validar el juego).
- 5 mundos pospuestos a Fase 4 (Fase 2 sale con Mundo 1).
- Herramientas internas reducidas al mínimo (JSON a mano + CLI hasta Fase 4).

## Riesgos vigilados

| Riesgo | Señal de alarma | Mitigación |
|---|---|---|
| El solver no genera casos Elite interesantes | Fase 0 produce solo casos triviales | Subir tamaño de grilla/pistas compuestas antes de seguir |
| Scope creep | Una fase lleva >2× lo previsto | Recortar la fase, no extenderla |
| Arte de 5 mundos | Sin fuente de assets clara en Fase 2 | Decidir en Fase 2: IA generativa vs comisión (ADR) |
| Costos Firestore | Lecturas disparadas en testing | Agregaciones precalculadas desde el día 1 (doc 07) |

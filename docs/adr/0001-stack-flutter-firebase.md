# ADR-0001: Stack Flutter + Firebase

- **Estado**: Aceptado
- **Fecha**: 2026-06-10 (formaliza la decisión del doc 07, 2026-05-01)
- **Decisores**: usuario / análisis del doc 07-arquitectura.md

## Contexto

Enigmatrix necesita: una sola base de código Android→iOS, UI con gestos finos (arrastre sobre tablero), backend con auth, validación oficial en servidor, push y configuración remota — con un equipo de una persona no programadora desarrollando vía Claude, y prioridad de time to market.

## Decisión

App en **Flutter (Dart)**; backend en **Firebase** (Auth, Firestore, Cloud Functions, FCM, Remote Config, Crashlytics/Analytics).

## Alternativas consideradas

- Kotlin nativo — mejor rendimiento bruto, pero obliga a reescribir para iOS.
- React Native — peor para gestos continuos y animación de tablero.
- Unity/Godot — sobreestructura para una UI de app con un tablero custom.
- Supabase / backend propio (Node/Go + Postgres) — mejor SQL para rankings, pero más trabajo inicial; reevaluar si los leaderboards en Firestore duelen (la migración está prevista en doc 07).

## Consecuencias

- Una base de código para ambas plataformas; ecosistema maduro para ads/IAP/push.
- Vendor lock-in con Firebase → mitigación obligatoria: capa de servicios que aísla Firebase en la app y esquema portable a Postgres (doc 07).
- Rankings "bloque alrededor del usuario" en Firestore son incómodos → agregaciones precalculadas desde el día 1.

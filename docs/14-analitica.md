# Enigmatrix - Analitica

## Objetivo de este documento
Definir que se mide en Enigmatrix, con que herramienta, y como se usa esa informacion para tomar decisiones.

Cubre:

- objetivos de la analitica
- stack y herramientas
- KPIs principales
- catalogo de eventos
- propiedades de usuario
- funnels criticos
- cohortes y retencion
- analitica de monetizacion
- analitica de antitrampa
- consentimiento y privacidad
- pendientes

## Objetivos de la analitica

### Para que se mide
- entender si el juego se entiende y se disfruta
- detectar fricciones y abandono
- validar el balance numerico real contra el propuesto
- decidir donde invertir esfuerzo de contenido y arte
- proteger la salud del ranking detectando comportamiento sospechoso
- evaluar la salud de la monetizacion sin sacrificar pillars

### Para que no se mide
- no se mide para vender datos personales
- no se mide para perfiles publicitarios externos
- no se mide para crear scoring de jugadores fuera del juego

## Stack y herramientas

### Recomendacion principal
- Firebase Analytics como capa base de eventos
- Crashlytics para errores
- exportacion a BigQuery para analisis a fondo
- panel propio para los KPIs principales

### Alternativas a considerar
- panel custom sobre BigQuery cuando se quiera vista propia
- herramienta independiente tipo PostHog si se requiere analisis de producto mas profundo

### Reglas
- toda analitica de servidor pasa por Cloud Functions
- toda analitica de cliente respeta el toggle de consentimiento
- ningun evento contiene datos sensibles del jugador
- ningun evento contiene contenido textual del jugador

## KPIs principales

### Adquisicion
- nuevas instalaciones por dia
- registros completados
- ratio registro frente a apertura
- canal de origen cuando exista

### Activacion
- usuarios que completan tutorial
- usuarios que completan primer caso oficial
- usuarios que verifican email
- usuarios que llegan a Mundo 2

### Retencion
- D1, D7, D30 sobre usuarios que completan tutorial
- retencion del reto diario: porcentaje que vuelve al dia siguiente
- retencion semanal del reto diario

### Engagement
- DAU
- MAU
- DAU MAU ratio
- promedio de partidas por DAU
- duracion media de sesion
- numero medio de retos diarios completados por usuario

### Monetizacion
- ARPDAU
- ARPPU
- conversion a premium
- conversion por pack de vidas
- conversion por protectores
- ratio anuncios mostrados frente a anuncios disponibles

### Calidad y salud
- tasa de crash
- tasa de errores no fatales
- tiempo medio de validacion oficial en servidor
- tasa de partidas invalidadas por desconexion

## Catalogo de eventos

### Convenciones
- nombre snake case en ingles
- propiedades en snake case en ingles
- todos los timestamps en hora del servidor
- todas las dificultades como strings en ingles minuscula

### Sesion y app
- app_open
- app_background
- app_foreground
- app_crash sintetico desde Crashlytics
- network_lost
- network_restored

### Auth
- signup_started
- signup_completed
- signup_failed
- login_started
- login_completed
- login_failed
- email_verification_sent
- email_verification_completed
- account_delete_requested
- account_delete_confirmed

### Onboarding
- welcome_seen
- welcome_completed
- tutorial_started
- tutorial_step_completed
- tutorial_completed
- tutorial_abandoned

### Inicio y navegacion
- home_opened
- card_clicked
- bottom_tab_clicked
- secondary_menu_opened
- screen_view

### Mapas y partidas
- map_preview_opened
- official_attempt_started
- official_attempt_resumed
- official_attempt_abandoned
- official_attempt_invalidated
- attempt_solved_correct
- attempt_solved_incorrect
- help_used
- hint_marked
- board_cleared
- undo_used
- redo_used

### Reto diario
- daily_module_opened
- daily_attempt_warning_shown
- daily_attempt_started
- daily_attempt_completed
- daily_attempt_failed
- daily_streak_increased
- daily_streak_protected
- daily_streak_lost

### Vidas
- life_lost
- life_regenerated
- life_ad_requested
- life_ad_completed
- life_ad_failed
- life_pack_purchased

### Tienda y premium
- store_opened
- iap_started
- iap_completed
- iap_failed
- premium_started
- premium_completed
- premium_renewed
- premium_canceled
- restore_purchases_requested
- restore_purchases_completed

### Anuncios
- ad_eligible
- ad_loaded
- ad_failed
- ad_shown
- ad_completed
- ad_skipped

### Resumen y compartir
- map_summary_shown
- daily_summary_shown
- world_summary_shown
- share_clicked
- share_completed

### Ranking
- ranking_main_opened
- ranking_map_opened
- ranking_daily_opened
- ranking_weekly_opened
- public_profile_opened

### Perfil y configuracion
- profile_opened
- profile_edited
- nickname_change_attempted
- nickname_change_completed
- settings_opened
- setting_toggled

### Antitrampa
- screenshot_blocked_event
- map_rotation_disabled_event
- offline_during_official_attempt
- official_attempt_blocked_offline
- multidevice_session_collision

## Propiedades de usuario

### Propiedades base
- user_id interno del juego
- account_provider: google o email
- email_verified: si o no
- premium_status: free, monthly, annual
- preferred_language
- preferred_notes_mode
- daltonic_mode_enabled
- reduced_motion_enabled
- map_rotation_disabled
- registered_at
- country_flag

### Propiedades dinamicas
- current_world
- current_world_progress
- lifetime_official_completions
- lifetime_daily_completions
- best_streak_ever
- current_streak
- protectors_available

## Funnels criticos

### Funnel de adquisicion
- app_open
- signup_started
- signup_completed
- welcome_completed
- tutorial_completed
- official_attempt_started
- attempt_solved_correct primer caso

### Funnel de activacion del reto diario
- daily_module_opened
- daily_attempt_warning_shown
- daily_attempt_started
- daily_attempt_completed

### Funnel de monetizacion premium
- store_opened
- iap_started premium
- iap_completed premium

### Funnel de monetizacion de vidas
- life_lost al cero
- life_pack_purchased o life_ad_completed o regeneracion natural

## Cohortes y retencion

### Cohortes base
- por semana de registro
- por proveedor de auth
- por idioma
- por pais
- por estado premium

### Vistas
- retencion clasica D1 D7 D30 por cohorte
- retencion del reto diario por cohorte
- progresion de mundo por cohorte
- conversion a premium por cohorte

## Analitica de monetizacion

### Reglas
- toda compra registra evento iap_started, iap_completed o iap_failed
- la validacion de la compra ocurre en servidor antes de marcar completed
- el evento ad_completed solo se dispara tras confirmacion del SDK del proveedor
- los precios reportados en eventos vienen del store, no del cliente

### Vistas
- ARPDAU desglosado por iap y anuncios
- conversion a premium por funnel completo
- impacto del premium en retencion
- impacto de paquetes de vidas en horas jugadas

## Analitica de antitrampa

### Senales rastreadas
- partidas con tiempos absurdamente bajos para su dificultad
- patrones de exito sin marcar candidatos previos
- multiples sesiones simultaneas activas
- intentos repetidos de enviar soluciones invalidas

### Reglas
- ninguna senal por si sola es prueba
- las senales acumuladas alimentan revision interna
- en V1 no hay sancion automatica derivada de analitica
- en futuro, posibles flags de revision manual

## Consentimiento y privacidad

### Reglas base
- consentimiento explicito al primer arranque para analitica no esencial
- el toggle de analitica vive en configuracion
- la analitica esencial al servicio del juego corre siempre
- la analitica para anuncios y atribucion respeta el opt out

### Datos prohibidos en eventos
- contenido textual del jugador
- contraseña
- datos de pago
- ubicacion exacta
- contactos del dispositivo
- archivos del dispositivo

### GDPR y similares
- el usuario puede pedir eliminacion de sus datos analiticos
- la eliminacion se procesa en un plazo definido en el doc legal
- la analitica anonimizada agregada se mantiene para metricas globales

## Pendientes
- definir herramienta del panel propio
- definir politicas de retencion de datos analiticos
- definir umbrales de senales antitrampa
- definir conjunto de eventos minimos para el primer mes vs eventos completos
- definir el equipo o persona responsable del seguimiento semanal de KPIs

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Etiqueta que marca como simulado (DEMO) lo que aún no tiene servidor.
  ///
  /// In es, this message translates to:
  /// **'DEMO'**
  String get uiDemo;

  /// Etiqueta de lo que todavía no se puede abrir.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get uiComingSoon;

  /// Botón y etiqueta de accesibilidad para volver atrás.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get uiBack;

  /// Aviso de las funciones simuladas de la tienda y las compras.
  ///
  /// In es, this message translates to:
  /// **'Función simulada: se activa con el modo online (Fase 2)'**
  String get uiDemoNotice;

  /// Pestaña Inicio de la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// Pestaña Mundos de la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Mundos'**
  String get navWorlds;

  /// Pestaña Reto de la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Reto'**
  String get navChallenge;

  /// Pestaña Ranking de la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Ranking'**
  String get navRanking;

  /// Pestaña Perfil de la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// Rótulo de la tarjeta del reto diario en Inicio.
  ///
  /// In es, this message translates to:
  /// **'RETO DIARIO'**
  String get homeChallengeLabel;

  /// Título de la tarjeta del reto diario en Inicio.
  ///
  /// In es, this message translates to:
  /// **'El caso de hoy te espera'**
  String get homeChallengeTitle;

  /// Botón para jugar el reto diario desde Inicio.
  ///
  /// In es, this message translates to:
  /// **'Jugar el reto'**
  String get homePlayChallenge;

  /// Rótulo de la tarjeta del Mundo 1 en Inicio.
  ///
  /// In es, this message translates to:
  /// **'MUNDO 1 · LA MANSIÓN'**
  String get homeWorldLabel;

  /// Botón que lleva a la lista de casos del Mundo 1.
  ///
  /// In es, this message translates to:
  /// **'Continuar investigando'**
  String get homeKeepInvestigating;

  /// Rótulo de la tarjeta de la tienda en Inicio.
  ///
  /// In es, this message translates to:
  /// **'TIENDA'**
  String get homeShop;

  /// Subtítulo de la tarjeta de la tienda.
  ///
  /// In es, this message translates to:
  /// **'Vidas y protectores de racha'**
  String get homeShopSub;

  /// Botón que abre la tienda.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get homeSee;

  /// Título de la pestaña Mundos.
  ///
  /// In es, this message translates to:
  /// **'Mundos'**
  String get homeWorlds;

  /// Título de la pestaña Reto diario.
  ///
  /// In es, this message translates to:
  /// **'Reto diario'**
  String get homeChallengeTab;

  /// Rótulo del bloque del caso de hoy en la pestaña Reto.
  ///
  /// In es, this message translates to:
  /// **'EL CASO DE HOY'**
  String get homeTodayCase;

  /// Aclaración de que el reto diario aún no es oficial.
  ///
  /// In es, this message translates to:
  /// **'Simulación: aún sin servidor, no hay intento oficial ni cierre a medianoche'**
  String get homeChallengeNote;

  /// Estado del reto de hoy: sin iniciar.
  ///
  /// In es, this message translates to:
  /// **'Estado: no iniciado'**
  String get homeStateNew;

  /// Estado del reto de hoy: en curso.
  ///
  /// In es, this message translates to:
  /// **'Estado: en curso'**
  String get homeStateOpen;

  /// Estado del reto de hoy: resuelto.
  ///
  /// In es, this message translates to:
  /// **'Estado: resuelto'**
  String get homeStateDone;

  /// Aviso cuando el reto de hoy no está disponible.
  ///
  /// In es, this message translates to:
  /// **'El caso de hoy no está disponible.'**
  String get homeNoChallenge;

  /// Botón para jugar el caso de hoy en la pestaña Reto.
  ///
  /// In es, this message translates to:
  /// **'Jugar el caso de hoy'**
  String get homePlayToday;

  /// Rótulo de los puntos de la semana.
  ///
  /// In es, this message translates to:
  /// **'PUNTOS DE LA SEMANA'**
  String get homeWeekPoints;

  /// Título de la pestaña Ranking.
  ///
  /// In es, this message translates to:
  /// **'Ranking'**
  String get homeRanking;

  /// Subtítulo de la pestaña Ranking.
  ///
  /// In es, this message translates to:
  /// **'Semanal · se conecta en el modo online'**
  String get homeRankingSub;

  /// Nombre de la fila del propio jugador en el ranking.
  ///
  /// In es, this message translates to:
  /// **'Tú (detective)'**
  String get homeYou;

  /// Título de la lista de casos del Mundo 1.
  ///
  /// In es, this message translates to:
  /// **'Casos'**
  String get caseListTitle;

  /// Rótulo de la tarjeta del siguiente caso por jugar.
  ///
  /// In es, this message translates to:
  /// **'SIGUIENTE CASO'**
  String get caseListNextCase;

  /// Rótulo de la tarjeta del tutorial.
  ///
  /// In es, this message translates to:
  /// **'TUTORIAL'**
  String get caseListTutorial;

  /// Descripción de la tarjeta del tutorial.
  ///
  /// In es, this message translates to:
  /// **'Caso de práctica paso a paso (no cuenta como Caso 1)'**
  String get caseListTutorialBody;

  /// Descripción del tutorial ya completado.
  ///
  /// In es, this message translates to:
  /// **'Completado: puedes repetirlo'**
  String get caseListTutorialDone;

  /// Botón para empezar un caso.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get caseListStart;

  /// Botón para repetir el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get caseListRepeat;

  /// Aviso de las dificultades que llegan en una actualización.
  ///
  /// In es, this message translates to:
  /// **'Llega en una próxima actualización.'**
  String get caseListSoonBody;

  /// Botón que abre las instrucciones de juego.
  ///
  /// In es, this message translates to:
  /// **'Cómo jugar'**
  String get caseListHowToPlay;

  /// Botón para reabrir un caso ya cerrado.
  ///
  /// In es, this message translates to:
  /// **'Reabrir caso'**
  String get caseListReopen;

  /// Botón para continuar un caso en curso.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get caseListKeepPlaying;

  /// Botón para investigar el siguiente caso.
  ///
  /// In es, this message translates to:
  /// **'Investigar'**
  String get caseListInvestigate;

  /// Título de la hoja de más acciones de la partida.
  ///
  /// In es, this message translates to:
  /// **'Más acciones'**
  String get gameMenuTitle;

  /// Acción de rehacer el último movimiento deshecho.
  ///
  /// In es, this message translates to:
  /// **'Rehacer'**
  String get gameMenuRedo;

  /// Acción de limpiar el tablero.
  ///
  /// In es, this message translates to:
  /// **'Limpiar tablero'**
  String get gameMenuClear;

  /// Título del diálogo de confirmación de limpiar el tablero.
  ///
  /// In es, this message translates to:
  /// **'¿Limpiar tablero?'**
  String get gameMenuClearTitle;

  /// Explicación del diálogo de limpiar el tablero.
  ///
  /// In es, this message translates to:
  /// **'Se borran las marcas del tablero y de las pistas. El tiempo y los errores se mantienen.'**
  String get gameMenuClearBody;

  /// Botón de cancelar en el diálogo de limpiar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get gameMenuCancel;

  /// Botón que confirma limpiar el tablero.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get gameMenuClearConfirm;

  /// Rótulo del selector de vista del tablero.
  ///
  /// In es, this message translates to:
  /// **'Vista del tablero'**
  String get gameMenuView;

  /// Vista del tablero: mapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get gameMenuViewMap;

  /// Vista del tablero: notas.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get gameMenuViewNotes;

  /// Nombre del interruptor que tacha solo fila y columna.
  ///
  /// In es, this message translates to:
  /// **'Auto-X'**
  String get gameMenuAutoX;

  /// Explicación del interruptor Auto-X.
  ///
  /// In es, this message translates to:
  /// **'Al confirmar a alguien, tacha su fila y columna automáticamente'**
  String get gameMenuAutoXHelp;

  /// Opción que abre la leyenda y las reglas.
  ///
  /// In es, this message translates to:
  /// **'Leyenda y reglas'**
  String get gameMenuLegend;

  /// Rótulo del selector de marca de la pista.
  ///
  /// In es, this message translates to:
  /// **'Marca de la pista'**
  String get gameMenuClueMark;

  /// Marca de pista normal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get gameMenuMarkNormal;

  /// Marca de pista destacada.
  ///
  /// In es, this message translates to:
  /// **'Destacar'**
  String get gameMenuMarkHighlight;

  /// Marca de pista tachada.
  ///
  /// In es, this message translates to:
  /// **'Tachar'**
  String get gameMenuMarkStrike;

  /// Botón para saltar el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get gameScreenSkip;

  /// Título de la pantalla de pausa.
  ///
  /// In es, this message translates to:
  /// **'Partida en pausa'**
  String get gameScreenPaused;

  /// Explicación de la pantalla de pausa.
  ///
  /// In es, this message translates to:
  /// **'El reloj está detenido y el tablero oculto. Toca Continuar para seguir.'**
  String get gameScreenPausedBody;

  /// Botón que reanuda la partida pausada.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get gameScreenResume;

  /// Título del diálogo de salir de un caso.
  ///
  /// In es, this message translates to:
  /// **'Salir del caso'**
  String get gameScreenExitTitle;

  /// Pregunta del diálogo de salir de un caso.
  ///
  /// In es, this message translates to:
  /// **'Tu avance queda guardado. ¿Salir del caso?'**
  String get gameScreenExitBody;

  /// Botón para seguir jugando en lugar de salir.
  ///
  /// In es, this message translates to:
  /// **'Seguir jugando'**
  String get gameScreenKeepPlaying;

  /// Botón que confirma salir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get gameScreenLeave;

  /// Título del diálogo de salir del tutorial.
  ///
  /// In es, this message translates to:
  /// **'Salir del tutorial'**
  String get gameScreenExitTutorialTitle;

  /// Pregunta del diálogo de salir del tutorial.
  ///
  /// In es, this message translates to:
  /// **'El tutorial no guarda avance. Si sales, podrás repetirlo desde la lista de casos. ¿Salir?'**
  String get gameScreenExitTutorialBody;

  /// Botón para seguir practicando en el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Seguir practicando'**
  String get gameScreenKeepPracticing;

  /// Título del diálogo de reemplazar una casilla confirmada.
  ///
  /// In es, this message translates to:
  /// **'¿Reemplazar confirmado?'**
  String get gameScreenReplaceTitle;

  /// Pregunta del diálogo de reemplazar una casilla confirmada.
  ///
  /// In es, this message translates to:
  /// **'Esta casilla ya tiene una decisión confirmada. ¿Quieres reemplazarla?'**
  String get gameScreenReplaceBody;

  /// Botón de cancelar en el diálogo de reemplazar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get gameScreenCancel;

  /// Botón que confirma reemplazar.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get gameScreenReplace;

  /// Aviso mientras el botón Resolver está bloqueado.
  ///
  /// In es, this message translates to:
  /// **'Espera un momento…'**
  String get gameScreenLockedWait;

  /// Texto de la bandeja cuando no hay pista seleccionada.
  ///
  /// In es, this message translates to:
  /// **'Toca un retrato para ver su pista.'**
  String get gameHintEmpty;

  /// Etiqueta de accesibilidad de la pista completa.
  ///
  /// In es, this message translates to:
  /// **'Pista completa'**
  String get gameHintExpandLabel;

  /// Enlace para ver el resto de una pista larga.
  ///
  /// In es, this message translates to:
  /// **'ver más'**
  String get gameHintMore;

  /// Herramienta de anotar candidatos.
  ///
  /// In es, this message translates to:
  /// **'Anotar'**
  String get gameToolbarToolNotes;

  /// Herramienta de tachar casillas.
  ///
  /// In es, this message translates to:
  /// **'Tachar'**
  String get gameToolbarToolCross;

  /// Herramienta de confirmar un sospechoso.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get gameToolbarToolPlace;

  /// Herramienta de borrar una casilla.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get gameToolbarToolErase;

  /// Botón para resolver el caso.
  ///
  /// In es, this message translates to:
  /// **'Resolver'**
  String get gameToolbarResolve;

  /// Botón para ver el resumen del caso resuelto.
  ///
  /// In es, this message translates to:
  /// **'Ver resumen'**
  String get gameToolbarViewSummary;

  /// Botón de deshacer.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get gameToolbarUndo;

  /// Botón para salir del caso.
  ///
  /// In es, this message translates to:
  /// **'Salir del caso'**
  String get gameToolbarBack;

  /// Botón del menú de más acciones.
  ///
  /// In es, this message translates to:
  /// **'Más acciones'**
  String get gameToolbarMenu;

  /// Rótulo de la víctima.
  ///
  /// In es, this message translates to:
  /// **'Víctima'**
  String get gameToolbarVictim;

  /// Encabezado del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'CÓMO JUGAR'**
  String get tutorialDialogHeader;

  /// Botón para omitir el diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get tutorialDialogSkip;

  /// Botón para pasar a la página siguiente.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get tutorialDialogNext;

  /// Botón que abre el caso de práctica.
  ///
  /// In es, this message translates to:
  /// **'Empezar la práctica'**
  String get tutorialDialogStartPractice;

  /// Botón final del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'¡A investigar!'**
  String get tutorialDialogGo;

  /// Sello de la pantalla de victoria.
  ///
  /// In es, this message translates to:
  /// **'CASO CERRADO'**
  String get victoryStamp;

  /// Felicitación de la pantalla de victoria.
  ///
  /// In es, this message translates to:
  /// **'Buen trabajo, detective.'**
  String get victoryGoodJob;

  /// Rótulo del informe del caso.
  ///
  /// In es, this message translates to:
  /// **'INFORME DEL CASO'**
  String get victoryReport;

  /// Rótulo del tiempo empleado.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get victoryTime;

  /// Rótulo de los errores cometidos.
  ///
  /// In es, this message translates to:
  /// **'Errores'**
  String get victoryErrors;

  /// Botón para continuar tras la victoria.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get victoryKeepGoing;

  /// Botón para seguir mirando el tablero resuelto.
  ///
  /// In es, this message translates to:
  /// **'Seguir mirando el tablero'**
  String get victoryLookBoard;

  /// Título de la hoja de la tienda.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get sheetShop;

  /// Título de la hoja Premium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get sheetPremium;

  /// Beneficios de Premium.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios · vidas ilimitadas · sin ventajas de ranking'**
  String get sheetPremiumBody;

  /// Título de la hoja de configuración.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get sheetSettings;

  /// Interruptor de sonido.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get sheetSound;

  /// Interruptor de música.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get sheetMusic;

  /// Interruptor de vibración.
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get sheetHaptics;

  /// Interruptor de reducir movimiento.
  ///
  /// In es, this message translates to:
  /// **'Reducir movimiento'**
  String get sheetReduceMotion;

  /// Explicación de reducir movimiento.
  ///
  /// In es, this message translates to:
  /// **'Menos rebotes, sacudidas y partículas en el tablero.'**
  String get sheetReduceMotionHint;

  /// Fila de notificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get sheetNotifications;

  /// Fila de idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get sheetLanguage;

  /// Nombre del idioma español.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get sheetSpanish;

  /// Título del bloque de cuenta y compras.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y compras'**
  String get sheetAccount;

  /// Explicación del bloque de cuenta y compras.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras, cerrar sesión y eliminar cuenta se activan con el modo online.'**
  String get sheetAccountBody;

  /// Título del diálogo para cambiar el nombre.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre de detective'**
  String get sheetNickTitle;

  /// Botón de cancelar del diálogo de nombre.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get sheetCancel;

  /// Botón de guardar del diálogo de nombre.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get sheetSave;

  /// Título del bloque de aspecto del juego.
  ///
  /// In es, this message translates to:
  /// **'Aspecto del juego'**
  String get appearanceTitle;

  /// Rótulo del selector de piel.
  ///
  /// In es, this message translates to:
  /// **'Piel'**
  String get appearanceSkin;

  /// Rótulo del selector de modo.
  ///
  /// In es, this message translates to:
  /// **'Modo'**
  String get appearanceMode;

  /// Modo que sigue al teléfono.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get appearanceSystem;

  /// Modo claro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get appearanceLight;

  /// Modo oscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get appearanceDark;

  /// Etiqueta de accesibilidad de una casilla sin candidatos.
  ///
  /// In es, this message translates to:
  /// **'candidatos: ninguno'**
  String get boardSemanticsNoCandidates;

  /// Etiqueta de accesibilidad de una casilla sin confirmado.
  ///
  /// In es, this message translates to:
  /// **'confirmado: ninguno'**
  String get boardSemanticsNoConfirmed;

  /// Etiqueta de accesibilidad de una casilla tachada.
  ///
  /// In es, this message translates to:
  /// **'tachada'**
  String get boardSemanticsCrossed;

  /// Pista de accesibilidad del gesto de mantener oprimido.
  ///
  /// In es, this message translates to:
  /// **'Mantén oprimido para confirmar'**
  String get boardSemanticsHoldHint;

  /// Nombre de la dificultad Principiante.
  ///
  /// In es, this message translates to:
  /// **'Principiante'**
  String get difficultyBeginner;

  /// Nombre de la dificultad Casual.
  ///
  /// In es, this message translates to:
  /// **'Casual'**
  String get difficultyCasual;

  /// Nombre de la dificultad Intermedio.
  ///
  /// In es, this message translates to:
  /// **'Intermedio'**
  String get difficultyIntermediate;

  /// Nombre de la dificultad Experto.
  ///
  /// In es, this message translates to:
  /// **'Experto'**
  String get difficultyExpert;

  /// Nombre de la dificultad Élite.
  ///
  /// In es, this message translates to:
  /// **'Élite'**
  String get difficultyElite;

  /// Nombre del Mundo 1.
  ///
  /// In es, this message translates to:
  /// **'La Mansión'**
  String get worldMansion;

  /// Nombre del mundo El Hotel (próximamente).
  ///
  /// In es, this message translates to:
  /// **'El Hotel'**
  String get worldHotel;

  /// Nombre del mundo El Museo (próximamente).
  ///
  /// In es, this message translates to:
  /// **'El Museo'**
  String get worldMuseum;

  /// Nombre del mundo El Tren (próximamente).
  ///
  /// In es, this message translates to:
  /// **'El Tren'**
  String get worldTrain;

  /// Nombre del mundo El Hospital (próximamente).
  ///
  /// In es, this message translates to:
  /// **'El Hospital'**
  String get worldHospital;

  /// Nombre del juego (título de la app y de la pantalla de carga).
  ///
  /// In es, this message translates to:
  /// **'Murdoku Diario'**
  String get appTitle;

  /// Nombre de la piel Ilustrada.
  ///
  /// In es, this message translates to:
  /// **'Ilustrada'**
  String get skinIllustrated;

  /// Nombre de la piel Papel.
  ///
  /// In es, this message translates to:
  /// **'Papel'**
  String get skinPaper;

  /// Nombre de la piel neutra (solo para pruebas internas).
  ///
  /// In es, this message translates to:
  /// **'Neutra'**
  String get skinNeutral;

  /// Lema bajo el nombre del juego en la pantalla de carga.
  ///
  /// In es, this message translates to:
  /// **'Un misterio de papel'**
  String get splashTagline;

  /// Etiqueta de accesibilidad de la barra de carga inicial.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get splashLoading;

  /// Saludo de Inicio antes de las 12 h.
  ///
  /// In es, this message translates to:
  /// **'Buenos días,'**
  String get homeGreetingMorning;

  /// Saludo de Inicio entre las 12 y las 19 h.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes,'**
  String get homeGreetingAfternoon;

  /// Saludo de Inicio desde las 19 h.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches,'**
  String get homeGreetingEvening;

  /// Segunda línea del saludo de Inicio.
  ///
  /// In es, this message translates to:
  /// **'detective'**
  String get homeDetective;

  /// Línea de la tarjeta del reto diario con la racha simulada.
  ///
  /// In es, this message translates to:
  /// **'Racha: {streak, plural, =1{1 día} other{{streak} días}} · Caso del día (simulación: aún sin servidor)'**
  String homeStreakLine(int streak);

  /// Día del reto dentro del ciclo de retos.
  ///
  /// In es, this message translates to:
  /// **'Día {day} de {total}'**
  String challengeDayOf(int day, int total);

  /// Casos cerrados del Mundo 1 sobre el total.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{solved} de 1 caso cerrado} other{{solved} de {total} casos cerrados}}'**
  String homeSolvedCount(int solved, int total);

  /// Etiqueta de accesibilidad de la barra de progreso del Mundo 1.
  ///
  /// In es, this message translates to:
  /// **'Progreso del Mundo 1'**
  String get homeWorldProgress;

  /// Tiempo simulado hasta la próxima vida.
  ///
  /// In es, this message translates to:
  /// **'+1 en {time}'**
  String homeNextLife(String time);

  /// Subtítulo de Mundos: cuántos mundos se pueden abrir.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{open} de 1 disponible} other{{open} de {total} disponibles}}'**
  String worldsAvailable(int open, int total);

  /// Etiqueta de accesibilidad de un mundo disponible.
  ///
  /// In es, this message translates to:
  /// **'{name}: entrar'**
  String worldsEnter(String name);

  /// Etiqueta de accesibilidad de la barra de progreso de un mundo.
  ///
  /// In es, this message translates to:
  /// **'Progreso de {name}'**
  String worldsProgress(String name);

  /// Título de la racha simulada en la pestaña Reto.
  ///
  /// In es, this message translates to:
  /// **'{streak, plural, =1{1 día de racha} other{{streak} días de racha}}'**
  String challengeStreakTitle(int streak);

  /// Racha máxima y protectores simulados.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha: {best} · protectores: {protectors}'**
  String challengeBestStreak(int best, int protectors);

  /// Inicial del lunes en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get challengeWeekdayMon;

  /// Inicial del martes en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get challengeWeekdayTue;

  /// Inicial del miércoles en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get challengeWeekdayWed;

  /// Inicial del jueves en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get challengeWeekdayThu;

  /// Inicial del viernes en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get challengeWeekdayFri;

  /// Inicial del sábado en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get challengeWeekdaySat;

  /// Inicial del domingo en la tira de la semana.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get challengeWeekdaySun;

  /// Resumen del reto de hoy: día, dificultad y tamaño del tablero.
  ///
  /// In es, this message translates to:
  /// **'Día {day} de {total} · {difficulty} · {size}×{size}'**
  String challengeTodaySummary(int day, int total, String difficulty, int size);

  /// Puntos abreviados.
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String pointsShort(int points);

  /// Nombre por defecto del jugador.
  ///
  /// In es, this message translates to:
  /// **'Detective'**
  String get profileDefaultNick;

  /// Tooltip del botón que edita el nombre del jugador.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get profileChangeName;

  /// Línea simulada bajo el nombre en el perfil.
  ///
  /// In es, this message translates to:
  /// **'🇨🇴 · detective desde julio 2026'**
  String get profileSince;

  /// Rótulo de la cifra de casos cerrados en el perfil.
  ///
  /// In es, this message translates to:
  /// **'casos cerrados'**
  String get profileSolvedLabel;

  /// Rótulo de la cifra de racha actual en el perfil.
  ///
  /// In es, this message translates to:
  /// **'racha actual'**
  String get profileStreakLabel;

  /// Rótulo de la cifra de mejor racha en el perfil.
  ///
  /// In es, this message translates to:
  /// **'mejor racha'**
  String get profileBestStreakLabel;

  /// Rótulo de la cifra de puntos semanales en el perfil.
  ///
  /// In es, this message translates to:
  /// **'puntos semana'**
  String get profileWeekPointsLabel;

  /// Fila del menú del perfil que abre la tienda.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get profileMenuShop;

  /// Fila del menú del perfil que abre Premium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get profileMenuPremium;

  /// Fila del menú del perfil que abre las instrucciones.
  ///
  /// In es, this message translates to:
  /// **'Cómo jugar'**
  String get profileMenuHowToPlay;

  /// Fila del menú del perfil que abre la configuración.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profileMenuSettings;

  /// Producto simulado de la tienda: paquete de vidas.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 vida} other{{count} vidas}}'**
  String shopLives(int count);

  /// Producto simulado de la tienda: protectores de racha.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 protector de racha} other{{count} protectores de racha}}'**
  String shopProtectors(int count);

  /// Botón de la suscripción mensual simulada.
  ///
  /// In es, this message translates to:
  /// **'Mensual · {price}'**
  String premiumMonthly(String price);

  /// Botón de la suscripción anual simulada.
  ///
  /// In es, this message translates to:
  /// **'Anual · {price} (ahorra 50%)'**
  String premiumYearly(String price);

  /// Versión de la app al pie de la configuración.
  ///
  /// In es, this message translates to:
  /// **'Murdoku Diario v{version}'**
  String settingsVersion(String version);

  /// Título de la primera página (bienvenida) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido, detective'**
  String get tutorialDialogWelcomeTitle;

  /// Línea 1 de la primera página (bienvenida) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'En cada caso hay un grupo de sospechosos, una víctima y UNA verdad.'**
  String get tutorialDialogWelcomeLine1;

  /// Línea 2 de la primera página (bienvenida) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Tu misión: descubrir dónde estaba cada persona usando pura lógica.'**
  String get tutorialDialogWelcomeLine2;

  /// Línea 3 de la primera página (bienvenida) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Nada de adivinar — cada caso tiene una única solución deducible.'**
  String get tutorialDialogWelcomeLine3;

  /// Título de la segunda página (el tablero) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'El tablero'**
  String get tutorialDialogBoardTitle;

  /// Línea 1 de la segunda página (el tablero) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'El mapa es una cuadrícula con habitaciones y muebles.'**
  String get tutorialDialogBoardLine1;

  /// Línea 2 de la segunda página (el tablero) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'REGLA DE ORO: hay exactamente UNA persona por fila y UNA por columna, como en un sudoku.'**
  String get tutorialDialogBoardLine2;

  /// Línea 3 de la segunda página (el tablero) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Las casillas con muebles que bloquean (mesas, plantas, cajas) no pueden ocuparse. Sobre sillas, camas, sofás y alfombras SÍ puede haber alguien.'**
  String get tutorialDialogBoardLine3;

  /// Título de la tercera página (las pistas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Las pistas'**
  String get tutorialDialogCluesTitle;

  /// Línea 1 de la tercera página (las pistas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Cada sospechoso tiene una pista en su tarjeta: \"estaba sobre una cama\", \"junto a una planta\"…'**
  String get tutorialDialogCluesLine1;

  /// Línea 2 de la tercera página (las pistas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'\"Junto a\" significa en una casilla vecina (arriba, abajo, izquierda o derecha) de la misma habitación.'**
  String get tutorialDialogCluesLine2;

  /// Línea 3 de la tercera página (las pistas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Cruza las pistas con la regla de filas y columnas para descartar casillas.'**
  String get tutorialDialogCluesLine3;

  /// Título de la cuarta página (las marcas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Tus marcas'**
  String get tutorialDialogMarksTitle;

  /// Línea 1 de la cuarta página (las marcas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'TOCA una casilla para anotar un CANDIDATO (una letra pequeña).'**
  String get tutorialDialogMarksLine1;

  /// Línea 2 de la cuarta página (las marcas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'MANTÉN PRESIONADO (o usa la herramienta Confirmar) para CONFIRMAR a alguien: se tachan su fila y su columna automáticamente.'**
  String get tutorialDialogMarksLine2;

  /// Línea 3 de la cuarta página (las marcas) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Usa Tachar para descartar casillas y Borrar para limpiar. Deshacer siempre está disponible.'**
  String get tutorialDialogMarksLine3;

  /// Título de la quinta página (resolver el caso) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Resolver el caso'**
  String get tutorialDialogSolveTitle;

  /// Línea 1 de la quinta página (resolver el caso) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Cuando todos estén confirmados, pulsa RESOLVER.'**
  String get tutorialDialogSolveLine1;

  /// Línea 2 de la quinta página (resolver el caso) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Si todo está correcto: el asesino es quien quedó A SOLAS con la víctima en la misma habitación. El sistema lo revela.'**
  String get tutorialDialogSolveLine2;

  /// Línea 3 de la quinta página (resolver el caso) del diálogo de cómo jugar.
  ///
  /// In es, this message translates to:
  /// **'Si algo no cuadra, el juego te dice cuántas casillas fallan, pero no cuáles: hay que volver a deducir. ¡Suerte, detective!'**
  String get tutorialDialogSolveLine3;

  /// Mensaje cuando no se pueden cargar los casos.
  ///
  /// In es, this message translates to:
  /// **'Error cargando casos: {error}'**
  String caseListLoadError(String error);

  /// Pestaña de cada carpeta de dificultad con su número de expediente.
  ///
  /// In es, this message translates to:
  /// **'EXPEDIENTE Nº{index}'**
  String caseListFolderNumber(int index);

  /// Tamaño del tablero de los casos de una carpeta.
  ///
  /// In es, this message translates to:
  /// **'Tablero {size}×{size}'**
  String caseListBoardSize(int size);

  /// Etiqueta de accesibilidad de la barra de progreso de una dificultad.
  ///
  /// In es, this message translates to:
  /// **'Progreso de {difficulty}'**
  String caseListDifficultyProgress(String difficulty);

  /// Etiqueta de accesibilidad de la ficha de un caso.
  ///
  /// In es, this message translates to:
  /// **'Caso {number}: {title}'**
  String caseListTileLabel(int number, String title);

  /// Etiqueta de accesibilidad de la ficha de un caso ya cerrado.
  ///
  /// In es, this message translates to:
  /// **'Caso {number}: {title}, cerrado'**
  String caseListTileLabelDone(int number, String title);

  /// Número de caso sobre la ficha.
  ///
  /// In es, this message translates to:
  /// **'Nº {number}'**
  String caseListNumberShort(int number);

  /// Etiqueta sobre la ficha de un caso empezado, con el tiempo jugado.
  ///
  /// In es, this message translates to:
  /// **'En curso · {time}'**
  String caseListInProgressTag(String time);

  /// Etiqueta destacada del caso actual empezado, con el tiempo jugado.
  ///
  /// In es, this message translates to:
  /// **'EN CURSO · {time}'**
  String caseListInProgressTagStrong(String time);

  /// Título de la hoja con el detalle de un caso.
  ///
  /// In es, this message translates to:
  /// **'Caso Nº{number} — {title}'**
  String caseListSheetTitle(int number, String title);

  /// Cantidad de sospechosos de un caso.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sospechoso} other{{count} sospechosos}}'**
  String caseListSuspects(int count);

  /// Cantidad de pistas de un caso.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pista} other{{count} pistas}}'**
  String caseListClues(int count);

  /// Chip que indica que el caso tiene arma homicida.
  ///
  /// In es, this message translates to:
  /// **'arma homicida'**
  String get caseListWeapon;

  /// Resultado de un caso ya cerrado: segundos y errores.
  ///
  /// In es, this message translates to:
  /// **'Caso cerrado en {time} s · {errors, plural, =1{1 error} other{{errors} errores}}'**
  String caseListClosedIn(String time, int errors);

  /// Avance de un caso empezado: tiempo jugado y errores.
  ///
  /// In es, this message translates to:
  /// **'En curso: {time} jugados · {errors, plural, =1{1 error} other{{errors} errores}}'**
  String caseListInProgressInfo(String time, int errors);

  /// Título del bloque de información adicional de la leyenda.
  ///
  /// In es, this message translates to:
  /// **'INFORMACIÓN ADICIONAL'**
  String get gameLegendExtraTitle;

  /// Título del bloque de habitaciones de la leyenda.
  ///
  /// In es, this message translates to:
  /// **'HABITACIONES'**
  String get gameLegendRoomsTitle;

  /// Habitación de la leyenda con las armas que hay en ella.
  ///
  /// In es, this message translates to:
  /// **'{room}  ·  armas: {weapons}'**
  String gameLegendRoomWeapons(String room, String weapons);

  /// Título del bloque de muebles de la leyenda.
  ///
  /// In es, this message translates to:
  /// **'MUEBLES'**
  String get gameLegendFurnitureTitle;

  /// Explicación de los muebles pisables en la leyenda.
  ///
  /// In es, this message translates to:
  /// **'Pisables: puedes colocar gente encima. Los demás bloquean su casilla.'**
  String get gameLegendFurnitureNote;

  /// Mueble pisable en la leyenda, marcado con un círculo.
  ///
  /// In es, this message translates to:
  /// **'{name} ◦'**
  String gameLegendStandable(String name);

  /// Clave del círculo que marca los muebles pisables.
  ///
  /// In es, this message translates to:
  /// **'◦ = pisable'**
  String get gameLegendStandableKey;

  /// Título del bloque de reglas de la leyenda.
  ///
  /// In es, this message translates to:
  /// **'REGLAS'**
  String get gameLegendRulesTitle;

  /// Resumen de las reglas en la leyenda.
  ///
  /// In es, this message translates to:
  /// **'Una persona por fila y por columna. El asesino quedó a solas con la víctima en la misma habitación. Ubica a todos, incluida la víctima.'**
  String get gameLegendRulesBody;

  /// Etiqueta de accesibilidad de un retrato ya colocado en el tablero.
  ///
  /// In es, this message translates to:
  /// **'{label}, ya colocado'**
  String gameHintPlaced(String label);

  /// Etiqueta de accesibilidad del retrato de la víctima.
  ///
  /// In es, this message translates to:
  /// **'{name} ({victim})'**
  String gameHintVictimLabel(String name, String victim);

  /// Etiqueta de accesibilidad de la pista de un personaje.
  ///
  /// In es, this message translates to:
  /// **'{name}: {clue}'**
  String gameHintClueSemantics(String name, String clue);

  /// Etiqueta de accesibilidad del cronómetro.
  ///
  /// In es, this message translates to:
  /// **'Tiempo {time}'**
  String gameToolbarTime(String time);

  /// Etiqueta de accesibilidad del tablero completo.
  ///
  /// In es, this message translates to:
  /// **'Tablero de {n} por {n} casillas'**
  String boardSemanticsBoard(int n);

  /// Posición de una casilla leída por el lector de pantalla.
  ///
  /// In es, this message translates to:
  /// **'Fila {row}, columna {col}'**
  String boardSemanticsPosition(int row, int col);

  /// Muebles de las casillas vecinas (lista separada por comas).
  ///
  /// In es, this message translates to:
  /// **'junto a {names}'**
  String boardSemanticsBesideObjects(String names);

  /// Mueble pisable que cubre la casilla.
  ///
  /// In es, this message translates to:
  /// **'sobre {name}'**
  String boardSemanticsOnObject(String name);

  /// Mueble que bloquea la casilla.
  ///
  /// In es, this message translates to:
  /// **'ocupada por {name}: no se puede usar'**
  String boardSemanticsBlockedBy(String name);

  /// Candidatos anotados en la casilla (lista separada por comas).
  ///
  /// In es, this message translates to:
  /// **'candidatos: {names}'**
  String boardSemanticsCandidates(String names);

  /// Personaje confirmado en la casilla.
  ///
  /// In es, this message translates to:
  /// **'confirmado: {name}'**
  String boardSemanticsConfirmed(String name);

  /// Casilla tachada sola por los personajes ya confirmados (lista separada por comas).
  ///
  /// In es, this message translates to:
  /// **'descartada por {names}'**
  String boardSemanticsAutoCrossed(String names);

  /// Revelación del asesino; el nombre va resaltado.
  ///
  /// In es, this message translates to:
  /// **'El asesino era {name}, que quedó a solas con la víctima.'**
  String victoryMurdererLine(String name);

  /// Arma homicida del caso; el nombre va resaltado.
  ///
  /// In es, this message translates to:
  /// **'Arma homicida: {weapon}'**
  String victoryWeaponLine(String weapon);

  /// Aviso sobre el tablero: falta elegir un sospechoso antes de tocar una casilla.
  ///
  /// In es, this message translates to:
  /// **'Elige primero a un sospechoso'**
  String get boardPickSuspectFirst;

  /// Aviso sobre el tablero: la casilla ya tiene un sospechoso confirmado.
  ///
  /// In es, this message translates to:
  /// **'Esa casilla ya tiene una ficha. Bórrala primero'**
  String get boardCellHasConfirmed;

  /// Aviso sobre el tablero: la casilla está tachada.
  ///
  /// In es, this message translates to:
  /// **'Esa casilla está tachada'**
  String get boardCellHasX;

  /// Aviso sobre el tablero: el sospechoso ya está confirmado en otra casilla.
  ///
  /// In es, this message translates to:
  /// **'Ese sospechoso ya está colocado. Bórralo para moverlo'**
  String get boardAlreadyPlaced;

  /// Aviso sobre el tablero: la casilla tiene un mueble que bloquea.
  ///
  /// In es, this message translates to:
  /// **'Ahí hay un mueble'**
  String get boardBlockedCell;

  /// Resultado de un Resolver fallido: cuántas casillas no cuadran.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 casilla no cuadra} other{{n} casillas no cuadran}}'**
  String boardWrongCells(int n);

  /// Aviso de un Resolver incompleto: cuántos personajes faltan por ubicar.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Falta ubicar a 1 personaje} other{Faltan {n} personajes por ubicar}}'**
  String boardMissingSuspects(int n);

  /// Rótulo de la revelación del asesino sobre el tablero.
  ///
  /// In es, this message translates to:
  /// **'El asesino es {name}'**
  String boardMurdererIs(String name);

  /// Aviso del tutorial tras un Resolver fallido.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 casilla no cuadra} other{{n} casillas no cuadran}}: revisa las marcadas'**
  String gameScreenWrongInTutorial(int n);

  /// Título de la partida del tutorial.
  ///
  /// In es, this message translates to:
  /// **'Tutorial · {title}'**
  String gameScreenTutorialHeading(String title);

  /// Primera parte de la línea de estado del tutorial.
  ///
  /// In es, this message translates to:
  /// **'Práctica · {size}×{size}'**
  String gameScreenPracticeHead(int size);

  /// Primera parte de la línea de estado de un caso.
  ///
  /// In es, this message translates to:
  /// **'{difficulty} · {size}×{size}'**
  String gameScreenCaseHead(String difficulty, int size);

  /// Primera parte de la línea de estado de un caso con arma homicida.
  ///
  /// In es, this message translates to:
  /// **'{difficulty} · {size}×{size} · con arma'**
  String gameScreenCaseHeadWeapon(String difficulty, int size);

  /// Línea de estado bajo el título de la partida.
  ///
  /// In es, this message translates to:
  /// **'{head} · errores: {errors}'**
  String gameScreenStatusLine(String head, int errors);

  /// Posición de una casilla dentro de un paso del tutorial.
  ///
  /// In es, this message translates to:
  /// **'fila {row}, columna {col}'**
  String tutorialCoachRowCol(int row, int col);

  /// Pista entre comillas latinas dentro de un paso del tutorial.
  ///
  /// In es, this message translates to:
  /// **'«{text}»'**
  String tutorialCoachClueQuote(String text);

  /// Aviso cuando un personaje está confirmado en la casilla equivocada.
  ///
  /// In es, this message translates to:
  /// **'{name} no va ahí: {why} Bórrala con BORRAR y prueba otra.'**
  String tutorialCoachMisplaced(String name, String why);

  /// Razón del aviso para la víctima mal colocada.
  ///
  /// In es, this message translates to:
  /// **'solo cuadra junto a una cama, sin estar encima de ella.'**
  String get tutorialCoachWhyVictim;

  /// Razón del aviso para Bruno mal colocado.
  ///
  /// In es, this message translates to:
  /// **'solo puede ir en la casilla de cama que no está tachada.'**
  String get tutorialCoachWhyBruno;

  /// Razón del aviso para Clara mal colocada.
  ///
  /// In es, this message translates to:
  /// **'solo cuadra en la única casilla libre de su habitación.'**
  String get tutorialCoachWhyClara;

  /// Aviso cuando una X manual tapa la casilla de un personaje.
  ///
  /// In es, this message translates to:
  /// **'Esa X tapa la casilla de alguien. Bórrala con BORRAR.'**
  String get tutorialCoachWarnXOnSolution;

  /// Aviso cuando los cinco personajes están puestos pero alguno está mal.
  ///
  /// In es, this message translates to:
  /// **'Los cinco están puestos, pero alguno no cuadra. Relee las pistas de los que dudes.'**
  String get tutorialCoachWarnFiveWrong;

  /// Aviso cuando el jugador dejó el tablero correcto en el paso del experimento.
  ///
  /// In es, this message translates to:
  /// **'Ese tablero es el correcto; para el experimento hay que intercambiarlos.'**
  String get tutorialCoachWarnBoardCorrect;

  /// Aviso cuando se pulsa Resolver demasiado pronto en el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Aún no: antes del Resolver final hay un experimento. Sigue la tarjeta de arriba (o pulsa Saltar).'**
  String get tutorialCoachBlockResolve;

  /// Paso 1 del tutorial: presentación del caso de práctica.
  ///
  /// In es, this message translates to:
  /// **'Este es un caso de práctica con solo 5 personajes. No cuenta como ningún caso de la lista. Abajo del mapa están los sospechosos: toca uno y verás su pista.'**
  String get tutorialCoachStep0;

  /// Paso 2 del tutorial: la regla de oro.
  ///
  /// In es, this message translates to:
  /// **'Regla de oro: UNA persona por fila y UNA por columna, como en un sudoku. Hay que ubicar a todos, incluida la víctima: {victim} (su retrato dice «Víctima»).'**
  String tutorialCoachStep1(String victim);

  /// Paso 3 del tutorial: anotar un candidato.
  ///
  /// In es, this message translates to:
  /// **'Pista de {victim}: {clue}. Toca su retrato y luego TOCA una casilla donde pueda estar: queda anotada como candidato (su letra).'**
  String tutorialCoachStep2(String victim, String clue);

  /// Paso 4 del tutorial: confirmar a la víctima (herramienta Confirmar ya activa).
  ///
  /// In es, this message translates to:
  /// **'{area}: la única casilla junto a una cama sin ser cama es {cell}. Con {victim} elegida, toca esa casilla.'**
  String tutorialCoachStep3Place(String area, String cell, String victim);

  /// Paso 4 del tutorial: confirmar a la víctima (falta elegir la herramienta).
  ///
  /// In es, this message translates to:
  /// **'{area}: la única casilla junto a una cama sin ser cama es {cell}. Con {victim} elegida, pulsa CONFIRMAR y toca esa casilla.'**
  String tutorialCoachStep3Tool(String area, String cell, String victim);

  /// Paso 5 del tutorial: la X automática.
  ///
  /// In es, this message translates to:
  /// **'¿Viste? Al confirmar a {victim}, el juego tachó con X claras su fila y su columna (es el interruptor Auto-X del menú ⋮): ahí ya no puede haber nadie más.'**
  String tutorialCoachStep4(String victim);

  /// Paso 6 del tutorial: confirmar a Bruno.
  ///
  /// In es, this message translates to:
  /// **'Pista de {bruno}: {clue}. Casi todas las casillas de cama quedaron tachadas: solo una sigue libre, {cell}. Confirma a {bruno} ahí.'**
  String tutorialCoachStep5(String bruno, String clue, String cell);

  /// Casilla sugerida para ensayar la X cuando no hay una concreta.
  ///
  /// In es, this message translates to:
  /// **'una casilla en {area} que no sea el sofá'**
  String tutorialCoachStep6AnyCell(String area);

  /// Paso 7 del tutorial: X a mano con la herramienta Tachar activa.
  ///
  /// In es, this message translates to:
  /// **'Con TACHAR activo, toca {where}. Esa X la pones tú: sirve para descartar lo que sabes que no puede ser.'**
  String tutorialCoachStep6Cross(String where);

  /// Paso 7 del tutorial: X a mano, falta elegir la herramienta.
  ///
  /// In es, this message translates to:
  /// **'{elena} está sobre un sofá, en {area}: ahí nadie más puede estar. Descártalo: pulsa TACHAR en la barra y toca una casilla de esa habitación.'**
  String tutorialCoachStep6Tool(String elena, String area);

  /// Paso 8 del tutorial: cambiar a la vista Notas.
  ///
  /// In es, this message translates to:
  /// **'Para pensar sin el dibujo, abre el menú ⋮ (arriba a la derecha) y cambia a la vista NOTAS.'**
  String get tutorialCoachStep7;

  /// Paso 9 del tutorial: volver a la vista Mapa.
  ///
  /// In es, this message translates to:
  /// **'NOTAS esconde los muebles y los nombres: queda la cuadrícula con tus marcas, ideal para repasar filas y columnas. Vuelve a MAPA desde el menú ⋮.'**
  String get tutorialCoachStep8;

  /// Paso 10 del tutorial: confirmar a Clara.
  ///
  /// In es, this message translates to:
  /// **'Pista de {clara}: {clue}. Con las X que hay, en {area} solo queda una casilla libre: {cell}. Confirma a {clara} ahí.'**
  String tutorialCoachStep9(
    String clara,
    String clue,
    String area,
    String cell,
  );

  /// Paso 11 del tutorial: terminar el tablero.
  ///
  /// In es, this message translates to:
  /// **'Faltan {elena} ({elenaClue}) y {dario} ({darioClue}). Termina tú con las X y la regla de fila y columna.'**
  String tutorialCoachStep10(
    String elena,
    String elenaClue,
    String dario,
    String darioClue,
  );

  /// Paso 12 del tutorial: borrar dos fichas para el experimento.
  ///
  /// In es, this message translates to:
  /// **'¡Todos bien ubicados! Antes de resolver, un experimento: equivoquémonos a propósito. Primero quita a {elena} y a {dario}: pulsa BORRAR y toca cada ficha en el mapa.'**
  String tutorialCoachStep11(String elena, String dario);

  /// Paso 13 del tutorial: intercambiar dos personajes.
  ///
  /// In es, this message translates to:
  /// **'Ahora cámbialos de sitio: {elena} en {elenaCell} y {dario} en {darioCell}. Elige su retrato, pulsa CONFIRMAR y toca la casilla.'**
  String tutorialCoachStep12(
    String elena,
    String elenaCell,
    String dario,
    String darioCell,
  );

  /// Paso 14 del tutorial: Resolver fallido.
  ///
  /// In es, this message translates to:
  /// **'Con el tablero lleno pero mal, pulsa RESOLVER (abajo). En el tutorial el juego marca en rojo las casillas que no cuadran.'**
  String get tutorialCoachStep13;

  /// Paso 15 del tutorial: explicación de las casillas rojas.
  ///
  /// In es, this message translates to:
  /// **'Las casillas rojas no cuadran: {elena} no está sobre un sofá, como exige su pista, y por eso falla también {dario}. En una partida real solo verás CUÁNTAS no cuadran.'**
  String tutorialCoachStep14(String elena, String dario);

  /// Paso 16 del tutorial: borrar para corregir.
  ///
  /// In es, this message translates to:
  /// **'Para corregir, pulsa BORRAR otra vez y toca a {elena} y a {dario} en el mapa para limpiarlos.'**
  String tutorialCoachStep15(String elena, String dario);

  /// Paso 17 del tutorial: poner a los dos en su sitio.
  ///
  /// In es, this message translates to:
  /// **'Ahora ponlos bien: {elena} en {elenaCell} (sobre el sofá) y {dario} en {darioCell} (a solas).'**
  String tutorialCoachStep16(
    String elena,
    String elenaCell,
    String dario,
    String darioCell,
  );

  /// Paso 18 del tutorial: Resolver final.
  ///
  /// In es, this message translates to:
  /// **'¡Tablero completo y correcto! Pulsa RESOLVER: si todo cuadra, sabrás quién quedó a solas con la víctima. Ese es el asesino.'**
  String get tutorialCoachStep17;

  /// Mensaje cuando no se puede cargar el caso del tutorial.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el tutorial.'**
  String get tutorialCoachLoadError;

  /// Botón para volver a la lista de casos desde el error del tutorial.
  ///
  /// In es, this message translates to:
  /// **'Volver a los casos'**
  String get tutorialCoachBackToCases;

  /// Progreso de los pasos de la guía del tutorial.
  ///
  /// In es, this message translates to:
  /// **'TUTORIAL · {index}/{total}'**
  String tutorialCoachProgress(int index, int total);

  /// Aviso de la guía con el símbolo de advertencia delante.
  ///
  /// In es, this message translates to:
  /// **'⚠ {text}'**
  String tutorialCoachWarning(String text);

  /// Botón para pasar al siguiente paso manual de la guía.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get tutorialCoachGotIt;

  /// Título del cierre del tutorial.
  ///
  /// In es, this message translates to:
  /// **'¡Práctica superada!'**
  String get tutorialEndTitle;

  /// Revelación del asesino al terminar el tutorial.
  ///
  /// In es, this message translates to:
  /// **'El asesino era {name}: fue la única persona que quedó a solas con la víctima.'**
  String tutorialEndMurderer(String name);

  /// Resumen de lo aprendido al terminar el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Ya sabes ubicar, descartar con X, usar Notas, borrar y resolver. Esto era solo práctica: tu Caso 1 te espera sin empezar.'**
  String get tutorialEndSummary;

  /// Botón que lleva a la lista de casos al terminar el tutorial.
  ///
  /// In es, this message translates to:
  /// **'Ir a los casos'**
  String get tutorialEndGoToCases;

  /// Botón para cerrar el cierre del tutorial y seguir mirando el tablero.
  ///
  /// In es, this message translates to:
  /// **'Seguir mirando el tablero'**
  String get tutorialEndLookBoard;

  /// Aviso mientras la partida espera la respuesta del servidor a Resolver.
  ///
  /// In es, this message translates to:
  /// **'Comprobando tu solución…'**
  String get validationChecking;

  /// Aviso de la partida cuando Resolver se envió sin conexión y el tablero queda por validar.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo validamos en cuanto tengas señal.'**
  String get validationPending;

  /// Marca en la lista de casos (y en el estado del reto) de un caso con la solución enviada sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Por validar'**
  String get validationPendingTag;

  /// Texto en la ficha de un caso cuyo envío espera señal.
  ///
  /// In es, this message translates to:
  /// **'Enviaste tu solución sin conexión. La validamos en cuanto tengas señal.'**
  String get validationPendingSheetInfo;

  /// Botón de la ficha de un caso por validar.
  ///
  /// In es, this message translates to:
  /// **'Ver el caso'**
  String get validationPendingOpen;

  /// Aviso cuando el servidor limita los envíos de Resolver por minuto.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento.'**
  String get validationRateLimited;

  /// Aviso cuando el servidor no acepta el envío de Resolver.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar este caso. Inténtalo de nuevo.'**
  String get validationRejected;

  /// Aviso discreto cuando llega, con el jugador fuera de la partida, la respuesta de que el caso quedó resuelto.
  ///
  /// In es, this message translates to:
  /// **'Validamos tu solución: «{title}» quedó resuelto.'**
  String validationLateSolved(String title);

  /// Aviso discreto cuando llega, con el jugador fuera de la partida, la respuesta de que la solución no era correcta.
  ///
  /// In es, this message translates to:
  /// **'Tu solución de «{title}» no era correcta: {n, plural, =1{1 casilla no cuadra} other{{n} casillas no cuadran}}.'**
  String validationLateWrong(String title, int n);

  /// Título y aviso cuando el envío de Resolver se detuvo tras errores seguidos del servidor.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar tu solución.'**
  String get validationStalledTitle;

  /// Explicación del diálogo de un envío detenido.
  ///
  /// In es, this message translates to:
  /// **'Hubo un problema al validar tu solución. Puedes reintentar o cancelar el envío y seguir con el tablero.'**
  String get validationStalledBody;

  /// Botón que vuelve a enviar un envío detenido.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get validationRetry;

  /// Botón que quita de la cola un envío detenido y desbloquea el tablero.
  ///
  /// In es, this message translates to:
  /// **'Cancelar envío'**
  String get validationCancelSubmit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

/// Pantalla de partida (doc 06, pantalla 19) con el tablero de Flame del
/// ADR-0013: escena de Flame a todo el ancho, barra de herramientas (Anotar,
/// Tachar, Confirmar, Borrar), retratos con la pista del personaje, Resolver
/// y un menú para las acciones secundarias. Las reglas siguen en
/// [GameController]; aquí solo se arma la pantalla y se conecta el tablero
/// con el controlador y con el director de feedback.
///
/// Rendimiento (H-58): el reloj solo redibuja la pastilla del cronómetro. El
/// tablero vive en una escena de Flame que no se reconstruye con los
/// segundos, y cada bloque de la pantalla mira solo lo que le toca.
library;

import 'dart:async';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../board/feedback/feedback_director.dart';
import '../board/feedback/feedback_plan.dart';
import '../board/fps_recorder.dart';
import '../board/scene/board_game.dart';
import '../board/scene/skin.dart';
import '../board/scene/skins.dart';
import '../board/scene_session.dart';
import '../data/case_repository.dart';
import '../game/app_settings.dart';
import '../game/board_interaction.dart';
import '../game/dev_tools.dart';
import '../game/feedback_providers.dart';
import '../game/game_controller.dart';
import 'board_semantics.dart';
import 'fps_overlay.dart';
import 'game_chrome.dart';
import 'game_menu.dart';
import 'game_toolbar.dart';
import 'game_tray.dart';
import 'layout_metrics.dart';
import 'skin_theme.dart';
import 'registration_screen.dart' show showRegistrationInvite;
import 'tutorial_coach.dart';
import 'v1_scope.dart' show caseTitle, difficultyName, exitRouteFor;
import 'victory_screen.dart';

class GameScreen extends ConsumerWidget {
  final String caseId;

  /// Modo tutorial (regla 11, ADR-0012): juega el caso propio de
  /// assets/tutorial (no el del banco, [caseId] se ignora), con la guía
  /// paso a paso, sin escribir "done:" y con Saltar siempre visible.
  final bool tutorial;
  const GameScreen({super.key, required this.caseId, this.tutorial = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tutorial) {
      return TutorialLoader(builder: (pc) => _GameView(pc: pc, tutorial: true));
    }
    final pc = ref.watch(caseByIdProvider(caseId));
    if (pc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _GameView(pc: pc, tutorial: tutorial);
  }
}

/// Pone a la partida el tema de la piel y el modo elegidos en Configuración.
/// Las demás pantallas de la app conservan su estilo (se migran en la 4.2).
class _GameView extends ConsumerWidget {
  final PuzzleCase pc;
  final bool tutorial;
  const _GameView({required this.pc, this.tutorial = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinId = ref.watch(settingsProvider.select((s) => s.skinId));
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final brightness = resolveBrightness(
      mode,
      MediaQuery.platformBrightnessOf(context),
    );
    // La partida tiene alturas medidas: respeta el texto del sistema hasta
    // 1,3 (las medidas crecen con él, ver ScreenMetrics) y no pasa de ahí.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kGameMaxTextScale,
      child: Theme(
        data: SkinUi.theme(skinId, brightness),
        child: _GameBody(pc: pc, tutorial: tutorial),
      ),
    );
  }
}

/// Reparte los efectos visuales entre la escena de Flame y la interfaz.
class _VisualRouter implements VisualSink {
  BoardGame? game;
  void Function(String text)? onMessage;
  void Function(String text)? onWrong;
  void Function(String charId)? onSelect;

  @override
  void play(VisualEffect e) {
    game?.play(e);
    switch (e.kind) {
      case VisualKind.message:
        onMessage?.call(e.text ?? '');
      case VisualKind.errorText:
        onWrong?.call(e.text ?? '');
      case VisualKind.selectPulse:
        onSelect?.call(e.charId!);
      default:
        break;
    }
  }
}

class _GameBody extends ConsumerStatefulWidget {
  final PuzzleCase pc;
  final bool tutorial;
  const _GameBody({required this.pc, required this.tutorial});

  @override
  ConsumerState<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends ConsumerState<_GameBody> {
  PuzzleCase get pc => widget.pc;
  bool get tutorial => widget.tutorial;

  final _VisualRouter _router = _VisualRouter();
  final ValueNotifier<TrayPulse?> _trayPulse = ValueNotifier(null);
  final ValueNotifier<String?> _toast = ValueNotifier(null);
  final ValueNotifier<String?> _live = ValueNotifier(null);
  Timer? _toastTimer;
  Timer? _fallbackTimer;
  Timer? _summaryTimer;

  late BoardSkin _skin;
  late String _skinId;
  late Brightness _mode;
  late SceneSession _scene;
  late BoardGame _game;
  late FeedbackDirector _director;
  late BoardInteraction _interaction;
  late SoundSink _sounds;
  FpsMonitor? _fps;

  bool _built = false;
  bool _systemReduce = false;
  bool _summaryShown = false;
  int _pulseSerial = 0;
  RingerMode _ringer = RingerMode.normal;

  // ---- construcción de la escena ----------------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final skinId = context.skinTheme.skinId;
    final mode = Theme.of(context).brightness;
    _systemReduce = MediaQuery.disableAnimationsOf(context);
    if (!_built) {
      _built = true;
      _skinId = skinId;
      _mode = mode;
      _skin = SkinRegistry.create(skinId, mode);
      _buildScene();
    } else {
      if (skinId != _skinId || mode != _mode) {
        // Cambió la piel o el modo: se redibuja el tablero sin perder nada.
        _skinId = skinId;
        _mode = mode;
        _skin = SkinRegistry.create(skinId, mode);
        _game.setSkin(_skin);
      }
      _applySettings();
    }
  }

  void _buildScene() {
    _sounds = ref.read(soundSinkProvider);
    _director = FeedbackDirector(
      l10n: context.l10n,
      settings: _effectiveSettings(),
      visuals: _router,
      sounds: _sounds,
      haptics: ref.read(hapticSinkProvider),
    );
    _scene = SceneSession(pc: pc, director: _director);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    _game = BoardGame(
      l10n: context.l10n,
      session: _scene,
      settings: _effectiveSettings(),
      skin: _skin,
      pixelRatio: dpr.clamp(1.0, 3.0),
    );
    _router.game = _game;
    _router.onMessage = _showToast;
    _router.onWrong = _onWrong;
    _router.onSelect = (id) => _trayPulse.value = TrayPulse(++_pulseSerial, id);
    _interaction = BoardInteraction(
      controller: ref.read(gameControllerProvider(pc).notifier),
      read: () => ref.read(gameControllerProvider(pc)),
      director: _director,
      confirmReplace: _askReplace,
    );
    _scene.onTapCell = _interaction.tapCell;
    _scene.onHoldCell = _interaction.holdCell;
    _game.onRevealStarted = () => _fps?.startRecording();
    _game.onRevealFinished = _onRevealFinished;

    // La escena copia lo que necesita dibujar de la partida.
    ref.listenManual<GameState>(
      gameControllerProvider(pc),
      (prev, next) => _syncScene(prev, next),
      fireImmediately: true,
    );
    // Cambios de opciones (sonido, vibración...).
    ref.listenManual<AppSettings>(settingsProvider, (_, _) => _applySettings());
    // Al volver a la app se vuelve a mirar el modo silencio del teléfono.
    ref.listenManual<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) _readRinger();
    });
    _readRinger();
  }

  AppSettings _effectiveSettings() => ref
      .read(settingsProvider)
      .effective(systemReduceMotion: _systemReduce, ringer: _ringer);

  void _applySettings() {
    final eff = _effectiveSettings();
    _director.settings = eff;
    _game.settings = eff;
  }

  Future<void> _readRinger() async {
    final mode = await ref.read(ringerProbeProvider).read();
    if (!mounted || mode == _ringer) return;
    _ringer = mode;
    _applySettings();
  }

  void _syncScene(GameState? prev, GameState s) {
    final sc = _scene;
    sc.board = s.board;
    sc.selectedChar = s.selectedChar;
    // Resuelto: no hay casillas posibles que resaltar.
    sc.highlightsCandidates =
        !s.solved &&
        (s.toolMode == ToolMode.notes || s.toolMode == ToolMode.place);
    sc.solved = s.solved;
    sc.errorCells = s.errorCells;
    sc.interactive =
        !s.paused &&
        !s.loading &&
        !s.solved &&
        !s.locked &&
        !s.submitting &&
        !s.pendingValidation;
    if (prev == null || prev.mapMode != s.mapMode) _game.setMapMode(s.mapMode);
    _syncValidation(prev, s);
  }

  /// Modo servidor: avisos mientras se espera la respuesta y reacción a la
  /// respuesta que llega tarde (el envío estaba "por validar").
  void _syncValidation(GameState? prev, GameState s) {
    final wasPending = prev?.pendingValidation ?? false;
    final wasSubmitting = prev?.submitting ?? false;
    final wasStalled = prev?.validationStalled ?? false;
    if (s.validationStalled && !wasStalled) {
      // El servidor falló varias veces seguidas: el jugador decide.
      _showToast(context.l10n.validationStalledTitle, persistent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_askStalled());
      });
    } else if (wasStalled && !s.validationStalled && s.pendingValidation) {
      _showToast(context.l10n.validationPending, persistent: true);
    } else if (s.pendingValidation && !wasPending) {
      _showToast(context.l10n.validationPending, persistent: true);
    } else if (s.submitting && !wasSubmitting) {
      _showToast(context.l10n.validationChecking, persistent: true);
    } else if ((wasPending && !s.pendingValidation) ||
        (wasSubmitting && !s.submitting && !s.pendingValidation)) {
      _clearToast();
    }
    // La respuesta llegó cuando el jugador seguía en la partida.
    if (wasPending && !s.pendingValidation) {
      if (s.solved) {
        _interaction.announceSolve(ActionFeedback.solvedOk);
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(const Duration(seconds: 9), _onRevealFinished);
      } else if (s.wrongCount > 0) {
        _interaction.announceSolve(ActionFeedback.wrongSolution);
      }
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _fallbackTimer?.cancel();
    _summaryTimer?.cancel();
    _sounds.stopLong();
    _trayPulse.dispose();
    _toast.dispose();
    _live.dispose();
    _fps?.dispose();
    super.dispose();
  }

  // ---- avisos ---------------------------------------------------------------------

  void _showToast(String text, {Duration? duration, bool persistent = false}) {
    _toast.value = text;
    _live.value = text;
    _toastTimer?.cancel();
    _toastTimer = null;
    // El aviso de "por validar" no se apaga solo: dura hasta la respuesta.
    if (persistent) return;
    _toastTimer = Timer(duration ?? const Duration(milliseconds: 1900), () {
      _toast.value = null;
    });
  }

  void _clearToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toast.value = null;
  }

  /// Toque en el tablero: durante el bloqueo de 3 s que sigue a un Resolver
  /// fallido el tablero no responde, así que se avisa en vez de callar.
  void _onBoardTouch() {
    if (ref.read(gameControllerProvider(pc)).locked) {
      _showToast(
        context.l10n.gameScreenLockedWait,
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  /// Resolver fallido: el tablero dibuja "N casillas no cuadran". Aquí se
  /// avisa también a los lectores de pantalla y, en el tutorial, se agrega
  /// que miren las casillas marcadas en rojo.
  void _onWrong(String text) {
    _live.value = text;
    if (tutorial) {
      final n = ref.read(gameControllerProvider(pc)).wrongCount;
      _showToast(
        context.l10n.gameScreenWrongInTutorial(n),
        duration: const Duration(milliseconds: 3200),
      );
    }
  }

  // ---- acciones ------------------------------------------------------------------

  Future<bool> _askReplace() async {
    if (!mounted) return false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.gameScreenReplaceTitle),
        content: Text(ctx.l10n.gameScreenReplaceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.gameScreenCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.gameScreenReplace),
          ),
        ],
      ),
    );
    return yes == true;
  }

  // Salir con seguridad (regla 10): el avance ya está guardado, pero se
  // pide confirmación para que un toque accidental no saque al jugador.
  Future<void> _requestExit() async {
    if (!mounted) return;
    final controller = ref.read(gameControllerProvider(pc).notifier);
    if (tutorial) {
      // El tutorial no guarda avance: salir equivale a saltarlo.
      if (ref.read(gameControllerProvider(pc)).solved) {
        await leaveTutorial(context);
        return;
      }
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.gameScreenExitTutorialTitle),
          content: Text(ctx.l10n.gameScreenExitTutorialBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.gameScreenKeepPracticing),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.gameScreenLeave),
            ),
          ],
        ),
      );
      if (leave == true && mounted) await leaveTutorial(context);
      return;
    }
    if (ref.read(gameControllerProvider(pc)).solved) {
      context.go(exitRouteFor(pc.caseId));
      return;
    }
    controller.holdClock();
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.gameScreenExitTitle),
        content: Text(ctx.l10n.gameScreenExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.gameScreenKeepPlaying),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.gameScreenLeave),
          ),
        ],
      ),
    );
    if (leave != true) {
      controller.releaseClock();
      return;
    }
    await controller.saveNow();
    // Nunca '/': la raíz pasa por la pantalla de carga.
    if (mounted) context.go(exitRouteFor(pc.caseId));
  }

  void _resolve() {
    final state = ref.read(gameControllerProvider(pc));
    if (tutorial) {
      // Antes del Resolver final la guía enseña uno fallido.
      final block = tutorialResolveBlock(
        context.l10n,
        pc,
        state,
        ref.read(tutorialStepProvider),
      );
      if (block != null) {
        _showToast(block, duration: const Duration(milliseconds: 3500));
        return;
      }
    }
    if (!tutorial && ref.read(gameControllerProvider(pc).notifier).usesServer) {
      unawaited(_resolveOnline());
      return;
    }
    final fb = _interaction.solve(revealCells: tutorial);
    _afterResolve(fb);
  }

  void _afterResolve(ActionFeedback fb) {
    if (fb == ActionFeedback.solvedOk) {
      // Si por algo la secuencia del tablero no termina, el resumen sale igual.
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(seconds: 9), _onRevealFinished);
    }
  }

  bool _stalledDialogOpen = false;

  /// Envío detenido por errores del servidor: Reintentar o Cancelar envío.
  /// Si se cierra el diálogo sin elegir, Resolver lo vuelve a abrir.
  Future<void> _askStalled() async {
    if (_stalledDialogOpen || !mounted) return;
    _stalledDialogOpen = true;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.validationStalledTitle),
        content: Text(ctx.l10n.validationStalledBody),
        actions: [
          TextButton(
            key: const ValueKey('envio-cancelar'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.validationCancelSubmit),
          ),
          FilledButton(
            key: const ValueKey('envio-reintentar'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.validationRetry),
          ),
        ],
      ),
    );
    _stalledDialogOpen = false;
    if (!mounted || retry == null) return;
    final controller = ref.read(gameControllerProvider(pc).notifier);
    if (retry) {
      controller.retryValidation();
    } else {
      await controller.cancelValidation();
      if (mounted) _clearToast();
    }
  }

  /// Resolver con el servidor: espera la respuesta. Sin conexión el caso queda
  /// "por validar" (el aviso lo pone [_syncValidation]).
  Future<void> _resolveOnline() async {
    final state = ref.read(gameControllerProvider(pc));
    if (state.validationStalled) {
      unawaited(_askStalled());
      return;
    }
    if (state.pendingValidation) {
      _showToast(context.l10n.validationPending, persistent: true);
      return;
    }
    final fb = await _interaction.solveOnline();
    if (!mounted) return;
    switch (fb) {
      case ActionFeedback.rateLimited:
        _showToast(
          context.l10n.validationRateLimited,
          duration: const Duration(milliseconds: 3500),
        );
      case ActionFeedback.validationFailed:
        _showToast(
          context.l10n.validationRejected,
          duration: const Duration(milliseconds: 3500),
        );
      case ActionFeedback.wrongLimit:
        _showToast(
          context.l10n.validationWrongLimit,
          duration: const Duration(milliseconds: 4500),
        );
      case ActionFeedback.emailUnverified:
        _showToast(
          context.l10n.validationEmailUnverified,
          duration: const Duration(milliseconds: 4500),
        );
      case ActionFeedback.registrationRequired:
        unawaited(showRegistrationInvite(context));
      default:
        _afterResolve(fb);
    }
  }

  /// Termina la secuencia de resolver: se guarda la medición de FPS y, tras
  /// una pausa para ver "El asesino es...", se abre el resumen.
  void _onRevealFinished() {
    _fallbackTimer?.cancel();
    if (!mounted || _summaryShown) return;
    final fps = _fps;
    if (fps != null) {
      final r = fps.stopRecording();
      if (r != null) {
        if (ref.read(devToolsProvider) && ref.read(settingsProvider).fpsMeter) {
          showFpsReport(context, r);
        }
      }
    }
    _summaryTimer?.cancel();
    _summaryTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_summaryShown) _showSummary();
    });
  }

  Future<void> _showSummary() async {
    if (!mounted) return;
    _summaryShown = true;
    _fallbackTimer?.cancel();
    _summaryTimer?.cancel();
    final state = ref.read(gameControllerProvider(pc));
    final Future<bool> summary = tutorial
        ? showTutorialEnd(context, pc, state)
        : showVictoryScreen(context, ref, pc);
    final look = await summary;
    if (look && mounted) _startReview();
  }

  /// "Seguir mirando el tablero": la cámara vuelve a la vista normal y se
  /// muestra la solución completa, solo para mirar (pistas, Mapa y Notas).
  void _startReview() {
    _game.restoreNormalView();
    ref.read(gameControllerProvider(pc).notifier).startReview();
  }

  void _selectSuspect(String id) => _interaction.selectSuspect(id);

  void _openClue() {
    final id = ref.read(gameControllerProvider(pc)).selectedChar;
    final clue = id == null ? null : pc.clueFor(id);
    if (id == null || clue == null) return;
    showFullClueSheet(context, pc, id, pc.clues.indexOf(clue));
  }

  // ---- pantalla ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final paused = ref.watch(
      gameControllerProvider(pc).select((s) => s.paused && !s.solved),
    );
    final loading = ref.watch(
      gameControllerProvider(pc).select((s) => s.loading),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: PaperFibers()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, box) =>
                    _layout(context, box, paused: paused, loading: loading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: ScreenMetrics.sidePad),
    child: child,
  );

  Widget _layout(
    BuildContext context,
    BoxConstraints box, {
    required bool paused,
    required bool loading,
  }) {
    final coach = tutorial ? kTutorialCoachHeight + 6 : 0.0;
    final m = ScreenMetrics.of(
      Size(box.maxWidth, box.maxHeight - coach),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final lower = Column(
      children: [
        if (tutorial) ...[
          _pad(TutorialCoach(pc: pc)),
          const SizedBox(height: 6),
        ],
        // El tablero ocupa todo el ancho, sin márgenes de página.
        SizedBox(
          width: double.infinity,
          height: m.stageHeight,
          child: _wrapSpot(
            TutorialTarget.board,
            _BoardStage(
              game: _game,
              toast: _toast,
              live: _live,
              onSkip: _game.skipReveal,
              onTouch: _onBoardTouch,
              // Lectores de pantalla: una descripción por casilla (H-56).
              semanticsLayer: BoardSemanticsLayer(
                pc: pc,
                onTapCell: _interaction.tapCell,
                onHoldCell: _interaction.holdCell,
              ),
            ),
            radius: 6,
          ),
        ),
        SizedBox(height: m.gap),
        Expanded(child: _pad(_bottom(m))),
      ],
    );

    return Column(
      children: [
        SizedBox(
          height: m.compact
              ? ScreenMetrics.headerTopCompact
              : ScreenMetrics.headerTopNormal,
        ),
        _pad(_topBar()),
        SizedBox(height: m.compact ? 0 : ScreenMetrics.headerGapNormal),
        _pad(_titleRow(m)),
        SizedBox(
          height: m.compact
              ? ScreenMetrics.headerGapCompact
              : ScreenMetrics.gapNormal,
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: lower),
              // Partida en pausa (app en segundo plano): tapa el tablero y las
              // pistas hasta que el jugador toque Continuar (regla 10).
              if (paused)
                Positioned.fill(
                  child: _PausedCover(
                    onContinue: ref
                        .read(gameControllerProvider(pc).notifier)
                        .resume,
                  ),
                ),
              if (loading)
                Positioned.fill(
                  child: ColoredBox(
                    color: context.pal.bg,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Marco de la guía alrededor de un elemento (solo en el tutorial).
  Widget _wrapSpot(TutorialTarget t, Widget child, {double radius = 18}) =>
      tutorial
      ? TutorialSpot(pc: pc, target: t, radius: radius, child: child)
      : child;

  // ---- barra superior ------------------------------------------------------------

  Widget _topBar() {
    return Row(
      children: [
        IconSquare(
          icon: Icons.arrow_back,
          label: context.l10n.gameToolbarBack,
          onTap: _requestExit,
        ),
        const Spacer(),
        // Solo esta pastilla se redibuja cada segundo.
        Consumer(
          builder: (context, ref, _) {
            final secs = ref.watch(
              gameControllerProvider(pc).select((s) => s.elapsedSeconds),
            );
            // El medidor solo existe con ENX_DEV, aunque quede guardado.
            final fpsOn =
                ref.watch(devToolsProvider) &&
                ref.watch(settingsProvider.select((s) => s.fpsMeter));
            if (fpsOn) _fps ??= FpsMonitor();
            return TimerPill(
              seconds: secs,
              subline: fpsOn ? FpsReadout(monitor: _fps!) : null,
            );
          },
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, _) {
            final canUndo = ref.watch(
              gameControllerProvider(pc).select((s) => s.canUndo && !s.solved),
            );
            return IconSquare(
              icon: Icons.undo,
              label: context.l10n.gameToolbarUndo,
              onTap: canUndo
                  ? ref.read(gameControllerProvider(pc).notifier).undo
                  : null,
            );
          },
        ),
        const SizedBox(width: 4),
        _wrapSpot(
          TutorialTarget.menu,
          IconSquare(
            icon: Icons.more_vert,
            label: context.l10n.gameToolbarMenu,
            onTap: () => showGameMenu(context, pc),
          ),
          radius: 16,
        ),
      ],
    );
  }

  Widget _titleRow(ScreenMetrics m) {
    final p = context.pal;
    final h = m.titleRowHeight;
    final size = pc.map.size;
    return SizedBox(
      height: h,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutorial
                      ? context.l10n.gameScreenTutorialHeading(caseTitle(pc))
                      : caseTitle(pc),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final errors = ref.watch(
                      gameControllerProvider(pc).select((s) => s.errorCount),
                    );
                    final difficulty = difficultyName(
                      context.l10n,
                      pc.difficulty,
                    );
                    final head = tutorial
                        ? context.l10n.gameScreenPracticeHead(size)
                        : pc.hasWeapon
                        ? context.l10n.gameScreenCaseHeadWeapon(
                            difficulty,
                            size,
                          )
                        : context.l10n.gameScreenCaseHead(difficulty, size);
                    return Text(
                      context.l10n.gameScreenStatusLine(head, errors),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        color: p.textDim,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Regla 11: Saltar siempre visible (también en pausa o cargando).
          if (tutorial)
            Consumer(
              builder: (context, ref, _) {
                final solved = ref.watch(
                  gameControllerProvider(pc).select((s) => s.solved),
                );
                if (solved) return const SizedBox.shrink();
                return ChromeButton(
                  key: const ValueKey('guia-saltar'),
                  onTap: () => leaveTutorial(context),
                  radius: 14,
                  minSize: Size(64, h),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  semanticsLabel: context.l10n.gameScreenSkip,
                  child: Text(
                    context.l10n.gameScreenSkip,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---- parte de abajo: herramientas, retratos, pista y Resolver --------------------

  Widget _bottom(ScreenMetrics m) {
    return Consumer(
      builder: (context, ref, _) {
        // Nada de esto depende del reloj: solo se reconstruye si cambia la
        // herramienta, el sospechoso, el tablero o las marcas de las pistas.
        final v = ref.watch(
          gameControllerProvider(pc).select(
            (s) => (
              s.toolMode,
              s.selectedChar,
              s.board,
              s.clueMarks,
              s.solved,
              s.paused,
              s.loading,
              s.reviewing,
            ),
          ),
        );
        final (
          toolMode,
          selected,
          board,
          clueMarks,
          solved,
          paused,
          loading,
          reviewing,
        ) = v;
        final controller = ref.read(gameControllerProvider(pc).notifier);
        final enabled = !paused && !loading && !solved;
        // Mirando el tablero resuelto los retratos siguen sirviendo para leer
        // las pistas, pero las herramientas quedan apagadas.
        final panelEnabled = enabled || (solved && reviewing && !paused);

        final placed = <String>{
          for (final c in board.confirmedCells) board.cell(c).confirmed!,
        };
        final clue = selected == null ? null : pc.clueFor(selected);
        final clueIndex = clue == null ? -1 : pc.clues.indexOf(clue);
        final mark = clueIndex >= 0 ? clueMarks[clueIndex] : ClueMark.normal;

        final toolbar = ToolBar(
          mode: toolMode,
          height: m.toolbarHeight,
          enabled: enabled,
          onSelect: controller.setToolMode,
          wrap: tutorial
              ? (mode, button) => TutorialSpot(
                  pc: pc,
                  target: switch (mode) {
                    ToolMode.notes => TutorialTarget.toolNotes,
                    ToolMode.cross => TutorialTarget.toolCross,
                    ToolMode.place => TutorialTarget.toolPlace,
                    ToolMode.erase => TutorialTarget.toolErase,
                  },
                  child: button,
                )
              : null,
        );

        final resolve = _wrapSpot(
          TutorialTarget.resolve,
          ResolveBar(
            solved: solved,
            onResolve: _resolve,
            onSummary: _showSummary,
            height: m.compact
                ? ScreenMetrics.resolveCompact
                : ScreenMetrics.resolveNormal,
            fill: !m.compact,
          ),
          radius: 20,
        );

        Widget panel({Widget? trailing}) => SuspectPanel(
          pc: pc,
          skin: _skin,
          pulse: _trayPulse,
          selectedChar: selected,
          placed: placed,
          enabled: panelEnabled,
          onSelect: _selectSuspect,
          clueMark: mark,
          onCycleClue: () {
            if (clueIndex >= 0) controller.cycleClue(clueIndex);
          },
          onOpenClue: _openClue,
          compact: m.compact,
          trailing: trailing,
          // La guía del tutorial señala solo los retratos.
          wrapPortraits: tutorial
              ? (w) => _wrapSpot(TutorialTarget.portraits, w, radius: 14)
              : null,
        );

        if (m.compact) {
          // Pantallas bajas: la pista en una línea y Resolver a su lado.
          return Column(
            children: [
              toolbar,
              SizedBox(height: m.gap),
              panel(trailing: resolve),
            ],
          );
        }
        return Column(
          children: [
            toolbar,
            SizedBox(height: m.gap),
            panel(),
            const Spacer(),
            resolve,
            SizedBox(height: m.gap),
          ],
        );
      },
    );
  }

  /// Para pruebas: la escena de Flame de esta partida.
  @visibleForTesting
  BoardGame get debugGame => _game;
}

/// El escenario: escena de Flame, aviso corto y botón para saltar la
/// secuencia de resolver. No depende del reloj ni del estado de la partida,
/// así que los segundos no lo reconstruyen.
class _BoardStage extends StatelessWidget {
  const _BoardStage({
    required this.game,
    required this.toast,
    required this.live,
    required this.onSkip,
    this.onTouch,
    this.semanticsLayer,
  });

  /// Capa invisible con la semántica de cada casilla.
  final Widget? semanticsLayer;

  final BoardGame game;
  final ValueNotifier<String?> toast;
  final ValueNotifier<String?> live;
  final VoidCallback onSkip;

  /// Se llama en cada toque sobre el tablero (aviso del bloqueo de 3 s).
  final VoidCallback? onTouch;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              onTouch?.call();
              game.pointerDown(e.pointer, e.localPosition);
            },
            onPointerMove: (e) => game.pointerMove(e.pointer, e.localPosition),
            onPointerUp: (e) => game.pointerUp(e.pointer, e.localPosition),
            onPointerCancel: (e) => game.pointerCancel(e.pointer),
            child: GameWidget(key: const ValueKey('tablero'), game: game),
          ),
          if (semanticsLayer != null) Positioned.fill(child: semanticsLayer!),
          // Aviso corto ("Elige primero a un sospechoso").
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: IgnorePointer(
              child: ValueListenableBuilder<String?>(
                valueListenable: toast,
                builder: (context, text, _) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: text == null ? 0 : 1,
                  child: Center(
                    child: ChromeBox(
                      color: p.pill,
                      radius: 20,
                      depth: 2.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      child: Text(
                        text ?? '',
                        key: const ValueKey('aviso'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: p.onPill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Los avisos del tablero también los leen los lectores de pantalla.
          Positioned(
            left: 0,
            top: 0,
            child: ValueListenableBuilder<String?>(
              valueListenable: live,
              builder: (context, text, _) => Semantics(
                liveRegion: true,
                label: text ?? '',
                child: const SizedBox(width: 1, height: 1),
              ),
            ),
          ),
          // Saltar la secuencia de resolver (disponible tras 1 s).
          Positioned(
            right: 10,
            bottom: 10,
            child: ValueListenableBuilder<RevealPhase>(
              valueListenable: game.revealPhase,
              builder: (context, phase, _) =>
                  phase == RevealPhase.runningCanSkip
                  ? ChromeButton(
                      key: const ValueKey('saltar-secuencia'),
                      onTap: onSkip,
                      color: p.accent,
                      radius: 18,
                      semanticsLabel: context.l10n.gameScreenSkip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward, color: p.onAccent),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.gameScreenSkip,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: p.onAccent,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que tapa todo mientras la partida está en pausa.
class _PausedCover extends StatelessWidget {
  final VoidCallback onContinue;
  const _PausedCover({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ColoredBox(
      color: p.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ChromeBox(
              color: p.surface,
              radius: 20,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle_outline, size: 56, color: p.accent),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.gameScreenPaused,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.gameScreenPausedBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.4, color: p.text),
                  ),
                  const SizedBox(height: 20),
                  ChromeButton(
                    key: const ValueKey('continuar'),
                    onTap: onContinue,
                    color: p.accent,
                    radius: 20,
                    minSize: const Size(200, 52),
                    semanticsLabel: context.l10n.gameScreenResume,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: p.onAccent),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.gameScreenResume,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

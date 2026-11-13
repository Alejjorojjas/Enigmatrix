/// Pantallas del reto diario y del ranking reales (ronda F2b). Solo se usan
/// con el servidor activo; con el modo `none` quedan las pantallas de siempre.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../backend/validation_client.dart';
import '../data/case_repository.dart';
import '../ui/skin_theme.dart';
import '../ui/ui_kit.dart';
import '../ui/v1_scope.dart';
import 'daily_logic.dart';
import 'daily_providers.dart';

int get _penaltySeconds => kDefaultErrorPenaltyMs ~/ 1000;

/// Empieza (o retoma) el reto de hoy: a un invitado lo invita a registrarse;
/// si es la primera vez avisa que el reloj no se detiene y pide confirmar.
Future<void> playDailyChallenge(
  BuildContext context,
  WidgetRef ref,
  DailyTabState state,
) async {
  if (state.guest) {
    ref.read(onRegistrationRequestedProvider)(context);
    return;
  }
  if (state.solved) return;
  if (!state.startedToday) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.dailyWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.dailyClockWarning,
              key: const ValueKey('aviso-reloj-dialogo'),
              style: ctx.body(16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(ctx.l10n.dailyPenaltyNote(_penaltySeconds)),
            if (!state.ranked) ...[
              const SizedBox(height: 8),
              Text(ctx.l10n.dailyOfflineNote),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.dailyWarningStay),
          ),
          TextButton(
            key: const ValueKey('aviso-reloj-empezar'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.dailyWarningGo),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  context.go('/play/${state.caseId}');
}

/// Abre el ranking del día a pantalla completa (desde la victoria).
Future<void> showRankingDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog.fullscreen(
    backgroundColor: ctx.pal.bg,
    child: ScreenBackground(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.l10n.rankingClose),
              ),
            ),
            const Expanded(child: ServerRankingTab()),
          ],
        ),
      ),
    ),
  ),
);

// ---------- RETO ----------

class ServerChallengeTab extends ConsumerStatefulWidget {
  const ServerChallengeTab({super.key});

  @override
  ConsumerState<ServerChallengeTab> createState() => _ServerChallengeTabState();
}

class _ServerChallengeTabState extends ConsumerState<ServerChallengeTab> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Cada segundo se redibuja el tiempo del reto en curso.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = ref.read(dailyTabProvider).valueOrNull;
      if (mounted && s != null && s.startedAtMs != null && !s.solved) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyTabProvider);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(title: context.l10n.homeChallengeTab),
        async.when(
          loading: () => AppCard(
            child: Text(
              context.l10n.dailyLoading,
              key: const ValueKey('reto-cargando'),
              style: context.note(18),
            ),
          ),
          error: (_, __) => _LoadError(
            text: context.l10n.dailyLoadError,
            onRetry: () => ref.invalidate(dailyTabProvider),
          ),
          data: (s) => _body(context, s),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, DailyTabState s) {
    final p = context.pal;
    if (s.guest) {
      return AppCard(
        key: const ValueKey('reto-invitado'),
        accent: p.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.dailyGuestTitle, style: context.display(20)),
            const SizedBox(height: 8),
            Text(
              context.l10n.dailyGuestBody,
              style: context.body(15, color: p.softText),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: context.l10n.dailyGuestButton,
              color: p.danger,
              onTap: () => ref.read(onRegistrationRequestedProvider)(context),
            ),
          ],
        ),
      );
    }
    final challenges = ref.watch(dailyChallengesProvider).valueOrNull;
    final today = challenges
        ?.where((c) => c.puzzle.caseId == s.caseId)
        .firstOrNull;
    final r = s.result;
    final inProgress = !s.solved && s.startedToday;
    final elapsed = s.startedAtMs == null
        ? null
        : elapsedSince(
            s.startedAtMs!,
            ref.read(dailyClockProvider)().millisecondsSinceEpoch,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.connection == DailyConnection.offline)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NoticeBox(context.l10n.dailyOfflineNote),
          ),
        if (s.connection == DailyConnection.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NoticeBox(
              s.errorMessage ?? context.l10n.dailyServerErrorNote,
            ),
          ),
        AppCard(
          accent: p.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(context.l10n.homeTodayCase),
              const SizedBox(height: 6),
              if (today != null)
                Text(
                  context.l10n.challengeTodaySummary(
                    today.day,
                    kDailyCycleDays,
                    difficultyName(context.l10n, today.puzzle.difficulty),
                    today.puzzle.map.size,
                  ),
                  style: context.body(15),
                ),
              const SizedBox(height: 4),
              if (r != null) ...[
                Text(
                  context.l10n.dailySolvedTitle,
                  key: const ValueKey('reto-resuelto'),
                  style: context.display(22, color: p.good),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: formatElapsedMs(r.serverElapsedMs),
                        label: context.l10n.victoryTime,
                        icon: Icons.timer_outlined,
                        color: p.world(0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: '${r.errors}',
                        label: context.l10n.victoryErrors,
                        icon: r.errors == 0
                            ? Icons.verified_outlined
                            : Icons.close_rounded,
                        color: r.errors == 0 ? p.good : p.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: formatElapsedMs(r.score),
                        label: context.l10n.dailyScoreLabel,
                        icon: Icons.stars_rounded,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: r.rank == null
                            ? context.l10n.dailyNoRankShort
                            : '#${r.rank}',
                        label: context.l10n.dailyRankLabel,
                        icon: Icons.emoji_events_rounded,
                        color: p.medal(0),
                      ),
                    ),
                  ],
                ),
                if (r.rank == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      context.l10n.dailyNoRank,
                      style: context.note(15, color: p.softText),
                    ),
                  ),
                const SizedBox(height: 14),
                AppButton(
                  label: context.l10n.dailySeeRanking,
                  color: p.danger,
                  onTap: () => showRankingDialog(context),
                ),
              ] else ...[
                if (inProgress) ...[
                  Text(
                    context.l10n.dailyInProgress,
                    key: const ValueKey('reto-en-curso'),
                    style: context.display(20),
                  ),
                  if (elapsed != null)
                    Text(
                      context.l10n.dailyElapsedLine(formatElapsedMs(elapsed)),
                      key: const ValueKey('reto-tiempo'),
                      style: context.display(26, color: p.danger),
                    ),
                  const SizedBox(height: 6),
                ],
                Text(
                  context.l10n.dailyClockWarning,
                  key: const ValueKey('reto-aviso-reloj'),
                  style: context.body(15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.dailyPenaltyNote(_penaltySeconds),
                  style: context.note(15, color: p.softText),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: inProgress
                      ? context.l10n.dailyContinueButton
                      : context.l10n.dailyStartButton,
                  color: p.danger,
                  onTap: today == null
                      ? null
                      : () => playDailyChallenge(context, ref, s),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey('carga-error'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: context.body(15, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        AppButton(label: context.l10n.dailyRetry, onTap: onRetry),
      ],
    ),
  );
}

// ---------- RANKING ----------

class ServerRankingTab extends ConsumerWidget {
  const ServerRankingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDate = formatLocalDate(ref.watch(dailyClockProvider)());
    final async = ref.watch(dailyRankingProvider);
    final guest = ref.watch(
      dailyTabProvider.select((v) => v.valueOrNull?.guest ?? false),
    );
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyRankingProvider);
        try {
          await ref.read(dailyRankingProvider.future);
        } on Object {
          // el error se ve en la pantalla
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          PageHeader(
            title: context.l10n.homeRanking,
            subtitle: context.l10n.rankingTodaySub(displayDate(localDate)),
          ),
          async.when(
            loading: () => AppCard(
              child: Text(
                context.l10n.dailyLoading,
                key: const ValueKey('ranking-cargando'),
                style: context.note(18),
              ),
            ),
            error: (e, _) {
              final unavailable =
                  e is ValidationException &&
                  e.kind == ValidationFailure.serverError &&
                  e.detail == 'sin-fuente-de-ranking';
              return _LoadError(
                text: unavailable
                    ? context.l10n.rankingUnavailable
                    : context.l10n.rankingLoadError,
                onRetry: () => ref.invalidate(dailyRankingProvider),
              );
            },
            data: (d) => _rows(context, d, guest),
          ),
        ],
      ),
    );
  }

  Widget _rows(BuildContext context, RankingData d, bool guest) {
    final p = context.pal;
    if (d.isEmpty) {
      return Column(
        children: [
          AppCard(
            key: const ValueKey('ranking-vacio'),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: p.medal(0), size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.rankingEmpty,
                    style: context.body(16, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (guest) NoticeBox(context.l10n.rankingGuestNote),
        ],
      );
    }
    final own = d.ownOutsideTop;
    return Column(
      children: [
        for (final (i, e) in d.top.indexed)
          RankingRow(place: i + 1, entry: e, mine: e.uid == d.ownUid),
        if (own != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel(context.l10n.rankingYourPlace),
            ),
          ),
          RankingRow(place: d.ownRank, entry: own, mine: true),
        ],
        if (guest) NoticeBox(context.l10n.rankingGuestNote),
        const SizedBox(height: 8),
        Text(
          context.l10n.rankingPenaltyNote(_penaltySeconds),
          textAlign: TextAlign.center,
          style: context.note(14, color: p.softText),
        ),
      ],
    );
  }
}

/// Una fila: puesto, apodo, tiempo, errores y total con penalización. La fila
/// propia va resaltada (borde de color y la etiqueta "Tú", no solo color).
class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.place,
    required this.entry,
    required this.mine,
  });

  /// Puesto (null si no se conoce).
  final int? place;
  final RankingEntry entry;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final top3 = place != null && place! <= 3;
    final detail = context.l10n.rankingRowDetail(
      formatElapsedMs(entry.serverElapsedMs),
      entry.errors,
      formatElapsedMs(entry.score),
    );
    return AppCard(
      key: ValueKey('ranking-fila-${entry.uid}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      accent: mine ? p.world(0) : (top3 ? p.medal(place! - 1) : null),
      color: mine ? p.surfaceAlt : null,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: top3
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: p.medal(place! - 1),
                    size: 28,
                  )
                : Text(
                    place == null ? '–' : '$place',
                    style: context.display(18, color: p.softText),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.body(
                          16,
                          weight: mine ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${context.l10n.rankingYouTag})',
                        style: context.body(
                          14,
                          weight: FontWeight.w800,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  detail,
                  style: context.body(
                    13,
                    weight: FontWeight.w600,
                    color: p.softText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(formatElapsedMs(entry.score), style: context.display(17)),
        ],
      ),
    );
  }
}

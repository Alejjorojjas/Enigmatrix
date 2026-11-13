/// Las cinco pestañas del shell: Inicio, Mundos, Reto, Ranking y Perfil. Todo
/// el color y la tipografía salen de la piel y el modo activos. Vidas, racha,
/// puntos y ranking son simulados (DEMO). Experto, Élite y los mundos que
/// aún no existen se muestran "Próximamente" y no se pueden abrir (ADR-0014).
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../backend/backend_config.dart';
import '../backend/validation_client.dart' show formatLocalDate;
import '../backend/validation_providers.dart';
import '../daily/daily_logic.dart';
import '../daily/daily_providers.dart';
import '../daily/daily_screens.dart';
import '../data/case_repository.dart';
import '../game/dev_tools.dart' show showSimulatedProvider;
import '../game/game_config.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'game_chrome.dart';
import 'home_sheets.dart';
import 'logo.dart';
import 'mock_data.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

/// Cuántos de [cases] están cerrados según lo guardado.
int solvedIn(List<PuzzleCase> cases, SharedPreferences? prefs) =>
    cases.where((c) => prefs?.getString('done:${c.caseId}') != null).length;

/// Los casos del Mundo 1 en el orden de la campaña (vacío mientras cargan).
List<PuzzleCase> worldCases(WidgetRef ref) =>
    ref.watch(campaignProvider(kMundoMansion)).valueOrNull ?? const [];

/// El reto de hoy (null si aún carga o ese día no existe). Con el servidor
/// activo manda su fórmula (inicio 16-11-2026, ciclo de 30 días).
DailyChallenge? todaysChallengeOf(WidgetRef ref) {
  final all = ref.watch(dailyChallengesProvider).valueOrNull ?? const [];
  if (ref.watch(backendModeProvider).usesServer) {
    final config = ref.watch(gameConfigProvider);
    final id = dailyCaseIdForLocalDate(
      formatLocalDate(ref.watch(dailyClockProvider)()),
      startDate: config.challengeStartDate,
      cycleDays: config.challengeDays,
    );
    return all.where((c) => c.puzzle.caseId == id).firstOrNull;
  }
  return todaysChallenge(
    all,
    DateTime.now(),
    config: ref.watch(gameConfigProvider),
  );
}

Future<void> _playToday(
  BuildContext context,
  WidgetRef ref,
  DailyChallenge? today,
) async {
  if (today == null) return;
  if (ref.read(backendModeProvider).usesServer) {
    // Con servidor: aviso del reloj, invitación a registrarse y reto oficial.
    final state = await ref.read(dailyTabProvider.future);
    if (!context.mounted) return;
    return playDailyChallenge(context, ref, state);
  }
  context.go('/play/${today.puzzle.caseId}');
}

/// Estado del reto de hoy según lo guardado: sin iniciar, en curso o
/// resuelto (las claves `done:` y `game:` más el id del caso).
String challengeStateText(
  AppLocalizations l10n,
  PuzzleCase pc,
  SharedPreferences? prefs, {
  bool pendingValidation = false,
}) {
  if (prefs?.getString('done:${pc.caseId}') != null) {
    return l10n.homeStateDone;
  }
  if (pendingValidation) return l10n.validationPendingTag;
  if (prefs?.getString('game:${pc.caseId}') != null) {
    return l10n.homeStateOpen;
  }
  return l10n.homeStateNew;
}

// ---------- INICIO ----------

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    // Una respuesta tardía del servidor cambia lo resuelto: se relee.
    ref.watch(pendingCaseIdsProvider);
    final playable = worldCases(ref);
    final solved = solvedIn(playable, prefs);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? context.l10n.homeGreetingMorning
        : hour < 19
        ? context.l10n.homeGreetingAfternoon
        : context.l10n.homeGreetingEvening;
    final today = todaysChallengeOf(ref);
    // Vidas, racha y Tienda son simulados (pregunta 18).
    final showSim = ref.watch(showSimulatedProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const PaperLogo(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: context.note(17, color: p.softText)),
                  Text(context.l10n.homeDetective, style: context.display(26)),
                ],
              ),
            ),
            if (showSim) const _LivesChip(),
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          accent: p.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SectionLabel(
                      context.l10n.homeChallengeLabel,
                      color: p.danger,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  if (showSim) ...[const SizedBox(width: 8), const DemoBadge()],
                ],
              ),
              const SizedBox(height: 8),
              Text(context.l10n.homeChallengeTitle, style: context.display(20)),
              if (showSim)
                Text(
                  context.l10n.homeStreakLine(mockStreak),
                  style: context.note(15, color: p.softText),
                ),
              if (today != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.speed_rounded,
                      text: difficultyName(
                        context.l10n,
                        today.puzzle.difficulty,
                      ),
                      color: p.difficulty(today.puzzle.difficulty),
                    ),
                    InfoChip(
                      icon: Icons.grid_on_rounded,
                      text: '${today.puzzle.map.size}×${today.puzzle.map.size}',
                    ),
                    InfoChip(
                      icon: Icons.event_rounded,
                      text: context.l10n.challengeDayOf(
                        today.day,
                        ref.watch(gameConfigProvider).challengeDays,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              AppButton(
                label: context.l10n.homePlayChallenge,
                color: p.danger,
                onTap: today == null
                    ? null
                    : () => _playToday(context, ref, today),
              ),
            ],
          ),
        ),
        AppCard(
          accent: p.good,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(
                context.l10n.homeWorldLabel,
                color: p.good,
                icon: Icons.map_rounded,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.homeSolvedCount(solved, playable.length),
                style: context.display(20),
              ),
              const SizedBox(height: 10),
              AppProgressBar(
                value: playable.isEmpty ? 0 : solved / playable.length,
                color: p.good,
                height: 14,
                semanticsLabel: context.l10n.homeWorldProgress,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: context.l10n.homeKeepInvestigating,
                onTap: () => context.go('/casos'),
              ),
            ],
          ),
        ),
        if (showSim)
          AppCard(
            child: Row(
              children: [
                IconTile(
                  icon: Icons.storefront_rounded,
                  color: p.world(2),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap: con el texto del sistema grande la etiqueta DEMO
                      // baja a otra línea en vez de desbordar.
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            context.l10n.homeShop,
                            style: context.body(
                              14,
                              weight: FontWeight.w800,
                              spacing: 1.4,
                            ),
                          ),
                          const DemoBadge(),
                        ],
                      ),
                      Text(
                        context.l10n.homeShopSub,
                        style: context.note(15, color: p.softText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: context.l10n.homeSee,
                  expand: false,
                  onTap: () => openShopSheet(context),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Vidas simuladas, arriba a la derecha del Inicio.
class _LivesChip extends ConsumerWidget {
  const _LivesChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, color: p.danger, size: 22),
            const SizedBox(width: 4),
            Text(
              '$mockLives/${ref.watch(gameConfigProvider).maxLives}',
              style: context.body(16),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.homeNextLife(mockNextLife),
              style: context.body(
                13,
                weight: FontWeight.w600,
                color: p.softText,
              ),
            ),
            const SizedBox(width: 5),
            const DemoBadge(),
          ],
        ),
      ],
    );
  }
}

// ---------- MUNDOS ----------

IconData _worldIcon(String id) => switch (id) {
  'mansion' => Icons.villa_rounded,
  'hotel' => Icons.hotel_rounded,
  'museo' => Icons.account_balance_rounded,
  'tren' => Icons.train_rounded,
  'hospital' => Icons.local_hospital_rounded,
  _ => Icons.map_rounded,
};

class WorldsTab extends ConsumerWidget {
  const WorldsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    // Una respuesta tardía del servidor cambia lo resuelto: se relee.
    ref.watch(pendingCaseIdsProvider);
    final playable = worldCases(ref);
    final solved = solvedIn(playable, prefs);
    final worlds = worldsFor(ref.watch(gameConfigProvider), context.l10n);
    final open = worlds.where((w) => w.available).length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(
          title: context.l10n.homeWorlds,
          subtitle: context.l10n.worldsAvailable(open, worlds.length),
        ),
        for (final (i, w) in worlds.indexed)
          Opacity(
            opacity: w.available ? 1 : 0.62,
            child: AppCard(
              accent: w.available ? p.world(i) : null,
              semanticsLabel: w.available
                  ? context.l10n.worldsEnter(w.name)
                  : null,
              onTap: w.available ? () => context.go('/casos') : null,
              child: Row(
                children: [
                  IconTile(
                    icon: w.available ? _worldIcon(w.id) : Icons.lock_rounded,
                    color: w.available ? p.world(i) : p.surfaceAlt,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: context.display(20)),
                        const SizedBox(height: 2),
                        if (w.available) ...[
                          Text(
                            context.l10n.homeSolvedCount(
                              solved,
                              playable.length,
                            ),
                            style: context.body(
                              14,
                              weight: FontWeight.w600,
                              color: p.softText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppProgressBar(
                            value: playable.isEmpty
                                ? 0
                                : solved / playable.length,
                            color: p.world(i),
                            semanticsLabel: context.l10n.worldsProgress(w.name),
                          ),
                        ] else
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SoonBadge(),
                          ),
                      ],
                    ),
                  ),
                  if (w.available) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: p.textDim,
                      size: 30,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- RETO DIARIO ----------

class ChallengeTab extends ConsumerWidget {
  const ChallengeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con servidor: reto oficial con ranking (ronda F2b).
    if (ref.watch(backendModeProvider).usesServer) {
      return const ServerChallengeTab();
    }
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final today = todaysChallengeOf(ref);
    final showSim = ref.watch(showSimulatedProvider);
    final days = [
      (context.l10n.challengeWeekdayMon, true),
      (context.l10n.challengeWeekdayTue, true),
      (context.l10n.challengeWeekdayWed, true),
      (context.l10n.challengeWeekdayThu, false),
      (context.l10n.challengeWeekdayFri, false),
      (context.l10n.challengeWeekdaySat, false),
      (context.l10n.challengeWeekdaySun, false),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(title: context.l10n.homeChallengeTab),
        if (showSim)
          AppCard(
            accent: p.danger,
            child: Column(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 52,
                  color: p.danger,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      context.l10n.challengeStreakTitle(mockStreak),
                      style: context.display(26),
                    ),
                    const DemoBadge(),
                  ],
                ),
                Text(
                  context.l10n.challengeBestStreak(
                    mockBestStreak,
                    mockProtectors,
                  ),
                  textAlign: TextAlign.center,
                  style: context.note(16, color: p.softText),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (d, done) in days)
                      Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: done ? p.danger : p.surfaceAlt,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.line, width: 1.5),
                        ),
                        child: Center(
                          child: done
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: p.onColor(p.danger),
                                )
                              : Text(
                                  d,
                                  style: context.body(13, color: p.textDim),
                                ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(context.l10n.homeTodayCase),
              const SizedBox(height: 6),
              if (today != null) ...[
                Text(
                  context.l10n.challengeTodaySummary(
                    today.day,
                    ref.watch(gameConfigProvider).challengeDays,
                    difficultyName(context.l10n, today.puzzle.difficulty),
                    today.puzzle.map.size,
                  ),
                  style: context.body(15, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  challengeStateText(
                    context.l10n,
                    today.puzzle,
                    prefs,
                    pendingValidation: ref
                        .watch(pendingCaseIdsProvider)
                        .contains(today.puzzle.caseId),
                  ),
                  style: context.note(18, color: p.text),
                ),
              ] else
                Text(
                  context.l10n.homeNoChallenge,
                  style: context.note(18, color: p.text),
                ),
              Text(
                context.l10n.homeChallengeNote,
                style: context.note(15, color: p.softText),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: context.l10n.homePlayToday,
                color: p.danger,
                onTap: today == null
                    ? null
                    : () => _playToday(context, ref, today),
              ),
            ],
          ),
        ),
        if (showSim)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: SectionLabel(context.l10n.homeWeekPoints)),
                    const SizedBox(width: 8),
                    const DemoBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.pointsShort(mockWeeklyPoints),
                  style: context.display(24),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------- RANKING ----------

class RankingTab extends ConsumerWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con servidor: ranking real del día (ronda F2b).
    if (ref.watch(backendModeProvider).usesServer) {
      return const ServerRankingTab();
    }
    final p = context.pal;
    // El jugador entra en el orden real por puntos (datos simulados).
    final rows = <(String, int, String, bool)>[
      for (final b in mockBots) (b.$1, b.$2, b.$3, false),
      (context.l10n.homeYou, mockWeeklyPoints, '🇨🇴', true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(
          title: context.l10n.homeRanking,
          subtitle: context.l10n.homeRankingSub,
          badge: const DemoBadge(),
        ),
        for (final (i, r) in rows.indexed)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            accent: r.$4 ? p.world(0) : (i < 3 ? p.medal(i) : null),
            color: r.$4 ? p.surfaceAlt : null,
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: i < 3
                      ? Icon(
                          Icons.emoji_events_rounded,
                          color: p.medal(i),
                          size: 28,
                        )
                      : Text(
                          '${i + 1}',
                          style: context.display(18, color: p.softText),
                        ),
                ),
                Text(r.$3, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.body(
                      16,
                      weight: r.$4 ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.pointsShort(r.$2),
                  style: context.display(17),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------- PERFIL ----------

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final showSim = ref.watch(showSimulatedProvider);
    // Casos cerrados: los del Mundo 1 y los retos (el banco de pruebas no
    // cuenta).
    final solved = solvedIn([
      ...worldCases(ref),
      for (final c
          in ref.watch(dailyChallengesProvider).valueOrNull ??
              const <DailyChallenge>[])
        c.puzzle,
    ], prefs);
    final nickname =
        prefs?.getString('profile:nick') ?? context.l10n.profileDefaultNick;
    final initial =
        (nickname.isEmpty ? context.l10n.profileDefaultNick : nickname)[0]
            .toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(
          child: Column(
            children: [
              ChromeBox(
                color: p.world(0),
                radius: 48,
                depth: 4,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: Text(
                      initial,
                      style: context.display(44, color: p.onColor(p.world(0))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.display(26),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.profileChangeName,
                    constraints: const BoxConstraints(
                      minWidth: SkinUi.minTouch,
                      minHeight: SkinUi.minTouch,
                    ),
                    icon: Icon(Icons.edit_rounded, size: 22, color: p.softText),
                    onPressed: () => editNickname(context, ref, prefs),
                  ),
                ],
              ),
              // "Detective desde…" es simulado.
              if (showSim)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      context.l10n.profileSince,
                      style: context.note(16, color: p.softText),
                    ),
                    const DemoBadge(),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '$solved',
                label: context.l10n.profileSolvedLabel,
                icon: Icons.folder_special_rounded,
                color: p.good,
              ),
            ),
            if (showSim) ...[
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '$mockStreak',
                  label: context.l10n.profileStreakLabel,
                  icon: Icons.local_fire_department_rounded,
                  color: p.danger,
                  demo: true,
                ),
              ),
            ],
          ],
        ),
        if (showSim) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '$mockBestStreak',
                  label: context.l10n.profileBestStreakLabel,
                  icon: Icons.military_tech_rounded,
                  color: p.medal(0),
                  demo: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '$mockWeeklyPoints',
                  label: context.l10n.profileWeekPointsLabel,
                  icon: Icons.stars_rounded,
                  color: p.accent,
                  demo: true,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              if (showSim) ...[
                _MenuRow(
                  icon: Icons.storefront_rounded,
                  label: context.l10n.profileMenuShop,
                  demo: true,
                  onTap: () => openShopSheet(context),
                ),
                _MenuRow(
                  icon: Icons.workspace_premium_rounded,
                  label: context.l10n.profileMenuPremium,
                  demo: true,
                  onTap: () => openPremiumSheet(context),
                ),
              ],
              _MenuRow(
                icon: Icons.help_outline_rounded,
                label: context.l10n.profileMenuHowToPlay,
                onTap: () => openHowToPlay(context),
              ),
              _MenuRow(
                icon: Icons.settings_rounded,
                label: context.l10n.profileMenuSettings,
                onTap: () => openSettingsSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.demo = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Icon(icon, color: p.accent, size: 26),
            const SizedBox(width: 12),
            Text(label, style: context.body(17)),
            if (demo) ...[const SizedBox(width: 8), const DemoBadge()],
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: p.textDim),
          ],
        ),
      ),
    );
  }
}

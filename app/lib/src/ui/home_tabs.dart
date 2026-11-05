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

import '../data/case_repository.dart';
import '../game/game_config.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'game_chrome.dart';
import 'home_sheets.dart';
import 'logo.dart';
import 'mock_data.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';
import 'v1_scope.dart';

/// Textos de las pestañas (centralizados para traducir en la ronda 4.3).
abstract final class HomeTexts {
  static const challengeLabel = 'RETO DIARIO';
  static const challengeTitle = 'El caso de hoy te espera';
  static const challengeSim = 'Caso del día (simulación: aún sin servidor)';
  static const playChallenge = 'Jugar el reto';
  static const worldLabel = 'MUNDO 1 · LA MANSIÓN';
  static const keepInvestigating = 'Continuar investigando';
  static const shop = 'TIENDA';
  static const shopSub = 'Vidas y protectores de racha';
  static const see = 'Ver';
  static const worlds = 'Mundos';
  static const challengeTab = 'Reto diario';
  static const todayCase = 'EL CASO DE HOY';
  static const challengeNote =
      'Simulación: aún sin servidor, no hay intento oficial ni cierre a '
      'medianoche';
  static const stateNew = 'Estado: no iniciado';
  static const stateOpen = 'Estado: en curso';
  static const stateDone = 'Estado: resuelto';
  static const noChallenge = 'El caso de hoy no está disponible.';
  static const playToday = 'Jugar el caso de hoy';
  static const weekPoints = 'PUNTOS DE LA SEMANA';
  static const ranking = 'Ranking';
  static const rankingSub = 'Semanal · se conecta en el modo online';
  static const you = 'Tú (detective)';
}

/// Cuántos de [cases] están cerrados según lo guardado.
int solvedIn(List<PuzzleCase> cases, SharedPreferences? prefs) =>
    cases.where((c) => prefs?.getString('done:${c.caseId}') != null).length;

/// Los casos del Mundo 1 en el orden de la campaña (vacío mientras cargan).
List<PuzzleCase> worldCases(WidgetRef ref) =>
    ref.watch(campaignProvider(kMundoMansion)).valueOrNull ?? const [];

/// El reto de hoy (null si aún carga o ese día no existe).
DailyChallenge? todaysChallengeOf(WidgetRef ref) => todaysChallenge(
  ref.watch(dailyChallengesProvider).valueOrNull ?? const [],
  DateTime.now(),
  config: ref.watch(gameConfigProvider),
);

void _playToday(BuildContext context, DailyChallenge? today) {
  if (today != null) context.go('/play/${today.puzzle.caseId}');
}

/// Estado del reto de hoy según lo guardado: sin iniciar, en curso o
/// resuelto (las claves `done:` y `game:` más el id del caso).
String challengeStateText(PuzzleCase pc, SharedPreferences? prefs) {
  if (prefs?.getString('done:${pc.caseId}') != null) {
    return HomeTexts.stateDone;
  }
  if (prefs?.getString('game:${pc.caseId}') != null) {
    return HomeTexts.stateOpen;
  }
  return HomeTexts.stateNew;
}

// ---------- INICIO ----------

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final playable = worldCases(ref);
    final solved = solvedIn(playable, prefs);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    final today = todaysChallengeOf(ref);

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
                  Text(
                    '$greeting,',
                    style: context.note(17, color: p.softText),
                  ),
                  Text('detective', style: context.display(26)),
                ],
              ),
            ),
            const _LivesChip(),
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
                      HomeTexts.challengeLabel,
                      color: p.danger,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const DemoBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(HomeTexts.challengeTitle, style: context.display(20)),
              Text(
                'Racha: $mockStreak días · ${HomeTexts.challengeSim}',
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
                      text: difficultyName(today.puzzle.difficulty),
                      color: p.difficulty(today.puzzle.difficulty),
                    ),
                    InfoChip(
                      icon: Icons.grid_on_rounded,
                      text: '${today.puzzle.map.size}×${today.puzzle.map.size}',
                    ),
                    InfoChip(
                      icon: Icons.event_rounded,
                      text:
                          'Día ${today.day} de '
                          '${ref.watch(gameConfigProvider).challengeDays}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              AppButton(
                label: HomeTexts.playChallenge,
                color: p.danger,
                onTap: today == null ? null : () => _playToday(context, today),
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
                HomeTexts.worldLabel,
                color: p.good,
                icon: Icons.map_rounded,
              ),
              const SizedBox(height: 8),
              Text(
                '$solved de ${playable.length} casos cerrados',
                style: context.display(20),
              ),
              const SizedBox(height: 10),
              AppProgressBar(
                value: playable.isEmpty ? 0 : solved / playable.length,
                color: p.good,
                height: 14,
                semanticsLabel: 'Progreso del Mundo 1',
              ),
              const SizedBox(height: 14),
              AppButton(
                label: HomeTexts.keepInvestigating,
                onTap: () => context.go('/casos'),
              ),
            ],
          ),
        ),
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
                          HomeTexts.shop,
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
                      HomeTexts.shopSub,
                      style: context.note(15, color: p.softText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: HomeTexts.see,
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
              '+1 en $mockNextLife',
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
    final playable = worldCases(ref);
    final solved = solvedIn(playable, prefs);
    final worlds = worldsFor(ref.watch(gameConfigProvider));
    final open = worlds.where((w) => w.available).length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(
          title: HomeTexts.worlds,
          subtitle: '$open de ${worlds.length} disponibles',
        ),
        for (final (i, w) in worlds.indexed)
          Opacity(
            opacity: w.available ? 1 : 0.62,
            child: AppCard(
              accent: w.available ? p.world(i) : null,
              semanticsLabel: w.available ? '${w.name}: entrar' : null,
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
                            '$solved de ${playable.length} casos cerrados',
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
                            semanticsLabel: 'Progreso de ${w.name}',
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
    final p = context.pal;
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final today = todaysChallengeOf(ref);
    const days = [
      ('L', true),
      ('M', true),
      ('X', true),
      ('J', false),
      ('V', false),
      ('S', false),
      ('D', false),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeader(title: HomeTexts.challengeTab),
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
                  Text('$mockStreak días de racha', style: context.display(26)),
                  const DemoBadge(),
                ],
              ),
              Text(
                'Mejor racha: $mockBestStreak · protectores: $mockProtectors',
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
              const SectionLabel(HomeTexts.todayCase),
              const SizedBox(height: 6),
              if (today != null) ...[
                Text(
                  'Día ${today.day} de '
                  '${ref.watch(gameConfigProvider).challengeDays} · '
                  '${difficultyName(today.puzzle.difficulty)} · '
                  '${today.puzzle.map.size}×${today.puzzle.map.size}',
                  style: context.body(15, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  challengeStateText(today.puzzle, prefs),
                  style: context.note(18, color: p.text),
                ),
              ] else
                Text(
                  HomeTexts.noChallenge,
                  style: context.note(18, color: p.text),
                ),
              Text(
                HomeTexts.challengeNote,
                style: context.note(15, color: p.softText),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: HomeTexts.playToday,
                color: p.danger,
                onTap: today == null ? null : () => _playToday(context, today),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Flexible(child: SectionLabel(HomeTexts.weekPoints)),
                  SizedBox(width: 8),
                  DemoBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text('$mockWeeklyPoints pts', style: context.display(24)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- RANKING ----------

class RankingTab extends StatelessWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    // El jugador entra en el orden real por puntos (datos simulados).
    final rows = <(String, int, String, bool)>[
      for (final b in mockBots) (b.$1, b.$2, b.$3, false),
      (HomeTexts.you, mockWeeklyPoints, '🇨🇴', true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const PageHeader(
          title: HomeTexts.ranking,
          subtitle: HomeTexts.rankingSub,
          badge: DemoBadge(),
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
                Text('${r.$2} pts', style: context.display(17)),
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
    // Casos cerrados: los del Mundo 1 y los retos (el banco de pruebas no
    // cuenta).
    final solved = solvedIn([
      ...worldCases(ref),
      for (final c
          in ref.watch(dailyChallengesProvider).valueOrNull ??
              const <DailyChallenge>[])
        c.puzzle,
    ], prefs);
    final nickname = prefs?.getString('profile:nick') ?? 'Detective';
    final initial = nickname.isEmpty ? 'D' : nickname[0].toUpperCase();

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
                    tooltip: 'Cambiar nombre',
                    constraints: const BoxConstraints(
                      minWidth: SkinUi.minTouch,
                      minHeight: SkinUi.minTouch,
                    ),
                    icon: Icon(Icons.edit_rounded, size: 22, color: p.softText),
                    onPressed: () => editNickname(context, ref, prefs),
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    '🇨🇴 · detective desde julio 2026',
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
                label: 'casos cerrados',
                icon: Icons.folder_special_rounded,
                color: p.good,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                value: '$mockStreak',
                label: 'racha actual',
                icon: Icons.local_fire_department_rounded,
                color: p.danger,
                demo: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '$mockBestStreak',
                label: 'mejor racha',
                icon: Icons.military_tech_rounded,
                color: p.medal(0),
                demo: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                value: '$mockWeeklyPoints',
                label: 'puntos semana',
                icon: Icons.stars_rounded,
                color: p.accent,
                demo: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              _MenuRow(
                icon: Icons.storefront_rounded,
                label: 'Tienda',
                demo: true,
                onTap: () => openShopSheet(context),
              ),
              _MenuRow(
                icon: Icons.workspace_premium_rounded,
                label: 'Premium',
                demo: true,
                onTap: () => openPremiumSheet(context),
              ),
              _MenuRow(
                icon: Icons.help_outline_rounded,
                label: 'Cómo jugar',
                onTap: () => openHowToPlay(context),
              ),
              _MenuRow(
                icon: Icons.settings_rounded,
                label: 'Configuración',
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

/// Shell de navegación (2026-07-12): barra inferior SOLO ICONOS estilo
/// Duolingo (referencia del usuario) en versión paper craft — recortes de
/// papel, pestaña activa enmarcada. Pestañas: Inicio · Mundos · Reto ·
/// Ranking · Perfil. Las pantallas usan DATOS QUEMADOS (mock) mientras
/// llega Firebase en Fase 2; la estructura queda final.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/case_repository.dart';
import 'case_list_screen.dart' show prefsProvider;
import 'enx_style.dart';
import 'logo.dart';
import 'tutorial_dialog.dart';

/// ---- DATOS QUEMADOS (se reemplazan por Firebase en Fase 2) ----
const mockLives = 4;
const mockMaxLives = 5;
const mockNextLife = '23:41';
const mockStreak = 3;
const mockBestStreak = 7;
const mockProtectors = 1;
const mockWeeklyPoints = 1840;
const mockBots = [
  ('Sherlock221B', 2450, '🇬🇧'),
  ('MissMarple', 2210, '🇬🇧'),
  ('Kogoro', 2075, '🇯🇵'),
  ('DetectivePikachu', 1990, '🇯🇵'),
  ('Clouseau', 1720, '🇫🇷'),
  ('Colombo', 1580, '🇺🇸'),
  ('PoirotFan', 1495, '🇧🇪'),
];

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pal = ref.watch(paletteProvider);
    final tabs = [
      const _InicioTab(),
      const _MundosTab(),
      const _RetoTab(),
      const _RankingTab(),
      const _PerfilTab(),
    ];
    return Scaffold(
      backgroundColor: pal.background,
      body: SafeArea(child: IndexedStack(index: _tab, children: tabs)),
      bottomNavigationBar: _PaperNavBar(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Barra inferior de papel: solo iconos, activa enmarcada (ref. Duolingo).
class _PaperNavBar extends ConsumerWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _PaperNavBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ref.watch(paletteProvider);
    const items = [
      (Icons.home_rounded, Color(0xFFB3452E)),
      (Icons.map_rounded, Color(0xFF4A7A34)),
      (Icons.today_rounded, Color(0xFF8A5C2E)),
      (Icons.emoji_events_rounded, Color(0xFFB3821F)),
      (Icons.person_rounded, Color(0xFF2E5D8A)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border(top: BorderSide(color: pal.border, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final (i, item) in items.indexed)
                InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 7),
                    decoration: BoxDecoration(
                      color: i == current
                          ? item.$2.withValues(alpha: .14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: i == current
                              ? item.$2
                              : Colors.transparent,
                          width: 2.5),
                    ),
                    child: Icon(item.$1,
                        size: 30,
                        color: i == current ? item.$2 : pal.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- widgets compartidos ----------

class _PaperCard extends ConsumerWidget {
  final Widget child;
  final Color? accent;
  const _PaperCard({required this.child, this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Enx.paper,
        borderRadius: BorderRadius.circular(6),
        border: accent != null
            ? Border(left: BorderSide(color: accent!, width: 5))
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x59473418),
              offset: Offset(0, 5),
              blurRadius: 2),
        ],
      ),
      child: child,
    );
  }
}

Widget _demoBadge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D48E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('DEMO',
          style: Enx.font(10, weight: FontWeight.w800, spacing: 1.5)),
    );

void _demoSnack(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Función simulada — se activa con el modo online '
            '(Fase 2)')));

Widget _livesChip() => Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.favorite_rounded, color: Enx.crimson, size: 20),
      const SizedBox(width: 4),
      Text('$mockLives/$mockMaxLives', style: Enx.font(15)),
      const SizedBox(width: 6),
      Text('+1 en $mockNextLife', style: Enx.font(11, color: Enx.inkMuted)),
    ]);

// ---------- INICIO ----------

class _InicioTab extends ConsumerWidget {
  const _InicioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final cases = ref.watch(casesProvider).valueOrNull ?? [];
    final solved = cases
        .where((c) => prefs?.getString('done:${c.caseId}') != null)
        .length;
    final hour = DateTime.now().hour;
    final saludo = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(children: [
          const PaperLogo(size: 44, withPlate: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$saludo,', style: Enx.hand(17, color: Enx.inkMuted)),
                  Text('detective', style: Enx.display(24)),
                ]),
          ),
          _livesChip(),
        ]),
        const SizedBox(height: 18),
        _PaperCard(
          accent: Enx.crimson,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('🔥 RETO DIARIO',
                      style: Enx.font(12,
                          weight: FontWeight.w800,
                          color: Enx.crimson,
                          spacing: 1.5)),
                  const Spacer(),
                  Text('racha: $mockStreak días', style: Enx.font(12.5)),
                ]),
                const SizedBox(height: 6),
                Text('El caso de hoy te espera',
                    style: Enx.display(19)),
                Text('Un intento oficial · mismo caso para todos',
                    style: Enx.hand(16, color: Enx.inkMuted)),
                const SizedBox(height: 12),
                EnxButton(
                    label: 'Jugar el reto',
                    color: Enx.crimson,
                    onPressed: () {
                      if (cases.isNotEmpty) {
                        // Caso del día determinista por fecha (mock local).
                        final day = DateTime.now()
                            .difference(DateTime(2026, 1, 1))
                            .inDays;
                        context
                            .go('/play/${cases[day % cases.length].caseId}');
                      }
                    }),
              ]),
        ),
        _PaperCard(
          accent: const Color(0xFF4A7A34),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🗺️ MUNDO 1 · LA MANSIÓN',
                    style: Enx.font(12,
                        weight: FontWeight.w800,
                        color: const Color(0xFF4A7A34),
                        spacing: 1.5)),
                const SizedBox(height: 6),
                Text('$solved de ${cases.length} casos cerrados',
                    style: Enx.display(19)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cases.isEmpty ? 0 : solved / cases.length,
                    minHeight: 9,
                    backgroundColor: Enx.paperShade,
                    color: const Color(0xFF4A7A34),
                  ),
                ),
                const SizedBox(height: 12),
                EnxButton(
                    label: 'Continuar investigando',
                    color: Enx.gold,
                    textColor: const Color(0xFF4A3200),
                    onPressed: () => context.go('/casos')),
              ]),
        ),
        _PaperCard(
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text('🛒 TIENDA  ',
                        style: Enx.font(12,
                            weight: FontWeight.w800, spacing: 1.5)),
                    _demoBadge(),
                  ]),
                  const SizedBox(height: 4),
                  Text('Vidas y protectores de racha',
                      style: Enx.hand(16, color: Enx.inkMuted)),
                ])),
            EnxButton(
                label: 'Ver',
                color: Enx.blue,
                expand: false,
                onPressed: () => _openTienda(context)),
          ]),
        ),
      ],
    );
  }
}

// ---------- MUNDOS ----------

class _MundosTab extends ConsumerWidget {
  const _MundosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = [
      ('La Mansión', '🏚️', true),
      ('El Hotel', '🏨', false),
      ('El Museo', '🏛️', false),
      ('El Tren', '🚂', false),
      ('El Hospital', '🏥', false),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Mundos', style: Enx.display(28)),
        Text('1 de 5 desbloqueados', style: Enx.hand(17, color: Enx.inkMuted)),
        const SizedBox(height: 14),
        for (final (name, emoji, unlocked) in worlds)
          Opacity(
            opacity: unlocked ? 1 : .55,
            child: _PaperCard(
              accent: unlocked ? const Color(0xFF4A7A34) : null,
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name, style: Enx.display(19)),
                      Text(unlocked ? 'En investigación' : 'Bloqueado',
                          style: Enx.hand(15, color: Enx.inkMuted)),
                    ])),
                unlocked
                    ? EnxButton(
                        label: 'Entrar',
                        color: const Color(0xFF4A7A34),
                        expand: false,
                        onPressed: () => context.go('/casos'))
                    : const Icon(Icons.lock_rounded,
                        color: Enx.inkMuted, size: 28),
              ]),
            ),
          ),
      ],
    );
  }
}

// ---------- RETO DIARIO ----------

class _RetoTab extends ConsumerWidget {
  const _RetoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(casesProvider).valueOrNull ?? [];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Reto diario', style: Enx.display(28)),
        const SizedBox(height: 14),
        _PaperCard(
          accent: Enx.crimson,
          child: Column(children: [
            Text('🔥', style: const TextStyle(fontSize: 46)),
            Text('$mockStreak días de racha', style: Enx.display(24)),
            Text('mejor racha: $mockBestStreak · protectores: '
                '$mockProtectors 🛡️',
                style: Enx.hand(16, color: Enx.inkMuted)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final (d, done) in [
                ('L', true), ('M', true), ('X', true),
                ('J', false), ('V', false), ('S', false), ('D', false),
              ])
                Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: done ? Enx.crimson : Enx.paperShade,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(d,
                              style: Enx.font(12, color: Enx.inkMuted))),
                ),
            ]),
          ]),
        ),
        _PaperCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EL CASO DE HOY',
                    style: Enx.font(12,
                        weight: FontWeight.w800, spacing: 1.5)),
                const SizedBox(height: 4),
                Text('Estado: no iniciado', style: Enx.hand(17)),
                Text('Un solo intento oficial · cierra a medianoche',
                    style: Enx.hand(15, color: Enx.inkMuted)),
                const SizedBox(height: 12),
                EnxButton(
                    label: 'Comenzar intento oficial',
                    color: Enx.crimson,
                    onPressed: () {
                      if (cases.isNotEmpty) {
                        final day = DateTime.now()
                            .difference(DateTime(2026, 1, 1))
                            .inDays;
                        context
                            .go('/play/${cases[day % cases.length].caseId}');
                      }
                    }),
              ]),
        ),
        _PaperCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('PUNTOS DE LA SEMANA  ',
                      style: Enx.font(12,
                          weight: FontWeight.w800, spacing: 1.5)),
                  _demoBadge(),
                ]),
                const SizedBox(height: 4),
                Text('$mockWeeklyPoints pts', style: Enx.display(22)),
              ]),
        ),
      ],
    );
  }
}

// ---------- RANKING ----------

class _RankingTab extends StatelessWidget {
  const _RankingTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(children: [
          Text('Ranking', style: Enx.display(28)),
          const SizedBox(width: 8),
          _demoBadge(),
        ]),
        Text('Semanal · se conecta en el modo online',
            style: Enx.hand(16, color: Enx.inkMuted)),
        const SizedBox(height: 14),
        for (final (i, bot) in mockBots.indexed)
          _PaperCard(
            accent: i == 0
                ? Enx.gold
                : i == 1
                    ? const Color(0xFFA8A8A8)
                    : i == 2
                        ? const Color(0xFFB07B4A)
                        : null,
            child: Row(children: [
              SizedBox(
                  width: 34,
                  child: Text(
                      i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}',
                      style: i < 3
                          ? const TextStyle(fontSize: 22)
                          : Enx.display(17, color: Enx.inkMuted))),
              Text(bot.$3, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text(bot.$1, style: Enx.font(15.5))),
              Text('${bot.$2} pts', style: Enx.display(16)),
            ]),
          ),
        _PaperCard(
          accent: Enx.blue,
          child: Row(children: [
            SizedBox(width: 34, child: Text('11', style: Enx.display(17))),
            const Text('🇨🇴', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Tú (detective)',
                    style: Enx.font(15.5, weight: FontWeight.w800))),
            Text('$mockWeeklyPoints pts', style: Enx.display(16)),
          ]),
        ),
      ],
    );
  }
}

// ---------- PERFIL ----------

class _PerfilTab extends ConsumerWidget {
  const _PerfilTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).valueOrNull;
    final cases = ref.watch(casesProvider).valueOrNull ?? [];
    final solved = cases
        .where((c) => prefs?.getString('done:${c.caseId}') != null)
        .length;
    final nickname = prefs?.getString('profile:nick') ?? 'Detective';

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(
            child: Column(children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: Enx.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Enx.paper, width: 4),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x59473418),
                    offset: Offset(0, 5),
                    blurRadius: 2),
              ],
            ),
            child: Center(
                child: Text(nickname[0].toUpperCase(),
                    style: Enx.display(42, color: Colors.white))),
          ),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(nickname, style: Enx.display(24)),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 20, color: Enx.inkMuted),
              onPressed: () => _editNick(context, ref, prefs),
            ),
          ]),
          Text('🇨🇴 · detective desde julio 2026',
              style: Enx.hand(16, color: Enx.inkMuted)),
        ])),
        const SizedBox(height: 16),
        _PaperCard(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('$solved', 'casos\ncerrados'),
                _stat('$mockStreak🔥', 'racha\nactual'),
                _stat('$mockBestStreak', 'mejor\nracha'),
                _stat('$mockWeeklyPoints', 'puntos\nsemana'),
              ]),
        ),
        _PaperCard(
            child: Column(children: [
          _menuRow(context, Icons.storefront_rounded, 'Tienda',
              badge: true, onTap: () => _openTienda(context)),
          _menuRow(context, Icons.workspace_premium_rounded, 'Premium',
              badge: true, onTap: () => _openPremium(context)),
          _menuRow(context, Icons.help_outline_rounded, 'Cómo jugar',
              onTap: () => showTutorialDialog(context)),
          _menuRow(context, Icons.settings_rounded, 'Configuración',
              onTap: () => _openConfig(context)),
        ])),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(children: [
        Text(value, style: Enx.display(21)),
        Text(label,
            textAlign: TextAlign.center,
            style: Enx.font(10.5, color: Enx.inkMuted)),
      ]);

  Widget _menuRow(BuildContext context, IconData icon, String label,
          {bool badge = false, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Icon(icon, color: Enx.goldInk, size: 24),
            const SizedBox(width: 12),
            Text(label, style: Enx.font(16)),
            const SizedBox(width: 8),
            if (badge) _demoBadge(),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Enx.inkMuted),
          ]),
        ),
      );

  void _editNick(
      BuildContext context, WidgetRef ref, SharedPreferences? prefs) {
    final ctl =
        TextEditingController(text: prefs?.getString('profile:nick') ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu nombre de detective'),
        content: TextField(controller: ctl, maxLength: 16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () async {
                if (ctl.text.trim().isNotEmpty) {
                  await prefs?.setString('profile:nick', ctl.text.trim());
                  ref.invalidate(prefsProvider);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar')),
        ],
      ),
    );
  }
}

// ---------- TIENDA / PREMIUM / CONFIG (hojas modales DEMO) ----------

void _openTienda(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Enx.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Tienda ', style: Enx.display(22)),
                _demoBadge(),
              ]),
              const SizedBox(height: 12),
              for (final (name, price) in [
                ('❤️ 10 vidas', r'$0.99'),
                ('🛡️ 3 protectores de racha', r'$0.99'),
                ('🛡️ 10 protectores de racha', r'$2.99'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(child: Text(name, style: Enx.font(16))),
                    EnxButton(
                        label: price,
                        color: Enx.gold,
                        textColor: const Color(0xFF4A3200),
                        expand: false,
                        onPressed: () => _demoSnack(ctx)),
                  ]),
                ),
            ]),
      ),
    );

void _openPremium(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Enx.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Premium ', style: Enx.display(22)),
                _demoBadge(),
              ]),
              Text('Sin anuncios · vidas ilimitadas · sin ventajas de '
                  'ranking',
                  style: Enx.hand(16, color: Enx.inkMuted)),
              const SizedBox(height: 14),
              EnxButton(
                  label: r'Mensual · $4.99',
                  color: Enx.blue,
                  onPressed: () => _demoSnack(ctx)),
              const SizedBox(height: 10),
              EnxButton(
                  label: r'Anual · $29.99 (ahorra 50%)',
                  color: Enx.crimson,
                  onPressed: () => _demoSnack(ctx)),
            ]),
      ),
    );

void _openConfig(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Enx.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _ConfigSheet(),
    );

class _ConfigSheet extends StatefulWidget {
  const _ConfigSheet();
  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) => setState(() => _prefs = p));
  }

  @override
  Widget build(BuildContext context) {
    Widget toggle(String label, String key, {bool def = true}) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: Enx.font(15.5)),
          value: _prefs?.getBool('cfg:$key') ?? def,
          activeTrackColor: Enx.green,
          onChanged: (v) async {
            await _prefs?.setBool('cfg:$key', v);
            setState(() {});
          },
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración', style: Enx.display(22)),
            const SizedBox(height: 6),
            toggle('Sonido', 'sound'),
            toggle('Música', 'music'),
            toggle('Vibración', 'haptics'),
            toggle('Notificaciones', 'notifs'),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Idioma', style: Enx.font(15.5)),
              trailing: Text('Español', style: Enx.font(14, color: Enx.inkMuted)),
            ),
            Row(children: [
              Expanded(
                  child: Text('Cuenta y compras',
                      style: Enx.font(15.5, color: Enx.inkMuted))),
              _demoBadge(),
            ]),
            Text('Restaurar compras, cerrar sesión y eliminar cuenta se '
                'activan con el modo online.',
                style: Enx.hand(15, color: Enx.inkMuted)),
            const SizedBox(height: 6),
            Text('Enigmatrix v0.1.0 · hecho en papel 📜',
                style: Enx.font(12, color: Enx.inkMuted)),
          ]),
    );
  }
}

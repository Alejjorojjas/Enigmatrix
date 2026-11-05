/// Bienvenida de primera vez: ventana paginada estilo cuaderno de detective
/// que explica cómo jugar. Aparece automáticamente en el primer arranque, se
/// puede OMITIR, y se reabre desde el botón ? de la lista de casos. Desde el
/// 04-11-2026 (regla 11, ADR-0012) el primer arranque sigue con el caso de
/// práctica; ver tutorial_coach.dart. Toma su aspecto de la piel y el modo
/// activos.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import 'game_chrome.dart';
import 'skin_theme.dart';
import 'ui_kit.dart';

const tutorialSeenKey = 'tutorial:seen';

/// Con [thenPractice] (primer arranque) el último botón anuncia el caso de
/// práctica que viene a continuación; quien llama navega al terminar.
Future<void> showTutorialDialog(
  BuildContext context, {
  bool thenPractice = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(tutorialSeenKey, true);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TutorialDialog(thenPractice: thenPractice),
  );
}

class _Page {
  final IconData icon;
  final String title;
  final List<String> lines;
  const _Page(this.icon, this.title, this.lines);
}

/// Las páginas del diálogo, con los textos del idioma activo.
List<_Page> _pagesOf(AppLocalizations l10n) => [
  _Page(Icons.search_rounded, l10n.tutorialDialogWelcomeTitle, [
    l10n.tutorialDialogWelcomeLine1,
    l10n.tutorialDialogWelcomeLine2,
    l10n.tutorialDialogWelcomeLine3,
  ]),
  _Page(Icons.map_rounded, l10n.tutorialDialogBoardTitle, [
    l10n.tutorialDialogBoardLine1,
    l10n.tutorialDialogBoardLine2,
    l10n.tutorialDialogBoardLine3,
  ]),
  _Page(Icons.description_rounded, l10n.tutorialDialogCluesTitle, [
    l10n.tutorialDialogCluesLine1,
    l10n.tutorialDialogCluesLine2,
    l10n.tutorialDialogCluesLine3,
  ]),
  _Page(Icons.edit_rounded, l10n.tutorialDialogMarksTitle, [
    l10n.tutorialDialogMarksLine1,
    l10n.tutorialDialogMarksLine2,
    l10n.tutorialDialogMarksLine3,
  ]),
  _Page(Icons.balance_rounded, l10n.tutorialDialogSolveTitle, [
    l10n.tutorialDialogSolveLine1,
    l10n.tutorialDialogSolveLine2,
    l10n.tutorialDialogSolveLine3,
  ]),
];

class _TutorialDialog extends StatefulWidget {
  final bool thenPractice;
  const _TutorialDialog({this.thenPractice = false});

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pages = _pagesOf(context.l10n);
    final isLast = _page == pages.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
        child: ChromeBox(
          color: p.surface,
          radius: 22,
          child: Column(
            children: [
              // Rótulo superior + omitir.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 8, 0),
                child: Row(
                  children: [
                    SectionLabel(
                      context.l10n.tutorialDialogHeader,
                      icon: Icons.menu_book_rounded,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.l10n.tutorialDialogSkip,
                        style: context.body(15, color: p.softText),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final pg = pages[i];
                    // Se desplaza: en pantallas bajas el contenido no cabe.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                      child: Column(
                        children: [
                          IconTile(icon: pg.icon, color: p.world(i), size: 64),
                          const SizedBox(height: 10),
                          Text(
                            pg.title,
                            textAlign: TextAlign.center,
                            style: context.display(24),
                          ),
                          const SizedBox(height: 12),
                          for (final line in pg.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: context.body(
                                      16,
                                      color: p.danger,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: context.note(17, color: p.text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Puntos de página + botón.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == _page ? 24 : 9,
                            height: 9,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _page ? p.accent : p.surfaceAlt,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: p.line, width: 1.2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: isLast
                          ? (widget.thenPractice
                                ? context.l10n.tutorialDialogStartPractice
                                : context.l10n.tutorialDialogGo)
                          : context.l10n.tutorialDialogNext,
                      color: isLast ? p.danger : null,
                      onTap: () {
                        if (isLast) {
                          Navigator.of(context).pop();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

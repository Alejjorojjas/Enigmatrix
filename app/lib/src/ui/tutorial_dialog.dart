/// Bienvenida de primera vez: ventana paginada estilo cuaderno de detective
/// que explica cómo jugar. Aparece automáticamente en el primer arranque, se
/// puede OMITIR, y se reabre desde el botón ? de la lista de casos. Desde el
/// 04-11-2026 (regla 11, ADR-0012) el primer arranque sigue con el caso de
/// práctica; ver tutorial_coach.dart. Toma su aspecto de la piel y el modo
/// activos.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _pages = [
  _Page(Icons.search_rounded, 'Bienvenido, detective', [
    'En cada caso hay un grupo de sospechosos, una víctima y UNA verdad.',
    'Tu misión: descubrir dónde estaba cada persona usando pura lógica.',
    'Nada de adivinar — cada caso tiene una única solución deducible.',
  ]),
  _Page(Icons.map_rounded, 'El tablero', [
    'El mapa es una cuadrícula con habitaciones y muebles.',
    'REGLA DE ORO: hay exactamente UNA persona por fila y UNA por columna, como en un sudoku.',
    'Las casillas con muebles que bloquean (mesas, plantas, cajas) no pueden ocuparse. Sobre sillas, camas, sofás y alfombras SÍ puede haber alguien.',
  ]),
  _Page(Icons.description_rounded, 'Las pistas', [
    'Cada sospechoso tiene una pista en su tarjeta: "estaba sobre una cama", "junto a una planta"…',
    '"Junto a" significa en una casilla vecina (arriba, abajo, izquierda o derecha) de la misma habitación.',
    'Cruza las pistas con la regla de filas y columnas para descartar casillas.',
  ]),
  _Page(Icons.edit_rounded, 'Tus marcas', [
    'TOCA una casilla para anotar un CANDIDATO (una letra pequeña).',
    'MANTÉN PRESIONADO (o usa la herramienta Confirmar) para CONFIRMAR a alguien: se tachan su fila y su columna automáticamente.',
    'Usa Tachar para descartar casillas y Borrar para limpiar. Deshacer siempre está disponible.',
  ]),
  _Page(Icons.balance_rounded, 'Resolver el caso', [
    'Cuando todos estén confirmados, pulsa RESOLVER.',
    'Si todo está correcto: el asesino es quien quedó A SOLAS con la víctima en la misma habitación. El sistema lo revela.',
    'Si algo no cuadra, el juego te dice cuántas casillas fallan, pero no cuáles: hay que volver a deducir. ¡Suerte, detective!',
  ]),
];

/// Textos del diálogo (centralizados para traducir en la ronda 4.3).
abstract final class TutorialDialogTexts {
  static const header = 'CÓMO JUGAR';
  static const skip = 'Omitir';
  static const next = 'Siguiente';
  static const startPractice = 'Empezar la práctica';
  static const go = '¡A investigar!';
}

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
    final isLast = _page == _pages.length - 1;
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
                    const SectionLabel(
                      TutorialDialogTexts.header,
                      icon: Icons.menu_book_rounded,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        TutorialDialogTexts.skip,
                        style: context.body(15, color: p.softText),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final pg = _pages[i];
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
                        for (var i = 0; i < _pages.length; i++)
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
                                ? TutorialDialogTexts.startPractice
                                : TutorialDialogTexts.go)
                          : TutorialDialogTexts.next,
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

/// Bienvenida de primera vez (2026-07-12): ventana paginada estilo cuaderno
/// de detective que explica cómo jugar. Aparece automáticamente en el primer
/// arranque, se puede OMITIR, y se reabre desde el botón ? de la pantalla
/// de casos. Desde el 04-11-2026 (regla 11, ADR-0012) el primer arranque
/// sigue con el caso de práctica; ver tutorial_coach.dart.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'enx_style.dart';

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
    barrierColor: const Color(0xCC3D2F1C),
    builder: (_) => _TutorialDialog(thenPractice: thenPractice),
  );
}

class _Page {
  final String emoji;
  final String title;
  final List<String> lines;
  const _Page(this.emoji, this.title, this.lines);
}

const _pages = [
  _Page('🔍', 'Bienvenido, detective', [
    'En cada caso hay un grupo de sospechosos, una víctima y UNA verdad.',
    'Tu misión: descubrir dónde estaba cada persona usando pura lógica.',
    'Nada de adivinar — cada caso tiene una única solución deducible.',
  ]),
  _Page('🗺️', 'El tablero', [
    'El mapa es una cuadrícula con habitaciones y muebles.',
    'REGLA DE ORO: hay exactamente UNA persona por fila y UNA por columna, como en un sudoku.',
    'Las casillas con muebles que bloquean (mesas, plantas, cajas) no pueden ocuparse. Sobre sillas, camas, sofás y alfombras SÍ puede haber alguien.',
  ]),
  _Page('📜', 'Las pistas', [
    'Cada sospechoso tiene una pista en su tarjeta: "estaba sobre una cama", "junto a una planta"…',
    '"Junto a" significa en una casilla vecina (arriba, abajo, izquierda o derecha) de la misma habitación.',
    'Cruza las pistas con la regla de filas y columnas para descartar casillas.',
  ]),
  _Page('✏️', 'Tus marcas', [
    'TOCA una casilla para anotar un CANDIDATO (una letra pequeña).',
    'MANTÉN PRESIONADO (o arrastra la tarjeta) para CONFIRMAR a alguien: se tachan su fila y su columna automáticamente.',
    'Usa la X para descartar casillas, el borrador para limpiar, y la papelera para eliminar arrastrando. Deshacer y rehacer siempre disponibles.',
  ]),
  _Page('⚖️', 'Resolver el caso', [
    'Cuando todos estén confirmados, pulsa RESOLVER.',
    'Si todo está correcto: el asesino es quien quedó A SOLAS con la víctima en la misma habitación. El sistema lo revela.',
    'Si algo no cuadra, el juego te dice cuántas casillas fallan, pero no cuáles: hay que volver a deducir. ¡Suerte, detective!',
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
    final isLast = _page == _pages.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Container(
          decoration: BoxDecoration(
            color: Enx.paper,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99271D0E),
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            children: [
              // Cinta superior + omitir.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      color: const Color(0xFFE8D48E),
                      child: Text(
                        'CÓMO JUGAR',
                        style: Enx.font(
                          11,
                          weight: FontWeight.w800,
                          color: Enx.ink,
                          spacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Omitir',
                        style: Enx.font(14, color: Enx.inkMuted),
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
                    final p = _pages[i];
                    // Scrolleable: en pantallas bajas el contenido no cabe.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 10, 26, 8),
                      child: Column(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 52)),
                          const SizedBox(height: 8),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: Enx.display(23, color: Enx.goldInk),
                          ),
                          const SizedBox(height: 14),
                          for (final line in p.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: Enx.font(
                                      15,
                                      color: Enx.crimson,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: Enx.hand(18, color: Enx.ink),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _page ? Enx.crimson : Enx.paperShade,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    EnxButton(
                      label: isLast
                          ? (widget.thenPractice
                                ? 'Empezar la práctica'
                                : '¡A investigar!')
                          : 'Siguiente',
                      color: isLast ? Enx.crimson : Enx.gold,
                      textColor: isLast
                          ? Colors.white
                          : const Color(0xFF4A3200),
                      onPressed: () {
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

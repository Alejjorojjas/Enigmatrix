/// `clueText` es el único punto de la app que pide el texto de una pista (H-63):
/// elige el formateador del motor según el idioma (hoy solo español).
library;

import 'dart:ui';

import 'package:enigmatrix/src/ui/clue_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_ui.dart';

void main() {
  final pc = loadBankCase('caso-principiante-s1');
  final clue = pc.clues.first;

  test('en español devuelve la tarjeta del motor (ClueFormatterEs)', () {
    expect(
      clueText(pc, clue, locale: const Locale('es')),
      clue.cardTextEs(pc.map, pc.names),
    );
  });

  test('card: false devuelve la frase completa con el sujeto', () {
    expect(clueText(pc, clue, card: false), clue.textEs(pc.map, pc.names));
  });

  test('sin formateador para el idioma cae en español', () {
    expect(
      clueText(pc, clue, locale: const Locale('en')),
      clue.cardTextEs(pc.map, pc.names),
    );
  });
}

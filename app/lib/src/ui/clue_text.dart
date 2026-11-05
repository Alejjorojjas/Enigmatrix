/// Único punto de la app donde se pide el texto de una pista (H-63).
///
/// Los textos de las pistas NO van en el .arb: los compone el motor
/// (`tools/`, ClueFormatter) a partir del mapa y los nombres del caso. Aquí se
/// elige el formateador según el idioma; hoy solo existe el español, así que
/// cualquier otro idioma cae en él hasta que el motor tenga su formateador.
library;

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../l10n/l10n.dart' show kAppLocale;

/// Texto de la pista [clue] del caso [pc] en el idioma [locale].
///
/// Con [card] (por omisión) es el texto de la tarjeta del personaje, sin el
/// nombre ("Estaba en el Salón."); si no, la frase completa con el sujeto
/// ("Adela estaba en el Salón.").
String clueText(
  PuzzleCase pc,
  Clue clue, {
  Locale locale = kAppLocale,
  bool card = true,
}) {
  switch (locale.languageCode) {
    case 'es':
    default:
      return card
          ? clue.cardTextEs(pc.map, pc.names)
          : clue.textEs(pc.map, pc.names);
  }
}

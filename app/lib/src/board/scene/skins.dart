/// Pieles disponibles. "Ilustrada" y "Papel" son las dos direcciones de arte
/// que Alejandro compara en el teléfono; "Neutra" es la prueba técnica
/// original. Cada piel se construye para un modo (claro u oscuro).
library;

import 'dart:ui' show Brightness;

import 'illustrated_skin.dart';
import 'neutral_skin.dart';
import 'palette.dart';
import 'paper_skin.dart';
import 'skin.dart';

/// Descripción de una piel: su nombre, cómo se ve la interfaz y cómo
/// construirla, sin instanciarla.
class SkinSpec {
  const SkinSpec({
    required this.id,
    required this.displayName,
    required this.chrome,
    required this.palette,
    required this.create,
  });

  final String id;
  final String displayName;
  final ChromeKind chrome;
  final SkinPalette Function(Brightness) palette;
  final BoardSkin Function(Brightness) create;
}

class SkinRegistry {
  const SkinRegistry._();

  /// La primera es la que se usa si un identificador no existe.
  static final List<SkinSpec> specs = [
    SkinSpec(
      id: IllustratedSkin.idName,
      displayName: 'Ilustrada',
      chrome: ChromeKind.ink,
      palette: IllustratedSkin.paletteFor,
      create: (m) => IllustratedSkin(mode: m),
    ),
    SkinSpec(
      id: PaperSkin.idName,
      displayName: 'Papel',
      chrome: ChromeKind.paper,
      palette: PaperSkin.paletteFor,
      create: (m) => PaperSkin(mode: m),
    ),
    SkinSpec(
      id: NeutralSkin.idName,
      displayName: 'Neutra',
      chrome: ChromeKind.flat,
      palette: NeutralSkin.paletteFor,
      create: (m) => NeutralSkin(mode: m),
    ),
  ];

  static List<String> get ids => [for (final s in specs) s.id];

  static SkinSpec spec(String id) =>
      specs.firstWhere((s) => s.id == id, orElse: () => specs.first);

  static BoardSkin create(String id, Brightness mode) => spec(id).create(mode);

  static List<BoardSkin> all(Brightness mode) =>
      [for (final s in specs) s.create(mode)];
}

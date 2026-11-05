import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablero_flame/src/scene/board_geometry.dart';
import 'package:tablero_flame/src/scene/neutral_skin.dart';
import 'package:tablero_flame/src/scene/skin.dart';
import 'package:tablero_flame/src/scene/skins.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('los dos casos copiados se leen con el motor y son válidos', () {
    for (final (name, size, difficulty) in [
      ('caso-principiante-s1', 6, 'principiante'),
      ('caso-casual-s1', 8, 'casual'),
    ]) {
      test(name, () {
        final pc = loadCase(name);
        expect(pc.map.size, size);
        expect(pc.difficulty, difficulty);
        expect(pc.characters, hasLength(size));
        final v = Validator.validate(pc, pc.solution.positions);
        expect(v.valid, isTrue, reason: v.errors.join('; '));
        expect(v.murdererId, pc.solution.murdererId);
      });
    }
  });

  group('piel neutra', () {
    final skin = NeutralSkin();

    test('el registro entrega las tres pieles y la inexistente cae en la primera', () {
      expect(SkinRegistry.ids, ['ilustrada', 'papel', 'neutra']);
      expect(SkinRegistry.all(Brightness.light), hasLength(3));
      expect(SkinRegistry.create('neutra', Brightness.dark).id, 'neutra');
      expect(SkinRegistry.create('no-existe', Brightness.dark).id, 'ilustrada');
    });

    test('pinta el fondo de ambos casos sin errores', () {
      for (final name in ['caso-principiante-s1', 'caso-casual-s1']) {
        final pc = loadCase(name);
        const size = Size(360, 520);
        final g = BoardGeometry.fit(pc.map.size, size);
        final rec = PictureRecorder();
        final canvas = Canvas(rec);
        skin.paintBackdrop(canvas, size, g, pc.map);
        final pic = rec.endRecording();
        expect(pic.approximateBytesUsed, greaterThan(0));
        pic.dispose();
      }
    });

    test('pinta fichas, notas, X, anillo y estrella', () {
      final rec = PictureRecorder();
      final c = Canvas(rec);
      const style = TokenStyle(charIndex: 2, initial: 'C');
      skin.paintTokenShadow(c, const Offset(50, 50), 18, lift: 6);
      skin.paintToken(c, const Offset(50, 50), 18, style);
      skin.paintToken(c, const Offset(100, 50), 18,
          const TokenStyle(charIndex: 4, initial: 'E', victim: true, alpha: 0.5));
      skin.paintToken(c, const Offset(150, 50), 18,
          const TokenStyle(charIndex: 1, initial: 'B', eyeOpen: 0.1));
      skin.paintCandidate(c, const Offset(50, 100), 16, style, 1);
      skin.paintCross(c, const Rect.fromLTWH(0, 120, 50, 50), 0.7);
      skin.paintCross(c, const Rect.fromLTWH(60, 120, 50, 50), 1, alpha: 0.4);
      skin.paintCellGlow(c, const Rect.fromLTWH(0, 180, 50, 50), 0.3);
      skin.paintHoldRing(c, const Offset(80, 200), 20, 0.5, 1);
      skin.paintStar(c, const Offset(150, 200), 20, 1);
      final pic = rec.endRecording();
      expect(pic.approximateBytesUsed, greaterThan(0));
      pic.dispose();
    });

    test('cada personaje tiene un color distinto', () {
      final colors = {for (var i = 0; i < 8; i++) skin.characterColor(i)};
      expect(colors, hasLength(8));
    });
  });
}

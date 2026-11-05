import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/scene/board_geometry.dart';
import 'package:enigmatrix/src/board/scene/floors.dart';
import 'package:enigmatrix/src/board/scene/furniture_art.dart';
import 'package:enigmatrix/src/board/scene/portrait_art.dart';
import 'package:enigmatrix/src/board/scene/skin.dart';
import 'package:enigmatrix/src/board/scene/skins.dart';
import 'package:enigmatrix/src/ui/skin_theme.dart' show SkinPaletteUi;

import '../support/board_rig.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Un mapa de 6x6 con una sola habitación y un mueble.
GameMap _mapWith(ObjectType type, List<int> cells) => GameMap(
  id: 'm',
  nameEs: 'Prueba',
  size: 6,
  areas: [
    Area(id: 'sala', nameEs: 'la Sala', cells: List.generate(36, (i) => i)),
  ],
  objects: [MapObject(id: 'o', type: type, cells: cells)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cada piel entrega los colores de los dos modos', () {
    for (final spec in SkinRegistry.specs) {
      group(spec.id, () {
        final light = spec.palette(Brightness.light);
        final dark = spec.palette(Brightness.dark);

        test('cada modo trae todos sus colores', () {
          expect(light.mode, Brightness.light);
          expect(dark.mode, Brightness.dark);
          expect(light.characters, hasLength(8));
          expect(dark.characters, hasLength(8));
          expect(light.portraitBg, hasLength(8));
          expect(dark.portraitBg, hasLength(8));
          // Los colores de interfaz son opacos.
          for (final c in [
            light.bg,
            light.surface,
            light.text,
            light.accent,
            light.pill,
            dark.bg,
            dark.surface,
            dark.text,
            dark.accent,
            dark.pill,
          ]) {
            expect(c.a, 1.0);
          }
          expect(light.all, isNotEmpty);
          expect(dark.all, hasLength(light.all.length));
        });

        test(
          'el claro es claro pero no blanco; el oscuro es oscuro pero no negro',
          () {
            expect(
              light.bg.computeLuminance(),
              greaterThan(dark.bg.computeLuminance()),
            );
            expect(light.bg, isNot(const Color(0xFFFFFFFF)));
            expect(light.surface, isNot(const Color(0xFFFFFFFF)));
            expect(light.bg.computeLuminance(), lessThan(0.85));
            expect(dark.bg, isNot(const Color(0xFF000000)));
            expect(dark.bg.computeLuminance(), greaterThan(0.004));
            expect(dark.bg.computeLuminance(), lessThan(0.15));
          },
        );

        test(
          'el texto se lee sobre el fondo y los botones activos se leen',
          () {
            for (final p in [light, dark]) {
              expect(
                _contrast(p.text, p.bg),
                greaterThanOrEqualTo(4.5),
                reason: '${p.mode}',
              );
              expect(_contrast(p.text, p.surface), greaterThanOrEqualTo(4.5));
              expect(
                _contrast(p.text, p.surfaceAlt),
                greaterThanOrEqualTo(4.5),
              );
              expect(_contrast(p.onPill, p.pill), greaterThanOrEqualTo(4.5));
              expect(
                _contrast(p.onToolActive, p.toolActive),
                greaterThanOrEqualTo(4.5),
              );
              expect(
                _contrast(p.onAccent, p.accent),
                greaterThanOrEqualTo(4.5),
                reason: 'onAccent sobre accent, ${p.mode}',
              );
            }
          },
        );

        test('los botones de color (acento, peligro y bien) llegan a AA 4,5:1 '
            'con su texto, en los dos modos', () {
          for (final p in [light, dark]) {
            for (final (name, fill) in [
              ('accent', p.accent),
              ('danger', p.danger),
              ('good', p.good),
            ]) {
              expect(
                _contrast(p.onColor(fill), fill),
                greaterThanOrEqualTo(4.5),
                reason: '$name en ${p.mode} (${spec.id})',
              );
            }
          }
        });

        test('la piel construida en cada modo usa la paleta de ese modo', () {
          for (final m in Brightness.values) {
            final skin = spec.create(m);
            expect(skin.mode, m);
            expect(skin.palette.mode, m);
            expect(skin.palette.bg, spec.palette(m).bg);
            expect(skin.backdrop, spec.palette(m).backdrop);
            expect(skin.chrome, spec.chrome);
          }
        });
      });
    }
  });

  group('muebles', () {
    test('los 18 tipos tienen dibujo (1 casilla y 2 casillas)', () {
      expect(ObjectType.values, hasLength(18));
      for (final t in ObjectType.values) {
        for (final mode in Brightness.values) {
          for (final (w, h) in const [(0.78, 0.78), (1.78, 0.78)]) {
            final m = buildFurniture(t, w, h, mode);
            expect(m.parts.length, greaterThanOrEqualTo(3), reason: '$t');
            expect(m.silhouettes, isNotEmpty, reason: '$t tiene silueta');
          }
        }
      }
    });

    test('en modo oscuro los muebles se atenúan', () {
      final l = buildFurniture(ObjectType.mesa, 1.78, 0.78, Brightness.light);
      final d = buildFurniture(ObjectType.mesa, 1.78, 0.78, Brightness.dark);
      expect(
        d.parts.first.color.computeLuminance(),
        lessThan(l.parts.first.color.computeLuminance()),
      );
    });

    for (final skinId in ['ilustrada', 'papel']) {
      testWidgets(
        '$skinId pinta todos los tipos, en horizontal y vertical, en los dos modos',
        (tester) async {
          for (final mode in Brightness.values) {
            final skin = SkinRegistry.create(skinId, mode);
            for (final t in ObjectType.values) {
              for (final cells in const [
                [8],
                [8, 9],
                [8, 14],
              ]) {
                final map = _mapWith(t, cells);
                const size = Size(360, 520);
                final g = BoardGeometry.fit(6, size);
                final rec = PictureRecorder();
                skin.paintBackdrop(Canvas(rec), size, g, map);
                final pic = rec.endRecording();
                expect(
                  pic.approximateBytesUsed,
                  greaterThan(0),
                  reason: '$skinId $t',
                );
                pic.dispose();
              }
            }
          }
        },
      );
    }

    testWidgets(
      'cada mueble deja píxeles propios distintos en las dos pieles',
      (tester) async {
        await tester.runAsync(() async {
          for (final skinId in ['ilustrada', 'papel']) {
            final skin = SkinRegistry.create(skinId, Brightness.light);
            final empty = _mapWith(ObjectType.mesa, [0]);
            const size = Size(240, 240);
            final g = BoardGeometry.fit(6, size, margin: 0);

            Future<List<int>> render(GameMap map) async {
              final rec = PictureRecorder();
              skin.paintBackdrop(Canvas(rec), size, g, map);
              final img = await rec.endRecording().toImage(240, 240);
              final bytes = (await img.toByteData())!;
              return bytes.buffer.asUint8List();
            }

            final base = await render(empty); // solo la mesa en la casilla 0
            for (final t in ObjectType.values) {
              if (t == ObjectType.mesa) continue;
              // El mueble de prueba va en la casilla 14 (fila 2, columna 2).
              final withT = await render(_mapWith(t, [14]));
              var diff = 0;
              for (var i = 0; i < base.length; i += 4) {
                if (base[i] != withT[i] || base[i + 1] != withT[i + 1]) diff++;
              }
              expect(diff, greaterThan(300), reason: '$skinId $t se ve');
            }
          }
        });
      },
    );
  });

  group('retratos y pisos', () {
    test('cada personaje tiene un retrato distinto', () {
      final keys = <String>{};
      for (var i = 0; i < 8; i++) {
        final s = PortraitSpec.forCharacter(i, female: i.isEven);
        keys.add('${s.skin}|${s.hair}|${s.clothes}|${s.style}');
        expect(buildBust(s), isNotEmpty);
      }
      expect(keys, hasLength(8));
    });

    test('la víctima y el parpadeo cambian el dibujo', () {
      final s = PortraitSpec.forCharacter(2, female: true);
      final normal = buildBust(s);
      final victim = buildBust(s, victim: true);
      final blink = buildBust(s, eyeOpen: 0.1);
      // La víctima tiene cruces en los ojos (otra cantidad de piezas) y piel pálida.
      expect(victim.length, isNot(normal.length));
      expect(victim.any((p) => p.color == s.skin), isFalse);
      // Con los ojos cerrados desaparece el brillo de las pupilas.
      expect(blink.length, lessThan(normal.length));
    });

    test('el tipo de piso sale del nombre de la habitación', () {
      expect(floorKindFor('el Baño', 0), FloorKind.baldosa);
      expect(floorKindFor('la Terraza', 0), FloorKind.piedra);
      expect(floorKindFor('el Pasillo', 3), FloorKind.piedra);
      expect(floorKindFor('la Biblioteca', 0), FloorKind.madera);
      expect(floorKindFor('el Dormitorio', 0), FloorKind.alfombra);
      expect(floorKindFor('la Lavandería', 0), FloorKind.baldosa);
      // Sin pista en el nombre: cae por índice.
      expect(floorKindFor('Rincón X', 2), FloorKind.baldosa);
    });

    test('en modo oscuro los pisos se atenúan', () {
      for (final k in FloorKind.values) {
        expect(
          floorTone(k, 0, Brightness.dark).computeLuminance(),
          lessThan(floorTone(k, 0, Brightness.light).computeLuminance()),
        );
      }
    });

    test('los casos reales dan al menos 3 tipos de piso distintos', () {
      for (final name in ['caso-principiante-s1', 'caso-casual-s1']) {
        final pc = loadCase(name);
        final kinds = {
          for (var i = 0; i < pc.map.areas.length; i++)
            floorKindFor(pc.map.areas[i].nameEs, i),
        };
        expect(kinds.length, greaterThanOrEqualTo(3), reason: name);
      }
    });

    for (final skinId in ['ilustrada', 'papel']) {
      test('$skinId pinta retratos, fichas y notas de los 8 personajes', () {
        for (final mode in Brightness.values) {
          final skin = SkinRegistry.create(skinId, mode);
          final rec = PictureRecorder();
          final c = Canvas(rec);
          for (var i = 0; i < 8; i++) {
            final st = TokenStyle(
              charIndex: i,
              initial: 'ABCDEFGH'[i],
              female: i.isEven,
              victim: i == 4,
            );
            skin.paintPortrait(
              c,
              Rect.fromLTWH(i * 70.0, 0, 64, 64),
              st,
              selected: i == 1,
            );
            skin.paintTokenShadow(c, Offset(i * 70.0 + 30, 120), 20);
            skin.paintToken(c, Offset(i * 70.0 + 30, 120), 20, st);
            skin.paintCandidate(c, Offset(i * 70.0 + 30, 170), 18, st, 1);
          }
          skin.paintCross(c, const Rect.fromLTWH(0, 200, 50, 50), 1);
          skin.paintStar(c, const Offset(100, 230), 20, 1);
          final pic = rec.endRecording();
          expect(pic.approximateBytesUsed, greaterThan(0));
          pic.dispose();
        }
      });
    }
  });
}

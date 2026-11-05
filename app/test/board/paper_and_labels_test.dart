import 'dart:math' as math;
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enigmatrix/src/board/scene/art_parts.dart';
import 'package:enigmatrix/src/board/scene/art_skin.dart';
import 'package:enigmatrix/src/board/scene/board_geometry.dart';
import 'package:enigmatrix/src/board/scene/floors.dart';
import 'package:enigmatrix/src/board/scene/furniture_art.dart';
import 'package:enigmatrix/src/board/scene/paper_edges.dart';
import 'package:enigmatrix/src/board/scene/paper_floors.dart';
import 'package:enigmatrix/src/board/scene/paper_skin.dart';
import 'package:enigmatrix/src/board/scene/skins.dart';

import '../support/board_rig.dart';
import '../support/game_ui.dart' show loadRoboto;

/// Geometría del tablero tal como la deja la pantalla de 360 px de ancho.
BoardGeometry _phoneGeometry(int n) =>
    BoardGeometry.fit(n, const Size(360, 348), margin: 12, marginY: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRoboto);

  group('el tablero a todo el ancho', () {
    test('en 360 px de ancho mide 336 px (12 px a cada lado)', () {
      for (final n in [6, 8]) {
        final g = _phoneGeometry(n);
        expect(g.board.width, closeTo(336, 1e-9));
        expect(g.board.left, closeTo(12, 1e-9));
        expect(g.cell, closeTo(336 / n, 1e-9));
      }
      expect(_phoneGeometry(6).cell, closeTo(56, 1e-9));
      expect(_phoneGeometry(8).cell, closeTo(42, 1e-9));
    });

    test('una casilla del 8x8 es lo bastante grande para tocarla', () {
      expect(_phoneGeometry(8).cell, greaterThanOrEqualTo(42));
    });
  });

  group('rótulos de habitación', () {
    ArtSkin skin() => SkinRegistry.create('papel', Brightness.light) as ArtSkin;

    for (final name in ['caso-principiante-s1', 'caso-casual-s1']) {
      for (final skinId in ['ilustrada', 'papel']) {
        test(
          '$name ($skinId): 11 px o más, dentro de su habitación y sin montarse',
          () {
            final pc = loadCase(name);
            final g = _phoneGeometry(pc.map.size);
            final art =
                SkinRegistry.create(skinId, Brightness.light) as ArtSkin;
            final labels = art.roomLabels(g, pc.map);
            expect(labels, hasLength(pc.map.areas.length));
            final occupied = <int>{for (final o in pc.map.objects) ...o.cells};

            for (final l in labels) {
              final area = pc.map.areas.firstWhere((a) => a.id == l.areaId);
              expect(l.fontSize, greaterThanOrEqualTo(11), reason: l.text);
              // Dentro del tablero.
              expect(g.board.contains(l.pill.topLeft), isTrue, reason: l.text);
              expect(
                g.board.contains(l.pill.bottomRight),
                isTrue,
                reason: l.text,
              );
              // Todas las casillas bajo la pastilla son de su propia habitación.
              for (final x in [
                l.pill.left + 1,
                l.pill.center.dx,
                l.pill.right - 1,
              ]) {
                final c = g.cellAt(Offset(x, l.pill.center.dy));
                expect(c, isNotNull);
                expect(
                  area.cells,
                  contains(c),
                  reason: '${l.text} invade otra habitación',
                );
                expect(
                  occupied.contains(c),
                  isFalse,
                  reason: '${l.text} tapa un mueble',
                );
              }
            }
            // Nunca se montan entre sí.
            for (var i = 0; i < labels.length; i++) {
              for (var j = i + 1; j < labels.length; j++) {
                expect(
                  labels[i].pill.overlaps(labels[j].pill),
                  isFalse,
                  reason: '${labels[i].text} / ${labels[j].text}',
                );
              }
            }
          },
        );
      }
    }

    test('si el nombre no cabe, se abrevia (y sigue sin montarse)', () {
      // Una cuadrícula de 8x8 con habitaciones de un solo renglón y nombres largos.
      final areas = <Area>[];
      for (var r = 0; r < 8; r++) {
        areas.add(
          Area(
            id: 'a$r',
            nameEs: 'el Departamento de Investigación $r',
            cells: [for (var c = 0; c < 8; c++) r * 8 + c],
          ),
        );
      }
      final map = GameMap(
        id: 'm',
        nameEs: 'x',
        size: 8,
        areas: areas,
        objects: const [],
      );
      final g = _phoneGeometry(8);
      final labels = skin().roomLabels(g, map);
      expect(labels.any((l) => l.abbreviated), isTrue);
      for (final l in labels) {
        expect(l.fontSize, greaterThanOrEqualTo(11));
        expect(l.text.length, greaterThanOrEqualTo(3));
      }
      for (var i = 0; i < labels.length; i++) {
        for (var j = i + 1; j < labels.length; j++) {
          expect(labels[i].pill.overlaps(labels[j].pill), isFalse);
        }
      }
    });

    test('una habitación con una sola casilla libre se acomoda en ella', () {
      final map = GameMap(
        id: 'm',
        nameEs: 'x',
        size: 6,
        areas: [
          Area(id: 'a', nameEs: 'la Cocina', cells: [0, 1, 2]),
          Area(
            id: 'b',
            nameEs: 'el Resto',
            cells: [for (var i = 3; i < 36; i++) i],
          ),
        ],
        objects: [
          MapObject(id: 'o', type: ObjectType.mesa, cells: const [0, 1]),
        ],
      );
      final g = _phoneGeometry(6);
      final l = skin().roomLabels(g, map).firstWhere((l) => l.areaId == 'a');
      expect(g.cellAt(l.pill.center), 2);
      expect(l.pill.left, greaterThanOrEqualTo(g.cellRect(2).left));
      expect(l.pill.right, lessThanOrEqualTo(g.cellRect(2).right));
    });
  });

  group('bordes de papel', () {
    test('el contorno de una habitación en L tiene 6 esquinas', () {
      // Casillas 0,1,2 (arriba) y 8 (debajo de la primera) en un 8x8.
      final loops = gridOutline([0, 1, 2, 8], 8);
      expect(loops, hasLength(1));
      expect(loops.single, hasLength(6));
    });

    test('un anillo tiene el contorno de afuera y el hueco', () {
      final ring = [0, 1, 2, 8, 10, 16, 17, 18];
      final loops = gridOutline(ring, 8);
      expect(loops, hasLength(2));
    });

    test(
      'el borde rasgado es irregular, siempre igual para una semilla y cambia con otra',
      () {
        final loops = gridOutline([for (var c = 0; c < 3; c++) c], 6);
        Path make(int seed) => tornPath(
          loops,
          origin: const Offset(12, 10),
          cell: 56,
          seed: seed,
          amp: 1.5,
        );
        final a = make(3), a2 = make(3), b = make(4);
        expect(a.getBounds(), a2.getBounds());
        expect(a.getBounds(), isNot(b.getBounds()));
        // Más largo que el contorno recto: es dentado.
        double length(Path p) =>
            p.computeMetrics().fold(0.0, (s, m) => s + m.length);
        const perimeter = 2 * (3 * 56 + 56);
        expect(length(a), greaterThan(perimeter * 1.01));
        // Pero no se aleja más de unos píxeles de la forma real.
        final nominal = const Rect.fromLTWH(12, 10, 168, 56);
        expect(
          nominal.inflate(4).expandToInclude(a.getBounds()),
          nominal.inflate(4),
        );
      },
    );
  });

  group('Papel se distingue de Ilustrada', () {
    test('los pisos son cartulina con estampado, no madera ni piedra', () {
      expect(PaperPattern.values, hasLength(4));
      expect({
        for (final k in FloorKind.values) paperPatternFor(k),
      }, hasLength(4));
      // Cada habitación tiene su color de cartulina.
      for (final mode in Brightness.values) {
        final tones = {for (var i = 0; i < 5; i++) cardstockTone(i, mode)};
        expect(tones, hasLength(5));
      }
      for (var i = 0; i < 8; i++) {
        expect(
          cardstockTone(i, Brightness.dark).computeLuminance(),
          lessThan(cardstockTone(i, Brightness.light).computeLuminance()),
        );
        expect(
          cardstockTone(i, Brightness.dark).computeLuminance(),
          greaterThan(0.01),
        );
      }
    });

    test(
      'el grosor visible es de 2 a 3 px y el borde blanco de recorte se nota',
      () {
        for (final cell in [42.0, 56.0]) {
          final depth = PaperSkin.pieceDepth(cell);
          expect(depth, inInclusiveRange(2.0, 3.2), reason: 'casilla $cell');
        }
        final skin = SkinRegistry.create('papel', Brightness.light) as ArtSkin;
        final r = skin.furnitureRenderer as PaperRenderer;
        expect(r.depth * 42, inInclusiveRange(2.0, 3.2)); // grosor de un mueble
        expect(r.border * 42, greaterThanOrEqualTo(1.8)); // borde blanco
        expect(r.fibers, greaterThanOrEqualTo(12));
      },
    );

    test(
      'los recortes giran un poco al azar: hasta 1,5 grados y siempre igual',
      () {
        final angles = <double>[];
        for (var i = 0; i < 60; i++) {
          final a = ArtSkin.cutoutTilt('mueble-$i');
          expect(a.abs(), lessThanOrEqualTo(1.5 * math.pi / 180 + 1e-12));
          expect(ArtSkin.cutoutTilt('mueble-$i'), a);
          angles.add(a);
        }
        // No todos iguales.
        expect(angles.toSet().length, greaterThan(30));
        expect(angles.any((a) => a > 0.01), isTrue);
        expect(angles.any((a) => a < -0.01), isTrue);
      },
    );

    testWidgets('el mismo tablero se ve muy distinto en las dos pieles', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final pc = loadCase('caso-casual-s1');
        const size = Size(360, 348);
        final g = _phoneGeometry(8);

        Future<List<int>> render(String skinId) async {
          final skin = SkinRegistry.create(skinId, Brightness.light);
          final rec = PictureRecorder();
          skin.paintBackdrop(Canvas(rec), size, g, pc.map);
          final img = await rec.endRecording().toImage(360, 348);
          return (await img.toByteData())!.buffer.asUint8List();
        }

        final a = await render('ilustrada');
        final b = await render('papel');
        var diff = 0;
        for (var i = 0; i < a.length; i += 4) {
          final d =
              (a[i] - b[i]).abs() +
              (a[i + 1] - b[i + 1]).abs() +
              (a[i + 2] - b[i + 2]).abs();
          if (d > 60) diff++;
        }
        final total = a.length / 4;
        expect(
          diff / total,
          greaterThan(0.6),
          reason: 'las pieles se parecen demasiado',
        );

        // La mesa de kraft se ve alrededor del tablero: el borde del escenario
        // es marrón de embalaje (rojo > verde > azul y bastante saturado).
        int px(List<int> bytes, int x, int y) => (y * 360 + x) * 4;
        final i = px(b, 4, 174);
        expect(b[i], greaterThan(b[i + 1]));
        expect(b[i + 1], greaterThan(b[i + 2]));
        expect(b[i] - b[i + 2], greaterThan(40));
      });
    });
  });

  group('muebles', () {
    FurnitureModel build(ObjectType t, [double w = 0.78, double h = 0.78]) =>
        buildFurniture(t, w, h, Brightness.light);

    test('la silla tiene respaldo, asiento, cojín y patas, y es chica', () {
      final chair = build(ObjectType.silla);
      final bases = chair.parts.where((p) => p.role == PartRole.base).toList();
      expect(bases.length, greaterThanOrEqualTo(2)); // respaldo y asiento
      // El respaldo es lo más alto y ancho: sube hasta el borde de arriba.
      final top = bases.map((p) => p.path.getBounds().top).reduce(math.min);
      expect(top, lessThan(0.03));
      expect(
        bases.map((p) => p.path.getBounds().width).reduce(math.max),
        closeTo(0.78, 0.01),
      );
      // Patas: al menos dos piezas oscuras abajo y asoman bajo el asiento.
      final legs = chair.parts.where(
        (p) =>
            p.role == PartRole.face &&
            p.path.getBounds().height < 0.2 &&
            p.path.getBounds().bottom > 0.6,
      );
      expect(legs.length, greaterThanOrEqualTo(2));
      expect(chair.parts.length, greaterThanOrEqualTo(9));
    });

    test('silla, sillón y sofá se distinguen: colores y formas propias', () {
      final chair = build(ObjectType.silla);
      final armchair = build(ObjectType.sillon);
      final sofa = build(ObjectType.sofa, 1.78, 0.78);
      Set<int> colors(FurnitureModel m) => {
        for (final p in m.parts) p.color.toARGB32(),
      };
      // Ninguna comparte su color principal con las otras.
      Color main(FurnitureModel m) =>
          m.parts.firstWhere((p) => p.role == PartRole.base).color;
      expect(main(chair), isNot(main(armchair)));
      expect(main(armchair), isNot(main(sofa)));
      expect(main(chair), isNot(main(sofa)));
      // El sillón y el sofá no usan los tonos de madera ni el cojín de la silla.
      expect(colors(chair).intersection(colors(armchair)), isEmpty);
      expect(colors(chair).intersection(colors(sofa)), isEmpty);
      // El sillón es el único con botones del respaldo y cojincito en diagonal:
      // más piezas de detalle que la silla.
      expect(
        armchair.parts.where((p) => p.role == PartRole.detail).length,
        greaterThanOrEqualTo(3),
      );
      // El sofá de dos plazas es el doble de ancho que la silla.
      final sofaW = sofa.silhouettes
          .map((p) => p.getBounds().width)
          .reduce(math.max);
      final chairW = chair.silhouettes
          .map((p) => p.getBounds().width)
          .reduce(math.max);
      expect(sofaW, greaterThan(chairW * 2));
    });

    testWidgets('la silla se dibuja distinta del sillón en las dos pieles', (
      tester,
    ) async {
      await tester.runAsync(() async {
        GameMap map(ObjectType t) => GameMap(
          id: 'm',
          nameEs: 'x',
          size: 6,
          areas: [
            Area(
              id: 's',
              nameEs: 'la Sala',
              cells: List.generate(36, (i) => i),
            ),
          ],
          objects: [
            MapObject(id: 'o', type: t, cells: const [14]),
          ],
        );
        for (final skinId in ['ilustrada', 'papel']) {
          final skin = SkinRegistry.create(skinId, Brightness.light);
          const size = Size(240, 240);
          final g = BoardGeometry.fit(6, size, margin: 0);
          Future<List<int>> render(ObjectType t) async {
            final rec = PictureRecorder();
            skin.paintBackdrop(Canvas(rec), size, g, map(t));
            final img = await rec.endRecording().toImage(240, 240);
            return (await img.toByteData())!.buffer.asUint8List();
          }

          final chair = await render(ObjectType.silla);
          final armchair = await render(ObjectType.sillon);
          var diff = 0;
          for (var i = 0; i < chair.length; i += 4) {
            if ((chair[i] - armchair[i]).abs() +
                    (chair[i + 1] - armchair[i + 1]).abs() >
                60) {
              diff++;
            }
          }
          expect(
            diff,
            greaterThan(400),
            reason: '$skinId: silla y sillón casi iguales',
          );
        }
      });
    });
  });
}

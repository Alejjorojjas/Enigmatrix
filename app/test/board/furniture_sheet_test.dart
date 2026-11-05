/// Lámina de muestra de los muebles: los 18 objetos en un tablero de 9x9 de
/// 360 px (el ancho de un teléfono chico), en las dos pieles y los dos modos.
/// Siempre comprueba que se puede pintar y pasar a imagen; si la variable de
/// entorno `ENX_MUEBLES_PNG` trae una ruta, guarda además la lámina ahí (para
/// revisarla a ojo; no vive en el repo).
library;

import 'dart:io';
import 'dart:ui';

import 'package:enigmatrix_engine/enigmatrix_engine.dart';
import 'package:enigmatrix/src/board/scene/board_geometry.dart';
import 'package:enigmatrix/src/board/scene/skins.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un mapa de 9x9 con una sola sala y los 18 muebles, sin pegarse entre sí.
GameMap _sheetMap() {
  const layout = <(ObjectType, List<int>)>[
    (ObjectType.silla, [0]),
    (ObjectType.sillon, [2]),
    (ObjectType.sofa, [4, 5]),
    (ObjectType.cama, [7, 8]),
    (ObjectType.alfombra, [18, 19]),
    (ObjectType.mesa, [21, 22]),
    (ObjectType.tv, [24]),
    (ObjectType.planta, [26]),
    (ObjectType.arbusto, [36]),
    (ObjectType.armario, [38, 39]),
    (ObjectType.caja, [41]),
    (ObjectType.lavadora, [43]),
    (ObjectType.piano, [54, 55]),
    (ObjectType.barra, [57, 58]),
    (ObjectType.perchero, [60]),
    (ObjectType.banera, [62]),
    (ObjectType.nevera, [72]),
    (ObjectType.chimenea, [74]),
  ];
  return GameMap(
    id: 'lamina',
    nameEs: 'Lámina',
    size: 9,
    areas: [
      Area(id: 'sala', nameEs: 'la Biblioteca', cells: List.generate(81, (i) => i)),
    ],
    objects: [
      for (final (t, cells) in layout)
        MapObject(id: t.name, type: t, cells: cells),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la lámina cubre los 18 tipos de objeto', () {
    final types = {for (final o in _sheetMap().objects) o.type};
    expect(types, ObjectType.values.toSet());
    expect(ObjectType.values, hasLength(18));
  });

  testWidgets('pinta la lámina con los 18 muebles en 2 pieles x 2 modos', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final map = _sheetMap();
      const board = Size(360, 360);
      const ratio = 2.0;
      final rec = PictureRecorder();
      final canvas = Canvas(rec)..scale(ratio);
      var i = 0;
      for (final skinId in ['ilustrada', 'papel']) {
        for (final mode in Brightness.values) {
          final skin = SkinRegistry.create(skinId, mode);
          final g = BoardGeometry.fit(9, board, margin: 12);
          canvas.save();
          canvas.translate((i % 2) * board.width, (i ~/ 2) * board.height);
          canvas.clipRect(Offset.zero & board);
          skin.paintBackdrop(canvas, board, g, map);
          canvas.restore();
          i++;
        }
      }
      final img = await rec.endRecording().toImage(
        (board.width * 2 * ratio).round(),
        (board.height * 2 * ratio).round(),
      );
      final bytes = await img.toByteData(format: ImageByteFormat.png);
      expect(bytes, isNotNull);
      expect(bytes!.lengthInBytes, greaterThan(1000));
      final out = Platform.environment['ENX_MUEBLES_PNG'];
      if (out != null && out.isNotEmpty) {
        File(out).writeAsBytesSync(bytes.buffer.asUint8List());
      }
    });
  });
}

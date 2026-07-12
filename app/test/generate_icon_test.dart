/// Generador del icono de la app: rasteriza PaperLogo a PNG en assets/icon/.
/// Se corre a propósito con: flutter test test/generate_icon_test.dart
/// Luego: dart run flutter_launcher_icons
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:enigmatrix/src/ui/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _renderToPng(Widget widget, double size, String path,
    WidgetTester tester) async {
  await tester.binding.setSurfaceSize(Size.square(size));
  tester.view.physicalSize = Size.square(size);
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: SizedBox.square(dimension: size, child: widget),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('genera los PNG del icono', (tester) async {
    // Icono completo (placa kraft + lupa) para iOS y legacy Android.
    await _renderToPng(
        const ColoredBox(
            color: Color(0xFFE9DCBE),
            child: Center(child: PaperLogo(size: 1024))),
        1024,
        'assets/icon/icon_full.png',
        tester);
    // Foreground adaptativo Android: lupa sin placa, con margen de zona
    // segura (el sistema recorta ~66% del centro).
    await _renderToPng(
        const Center(child: PaperLogo(size: 560, withPlate: false)),
        1024,
        'assets/icon/icon_fg.png',
        tester);
    expect(File('assets/icon/icon_full.png').existsSync(), isTrue);
    expect(File('assets/icon/icon_fg.png').existsSync(), isTrue);
  });
}

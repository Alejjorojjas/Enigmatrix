/// Vigila los archivos fuente del icono de la app (diseño AB3-a, 13-11-2026).
///
/// Antes este archivo redibujaba el icono viejo cada vez que corrían las
/// pruebas. Ahora solo lee: los PNG salen del diseño aprobado por Alejandro y
/// de ellos se generan los iconos con `dart run flutter_launcher_icons`.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

({int width, int height, int colorType}) _pngHeader(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(data.getUint32(0), 0x89504E47, reason: '$path no es un PNG');
  return (
    width: data.getUint32(16),
    height: data.getUint32(20),
    colorType: bytes[25],
  );
}

void main() {
  test('el icono completo mide 1024 px y no tiene transparencia (Apple)', () {
    final h = _pngHeader('assets/icon/icon_full.png');
    expect((h.width, h.height), (1024, 1024));
    expect(h.colorType, 2, reason: 'debe ser RGB, sin canal alfa');
  });

  test('el primer plano de Android mide 1024 px y tiene transparencia', () {
    final h = _pngHeader('assets/icon/icon_fg.png');
    expect((h.width, h.height), (1024, 1024));
    expect(h.colorType, 6, reason: 'debe ser RGBA');
  });
}

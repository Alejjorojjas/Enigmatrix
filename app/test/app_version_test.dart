import 'dart:io';

import 'package:enigmatrix/src/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kAppVersion coincide con la línea version de pubspec.yaml', () {
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(line.substring('version:'.length).trim(), kAppVersion);
  });
}

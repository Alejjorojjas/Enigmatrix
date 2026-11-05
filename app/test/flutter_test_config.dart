/// Configuración común de todas las pruebas. Las tipografías de la interfaz
/// (Baloo 2, Quicksand y Patrick Hand) vienen empaquetadas en la app y
/// `flutter test` las carga del pubspec; además se carga Roboto (que viene con
/// el SDK de Flutter) para el texto del tablero, que usa la letra por omisión,
/// así los anchos que se miden son los de verdad.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/game_ui.dart' show loadAppFonts, loadRoboto;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadRoboto();
  await loadAppFonts();
  await testMain();
}

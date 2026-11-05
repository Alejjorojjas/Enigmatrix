/// Configuración común de todas las pruebas: sin red no se pueden bajar las
/// tipografías de google_fonts, así que la interfaz usa la letra por omisión
/// (Roboto, que viene con el SDK de Flutter) para medir los anchos de verdad.
library;

import 'dart:async';

import 'package:enigmatrix/src/ui/skin_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/game_ui.dart' show loadRoboto;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  UiFonts.useWebFonts = false;
  GoogleFonts.config.allowRuntimeFetching = false;
  await loadRoboto();
  await testMain();
}

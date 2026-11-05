/// Herramientas de desarrollo (H-66): banco de pruebas, copia del feedback de
/// playtest y medidor de FPS. Quedan detrás de una bandera de compilación:
/// el APK normal no las trae a la vista; el de pruebas se compila con
/// `--dart-define=ENX_DEV=true`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true solo si se compiló con `--dart-define=ENX_DEV=true`.
const bool kEnxDev = bool.fromEnvironment('ENX_DEV', defaultValue: false);

/// Si las herramientas de desarrollo están activas. Los tests lo
/// sobreescriben para probar las dos situaciones.
final devToolsProvider = Provider<bool>((ref) => kEnxDev);

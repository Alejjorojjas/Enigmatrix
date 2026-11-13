/// Herramientas de desarrollo (H-66): banco de pruebas, copia del feedback de
/// playtest y medidor de FPS. Quedan detrás de una bandera de compilación:
/// el APK normal no las trae a la vista; el de pruebas se compila con
/// `--dart-define=ENX_DEV=true`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true solo si se compiló con `--dart-define=ENX_DEV=true`.
const bool kEnxDev = bool.fromEnvironment('ENX_DEV', defaultValue: false);

/// ÚNICO punto de decisión sobre lo simulado (pregunta 18, decidida por el
/// dueño): la versión de tienda (sin ENX_DEV) NO muestra pantallas ni datos
/// DEMO (Tienda, Premium, Ranking, vidas, racha, protectores, puntos de la
/// semana, estadísticas simuladas ni ajustes "Próximamente"). La de pruebas
/// internas (ENX_DEV=true) los muestra con sus etiquetas DEMO.
const bool kShowSimulated = kEnxDev;

/// Si se muestra lo simulado. Los widgets leen ESTE provider; los tests lo
/// sobreescriben con `showSimulatedProvider.overrideWithValue(true/false)`
/// porque [kShowSimulated] es const y no se puede cambiar en un test.
final showSimulatedProvider = Provider<bool>((ref) => kShowSimulated);

/// Si las herramientas de desarrollo están activas. Los tests lo
/// sobreescriben para probar las dos situaciones.
final devToolsProvider = Provider<bool>((ref) => kEnxDev);

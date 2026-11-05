/// Vibración con HapticFeedback de Flutter. Es la alternativa simple que pide
/// el informe gráfico: funciona en todos los Android sin comprobar
/// primitivas. Los patrones (varios pulsos separados) los arma el director.
library;

import 'package:flutter/services.dart';

import '../feedback/feedback_director.dart';
import '../feedback/feedback_plan.dart';

class FlutterHapticService implements HapticSink {
  @override
  void pulse(HapticKind kind) {
    switch (kind) {
      case HapticKind.selection:
        HapticFeedback.selectionClick();
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}

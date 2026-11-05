/// Medidor de FPS: apagado por defecto y activable en Opciones. Cuando está
/// activo va en la barra superior (debajo del cronómetro), FUERA del tablero,
/// con letra pequeña porque es de depuración. Tras la secuencia de resolver, el
/// mínimo y el promedio salen en un aviso con el botón de copiar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../board/fps_recorder.dart';
import 'dev_texts.dart';
import 'skin_theme.dart';

/// Línea con los cuadros por segundo en vivo (se pone bajo el cronómetro).
class FpsReadout extends StatelessWidget {
  const FpsReadout({super.key, required this.monitor});

  final FpsMonitor monitor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final rec = monitor.recorder;
        final pal = context.pal;
        final fps = rec.liveFps;
        final color = fps >= 55
            ? pal.good
            : (fps >= 30 ? pal.medal(0) : pal.danger);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fps > 0 ? DevTexts.fpsLive(fps.round()) : DevTexts.fpsNone,
              key: const ValueKey('fps-en-vivo'),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (rec.recording) ...[
              const SizedBox(width: 4),
              Icon(Icons.fiber_manual_record, size: 9, color: pal.danger),
              Text(
                DevTexts.fpsMeasuring,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.0,
                  color: pal.onPill.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Aviso con el resultado de la secuencia de resolver y botón para copiarlo.
void showFpsReport(BuildContext context, FpsReport r) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          DevTexts.fpsSolve(
            r.minFps.toStringAsFixed(0),
            r.averageFps.toStringAsFixed(0),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: DevTexts.fpsCopyResult,
          textColor: context.pal.accent,
          onPressed: () => Clipboard.setData(ClipboardData(text: r.toText())),
        ),
      ),
    );
}

Future<void> copyReport(BuildContext context, FpsReport r) async {
  await Clipboard.setData(ClipboardData(text: r.toText()));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(DevTexts.fpsCopied),
        duration: Duration(seconds: 2),
      ),
    );
}

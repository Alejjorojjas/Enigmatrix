/// Textos de las herramientas SOLO de desarrollo (banco de pruebas, feedback
/// de playtest y medidor de FPS). Quedan detrás de la bandera ENX_DEV (H-66) y
/// NO se traducen: por eso no están en el .arb (H-63).
library;

abstract final class DevTexts {
  // Banco de pruebas.
  static const bankTitle = 'Banco de pruebas';
  static const bankSubtitle =
      'Solo para desarrollo: estos casos no forman parte del juego.';
  static const bankDone = 'Resuelto';
  static const bankOpen = 'En curso';
  static const bankError = 'No se pudo cargar el banco de pruebas';
  static String bankRowSemantics(
    String title,
    String difficulty,
    int size,
    String? state,
  ) =>
      '$title, $difficulty, tablero $size por $size'
      '${state == null ? '' : ', $state'}';
  static String bankRowSubtitle(String difficulty, int size, String? state) =>
      '$difficulty · $size×$size${state == null ? '' : ' · $state'}';

  // Entrada en Configuración.
  static const bankEntryTitle = 'Banco de pruebas (desarrollo)';
  static const bankEntryBody =
      'Los 20 casos de prueba, para revisar el motor. No son parte del juego.';
  static const bankEntryOpen = 'Abrir banco de pruebas';

  // Feedback de playtest.
  static const feedbackCopy = 'Copiar feedback de playtest';
  static const feedbackCopied =
      'Feedback copiado al portapapeles: pégalo en el chat de Claude para '
      'calibrar el generador';
  static const feedbackTitle = 'FEEDBACK DE PLAYTEST';
  static const feedbackHint = '¿Pistas confusas? ¿Dificultad justa?…';

  // Medidor de FPS.
  static const fpsMenu = 'Medidor de FPS (pruebas)';
  static const fpsMeasuring = 'midiendo';
  static const fpsCopyResult = 'Copiar resultado';
  static const fpsCopied = 'Resultado copiado';
  static String fpsLive(int fps) => '$fps fps';
  static const fpsNone = '-- fps';
  static String fpsSolve(String min, String avg) =>
      'Resolver: mín $min · prom $avg';
}

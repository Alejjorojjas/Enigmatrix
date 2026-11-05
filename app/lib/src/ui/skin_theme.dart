/// Tema de TODA la interfaz de Flutter (ronda 4.2, H-59): inicio, caminos,
/// victoria, diálogos, hojas y la partida. Los colores NO están aquí: salen de
/// la paleta de la piel activa en el modo activo ([SkinPalette], en
/// `board/scene/`). Este archivo solo la convierte en `ThemeData` y la expone
/// a los widgets con `context.pal`, `context.display(...)` y compañía.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../board/scene/palette.dart';
import '../board/scene/skins.dart';

/// La paleta y el estilo de recuadros de la piel activa, dentro del tema.
class SkinTheme extends ThemeExtension<SkinTheme> {
  const SkinTheme({
    required this.skinId,
    required this.palette,
    required this.chrome,
  });

  final String skinId;
  final SkinPalette palette;
  final ChromeKind chrome;

  @override
  SkinTheme copyWith({
    String? skinId,
    SkinPalette? palette,
    ChromeKind? chrome,
  }) => SkinTheme(
    skinId: skinId ?? this.skinId,
    palette: palette ?? this.palette,
    chrome: chrome ?? this.chrome,
  );

  /// Los cambios de piel y de modo se ven de una vez (sin mezclar colores a
  /// medio camino: el tablero también cambia de golpe).
  @override
  SkinTheme lerp(ThemeExtension<SkinTheme>? other, double t) =>
      other is SkinTheme && t >= 0.5 ? other : this;
}

extension SkinContext on BuildContext {
  /// La piel del tema. Si la pantalla se monta fuera de la app (pruebas con
  /// un `MaterialApp` pelado), se usa la piel de arranque según el brillo.
  SkinTheme get skinTheme {
    final t = Theme.of(this);
    final ext = t.extension<SkinTheme>();
    if (ext != null) return ext;
    final spec = SkinRegistry.specs.first;
    return SkinTheme(
      skinId: spec.id,
      palette: spec.palette(t.brightness),
      chrome: spec.chrome,
    );
  }

  SkinPalette get pal => skinTheme.palette;
}

/// Tamaño mínimo de cualquier texto de la interfaz (doc 11 y ADR-0013).
const double kMinFont = 13;

/// Tipografías de la interfaz. Titulares en Baloo 2; cuerpo en Quicksand; la
/// piel Papel usa además Patrick Hand (manuscrita) para las notas. Ningún
/// texto baja de [kMinFont].
extension SkinText on BuildContext {
  /// Titular.
  TextStyle display(double size, {Color? color, double spacing = 0}) =>
      UiFonts.baloo(
        fontSize: math.max(kMinFont, size),
        fontWeight: FontWeight.w700,
        color: color ?? pal.text,
        letterSpacing: spacing,
        height: 1.15,
      );

  /// Cuerpo y botones.
  TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double spacing = 0,
  }) => UiFonts.quicksand(
    fontSize: math.max(kMinFont, size),
    fontWeight: weight,
    color: color ?? pal.text,
    letterSpacing: spacing,
    height: 1.25,
  );

  /// Nota o frase corta: manuscrita en Papel, redondeada en Ilustrada.
  TextStyle note(double size, {Color? color}) {
    final c = color ?? pal.textDim;
    final s = math.max(kMinFont, size);
    return skinTheme.chrome == ChromeKind.paper
        ? UiFonts.hand(fontSize: s + 1, color: c, height: 1.25)
        : UiFonts.quicksand(
            fontSize: s,
            fontWeight: FontWeight.w600,
            color: c,
            height: 1.3,
          );
  }
}

/// Colores derivados de la paleta de la piel para la interfaz (dificultades,
/// mundos, medallas y texto sobre colores). Nada de valores sueltos en las
/// pantallas.
extension SkinPaletteUi on SkinPalette {
  /// Texto secundario que se lee también sobre el fondo de la pantalla.
  Color get softText => Color.lerp(text, bg, 0.28)!;

  /// Color de texto o ícono legible sobre [c].
  Color onColor(Color c) {
    // El más legible de los dos: el oscuro (pill) o el claro (onPill).
    double ratio(Color a) {
      final la = a.computeLuminance(), lc = c.computeLuminance();
      return (math.max(la, lc) + 0.05) / (math.min(la, lc) + 0.05);
    }

    return ratio(pill) >= ratio(onPill) ? pill : onPill;
  }

  /// Color de una dificultad.
  Color difficulty(String label) => switch (label) {
    'principiante' => good,
    'casual' => characters[5],
    'intermedio' => characters[3],
    'experto' => danger,
    'elite' => characters[4],
    _ => textDim,
  };

  /// Color de un mundo (por su número, desde 0).
  Color world(int index) => characters[(index * 2 + 1) % characters.length];

  /// Medallas del ranking: oro, plata y bronce.
  Color medal(int place) => switch (place) {
    0 => characters[3],
    1 => characters[7],
    _ => characters[1],
  };
}

/// Brillo que corresponde a la elección del jugador (Sistema, Claro u
/// Oscuro) y al brillo del teléfono.
Brightness resolveBrightness(ThemeMode mode, Brightness platform) =>
    switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };

class SkinUi {
  const SkinUi._();

  /// Tamaño mínimo de toque (doc 11 de accesibilidad: 48 dp).
  static const minTouch = 48.0;

  static final Map<String, ThemeData> _cache = {};

  /// Tema para una piel en un modo (se guarda para no reconstruirlo).
  static ThemeData theme(String skinId, Brightness mode) =>
      _cache.putIfAbsent('$skinId|${mode.name}', () => _build(skinId, mode));

  static ThemeData _build(String skinId, Brightness mode) {
    final spec = SkinRegistry.spec(skinId);
    final p = spec.palette(mode);
    final scheme = ColorScheme(
      brightness: mode,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: p.onPill,
      surface: p.surface,
      onSurface: p.text,
    );
    final base = ThemeData(
      brightness: mode,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
    );
    // Quicksand en toda la interfaz; los textos pequeños del tema suben a 13.
    final quick = UiFonts.quicksandTheme(
      base.textTheme,
    ).apply(bodyColor: p.text, displayColor: p.text);
    TextStyle? atLeast(TextStyle? t) =>
        t?.copyWith(fontSize: math.max(kMinFont, t.fontSize ?? kMinFont));
    final text = quick.copyWith(
      bodySmall: atLeast(quick.bodySmall),
      labelSmall: atLeast(quick.labelSmall),
      labelMedium: atLeast(quick.labelMedium),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.line, width: 2),
    );
    return base.copyWith(
      extensions: [SkinTheme(skinId: spec.id, palette: p, chrome: spec.chrome)],
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: IconThemeData(color: p.text),
      dividerTheme: DividerThemeData(color: p.line),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceAlt,
        circularTrackColor: p.surfaceAlt,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        isDense: true,
        counterStyle: UiFonts.quicksand(color: p.textDim, fontSize: kMinFont),
        hintStyle: UiFonts.quicksand(color: p.textDim),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 2.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.text,
        textColor: p.text,
        titleTextStyle: UiFonts.quicksand(
          color: p.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: UiFonts.quicksand(
          color: p.textDim,
          fontSize: kMinFont,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.pill,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: UiFonts.quicksand(color: p.onPill, fontSize: kMinFont),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: UiFonts.quicksand(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: UiFonts.quicksand(
          color: p.text,
          fontSize: 16,
          height: 1.35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(minTouch, minTouch),
          textStyle: UiFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: p.line, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.pill,
        contentTextStyle: UiFonts.quicksand(color: p.onPill, fontSize: 15),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? p.toolActive : p.surfaceAlt,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onToolActive : p.text,
          ),
          side: WidgetStateProperty.all(BorderSide(color: p.line)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.textDim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.all(p.line),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(minTouch, minTouch),
          textStyle: UiFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Fuente de las tipografías de la interfaz: Baloo 2 (titulares), Quicksand
/// (cuerpo) y Patrick Hand (notas manuscritas de la piel Papel), de
/// google_fonts. Con [useWebFonts] apagado (solo en las pruebas, que no tienen
/// red) se usa la letra por omisión, que allí es Roboto.
abstract final class UiFonts {
  static bool useWebFonts = true;

  static TextStyle baloo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => useWebFonts
      ? GoogleFonts.baloo2(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: height,
        )
      : TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: height,
        );

  static TextStyle quicksand({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => useWebFonts
      ? GoogleFonts.quicksand(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: height,
        )
      : TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: height,
        );

  static TextStyle hand({double? fontSize, Color? color, double? height}) =>
      useWebFonts
      ? GoogleFonts.patrickHand(
          fontSize: fontSize,
          color: color,
          height: height,
        )
      : TextStyle(fontSize: fontSize, color: color, height: height);

  static TextTheme quicksandTheme(TextTheme base) =>
      useWebFonts ? GoogleFonts.quicksandTextTheme(base) : base;
}

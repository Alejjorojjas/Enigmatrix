/// Tema de la interfaz de Flutter que rodea al tablero (barra, bandeja,
/// opciones). Los colores NO están aquí: salen de la paleta de la piel activa
/// en el modo activo ([SkinPalette]). Este archivo solo la convierte en
/// `ThemeData` y la expone a los widgets con `context.pal`.
library;

import 'package:flutter/material.dart';

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
  SkinTheme get skinTheme => Theme.of(this).extension<SkinTheme>()!;
  SkinPalette get pal => skinTheme.palette;
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
      onError: const Color(0xFFFFFFFF),
      surface: p.surface,
      onSurface: p.text,
    );
    final base = ThemeData(
      brightness: mode,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
    );
    return base.copyWith(
      extensions: [SkinTheme(skinId: spec.id, palette: p, chrome: spec.chrome)],
      textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
      iconTheme: IconThemeData(color: p.text),
      dividerTheme: DividerThemeData(color: p.line),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: p.text, fontSize: 16, height: 1.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.pill,
        contentTextStyle: TextStyle(color: p.onPill),
        behavior: SnackBarBehavior.floating,
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
        ),
      ),
    );
  }
}

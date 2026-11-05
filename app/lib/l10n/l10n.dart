/// Punto de entrada de los textos traducibles (H-63).
///
/// Todo texto visible al jugador vive en `lib/l10n/app_es.arb` y se lee con
/// `context.l10n.clave`. Donde no hay `BuildContext` (escena de Flame,
/// controladores) se pasa una instancia de [AppLocalizations] explícita.
///
/// Para agregar un idioma: un archivo `app_xx.arb` nuevo en esta carpeta, su
/// `Locale` en [AppLocalizations.supportedLocales] (se genera solo) y
/// `flutter gen-l10n`.
library;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Idioma activo de la app. Hoy solo español (la app lo fuerza).
const kAppLocale = Locale('es');

extension AppL10nContext on BuildContext {
  /// Los textos del idioma activo.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

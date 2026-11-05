/// Ayudas de pruebas para los textos traducibles (H-63): la instancia en
/// español para comparar con lo que se ve en pantalla y los parámetros que
/// todo `MaterialApp` de prueba debe registrar para que `context.l10n`
/// funcione.
library;

import 'package:enigmatrix/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// Los textos en español, como los ve el jugador.
AppLocalizations get l10nEs => lookupAppLocalizations(const Locale('es'));

/// Delegados de localización para `MaterialApp.localizationsDelegates`.
const kL10nDelegates = AppLocalizations.localizationsDelegates;

/// Idiomas para `MaterialApp.supportedLocales`.
const kL10nLocales = AppLocalizations.supportedLocales;

/// Idioma forzado de las pruebas (`MaterialApp.locale`).
const kL10nLocale = kAppLocale;

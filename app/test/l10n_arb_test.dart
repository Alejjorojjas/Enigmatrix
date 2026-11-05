/// Textos traducibles (H-63): el .arb en español es JSON válido, cada clave
/// tiene su descripción y sus placeholders declarados, no quedan claves
/// huérfanas, no se escapó ningún texto de pistas ni de desarrollo al .arb y
/// la app solo ofrece español por ahora.
library;

import 'dart:convert';
import 'dart:io';

import 'package:enigmatrix/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadArb() {
  final raw = File('lib/l10n/app_es.arb').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Claves de mensajes (sin las que empiezan con @).
List<String> _keys(Map<String, dynamic> arb) => [
  for (final k in arb.keys)
    if (!k.startsWith('@')) k,
];

void main() {
  group('app_es.arb', () {
    final arb = _loadArb();
    final keys = _keys(arb);

    test('es JSON válido, en español y con claves camelCase', () {
      expect(arb['@@locale'], 'es');
      expect(keys, isNotEmpty);
      final camel = RegExp(r'^[a-z][a-zA-Z0-9]*$');
      for (final k in keys) {
        expect(camel.hasMatch(k), isTrue, reason: 'clave "$k" no es camelCase');
        expect(arb[k], isA<String>(), reason: 'el valor de "$k" no es texto');
        expect((arb[k] as String).isNotEmpty, isTrue, reason: '"$k" vacío');
      }
    });

    test('cada clave tiene @clave con description no vacía y viceversa', () {
      for (final k in keys) {
        final meta = arb['@$k'];
        expect(meta, isA<Map<String, dynamic>>(), reason: 'falta @$k');
        final desc = (meta as Map<String, dynamic>)['description'];
        expect(
          desc is String && desc.trim().isNotEmpty,
          isTrue,
          reason: '@$k sin description',
        );
      }
      for (final k in arb.keys.where(
        (k) => k.startsWith('@') && k != '@@locale',
      )) {
        expect(arb.containsKey(k.substring(1)), isTrue, reason: '$k sin clave');
      }
    });

    test('los placeholders del texto coinciden con los declarados', () {
      // {nombre} o {nombre, plural, ...}; las llaves de las ramas del plural
      // ("=1{...}", "other{...}") no empiezan con una palabra sola.
      final used = RegExp(r'\{(\w+)\s*[,}]');
      for (final k in keys) {
        final text = arb[k] as String;
        final inText = {for (final m in used.allMatches(text)) m.group(1)!};
        final meta = arb['@$k'] as Map<String, dynamic>;
        final declared =
            ((meta['placeholders'] ?? <String, dynamic>{})
                    as Map<String, dynamic>)
                .keys
                .toSet();
        expect(declared, inText, reason: 'placeholders de "$k"');
      }
    });

    test('los plurales usan un placeholder numérico y la rama other', () {
      for (final k in keys) {
        final text = arb[k] as String;
        if (!text.contains(', plural,')) continue;
        expect(text.contains('other{'), isTrue, reason: '"$k" sin other');
        final name = RegExp(r'\{(\w+), plural,').firstMatch(text)!.group(1)!;
        final ph =
            ((arb['@$k'] as Map<String, dynamic>)['placeholders']
                    as Map<String, dynamic>)[name]
                as Map<String, dynamic>;
        expect(ph['type'], anyOf('int', 'num'), reason: 'plural de "$k"');
      }
    });

    test('no quedan claves huérfanas: todas se usan en lib/', () {
      final source = StringBuffer();
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final p = f.path.replaceAll(r'\', '/');
        if (p.contains('lib/l10n/')) continue;
        source.write(f.readAsStringSync());
      }
      final text = source.toString();
      final orphans = [
        for (final k in keys)
          if (!RegExp('\\b$k\\b').hasMatch(text)) k,
      ];
      expect(orphans, isEmpty, reason: 'claves sin usar: $orphans');
    });

    test(
      'no hay claves de pistas, ni textos de desarrollo ni de bots en el .arb',
      () {
        final all = keys.map((k) => arb[k] as String).join('\n');
        // Las pistas las compone el motor (ClueFormatter), no el .arb.
        expect(keys.where((k) => k.startsWith('clue')), isEmpty);
        // Herramientas solo de desarrollo (DevTexts).
        for (final dev in [
          'Banco de pruebas',
          'playtest',
          'Medidor de FPS',
          'midiendo',
        ]) {
          expect(
            all.toLowerCase().contains(dev.toLowerCase()),
            isFalse,
            reason: dev,
          );
        }
        // Nombres DEMO del ranking.
        expect(all.contains('Sherlock221B'), isFalse);
      },
    );
  });

  group('idiomas', () {
    test('hoy solo hay español y la app lo fuerza', () {
      expect(AppLocalizations.supportedLocales, const [Locale('es')]);
      expect(kAppLocale, const Locale('es'));
    });

    test('hay un .arb por idioma soportado y nada más', () {
      final arbs = [
        for (final f in Directory('lib/l10n').listSync())
          if (f is File && f.path.endsWith('.arb'))
            f.path.replaceAll(r'\', '/').split('/').last,
      ];
      expect(arbs, ['app_es.arb']);
    });
  });
}

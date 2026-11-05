/// Partida guardada (H-55): ida y vuelta del tablero y del JSON `game:<id>`.
library;

import 'dart:convert';

import 'package:enigmatrix/src/game/board_state.dart';
import 'package:enigmatrix/src/game/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tablero con un poco de todo: confirmado con sus X automáticas,
/// candidatos, X manual pequeña y grande.
BoardState _sampleBoard() {
  var b = BoardState.empty();
  b = b.placeConfirmed(0, 'c1', autoXGridSize: 4).board;
  b = b.placeCandidate(5, 'c2').board;
  b = b.placeCandidate(5, 'c3').board;
  b = b.placeX(10, XLevel.small).board;
  b = b.placeX(15, XLevel.large).board;
  return b;
}

SavedGame _sampleGame({List<int>? marks}) => SavedGame(
  elapsed: 125,
  errors: 2,
  savedAt: DateTime.utc(2026, 11, 4, 10, 30),
  board: _sampleBoard(),
  clueMarks: marks ?? const [0, 1, 2, 0],
  autoX: false,
  mapMode: false,
);

void main() {
  group('BoardState.toJson / fromJson', () {
    test('ida y vuelta conserva todas las casillas', () {
      final original = _sampleBoard();
      final copy = BoardState.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(copy.toJson(), original.toJson());
      for (var i = 0; i < 16; i++) {
        final a = original.cell(i), b = copy.cell(i);
        expect(b.confirmed, a.confirmed, reason: 'confirmado en $i');
        expect(b.candidates, a.candidates, reason: 'candidatos en $i');
        expect(b.x, a.x, reason: 'X en $i');
        expect(b.autoXFrom, a.autoXFrom, reason: 'auto-X en $i');
      }
      expect(copy.confirmedCellOf('c1'), 0);
    });

    test('el JSON es determinista y solo guarda casillas con contenido', () {
      final json = _sampleBoard().toJson();
      final cells = json['cells'] as Map<String, dynamic>;
      expect(
        cells.keys.toList(),
        [...cells.keys.map(int.parse).toList()..sort()].map((i) => '$i'),
      );
      expect(cells['5'], {
        'k': ['c2', 'c3'],
      });
      expect(cells['10'], {'x': 'small'});
      expect(cells['15'], {'x': 'large'});
      expect(cells['0'], {'c': 'c1'});
      // Las X automáticas de la fila y la columna del confirmado.
      expect(cells['1'], {
        'a': ['c1'],
      });
      expect(jsonEncode(_sampleBoard().toJson()), jsonEncode(json));
    });

    test('tablero vacío ida y vuelta', () {
      final copy = BoardState.fromJson(BoardState.empty().toJson());
      expect(copy.isEmpty, isTrue);
      expect(copy.toJson(), {'cells': <String, dynamic>{}});
    });

    test('rechaza JSON dañado con FormatException', () {
      expect(() => BoardState.fromJson({}), throwsFormatException);
      expect(() => BoardState.fromJson({'cells': 3}), throwsFormatException);
      expect(
        () => BoardState.fromJson({
          'cells': {'abc': <String, dynamic>{}},
        }),
        throwsFormatException,
      );
      expect(
        () => BoardState.fromJson({
          'cells': {
            '1': {'x': 'enorme'},
          },
        }),
        throwsFormatException,
      );
      expect(
        () => BoardState.fromJson({
          'cells': {
            '1': {
              'k': [1, 2],
            },
          },
        }),
        throwsFormatException,
      );
    });

    test('con cellCount rechaza índices fuera del mapa', () {
      final json = {
        'cells': {
          '16': {'c': 'c1'},
        },
      };
      expect(
        () => BoardState.fromJson(json, cellCount: 16),
        throwsFormatException,
      );
      expect(BoardState.fromJson(json, cellCount: 17).cell(16).confirmed, 'c1');
    });
  });

  group('SavedGame', () {
    test('la clave es "game:<caseId>"', () {
      expect(SavedGame.keyFor('caso-1'), 'game:caso-1');
    });

    test('el JSON sigue el contrato compartido', () {
      final json = _sampleGame().toJson();
      expect(json.keys.toSet(), {
        'v',
        'elapsed',
        'errors',
        'savedAt',
        'board',
        'clueMarks',
        'autoX',
        'mapMode',
      });
      expect(json['v'], 1);
      expect(json['elapsed'], 125);
      expect(json['errors'], 2);
      expect(json['savedAt'], '2026-11-04T10:30:00.000Z');
      expect(json['clueMarks'], [0, 1, 2, 0]);
      expect(json['autoX'], false);
      expect(json['mapMode'], false);
      expect(json['board'], _sampleBoard().toJson());
    });

    test('ida y vuelta por texto', () {
      final copy = SavedGame.decode(
        _sampleGame().encode(),
        cellCount: 16,
        clueCount: 4,
      )!;
      expect(copy.elapsed, 125);
      expect(copy.errors, 2);
      expect(copy.savedAt, DateTime.utc(2026, 11, 4, 10, 30));
      expect(copy.clueMarks, [0, 1, 2, 0]);
      expect(copy.autoX, isFalse);
      expect(copy.mapMode, isFalse);
      expect(copy.board.toJson(), _sampleBoard().toJson());
    });

    test('datos dañados o que no encajan devuelven null', () {
      final ok = _sampleGame().toJson();
      Map<String, dynamic> withField(String k, Object? v) => {...ok, k: v};

      expect(SavedGame.decode('esto no es json'), isNull);
      expect(SavedGame.decode('[1,2]'), isNull);
      expect(SavedGame.fromJson(withField('v', 2)), isNull);
      expect(SavedGame.fromJson(withField('elapsed', -1)), isNull);
      expect(SavedGame.fromJson(withField('elapsed', 'x')), isNull);
      expect(SavedGame.fromJson(withField('errors', null)), isNull);
      expect(SavedGame.fromJson(withField('savedAt', 5)), isNull);
      expect(SavedGame.fromJson(withField('savedAt', 'ayer')), isNull);
      expect(SavedGame.fromJson(withField('board', 'nada')), isNull);
      expect(SavedGame.fromJson(withField('clueMarks', [0, 7])), isNull);
      expect(SavedGame.fromJson(withField('autoX', 1)), isNull);
      expect(SavedGame.fromJson(withField('mapMode', null)), isNull);
      // No encaja con el caso: otro número de pistas o de casillas.
      expect(SavedGame.fromJson(ok, clueCount: 5), isNull);
      expect(SavedGame.fromJson(ok, cellCount: 10), isNull);
    });

    test('guarda, lee, detecta y borra en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(SavedGame.exists(prefs, 'caso-1'), isFalse);
      expect(SavedGame.read(prefs, 'caso-1'), isNull);

      await SavedGame.write(prefs, 'caso-1', _sampleGame());
      expect(prefs.containsKey('game:caso-1'), isTrue);
      expect(SavedGame.exists(prefs, 'caso-1'), isTrue);
      expect(SavedGame.exists(prefs, 'caso-2'), isFalse);

      final read = SavedGame.read(prefs, 'caso-1', cellCount: 16)!;
      expect(read.elapsed, 125);
      expect(read.board.toJson(), _sampleBoard().toJson());

      await SavedGame.clear(prefs, 'caso-1');
      expect(SavedGame.exists(prefs, 'caso-1'), isFalse);
    });
  });
}

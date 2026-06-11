import 'package:enigmatrix/src/game/board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reglas de colocación (doc 03)', () {
    test('mismo candidato dos veces: no hace nada', () {
      final b1 = BoardState.empty().placeCandidate(0, 'c1');
      expect(b1.outcome, PlaceOutcome.placed);
      final b2 = b1.board.placeCandidate(0, 'c1');
      expect(b2.outcome, PlaceOutcome.noChange);
    });

    test('entidades distintas coexisten (candidatos + X)', () {
      var board = BoardState.empty().placeCandidate(0, 'c1').board;
      board = board.placeCandidate(0, 'c2').board;
      board = board.placeX(0, XLevel.small).board;
      expect(board.cell(0).candidates, {'c1', 'c2'});
      expect(board.cell(0).x, XLevel.small);
      expect(board.cell(0).elementCount, 3);
    });

    test('X de otro nivel reemplaza (misma entidad, otro estado)', () {
      var board = BoardState.empty().placeX(0, XLevel.small).board;
      final result = board.placeX(0, XLevel.large);
      expect(result.outcome, PlaceOutcome.placed);
      expect(result.board.cell(0).x, XLevel.large);
    });

    test('confirmado borra automáticamente todo lo demás de la casilla', () {
      var board = BoardState.empty().placeCandidate(0, 'c1').board;
      board = board.placeCandidate(0, 'c2').board;
      board = board.placeX(0, XLevel.large).board;
      final result = board.placeConfirmed(0, 'c3');
      expect(result.outcome, PlaceOutcome.placed);
      expect(result.board.cell(0).confirmed, 'c3');
      expect(result.board.cell(0).candidates, isEmpty);
      expect(result.board.cell(0).x, isNull);
    });

    test('casilla con confirmado rechaza candidatos y X', () {
      final board = BoardState.empty().placeConfirmed(0, 'c1').board;
      expect(board.placeCandidate(0, 'c2').outcome,
          PlaceOutcome.rejectedByConfirmed);
      expect(
          board.placeX(0, XLevel.small).outcome,
          PlaceOutcome.rejectedByConfirmed);
    });

    test('confirmado sobre confirmado: pide confirmación y reemplaza', () {
      final board = BoardState.empty().placeConfirmed(0, 'c1').board;
      expect(board.placeConfirmed(0, 'c2').outcome,
          PlaceOutcome.needsReplaceConfirmation);
      final replaced = board.placeConfirmed(0, 'c2', replace: true);
      expect(replaced.outcome, PlaceOutcome.placed);
      expect(replaced.board.cell(0).confirmed, 'c2');
    });

    test('mismo confirmado: no hace nada', () {
      final board = BoardState.empty().placeConfirmed(0, 'c1').board;
      expect(board.placeConfirmed(0, 'c1').outcome, PlaceOutcome.noChange);
    });
  });

  group('Borrado y posiciones', () {
    test('borrar elementos individuales (mini panel / papelera)', () {
      var board = BoardState.empty().placeCandidate(0, 'c1').board;
      board = board.placeX(0, XLevel.small).board;
      board = board.removeElement(0, const CandidateElement('c1'));
      expect(board.cell(0).candidates, isEmpty);
      expect(board.cell(0).x, XLevel.small);
      board = board.removeElement(0, const XElement(XLevel.small));
      expect(board.cell(0).isEmpty, isTrue);
    });

    test('confirmedPositions: completo y sin duplicados', () {
      var board = BoardState.empty().placeConfirmed(0, 'c1').board;
      board = board.placeConfirmed(5, 'c2').board;
      expect(board.confirmedPositions(['c1', 'c2']), {'c1': 0, 'c2': 5});
      // Falta un personaje:
      expect(board.confirmedPositions(['c1', 'c2', 'c3']), isNull);
      // Mismo personaje confirmado dos veces:
      board = board.placeConfirmed(9, 'c1').board;
      expect(board.confirmedPositions(['c1', 'c2']), isNull);
    });
  });
}

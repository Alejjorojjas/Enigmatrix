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

    test('varios candidatos coexisten en una casilla', () {
      var board = BoardState.empty().placeCandidate(0, 'c1').board;
      board = board.placeCandidate(0, 'c2').board;
      expect(board.cell(0).candidates, {'c1', 'c2'});
    });

    test('X manual limpia los candidatos (acto deliberado: no conviven)', () {
      var board = BoardState.empty().placeCandidate(0, 'c1').board;
      board = board.placeX(0, XLevel.small).board;
      expect(board.cell(0).candidates, isEmpty);
      expect(board.cell(0).x, XLevel.small);
    });

    test('no se puede anotar candidato sobre una X', () {
      final board = BoardState.empty().placeX(0, XLevel.small).board;
      expect(board.placeCandidate(0, 'c1').outcome, PlaceOutcome.rejectedByX);
    });

    test('X de otro nivel reemplaza (misma entidad, otro estado)', () {
      var board = BoardState.empty().placeX(0, XLevel.small).board;
      final result = board.placeX(0, XLevel.large);
      expect(result.outcome, PlaceOutcome.placed);
      expect(result.board.cell(0).x, XLevel.large);
    });

    test('un personaje solo puede estar confirmado en UNA casilla', () {
      final board = BoardState.empty().placeConfirmed(0, 'c1').board;
      expect(board.placeConfirmed(5, 'c1').outcome,
          PlaceOutcome.alreadyConfirmedElsewhere);
    });

    test('al confirmar, sus candidatos desaparecen del resto del tablero',
        () {
      var board = BoardState.empty().placeCandidate(1, 'c1').board;
      board = board.placeCandidate(2, 'c1').board;
      board = board.placeCandidate(2, 'c2').board;
      board = board.placeConfirmed(5, 'c1').board;
      expect(board.cell(1).candidates, isEmpty);
      expect(board.cell(2).candidates, {'c2'}); // los de otros se quedan
      expect(board.cell(5).confirmed, 'c1');
    });

    test('el borrador limpia la casilla completa (y las auto-X del fijo)',
        () {
      var board = BoardState.empty()
          .placeConfirmed(5, 'c1', autoXGridSize: 4)
          .board;
      board = board.eraseCell(5);
      expect(board.isEmpty, isTrue); // confirmado y sus X fuera
      // Borrar candidatos y X manual:
      var b2 = BoardState.empty().placeCandidate(0, 'c1').board;
      b2 = b2.placeX(3, XLevel.large).board;
      b2 = b2.eraseCell(0).eraseCell(3);
      expect(b2.isEmpty, isTrue);
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

  group('Auto-X al confirmar (opción 2026-06-11)', () {
    // Grilla 4x4 de prueba: confirmar en celda 5 (f2,c2) tacha su fila
    // {4,6,7} y su columna {1,9,13}.
    test('confirmar tacha fila y columna automáticamente', () {
      final board = BoardState.empty()
          .placeConfirmed(5, 'c1', autoXGridSize: 4)
          .board;
      for (final cell in [4, 6, 7, 1, 9, 13]) {
        expect(board.cell(cell).hasX, isTrue, reason: 'celda $cell sin X');
        expect(board.cell(cell).autoXFrom, {'c1'});
      }
      expect(board.cell(5).hasX, isFalse);
      expect(board.cell(0).hasX, isFalse); // fuera de fila/columna
    });

    test('borrar el confirmado retira sus X automáticas', () {
      var board = BoardState.empty()
          .placeConfirmed(5, 'c1', autoXGridSize: 4)
          .board;
      board = board.removeElement(5, const ConfirmedElement('c1'));
      expect(board.isEmpty, isTrue);
    });

    test('las X de dos confirmados se superponen y retiran por separado', () {
      var board = BoardState.empty()
          .placeConfirmed(0, 'c1', autoXGridSize: 4) // fila 0, col 0
          .board;
      board = board.placeConfirmed(5, 'c2', autoXGridSize: 4).board;
      // La celda 1 (f1,c2) está tachada por ambos (fila de c1, columna de c2).
      expect(board.cell(1).autoXFrom, {'c1', 'c2'});
      board = board.removeElement(0, const ConfirmedElement('c1'));
      expect(board.cell(1).autoXFrom, {'c2'}); // sigue tachada por c2
      expect(board.cell(2).hasX, isFalse); // solo era de c1
    });

    test('la X automática NO pisa confirmados NI candidatos', () {
      var board = BoardState.empty().placeCandidate(4, 'c3').board;
      board = board.placeConfirmed(0, 'c2', autoXGridSize: 4).board;
      board = board.placeConfirmed(5, 'c1', autoXGridSize: 4).board;
      expect(board.cell(0).confirmed, 'c2'); // celda confirmada intacta
      expect(board.cell(0).autoXFrom, isEmpty);
      // La celda 4 (fila de c2@0, columna de c1@5) tenía un candidato:
      // se respeta la anotación del jugador, sin X encima.
      expect(board.cell(4).candidates, {'c3'});
      expect(board.cell(4).hasX, isFalse);
    });

    test('sin autoXGridSize no se tacha nada (opción apagada)', () {
      final board = BoardState.empty().placeConfirmed(5, 'c1').board;
      expect(board.cell(4).hasX, isFalse);
    });

    test('borrar la X de una celda la limpia aunque sea automática', () {
      var board = BoardState.empty()
          .placeConfirmed(5, 'c1', autoXGridSize: 4)
          .board;
      board = board.removeElement(4, const XElement(XLevel.large));
      expect(board.cell(4).hasX, isFalse);
      expect(board.cell(6).hasX, isTrue); // las demás siguen
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
      // Duplicar un confirmado es imposible por diseño (regla 2026-06-12):
      final dup = board.placeConfirmed(9, 'c1');
      expect(dup.outcome, PlaceOutcome.alreadyConfirmedElsewhere);
      expect(dup.board.confirmedPositions(['c1', 'c2']), {'c1': 0, 'c2': 5});
    });
  });
}

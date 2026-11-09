/// Textos idénticos (H-63): lo que el jugador lee tras pasar los textos al
/// .arb es EXACTAMENTE lo que decía el código antes (mismos caracteres,
/// mayúsculas y tildes). Los literales de la derecha son los de las clases
/// `*Texts`, `BoardStrings` y los textos sueltos tal como estaban en el commit
/// anterior a la ronda 4.3b (se sacaron con `git show HEAD:<archivo>`).
library;

import 'package:enigmatrix/src/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/l10n.dart';

void main() {
  final l = l10nEs;

  group('textos simples', () {
    final cases = <String, (String, String)>{
      // clave: (lo que da el .arb, literal de antes)
      'NavTexts.home': (l.navHome, 'Inicio'),
      'HomeTexts.challengeLabel': (l.homeChallengeLabel, 'RETO DIARIO'),
      'HomeTexts.worldLabel': (l.homeWorldLabel, 'MUNDO 1 · LA MANSIÓN'),
      'HomeTexts.stateOpen': (l.homeStateOpen, 'Estado: en curso'),
      'UiTexts.demoNotice': (
        l.uiDemoNotice,
        'Función simulada: se activa con el modo online (Fase 2)',
      ),
      'AppearanceTexts.title': (l.appearanceTitle, 'Aspecto del juego'),
      'CaseListTexts.tutorialBody': (
        l.caseListTutorialBody,
        'Caso de práctica paso a paso (no cuenta como Caso 1)',
      ),
      'MenuTexts.clearBody': (
        l.gameMenuClearBody,
        'Se borran las marcas del tablero y de las pistas. '
            'El tiempo y los errores se mantienen.',
      ),
      'ScreenTexts.exitTutorialBody': (
        l.gameScreenExitTutorialBody,
        'El tutorial no guarda avance. Si sales, podrás repetirlo desde la '
            'lista de casos. ¿Salir?',
      ),
      'SheetTexts.accountBody': (
        l.sheetAccountBody,
        'Restaurar compras, cerrar sesión y eliminar cuenta se activan con el '
            'modo online.',
      ),
      'TutorialDialog página 2, línea 2': (
        l.tutorialDialogBoardLine2,
        'REGLA DE ORO: hay exactamente UNA persona por fila y UNA por '
            'columna, como en un sudoku.',
      ),
      'BoardSemanticsTexts.holdHint': (
        l.boardSemanticsHoldHint,
        'Mantén oprimido para confirmar',
      ),
      'VictoryTexts.stamp': (l.victoryStamp, 'CASO CERRADO'),
      'BoardStrings.cellHasConfirmed': (
        l.boardCellHasConfirmed,
        'Esa casilla ya tiene una ficha. Bórrala primero',
      ),
      'difficultyName elite': (l.difficultyElite, 'Élite'),
      'kWorldNames mansion': (l.worldMansion, 'La Mansión'),
      'splash': (l.splashTagline, 'Un misterio de papel'),
      'tutorial coach, paso 14 (Resolver fallido)': (
        l.tutorialCoachStep13,
        'Con el tablero lleno pero mal, pulsa RESOLVER (abajo). '
            'En el tutorial el juego marca en rojo las casillas que no '
            'cuadran.',
      ),
    };

    cases.forEach((name, pair) {
      test(name, () => expect(pair.$1, pair.$2));
    });

    test('se comparan al menos 15 textos simples', () {
      expect(cases.length, greaterThanOrEqualTo(15));
    });
  });

  group('textos con datos (placeholders)', () {
    test('HomeTexts: casos cerrados', () {
      expect(l.homeSolvedCount(3, 10), '3 de 10 casos cerrados');
    });
    test('resumen del reto de hoy', () {
      expect(
        l.challengeTodaySummary(5, 30, 'Casual', 6),
        'Día 5 de 30 · Casual · 6×6',
      );
    });
    test('título de la ficha de un caso', () {
      expect(l.caseListSheetTitle(2, 'El Club'), 'Caso Nº2 — El Club');
    });
    test('BoardStrings.murdererIs', () {
      expect(l.boardMurdererIs('Adela'), 'El asesino es Adela');
    });
    test('BoardSemanticsTexts.position y board', () {
      expect(l.boardSemanticsPosition(2, 3), 'Fila 2, columna 3');
      expect(l.boardSemanticsBoard(6), 'Tablero de 6 por 6 casillas');
    });
    test('semántica de casilla', () {
      expect(
        l.boardSemanticsBlockedBy('una mesa'),
        'ocupada por una mesa: no se puede usar',
      );
      expect(l.boardSemanticsOnObject('un sofá'), 'sobre un sofá');
      expect(
        l.boardSemanticsBesideObjects('una cama, una planta'),
        'junto a una cama, una planta',
      );
      expect(
        l.boardSemanticsAutoCrossed('Adela, Bruno'),
        'descartada por Adela, Bruno',
      );
    });
    test('mundos', () {
      expect(l.worldsEnter('La Mansión'), 'La Mansión: entrar');
      expect(l.worldsProgress('La Mansión'), 'Progreso de La Mansión');
    });
    test('pestaña del caso y progreso del tutorial', () {
      expect(l.caseListFolderNumber(2), 'EXPEDIENTE Nº2');
      expect(l.tutorialCoachProgress(3, 18), 'TUTORIAL · 3/18');
    });
    test('versión', () {
      expect(l.settingsVersion(kAppVersion), 'Murdoku Diario v$kAppVersion');
    });
    test('premium con precio', () {
      expect(l.premiumMonthly(r'$4.99'), r'Mensual · $4.99');
      expect(l.premiumYearly(r'$29.99'), r'Anual · $29.99 (ahorra 50%)');
    });
    test('frase con la pista entre comillas latinas', () {
      expect(
        l.tutorialCoachClueQuote('Estaba en el Salón'),
        '«Estaba en el Salón»',
      );
      expect(l.tutorialCoachRowCol(2, 4), 'fila 2, columna 4');
    });
    test('victoria: asesino y arma (el nombre queda dentro de la frase)', () {
      expect(
        l.victoryMurdererLine('Adela'),
        'El asesino era Adela, que quedó a solas con la víctima.',
      );
      expect(l.victoryWeaponLine('el cuchillo'), 'Arma homicida: el cuchillo');
    });
  });

  group('textos con plural', () {
    test('BoardStrings.wrongCells', () {
      expect(l.boardWrongCells(1), '1 casilla no cuadra');
      expect(l.boardWrongCells(2), '2 casillas no cuadran');
      expect(l.boardWrongCells(5), '5 casillas no cuadran');
    });
    test('BoardStrings.missingSuspects', () {
      expect(l.boardMissingSuspects(1), 'Falta ubicar a 1 personaje');
      expect(l.boardMissingSuspects(4), 'Faltan 4 personajes por ubicar');
    });
    test('ScreenTexts.wrongInTutorial', () {
      expect(
        l.gameScreenWrongInTutorial(2),
        '2 casillas no cuadran: revisa las marcadas',
      );
      expect(
        l.gameScreenWrongInTutorial(1),
        '1 casilla no cuadra: revisa las marcadas',
      );
    });
    test('racha simulada', () {
      expect(
        l.homeStreakLine(3),
        'Racha: 3 días · Caso del día (simulación: aún sin servidor)',
      );
      expect(l.challengeStreakTitle(3), '3 días de racha');
    });
    test('caso cerrado y caso en curso (segundos y errores)', () {
      expect(l.caseListClosedIn('95', 2), 'Caso cerrado en 95 s · 2 errores');
      expect(
        l.caseListInProgressInfo('2:05', 0),
        'En curso: 2:05 jugados · 0 errores',
      );
    });
    test('mundos disponibles', () {
      expect(l.worldsAvailable(1, 5), '1 de 5 disponibles');
    });
    test('ficha de un caso: sospechosos y pistas', () {
      expect(l.caseListSuspects(5), '5 sospechosos');
      expect(l.caseListClues(8), '8 pistas');
    });
    test('tienda simulada', () {
      expect(l.shopLives(10), '10 vidas');
      expect(l.shopProtectors(3), '3 protectores de racha');
      expect(l.shopProtectors(10), '10 protectores de racha');
    });
  });
}

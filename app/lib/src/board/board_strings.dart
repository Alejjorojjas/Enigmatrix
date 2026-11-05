/// Textos visibles del tablero, centralizados (español). Se extraen a .arb
/// en la ronda 4.3 (textos para traducir).
library;

class BoardStrings {
  const BoardStrings._();

  // Mensajes cortos sobre el tablero.
  static const pickSuspectFirst = 'Elige primero a un sospechoso';
  static const cellHasConfirmed =
      'Esa casilla ya tiene una ficha. Bórrala primero';
  static const cellHasX = 'Esa casilla está tachada';
  static const alreadyPlaced =
      'Ese sospechoso ya está colocado. Bórralo para moverlo';
  static const blockedCell = 'Ahí hay un mueble';

  static String wrongCells(int n) =>
      n == 1 ? '1 casilla no cuadra' : '$n casillas no cuadran';

  static String missingSuspects(int n) =>
      n == 1 ? 'Falta ubicar a 1 personaje' : 'Faltan $n personajes por ubicar';

  static String murdererIs(String name) => 'El asesino es $name';

  // Medidor de FPS.
  static const copyResult = 'Copiar resultado';
  static const copied = 'Resultado copiado';
}

/// Textos visibles del prototipo, centralizados (español).
/// Cuando esto pase a la app real, se extraen a .arb (etapa 4).
library;

class Strings {
  const Strings._();

  static const appTitle = 'Tablero · prueba técnica';

  // Mensajes cortos sobre el tablero.
  static const pickSuspectFirst = 'Elige primero a un sospechoso';
  static const cellHasConfirmed = 'Esa casilla ya tiene una ficha. Bórrala primero';
  static const cellHasX = 'Esa casilla está tachada';
  static const alreadyPlaced = 'Ese sospechoso ya está colocado. Bórralo para moverlo';
  static const blockedCell = 'Ahí hay un mueble';

  static String wrongCells(int n) =>
      n == 1 ? '1 casilla no cuadra' : '$n casillas no cuadran';

  static String missingSuspects(int n) =>
      n == 1 ? 'Falta ubicar a 1 personaje' : 'Faltan $n personajes por ubicar';

  static String murdererIs(String name) => 'El asesino es $name';

  // Barra y bandeja.
  static const victim = 'Víctima';
  static const resolve = 'Resolver';
  static const eraser = 'Borrar';
  static const undo = 'Deshacer';
  static const skip = 'Saltar';
  static const playAgain = 'Jugar de nuevo';
  static const options = 'Opciones';
  static const errorsLabel = 'Errores';

  // Opciones.
  static const sound = 'Sonido';
  static const haptics = 'Vibración';
  static const reduceMotion = 'Reducir movimiento';
  static const reduceMotionHint =
      'Cambia sacudidas y destellos por fundidos suaves';
  static const particleCap = 'Tope de partículas';
  static const fpsMeter = 'Medidor de FPS';
  static const fpsMeterHint = 'Para depurar. Aparece arriba, fuera del tablero';
  static const doubleTap = 'Doble toque confirma';
  static const doubleTapHint =
      'Tocar dos veces la misma casilla con el mismo sospechoso la confirma';
  static const autoX = 'Tachar fila y columna al confirmar';
  static const skin = 'Piel';
  static const skinHint = 'Cambia al instante para comparar';
  static const themeMode = 'Modo';
  static const modeSystem = 'Sistema';
  static const modeLight = 'Claro';
  static const modeDark = 'Oscuro';
  static const modeToggleToLight = 'Cambiar a modo claro';
  static const modeToggleToDark = 'Cambiar a modo oscuro';
  static const audioWeb = 'El audio está desactivado en el navegador; en Android sí suena.';

  // Barra de herramientas.
  // Anotar = candidato, Tachar = X a mano, Confirmar = un toque confirma,
  // Borrar = borrador.
  static const toolNotes = 'Anotar';
  static const toolCross = 'Tachar';
  static const toolPlace = 'Confirmar';
  static const toolErase = 'Borrar';

  // Pista del personaje seleccionado.
  static const hintTitle = 'Pista';
  static const hintEmpty = 'Toca un retrato para ver su pista.';
  static const hintExpandLabel = 'Pista completa';
  static const hintVictim = 'Víctima';

  static String caseSubtitle(String difficulty, int size) =>
      'Caso $size×$size · $difficulty';
  static const measureTools = 'Herramientas de medición';
  static const autofill = 'Llenar el tablero (solo para medir)';
  static const autofillHint =
      'Coloca a todos los personajes bien para probar la secuencia de resolver sin tener que deducir el caso';
  static const lastResult = 'Último resultado de la secuencia';
  static const noResultYet = 'Todavía no hay medición. Resuelve un caso.';
  static const copyResult = 'Copiar resultado';
  static const copied = 'Resultado copiado';
  static const audioUnavailable = 'El audio no se pudo iniciar';
}

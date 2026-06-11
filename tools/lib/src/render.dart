/// Render de consola: hoja del caso para jugarlo en papel (Fase 0).
/// Orientación canónica; la rotación anti-trampa es presentación de cliente.
library;

import 'puzzle_case.dart';

String renderCaseSheet(PuzzleCase pc, {bool revealSolution = false}) {
  final map = pc.map;
  final b = StringBuffer();

  b.writeln('=' * 64);
  b.writeln('CASO: ${pc.caseId}');
  b.writeln('Mapa: ${map.nameEs}   Dificultad: ${pc.difficulty}'
      '${pc.hasWeapon ? '   (incluye arma homicida)' : ''}');
  b.writeln('=' * 64);

  b.writeln('\nPERSONAJES:');
  for (final ch in pc.characters) {
    final tag = ch.id == pc.victimId ? '  <- LA VÍCTIMA' : '';
    b.writeln('  ${ch.nameEs[0]} = ${ch.nameEs}$tag');
  }

  b.writeln('\nPISTAS:');
  for (var i = 0; i < pc.clues.length; i++) {
    final text = pc.clues[i].textEs(map, pc.nameOf);
    b.writeln('  ${i + 1}. ${text[0].toUpperCase()}${text.substring(1)}');
  }

  b.writeln('\nTABLERO (letra = habitación, ## = celda bloqueada):');
  b.write(_renderGrid(pc, revealSolution: revealSolution));

  b.writeln('\nHABITACIONES:');
  for (var i = 0; i < map.areas.length; i++) {
    final a = map.areas[i];
    final letter = String.fromCharCode('a'.codeUnitAt(0) + i);
    final weapons = map.weaponsInArea(a.id);
    final wTxt = weapons.isEmpty
        ? ''
        : '  [armas: ${weapons.map((w) => w.nameEs).join(', ')}]';
    b.writeln('  $letter = ${a.nameEs}$wTxt');
  }
  if (map.objects.isNotEmpty) {
    b.writeln('\nOBJETOS (bloquean su celda):');
    for (final o in map.objects) {
      b.writeln('  ${o.nameEs}: fila ${map.row(o.cell) + 1}, '
          'columna ${map.col(o.cell) + 1}');
    }
  }

  b.writeln('\nREGLAS: exactamente una persona por fila y por columna. '
      'El asesino quedó a solas con la víctima en la misma habitación.');

  if (revealSolution) {
    final sol = pc.solution;
    b.writeln('\n${'-' * 64}');
    b.writeln('SOLUCIÓN (interna — el cliente nunca la recibe):');
    for (final ch in pc.characters) {
      final p = sol.positions[ch.id]!;
      final area = map.areas.firstWhere((a) => a.id == map.areaIdOf(p));
      final marks = [
        if (ch.id == pc.victimId) 'VÍCTIMA',
        if (ch.id == sol.murdererId) 'ASESINO',
      ].join(' · ');
      b.writeln('  ${ch.nameEs}: fila ${map.row(p) + 1}, '
          'col ${map.col(p) + 1} (${area.nameEs})'
          '${marks.isEmpty ? '' : '   <- $marks'}');
    }
    if (sol.lethalWeaponId != null) {
      final w = map.weapons.firstWhere((w) => w.id == sol.lethalWeaponId);
      b.writeln('  Arma homicida: ${w.nameEs}');
    }
    if (pc.metrics != null) {
      final m = pc.metrics!;
      b.writeln('  Métricas: ${m.clueCount} pistas, '
          '${m.deductionSteps} pasos de deducción, técnica máx. T${m.maxTier}');
    }
  }

  return b.toString();
}

String _renderGrid(PuzzleCase pc, {required bool revealSolution}) {
  final map = pc.map;
  final n = map.size;
  final b = StringBuffer();

  final areaLetter = <String, String>{};
  for (var i = 0; i < map.areas.length; i++) {
    areaLetter[map.areas[i].id] =
        String.fromCharCode('a'.codeUnitAt(0) + i);
  }
  final charAt = <int, String>{};
  if (revealSolution) {
    for (final ch in pc.characters) {
      final initial = ch.nameEs[0].toUpperCase();
      charAt[pc.solution.positions[ch.id]!] =
          ch.id == pc.victimId ? '$initial†' : '$initial ';
    }
  }

  String cellText(int cell) {
    if (charAt.containsKey(cell)) return ' ${charAt[cell]}';
    if (!map.isOccupiable(cell)) return ' ##';
    return ' ${areaLetter[map.areaIdOf(cell)]} ';
  }

  bool wallRight(int r, int c) =>
      c == n - 1 || !map.sameArea(map.cellAt(r, c), map.cellAt(r, c + 1));
  bool wallBelow(int r, int c) =>
      r == n - 1 || !map.sameArea(map.cellAt(r, c), map.cellAt(r + 1, c));

  b.write('     ');
  for (var c = 0; c < n; c++) {
    b.write(' c${c + 1} ');
  }
  b.writeln();
  b.writeln('    +${'---+' * n}');
  for (var r = 0; r < n; r++) {
    b.write(' f${r + 1} |');
    for (var c = 0; c < n; c++) {
      b.write(cellText(map.cellAt(r, c)));
      b.write(wallRight(r, c) ? '|' : ' ');
    }
    b.writeln();
    b.write('    +');
    for (var c = 0; c < n; c++) {
      b.write(wallBelow(r, c) ? '---+' : '   +');
    }
    b.writeln();
  }
  return b.toString();
}

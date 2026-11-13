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

  b.writeln('\nPERSONAJES Y SUS PISTAS:');
  for (final ch in pc.characters) {
    final tag = ch.id == pc.victimId ? ' (LA VÍCTIMA)' : '';
    final clue = pc.clueFor(ch.id);
    final text = clue == null ? '—' : clue.cardTextEs(map, pc.names);
    b.writeln('  ${ch.nameEs[0]} = ${ch.nameEs}$tag: $text');
  }
  final extras = pc.extraClues;
  if (extras.isNotEmpty) {
    b.writeln('\nINFORMACIÓN ADICIONAL:');
    for (final e in extras) {
      b.writeln('  · ${e.textEs(map, pc.names)}');
    }
  }

  b.writeln('\nTABLERO (letra = habitación, ## = mueble que bloquea, '
      '() = mueble pisable):');
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
    b.writeln('\nMUEBLES:');
    for (final o in map.objects) {
      final where = o.cells
          .map((c) => 'f${map.row(c) + 1}c${map.col(c) + 1}')
          .join(', ');
      final kind = o.type.standable ? 'pisable' : 'bloquea';
      b.writeln('  ${o.type.defEs} ($kind): $where');
    }
  }

  b.writeln('\nREGLAS: exactamente una persona por fila y por columna. '
      'Nadie puede estar en celdas con muebles que bloquean. '
      'El asesino quedó a solas con la víctima en la misma habitación.');

  if (revealSolution && pc.hasSolution) {
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
    areaLetter[map.areas[i].id] = String.fromCharCode('a'.codeUnitAt(0) + i);
  }
  final charAt = <int, String>{};
  if (revealSolution && pc.hasSolution) {
    for (final ch in pc.characters) {
      final initial = ch.nameEs[0].toUpperCase();
      charAt[pc.solution.positions[ch.id]!] =
          ch.id == pc.victimId ? '$initial†' : '$initial ';
    }
  }

  String cellText(int cell) {
    if (charAt.containsKey(cell)) return ' ${charAt[cell]}';
    final obj = map.objectAt(cell);
    if (obj != null && obj.blocks) return ' ##';
    final letter = areaLetter[map.areaIdOf(cell)]!;
    if (obj != null) return '($letter)'; // mueble pisable
    return ' $letter ';
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

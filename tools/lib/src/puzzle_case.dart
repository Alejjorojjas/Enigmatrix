/// Definición de un caso y su serialización.
/// Formato de referencia: docs/16-spec-puzzle.md sección 5.2.
library;

import 'clue.dart';
import 'model.dart';

class Solution {
  /// charId -> celda (coordenadas canónicas).
  final Map<String, int> positions;
  final String murdererId;
  final String? lethalWeaponId;

  const Solution({
    required this.positions,
    required this.murdererId,
    this.lethalWeaponId,
  });

  Map<String, dynamic> toJson() => {
        'positions': positions,
        'murderer': murdererId,
        if (lethalWeaponId != null) 'lethalWeapon': lethalWeaponId,
      };

  factory Solution.fromJson(Map<String, dynamic> j) => Solution(
        positions: (j['positions'] as Map).cast<String, int>(),
        murdererId: j['murderer'] as String,
        lethalWeaponId: j['lethalWeapon'] as String?,
      );
}

class CaseMetrics {
  /// Pasos de deducción: aplicaciones de técnica que aportaron información.
  final int deductionSteps;

  /// Técnica más avanzada requerida (1 = directa ... 4 = conteo de área/arma).
  final int maxTier;
  final int clueCount;

  const CaseMetrics({
    required this.deductionSteps,
    required this.maxTier,
    required this.clueCount,
  });

  Map<String, dynamic> toJson() => {
        'deductionSteps': deductionSteps,
        'maxTier': maxTier,
        'clueCount': clueCount,
      };

  factory CaseMetrics.fromJson(Map<String, dynamic> j) => CaseMetrics(
        deductionSteps: j['deductionSteps'] as int,
        maxTier: j['maxTier'] as int,
        clueCount: j['clueCount'] as int,
      );
}

class PuzzleCase {
  final String caseId;
  final GameMap map;
  final List<Character> characters;
  final String victimId;
  final List<Clue> clues;
  final bool hasWeapon;
  final String difficulty;

  /// SOLO pipeline interno. El cliente JAMÁS la recibe (ver toClientJson).
  final Solution solution;
  final CaseMetrics? metrics;

  const PuzzleCase({
    required this.caseId,
    required this.map,
    required this.characters,
    required this.victimId,
    required this.clues,
    required this.hasWeapon,
    required this.difficulty,
    required this.solution,
    this.metrics,
  });

  Character character(String id) => characters.firstWhere((c) => c.id == id);

  /// En texto de pistas la víctima se nombra por rol, no por nombre
  /// (minúscula: el render capitaliza inicio de frase).
  String nameOf(String charId) =>
      charId == victimId ? 'la víctima' : character(charId).nameEs;

  ClueContext contextFor(Map<String, int> positions, {String? lethal}) =>
      ClueContext(
        map: map,
        positions: positions,
        victimId: victimId,
        lethalWeaponId: lethal,
      );

  /// JSON completo del pipeline interno (incluye solución).
  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'mapId': map.id,
        'difficulty': difficulty,
        'hasWeapon': hasWeapon,
        'victim': victimId,
        'characters': [
          for (final c in characters) {'id': c.id, 'name_es': c.nameEs}
        ],
        'clues': [for (final c in clues) c.toJson()],
        'solution': solution.toJson(),
        if (metrics != null) 'metrics': metrics!.toJson(),
      };

  /// Payload para el cliente: SIN solución, SIN arma homicida, SIN métricas.
  /// Regla innegociable de docs/16-spec-puzzle.md sección 5.2.
  Map<String, dynamic> toClientJson() => {
        'caseId': caseId,
        'mapId': map.id,
        'difficulty': difficulty,
        'hasWeapon': hasWeapon,
        'victim': victimId,
        'characters': [
          for (final c in characters) {'id': c.id, 'name_es': c.nameEs}
        ],
        'clues': [for (final c in clues) c.toJson()],
      };

  factory PuzzleCase.fromJson(Map<String, dynamic> j, GameMap map) {
    if (j['mapId'] != map.id) {
      throw ArgumentError('El caso es del mapa ${j['mapId']}, no de ${map.id}');
    }
    return PuzzleCase(
      caseId: j['caseId'] as String,
      map: map,
      characters: [
        for (final c in (j['characters'] as List))
          Character(id: c['id'] as String, nameEs: c['name_es'] as String)
      ],
      victimId: j['victim'] as String,
      clues: [
        for (final c in (j['clues'] as List))
          Clue.fromJson((c as Map).cast<String, dynamic>())
      ],
      hasWeapon: j['hasWeapon'] as bool,
      difficulty: j['difficulty'] as String,
      solution:
          Solution.fromJson((j['solution'] as Map).cast<String, dynamic>()),
      metrics: j['metrics'] == null
          ? null
          : CaseMetrics.fromJson((j['metrics'] as Map).cast<String, dynamic>()),
    );
  }
}

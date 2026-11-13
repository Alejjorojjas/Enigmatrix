/// Definición de un caso y su serialización.
/// Formato de referencia: docs/16-spec-puzzle.md sección 5.2.
library;

import 'clue.dart';
import 'model.dart';
import 'story.dart';

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

  /// Una pista por personaje (en el orden de [characters]) + extras al final
  /// (área vacía / arma) — formato Murdoku decidido el 2026-06-11.
  final List<Clue> clues;
  final bool hasWeapon;
  final String difficulty;

  /// SOLO pipeline interno. El cliente JAMÁS la recibe (ver toClientJson).
  /// Es null en los casos publicados de los mundos (mansion-*, reto-*): se
  /// validan en el servidor y su JSON de la app no lleva `solution`. Los
  /// casos locales (tutorial y banco `caso-*`) sí la traen.
  final Solution? solutionOrNull;
  final CaseMetrics? metrics;

  /// Historia del caso (mundo, título y premisa). Opcional: los casos sin
  /// ella siguen funcionando. Es sabor, no lógica, y viaja también al
  /// cliente (ver toClientJson).
  final CaseStory? story;

  const PuzzleCase({
    required this.caseId,
    required this.map,
    required this.characters,
    required this.victimId,
    required this.clues,
    required this.hasWeapon,
    required this.difficulty,
    Solution? solution,
    this.metrics,
    this.story,
  }) : solutionOrNull = solution;

  /// true si el caso trae su solución (se puede validar en este equipo).
  bool get hasSolution => solutionOrNull != null;

  /// La solución. Lanza [StateError] si el caso no la trae: quien valida en
  /// local debe preguntar antes por [hasSolution].
  Solution get solution =>
      solutionOrNull ??
      (throw StateError('El caso $caseId no trae solución: se valida en el '
          'servidor.'));

  /// Copia del caso con otra historia (o sin ella si [story] es null).
  PuzzleCase withStory(CaseStory? story) => PuzzleCase(
        caseId: caseId,
        map: map,
        characters: characters,
        victimId: victimId,
        clues: clues,
        hasWeapon: hasWeapon,
        difficulty: difficulty,
        solution: solutionOrNull,
        metrics: metrics,
        story: story,
      );

  Character character(String id) => characters.firstWhere((c) => c.id == id);

  String nameOf(String charId) =>
      charId == victimId ? 'La víctima' : character(charId).nameEs;

  ClueNames get names => ClueNames(
        nameOf: nameOf,
        isFemale: (id) => character(id).female,
      );

  /// La pista de la tarjeta de un personaje (null si no tiene — no debería
  /// pasar en casos generados).
  Clue? clueFor(String charId) {
    for (final c in clues) {
      if (c.subjectId == charId) return c;
    }
    return null;
  }

  /// Pistas sueltas (sin tarjeta): área vacía, arma.
  List<Clue> get extraClues => [
        for (final c in clues)
          if (c.subjectId == null) c
      ];

  ClueContext contextFor(Map<String, int> positions, {String? lethal}) =>
      ClueContext(
        map: map,
        positions: positions,
        victimId: victimId,
        lethalWeaponId: lethal,
      );

  /// Copia del caso sin solución (la versión que va en los assets de la app
  /// para los casos que valida el servidor).
  PuzzleCase withoutSolution() => PuzzleCase(
        caseId: caseId,
        map: map,
        characters: characters,
        victimId: victimId,
        clues: clues,
        hasWeapon: hasWeapon,
        difficulty: difficulty,
        metrics: metrics,
        story: story,
      );

  /// JSON completo del pipeline interno (incluye solución si el caso la
  /// trae). El mapa viaja embebido: cada caso tiene su propio mapa
  /// (decisión 2026-06-11).
  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'mapId': map.id,
        'map': map.toJson(),
        'difficulty': difficulty,
        'hasWeapon': hasWeapon,
        'victim': victimId,
        'characters': [
          for (final c in characters)
            {'id': c.id, 'name_es': c.nameEs, 'female': c.female}
        ],
        'clues': [for (final c in clues) c.toJson()],
        if (solutionOrNull != null) 'solution': solutionOrNull!.toJson(),
        if (metrics != null) 'metrics': metrics!.toJson(),
        if (story != null) 'story': story!.toJson(),
      };

  /// Payload para el cliente: SIN solución, SIN arma homicida, SIN métricas.
  /// Regla innegociable de docs/16-spec-puzzle.md sección 5.2.
  Map<String, dynamic> toClientJson() => {
        'caseId': caseId,
        'mapId': map.id,
        'map': map.toJson(),
        'difficulty': difficulty,
        'hasWeapon': hasWeapon,
        'victim': victimId,
        'characters': [
          for (final c in characters)
            {'id': c.id, 'name_es': c.nameEs, 'female': c.female}
        ],
        'clues': [for (final c in clues) c.toJson()],
        if (story != null) 'story': story!.toJson(),
      };

  /// [mapOverride] solo para fixtures de test; los casos reales traen el
  /// mapa embebido.
  factory PuzzleCase.fromJson(Map<String, dynamic> j, {GameMap? mapOverride}) {
    final map = mapOverride ??
        GameMap.fromJson((j['map'] as Map).cast<String, dynamic>());
    return PuzzleCase(
      caseId: j['caseId'] as String,
      map: map,
      characters: [
        for (final c in (j['characters'] as List))
          Character(
            id: c['id'] as String,
            nameEs: c['name_es'] as String,
            female: (c['female'] as bool?) ?? false,
          )
      ],
      victimId: j['victim'] as String,
      clues: [
        for (final c in (j['clues'] as List))
          Clue.fromJson((c as Map).cast<String, dynamic>())
      ],
      hasWeapon: j['hasWeapon'] as bool,
      difficulty: j['difficulty'] as String,
      // La solución es opcional: los casos de los mundos la llevan solo en
      // la fuente del servidor (tools/data/casos-servidor).
      solution: j['solution'] == null
          ? null
          : Solution.fromJson((j['solution'] as Map).cast<String, dynamic>()),
      metrics: j['metrics'] == null
          ? null
          : CaseMetrics.fromJson((j['metrics'] as Map).cast<String, dynamic>()),
      story: j['story'] == null
          ? null
          : CaseStory.fromJson((j['story'] as Map).cast<String, dynamic>()),
    );
  }
}

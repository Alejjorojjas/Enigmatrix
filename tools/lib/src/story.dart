/// Historia del caso (ronda 3.2): mundo, título y premisa por idioma.
///
/// Es solo sabor narrativo (docs/13-narrativa.md): nunca entra en la lógica
/// del puzzle ni da información que las pistas no den. Formato en el JSON:
/// ```json
/// "story": {
///   "world": "mansion",
///   "title": {"es": "La última cena"},
///   "premise": {"es": "Una cena de aniversario ..."}
/// }
/// ```
/// Es un campo OPCIONAL del caso: los casos sin él siguen funcionando.
/// Hoy solo existe "es"; para agregar un idioma basta sumar su clave en
/// `title` y `premise` (la app pide `title('es')` y cae al título actual si
/// el idioma no está).
library;

class CaseStory {
  /// Id del mundo ("mansion"). Coincide con el `mundo` del catálogo.
  final String world;

  final Map<String, String> _title;
  final Map<String, String> _premise;

  CaseStory({
    required this.world,
    required Map<String, String> title,
    required Map<String, String> premise,
  })  : _title = Map.unmodifiable(title),
        _premise = Map.unmodifiable(premise);

  /// Título en el idioma [lang] ("es"), o null si no existe en ese idioma.
  String? title(String lang) => _title[lang];

  /// Premisa breve en el idioma [lang], o null si no existe.
  String? premise(String lang) => _premise[lang];

  /// Todos los títulos por idioma (copia de solo lectura).
  Map<String, String> get titles => _title;

  /// Todas las premisas por idioma (copia de solo lectura).
  Map<String, String> get premises => _premise;

  Map<String, dynamic> toJson() => {
        'world': world,
        'title': _title,
        'premise': _premise,
      };

  /// Estricto: lanza [FormatException] si falta o es inválido un campo.
  factory CaseStory.fromJson(Map<String, dynamic> j) {
    final world = j['world'];
    if (world is! String || world.trim().isEmpty) {
      throw const FormatException('story: campo "world" ausente o vacío');
    }
    return CaseStory(
      world: world,
      title: _texts(j, 'title'),
      premise: _texts(j, 'premise'),
    );
  }

  static Map<String, String> _texts(Map<String, dynamic> j, String key) {
    final raw = j[key];
    if (raw is! Map || raw.isEmpty) {
      throw FormatException('story: campo "$key" ausente o vacío '
          '(esperaba {"es": "..."})');
    }
    final out = <String, String>{};
    raw.forEach((lang, text) {
      if (lang is! String || text is! String || text.trim().isEmpty) {
        throw FormatException('story: "$key" tiene una entrada inválida '
            '($lang)');
      }
      out[lang] = text;
    });
    return out;
  }
}

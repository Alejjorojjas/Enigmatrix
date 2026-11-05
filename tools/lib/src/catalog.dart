/// Catálogo de casos (H-43, H-50): el manifiesto que dice qué casos existen,
/// de qué mundo son, si son de campaña o reto, su dificultad, su orden y su
/// archivo. Es la fuente del orden de la lista de casos de la app.
///
/// Formato de `app/assets/cases/catalogo.json`:
/// ```json
/// {
///   "version": 1,
///   "casos": [
///     {"id": "caso-principiante-s1", "mundo": "banco-de-pruebas",
///      "tipo": "campana", "dificultad": "principiante", "orden": 1,
///      "archivo": "caso-principiante-s1.json"}
///   ]
/// }
/// ```
/// - `dia`: SOLO en los retos (tipo "reto"), del 1 al 30; en la campaña no
///   va. Es el número de día del reto diario.
/// - `id`: estable para siempre; coincide con `caseId` del archivo y es la
///   clave del progreso del jugador ("done:<id>", "game:<id>"). NO se cambia.
/// - `orden`: posición global de la lista (entero positivo). La app ordena
///   por él; a igual orden, por id.
///
/// Pura (sin dart:io): la usan el CLI, las pruebas y la app.
library;

import 'dart:convert';

/// Mundo de los 20 casos del banco de pruebas (antes de los mundos reales).
const kBancoDePruebas = 'banco-de-pruebas';

/// Mundo 1 de la V1, "La Mansión" (ronda 3.2). Es el id que usan el
/// catálogo y `story.world` de sus casos. Los retos diarios también se
/// ambientan en él.
const kMundoMansion = 'mansion';

/// Días del reto diario de la V1 (ADR-0014): del 1 al 30.
const kDiasReto = 30;

/// Nombre del archivo del catálogo dentro de assets/cases/.
const kCatalogFileName = 'catalogo.json';

/// Tipo de caso: campaña (progresión) o reto (diario o especial).
enum CaseKind {
  campana,
  reto;

  static CaseKind? tryParse(Object? raw) {
    for (final k in values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}

class CatalogEntry {
  final String id;
  final String mundo;
  final CaseKind tipo;
  final String dificultad;
  final int orden;
  final String archivo;

  /// Número de día del reto diario (1 a [kDiasReto]); null en la campaña.
  /// La hora de cambio de día está pendiente (pregunta 7): solo se guarda
  /// el número.
  final int? dia;

  const CatalogEntry({
    required this.id,
    required this.mundo,
    required this.tipo,
    required this.dificultad,
    required this.orden,
    required this.archivo,
    this.dia,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mundo': mundo,
        'tipo': tipo.name,
        'dificultad': dificultad,
        'orden': orden,
        'archivo': archivo,
        if (dia != null) 'dia': dia,
      };

  /// Estricto: lanza [FormatException] si falta o es inválido un campo.
  factory CatalogEntry.fromJson(Map<String, dynamic> j) {
    String str(String k) {
      final v = j[k];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('campo "$k" ausente o vacío');
      }
      return v;
    }

    final tipo = CaseKind.tryParse(j['tipo']);
    if (tipo == null) {
      throw FormatException('campo "tipo" inválido: ${j['tipo']} '
          '(campana o reto)');
    }
    final orden = j['orden'];
    if (orden is! int || orden < 1) {
      throw FormatException('campo "orden" inválido: $orden (entero >= 1)');
    }
    final archivo = str('archivo');
    if (archivo.contains('/') || archivo.contains('\\')) {
      throw FormatException('campo "archivo" debe ser un nombre sin ruta: '
          '$archivo');
    }
    final dia = j['dia'];
    if (dia != null && (dia is! int || dia < 1 || dia > kDiasReto)) {
      throw FormatException('campo "dia" inválido: $dia '
          '(entero de 1 a $kDiasReto)');
    }
    return CatalogEntry(
      dia: dia as int?,
      id: str('id'),
      mundo: str('mundo'),
      tipo: tipo,
      dificultad: str('dificultad'),
      orden: orden,
      archivo: archivo,
    );
  }
}

class CaseCatalog {
  static const currentVersion = 1;

  /// Entradas ordenadas por [CatalogEntry.orden] y luego por id.
  final List<CatalogEntry> entries;

  CaseCatalog(Iterable<CatalogEntry> entries)
      : entries = (entries.toList()..sort(_compare));

  static int _compare(CatalogEntry a, CatalogEntry b) {
    final o = a.orden.compareTo(b.orden);
    return o != 0 ? o : a.id.compareTo(b.id);
  }

  CatalogEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Entradas de un mundo y tipo (ambos opcionales), en orden del catálogo.
  List<CatalogEntry> where({String? mundo, CaseKind? tipo}) => [
        for (final e in entries)
          if ((mundo == null || e.mundo == mundo) &&
              (tipo == null || e.tipo == tipo))
            e
      ];

  /// Nombres de archivo listados, en orden del catálogo.
  List<String> get files => [for (final e in entries) e.archivo];

  /// Siguiente número de orden libre.
  int get nextOrden =>
      entries.isEmpty ? 1 : entries.map((e) => e.orden).reduce(_max) + 1;

  static int _max(int a, int b) => a > b ? a : b;

  /// Catálogo nuevo con [entry] agregada. Lanza [ArgumentError] si el id o
  /// el archivo ya existen (los ids son estables: no se reutilizan).
  CaseCatalog withEntry(CatalogEntry entry) {
    if (byId(entry.id) != null) {
      throw ArgumentError('El id "${entry.id}" ya está en el catálogo');
    }
    if (files.contains(entry.archivo)) {
      throw ArgumentError(
          'El archivo "${entry.archivo}" ya está en el catálogo');
    }
    return CaseCatalog([...entries, entry]);
  }

  /// Problemas de consistencia interna (vacío = sano): ids, archivos u
  /// órdenes repetidos.
  List<String> consistencyProblems() {
    final problems = <String>[];
    void dup(String what, Iterable<String> values) {
      final seen = <String>{};
      for (final v in values) {
        if (!seen.add(v)) problems.add('$what repetido: $v');
      }
    }

    dup('id', entries.map((e) => e.id));
    dup('archivo', entries.map((e) => e.archivo));
    dup('orden', entries.map((e) => '${e.orden}'));
    dup('día de reto', [
      for (final e in entries)
        if (e.dia != null) '${e.dia}'
    ]);
    for (final e in entries) {
      if (e.tipo == CaseKind.reto && e.dia == null) {
        problems.add('el reto "${e.id}" no tiene "dia"');
      }
      if (e.tipo == CaseKind.campana && e.dia != null) {
        problems.add('el caso de campaña "${e.id}" no debe tener "dia"');
      }
    }
    return problems;
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'casos': [for (final e in entries) e.toJson()],
      };

  /// JSON con sangría y salto de línea final (legible en control de cambios).
  String toJsonString() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  /// Estricto: lanza [FormatException] ante cualquier problema.
  factory CaseCatalog.fromJsonString(String text) {
    final result = parse(text);
    if (result.errors.isNotEmpty) {
      throw FormatException(result.errors.join('; '));
    }
    return result.catalog;
  }

  /// Tolerante: salta las entradas inválidas o con id repetido (la primera
  /// gana) y las reporta en [CatalogParseResult.errors]. Si el documento
  /// completo no es un catálogo válido lanza [FormatException].
  static CatalogParseResult parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
          ? text.substring(1)
          : text);
    } on FormatException catch (e) {
      throw FormatException('catálogo no es JSON válido: ${e.message}');
    }
    if (decoded is! Map || decoded['casos'] is! List) {
      throw const FormatException('catálogo sin la lista "casos"');
    }
    final version = decoded['version'];
    if (version != currentVersion) {
      throw FormatException('versión de catálogo no soportada: $version');
    }
    final errors = <String>[];
    final ok = <CatalogEntry>[];
    final seen = <String>{};
    var i = 0;
    for (final item in decoded['casos'] as List) {
      i++;
      try {
        if (item is! Map) throw const FormatException('no es un objeto');
        final e = CatalogEntry.fromJson(item.cast<String, dynamic>());
        if (!seen.add(e.id)) {
          errors.add('entrada $i: id repetido "${e.id}"');
          continue;
        }
        ok.add(e);
      } on FormatException catch (e) {
        errors.add('entrada $i: ${e.message}');
      }
    }
    return CatalogParseResult(CaseCatalog(ok), errors);
  }
}

class CatalogParseResult {
  final CaseCatalog catalog;

  /// Entradas omitidas y por qué.
  final List<String> errors;

  const CatalogParseResult(this.catalog, this.errors);
}

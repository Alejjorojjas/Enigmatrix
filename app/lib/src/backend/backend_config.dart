/// Bandera de compilación del servidor (etapa 5A.2, ADR-0016).
///
/// `--dart-define=ENX_BACKEND=` admite tres valores:
///  - `none` (por defecto): la app valida en el teléfono, como hasta ahora.
///    No arranca Firebase ni usa la red.
///  - `emulator`: valida con el emulador local de Firebase (proyecto
///    `demo-enigmatrix`). El host se pasa con `--dart-define=ENX_EMULATOR_HOST=`.
///  - `firebase`: proyecto real. Se activa en la ronda de corte (5A.3).
///
/// Solo los casos de la campaña y del reto diario van al servidor. El tutorial
/// y el banco de pruebas validan siempre en el teléfono (ADR-0016).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BackendMode {
  none,
  emulator,
  firebase;

  /// true si la app habla con un servidor (emulador o real).
  bool get usesServer => this != BackendMode.none;
}

/// Valor crudo de `--dart-define=ENX_BACKEND=`.
const String kEnxBackendRaw = String.fromEnvironment(
  'ENX_BACKEND',
  defaultValue: 'none',
);

/// Valor crudo de `--dart-define=ENX_EMULATOR_HOST=` (vacío = el de la
/// plataforma).
const String kEnxEmulatorHostRaw = String.fromEnvironment(
  'ENX_EMULATOR_HOST',
  defaultValue: '',
);

/// Proyecto del emulador: con el prefijo `demo-` no usa nada real.
const String kEmulatorProjectId = 'demo-enigmatrix';

/// Región de las funciones (backend/functions/src/index.ts).
const String kFunctionsRegion = 'southamerica-east1';

/// Puertos del emulador (backend/firebase.json).
const int kAuthEmulatorPort = 9099;
const int kFunctionsEmulatorPort = 5001;

/// Convierte el texto de la bandera en un modo. Cualquier valor desconocido
/// cae en [BackendMode.none]: ante la duda, el comportamiento de siempre.
BackendMode parseBackendMode(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'emulator':
      return BackendMode.emulator;
    case 'firebase':
      return BackendMode.firebase;
    default:
      return BackendMode.none;
  }
}

/// Modo que de verdad se usa. En un build de release (el APK que se entrega)
/// el emulador no existe: `emulator` se comporta como `none`.
BackendMode effectiveBackendMode(
  BackendMode requested, {
  required bool releaseMode,
}) => (releaseMode && requested == BackendMode.emulator)
    ? BackendMode.none
    : requested;

/// Host del emulador: el pedido con `ENX_EMULATOR_HOST` o, si no, `localhost`
/// (web y escritorio) / `10.0.2.2` (emulador de Android).
String resolveEmulatorHost({
  String requested = kEnxEmulatorHostRaw,
  bool isWeb = kIsWeb,
  TargetPlatform platform = TargetPlatform.android,
}) {
  final host = requested.trim();
  if (host.isNotEmpty) return host;
  if (!isWeb && platform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}

/// Los casos que valida el servidor son los publicados: `mansion-*` (campaña)
/// y `reto-*` (reto diario). El tutorial y el banco `caso-*` no se publican.
bool isServerCaseId(String caseId) =>
    caseId.startsWith('mansion-') || caseId.startsWith('reto-');

/// Modo del servidor de esta compilación. Los tests lo sobreescriben.
final backendModeProvider = Provider<BackendMode>(
  (ref) => effectiveBackendMode(
    parseBackendMode(kEnxBackendRaw),
    releaseMode: kReleaseMode,
  ),
);

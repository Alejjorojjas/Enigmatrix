/// Apodo del jugador y borrado de la cuenta (etapa 5A.3).
///
/// Las reglas del apodo son las mismas que valida el servidor
/// (`setNickname`); aquí solo se revisan para avisar sin gastar una llamada.
/// El servidor tiene la última palabra (también filtra groserías).
///
/// Sin conexión el apodo se guarda en el teléfono (`profile:nick`) y queda
/// marcado como pendiente (`profile:nick-pending`): se reenvía al volver la
/// señal. SharedPreferences es solo cache; la verdad la tiene el servidor.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'validation_client.dart';
import 'validation_service.dart' show kPendingKey;

/// Apodo guardado en el teléfono (el mismo que muestra el Perfil).
const kNickKey = 'profile:nick';

/// '1' si el apodo guardado aún no llegó al servidor.
const kNickPendingKey = 'profile:nick-pending';

const int kNickMinLength = 3;
const int kNickMaxLength = 16;

/// Letras (con tildes y ñ), números, espacio, punto, guion y guion bajo.
final RegExp _allowedNick = RegExp(r'^[A-Za-z0-9À-ÖØ-öø-ÿ .\-_]+$');

enum NicknameProblem { tooShort, tooLong, invalidChars }

/// Apodo sin espacios a los lados, como lo guarda el servidor.
String cleanNickname(String raw) => raw.trim();

/// null si el apodo cumple las reglas; si no, el primer problema.
NicknameProblem? checkNickname(String raw) {
  final n = cleanNickname(raw);
  final length = n.runes.length;
  if (length < kNickMinLength) return NicknameProblem.tooShort;
  if (length > kNickMaxLength) return NicknameProblem.tooLong;
  if (!_allowedNick.hasMatch(n)) return NicknameProblem.invalidChars;
  return null;
}

/// Resultado de guardar un apodo.
sealed class NicknameResult {
  const NicknameResult();
}

/// Guardado. [synced] es false si quedó solo en el teléfono (sin conexión).
class NicknameSaved extends NicknameResult {
  const NicknameSaved(this.nickname, {required this.synced});
  final String nickname;
  final bool synced;
}

/// No cumple las reglas (revisado en el teléfono, sin llamar al servidor).
class NicknameInvalid extends NicknameResult {
  const NicknameInvalid(this.problem);
  final NicknameProblem problem;
}

/// El servidor lo rechazó; [message] es su explicación en español, si la dio.
class NicknameRejected extends NicknameResult {
  const NicknameRejected(this.message);
  final String? message;
}

/// Claves locales que se borran junto con la cuenta.
bool isAccountDataKey(String key) =>
    key == kPendingKey ||
    key == kNickKey ||
    key == kNickPendingKey ||
    key.startsWith('started:') ||
    key.startsWith('done:') ||
    key.startsWith('game:');

class NicknameService {
  NicknameService({
    required this.client,
    Future<SharedPreferences> Function()? loadPrefs,
    this.onAccountDeleted,
  }) : _loadPrefs = loadPrefs ?? SharedPreferences.getInstance;

  final ValidationClient client;

  /// Se llama tras borrar la cuenta (para olvidar la cola y la sesión en
  /// memoria).
  final Future<void> Function()? onAccountDeleted;

  final Future<SharedPreferences> Function() _loadPrefs;

  /// true si todavía no hay apodo guardado (primer arranque).
  static bool needsNickname(SharedPreferences prefs) =>
      (prefs.getString(kNickKey) ?? '').trim().isEmpty;

  Future<NicknameResult> save(String raw) async {
    final problem = checkNickname(raw);
    if (problem != null) return NicknameInvalid(problem);
    final nick = cleanNickname(raw);
    final prefs = await _loadPrefs();
    try {
      final saved = await client.setNickname(nick);
      await prefs.setString(kNickKey, saved);
      await prefs.remove(kNickPendingKey);
      return NicknameSaved(saved, synced: true);
    } on ValidationException catch (e) {
      if (e.kind == ValidationFailure.rejected) {
        return NicknameRejected(e.message);
      }
      // Sin señal (o el servidor no responde bien): se guarda aquí y se
      // reenvía después.
      await prefs.setString(kNickKey, nick);
      await prefs.setString(kNickPendingKey, '1');
      return NicknameSaved(nick, synced: false);
    }
  }

  /// Reenvía un apodo guardado sin conexión. Nunca lanza. Si el servidor lo
  /// rechaza, se olvida (la app volverá a pedirlo) y devuelve false.
  Future<bool> syncPending() async {
    try {
      final prefs = await _loadPrefs();
      if (prefs.getString(kNickPendingKey) != '1') return true;
      final nick = prefs.getString(kNickKey) ?? '';
      if (checkNickname(nick) != null) {
        await prefs.remove(kNickKey);
        await prefs.remove(kNickPendingKey);
        return false;
      }
      try {
        final saved = await client.setNickname(nick);
        await prefs.setString(kNickKey, saved);
        await prefs.remove(kNickPendingKey);
        return true;
      } on ValidationException catch (e) {
        if (e.kind == ValidationFailure.rejected) {
          await prefs.remove(kNickKey);
          await prefs.remove(kNickPendingKey);
          return false;
        }
        return true; // sin señal: se reintenta en otro momento
      }
    } on Object catch (e) {
      debugPrint('No se pudo reenviar el apodo: $e');
      return true;
    }
  }

  /// Borra la cuenta en el servidor y, si lo logra, todo lo local: cola de
  /// envíos, inicios, casos resueltos, partidas guardadas y apodo. Si el
  /// servidor falla, lanza [ValidationException] y no toca nada.
  Future<void> deleteAccount() async {
    await client.deleteAccount();
    final prefs = await _loadPrefs();
    for (final key in prefs.getKeys().where(isAccountDataKey).toList()) {
      await prefs.remove(key);
    }
    await onAccountDeleted?.call();
  }
}

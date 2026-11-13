/// Apodo y borrado de cuenta (etapa 5A.3): reglas iguales al servidor, guardado
/// sin conexión con reenvío, y borrado de lo local. Servidor falso, sin red.
library;

import 'package:enigmatrix/src/backend/nickname_service.dart';
import 'package:enigmatrix/src/backend/validation_service.dart'
    show kPendingKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_validation_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reglas del apodo', () {
    test('válidos: 3 a 16 caracteres tras quitar espacios', () {
      for (final ok in [
        'Ana',
        'Sherlock_H.',
        'María-José 7',
        'Ñandú',
        '  Pepe  ',
        'a' * 16,
        '  ${'b' * 16}  ',
        'Él.Ño-1_2',
      ]) {
        expect(checkNickname(ok), isNull, reason: '"$ok" debería valer');
      }
    });

    test('muy corto o muy largo', () {
      expect(checkNickname(''), NicknameProblem.tooShort);
      expect(checkNickname('  ab  '), NicknameProblem.tooShort);
      expect(checkNickname('a' * 17), NicknameProblem.tooLong);
    });

    test('caracteres no permitidos', () {
      for (final bad in [
        'Ana!',
        'Ana@x',
        'a/b/c',
        '😀😀😀',
        'Ana\nPepe',
        '漢字漢字',
      ]) {
        expect(
          checkNickname(bad),
          NicknameProblem.invalidChars,
          reason: '"$bad" no debería valer',
        );
      }
    });

    test('cleanNickname quita los espacios a los lados', () {
      expect(cleanNickname('  Ana Mar  '), 'Ana Mar');
    });
  });

  group('guardar el apodo', () {
    late FakeValidationClient client;
    late NicknameService service;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = FakeValidationClient();
      service = NicknameService(client: client);
    });

    test('válido y con conexión: el servidor lo limpia y se guarda', () async {
      final r = await service.save('  Sherlock  ');
      expect(r, isA<NicknameSaved>());
      expect((r as NicknameSaved).synced, isTrue);
      expect(r.nickname, 'Sherlock');
      expect(client.serverNickname, 'Sherlock');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Sherlock');
      expect(prefs.containsKey(kNickPendingKey), isFalse);
      expect(NicknameService.needsNickname(prefs), isFalse);
    });

    test('inválido: no llama al servidor ni guarda nada', () async {
      final r = await service.save('a!');
      expect(r, isA<NicknameInvalid>());
      expect(client.nicknameCalls, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(NicknameService.needsNickname(prefs), isTrue);
    });

    test('rechazado por el servidor (groserías): muestra su motivo', () async {
      final r = await service.save('Groseria99');
      expect(r, isA<NicknameRejected>());
      expect((r as NicknameRejected).message, 'Ese apodo no está permitido.');
      final prefs = await SharedPreferences.getInstance();
      expect(NicknameService.needsNickname(prefs), isTrue);
      expect(prefs.containsKey(kNickPendingKey), isFalse);
    });

    test(
      'sin conexión: se guarda local, queda pendiente y se reenvía',
      () async {
        client.online = false;
        final r = await service.save('Watson');
        expect(r, isA<NicknameSaved>());
        expect((r as NicknameSaved).synced, isFalse);
        var prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(kNickKey), 'Watson');
        expect(prefs.getString(kNickPendingKey), '1');
        expect(client.serverNickname, isNull);

        // Sigue sin señal: queda pendiente.
        expect(await service.syncPending(), isTrue);
        expect(prefs.getString(kNickPendingKey), '1');

        // Vuelve la señal.
        client.online = true;
        expect(await service.syncPending(), isTrue);
        prefs = await SharedPreferences.getInstance();
        expect(client.serverNickname, 'Watson');
        expect(prefs.containsKey(kNickPendingKey), isFalse);
        expect(prefs.getString(kNickKey), 'Watson');
      },
    );

    test(
      'pendiente que el servidor rechaza: se olvida y se vuelve a pedir',
      () async {
        client.online = false;
        await service.save('Grosería1'); // no contiene la palabra bloqueada
        client.online = true;
        client.blockedWords.add('grosería');
        expect(await service.syncPending(), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(NicknameService.needsNickname(prefs), isTrue);
        expect(prefs.containsKey(kNickPendingKey), isFalse);
      },
    );

    test('sin pendiente, syncPending no llama a nadie', () async {
      expect(await service.syncPending(), isTrue);
      expect(client.nicknameCalls, isEmpty);
    });
  });

  group('borrar la cuenta', () {
    late FakeValidationClient client;
    var resets = 0;
    late NicknameService service;
    setUp(() {
      resets = 0;
      SharedPreferences.setMockInitialValues({
        kPendingKey: '{"v":1,"items":[]}',
        'started:mansion-01': '1',
        'started:reto-003': '0',
        'done:mansion-01': '{"time":10}',
        'game:mansion-02': '{}',
        'fb:mansion-01': 'notas de playtest',
        kNickKey: 'Ana',
        kNickPendingKey: '1',
        // Estas se quedan: no son de la cuenta.
        'tutorial:v2:done': true,
        'settings:sound': false,
      });
      client = FakeValidationClient();
      service = NicknameService(
        client: client,
        onAccountDeleted: () async => resets++,
      );
    });

    test('isAccountDataKey reconoce solo lo de la cuenta', () {
      for (final k in [
        kPendingKey,
        kNickKey,
        kNickPendingKey,
        'started:x',
        'done:x',
        'game:x',
        'fb:mansion-01',
      ]) {
        expect(isAccountDataKey(k), isTrue, reason: k);
      }
      for (final k in ['tutorial:v2:done', 'settings:sound', 'skin']) {
        expect(isAccountDataKey(k), isFalse, reason: k);
      }
    });

    test('con conexión: borra en el servidor y limpia lo local', () async {
      await service.deleteAccount();
      expect(client.deleteCalls, 1);
      expect(client.accountDeleted, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'tutorial:v2:done', 'settings:sound'});
      expect(resets, 1);
    });

    test('sin conexión: falla y no toca nada local', () async {
      client.online = false;
      await expectLater(service.deleteAccount(), throwsA(anything));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Ana');
      expect(prefs.containsKey('done:mansion-01'), isTrue);
      expect(resets, 0);
    });
  });

  group('apodo desde el servidor al iniciar sesión', () {
    late FakeValidationClient client;
    late NicknameService service;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = FakeValidationClient()
        ..anonymous = false
        ..serverNickname = '  Sherlock ';
      service = NicknameService(client: client);
    });

    test('cuenta registrada sin apodo local: lo trae y lo guarda', () async {
      expect(await service.restoreFromServer(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Sherlock');
      expect(NicknameService.needsNickname(prefs), isFalse);
      expect(client.nicknameCalls, isEmpty); // solo lee, no escribe
    });

    test('con apodo local no lo toca ni consulta al servidor', () async {
      SharedPreferences.setMockInitialValues({kNickKey: 'Local'});
      expect(await service.restoreFromServer(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNickKey), 'Local');
      expect(client.fetchNicknameCalls, 0);
    });

    test('invitado: no consulta', () async {
      client.anonymous = true;
      expect(await service.restoreFromServer(), isFalse);
      expect(client.fetchNicknameCalls, 0);
    });

    test('sin apodo en el servidor, sin señal o inválido: no guarda', () async {
      client.serverNickname = null;
      expect(await service.restoreFromServer(), isFalse);
      client.serverNickname = 'Ana';
      client.online = false;
      expect(await service.restoreFromServer(), isFalse);
      client.online = true;
      client.serverNickname = 'a!';
      expect(await service.restoreFromServer(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(NicknameService.needsNickname(prefs), isTrue);
    });
  });
}

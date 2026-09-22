import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/login_attempt_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('começa em zero tentativas e não bloqueado', () async {
    final tracker = LoginAttemptTracker();
    expect(await tracker.tentativasFalhas(), 0);
    expect(await tracker.bloqueado(), isFalse);
  });

  test('registrarFalha incrementa e persiste o contador', () async {
    final tracker = LoginAttemptTracker();
    await tracker.registrarFalha();
    await tracker.registrarFalha();
    expect(await tracker.tentativasFalhas(), 2);

    final outraInstancia = LoginAttemptTracker();
    expect(await outraInstancia.tentativasFalhas(), 2);
  });

  test('resetar zera o contador', () async {
    final tracker = LoginAttemptTracker();
    await tracker.registrarFalha();
    await tracker.resetar();
    expect(await tracker.tentativasFalhas(), 0);
  });

  test('4 falhas não bloqueia', () async {
    final tracker = LoginAttemptTracker();
    for (var i = 0; i < 4; i++) {
      await tracker.registrarFalha();
    }
    expect(await tracker.bloqueado(), isFalse);
  });

  test('5 falhas bloqueia', () async {
    final tracker = LoginAttemptTracker();
    for (var i = 0; i < LoginAttemptTracker.limiteTentativas; i++) {
      await tracker.registrarFalha();
    }
    expect(await tracker.bloqueado(), isTrue);
  });

  test('bloqueado há menos de 15 minutos continua bloqueado', () async {
    var agora = DateTime(2026, 1, 1, 12, 0);
    final tracker = LoginAttemptTracker(relogio: () => agora);
    for (var i = 0; i < LoginAttemptTracker.limiteTentativas; i++) {
      await tracker.registrarFalha();
    }

    agora = agora.add(
      LoginAttemptTracker.duracaoBloqueio - const Duration(seconds: 1),
    );

    expect(await tracker.bloqueado(), isTrue);
  });

  test('bloqueado há 15 minutos ou mais libera e zera o contador', () async {
    var agora = DateTime(2026, 1, 1, 12, 0);
    final tracker = LoginAttemptTracker(relogio: () => agora);
    for (var i = 0; i < LoginAttemptTracker.limiteTentativas; i++) {
      await tracker.registrarFalha();
    }

    agora = agora.add(LoginAttemptTracker.duracaoBloqueio);

    expect(await tracker.bloqueado(), isFalse);
    expect(await tracker.tentativasFalhas(), 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/domain/auth_validators.dart';

void main() {
  group('validarEmail', () {
    test('rejeita e-mail vazio', () {
      expect(validarEmail(''), 'Informe seu e-mail.');
    });

    test('rejeita e-mail sem formato válido', () {
      expect(validarEmail('nao-e-email'), 'E-mail inválido.');
    });

    test('aceita e-mail válido', () {
      expect(validarEmail('usuario@exemplo.com'), isNull);
    });
  });

  group('validarSenha', () {
    test('rejeita senha vazia', () {
      expect(validarSenha(''), 'A senha deve ter no mínimo 8 caracteres.');
    });

    test('rejeita senha com 7 caracteres', () {
      expect(validarSenha('abc1234'), 'A senha deve ter no mínimo 8 caracteres.');
    });

    test('aceita senha com 8 caracteres', () {
      expect(validarSenha('abc12345'), isNull);
    });

    test('aceita senha com mais de 8 caracteres', () {
      expect(validarSenha('abc123456'), isNull);
    });
  });
}

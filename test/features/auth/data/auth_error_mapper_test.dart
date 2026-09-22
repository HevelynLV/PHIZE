import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/auth_error_mapper.dart';

void main() {
  test('mapeia email-already-in-use', () {
    final excecao = FirebaseAuthException(code: 'email-already-in-use');
    expect(
      mapearErroAutenticacao(excecao),
      'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.',
    );
  });

  test(
    'mapeia user-not-found, wrong-password e invalid-credential para a mesma mensagem genérica',
    () {
      for (final codigo in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      ]) {
        final excecao = FirebaseAuthException(code: codigo);
        expect(mapearErroAutenticacao(excecao), 'E-mail ou senha incorretos.');
      }
    },
  );

  test('mapeia too-many-requests', () {
    final excecao = FirebaseAuthException(code: 'too-many-requests');
    expect(
      mapearErroAutenticacao(excecao),
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
    );
  });

  test('mapeia network-request-failed', () {
    final excecao = FirebaseAuthException(code: 'network-request-failed');
    expect(
      mapearErroAutenticacao(excecao),
      'Falha de conexão. Verifique sua internet e tente novamente.',
    );
  });

  test('mapeia código desconhecido para mensagem padrão', () {
    final excecao = FirebaseAuthException(code: 'algum-erro-novo');
    expect(
      mapearErroAutenticacao(excecao),
      'Não foi possível concluir a operação. Tente novamente.',
    );
  });
}

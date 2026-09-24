import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/normalizacao_url.dart';

void main() {
  group('normalizarUrlReputacao', () {
    test('URL com query: a query é descartada', () {
      expect(
        normalizarUrlReputacao('https://golpe.com.br/login?cpf=123&x=1'),
        'https://golpe.com.br/login',
      );
    });

    test('URL com fragmento: o fragmento é descartado', () {
      expect(
        normalizarUrlReputacao('https://golpe.com.br/pagar#token=abc'),
        'https://golpe.com.br/pagar',
      );
      expect(
        normalizarUrlReputacao('https://golpe.com.br/a?b=1#c'),
        'https://golpe.com.br/a',
      );
    });

    test('URL com caminho: o caminho é preservado', () {
      expect(
        normalizarUrlReputacao('https://site.com.br/wp-content/banco/login'),
        'https://site.com.br/wp-content/banco/login',
      );
      expect(
        normalizarUrlReputacao(
          'http://testsafebrowsing.appspot.com/s/phishing.html',
        ),
        'http://testsafebrowsing.appspot.com/s/phishing.html',
      );
    });

    test('URL sem caminho: recebe "/"', () {
      expect(
        normalizarUrlReputacao('https://itau.com.br'),
        'https://itau.com.br/',
      );
      expect(normalizarUrlReputacao('itau.com.br'), 'http://itau.com.br/');
    });

    test('host e esquema em minúsculas; caminho mantém a caixa', () {
      expect(
        normalizarUrlReputacao('HTTPS://Golpe.COM.br/Login'),
        'https://golpe.com.br/Login',
      );
    });

    test('usuário e senha embutidos são descartados', () {
      final url = normalizarUrlReputacao('https://joao:senha@golpe.com.br/x');
      expect(url, 'https://golpe.com.br/x');
    });

    test('"www." é mantido (o Safe Browsing pode listar o subdomínio)', () {
      expect(
        normalizarUrlReputacao('https://www.golpe.com.br/'),
        'https://www.golpe.com.br/',
      );
    });

    test('porta não padrão é mantida', () {
      expect(
        normalizarUrlReputacao('http://golpe.com.br:8080/a'),
        'http://golpe.com.br:8080/a',
      );
    });

    test('entradas inválidas devolvem null', () {
      for (final entrada in [
        '',
        '   ',
        'não é url',
        'ftp://golpe.com.br/',
        'http://localhost/',
        'https://itaú.com.br/',
      ]) {
        expect(normalizarUrlReputacao(entrada), isNull, reason: entrada);
      }
    });

    test('a normalização é determinística', () {
      const entradas = [
        'https://golpe.com.br/login?cpf=123#x',
        'itau.com.br',
        'HTTP://Site.com.br/Caminho/',
      ];
      for (final entrada in entradas) {
        final primeira = normalizarUrlReputacao(entrada);
        for (var i = 0; i < 5; i++) {
          expect(normalizarUrlReputacao(entrada), primeira);
        }
      }
    });
  });

  group('normalizarDominio continua devolvendo só o domínio', () {
    test('caminho, query e fragmento não afetam o domínio', () {
      expect(
        normalizarDominio('https://www.golpe.com.br/login?cpf=1#x'),
        'golpe.com.br',
      );
    });

    test('"www.com" continua inválido', () {
      expect(normalizarDominio('www.com'), isNull);
    });
  });
}

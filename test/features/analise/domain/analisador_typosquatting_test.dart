import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analisador_typosquatting.dart';

void main() {
  group('Domínio legítimo', () {
    test('domínio real de uma marca da lista não é marcado como '
        'typosquatting', () {
      final resultado = AnalisadorTyposquatting.analisar('itau.com.br');
      expect(resultado.entradaValida, isTrue);
      expect(resultado.typosquattingDetectado, isFalse);
      expect(resultado.marcaImitada, isNull);
      expect(resultado.dominioNormalizado, 'itau.com.br');
    });
  });

  group('Variações detectadas (typosquatting)', () {
    test('uma letra trocada é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar('ital.com.br');
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });

    test('uma letra a mais é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar('itaau.com.br');
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });

    test('uma letra a menos é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar('ita.com.br');
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });
  });

  group('Subdomínio enganoso', () {
    test('marca fora do domínio principal é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'itau.dominio-falso.com',
      );
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
      expect(resultado.dominioNormalizado, 'itau.dominio-falso.com');
    });
  });

  group('Domínio não relacionado', () {
    test('domínio sem relação com a lista não é marcado', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'meusite-pessoal.com.br',
      );
      expect(resultado.typosquattingDetectado, isFalse);
      expect(resultado.marcaImitada, isNull);
    });
  });

  group('Normalização', () {
    test('mesmo domínio com/sem www, maiúsculas e parâmetros de consulta '
        'produz o mesmo resultado', () {
      final semVariacao = AnalisadorTyposquatting.analisar('itau.com.br');
      final comWww = AnalisadorTyposquatting.analisar('www.itau.com.br');
      final maiusculo = AnalisadorTyposquatting.analisar('ITAU.COM.BR');
      final comQuery = AnalisadorTyposquatting.analisar(
        'itau.com.br?ref=123',
      );
      final comEsquemaEBarra = AnalisadorTyposquatting.analisar(
        'https://WWW.Itau.COM.BR/',
      );

      for (final resultado in [
        comWww,
        maiusculo,
        comQuery,
        comEsquemaEBarra,
      ]) {
        expect(resultado.dominioNormalizado, semVariacao.dominioNormalizado);
        expect(
          resultado.typosquattingDetectado,
          semVariacao.typosquattingDetectado,
        );
      }
    });
  });

  group('Determinismo', () {
    test('mesma entrada produz sempre o mesmo resultado', () {
      const entrada = 'itau.dominio-falso.com';
      final primeira = AnalisadorTyposquatting.analisar(entrada);
      final segunda = AnalisadorTyposquatting.analisar(entrada);
      final terceira = AnalisadorTyposquatting.analisar(entrada);

      expect(segunda.typosquattingDetectado, primeira.typosquattingDetectado);
      expect(segunda.marcaImitada, primeira.marcaImitada);
      expect(segunda.dominioNormalizado, primeira.dominioNormalizado);
      expect(
        terceira.typosquattingDetectado,
        primeira.typosquattingDetectado,
      );
      expect(terceira.marcaImitada, primeira.marcaImitada);
      expect(terceira.dominioNormalizado, primeira.dominioNormalizado);
    });
  });

  group('Casos-limite', () {
    test('domínio muito curto não gera falso positivo (marca de 2 letras '
        'exige correspondência exata)', () {
      final resultado = AnalisadorTyposquatting.analisar('cb.com.br');
      expect(resultado.typosquattingDetectado, isFalse);
    });

    test('entrada que não é uma URL válida', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'isto não é uma url',
      );
      expect(resultado.entradaValida, isFalse);
      expect(resultado.dominioNormalizado, isNull);
      expect(resultado.typosquattingDetectado, isFalse);
    });

    test('entrada vazia é inválida', () {
      final resultado = AnalisadorTyposquatting.analisar('');
      expect(resultado.entradaValida, isFalse);
    });

    test('entrada sem TLD é inválida', () {
      final resultado = AnalisadorTyposquatting.analisar('12345');
      expect(resultado.entradaValida, isFalse);
    });

    test('host com acento é entrada inválida, sem lançar exceção', () {
      final resultado = AnalisadorTyposquatting.analisar('itaú.com.br');
      expect(resultado.entradaValida, isFalse);
      expect(resultado.dominioNormalizado, isNull);
      expect(resultado.typosquattingDetectado, isFalse);
    });

    test(
      'não gera falso positivo para nome de 4 a 6 letras (equivalente ao '
      'caso cb.com.br para nomes curtos)',
      () {
        final resultado = AnalisadorTyposquatting.analisar('zorve.com.br');
        expect(resultado.typosquattingDetectado, isFalse);
      },
    );
  });

  group('Correções da auditoria (marca embutida em rótulo composto)', () {
    test('marca como prefixo de rótulo composto é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'itau-seguranca.com.br',
      );
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });

    test('marca embutida em subdomínio composto é detectada', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'meu-itau.atendimento-cliente.net',
      );
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });

    test('marca como prefixo de outro rótulo composto (nubank)', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'nubank-app.com.br',
      );
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'nubank');
    });

    test('domínio não relacionado com rótulo composto não é marcado '
        '(regressão)', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'padaria-do-joao.com.br',
      );
      expect(resultado.typosquattingDetectado, isFalse);
    });

    test('nome da marca apenas como parte de outra palavra não dispara', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'interior-moveis.com.br',
      );
      expect(resultado.typosquattingDetectado, isFalse);
    });
  });

  group('Correções da auditoria (caracteres visualmente confundíveis)', () {
    test('"ll" no lugar de "l" é detectado como imitação (itall -> ital)', () {
      final resultado = AnalisadorTyposquatting.analisar('itall.com.br');
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'itau');
    });
  });

  group('Correções da auditoria (apelidos de marca)', () {
    test('domínio legítimo por apelido não é marcado (inter)', () {
      final resultado = AnalisadorTyposquatting.analisar('inter.com.br');
      expect(resultado.typosquattingDetectado, isFalse);
    });
  });

  group('Regressão pós-correções', () {
    test('itau.com.br permanece não detectado', () {
      expect(
        AnalisadorTyposquatting.analisar('itau.com.br').typosquattingDetectado,
        isFalse,
      );
    });

    test('bb.com.br permanece não detectado', () {
      expect(
        AnalisadorTyposquatting.analisar('bb.com.br').typosquattingDetectado,
        isFalse,
      );
    });

    test('caixa.dominio-falso.com permanece detectado (caixa)', () {
      final resultado = AnalisadorTyposquatting.analisar(
        'caixa.dominio-falso.com',
      );
      expect(resultado.typosquattingDetectado, isTrue);
      expect(resultado.marcaImitada, 'caixa');
    });

    test('bc.com.br permanece não detectado', () {
      expect(
        AnalisadorTyposquatting.analisar('bc.com.br').typosquattingDetectado,
        isFalse,
      );
    });
  });
}

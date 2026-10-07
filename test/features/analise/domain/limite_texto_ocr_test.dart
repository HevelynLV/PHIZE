import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/limite_texto_ocr.dart';
import 'package:phize/features/analise/domain/mascaramento_local.dart';

void main() {
  group('tabela de aferição de docs/limite-texto-ocr.md', () {
    for (final texto in [
      'Oi mãe, troquei de número',
      'Pix de R\$ 500 por favor',
      'Seu CPF foi bloqueado',
    ]) {
      test('passa: "$texto"', () {
        expect(LimiteTextoOcr.atende(texto), isTrue);
      });
    }

    for (final ruido in ['', '   ', '\n\n', '|||', 'Ok', '12:45 ✓✓', '@ #']) {
      test('ruído de OCR não passa: "$ruido"', () {
        expect(LimiteTextoOcr.atende(ruido), isFalse);
      });
    }
  });

  group('as duas condições são cumulativas', () {
    test('caracteres suficientes, palavras insuficientes: não passa', () {
      final palavra = 'x' * LimiteTextoOcr.minimoCaracteres;
      final texto = List.filled(
        LimiteTextoOcr.minimoPalavras - 1,
        palavra,
      ).join(' ');
      expect(LimiteTextoOcr.atende(texto), isFalse);
    });

    test('palavras suficientes, caracteres insuficientes: não passa', () {
      final texto = List.filled(LimiteTextoOcr.minimoPalavras, 'a').join(' ');
      expect(texto.length, lessThan(LimiteTextoOcr.minimoCaracteres));
      expect(LimiteTextoOcr.atende(texto), isFalse);
    });

    test('exatamente no mínimo das duas: passa', () {
      // minimoPalavras palavras de uma letra, completadas até o mínimo de
      // caracteres na última.
      final base = List.filled(LimiteTextoOcr.minimoPalavras - 1, 'a');
      final usados = base.join(' ').length + 1;
      final texto = [
        ...base,
        'b' * (LimiteTextoOcr.minimoCaracteres - usados),
      ].join(' ');
      expect(texto.runes.length, LimiteTextoOcr.minimoCaracteres);
      expect(LimiteTextoOcr.atende(texto), isTrue);

      final umAMenos = texto.substring(0, texto.length - 1);
      expect(LimiteTextoOcr.atende(umAMenos), isFalse);
    });
  });

  test('quebras de linha e espaços repetidos do OCR contam como um', () {
    expect(LimiteTextoOcr.atende('Seu   CPF\nfoi\n\n bloqueado'), isTrue);
    expect(LimiteTextoOcr.atende('  Oi  \n\n  tudo    bem   \n  '), isFalse);
  });

  group('segunda verificação, após o mascaramento', () {
    test('"Pix para [CHAVE_PIX] agora" passa', () {
      expect(
        LimiteTextoOcr.atendeAposMascaramento('Pix para [CHAVE_PIX] agora'),
        isTrue,
      );
    });

    test('"[TELEFONE] [EMAIL] [CPF] [CNPJ]" é interrompido', () {
      // Passaria na primeira verificação, que não distingue marcadores.
      expect(LimiteTextoOcr.atende('[TELEFONE] [EMAIL] [CPF] [CNPJ]'), isTrue);
      expect(
        LimiteTextoOcr.atendeAposMascaramento(
          '[TELEFONE] [EMAIL] [CPF] [CNPJ]',
        ),
        isFalse,
      );
    });

    test('nenhum marcador conta como conteúdo', () {
      final soMarcadores = marcadoresMascaramento.join(' ');
      expect(LimiteTextoOcr.atendeAposMascaramento(soMarcadores), isFalse);
      expect(LimiteTextoOcr.atendeAposMascaramento('[CARTAO] 12/29'), isFalse);
    });

    test('as duas condições são cumulativas', () {
      // Caracteres suficientes, uma palavra só.
      final umaPalavra = 'x' * LimiteTextoOcr.minimoCaracteresAposMascaramento;
      expect(LimiteTextoOcr.atendeAposMascaramento(umaPalavra), isFalse);
      // Palavras suficientes, caracteres insuficientes.
      final curtas = List.filled(
        LimiteTextoOcr.minimoPalavrasAposMascaramento,
        'a',
      ).join(' ');
      expect(LimiteTextoOcr.atendeAposMascaramento(curtas), isFalse);
    });

    test('marcador colado ao texto não soma caracteres', () {
      // "Pix[CHAVE_PIX]" vira "Pix" — uma palavra de três letras.
      expect(LimiteTextoOcr.atendeAposMascaramento('Pix[CHAVE_PIX]'), isFalse);
    });

    test('todo marcador emitido pelo mascaramento está na lista', () {
      final mascarado = mascararTextoLocal(
        'CPF 123.456.789-09, CNPJ 12.345.678/0001-90, fone (11) 91234-5678, '
        'e-mail a@b.com, chave 123e4567-e89b-12d3-a456-426614174000, '
        'cartão 4111 1111 1111 1111, boleto '
        '23793.38128 60000.000003 00000.000400 1 84340000012345',
      );
      final emitidos = RegExp(r'\[[A-Z_]+\]')
          .allMatches(mascarado)
          .map((m) => m.group(0))
          .toSet();
      expect(emitidos, marcadoresMascaramento.toSet());
    });
  });

  test('primeira verificação: marcadores contam como o texto que são', () {
    expect(LimiteTextoOcr.atende('[CPF]'), isFalse);
    expect(LimiteTextoOcr.atende('[CARTAO] 12/29'), isFalse);
  });
}

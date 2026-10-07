import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/mascaramento_local.dart';

void main() {
  group('CPF', () {
    test('mascara CPF formatado (000.000.000-00)', () {
      expect(
        mascararTextoLocal('Meu CPF é 123.456.789-09.'),
        'Meu CPF é [CPF].',
      );
    });

    test('mascara CPF sem pontuação (00000000000)', () {
      expect(mascararTextoLocal('Meu CPF é 12345678909.'), 'Meu CPF é [CPF].');
    });

    test('CPF sem pontuação cujo terceiro dígito não é 9 continua [CPF]', () {
      expect(mascararTextoLocal('12345678900'), '[CPF]');
    });

    test('CPF formatado continua [CPF] (regressão)', () {
      expect(mascararTextoLocal('123.456.789-00'), '[CPF]');
    });

    test('11 dígitos com DDD inválido viram [CPF], mesmo com 9 após o DDD', () {
      // 20, 23 e 00 não são DDDs brasileiros.
      for (final numero in ['20987654321', '23987654321', '00987654321']) {
        expect(mascararTextoLocal(numero), '[CPF]', reason: numero);
      }
    });
  });

  group('CNPJ', () {
    test('mascara CNPJ formatado', () {
      expect(
        mascararTextoLocal('CNPJ da empresa: 12.345.678/0001-95.'),
        'CNPJ da empresa: [CNPJ].',
      );
    });

    test('mascara CNPJ sem pontuação (14 dígitos)', () {
      expect(
        mascararTextoLocal('CNPJ da empresa: 12345678000195.'),
        'CNPJ da empresa: [CNPJ].',
      );
    });
  });

  group('Telefone', () {
    test('mascara telefone com DDD', () {
      expect(
        mascararTextoLocal('Ligue para (11) 91234-5678 agora.'),
        'Ligue para [TELEFONE] agora.',
      );
    });

    test('mascara telefone sem DDD', () {
      expect(
        mascararTextoLocal('Ligue para 91234-5678 agora.'),
        'Ligue para [TELEFONE] agora.',
      );
    });

    test('mascara telefone com DDI (+55), com separadores', () {
      expect(
        mascararTextoLocal('Ligue para +55 11 91234-5678 agora.'),
        'Ligue para [TELEFONE] agora.',
      );
    });

    test('mascara telefone com DDI (+55), sem separadores', () {
      expect(
        mascararTextoLocal('Ligue para +5511912345678 agora.'),
        'Ligue para [TELEFONE] agora.',
      );
    });

    test('mascara telefone com espaços: "11 98765 4321"', () {
      expect(
        mascararTextoLocal('Me chama no 11 98765 4321 hoje.'),
        'Me chama no [TELEFONE] hoje.',
      );
    });

    test('variações com espaço entre DDD e número ou entre as metades', () {
      for (final numero in [
        '11 98765 4321',
        '11 98765-4321',
        '11 987654321',
        '11 3456 7890',
        '(11) 98765 4321',
        '+55 11 98765 4321',
      ]) {
        expect(
          mascararTextoLocal('Fone $numero.'),
          'Fone [TELEFONE].',
          reason: numero,
        );
      }
    });

    test('celular de 11 dígitos corridos vira [TELEFONE], não [CPF]', () {
      expect(
        mascararTextoLocal('me manda um Pix de R\$ 500 no 11987654321'),
        'me manda um Pix de R\$ 500 no [TELEFONE]',
      );
      expect(mascararTextoLocal('21998887777'), '[TELEFONE]');
    });

    test('regressão: DDI, parênteses e hífen continuam [TELEFONE]', () {
      expect(mascararTextoLocal('+55 11 91234-5678'), '[TELEFONE]');
      expect(mascararTextoLocal('+5511912345678'), '[TELEFONE]');
      expect(mascararTextoLocal('(11) 91234-5678'), '[TELEFONE]');
      expect(mascararTextoLocal('91234-5678'), '[TELEFONE]');
    });

    test('nenhum dígito do telefone com espaços sobra', () {
      final mascarado = mascararTextoLocal(
        'Liga 11 98765 4321 ou 21 3456-7890',
      );
      expect(mascarado, 'Liga [TELEFONE] ou [TELEFONE]');
      expect(mascarado, isNot(contains(RegExp(r'\d'))));
    });
  });

  group('Cartão', () {
    test('mascara número de cartão com espaços', () {
      expect(
        mascararTextoLocal('Cartão: 1234 5678 9012 3456.'),
        'Cartão: [CARTAO].',
      );
    });

    test('mascara número de cartão com hífens', () {
      expect(
        mascararTextoLocal('Cartão: 1234-5678-9012-3456.'),
        'Cartão: [CARTAO].',
      );
    });
  });

  group('Boleto', () {
    test('mascara linha digitável de 47 dígitos', () {
      final boleto47 = List.generate(47, (i) => (i % 10).toString()).join();
      expect(
        mascararTextoLocal('Pague o boleto $boleto47 até amanhã.'),
        'Pague o boleto [BOLETO] até amanhã.',
      );
    });

    test('mascara linha digitável de 48 dígitos (convênio)', () {
      final boleto48 = List.generate(48, (i) => (i % 10).toString()).join();
      expect(
        mascararTextoLocal('Pague o boleto $boleto48 até amanhã.'),
        'Pague o boleto [BOLETO] até amanhã.',
      );
    });

    // Linha digitável no formato impresso (47 dígitos em blocos com pontos
    // e espaços) e a mesma linha sem formatação.
    const formatada = '23793.38128 60000.000003 00000.000400 1 84340000012345';
    const semFormatacao = '23793381286000000000300000000400184340000012345';

    test(
      'mascara linha digitável formatada em blocos com pontos e espaços',
      () {
        expect(mascararTextoLocal(formatada), '[BOLETO]');
      },
    );

    test('a mesma linha sem formatação continua virando [BOLETO]', () {
      expect(semFormatacao.length, 47);
      expect(mascararTextoLocal(semFormatacao), '[BOLETO]');
    });

    test('linha formatada dentro de uma frase, com texto antes e depois', () {
      expect(
        mascararTextoLocal('Pague o boleto $formatada até amanhã, por favor.'),
        'Pague o boleto [BOLETO] até amanhã, por favor.',
      );
      expect(
        mascararTextoLocal('Linha digitável:\n$formatada\nVencimento hoje.'),
        'Linha digitável:\n[BOLETO]\nVencimento hoje.',
      );
      expect(
        mascararTextoLocal('Segue o código $formatada, pague hoje.'),
        'Segue o código [BOLETO], pague hoje.',
      );
    });

    test('valor monetário na mesma frase não é afetado', () {
      expect(
        mascararTextoLocal(
          'Boleto de R\$ 1.234,56, linha $formatada, vence hoje.',
        ),
        'Boleto de R\$ 1.234,56, linha [BOLETO], vence hoje.',
      );
      // Valor colado à linha: os centavos e o valor não são absorvidos.
      expect(
        mascararTextoLocal('Total R\$ 150,00 $formatada'),
        'Total R\$ 150,00 [BOLETO]',
      );
      expect(
        mascararTextoLocal('Total R\$ 500 $formatada'),
        'Total R\$ 500 [BOLETO]',
      );
      expect(
        mascararTextoLocal('Linha $formatada 50,00 de multa'),
        'Linha [BOLETO] 50,00 de multa',
      );
    });

    test('blocos numéricos fora da faixa de dígitos não viram [BOLETO]', () {
      // Cartão com espaços continua como cartão; números curtos ficam
      // intactos.
      expect(
        mascararTextoLocal('Cartão 4111 1111 1111 1111 vence 12/29'),
        'Cartão [CARTAO] vence 12/29',
      );
      expect(
        mascararTextoLocal('Pedido 123 com 2 itens, versão 1.2.3'),
        'Pedido 123 com 2 itens, versão 1.2.3',
      );
    });

    // Convênio (contas de luz e água): 4 blocos de 11 dígitos, cada um com
    // o dígito verificador após hífen — 48 dígitos.
    const convenioComEspacos =
        '83640000001-1 47530000000-1 00000000000-0 12345678901-2';
    const convenioSemEspacos =
        '83640000001-147530000000-100000000000-012345678901-2';

    test('linha de convênio com espaços entre os blocos vira [BOLETO]', () {
      expect(
        mascararTextoLocal('Conta de luz $convenioComEspacos, vence dia 10.'),
        'Conta de luz [BOLETO], vence dia 10.',
      );
    });

    test('linha de convênio sem espaços entre os blocos vira [BOLETO]', () {
      expect(
        mascararTextoLocal('Conta de água $convenioSemEspacos'),
        'Conta de água [BOLETO]',
      );
    });

    test('convênio não deixa dígitos verificadores soltos nem vira [CPF]', () {
      final mascarado = mascararTextoLocal(convenioComEspacos);
      expect(mascarado, '[BOLETO]');
      expect(mascarado, isNot(contains('[CPF]')));
      expect(mascarado, isNot(contains(RegExp(r'\d'))));
    });

    test('hífen não junta CPF, telefone ou data a uma linha de boleto', () {
      expect(
        mascararTextoLocal('CPF 123.456.789-09, fone 91234-5678, dia 07-10'),
        'CPF [CPF], fone [TELEFONE], dia 07-10',
      );
    });

    test('regressão: linhas bancárias continuam virando [BOLETO]', () {
      expect(mascararTextoLocal(formatada), '[BOLETO]');
      expect(mascararTextoLocal(semFormatacao), '[BOLETO]');
    });
  });

  group('Chave Pix aleatória (UUID)', () {
    test('mascara chave Pix no formato UUID', () {
      expect(
        mascararTextoLocal(
          'Minha chave Pix é a1b2c3d4-e5f6-47a8-9b0c-d1e2f3a4b5c6, '
          'pode transferir.',
        ),
        'Minha chave Pix é [CHAVE_PIX], pode transferir.',
      );
    });
  });

  group('E-mail', () {
    test('mascara endereço de e-mail', () {
      expect(
        mascararTextoLocal('Envie para atendimento@banco-exemplo.com.br.'),
        'Envie para [EMAIL].',
      );
    });
  });

  group('Múltiplas ocorrências', () {
    test('mascara CPF e telefone na mesma mensagem (tipos diferentes)', () {
      expect(
        mascararTextoLocal(
          'Envie seu CPF 123.456.789-09 e ligue para (11) 91234-5678.',
        ),
        'Envie seu CPF [CPF] e ligue para [TELEFONE].',
      );
    });

    test('mascara duas ocorrências do mesmo tipo', () {
      expect(
        mascararTextoLocal('Ligue para (11) 91234-5678 ou (21) 98888-7777.'),
        'Ligue para [TELEFONE] ou [TELEFONE].',
      );
    });
  });

  group('Preservação (arquitetura 5.2)', () {
    test('preserva verbos de urgência', () {
      final resultado = mascararTextoLocal(
        'URGENTE: responda em 10 minutos ou perderá o acesso, '
        'informe seu CPF 123.456.789-09.',
      );
      expect(resultado, contains('URGENTE'));
      expect(resultado, contains('responda em 10 minutos'));
      expect(resultado, contains('[CPF]'));
      expect(resultado, isNot(contains('123.456.789-09')));
    });

    test('preserva valores monetários (R\$ 1.500,00)', () {
      final resultado = mascararTextoLocal(
        'Transfira R\$ 1.500,00 para o CPF 123.456.789-09 agora.',
      );
      expect(resultado, contains(r'R$ 1.500,00'));
      expect(resultado, contains('[CPF]'));
    });

    test('preserva domínios e URLs', () {
      final resultado = mascararTextoLocal(
        'Acesse www.banco-exemplo.com.br e informe o CPF 123.456.789-09.',
      );
      expect(resultado, contains('www.banco-exemplo.com.br'));
      expect(resultado, contains('[CPF]'));
    });

    test('preserva a estrutura argumentativa do texto', () {
      const entrada =
          'Se você não pagar o boleto até amanhã, seu nome vai para o SPC.';
      expect(mascararTextoLocal(entrada), entrada);
    });
  });

  group('Texto sem dado pessoal', () {
    test('sai idêntico ao original', () {
      const entrada =
          'URGENTE: sua conta será bloqueada em 24 horas, pague '
          'R\$ 1.500,00 agora acessando www.banco-exemplo.com.br.';
      expect(mascararTextoLocal(entrada), entrada);
    });
  });

  group('Determinismo', () {
    test('mesma entrada produz sempre a mesma saída', () {
      const entrada =
          'CPF 123.456.789-09, telefone (11) 91234-5678, '
          'cartão 1234 5678 9012 3456.';

      final primeiraExecucao = mascararTextoLocal(entrada);
      final segundaExecucao = mascararTextoLocal(entrada);
      final terceiraExecucao = mascararTextoLocal(entrada);

      expect(segundaExecucao, primeiraExecucao);
      expect(terceiraExecucao, primeiraExecucao);
    });
  });

  group('Casos-limite', () {
    test(
      'número que parece CPF mas é valor monetário longo não é mascarado',
      () {
        const entrada = 'O prêmio foi de R\$ 12345678901,00 para o ganhador.';
        expect(mascararTextoLocal(entrada), entrada);
      },
    );

    test('telefone dentro de uma URL não quebra o domínio (URL preservada '
        'por inteiro)', () {
      const entrada =
          'Acesse https://meubanco.com.br/91234-5678 para confirmar.';
      expect(mascararTextoLocal(entrada), entrada);
    });

    test('CPF e valor monetário na mesma frase: só o CPF é mascarado', () {
      final resultado = mascararTextoLocal(
        'Informe o CPF 123.456.789-09 e pague R\$ 1.500,00 hoje.',
      );
      expect(resultado, 'Informe o CPF [CPF] e pague R\$ 1.500,00 hoje.');
    });
  });

  group('Correções da auditoria (Fase 3)', () {
    test('cartão de 16 dígitos corridos, sem separadores, vira [CARTAO]', () {
      expect(
        mascararTextoLocal('Pedido 1234567890123456 confirmado'),
        'Pedido [CARTAO] confirmado',
      );
    });

    test('domínio com dígitos colados permanece intacto, sem máscara', () {
      const entrada = 'Acesse whatsapp-seguro11987654321.com agora';
      expect(mascararTextoLocal(entrada), entrada);
    });

    test('URL completa permanece intacta', () {
      const entrada = 'https://banco.com/pag/12345678901';
      expect(mascararTextoLocal(entrada), entrada);
    });

    test('boleto de 44 dígitos (fora de 47/48) vira [BOLETO]', () {
      final boleto44 = List.generate(44, (i) => (i % 10).toString()).join();
      expect(
        mascararTextoLocal('Pague o boleto $boleto44 até amanhã.'),
        'Pague o boleto [BOLETO] até amanhã.',
      );
    });

    test('boleto de 47 e de 48 dígitos nunca vira [CARTAO]', () {
      final boleto47 = List.generate(47, (i) => (i % 10).toString()).join();
      final boleto48 = List.generate(48, (i) => (i % 10).toString()).join();
      expect(mascararTextoLocal(boleto47), '[BOLETO]');
      expect(mascararTextoLocal(boleto48), '[BOLETO]');
    });

    test('CPF e valor monetário na mesma frase (texto da auditoria)', () {
      expect(
        mascararTextoLocal('Transfere R\$ 1.500,00 para o CPF 123.456.789-00'),
        'Transfere R\$ 1.500,00 para o CPF [CPF]',
      );
    });
  });

  group(
    'Correções da 2ª auditoria (colisão de marcador e URL sem esquema)',
    () {
      test(
        'caractere U+E000 pré-existente não corrompe a restauração da URL',
        () {
          const entrada = 'Antes  depois https://banco.com/x meio.';
          expect(mascararTextoLocal(entrada), entrada);
        },
      );

      test(
        'vários caracteres da Área de Uso Privado não corrompem a restauração',
        () {
          const entrada = ' Acesse https://loja.com/a agora.';
          expect(mascararTextoLocal(entrada), entrada);
        },
      );

      test('domínio sem esquema com caminho permanece intacto', () {
        const entrada = 'bb-seguranca.net/pagamento/12345678901';
        expect(mascararTextoLocal(entrada), entrada);
      });

      test('URL com esquema e caminho longo continua intacta (regressão)', () {
        const entrada = 'https://bb-seguranca.net/pagamento/12345678901';
        expect(mascararTextoLocal(entrada), entrada);
      });
    },
  );

  group('Textos da 2ª auditoria (mesmo resultado após a correção)', () {
    test('1. CPF e valor monetário', () {
      expect(
        mascararTextoLocal(
          'Transfere R\$ 1.500,00 hoje para o CPF 123.456.789-00',
        ),
        'Transfere R\$ 1.500,00 hoje para o CPF [CPF]',
      );
    });

    test('2. domínio com dígitos colados', () {
      const entrada = 'Acesse whatsapp-seguro11987654321.com agora';
      expect(mascararTextoLocal(entrada), entrada);
    });

    test('3. boleto de 44 dígitos', () {
      expect(
        mascararTextoLocal(
          'Boleto 34191790010104351004791020150008291070026000',
        ),
        'Boleto [BOLETO]',
      );
    });

    test('4. cartão de 16 dígitos corridos', () {
      expect(
        mascararTextoLocal('Pedido 1234567890123456 confirmado'),
        'Pedido [CARTAO] confirmado',
      );
    });

    test('5. telefone com DDI sem separadores', () {
      expect(
        mascararTextoLocal('Chama no +5511912345678 urgente'),
        'Chama no [TELEFONE] urgente',
      );
    });

    test('6. CPF citado como chave Pix', () {
      expect(
        mascararTextoLocal(
          'Manda pro pix 123.456.789-00 hoje, é o CPF da conta',
        ),
        'Manda pro pix [CPF] hoje, é o CPF da conta',
      );
    });

    test('7. e-mail com ponto no nome do usuário', () {
      expect(
        mascararTextoLocal('Meu email e joao.silva@gmail.com, pode mandar'),
        'Meu email e [EMAIL], pode mandar',
      );
    });

    test('8. domínio sem esquema seguido de texto sem dado pessoal', () {
      const entrada =
          'URGENTE: pague R\$ 2.500,00 ate as 18h ou sua conta sera '
          'bloqueada. Acesse bb-seguranca.net/regularizar';
      expect(mascararTextoLocal(entrada), entrada);
    });
  });

  group('Lacunas da auditoria de 2026-10-07', () {
    group('CPF com espaços', () {
      for (final cpf in [
        '123 456 789 00',
        '123.456.789 00',
        '123 456 789-00',
        '123 456.789-00',
      ]) {
        test('"$cpf" → [CPF]', () {
          expect(
            mascararTextoLocal('Confirme o CPF $cpf hoje.'),
            'Confirme o CPF [CPF] hoje.',
          );
        });
      }

      test('no fim da frase, com ponto final', () {
        expect(mascararTextoLocal('CPF 123 456 789 00.'), 'CPF [CPF].');
      });
    });

    group('CPF com barra no lugar do hífen', () {
      test('"123.456.789/00" → [CPF]', () {
        expect(
          mascararTextoLocal('CPF 123.456.789/00 confirmado'),
          'CPF [CPF] confirmado',
        );
      });
    });

    test('variante com padrão de celular segue a precedência: [TELEFONE]', () {
      // DDD 11 válido seguido de 9: mesma heurística dos 11 dígitos
      // corridos.
      expect(mascararTextoLocal('119 876 543 21'), '[TELEFONE]');
      // DDD 91 válido, mas o dígito seguinte não é 9: CPF.
      expect(mascararTextoLocal('912 345 678 90'), '[CPF]');
    });

    group('telefone sem DDD', () {
      test('"98765 4321" → [TELEFONE]', () {
        expect(
          mascararTextoLocal('Me chama no 98765 4321 agora.'),
          'Me chama no [TELEFONE] agora.',
        );
      });

      test('"987654321" (9 dígitos começando em 9) → [TELEFONE]', () {
        expect(
          mascararTextoLocal('Me chama no 987654321 agora.'),
          'Me chama no [TELEFONE] agora.',
        );
      });

      test('9 dígitos que não começam em 9 não viram telefone', () {
        expect(mascararTextoLocal('Pedido 123456789'), 'Pedido 123456789');
      });

      test('fixo de 8 dígitos sem hífen continua fora (indistinguível)', () {
        expect(mascararTextoLocal('Código 3456 7890'), 'Código 3456 7890');
      });

      test('valor monetário com 9 dígitos não vira telefone', () {
        expect(
          mascararTextoLocal('Prêmio de R\$ 900000000,00'),
          'Prêmio de R\$ 900000000,00',
        );
      });
    });

    group('regressão de todos os formatos já cobertos', () {
      const casos = {
        // CPF
        '123.456.789-09': '[CPF]',
        '12345678909': '[CPF]',
        '12345678900': '[CPF]',
        '20987654321': '[CPF]',
        // Telefone
        '(11) 91234-5678': '[TELEFONE]',
        '(11) 98765 4321': '[TELEFONE]',
        '91234-5678': '[TELEFONE]',
        '3456-7890': '[TELEFONE]',
        '+55 11 91234-5678': '[TELEFONE]',
        '+55 11 98765 4321': '[TELEFONE]',
        '+5511912345678': '[TELEFONE]',
        '11 98765 4321': '[TELEFONE]',
        '11 98765-4321': '[TELEFONE]',
        '11 987654321': '[TELEFONE]',
        '11987654321': '[TELEFONE]',
        // CNPJ
        '12.345.678/0001-95': '[CNPJ]',
        '12345678000195': '[CNPJ]',
        // Cartão
        '1234 5678 9012 3456': '[CARTAO]',
        '1234-5678-9012-3456': '[CARTAO]',
        '4111111111111111': '[CARTAO]',
        // Boleto
        '23793381286000000000300000000400184340000012345': '[BOLETO]',
        '23793.38128 60000.000003 00000.000400 1 84340000012345': '[BOLETO]',
        '83640000001-1 47530000000-1 00000000000-0 12345678901-2': '[BOLETO]',
        '83640000001-147530000000-100000000000-012345678901-2': '[BOLETO]',
        // Chave Pix aleatória e e-mail
        '123e4567-e89b-12d3-a456-426614174000': '[CHAVE_PIX]',
        'maria.silva@exemplo.com': '[EMAIL]',
      };
      for (final MapEntry(key: entrada, value: esperado) in casos.entries) {
        test('"$entrada" → $esperado', () {
          final mascarado = mascararTextoLocal('Dado: $entrada fim');
          expect(mascarado, 'Dado: $esperado fim');
          expect(mascarado, isNot(contains(RegExp(r'\d'))));
        });
      }
    });
  });

  group('Formatos de gravidade alta (última rodada)', () {
    group('chave Pix aleatória sem hífens', () {
      for (final chave in [
        '123e4567e89b12d3a456426614174000',
        '123E4567E89B12D3A456426614174000',
      ]) {
        test('"$chave" → [CHAVE_PIX]', () {
          expect(
            mascararTextoLocal('Faz o Pix na chave $chave agora.'),
            'Faz o Pix na chave [CHAVE_PIX] agora.',
          );
        });
      }

      test('precedência sobre cartão: a chave não é partida', () {
        // Os 16 últimos caracteres são só dígitos e casariam com cartão.
        const chave =
            'abcdef1234567890'
            '1234567890123456';
        final mascarado = mascararTextoLocal('chave $chave');
        expect(mascarado, 'chave [CHAVE_PIX]');
        expect(mascarado, isNot(contains('[CARTAO]')));
        expect(mascarado, isNot(contains('abcdef')));
      });

      test('a forma com hífens continua [CHAVE_PIX] (regressão)', () {
        expect(
          mascararTextoLocal('chave 123e4567-e89b-12d3-a456-426614174000'),
          'chave [CHAVE_PIX]',
        );
      });
    });

    group('CNPJ com espaços e separadores combinados', () {
      for (final cnpj in [
        '12 345 678 0001 95',
        '12.345.678/0001 95',
        '12 345 678/0001-95',
        '12.345.678 0001-95',
        '12-345-678-0001-95',
        '12 . 345 . 678 / 0001 - 95',
      ]) {
        test('"$cnpj" → [CNPJ]', () {
          final mascarado = mascararTextoLocal('CNPJ $cnpj da empresa.');
          expect(mascarado, 'CNPJ [CNPJ] da empresa.');
          expect(mascarado, isNot(contains(RegExp(r'\d'))));
        });
      }
    });

    group('CNPJ alfanumérico', () {
      for (final cnpj in [
        '12.ABC.345/01DE-35',
        '12ABC34501DE35',
        '12 ABC 345 01DE 35',
        'AB.CDE.FGH/IJKL-35',
        '1A.2B3.C4D/5E6F-07',
      ]) {
        test('"$cnpj" → [CNPJ]', () {
          expect(
            mascararTextoLocal('Fornecedor CNPJ $cnpj, pague hoje.'),
            'Fornecedor CNPJ [CNPJ], pague hoje.',
          );
        });
      }

      test('no fim da frase, com ponto final', () {
        expect(mascararTextoLocal('CNPJ 12.ABC.345/01DE-35.'), 'CNPJ [CNPJ].');
      });

      test('dígitos verificadores precisam ser numéricos', () {
        expect(
          mascararTextoLocal('código 12ABC34501DEXY'),
          'código 12ABC34501DEXY',
        );
      });
    });

    test('URLs, domínios e valores monetários continuam intactos', () {
      for (final entrada in [
        'acesse https://banco.com/pag/12345678000195 hoje',
        'acesse bb-seguranca.net/pagamento/123 hoje',
        'site AB.CDE.com.br ok',
        'R\$ 1.234.567,89 e R\$ 12345678000195,00',
        'URGENTE: SUA CONTA SERA BLOQUEADA HOJE 12',
      ]) {
        expect(mascararTextoLocal(entrada), entrada, reason: entrada);
      }
    });
  });
}

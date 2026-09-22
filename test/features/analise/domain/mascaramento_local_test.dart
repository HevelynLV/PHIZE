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
      expect(
        mascararTextoLocal('Meu CPF é 12345678909.'),
        'Meu CPF é [CPF].',
      );
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
        mascararTextoLocal(
          'Ligue para (11) 91234-5678 ou (21) 98888-7777.',
        ),
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
        mascararTextoLocal(
          'Transfere R\$ 1.500,00 para o CPF 123.456.789-00',
        ),
        'Transfere R\$ 1.500,00 para o CPF [CPF]',
      );
    });
  });

  group('Correções da 2ª auditoria (colisão de marcador e URL sem esquema)', () {
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
  });

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
}

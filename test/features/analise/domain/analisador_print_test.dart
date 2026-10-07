import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analisador_print.dart';
import 'package:phize/features/analise/domain/analise_texto_client.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/captura_imagem.dart';
import 'package:phize/features/analise/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/imagem_em_memoria.dart';
import 'package:phize/features/analise/domain/limite_texto_ocr.dart';
import 'package:phize/features/analise/domain/mascaramento_local.dart';
import 'package:phize/features/analise/domain/reconhecedor_texto.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/seletor_imagem.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';
import 'package:phize/features/analise/domain/texto_em_memoria.dart';

/// Texto de golpe com CPF, telefone e e-mail: passa nas duas verificações
/// de volume mínimo e tem dados que o mascaramento precisa ocultar.
const _textoGolpe =
    'Oi mãe, troquei de número. Me manda um Pix urgente, meu CPF é '
    '123.456.789-09, liga no (11) 91234-5678 ou escreve para '
    'maria.silva@exemplo.com';

const _analiseValida = {
  'sinais': ['pedido_financeiro', 'alegacao_troca_contato'],
  'categoria': 'falso_contato',
  'explicacao':
      'Quem diz ter trocado de número e pede dinheiro costuma '
      'ser golpista. Ligue para o número antigo antes de pagar.',
};

Map<String, dynamic> _concluida([
  Map<String, Object?> analise = _analiseValida,
]) => {'status': 'concluida', 'analise': analise};

Map<String, dynamic> _naoConcluida(String motivo) => {
  'status': 'nao_concluida',
  'motivo': motivo,
};

class _ReconhecedorFalso implements ReconhecedorTexto {
  _ReconhecedorFalso(this._eventos, {this.texto = _textoGolpe, this.erro});

  final List<String> _eventos;
  final String texto;
  final Object? erro;

  ImagemEmMemoria? imagemRecebida;

  @override
  Future<String> reconhecer(ImagemEmMemoria imagem) async {
    _eventos.add('ocr');
    imagemRecebida = imagem;
    // Prova de que o OCR recebe a imagem ainda íntegra.
    expect(imagem.descartada, isFalse);
    final e = erro;
    if (e != null) throw e;
    return texto;
  }
}

/// Function simulada. Cada item de [respostas] é devolvido (Map) ou lançado
/// (qualquer outro objeto) em uma chamada; o último se repete.
class _ClienteFalso implements AnaliseTextoClient {
  _ClienteFalso(
    this._eventos, {
    List<Object> respostas = const [],
    this.aoEnviar,
  }) : _respostas = respostas.isEmpty ? [_concluida()] : respostas;

  final List<String> _eventos;
  final List<Object> _respostas;
  final void Function()? aoEnviar;

  final List<String> textosEnviados = [];

  @override
  Future<Map<String, dynamic>> analisar(String textoMascarado) async {
    _eventos.add('enviar');
    textosEnviados.add(textoMascarado);
    aoEnviar?.call();
    final i = textosEnviados.length - 1;
    final resposta =
        _respostas[i < _respostas.length ? i : _respostas.length - 1];
    if (resposta is Map<String, dynamic>) return resposta;
    throw resposta;
  }
}

class _ArquivoFalso implements ArquivoSelecionado {
  _ArquivoFalso(this._eventos, {this.erroLeitura, this.erroRemocao});

  final List<String> _eventos;
  final Object? erroLeitura;
  final Object? erroRemocao;

  @override
  Future<Uint8List> lerBytes() async {
    final e = erroLeitura;
    if (e != null) throw e;
    return Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  Future<void> remover() async {
    _eventos.add('remover temporario');
    final e = erroRemocao;
    if (e != null) throw e;
  }
}

class _SeletorFalso implements SeletorImagem {
  _SeletorFalso({this.arquivo, this.erroSelecao});

  /// `null` simula o cancelamento pelo usuário.
  final ArquivoSelecionado? arquivo;
  final Object? erroSelecao;

  @override
  Future<ArquivoSelecionado?> selecionar() async {
    final e = erroSelecao;
    if (e != null) throw e;
    return arquivo;
  }

  @override
  Future<List<ArquivoSelecionado>> recuperarResiduos() async => const [];
}

/// Monta o cenário completo e registra os textos criados pelo pipeline.
class _Cenario {
  _Cenario({
    String texto = _textoGolpe,
    Object? erroOcr,
    List<Object> respostas = const [],
    String Function(String)? mascarar,
    this.erroLeitura,
    this.erroRemocao,
  }) {
    reconhecedor = _ReconhecedorFalso(eventos, texto: texto, erro: erroOcr);
    cliente = _ClienteFalso(
      eventos,
      respostas: respostas,
      aoEnviar: () =>
          imagemDescartadaNoEnvio = reconhecedor.imagemRecebida?.descartada,
    );
    analisador = AnalisadorPrint(
      reconhecedor: reconhecedor,
      cliente: cliente,
      mascarar: mascarar ?? mascararTextoLocal,
      aguardar: (intervalo) async => esperas.add(intervalo),
      agora: () => data,
      aoCriarTexto: textosCriados.add,
    );
  }

  final Object? erroLeitura;
  final Object? erroRemocao;

  final List<String> eventos = [];
  final List<Duration> esperas = [];
  final List<TextoEmMemoria> textosCriados = [];
  final DateTime data = DateTime(2026, 10, 7, 14, 30);
  bool? imagemDescartadaNoEnvio;

  late final _ReconhecedorFalso reconhecedor;
  late final _ClienteFalso cliente;
  late final AnalisadorPrint analisador;

  Future<ResultadoAnalisePrint> analisarCaptura() {
    final arquivo = _ArquivoFalso(
      eventos,
      erroLeitura: erroLeitura,
      erroRemocao: erroRemocao,
    );
    return analisador.analisarCaptura(
      CapturaImagem(_SeletorFalso(arquivo: arquivo)),
    );
  }
}

void main() {
  group('fluxo completo', () {
    test(
      'bem-sucedido: score, sinais, categoria, explicação, tipo e data',
      () async {
        final c = _Cenario();

        final r = await c.analisarCaptura();

        expect(r, isA<AnalisePrintConcluida>());
        r as AnalisePrintConcluida;
        const sinais = {
          SinalTextoPrint.pedidoFinanceiro,
          SinalTextoPrint.alegacaoTrocaContato,
        };
        expect(r.sinais, sinais);
        expect(r.categoria, CategoriaAmeaca.falsoContato);
        expect(r.explicacao, _analiseValida['explicacao']);
        expect(r.tipoEntrada, TipoEntrada.imagem);
        expect(r.data, c.data);
        final esperado = CalculadoraScore.calcular(
          const SinaisIdentificados(
            textoPrint: sinais,
            verificacaoIncompleta: true,
          ),
        );
        expect(r.score.pontuacao, esperado.pontuacao);
        expect(r.score.faixa, esperado.faixa);
        expect(r.score.rotulo, esperado.rotulo);
        // O temporário do seletor sai logo após a leitura dos bytes (6.1); o
        // envio só acontece depois do OCR e do descarte da imagem.
        expect(c.eventos, ['remover temporario', 'ocr', 'enviar']);
        expect(c.imagemDescartadaNoEnvio, isTrue);
      },
    );

    test('cancelamento da seleção: nada é reconhecido nem enviado', () async {
      final c = _Cenario();

      final r = await c.analisador.analisarCaptura(
        CapturaImagem(_SeletorFalso()),
      );

      expect(r, isA<AnalisePrintCancelada>());
      expect(c.eventos, isEmpty);
    });
  });

  group('volume mínimo', () {
    for (final texto in ['', '   \n ', 'Oi mãe', 'Pix agora por favor']) {
      test('abaixo do mínimo antes do mascaramento ("$texto"): nada é '
          'transmitido', () async {
        expect(LimiteTextoOcr.atende(texto), isFalse);
        final c = _Cenario(texto: texto);

        final r = await c.analisarCaptura();

        expect(
          (r as AnalisePrintInterrompida).motivo,
          MotivoInterrupcaoPrint.textoInsuficiente,
        );
        expect(c.cliente.textosEnviados, isEmpty);
      });
    }

    test('texto que esvazia após o mascaramento: nada é transmitido', () async {
      // Foto de cartão: passa na primeira verificação, mas vira
      // "[CARTAO] 12/29" depois do mascaramento.
      const texto = '4111 1111 1111 1111 12/29';
      expect(LimiteTextoOcr.atende(texto), isTrue);
      final c = _Cenario(texto: texto);

      final r = await c.analisarCaptura();

      expect(
        (r as AnalisePrintInterrompida).motivo,
        MotivoInterrupcaoPrint.textoInsuficienteAposMascaramento,
      );
      expect(c.cliente.textosEnviados, isEmpty);
    });
  });

  group('segunda verificação conta só o texto fora dos marcadores', () {
    test('print só com dados ("[TELEFONE] [EMAIL] [CPF] [CNPJ]"): nada é '
        'transmitido', () async {
      const texto = '(11) 91234-5678 a@b.com 123.456.789-09 12.345.678/0001-90';
      expect(mascararTextoLocal(texto), '[TELEFONE] [EMAIL] [CPF] [CNPJ]');
      final c = _Cenario(texto: texto);

      final r = await c.analisarCaptura();

      expect(
        (r as AnalisePrintInterrompida).motivo,
        MotivoInterrupcaoPrint.textoInsuficienteAposMascaramento,
      );
      expect(c.cliente.textosEnviados, isEmpty);
    });

    test('"Pix para [CHAVE_PIX] agora" segue para a análise', () async {
      const texto = 'Pix para 123e4567-e89b-12d3-a456-426614174000 agora';
      final c = _Cenario(texto: texto);

      final r = await c.analisarCaptura();

      expect(r, isA<AnalisePrintConcluida>());
      expect(c.cliente.textosEnviados, ['Pix para [CHAVE_PIX] agora']);
    });
  });

  group('privacidade', () {
    test('o texto enviado ao LLM está mascarado', () async {
      final c = _Cenario();

      await c.analisarCaptura();

      expect(c.cliente.textosEnviados, hasLength(1));
      final enviado = c.cliente.textosEnviados.single;
      expect(enviado, isNot(contains('123.456.789-09')));
      expect(enviado, isNot(contains('91234-5678')));
      expect(enviado, isNot(contains('maria.silva@exemplo.com')));
      expect(enviado, contains('[CPF]'));
      expect(enviado, contains('[TELEFONE]'));
      expect(enviado, contains('[EMAIL]'));
      // O restante da mensagem chega intacto ao modelo.
      expect(enviado, contains('troquei de número'));
      expect(enviado, contains('Pix urgente'));
    });

    test('a imagem é descartada antes do envio do texto', () async {
      final c = _Cenario();

      await c.analisarCaptura();

      expect(c.imagemDescartadaNoEnvio, isTrue);
      expect(
        c.eventos.indexOf('remover temporario'),
        lessThan(c.eventos.indexOf('enviar')),
      );
    });

    test('analisarImagem descarta a imagem mesmo quando o OCR falha', () async {
      final c = _Cenario(erroOcr: Exception('falha no OCR'));
      final imagem = ImagemEmMemoria(Uint8List.fromList([9, 9, 9]));

      final r = await c.analisador.analisarImagem(imagem);

      expect(imagem.descartada, isTrue);
      expect(
        (r as AnalisePrintInterrompida).motivo,
        MotivoInterrupcaoPrint.falhaReconhecimento,
      );
    });

    final cenariosDescarte = <String, _Cenario Function()>{
      'sucesso': _Cenario.new,
      'exceção da Function': () => _Cenario(respostas: [Exception('rede')]),
      'resposta inválida': () => _Cenario(
        respostas: [
          {'status': 'x'},
        ],
      ),
      'timeout': () => _Cenario(respostas: [TimeoutException('lento')]),
      'StateError no mascaramento': () =>
          _Cenario(mascarar: (_) => throw StateError('falha')),
      'volume insuficiente após mascarar': () =>
          _Cenario(texto: '4111 1111 1111 1111 12/29'),
    };
    for (final MapEntry(key: nome, value: criar) in cenariosDescarte.entries) {
      test('o texto é descartado ao final ($nome)', () async {
        final c = criar();

        await c.analisarCaptura();

        expect(c.textosCriados, isNotEmpty);
        expect(c.textosCriados.every((t) => t.descartado), isTrue);
      });
    }
  });

  group('sem base de conhecimento: verificação incompleta', () {
    const semSinais = {
      'sinais': <String>[],
      'categoria': 'sem_indicios',
      'explicacao':
          'Não identificamos sinais típicos de golpe nesta '
          'mensagem. Na dúvida, confirme por outro canal.',
    };

    test(
      'print sem sinais não sai verde, e a pontuação real é mantida',
      () async {
        final c = _Cenario(respostas: [_concluida(semSinais)]);

        final r = await c.analisarCaptura() as AnalisePrintConcluida;

        expect(r.sinais, isEmpty);
        expect(r.score.verificacaoIncompleta, isTrue);
        expect(r.score.faixa, isNot(FaixaRisco.baixo));
        // A faixa sobe, mas a pontuação não é inflada.
        expect(
          r.score.pontuacao,
          CalculadoraScore.calcular(const SinaisIdentificados()).pontuacao,
        );
      },
    );

    test('a verificação não concluída cita a comparação com padrões', () async {
      final c = _Cenario(respostas: [_concluida(semSinais)]);

      final r = await c.analisarCaptura() as AnalisePrintConcluida;

      expect(r.verificacoesNaoConcluidas, hasLength(1));
      expect(
        r.verificacoesNaoConcluidas.single,
        allOf(
          contains('comparação com padrões'),
          contains('não foi realizada'),
        ),
      );
      expect(r.verificacoesNaoConcluidas.single, isNot(contains('Seguro')));
    });

    test('vale também quando há sinais', () async {
      final c = _Cenario();

      final r = await c.analisarCaptura() as AnalisePrintConcluida;

      expect(r.score.verificacaoIncompleta, isTrue);
      expect(r.verificacoesNaoConcluidas, [
        AnalisadorPrint.motivoSemBaseConhecimento,
      ]);
    });
  });

  group('resposta do modelo', () {
    final foraDoFormato = <String, Map<String, dynamic>>{
      'sem explicação': _concluida({
        'sinais': ['pedido_financeiro'],
        'categoria': 'falso_contato',
      }),
      'sinal desconhecido': _concluida({
        ..._analiseValida,
        'sinais': ['x'],
      }),
      'sinal da base sem RAG': _concluida({
        ..._analiseValida,
        'sinais': ['correspondencia_padrao_catalogado'],
      }),
      'categoria desconhecida': _concluida({
        ..._analiseValida,
        'categoria': 'inventada',
      }),
      'sinais não é lista': _concluida({
        ..._analiseValida,
        'sinais': 'pedido_financeiro',
      }),
      'status desconhecido': {'status': 'talvez'},
      'nao_concluida por resposta inválida': _naoConcluida('resposta_invalida'),
    };
    for (final MapEntry(key: nome, value: resposta) in foraDoFormato.entries) {
      test(
        'fora do formato ($nome): descartada, sem exibição parcial',
        () async {
          final c = _Cenario(respostas: [resposta]);

          final r = await c.analisarCaptura();

          expect(r, isNot(isA<AnalisePrintConcluida>()));
          r as AnalisePrintInterrompida;
          expect(r.motivo, MotivoInterrupcaoPrint.respostaInvalida);
          expect(r.permiteNovaTentativa, isTrue);
        },
      );
    }

    test('o score vem do motor da Fase 2, não do modelo', () async {
      final c = _Cenario(
        respostas: [
          _concluida({..._analiseValida, 'score': 3, 'pontuacao': 99}),
        ],
      );

      final r = await c.analisarCaptura() as AnalisePrintConcluida;

      final esperado = CalculadoraScore.calcular(
        SinaisIdentificados(textoPrint: r.sinais, verificacaoIncompleta: true),
      );
      expect(r.score.pontuacao, esperado.pontuacao);
      expect(r.score.pontuacao, isNot(3));
      expect(r.score.pontuacao, isNot(99));
    });
  });

  group('limite do provedor', () {
    test('nova tentativa com intervalo progressivo e, persistindo, '
        'orientação para repetir em instantes', () async {
      final c = _Cenario(respostas: [_naoConcluida('limite_provedor')]);

      final r = await c.analisarCaptura();

      expect(
        (r as AnalisePrintInterrompida).motivo,
        MotivoInterrupcaoPrint.limiteProvedor,
      );
      expect(c.esperas, AnalisadorPrint.intervalosNovaTentativa);
      expect(
        c.cliente.textosEnviados,
        hasLength(AnalisadorPrint.intervalosNovaTentativa.length + 1),
      );
      for (var i = 1; i < c.esperas.length; i++) {
        expect(c.esperas[i], greaterThan(c.esperas[i - 1]));
      }
    });

    test('nova tentativa bem-sucedida conclui a análise', () async {
      final c = _Cenario(
        respostas: [_naoConcluida('limite_provedor'), _concluida()],
      );

      final r = await c.analisarCaptura();

      expect(r, isA<AnalisePrintConcluida>());
      expect(c.esperas, [AnalisadorPrint.intervalosNovaTentativa.first]);
    });
  });

  group('falhas', () {
    const segredoMascaramento = 'texto-secreto-do-print';
    const caminhoPrint =
        '/data/user/0/app/cache/abc/Screenshot_WhatsApp_Maria.png';

    test(
      'StateError do mascaramento interrompe sem expor a mensagem',
      () async {
        final c = _Cenario(
          mascarar: (_) => throw StateError(segredoMascaramento),
        );

        final r = await c.analisarCaptura() as AnalisePrintInterrompida;

        expect(r.motivo, MotivoInterrupcaoPrint.falhaMascaramento);
        expect(r.mensagem, isNot(contains(segredoMascaramento)));
        expect(r.mensagem, isNot(contains('StateError')));
        expect(c.cliente.textosEnviados, isEmpty);
      },
    );

    test('FileSystemException da captura vira mensagem genérica', () async {
      final c = _Cenario(
        erroLeitura: const FileSystemException(
          'Cannot open file',
          caminhoPrint,
        ),
      );

      final r = await c.analisarCaptura() as AnalisePrintInterrompida;

      expect(r.motivo, MotivoInterrupcaoPrint.falhaCaptura);
      expect(r.mensagem, isNot(contains('Screenshot')));
      expect(r.mensagem, isNot(contains(caminhoPrint)));
      expect(c.eventos, isNot(contains('ocr')));
    });

    final cenariosFalha =
        <String, (_Cenario Function(), MotivoInterrupcaoPrint)>{
          'OCR lança exceção': (
            () => _Cenario(erroOcr: Exception('ml kit')),
            MotivoInterrupcaoPrint.falhaReconhecimento,
          ),
          'OCR indisponível na plataforma': (
            () => _Cenario(
              erroOcr: const ReconhecimentoTextoNaoSuportadoException(),
            ),
            MotivoInterrupcaoPrint.plataformaNaoSuportada,
          ),
          'remoção do temporário falha': (
            () => _Cenario(
              erroRemocao: const FileSystemException(
                'Cannot delete',
                caminhoPrint,
              ),
            ),
            MotivoInterrupcaoPrint.falhaCaptura,
          ),
          'timeout da Function': (
            () => _Cenario(respostas: [TimeoutException('lento')]),
            MotivoInterrupcaoPrint.timeout,
          ),
          'Function responde timeout do provedor': (
            () => _Cenario(respostas: [_naoConcluida('timeout')]),
            MotivoInterrupcaoPrint.timeout,
          ),
          'sessão inválida': (
            () => _Cenario(
              respostas: [const AnaliseTextoNaoAutenticadoException()],
            ),
            MotivoInterrupcaoPrint.naoAutenticado,
          ),
          'limite do usuário': (
            () => _Cenario(
              respostas: [const AnaliseTextoLimiteExcedidoException()],
            ),
            MotivoInterrupcaoPrint.limiteUsuario,
          ),
          'Function indisponível': (
            () => _Cenario(
              respostas: [const AnaliseTextoIndisponivelException('500')],
            ),
            MotivoInterrupcaoPrint.indisponivel,
          ),
          'exceção não mapeada da Function': (
            () => _Cenario(respostas: [ArgumentError('inesperado')]),
            MotivoInterrupcaoPrint.indisponivel,
          ),
          'chave ausente na Function': (
            () => _Cenario(respostas: [_naoConcluida('chave_ausente')]),
            MotivoInterrupcaoPrint.indisponivel,
          ),
        };
    for (final MapEntry(key: nome, value: (criar, motivo))
        in cenariosFalha.entries) {
      test('nenhum caminho de falha lança exceção ($nome)', () async {
        final c = criar();

        final r = await c.analisarCaptura();

        expect(r, isA<AnalisePrintInterrompida>());
        expect((r as AnalisePrintInterrompida).motivo, motivo);
      });
    }

    test('seleção não suportada (web) vira mensagem própria', () async {
      final c = _Cenario();

      final r = await c.analisador.analisarCaptura(
        CapturaImagem(
          _SeletorFalso(
            erroSelecao: const SelecaoImagemNaoSuportadaException(),
          ),
        ),
      );

      expect(
        (r as AnalisePrintInterrompida).motivo,
        MotivoInterrupcaoPrint.plataformaNaoSuportada,
      );
    });
  });
}

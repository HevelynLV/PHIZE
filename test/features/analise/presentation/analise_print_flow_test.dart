import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phize/core/constants/firebase_auth_codigos.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/theme/app_theme.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/data/analise_texto_client_http.dart';
import 'package:phize/features/analise/data/historico_repository_firestore.dart';
import 'package:phize/features/analise/domain/analisador_print.dart';
import 'package:phize/features/analise/domain/analise_texto_client.dart';
import 'package:phize/features/analise/domain/caixa_compartilhamento.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/conteudo_compartilhado.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/shared/domain/imagem_em_memoria.dart';
import 'package:phize/shared/domain/reconhecedor_texto.dart';
import 'package:phize/features/analise/domain/resultado_analise_link.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/shared/domain/seletor_imagem.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_link.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';
import 'package:phize/features/analise/domain/tutorial_repository.dart';
import 'package:phize/features/analise/domain/verificacao_link.dart';
import 'package:phize/features/analise/presentation/pages/analise_compartilhada_page.dart';
import 'package:phize/features/analise/presentation/pages/resultado_analise_page.dart';
import 'package:phize/features/analise/presentation/widgets/progresso_analise.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_consentimento_repository.dart';
import '../../../support/fake_historico_repository.dart';
import '../../../support/fake_tutorial_repository.dart';

/// Texto de golpe que passa nas duas verificações de volume mínimo.
const _textoGolpe =
    'Oi mãe, troquei de número. Me manda um Pix urgente, meu CPF é '
    '123.456.789-09';

const _explicacao =
    'Quem diz ter trocado de número e pede dinheiro costuma ser golpista. '
    'Ligue para o número antigo antes de pagar.';

Map<String, dynamic> _concluida({
  List<String> sinais = const ['pedido_financeiro', 'alegacao_troca_contato'],
  String categoria = 'falso_contato',
  bool? baseConsultada,
}) => {
  'status': 'concluida',
  'analise': {
    'sinais': sinais,
    'categoria': categoria,
    'explicacao': _explicacao,
  },
  'baseConsultada': ?baseConsultada,
};

/// Resposta fora do contrato: `sinais` não é lista.
const Map<String, dynamic> _respostaForaDoFormato = {
  'status': 'concluida',
  'analise': {'sinais': 'pedido_financeiro', 'categoria': 'falso_contato'},
};

/// Nome original do print, como chega na `FileSystemException` do seletor.
const _nomeOriginalPrint = 'Screenshot_20261019_WhatsApp_Maria.png';

class _ArquivoFalso implements ArquivoSelecionado {
  _ArquivoFalso({this.erroLeitura});

  final Object? erroLeitura;

  /// Os bytes entregues ao pipeline, para provar o descarte da imagem.
  final Uint8List bytes = Uint8List.fromList([7, 7, 7, 7]);

  @override
  Future<Uint8List> lerBytes() async {
    final e = erroLeitura;
    if (e != null) throw e;
    return bytes;
  }

  @override
  Future<void> remover() async {}
}

class _SeletorFalso implements SeletorImagem {
  _SeletorFalso({this.arquivo, this.escolha});

  /// `null` simula o cancelamento pelo usuário.
  final ArquivoSelecionado? arquivo;

  /// Quando presente, a galeria só "devolve" a imagem quando ele for
  /// completado: simula o tempo que a pessoa passa escolhendo.
  final Completer<void>? escolha;
  int selecoes = 0;

  @override
  Future<ArquivoSelecionado?> selecionar() async {
    selecoes++;
    await escolha?.future;
    return arquivo;
  }

  @override
  Future<List<ArquivoSelecionado>> recuperarResiduos() async => const [];
}

class _ReconhecedorFalso implements ReconhecedorTexto {
  _ReconhecedorFalso({this.texto = _textoGolpe, this.erro});

  final String texto;
  final Object? erro;

  @override
  Future<String> reconhecer(ImagemEmMemoria imagem) async {
    final e = erro;
    if (e != null) throw e;
    return texto;
  }
}

/// Function simulada. Cada item de [respostas] é devolvido (Map) ou lançado
/// (qualquer outro objeto) em uma chamada; o último se repete. Com
/// [completer], a primeira chamada só termina quando o teste o completa.
class _ClienteFalso implements AnaliseTextoClient {
  _ClienteFalso({List<Object>? respostas, this.completer})
    : _respostas = respostas ?? [_concluida()];

  final List<Object> _respostas;
  final Completer<Map<String, dynamic>>? completer;
  int chamadas = 0;

  @override
  Future<Map<String, dynamic>> analisar(String textoMascarado) async {
    final i = chamadas++;
    final completer = this.completer;
    if (completer != null && i == 0) return completer.future;
    final resposta =
        _respostas[i < _respostas.length ? i : _respostas.length - 1];
    if (resposta is Map<String, dynamic>) return resposta;
    throw resposta;
  }
}

Future<void> _abrir(
  WidgetTester tester, {
  required SeletorImagem seletor,
  ReconhecedorTexto? reconhecedor,
  AnaliseTextoClient? cliente,
  FakeHistoricoRepository? historico,
  FakeConsentimentoRepository? consentimento,
  FakeTutorialRepository? tutorial,
  String rotaInicial = AppRoutes.analisarPrint,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        seletorImagem: seletor,
        reconhecedorTexto: reconhecedor ?? _ReconhecedorFalso(),
        analiseTextoClient: cliente ?? _ClienteFalso(),
        historicoRepository: historico ?? FakeHistoricoRepository(),
        consentimentoRepository:
            consentimento ?? FakeConsentimentoRepository(),
        tutorialRepository: tutorial ?? FakeTutorialRepository(),
      ),
      initialRoute: rotaInicial,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _analisar(
  WidgetTester tester, {
  ArquivoSelecionado? arquivo,
  ReconhecedorTexto? reconhecedor,
  AnaliseTextoClient? cliente,
}) async {
  await _abrir(
    tester,
    seletor: _SeletorFalso(arquivo: arquivo ?? _ArquivoFalso()),
    reconhecedor: reconhecedor,
    cliente: cliente,
  );
  await tester.tap(find.byKey(const Key('analisar_print_botao')));
  await tester.pumpAndSettle();
}

/// "Seguro" (ou "segura"/"seguros") como palavra isolada — o termo
/// proibido pela CLAUDE.md, Seção 5.
final _termoProibido = RegExp(r'\bsegur[oa]s?\b', caseSensitive: false);

void _verificarResultadoPrint() {
  expect(find.text('Resultado da Análise'), findsOneWidget);
  expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  // O aviso do Safe Browsing é próprio da análise de link.
  expect(find.text(RotulosRisco.avisoFalibilidadeReputacao), findsNothing);
  expect(find.textContaining(_termoProibido), findsNothing);
}

void _verificarInterrupcao(MotivoInterrupcaoPrint motivo) {
  expect(find.text('Resultado da Análise'), findsNothing);
  expect(find.byKey(const Key('analisar_print_interrupcao')), findsOneWidget);
  expect(find.text(motivo.mensagem), findsOneWidget);
  expect(find.byKey(const Key('analisar_print_carregando')), findsNothing);
  expect(find.textContaining(_termoProibido), findsNothing);
}

Future<void> _abrirCompartilhado(
  WidgetTester tester, {
  required ConteudoCompartilhado conteudo,
  AnaliseTextoClient? cliente,
  ReconhecedorTexto? reconhecedor,
  FakeHistoricoRepository? historico,
  FakeConsentimentoRepository? consentimento,
  FakeTutorialRepository? tutorial,
}) async {
  final caixa = CaixaCompartilhamento()..guardar(conteudo);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        reconhecedorTexto: reconhecedor ?? _ReconhecedorFalso(),
        analiseTextoClient: cliente ?? _ClienteFalso(),
        historicoRepository: historico ?? FakeHistoricoRepository(),
        authRepository: FakeAuthRepository(),
        caixaCompartilhamento: caixa,
        consentimentoRepository:
            consentimento ?? FakeConsentimentoRepository(),
        tutorialRepository: tutorial ?? FakeTutorialRepository(),
      ),
      initialRoute: AppRoutes.analiseCompartilhada,
    ),
  );
  await tester.pumpAndSettle();
}

ImagemEmMemoria _imagemCompartilhada() =>
    ImagemEmMemoria(Uint8List.fromList([5, 5, 5]));

void main() {
  testWidgets('a tela mostra a etapa real e avisa quando a análise demora', (
    tester,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      cliente: _ClienteFalso(completer: completer),
    );

    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text(EtapaAnalisePrint.analisando.titulo), findsOneWidget);
    expect(find.byKey(const Key('progresso_aviso_demora')), findsNothing);

    await tester.pump(ProgressoAnalise.tempoParaAviso);
    expect(find.byKey(const Key('progresso_aviso_demora')), findsOneWidget);

    completer.complete(_concluida());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resultado_aviso_permanente')), findsOneWidget);
  });

  testWidgets('o tempo gasto escolhendo na galeria não conta como demora', (
    tester,
  ) async {
    final escolha = Completer<void>();
    final completer = Completer<Map<String, dynamic>>();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso(), escolha: escolha),
      cliente: _ClienteFalso(completer: completer),
    );

    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pump();
    // A pessoa passa 30 segundos na galeria.
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const Key('progresso_aviso_demora')), findsNothing);

    escolha.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(
      ProgressoAnalise.tempoParaAviso - const Duration(seconds: 1),
    );
    expect(find.byKey(const Key('progresso_aviso_demora')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('progresso_aviso_demora')), findsOneWidget);

    completer.complete(_concluida());
    await tester.pumpAndSettle();
  });

  testWidgets('duas frases do mesmo sinal aparecem sem erro na tela', (
    tester,
  ) async {
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      cliente: _ClienteFalso(
        respostas: [
          {
            'status': 'concluida',
            'baseConsultada': true,
            'analise': {
              'sinais': ['pedido_financeiro'],
              'categoria': 'falso_contato',
              'explicacao': 'Golpistas pedem dinheiro com pressa.',
              'trechos': [
                {'sinal': 'pedido_financeiro', 'trecho': 'Faz um Pix agora'},
                {'sinal': 'pedido_financeiro', 'trecho': 'Manda o dinheiro'},
              ],
            },
          },
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('resultado_print_trecho'), skipOffstage: false),
      findsNWidgets(2),
    );
  });

  testWidgets('frases destacadas aparecem no resultado e não vão ao histórico', (
    tester,
  ) async {
    const trecho = 'Faz um Pix agora';
    final historico = FakeHistoricoRepository();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      historico: historico,
      cliente: _ClienteFalso(
        respostas: [
          {
            'status': 'concluida',
            'baseConsultada': true,
            'analise': {
              'sinais': ['pedido_financeiro'],
              'categoria': 'falso_contato',
              'explicacao': 'Golpistas pedem dinheiro com pressa.',
              'trechos': [
                {'sinal': 'pedido_financeiro', 'trecho': trecho},
              ],
            },
          },
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('resultado_print_trecho')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('“$trecho”'), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_print_aviso_trechos')),
      findsOneWidget,
    );
    expect(
      find.textContaining('podem ter pequenos erros de leitura'),
      findsOneWidget,
    );

    final gravado = analiseParaDocumento(historico.analises.single);
    expect(gravado.keys.toSet(), {
      'score',
      'faixa',
      'categoria',
      'explicacao',
      'tipoEntrada',
      'data',
    });
    expect(gravado.values.join(' '), isNot(contains(trecho)));
  });

  group('consentimento (T33)', () {
    testWidgets('sem aceite, a galeria não abre nem o texto é enviado', (
      tester,
    ) async {
      final seletor = _SeletorFalso(arquivo: _ArquivoFalso());
      final cliente = _ClienteFalso();
      await _abrir(
        tester,
        seletor: seletor,
        cliente: cliente,
        consentimento: FakeConsentimentoRepository(aceitou: false),
      );

      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('consentimento_recusar')),
      );
      await tester.tap(find.byKey(const Key('consentimento_recusar')));
      await tester.pumpAndSettle();

      expect(seletor.selecoes, 0);
      expect(cliente.chamadas, 0);
    });

    testWidgets('ao aceitar, a análise continua', (tester) async {
      final seletor = _SeletorFalso(arquivo: _ArquivoFalso());
      await _abrir(
        tester,
        seletor: seletor,
        consentimento: FakeConsentimentoRepository(aceitou: false),
      );

      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('consentimento_aceitar')),
      );
      await tester.tap(find.byKey(const Key('consentimento_aceitar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resultado_aviso_permanente')), findsOneWidget);
    });

    testWidgets('imagem compartilhada sem aceite é descartada sem envio', (
      tester,
    ) async {
      final imagem = _imagemCompartilhada();
      final cliente = _ClienteFalso();
      await _abrirCompartilhado(
        tester,
        conteudo: ImagemCompartilhada(imagem),
        cliente: cliente,
        consentimento: FakeConsentimentoRepository(aceitou: false),
      );

      await tester.ensureVisible(
        find.byKey(const Key('consentimento_recusar')),
      );
      await tester.tap(find.byKey(const Key('consentimento_recusar')));
      await tester.pumpAndSettle();

      expect(imagem.descartada, isTrue);
      expect(cliente.chamadas, 0);
      expect(
        find.text(AnaliseCompartilhadaPage.mensagemSemConsentimento),
        findsOneWidget,
      );
    });
  });

  group('compartilhamento nativo (UC11)', () {
    testWidgets('imagem vai direto ao resultado, sem a galeria, é descartada '
        'e entra no histórico', (tester) async {
      final imagem = _imagemCompartilhada();
      final historico = FakeHistoricoRepository();

      await _abrirCompartilhado(
        tester,
        conteudo: ImagemCompartilhada(imagem),
        historico: historico,
      );

      expect(find.byKey(const Key('resultado_aviso_permanente')), findsOneWidget);
      expect(imagem.descartada, isTrue);
      expect(historico.analises.single.tipoEntrada, TipoEntrada.imagem);
    });

    testWidgets('falha na análise da imagem descarta a imagem e não grava', (
      tester,
    ) async {
      final imagem = _imagemCompartilhada();
      final historico = FakeHistoricoRepository();

      await _abrirCompartilhado(
        tester,
        conteudo: ImagemCompartilhada(imagem),
        reconhecedor: _ReconhecedorFalso(erro: StateError('falha')),
        historico: historico,
      );

      expect(imagem.descartada, isTrue);
      expect(historico.analises, isEmpty);
      expect(
        find.text(MotivoInterrupcaoPrint.falhaReconhecimento.mensagem),
        findsOneWidget,
      );
      expect(find.byKey(const Key('compartilhado_inicio')), findsOneWidget);
    });

    testWidgets('sessão não reconhecida oferece entrar de novo', (tester) async {
      await _abrirCompartilhado(
        tester,
        conteudo: ImagemCompartilhada(_imagemCompartilhada()),
        cliente: _ClienteFalso(
          respostas: [const AnaliseTextoNaoAutenticadoException()],
        ),
      );

      expect(
        find.byKey(const Key('compartilhado_entrar_de_novo')),
        findsOneWidget,
      );
    });

    testWidgets('imagem e link: pede a escolha e analisa a imagem escolhida', (
      tester,
    ) async {
      final imagem = _imagemCompartilhada();
      await _abrirCompartilhado(
        tester,
        conteudo: ImagemELinkCompartilhados(
          imagem: imagem,
          link: 'https://site.com.br',
        ),
      );

      expect(find.byKey(const Key('resultado_aviso_permanente')), findsNothing);
      await tester.tap(find.byKey(const Key('compartilhado_escolher_imagem')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resultado_aviso_permanente')), findsOneWidget);
      expect(imagem.descartada, isTrue);
    });

    testWidgets('sair sem escolher descarta a imagem', (tester) async {
      final imagem = _imagemCompartilhada();
      await _abrirCompartilhado(
        tester,
        conteudo: ImagemELinkCompartilhados(
          imagem: imagem,
          link: 'https://site.com.br',
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      expect(imagem.descartada, isTrue);
    });

    testWidgets('texto sem link explica e oferece voltar ao início', (
      tester,
    ) async {
      await _abrirCompartilhado(tester, conteudo: const TextoSemLink());

      expect(
        find.text(AnaliseCompartilhadaPage.mensagemTextoSemLink),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('compartilhado_inicio')));
      await tester.pumpAndSettle();
      expect(find.text('Recebeu algo estranho?'), findsOneWidget);
    });

    testWidgets('tipo não suportado avisa', (tester) async {
      await _abrirCompartilhado(tester, conteudo: const ConteudoNaoSuportado());

      expect(
        find.text(AnaliseCompartilhadaPage.mensagemNaoSuportado),
        findsOneWidget,
      );
    });
  });

  testWidgets('Dashboard: "Analisar print" é a ação principal (preenchida), '
      '"Analisar link" a secundária (contornada), e abre a seleção do print', (
    tester,
  ) async {
    await _abrir(
      tester,
      seletor: _SeletorFalso(),
      rotaInicial: AppRoutes.dashboard,
    );

    final link = find.byKey(const Key('dashboard_analisar_link'));
    final print = find.byKey(const Key('dashboard_analisar_print'));
    expect(tester.widget(print), isA<FilledButton>());
    expect(tester.widget(link), isA<OutlinedButton>());
    expect(tester.widget<ButtonStyleButton>(link).onPressed, isNotNull);
    expect(tester.widget<ButtonStyleButton>(print).onPressed, isNotNull);

    await tester.tap(print);
    await tester.pumpAndSettle();

    expect(find.text('Analisar print'), findsOneWidget);
    expect(find.byKey(const Key('analisar_print_botao')), findsOneWidget);
  });

  testWidgets('resultado de print: termômetro com score e rótulo calculados '
      'pelo motor, sinais, categoria, explicação e avisos', (tester) async {
    await _analisar(tester);

    final esperado = CalculadoraScore.calcular(
      SinaisIdentificados(
        textoPrint: {
          SinalTextoPrint.pedidoFinanceiro,
          SinalTextoPrint.alegacaoTrocaContato,
        },
        verificacaoIncompleta: true,
      ),
    );

    _verificarResultadoPrint();
    expect(
      find.text('Score de Risco: ${esperado.pontuacao}/100'),
      findsOneWidget,
    );
    expect(find.text(esperado.rotulo), findsOneWidget);
    expect(find.text('Pedido de dinheiro ou pagamento'), findsOneWidget);
    expect(
      find.text('Alegação de troca de número ou de contato'),
      findsOneWidget,
    );
    expect(find.text('Falso contato'), findsOneWidget);
    expect(find.text(_explicacao), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
    expect(
      find.textContaining(AnalisadorPrint.motivoBaseNaoConsultada),
      findsOneWidget,
    );
  });

  testWidgets('sem RAG, nenhum sinal encontrado: a tela exibe a faixa elevada '
      'pelo motor, nunca a verde, e informa a verificação incompleta', (
    tester,
  ) async {
    await _analisar(
      tester,
      cliente: _ClienteFalso(
        respostas: [_concluida(sinais: const [], categoria: 'sem_indicios')],
      ),
    );

    _verificarResultadoPrint();
    expect(find.text('Score de Risco: 0/100'), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsNothing);
    expect(find.text(FaixaRisco.medio.rotulo), findsOneWidget);
    expect(find.byKey(const Key('resultado_print_sem_sinais')), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
  });

  testWidgets('com a base consultada: a correspondência com golpe '
      'catalogado aparece entre os sinais, sem aviso de verificação '
      'incompleta', (tester) async {
    await _analisar(
      tester,
      cliente: _ClienteFalso(
        respostas: [
          _concluida(
            sinais: const [
              'correspondencia_padrao_catalogado',
              'pedido_financeiro',
            ],
            baseConsultada: true,
          ),
        ],
      ),
    );

    final esperado = CalculadoraScore.calcular(
      SinaisIdentificados(
        textoPrint: {
          SinalTextoPrint.correspondenciaPadraoCatalogado,
          SinalTextoPrint.pedidoFinanceiro,
        },
      ),
    );
    _verificarResultadoPrint();
    expect(
      find.text('Score de Risco: ${esperado.pontuacao}/100'),
      findsOneWidget,
    );
    expect(find.text('Semelhança com golpe já catalogado'), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsNothing,
    );
  });

  testWidgets('com a base consultada e nenhum sinal: o rótulo da faixa '
      'verde aparece, sem aviso de verificação incompleta', (tester) async {
    await _analisar(
      tester,
      cliente: _ClienteFalso(
        respostas: [
          _concluida(
            sinais: const [],
            categoria: 'sem_indicios',
            baseConsultada: true,
          ),
        ],
      ),
    );

    _verificarResultadoPrint();
    expect(find.text('Score de Risco: 0/100'), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsNothing,
    );
  });

  testWidgets('análise concluída é gravada no histórico', (
    tester,
  ) async {
    final historico = FakeHistoricoRepository();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      historico: historico,
    );
    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pumpAndSettle();

    final registro = historico.analises.single;
    expect(registro.tipoEntrada, TipoEntrada.imagem);
    expect(registro.categoria, isNotNull);
    expect(registro.explicacao, isNot(contains(_textoGolpe)));
  });

  testWidgets('análise interrompida não é gravada no histórico', (tester) async {
    final semRegistro = FakeHistoricoRepository();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      cliente: _ClienteFalso(
        respostas: [const AnaliseTextoNaoAutenticadoException()],
      ),
      historico: semRegistro,
    );
    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pumpAndSettle();

    expect(semRegistro.analises, isEmpty);
  });

  testWidgets('feedback de carregamento aparece imediatamente após o '
      'acionamento (RNF03)', (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    await _abrir(
      tester,
      seletor: _SeletorFalso(arquivo: _ArquivoFalso()),
      cliente: _ClienteFalso(completer: completer),
    );

    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pump();

    expect(find.byKey(const Key('analisar_print_carregando')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.byKey(const Key('analisar_print_botao')),
          )
          .onPressed,
      isNull,
    );

    completer.complete(_concluida());
    await tester.pumpAndSettle();
    _verificarResultadoPrint();
  });

  testWidgets('a imagem é descartada da memória ao exibir o resultado e a '
      'tela de seleção volta sem conteúdo nem mensagem', (tester) async {
    final arquivo = _ArquivoFalso();
    await _analisar(tester, arquivo: arquivo);

    _verificarResultadoPrint();
    expect(arquivo.bytes.every((b) => b == 0), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('analisar_print_interrupcao')), findsNothing);
    expect(find.byKey(const Key('analisar_print_carregando')), findsNothing);
    expect(find.text('Escolher print'), findsOneWidget);
  });

  group('interrupções do pipeline: mensagem própria, sem resultado', () {
    testWidgets('texto insuficiente na primeira verificação de volume', (
      tester,
    ) async {
      final cliente = _ClienteFalso();
      await _analisar(
        tester,
        reconhecedor: _ReconhecedorFalso(texto: 'oi tudo bem'),
        cliente: cliente,
      );

      _verificarInterrupcao(MotivoInterrupcaoPrint.textoInsuficiente);
      expect(cliente.chamadas, 0);
    });

    testWidgets('texto insuficiente na segunda verificação de volume, após o '
        'mascaramento', (tester) async {
      final cliente = _ClienteFalso();
      await _analisar(
        tester,
        reconhecedor: _ReconhecedorFalso(
          texto: '(11) 91234-5678 a@b.com 123.456.789-09 12.345.678/0001-90',
        ),
        cliente: cliente,
      );

      _verificarInterrupcao(
        MotivoInterrupcaoPrint.textoInsuficienteAposMascaramento,
      );
      expect(cliente.chamadas, 0);
    });

    testWidgets('falha de OCR', (tester) async {
      final cliente = _ClienteFalso();
      await _analisar(
        tester,
        reconhecedor: _ReconhecedorFalso(erro: Exception('ML Kit falhou')),
        cliente: cliente,
      );

      _verificarInterrupcao(MotivoInterrupcaoPrint.falhaReconhecimento);
      expect(find.textContaining('ML Kit'), findsNothing);
      expect(cliente.chamadas, 0);
    });

    testWidgets('falha na chamada ao modelo: serviço indisponível', (
      tester,
    ) async {
      await _analisar(
        tester,
        cliente: _ClienteFalso(
          respostas: [const AnaliseTextoIndisponivelException('status 500')],
        ),
      );

      _verificarInterrupcao(MotivoInterrupcaoPrint.indisponivel);
      expect(find.textContaining('500'), findsNothing);
    });

    testWidgets('falha na chamada ao modelo: tempo esgotado na Function', (
      tester,
    ) async {
      await _analisar(
        tester,
        cliente: _ClienteFalso(
          respostas: [
            {'status': 'nao_concluida', 'motivo': 'timeout'},
          ],
        ),
      );

      _verificarInterrupcao(MotivoInterrupcaoPrint.timeout);
    });

    testWidgets('resposta inválida do modelo: descartada sem exibição '
        'parcial, com oferta de nova tentativa que refaz o fluxo', (
      tester,
    ) async {
      final seletor = _SeletorFalso(arquivo: _ArquivoFalso());
      final cliente = _ClienteFalso(
        respostas: [_respostaForaDoFormato, _concluida()],
      );
      await _abrir(tester, seletor: seletor, cliente: cliente);
      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();

      _verificarInterrupcao(MotivoInterrupcaoPrint.respostaInvalida);
      expect(find.text('Falso contato'), findsNothing);
      expect(find.text('Escolher o print de novo'), findsOneWidget);

      await tester.tap(find.text('Escolher o print de novo'));
      await tester.pumpAndSettle();

      expect(seletor.selecoes, 2);
      _verificarResultadoPrint();
    });
  });

  testWidgets('FileSystemException da captura: mensagem genérica, sem o nome '
      'original do print na tela nem no log', (tester) async {
    final logs = <String?>[];
    final debugPrintOriginal = debugPrint;
    debugPrint = (String? mensagem, {int? wrapWidth}) => logs.add(mensagem);
    // Restaurado antes do fim do corpo: o framework confere, antes do
    // tearDown, que nenhuma variável de depuração ficou alterada.
    try {
      await _analisar(
        tester,
        arquivo: _ArquivoFalso(
          erroLeitura: const FileSystemException(
            'Cannot open file',
            '/data/user/0/app/cache/uuid/$_nomeOriginalPrint',
          ),
        ),
      );

      _verificarInterrupcao(MotivoInterrupcaoPrint.falhaCaptura);
      expect(find.textContaining('Screenshot'), findsNothing);
      expect(find.textContaining('FileSystemException'), findsNothing);
      expect(logs.where((l) => l?.contains('Screenshot') ?? false), isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = debugPrintOriginal;
    }
  });

  testWidgets('seleção cancelada: volta ao estado inicial, sem mensagem', (
    tester,
  ) async {
    final cliente = _ClienteFalso();
    await _abrir(tester, seletor: _SeletorFalso(), cliente: cliente);
    await tester.tap(find.byKey(const Key('analisar_print_botao')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('analisar_print_interrupcao')), findsNothing);
    expect(find.byKey(const Key('analisar_print_carregando')), findsNothing);
    expect(find.text('Resultado da Análise'), findsNothing);
    expect(cliente.chamadas, 0);
  });

  testWidgets('resultado de link pela mesma rota continua como antes: '
      'verificações, aviso de falibilidade e aviso permanente', (tester) async {
    final score = CalculadoraScore.calcular(
      const SinaisIdentificados(link: {SinalLink.typosquatting}),
    );
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            RouteSettings(
              name: AppRoutes.resultado,
              arguments: ResultadoAnaliseLink(
                score: score,
                verificacoes: const [
                  VerificacaoLink(
                    titulo: 'Imitação de endereço conhecido',
                    descricao: 'Descrição de teste.',
                    fonte: 'Fonte de teste',
                    status: StatusVerificacao.sinalEncontrado,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resultado da Análise'), findsOneWidget);
    expect(find.text(score.rotulo), findsOneWidget);
    expect(find.text('O que verificamos'), findsOneWidget);
    expect(find.text('Imitação de endereço conhecido'), findsOneWidget);
    expect(find.text(RotulosRisco.avisoFalibilidadeReputacao), findsOneWidget);
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
    expect(find.text('O que encontramos na mensagem'), findsNothing);
    expect(find.textContaining(_termoProibido), findsNothing);
  });

  group('correções da auditoria da Fase 6.3', () {
    testWidgets('D2: estado vazio com verificação incompleta não usa ícone de '
        'confirmação e diz que a verificação não pôde ser completa', (
      tester,
    ) async {
      await _analisar(
        tester,
        cliente: _ClienteFalso(
          respostas: [_concluida(sinais: const [], categoria: 'sem_indicios')],
        ),
      );

      final vazio = find.byKey(const Key('resultado_print_sem_sinais'));
      expect(vazio, findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      // Ícone neutro de informação, nem confirmação nem alerta (achado 6
      // do ensaio de 2026-11-16: o "?" laranja soava como aviso).
      expect(
        find.descendant(of: vazio, matching: find.byIcon(Icons.info_outline)),
        findsOneWidget,
      );
      final icone = tester.widget<Icon>(
        find.byKey(const Key('resultado_print_sem_sinais_icone')),
      );
      // Neutra no visual noturno da tela.
      expect(icone.color, CoresTema.noturno.textoSecundario);
      expect(
        find.descendant(
          of: vazio,
          matching: find.textContaining('não pôde ser completa'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Nenhum sinal de golpe identificado no texto'),
        findsNothing,
      );
      // Rótulo da faixa e aviso permanente do RF07 intactos.
      expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
      expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
      expect(find.textContaining(_termoProibido), findsNothing);
    });

    testWidgets('D2: estado vazio sem verificação incompleta (após a Fase 7) '
        'também não usa ícone de confirmação', (tester) async {
      final score = CalculadoraScore.calcular(const SinaisIdentificados());
      await tester.pumpWidget(
        MaterialApp(
          home: ResultadoAnalisePage.print(
            resultado: AnalisePrintConcluida(
              score: score,
              sinais: const {},
              categoria: CategoriaAmeaca.semIndicios,
              explicacao: _explicacao,
              data: DateTime(2026, 10, 19),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(
        find.text('Não identificamos sinais de golpe conhecidos neste texto.'),
        findsOneWidget,
      );
      expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
      expect(find.textContaining(_termoProibido), findsNothing);
    });

    testWidgets('D3: o texto da tela de seleção diz que a imagem não sai do '
        'celular e que o texto é enviado, sem prometer que nada é guardado', (
      tester,
    ) async {
      await _abrir(tester, seletor: _SeletorFalso());

      expect(find.textContaining('não sai do seu celular'), findsOneWidget);
      expect(find.textContaining('enviamos só o texto'), findsOneWidget);
      expect(find.textContaining('nem guardada'), findsNothing);
      expect(find.textContaining('não é enviada'), findsNothing);
      expect(find.textContaining(_termoProibido), findsNothing);
    });

    testWidgets('D4: resposta inválida orienta a escolher o print de novo, e o '
        'botão diz isso', (tester) async {
      final seletor = _SeletorFalso(arquivo: _ArquivoFalso());
      await _abrir(
        tester,
        seletor: seletor,
        cliente: _ClienteFalso(
          respostas: [_respostaForaDoFormato, _concluida()],
        ),
      );
      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('escolha o mesmo print outra vez'),
        findsOneWidget,
      );
      expect(find.text('Escolher o print de novo'), findsOneWidget);

      await tester.tap(find.text('Escolher o print de novo'));
      await tester.pumpAndSettle();
      expect(seletor.selecoes, 2);
      _verificarResultadoPrint();
    });

    testWidgets('D4: interrupção sem nova tentativa mantém o rótulo comum', (
      tester,
    ) async {
      await _analisar(
        tester,
        reconhecedor: _ReconhecedorFalso(texto: 'oi tudo bem'),
      );

      expect(find.text('Escolher print'), findsOneWidget);
      expect(find.text('Escolher o print de novo'), findsNothing);
    });

    testWidgets('D1: sem sessão reconhecida, a mensagem não usa "sessão" e o '
        'botão encerra a sessão e leva ao login', (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
            settings,
            authRepository: auth,
            seletorImagem: _SeletorFalso(arquivo: _ArquivoFalso()),
            reconhecedorTexto: _ReconhecedorFalso(),
            analiseTextoClient: _ClienteFalso(
              respostas: [const AnaliseTextoNaoAutenticadoException()],
            ),
            historicoRepository: FakeHistoricoRepository(),
            consentimentoRepository: FakeConsentimentoRepository(),
          ),
          initialRoute: AppRoutes.analisarPrint,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();

      _verificarInterrupcao(MotivoInterrupcaoPrint.naoAutenticado);
      expect(
        find.textContaining(RegExp('sess', caseSensitive: false)),
        findsNothing,
      );
      // Só um caminho na tela: escolher outro print não resolveria.
      expect(find.byKey(const Key('analisar_print_botao')), findsNothing);
      expect(find.text('Entrar de novo'), findsOneWidget);

      await tester.tap(find.text('Entrar de novo'));
      await tester.pumpAndSettle();

      expect(auth.saiu, isTrue);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Analisar print'), findsNothing);
      // A pilha foi limpa: não há como voltar à tela de análise.
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });

    testWidgets('D1: o botão "Entrar de novo" só aparece na falta de sessão', (
      tester,
    ) async {
      await _analisar(
        tester,
        cliente: _ClienteFalso(
          respostas: [const AnaliseTextoIndisponivelException('status 500')],
        ),
      );

      expect(find.text('Entrar de novo'), findsNothing);
      expect(find.byKey(const Key('analisar_print_botao')), findsOneWidget);
    });

    group('D1-a: falha ao obter o token, pelo cliente HTTP real', () {
      Future<(FakeAuthRepository, int Function())> abrirComToken(
        WidgetTester tester,
        Object erroToken,
      ) async {
        final auth = FakeAuthRepository();
        var chamadasFunction = 0;
        final cliente = AnaliseTextoClientHttp(
          obterToken: () async => throw erroToken,
          clienteHttp: MockClient((_) async {
            chamadasFunction++;
            return http.Response('{}', 200);
          }),
          endpoint: Uri.parse('http://function.test/analiseTexto'),
        );
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
              settings,
              authRepository: auth,
              seletorImagem: _SeletorFalso(arquivo: _ArquivoFalso()),
              reconhecedorTexto: _ReconhecedorFalso(),
              analiseTextoClient: cliente,
              consentimentoRepository: FakeConsentimentoRepository(),
            ),
            initialRoute: AppRoutes.analisarPrint,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('analisar_print_botao')));
        await tester.pumpAndSettle();
        return (auth, () => chamadasFunction);
      }

      testWidgets('sem conexão: falha de conexão, sem diagnóstico de '
          'identidade, e o caminho de nova tentativa continua', (tester) async {
        final (auth, chamadas) = await abrirComToken(
          tester,
          FirebaseAuthException(code: FirebaseAuthCodigos.falhaRede),
        );

        _verificarInterrupcao(MotivoInterrupcaoPrint.indisponivel);
        expect(
          find.text(MotivoInterrupcaoPrint.naoAutenticado.mensagem),
          findsNothing,
        );
        expect(find.text('Entrar de novo'), findsNothing);
        expect(find.text('Escolher print'), findsOneWidget);
        expect(chamadas(), 0);
        expect(auth.saiu, isFalse);

        // A nova tentativa refaz o fluxo.
        await tester.tap(find.byKey(const Key('analisar_print_botao')));
        await tester.pumpAndSettle();
        _verificarInterrupcao(MotivoInterrupcaoPrint.indisponivel);
      });

      testWidgets('token rejeitado: não autenticado, e o botão encerra a '
          'sessão e leva ao login', (tester) async {
        final (auth, chamadas) = await abrirComToken(
          tester,
          FirebaseAuthException(code: 'user-token-expired'),
        );

        _verificarInterrupcao(MotivoInterrupcaoPrint.naoAutenticado);
        expect(find.byKey(const Key('analisar_print_botao')), findsNothing);
        expect(chamadas(), 0);

        await tester.tap(find.text('Entrar de novo'));
        await tester.pumpAndSettle();

        expect(auth.saiu, isTrue);
        expect(find.text('Criar conta'), findsOneWidget);
      });
    });

    testWidgets('D3-a/D3-b: o texto diz que vai o texto que aparece no print '
        'e não promete esconder tudo', (tester) async {
      await _abrir(tester, seletor: _SeletorFalso());

      expect(
        find.textContaining('enviamos só o texto que aparece no print'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'procuramos esconder dados como CPF, telefone e cartão',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('texto da mensagem'), findsNothing);
      expect(find.textContaining('escondidos'), findsNothing);
      expect(find.textContaining(_termoProibido), findsNothing);
    });
  });

  group('tutorial de primeiro uso (RF13)', () {
    const tituloTutorial = 'Tire o print da conversa';

    testWidgets('aparece na primeira abertura, antes da escolha; o '
        'consentimento continua aparecendo ao escolher o print', (
      tester,
    ) async {
      final tutorial = FakeTutorialRepository(vistos: {});
      final seletor = _SeletorFalso(arquivo: _ArquivoFalso());
      await _abrir(
        tester,
        seletor: seletor,
        tutorial: tutorial,
        consentimento: FakeConsentimentoRepository(aceitou: false),
      );

      expect(find.text(tituloTutorial), findsOneWidget);
      await tester.tap(find.byKey(const Key('tutorial_pular')));
      await tester.pumpAndSettle();
      expect(tutorial.vistos, contains(TipoTutorial.print));

      await tester.tap(find.byKey(const Key('analisar_print_botao')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consentimento_aceitar')), findsOneWidget);
      expect(seletor.selecoes, 0);
    });

    testWidgets('o botão de ajuda reabre o tutorial', (tester) async {
      await _abrir(tester, seletor: _SeletorFalso());

      expect(find.text(tituloTutorial), findsNothing);
      await tester.tap(find.byKey(const Key('analisar_print_ajuda')));
      await tester.pumpAndSettle();
      expect(find.text(tituloTutorial), findsOneWidget);
    });

    testWidgets('print compartilhado vai à análise sem o tutorial, e o '
        'resultado oferece "Como funciona?"', (tester) async {
      final tutorial = FakeTutorialRepository(vistos: {});
      await _abrirCompartilhado(
        tester,
        conteudo: ImagemCompartilhada(_imagemCompartilhada()),
        tutorial: tutorial,
      );

      expect(find.byKey(const Key('resultado_aviso_permanente')), findsOneWidget);
      expect(find.text(tituloTutorial), findsNothing);

      await tester.tap(find.byKey(const Key('resultado_como_funciona')));
      await tester.pumpAndSettle();
      expect(find.text(tituloTutorial), findsOneWidget);
    });
  });
}

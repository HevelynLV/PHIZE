import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/rdap_client.dart';
import 'package:phize/features/analise/domain/reputacao_dominio_client.dart';
import 'package:phize/features/analise/domain/resultado_analise_link.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_link.dart';
import 'package:phize/features/analise/domain/verificacao_link.dart';
import 'package:phize/features/analise/presentation/pages/resultado_analise_page.dart';

/// Dublê de RDAP: nenhum teste deste arquivo acessa a rede. Registra cada
/// domínio pedido e, por padrão, responde com o `ldhName` do próprio
/// domínio pedido, como um servidor RDAP real sem redirecionamento.
/// [ldhNameRespondido] simula a resposta de outro domínio (ex.: o
/// redirecionamento do Registro.br para um nome parecido).
class _RdapClientFalso implements RdapClient {
  _RdapClientFalso({
    this.dataRegistro,
    this.ldhNameRespondido,
    this.erro,
    this.completer,
  });

  final DateTime? dataRegistro;
  final String? ldhNameRespondido;
  final Object? erro;
  final Completer<Map<String, dynamic>>? completer;

  final List<String> dominiosConsultados = [];

  @override
  Future<Map<String, dynamic>> consultarDominio(String dominioNormalizado) {
    dominiosConsultados.add(dominioNormalizado);
    final completer = this.completer;
    if (completer != null) return completer.future;
    final erro = this.erro;
    if (erro != null) return Future.error(erro);
    return Future.value(
      _registradoEm(ldhNameRespondido ?? dominioNormalizado, dataRegistro!),
    );
  }
}

Map<String, dynamic> _registradoEm(String ldhName, DateTime data) => {
  'ldhName': ldhName,
  'events': [
    {'eventAction': 'registration', 'eventDate': data.toIso8601String()},
  ],
};

_RdapClientFalso _rdapDominioAntigo() =>
    _RdapClientFalso(dataRegistro: DateTime(2000, 1, 15));

_RdapClientFalso _rdapDominioRecente() => _RdapClientFalso(
  dataRegistro: DateTime.now().subtract(const Duration(days: 5)),
);

_RdapClientFalso _rdapIndisponivel() => _RdapClientFalso(
  erro: const RdapIndisponivelException('serviço fora do ar'),
);

/// Dublê da Function `reputacaoDominio`: nenhum teste deste arquivo acessa
/// a rede. Registra cada URL recebida, para provar que a normalização
/// (sem query nem fragmento) ocorre antes da transmissão.
class _ReputacaoClientFalso implements ReputacaoDominioClient {
  _ReputacaoClientFalso.comResposta(Map<String, dynamic> resposta)
    : _resposta = resposta,
      _erro = null;

  _ReputacaoClientFalso.comErro(Object erro) : _resposta = null, _erro = erro;

  final Map<String, dynamic>? _resposta;
  final Object? _erro;

  final List<String> urlsConsultadas = [];

  @override
  Future<Map<String, dynamic>> consultarUrl(String urlNormalizada) {
    urlsConsultadas.add(urlNormalizada);
    final erro = _erro;
    if (erro != null) return Future.error(erro);
    return Future.value(_resposta);
  }
}

_ReputacaoClientFalso _reputacaoNaoListado() =>
    _ReputacaoClientFalso.comResposta({'status': 'nao_listado'});

_ReputacaoClientFalso _reputacaoListado() =>
    _ReputacaoClientFalso.comResposta({
      'status': 'listado',
      'tiposAmeaca': ['SOCIAL_ENGINEERING'],
    });

_ReputacaoClientFalso _reputacaoIndisponivel() => _ReputacaoClientFalso.comErro(
  const ReputacaoIndisponivelException('Function fora do ar'),
);

Future<void> _abrirAnalisarLink(
  WidgetTester tester,
  RdapClient rdapClient, {
  ReputacaoDominioClient? reputacaoClient,
}) async {
  final reputacao = reputacaoClient ?? _reputacaoNaoListado();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        rdapClient: rdapClient,
        reputacaoClient: reputacao,
      ),
      initialRoute: AppRoutes.analisarLink,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _analisar(
  WidgetTester tester,
  RdapClient rdapClient,
  String entrada, {
  ReputacaoDominioClient? reputacaoClient,
}) async {
  await _abrirAnalisarLink(
    tester,
    rdapClient,
    reputacaoClient: reputacaoClient,
  );
  await tester.enterText(find.byKey(const Key('analisar_link_url')), entrada);
  await tester.tap(find.byKey(const Key('analisar_link_botao')));
  await tester.pumpAndSettle();
}

/// "Seguro" (ou "segura"/"seguros") como palavra isolada — o termo
/// proibido pela CLAUDE.md, Seção 5.
final _termoProibido = RegExp(r'\bsegur[oa]s?\b', caseSensitive: false);

void _verificarInvariantesDoResultado() {
  expect(find.text('Resultado da Análise'), findsOneWidget);
  expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  expect(find.text(RotulosRisco.avisoFalibilidadeReputacao), findsOneWidget);
  expect(find.textContaining(_termoProibido), findsNothing);
}

const _fonteGoogle = 'Fonte: Google Safe Browsing, serviço do Google';

void main() {
  testWidgets('domínio legítimo, três verificações concluídas sem sinais: '
      'faixa VERDE, sem aviso de verificação incompleta', (tester) async {
    final rdap = _rdapDominioAntigo();
    final reputacao = _reputacaoNaoListado();
    await _analisar(
      tester,
      rdap,
      'https://www.itau.com.br/conta?x=1#topo',
      reputacaoClient: reputacao,
    );

    _verificarInvariantesDoResultado();
    expect(rdap.dominiosConsultados, ['itau.com.br']);
    // Query string e fragmento descartados antes da transmissão; o caminho
    // é preservado (arquitetura, seção 4, etapa 2).
    expect(reputacao.urlsConsultadas, ['https://www.itau.com.br/conta']);
    expect(find.text('Score de Risco: 0/100'), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsNothing);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsNothing,
    );
    expect(find.textContaining('Verificação não concluída'), findsNothing);
    expect(
      find.textContaining(
        'Nenhum sinal de risco nesta verificação. Segundo o Google, este '
        'endereço não aparece na lista',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(_fonteGoogle), findsOneWidget);
  });

  testWidgets('domínio listado como malicioso: faixa vermelha, com o sinal '
      'listado e a fonte atribuída ao Google', (tester) async {
    final reputacao = _reputacaoListado();
    await _analisar(
      tester,
      _rdapDominioAntigo(),
      'exemplo-qualquer.org/pagar',
      reputacaoClient: reputacao,
    );

    _verificarInvariantesDoResultado();
    expect(reputacao.urlsConsultadas, ['http://exemplo-qualquer.org/pagar']);
    expect(find.text('Score de Risco: 70/100'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(
      find.textContaining(
        'Sinal de risco encontrado. Segundo o Google, este endereço aparece '
        'na lista de endereços identificados como possivelmente perigosos. '
        'Motivo apontado: página que tenta enganar as pessoas',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(_fonteGoogle), findsOneWidget);
    // Nenhuma categoria técnica chega à tela.
    expect(find.textContaining('SOCIAL_ENGINEERING'), findsNothing);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsNothing,
    );
  });

  testWidgets('domínio listado somado a typosquatting: score com teto de '
      '100', (tester) async {
    await _analisar(
      tester,
      _rdapDominioAntigo(),
      'https://itau-seguranca.com/login',
      reputacaoClient: _reputacaoListado(),
    );

    _verificarInvariantesDoResultado();
    expect(find.text('Score de Risco: 100/100'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.textContaining('Sinal de risco encontrado'), findsNWidgets(2));
  });

  testWidgets('domínio listado, typosquatting e domínio recente: score com '
      'teto de 100', (tester) async {
    await _analisar(
      tester,
      _rdapDominioRecente(),
      'https://itau-seguranca.com/login',
      reputacaoClient: _reputacaoListado(),
    );

    _verificarInvariantesDoResultado();
    expect(find.text('Score de Risco: 100/100'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.textContaining('Sinal de risco encontrado'), findsNWidgets(3));
  });

  testWidgets('reputação não concluída, sem outros sinais: faixa elevada de '
      'verde para amarelo, com aviso', (tester) async {
    await _analisar(
      tester,
      _rdapDominioAntigo(),
      'https://www.itau.com.br/conta',
      reputacaoClient: _reputacaoIndisponivel(),
    );

    expect(tester.takeException(), isNull);
    _verificarInvariantesDoResultado();
    // A pontuação real (0) é preservada; só a faixa é elevada.
    expect(find.text('Score de Risco: 0/100'), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsNothing);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Não foi possível concluir: Lista de endereços perigosos.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Verificação não concluída. Não foi possível consultar a lista de '
        'endereços já identificados como perigosos pelo Google. O Google '
        'Safe Browsing não pôde ser consultado agora.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(_fonteGoogle), findsOneWidget);
  });

  testWidgets('reputação não concluída, com typosquatting: 40 pontos, faixa '
      'amarela conforme a calibragem', (tester) async {
    await _analisar(
      tester,
      _rdapDominioAntigo(),
      'https://itau-seguranca.com/login',
      reputacaoClient: _reputacaoIndisponivel(),
    );

    _verificarInvariantesDoResultado();
    expect(find.text('Score de Risco: 40/100'), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
  });

  testWidgets('reputação não concluída, com typosquatting e domínio '
      'recente: 65 pontos, faixa vermelha conforme a calibragem', (
    tester,
  ) async {
    await _analisar(
      tester,
      _rdapDominioRecente(),
      'https://itau-seguranca.com/login',
      reputacaoClient: _reputacaoIndisponivel(),
    );

    _verificarInvariantesDoResultado();
    expect(find.text('Score de Risco: 65/100'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    // A verificação incompleta continua informada, mesmo fora do verde.
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
  });

  testWidgets('domínio com typosquatting e recém-criado: sinais somados, '
      'score 65 e faixa vermelha (cenário da calibragem v1.0)', (
    tester,
  ) async {
    final rdap = _rdapDominioRecente();
    await _analisar(tester, rdap, 'https://itau-seguranca.com/login');

    _verificarInvariantesDoResultado();
    // O domínio consultado é o digitado, nunca o da marca imitada.
    expect(rdap.dominiosConsultados, ['itau-seguranca.com']);
    expect(find.text('Score de Risco: 65/100'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.text('Imitação de endereço conhecido'), findsOneWidget);
    expect(
      find.textContaining(
        'Sinal de risco encontrado. O endereço se parece com itau.com.br',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Sinal de risco encontrado. O endereço foi criado'),
      findsOneWidget,
    );
  });

  testWidgets('RDAP responde com outro domínio (redirecionamento do '
      'Registro.br): idade não concluída, sem data do outro domínio', (
    tester,
  ) async {
    final rdap = _RdapClientFalso(
      dataRegistro: DateTime.utc(2009, 9, 25),
      ldhNameRespondido: 'itauseguranca.com.br',
    );
    await _analisar(tester, rdap, 'https://itau-seguranca.com.br/login');

    _verificarInvariantesDoResultado();
    expect(rdap.dominiosConsultados, ['itau-seguranca.com.br']);
    expect(find.textContaining('2009'), findsNothing);
    expect(
      find.textContaining(
        'Verificação não concluída. Não foi possível descobrir há quanto '
        'tempo o endereço existe. O RDAP respondeu com os dados de outro '
        'endereço',
      ),
      findsOneWidget,
    );
    // Só o typosquatting pontua (40): amarela, com aviso de incompleta.
    expect(find.text('Score de Risco: 40/100'), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
  });

  testWidgets('entrada inválida: mensagem pedindo reenvio, sem exceção', (
    tester,
  ) async {
    final rdap = _rdapDominioAntigo();
    final reputacao = _reputacaoNaoListado();
    await _analisar(
      tester,
      rdap,
      'isso não é um link',
      reputacaoClient: reputacao,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Isso não parece ser um link'),
      findsOneWidget,
    );
    expect(find.text('Resultado da Análise'), findsNothing);
    expect(rdap.dominiosConsultados, isEmpty);
    expect(reputacao.urlsConsultadas, isEmpty);

    // O app segue utilizável: uma nova submissão válida funciona.
    await tester.enterText(
      find.byKey(const Key('analisar_link_url')),
      'itau.com.br',
    );
    await tester.tap(find.byKey(const Key('analisar_link_botao')));
    await tester.pumpAndSettle();
    _verificarInvariantesDoResultado();
  });

  testWidgets('falha do RDAP: resultado aparece com os demais sinais e o '
      'aviso de verificação não concluída', (tester) async {
    final rdap = _rdapIndisponivel();
    await _analisar(tester, rdap, 'itau-seguranca.com');

    expect(tester.takeException(), isNull);
    expect(rdap.dominiosConsultados, ['itau-seguranca.com']);
    _verificarInvariantesDoResultado();
    // Só o typosquatting pontua: faixa amarela, conforme a tabela v1.0.
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(
      find.textContaining('O endereço se parece com itau.com.br'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Verificação não concluída. Não foi possível descobrir há quanto '
        'tempo o endereço existe. O serviço RDAP não pôde ser consultado '
        'agora.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('feedback de carregamento aparece imediatamente após a '
      'submissão (RNF03)', (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    await _abrirAnalisarLink(tester, _RdapClientFalso(completer: completer));

    await tester.enterText(
      find.byKey(const Key('analisar_link_url')),
      'itau.com.br',
    );
    await tester.tap(find.byKey(const Key('analisar_link_botao')));
    await tester.pump();

    expect(find.byKey(const Key('analisar_link_carregando')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_registradoEm('itau.com.br', DateTime(2000)));
    await tester.pumpAndSettle();
    _verificarInvariantesDoResultado();
  });

  group('Invariantes de toda tela de resultado', () {
    final cenariosDoFluxo =
        <
          String,
          (RdapClient Function(), ReputacaoDominioClient Function(), String)
        >{
          'banco legítimo': (
            _rdapDominioAntigo,
            _reputacaoNaoListado,
            'itau.com.br',
          ),
          'typosquatting recente': (
            _rdapDominioRecente,
            _reputacaoNaoListado,
            'nubannk.com',
          ),
          'RDAP indisponível': (
            _rdapIndisponivel,
            _reputacaoNaoListado,
            'bradesco.com.br',
          ),
          'domínio sem sinal': (
            _rdapDominioAntigo,
            _reputacaoNaoListado,
            'exemplo-qualquer.org',
          ),
          'domínio listado': (
            _rdapDominioAntigo,
            _reputacaoListado,
            'exemplo-qualquer.org',
          ),
          'reputação indisponível': (
            _rdapDominioAntigo,
            _reputacaoIndisponivel,
            'itau.com.br',
          ),
          'todas as fontes indisponíveis': (
            _rdapIndisponivel,
            _reputacaoIndisponivel,
            'nubannk.com',
          ),
        };

    for (final MapEntry(key: nome, value: (rdap, reputacao, url))
        in cenariosDoFluxo.entries) {
      testWidgets('fluxo "$nome": sem "Seguro", com aviso permanente e aviso '
          'de falibilidade', (tester) async {
        await _analisar(tester, rdap(), url, reputacaoClient: reputacao());
        _verificarInvariantesDoResultado();
      });
    }

    // A tela também é exercitada diretamente nas três faixas, independente
    // do fluxo, para garantir a rotulagem e os avisos nela.
    final sinaisPorFaixa = <String, SinaisIdentificados>{
      'verde': const SinaisIdentificados(),
      'amarela': const SinaisIdentificados(link: {SinalLink.typosquatting}),
      'vermelha': const SinaisIdentificados(
        link: {SinalLink.typosquatting, SinalLink.dominioRecemCriado},
      ),
    };

    for (final MapEntry(key: faixa, value: sinais) in sinaisPorFaixa.entries) {
      testWidgets('faixa $faixa: sem "Seguro" e com aviso permanente', (
        tester,
      ) async {
        final score = CalculadoraScore.calcular(sinais);
        await tester.pumpWidget(
          MaterialApp(
            home: ResultadoAnalisePage(
              resultado: ResultadoAnaliseLink(
                score: score,
                verificacoes: const [
                  VerificacaoLink(
                    titulo: 'Imitação de endereço conhecido',
                    descricao: 'Descrição de teste.',
                    fonte: 'Fonte de teste',
                    status: StatusVerificacao.semSinal,
                  ),
                ],
              ),
            ),
          ),
        );

        _verificarInvariantesDoResultado();
        expect(find.text(score.rotulo), findsOneWidget);
        expect(
          find.byKey(const Key('resultado_verificacao_incompleta')),
          findsNothing,
        );
      });
    }
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/rdap_client.dart';
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

Future<void> _abrirAnalisarLink(
  WidgetTester tester,
  RdapClient rdapClient,
) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, rdapClient: rdapClient),
      initialRoute: AppRoutes.analisarLink,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _analisar(
  WidgetTester tester,
  RdapClient rdapClient,
  String entrada,
) async {
  await _abrirAnalisarLink(tester, rdapClient);
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
  expect(find.textContaining(_termoProibido), findsNothing);
}

void main() {
  testWidgets('URL legítima de banco: amarelo, nunca verde, com aviso de '
      'verificação incompleta', (tester) async {
    final rdap = _rdapDominioAntigo();
    await _analisar(tester, rdap, 'https://www.itau.com.br/conta?x=1');

    _verificarInvariantesDoResultado();
    expect(rdap.dominiosConsultados, ['itau.com.br']);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsNothing);
    // A pontuação real (0) é preservada; só a faixa é elevada.
    expect(find.text('Score de Risco: 0/100'), findsOneWidget);
    expect(
      find.byKey(const Key('resultado_verificacao_incompleta')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Lista de endereços perigosos'),
      findsWidgets,
    );
    expect(find.textContaining('Fonte: Google Safe Browsing'), findsOneWidget);
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
    await _analisar(tester, rdap, 'isso não é um link');

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Isso não parece ser um link'),
      findsOneWidget,
    );
    expect(find.text('Resultado da Análise'), findsNothing);
    expect(rdap.dominiosConsultados, isEmpty);

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
    final cenariosDoFluxo = <String, (RdapClient Function(), String)>{
      'banco legítimo': (_rdapDominioAntigo, 'itau.com.br'),
      'typosquatting recente': (_rdapDominioRecente, 'nubannk.com'),
      'RDAP indisponível': (_rdapIndisponivel, 'bradesco.com.br'),
      'domínio sem sinal': (_rdapDominioAntigo, 'exemplo-qualquer.org'),
    };

    for (final MapEntry(key: nome, value: (rdap, url))
        in cenariosDoFluxo.entries) {
      testWidgets('fluxo "$nome": sem "Seguro" e com aviso permanente', (
        tester,
      ) async {
        await _analisar(tester, rdap(), url);
        _verificarInvariantesDoResultado();
      });
    }

    // A faixa verde é inalcançável pelo fluxo de link enquanto o Safe
    // Browsing não existir; a tela é exercitada diretamente nas três faixas
    // para garantir a rotulagem também nela.
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

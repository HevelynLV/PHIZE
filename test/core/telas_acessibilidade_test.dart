import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/core/theme/app_theme.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/exemplo_tutorial_link.dart';
import 'package:phize/features/analise/domain/exemplo_tutorial_print.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/golpe_da_semana.dart';
import 'package:phize/features/analise/domain/resultado_analise_link.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/verificacao_link.dart';
import 'package:phize/features/analise/presentation/pages/como_calcula_risco_page.dart';
import 'package:phize/features/analise/presentation/tutorial/tutorial_link.dart';
import 'package:phize/features/analise/presentation/tutorial/tutorial_print.dart';
import 'package:phize/features/comunidade/domain/meus_reportes_repository.dart';
import 'package:phize/features/comunidade/domain/motivo_denuncia.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/features/conta/domain/preferencias_aparencia.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_consentimento_repository.dart';
import '../support/fake_conta_repository.dart';
import '../support/fake_feed_repository.dart';
import '../support/fake_historico_repository.dart';
import '../support/fake_meus_reportes_repository.dart';
import '../support/fake_tutorial_repository.dart';

/// Telas principais no maior tamanho de letra do perfil (RF14), em tela de
/// celular pequeno: nenhuma pode estourar o layout.

final _resultadoLink = ResultadoAnaliseLink(
  score: ExemploTutorialLink.todos.first.resultado,
  verificacoes: const [
    VerificacaoLink(
      titulo: 'Endereço parecido com o de empresa conhecida',
      descricao: 'Nenhuma semelhança encontrada.',
      fonte: 'Fonte: comparação feita no aparelho',
      status: StatusVerificacao.semSinal,
    ),
    VerificacaoLink(
      titulo: 'Idade do site',
      descricao: 'Não foi possível consultar.',
      fonte: 'Fonte: registro público de domínios',
      status: StatusVerificacao.naoConcluida,
    ),
    VerificacaoLink(
      titulo: 'Reputação do endereço',
      descricao: 'Endereço listado como perigoso.',
      fonte: 'Fonte: Google Safe Browsing, serviço do Google',
      status: StatusVerificacao.sinalEncontrado,
    ),
  ],
);

final _resultadoPrint = AnalisePrintConcluida(
  score: ExemploTutorialPrint.todos.first.resultado,
  sinais: ExemploTutorialPrint.todos.first.sinaisEmOrdem.toSet(),
  categoria: CategoriaAmeaca.falsoContato,
  explicacao:
      'A mensagem pede dinheiro com urgência e diz que o número mudou. '
      'Ligue para o número antigo antes de qualquer pagamento.',
  data: DateTime(2026, 11, 12),
);

final _historico = [
  for (final faixa in FaixaRisco.values)
    AnaliseRisco(
      id: faixa.name,
      score: switch (faixa) {
        FaixaRisco.baixo => 10,
        FaixaRisco.medio => 45,
        FaixaRisco.alto => 90,
      },
      faixa: faixa,
      categoria: CategoriaAmeaca.falsoContato,
      explicacao: 'Explicação de exemplo para o histórico.',
      tipoEntrada: AnaliseRisco.doPrint(_resultadoPrint).tipoEntrada,
      data: DateTime(2026, 11, 12),
    ),
];

const _golpeDaSemana = FichaEducativa(
  id: 'falsa-central-falso-funcionario',
  modalidade: 'Falsa central de atendimento ou falso funcionário do banco',
  categoria: CategoriaAmeaca.falsaCentralOuInstituicao,
  canais: ['Ligação', 'WhatsApp', 'SMS'],
  frasesComuns: [
    'identificamos uma compra suspeita no seu cartão',
    'vou transferir para o setor de segurança',
  ],
  oQuePedem: 'Senha, código de verificação ou transferência para conta segura.',
  oQueFazer:
      'Desligue e ligue você mesmo para o número do verso do cartão. O banco '
      'não pede senha nem transferência para proteger a conta.',
  fontes: [(publicador: 'Fonte pública de exemplo', titulo: 'Alerta')],
);

Future<void> _abrir(
  WidgetTester tester, {
  required ThemeData tema,
  String? rota,
  Object? argumentos,
  Widget? tela,
}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: tema,
      builder: (context, filho) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: aplicarTamanhoLetra(
            TextScaler.noScaling,
            TamanhoLetra.muitoGrande,
          ),
        ),
        child: filho!,
      ),
      home: tela,
      onGenerateRoute: tela != null
          ? null
          : (settings) => AppRouter.onGenerateRoute(
              settings.name == '/'
                  ? RouteSettings(name: rota, arguments: argumentos)
                  : settings,
              authRepository: FakeAuthRepository(),
              contaRepository: FakeContaRepository(),
              historicoRepository: FakeHistoricoRepository(
                analises: [..._historico],
              ),
              compartilhador: FakeCompartilhador(),
              consentimentoRepository: FakeConsentimentoRepository(),
              tutorialRepository: FakeTutorialRepository(),
              feedRepository: FakeFeedRepository(
                reportes: [
                  reporteDeTeste(),
                  reporteDeTeste(id: 'r2', curtidas: 1),
                ],
              ),
              compartilhadorTexto: FakeCompartilhadorTexto(),
              meusReportesRepository: FakeMeusReportesRepository(
                reportes: [
                  MeuReporte(
                    id: 'r1',
                    publicadoEm: DateTime(2026, 11, 16),
                    reporte: reporteDeTeste(),
                  ),
                  MeuReporte(id: 'r2', publicadoEm: DateTime(2026, 11, 15)),
                ],
              ),
              moderacaoRepository: FakeModeracaoRepository(
                reportes: [
                  reporteDeTeste(status: StatusReporte.oculto, denuncias: 3),
                ],
                motivos: {MotivoDenuncia.acusaOrganizacaoLegitima: 3},
              ),
            ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (nomeTema, tema) in [('do app', AppTheme.noturno)]) {
    group('tema $nomeTema, letra muito grande', () {
      final rotas = <String, (String, Object?)>{
        'login': (AppRoutes.login, null),
        'cadastro': (AppRoutes.cadastro, null),
        'painel': (AppRoutes.dashboard, null),
        'histórico': (AppRoutes.historico, null),
        'detalhe do histórico': (AppRoutes.detalheHistorico, _historico.last),
        'análise de link': (AppRoutes.analisarLink, null),
        'análise de print': (AppRoutes.analisarPrint, null),
        'resultado do link': (AppRoutes.resultado, _resultadoLink),
        'resultado do print': (AppRoutes.resultado, _resultadoPrint),
        'perfil': (AppRoutes.perfil, null),
        'comunidade': (AppRoutes.comunidade, null),
        'detalhe do reporte': (AppRoutes.detalheReporte, reporteDeTeste()),
        'moderação': (AppRoutes.moderacao, null),
        'golpe da semana': (AppRoutes.golpeDaSemana, _golpeDaSemana),
        'pesquisa da comunidade': (AppRoutes.pesquisaComunidade, null),
        'meus reportes': (AppRoutes.meusReportes, null),
        'editar reporte': (AppRoutes.editarReporte, reporteDeTeste()),
      };
      for (final MapEntry(key: nome, value: (rota, argumentos))
          in rotas.entries) {
        testWidgets('$nome sem estouro de layout', (tester) async {
          await _abrir(tester, tema: tema, rota: rota, argumentos: argumentos);
          expect(tester.takeException(), isNull);

          // A rolagem até o fim mostra o que está abaixo da dobra.
          final rolaveis = find.byType(Scrollable);
          if (rolaveis.evaluate().isNotEmpty) {
            await tester.drag(rolaveis.first, const Offset(0, -4000));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('como o risco é calculado sem estouro de layout', (
        tester,
      ) async {
        await _abrir(tester, tema: tema, tela: const ComoCalculaRiscoPage());
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -6000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      for (final (nome, tela) in [
        ('tutorial do link', const TutorialLinkPage()),
        ('tutorial do print', const TutorialPrintPage()),
      ]) {
        testWidgets('$nome sem estouro em todas as etapas', (tester) async {
          await _abrir(tester, tema: tema, tela: tela);
          for (var etapa = 0; etapa < 4; etapa++) {
            expect(tester.takeException(), isNull);
            final proximo = find.text('Próximo');
            if (proximo.evaluate().isEmpty) break;
            await tester.ensureVisible(proximo);
            await tester.tap(proximo);
            await tester.pumpAndSettle();
          }
          expect(find.text('Começar'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  test('rótulos das faixas mantêm contraste de texto nos dois temas', () {
    double luminancia(Color cor) => cor.computeLuminance();
    double contraste(Color a, Color b) {
      final (claro, escuro) = luminancia(a) > luminancia(b) ? (a, b) : (b, a);
      return (luminancia(claro) + 0.05) / (luminancia(escuro) + 0.05);
    }

    for (final (tema, cores) in [
      (Brightness.light, CoresTema.claro),
      (Brightness.dark, CoresTema.noturno),
    ]) {
      for (final faixa in FaixaRisco.values) {
        final texto = faixa.corTextoEm(tema);
        expect(
          contraste(texto, cores.fundo),
          greaterThanOrEqualTo(4.5),
          reason: '$faixa sobre o fundo, tema $tema',
        );
        expect(
          contraste(texto, cores.superficie),
          greaterThanOrEqualTo(4.5),
          reason: '$faixa sobre a superfície, tema $tema',
        );
      }
      expect(contraste(cores.tinta, cores.fundo), greaterThanOrEqualTo(4.5));
      expect(
        contraste(cores.textoSecundario, cores.fundoSuave),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contraste(cores.azulEscuro, cores.azulClaro),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

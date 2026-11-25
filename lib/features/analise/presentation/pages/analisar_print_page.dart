import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../auth/data/firebase_auth_repository.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../data/consentimento_repository_local.dart';
import '../../data/historico_repository_firestore.dart';
import '../../data/tutorial_repository_local.dart';
import '../../domain/analisador_print.dart';
import '../../domain/analise_risco.dart';
import '../../../../shared/domain/captura_imagem.dart';
import '../../domain/consentimento_repository.dart';
import '../../domain/historico_repository.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/tutorial_repository.dart';
import '../registro_historico.dart';
import '../tutorial/tutorial_page.dart';
import '../tutorial/tutorial_print.dart';
import '../../../../shared/widgets/scaffold_phize.dart';
import '../widgets/progresso_analise.dart';
import '../widgets/visual_noturno.dart';
import 'consentimento_page.dart';

/// Tela "Analisar print" (UC04, passo 1): o usuário escolhe o print na
/// galeria e o pipeline (`AnalisadorPrint`) é executado.
///
/// A tela não guarda imagem nem texto em momento algum: recebe do pipeline
/// apenas o resultado (sem conteúdo da conversa) ou o motivo da
/// interrupção, cuja mensagem é sempre a própria de
/// [MotivoInterrupcaoPrint] — nunca a de uma exceção. Em especial, a
/// `FileSystemException` da captura traz o nome original do print e não é
/// exibida nem registrada em log por esta camada (RNF01, RNF07).
class AnalisarPrintPage extends StatefulWidget {
  const AnalisarPrintPage({
    super.key,
    required this.analisadorPrint,
    required this.captura,
    this.authRepository,
    this.historicoRepository,
    this.consentimentoRepository,
    this.tutorialRepository,
  });

  final AnalisadorPrint analisadorPrint;
  final CapturaImagem captura;

  /// Usado só para encerrar a sessão quando a Function não a reconhece
  /// ([MotivoInterrupcaoPrint.naoAutenticado]).
  final AuthRepository? authRepository;

  final HistoricoRepository? historicoRepository;
  final ConsentimentoRepository? consentimentoRepository;
  final TutorialRepository? tutorialRepository;

  @override
  State<AnalisarPrintPage> createState() => _AnalisarPrintPageState();
}

class _AnalisarPrintPageState extends State<AnalisarPrintPage> {
  // Resolvido só quando usado: criar o repositório real exige o Firebase
  // inicializado.
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final HistoricoRepository _historico =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late final ConsentimentoRepository _consentimento =
      widget.consentimentoRepository ?? ConsentimentoRepositoryLocal();
  late final TutorialRepository _tutorial =
      widget.tutorialRepository ?? TutorialRepositoryLocal();
  bool _carregando = false;
  EtapaAnalisePrint _etapa = EtapaAnalisePrint.lendoTexto;
  // A primeira etapa só é avisada depois que a imagem foi escolhida na
  // galeria; até lá, a demora não conta (ver `ProgressoAnalise`).
  bool _imagemEscolhida = false;
  MotivoInterrupcaoPrint? _interrupcao;

  @override
  void initState() {
    super.initState();
    // Tutorial de primeiro uso (RF13), antes da escolha do print. A tela de
    // consentimento continua aparecendo ao tocar em "Escolher print".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      abrirTutorialNaPrimeiraVez(
        context,
        tipo: TipoTutorial.print,
        repositorio: _tutorial,
        construir: (_) => const TutorialPrintPage(),
      );
    });
  }

  void _abrirTutorial() => abrirTutorial(
    context,
    tipo: TipoTutorial.print,
    repositorio: _tutorial,
    construir: (_) => const TutorialPrintPage(),
  );

  Future<void> _entrarDeNovo() async {
    try {
      await _authRepository.sair();
    } catch (_) {
      // Mesmo que o encerramento falhe, o login substitui a sessão atual.
    }
    if (!mounted) return;
    await Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _analisar() async {
    if (!await confirmarConsentimento(context, _consentimento)) return;
    if (!mounted) return;

    // Feedback de carregamento imediato após o acionamento (RNF03).
    setState(() {
      _carregando = true;
      _etapa = EtapaAnalisePrint.lendoTexto;
      _imagemEscolhida = false;
      _interrupcao = null;
    });

    ResultadoAnalisePrint resultado;
    try {
      resultado = await widget.analisadorPrint.analisarCaptura(
        widget.captura,
        aoAvancar: (etapa) {
          if (mounted) {
            setState(() {
              _etapa = etapa;
              _imagemEscolhida = true;
            });
          }
        },
      );
    } catch (_) {
      // O pipeline não lança por contrato; esta é só a rede de segurança
      // que impede uma exceção (e a mensagem dela) de chegar à tela ou ao
      // log de erros não tratados.
      resultado = const AnalisePrintInterrompida(
        MotivoInterrupcaoPrint.indisponivel,
      );
    }
    if (!mounted) return;

    switch (resultado) {
      case AnalisePrintCancelada():
        setState(() => _carregando = false);
      case AnalisePrintInterrompida(:final motivo):
        setState(() {
          _carregando = false;
          _interrupcao = motivo;
        });
      case AnalisePrintConcluida():
        setState(() => _carregando = false);
        registrarNoHistorico(
          mensageiro: ScaffoldMessenger.of(context),
          repositorio: _historico,
          analise: AnaliseRisco.doPrint(resultado),
        );
        await Navigator.of(context)
            .pushNamed(AppRoutes.resultado, arguments: resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interrupcao = _interrupcao;

    return TelaNoturna(
      titulo: 'Analisar print',
      icone: Icons.image_outlined,
      acoes: [
        IconButton(
          key: const Key('analisar_print_ajuda'),
          tooltip: 'Como funciona',
          icon: const Icon(Icons.help_outline),
          onPressed: _carregando ? null : _abrirTutorial,
        ),
      ],
      // Rolável: com letra ampliada (RF14), o texto empurra o botão para
      // baixo da tela.
      corpo: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CartaoDestaque(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolha na galeria o print da mensagem que você recebeu. '
                  'A imagem não sai do seu celular: o texto dela é lido aqui '
                  'mesmo e a imagem é descartada em seguida. Para a análise, '
                  'enviamos só o texto que aparece no print, e procuramos '
                  'esconder dados como CPF, telefone e cartão antes do envio.',
                ),
                if (interrupcao != null) ...[
                  const SizedBox(height: 16),
                  _AvisoInterrupcao(mensagem: interrupcao.mensagem),
                ],
                const SizedBox(height: 16),
                if (interrupcao == MotivoInterrupcaoPrint.naoAutenticado)
                  FilledButton.icon(
                    key: const Key('analisar_print_entrar_de_novo'),
                    style: estiloBotaoDegrade,
                    onPressed: _entrarDeNovo,
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar de novo'),
                  )
                else
                  FilledButton.icon(
                    key: const Key('analisar_print_botao'),
                    style: estiloBotaoDegrade,
                    onPressed: _carregando ? null : _analisar,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      interrupcao?.permiteNovaTentativa ?? false
                          // A imagem anterior já foi descartada: a nova
                          // tentativa exige escolher o print de novo.
                          ? 'Escolher o print de novo'
                          : 'Escolher print',
                    ),
                  ),
              ],
            ),
          ),
          if (_carregando) ...[
            const SizedBox(height: 20),
            CartaoSecao(
              filhos: [
                ProgressoAnalise(
                  key: const Key('analisar_print_carregando'),
                  etapa: _etapa,
                  contandoDemora: _imagemEscolhida,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AvisoInterrupcao extends StatelessWidget {
  const _AvisoInterrupcao({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('analisar_print_interrupcao'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(mensagem)),
          ],
        ),
      ),
    );
  }
}

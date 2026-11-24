import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../auth/data/firebase_auth_repository.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../data/consentimento_repository_local.dart';
import '../../data/historico_repository_firestore.dart';
import '../../domain/analisador_link.dart';
import '../../domain/analisador_print.dart';
import '../../domain/analise_risco.dart';
import '../../domain/caixa_compartilhamento.dart';
import '../../domain/consentimento_repository.dart';
import '../../domain/conteudo_compartilhado.dart';
import '../../domain/historico_repository.dart';
import '../../../../shared/domain/imagem_em_memoria.dart';
import '../../domain/resultado_analise_print.dart';
import '../registro_historico.dart';
import '../widgets/progresso_analise.dart';
import '../../../../shared/widgets/scaffold_phize.dart';
import 'consentimento_page.dart';

/// Análise do conteúdo recebido por compartilhamento (RF10 / UC11): começa
/// sozinha e vai direto ao resultado, sem passar pela galeria nem pelo campo
/// de link. Só a escolha entre imagem e link, quando vierem juntos, pede uma
/// ação do usuário.
class AnaliseCompartilhadaPage extends StatefulWidget {
  const AnaliseCompartilhadaPage({
    super.key,
    required this.caixa,
    required this.analisadorPrint,
    required this.analisadorLink,
    this.historicoRepository,
    this.authRepository,
    this.consentimentoRepository,
  });

  static const String mensagemSemConsentimento =
      'Para analisar um print, precisamos da sua concordância. A imagem foi '
      'descartada. Você pode compartilhar de novo quando quiser.';
  static const String mensagemTextoSemLink =
      'Só conseguimos analisar links por aqui, e não encontramos um único '
      'link neste texto. Para analisar uma mensagem, tire um print dela e '
      'compartilhe a imagem com o Phize.';
  static const String mensagemNaoSuportado =
      'Este formato não pode ser analisado. Compartilhe uma imagem ou um '
      'link.';
  static const String mensagemLinkInvalido =
      'Isso não parece ser um link. Confira o endereço e tente de novo.';
  static const String mensagemFalhaEscolha =
      'Não conseguimos concluir a análise. Tente compartilhar de novo.';

  final CaixaCompartilhamento caixa;
  final AnalisadorPrint analisadorPrint;
  final AnalisadorLink analisadorLink;
  final HistoricoRepository? historicoRepository;
  final AuthRepository? authRepository;
  final ConsentimentoRepository? consentimentoRepository;

  @override
  State<AnaliseCompartilhadaPage> createState() =>
      _AnaliseCompartilhadaPageState();
}

class _AnaliseCompartilhadaPageState extends State<AnaliseCompartilhadaPage> {
  // Resolvidos só quando usados: os repositórios reais exigem o Firebase
  // inicializado.
  late final HistoricoRepository _historico =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  late final ConsentimentoRepository _consentimento =
      widget.consentimentoRepository ?? ConsentimentoRepositoryLocal();

  ConteudoCompartilhado? _conteudo;
  ImagemELinkCompartilhados? _escolha;
  String? _mensagem;
  bool _pedirLogin = false;
  bool _carregando = false;
  EtapaAnalisePrint? _etapa;

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: a análise usa o contexto da tela, e retirar
    // da caixa avisa quem a observa, o que não pode ocorrer durante um build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  @override
  void dispose() {
    // Conteúdo que não chegou a ser analisado.
    _conteudo?.descartar();
    super.dispose();
  }

  void _iniciar() {
    if (!mounted) return;
    _conteudo = widget.caixa.retirar();
    switch (_conteudo) {
      case ImagemCompartilhada(:final imagem):
        _analisarImagem(imagem);
      case LinkCompartilhado(:final link):
        _analisarLink(link);
      case final ImagemELinkCompartilhados conteudo:
        setState(() => _escolha = conteudo);
      case TextoSemLink():
        setState(
          () => _mensagem = AnaliseCompartilhadaPage.mensagemTextoSemLink,
        );
      case ConteudoNaoSuportado() || null:
        setState(
          () => _mensagem = AnaliseCompartilhadaPage.mensagemNaoSuportado,
        );
    }
  }

  Future<void> _analisarImagem(ImagemEmMemoria imagem) async {
    setState(() => _escolha = null);
    final consentiu = await confirmarConsentimento(context, _consentimento);
    if (!mounted) {
      imagem.descartar();
      return;
    }
    if (!consentiu) {
      imagem.descartar();
      setState(
        () => _mensagem = AnaliseCompartilhadaPage.mensagemSemConsentimento,
      );
      return;
    }

    setState(() {
      _carregando = true;
      _etapa = EtapaAnalisePrint.lendoTexto;
    });
    ResultadoAnalisePrint resultado;
    try {
      resultado = await widget.analisadorPrint.analisarImagem(
        imagem,
        aoAvancar: (etapa) {
          if (mounted) setState(() => _etapa = etapa);
        },
      );
    } catch (_) {
      resultado = const AnalisePrintInterrompida(
        MotivoInterrupcaoPrint.indisponivel,
      );
    } finally {
      imagem.descartar();
    }
    if (!mounted) return;

    switch (resultado) {
      case AnalisePrintConcluida():
        registrarNoHistorico(
          mensageiro: ScaffoldMessenger.of(context),
          repositorio: _historico,
          analise: AnaliseRisco.doPrint(resultado),
        );
        await Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.resultado, arguments: resultado);
      case AnalisePrintInterrompida(:final motivo):
        setState(() {
          _carregando = false;
          _mensagem = motivo.mensagem;
          _pedirLogin = motivo == MotivoInterrupcaoPrint.naoAutenticado;
        });
      case AnalisePrintCancelada():
        setState(() {
          _carregando = false;
          _mensagem = AnaliseCompartilhadaPage.mensagemFalhaEscolha;
        });
    }
  }

  Future<void> _analisarLink(String link) async {
    _escolha?.imagem.descartar();
    setState(() {
      _escolha = null;
      _carregando = true;
    });
    final resultado = await widget.analisadorLink.analisar(link);
    if (!mounted) return;

    if (resultado == null) {
      setState(() {
        _carregando = false;
        _mensagem = AnaliseCompartilhadaPage.mensagemLinkInvalido;
      });
      return;
    }
    registrarNoHistorico(
      mensageiro: ScaffoldMessenger.of(context),
      repositorio: _historico,
      analise: AnaliseRisco.doLink(resultado, DateTime.now()),
    );
    await Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.resultado, arguments: resultado);
  }

  Future<void> _entrarDeNovo() async {
    final navegador = Navigator.of(context);
    try {
      await _auth.sair();
    } catch (_) {
      // Mesmo que o encerramento falhe, o login substitui a sessão atual.
    }
    await navegador.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _irAoInicio() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final escolha = _escolha;
    final mensagem = _mensagem;
    final etapa = _etapa;

    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Analisar conteúdo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_carregando && etapa != null)
                ProgressoAnalise(
                  key: const Key('compartilhado_carregando'),
                  etapa: etapa,
                )
              else if (_carregando) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Text(
                  'Analisando…',
                  key: Key('compartilhado_carregando'),
                  textAlign: TextAlign.center,
                ),
              ],
              if (escolha != null) ...[
                const Text(
                  'Você enviou uma imagem e um link. O que quer analisar?',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('compartilhado_escolher_imagem'),
                  style: estiloBotaoDegrade,
                  onPressed: () => _analisarImagem(escolha.imagem),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('A imagem'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('compartilhado_escolher_link'),
                  style: estiloBotaoDegrade,
                  onPressed: () => _analisarLink(escolha.link),
                  icon: const Icon(Icons.link),
                  label: const Text('O link'),
                ),
              ],
              if (mensagem != null) ...[
                Text(mensagem, key: const Key('compartilhado_mensagem')),
                const SizedBox(height: 16),
                if (_pedirLogin)
                  FilledButton(
                    key: const Key('compartilhado_entrar_de_novo'),
                    style: estiloBotaoDegrade,
                    onPressed: _entrarDeNovo,
                    child: const Text('Entrar de novo'),
                  )
                else
                  FilledButton(
                    key: const Key('compartilhado_inicio'),
                    style: estiloBotaoDegrade,
                    onPressed: _irAoInicio,
                    child: const Text('Ir para o início'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

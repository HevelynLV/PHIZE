import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/historico_repository_firestore.dart';
import '../../data/tutorial_repository_local.dart';
import '../../domain/analisador_link.dart';
import '../../domain/analise_risco.dart';
import '../../domain/historico_repository.dart';
import '../../domain/tutorial_repository.dart';
import '../registro_historico.dart';
import '../tutorial/tutorial_link.dart';
import '../tutorial/tutorial_page.dart';

/// Tela "Analisar Link" (UC03, passos 1 e 2): o usuário cola a URL e
/// aciona a verificação. O endereço fica apenas em memória, no campo de
/// texto, e é limpo assim que a análise termina — nunca é persistido
/// (UC03, pós-condições).
class AnalisarLinkPage extends StatefulWidget {
  const AnalisarLinkPage({
    super.key,
    required this.analisadorLink,
    this.historicoRepository,
    this.tutorialRepository,
  });

  final AnalisadorLink analisadorLink;
  final HistoricoRepository? historicoRepository;
  final TutorialRepository? tutorialRepository;

  @override
  State<AnalisarLinkPage> createState() => _AnalisarLinkPageState();
}

class _AnalisarLinkPageState extends State<AnalisarLinkPage> {
  static const _fundo = Color(0xFF050A24);
  static const _campo = Color(0xFF0E1233);
  static const _bordaCampo = Color(0xFF2B3A7A);
  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _ciano = Color(0xFF48CAE4);
  static const _textoSuave = Color(0xFFA3A9D6);
  static const _erroCor = Color(0xFFFF8A80);

  // Resolvido só quando usado: criar o repositório real exige o Firebase
  // inicializado.
  late final HistoricoRepository _historico =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late final TutorialRepository _tutorial =
      widget.tutorialRepository ?? TutorialRepositoryLocal();
  final _urlController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Tutorial de primeiro uso (RF13), depois que a tela aparece.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      abrirTutorialNaPrimeiraVez(
        context,
        tipo: TipoTutorial.link,
        repositorio: _tutorial,
        construir: (_) => const TutorialLinkPage(),
      );
    });
  }

  void _abrirTutorial() => abrirTutorial(
        context,
        tipo: TipoTutorial.link,
        repositorio: _tutorial,
        construir: (_) => const TutorialLinkPage(),
      );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Botão "Colar" (o mesmo da cena do tutorial): lê a área de
  /// transferência só quando a pessoa toca nele, e o texto vai para o campo,
  /// como se tivesse sido colado à mão. O balão de colar do Android é
  /// pequeno e fica no canto do campo (ensaio de 2026-11-16).
  Future<void> _colar() async {
    String? texto;
    try {
      texto = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    } catch (_) {
      texto = null;
    }
    if (!mounted) return;
    if (texto == null || texto.isEmpty) {
      setState(
        () => _erro =
            'Nenhum link copiado. Na conversa, toque e segure o link, '
            'escolha "Copiar" e volte aqui.',
      );
      return;
    }
    _urlController.text = texto;
    setState(() => _erro = null);
  }

  Future<void> _verificar() async {
    // Feedback de carregamento imediato após a submissão (RNF03).
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await widget.analisadorLink.analisar(_urlController.text);
    if (!mounted) return;

    if (resultado == null) {
      setState(() {
        _carregando = false;
        _erro =
            'Isso não parece ser um link. Confira o endereço e envie '
            'novamente (exemplo: site.com.br).';
      });
      return;
    }

    _urlController.clear();
    setState(() => _carregando = false);
    registrarNoHistorico(
      mensageiro: ScaffoldMessenger.of(context),
      repositorio: _historico,
      analise: AnaliseRisco.doLink(resultado, DateTime.now()),
    );
    await Navigator.of(context).pushNamed(
      AppRoutes.resultado,
      arguments: resultado,
    );
  }

  OutlineInputBorder _borda(Color cor, [double largura = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: cor, width: largura),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, color: _ciano, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Analisar link',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              key: const Key('analisar_link_ajuda'),
              tooltip: 'Como funciona',
              style: IconButton.styleFrom(
                backgroundColor: _campo.withValues(alpha: 0.85),
                side: const BorderSide(color: _bordaCampo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.help_outline, color: _ciano, size: 21),
              onPressed: _carregando ? null : _abrirTutorial,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _FundoAnalisarLinkPainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Painel principal com ícone de radar/inspeção de URL.
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF141C4E),
                              Color(0xFF0C1238),
                              Color(0xFF091B3A),
                            ],
                          ),
                          border: Border.all(
                            color:
                                const Color(0xFF3A4FA8).withValues(alpha: 0.75),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3A2BFF)
                                  .withValues(alpha: 0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _ciano.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _ciano.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.travel_explore_rounded,
                                    color: _ciano,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verificação de endereço',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Cole abaixo o link que você recebeu.',
                                        style: TextStyle(
                                          color: Color(0xFFC3C9F7),
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              key: const Key('analisar_link_url'),
                              controller: _urlController,
                              enabled: !_carregando,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              cursorColor: _ciano,
                              decoration: InputDecoration(
                                labelText: 'Link',
                                labelStyle: const TextStyle(
                                  color: _textoSuave,
                                  fontSize: 15,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: _ciano,
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: 'https://...',
                                hintStyle: TextStyle(
                                  color: _textoSuave.withValues(alpha: 0.6),
                                ),
                                filled: true,
                                fillColor: _campo,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 14, right: 10),
                                  child: Icon(
                                    Icons.language_rounded,
                                    color: _roxoClaro,
                                    size: 22,
                                  ),
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TextButton(
                                    key: const Key('analisar_link_colar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _ciano,
                                      backgroundColor:
                                          _ciano.withValues(alpha: 0.12),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: _carregando ? null : _colar,
                                    child: const Text('Colar'),
                                  ),
                                ),
                                errorText: _erro,
                                errorMaxLines: 3,
                                errorStyle: const TextStyle(
                                  color: _erroCor,
                                  fontSize: 13.5,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                enabledBorder: _borda(_bordaCampo),
                                focusedBorder: _borda(_ciano, 1.5),
                                errorBorder: _borda(_erroCor),
                                focusedErrorBorder: _borda(_erroCor, 1.5),
                                disabledBorder:
                                    _borda(_bordaCampo.withValues(alpha: 0.45)),
                                border: _borda(_bordaCampo),
                              ),
                              onSubmitted: (_) =>
                                  _carregando ? null : _verificar(),
                            ),
                            const SizedBox(height: 18),
                            Opacity(
                              opacity: _carregando ? 0.65 : 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF3F8CFF),
                                      Color(0xFF3A2BFF),
                                      Color(0xFF8B5CFF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4C6EF5)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 22,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  key: const Key('analisar_link_botao'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(58),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: _carregando ? null : _verificar,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_outlined,
                                          size: 22),
                                      SizedBox(width: 10),
                                      Flexible(child: Text('Verificar link')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_carregando) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _campo,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _ciano.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Column(
                            children: [
                              CircularProgressIndicator(color: _ciano),
                              SizedBox(height: 14),
                              Text(
                                'Analisando o link…',
                                key: Key('analisar_link_carregando'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        // Cartão informativo sobre o que é verificado no link.
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _campo.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _bordaCampo.withValues(alpha: 0.7),
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.radar_rounded,
                                    color: _roxoClaro,
                                    size: 19,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'O que verificamos para você',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              _ItemVerificacao(
                                texto:
                                    'Domínios recém-criados ou imitando marcas conhecidas',
                              ),
                              SizedBox(height: 6),
                              _ItemVerificacao(
                                texto:
                                    'Endereços apontados como possivelmente perigosos pelo '
                                    'Google Safe Browsing',
                              ),
                              SizedBox(height: 6),
                              _ItemVerificacao(
                                texto:
                                    'O endereço é descartado assim que a análise termina',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemVerificacao extends StatelessWidget {
  const _ItemVerificacao({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF48CAE4),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFFA3A9D6),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fundo azul-marinho com ondas nos cantos, arcos de radar e estrelas.
class _FundoAnalisarLinkPainter extends CustomPainter {
  const _FundoAnalisarLinkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    canvas.drawRect(todo, Paint()..color = const Color(0xFF050A24));

    // Onda superior direita em ciano/azul.
    final topo = Path()
      ..moveTo(w, 0)
      ..lineTo(0.55 * w, 0)
      ..cubicTo(0.60 * w, 0.05 * h, 0.78 * w, 0.09 * h, w, 0.13 * h)
      ..close();
    canvas.drawPath(
      topo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0096C7), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0.55 * w, 0, 0.45 * w, 0.13 * h)),
    );

    // Onda inferior esquerda em azul-índigo.
    final base = Path()
      ..moveTo(0, h)
      ..lineTo(0.45 * w, h)
      ..cubicTo(0.40 * w, 0.92 * h, 0.20 * w, 0.87 * h, 0, 0.86 * h)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF3D4DFF), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0, 0.86 * h, 0.45 * w, 0.14 * h)),
    );

    // Arcos finos remetendo a varredura/radar.
    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(0.95 * w, -0.02 * h), 0.56 * w, arco);
    canvas.drawCircle(Offset(-0.05 * w, 1.02 * h), 0.56 * w, arco);

    // Estrelinhas nos cantos.
    final brilhoCiano = Paint()..color = const Color(0xFF48CAE4);
    final brilhoRoxo = Paint()..color = const Color(0xFF8FA0FF);
    _estrela(canvas, Offset(0.14 * w, 0.08 * h), 0.020 * w, brilhoCiano);
    _estrela(canvas, Offset(0.86 * w, 0.90 * h), 0.022 * w, brilhoRoxo);
  }

  void _estrela(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}
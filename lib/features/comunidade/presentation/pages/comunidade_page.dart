import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../data/feed_repository_firestore.dart';
import '../../data/moderacao_repository_firestore.dart';
import '../../domain/feed_repository.dart';
import '../../domain/moderacao_repository.dart';
import '../../domain/reporte_comunidade.dart';
import '../widgets/cartao_reporte.dart';

/// Aba "Comunidade" (RF08, UC07): reportes de outras pessoas, "Em alta" ou
/// "Mais recentes". Reportes ocultos pela moderação não aparecem (RF11).
class ComunidadePage extends StatefulWidget {
  const ComunidadePage({super.key, this.repositorio, this.moderacao});

  final FeedRepository? repositorio;
  final ModeracaoRepository? moderacao;

  static const String avisoFeed =
      'Relatos enviados por pessoas do Phize, sem nome. Nem todos foram '
      'revisados pela equipe.';

  @override
  State<ComunidadePage> createState() => _ComunidadePageState();
}

class _ComunidadePageState extends State<ComunidadePage> {
  static const _fundo = Color(0xFF050A24);
  static const _campo = Color(0xFF0E1233);
  static const _bordaCampo = Color(0xFF2B3A7A);
  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _ciano = Color(0xFF48CAE4);
  static const _textoSuave = Color(0xFFA3A9D6);

  // Resolvido só quando usado: o repositório real exige o Firebase
  // inicializado.
  late final FeedRepository _repositorio =
      widget.repositorio ?? FeedRepositoryFirestore();
  OrdemFeed _ordem = OrdemFeed.emAlta;
  late Future<List<ReporteComunidade>> _reportes = _repositorio.listar(_ordem);

  /// A entrada da moderação só aparece para contas da lista `moderadores`
  /// (RF11). Esconder o botão é conveniência; o acesso é barrado pelas
  /// regras do Firestore.
  bool _moderador = false;

  @override
  void initState() {
    super.initState();
    _conferirModeracao();
  }

  Future<void> _conferirModeracao() async {
    bool moderador;
    try {
      final moderacao = widget.moderacao ?? ModeracaoRepositoryFirestore();
      moderador = await moderacao.ehModerador();
    } catch (_) {
      moderador = false;
    }
    if (mounted && moderador) setState(() => _moderador = true);
  }

  Future<void> _abrirMeusReportes() async {
    await Navigator.of(context).pushNamed(AppRoutes.meusReportes);
    // Edição ou exclusão muda o feed.
    if (mounted) _recarregar();
  }

  Future<void> _abrirModeracao() async {
    await Navigator.of(context).pushNamed(AppRoutes.moderacao);
    if (mounted) _recarregar();
  }

  void _recarregar() {
    setState(() {
      _reportes = _repositorio.listar(_ordem);
    });
  }

  void _mudarOrdem(OrdemFeed ordem) {
    if (ordem == _ordem) return;
    _ordem = ordem;
    _recarregar();
  }

  Future<void> _abrir(ReporteComunidade reporte) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.detalheReporte, arguments: reporte);
    // A curtida dada no detalhe muda a contagem e, em "Em alta", a ordem.
    if (mounted) _recarregar();
  }

  Future<void> _reportar() async {
    await Navigator.of(context).pushNamed(AppRoutes.reportarGolpe);
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    // Com letra grande sobra pouco espaço: o botão sai de cima do conteúdo e
    // fica fixo acima do menu.
    final letraGrande = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final botaoReportar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
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
            color: const Color(0xFF4C6EF5).withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        key: const Key('comunidade_reportar'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        onPressed: _reportar,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text(
          'Reportar golpe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _fundo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2666).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ciano.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: _ciano,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Comunidade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          _BotaoAcaoAppBar(
            key: const Key('comunidade_pesquisar'),
            tooltip: 'Pesquisar',
            icone: Icons.search_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.pesquisaComunidade),
          ),
          _BotaoAcaoAppBar(
            key: const Key('comunidade_meus_reportes'),
            tooltip: 'Meus reportes',
            icone: Icons.article_outlined,
            onPressed: _abrirMeusReportes,
          ),
          if (_moderador)
            _BotaoAcaoAppBar(
              key: const Key('comunidade_moderacao'),
              tooltip: 'Moderação',
              icone: Icons.shield_outlined,
              corIcone: _ciano,
              onPressed: _abrirModeracao,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _FundoComunidadePainter(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, limites) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho de rede colaborativa. Com letra grande em
                      // tela baixa ele rola, para sobrar espaço para o feed.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: limites.maxHeight * 0.7,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
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
                                    const Color(0xFF3A4FA8).withValues(alpha: 0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3A2BFF)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const _AvataresRede(),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Rede de alerta coletivo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            ComunidadePage.avisoFeed,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFFC3C9F7),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<OrdemFeed>(
                                    key: const Key('comunidade_ordem'),
                                    style: SegmentedButton.styleFrom(
                                      backgroundColor:
                                          _fundo.withValues(alpha: 0.65),
                                      foregroundColor: _textoSuave,
                                      selectedBackgroundColor:
                                          _roxoClaro.withValues(alpha: 0.22),
                                      selectedForegroundColor: Colors.white,
                                      side: const BorderSide(color: _bordaCampo),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    segments: [
                                      for (final ordem in OrdemFeed.values)
                                        ButtonSegment(
                                          value: ordem,
                                          icon: Icon(
                                            ordem == OrdemFeed.emAlta
                                                ? Icons.local_fire_department_rounded
                                                : Icons.schedule_rounded,
                                            size: 18,
                                            color: _ordem == ordem
                                                ? _ciano
                                                : _textoSuave,
                                          ),
                                          label: Text(ordem.nome),
                                        ),
                                    ],
                                    selected: {_ordem},
                                    showSelectedIcon: false,
                                    onSelectionChanged: (escolha) =>
                                        _mudarOrdem(escolha.single),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            brightness: Brightness.dark,
                            cardColor: _campo,
                          ),
                          child: FutureBuilder<List<ReporteComunidade>>(
                            future: _reportes,
                            builder: (context, carga) {
                              if (carga.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: _ciano,
                                  ),
                                );
                              }
                              final reportes = carga.data;
                              if (carga.hasError || reportes == null) {
                                return _FalhaCarga(aoTentarDeNovo: _recarregar);
                              }
                              if (reportes.isEmpty) {
                                return const _FeedVazio();
                              }
                              return RefreshIndicator(
                                color: _ciano,
                                backgroundColor: _campo,
                                onRefresh: () async {
                                  _recarregar();
                                  await _reportes
                                      .catchError((_) => <ReporteComunidade>[]);
                                },
                                child: ListView.separated(
                                  key: const Key('comunidade_lista'),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 104),
                                  itemCount: reportes.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) => CartaoReporte(
                                    reporte: reportes[i],
                                    aoTocar: () => _abrir(reportes[i]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: letraGrande ? null : botaoReportar,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (letraGrande)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: botaoReportar,
            ),
          const PhizeBottomNav(currentIndex: 1),
        ],
      ),
    );
  }
}

class _BotaoAcaoAppBar extends StatelessWidget {
  const _BotaoAcaoAppBar({
    super.key,
    required this.tooltip,
    required this.icone,
    required this.onPressed,
    this.corIcone = Colors.white,
  });

  final String tooltip;
  final IconData icone;
  final VoidCallback onPressed;
  final Color corIcone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF0E1233).withValues(alpha: 0.8),
          side: const BorderSide(color: Color(0xFF2B3A7A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icone, color: corIcone, size: 20),
      ),
    );
  }
}

/// Avatares sobrepostos simbolizando pessoas protegendo umas às outras.
class _AvataresRede extends StatelessWidget {
  const _AvataresRede();

  @override
  Widget build(BuildContext context) {
    const perfis = [
      (Icons.person_outline, Color(0xFF48CAE4), Color(0xFF0B2E46)),
      (Icons.shield_outlined, Color(0xFF8FA0FF), Color(0xFF1A225C)),
      (Icons.verified_user_outlined, Color(0xFFA99BFF), Color(0xFF2A1E5C)),
    ];

    return ExcludeSemantics(
      child: SizedBox(
        width: 74,
        height: 36,
        child: Stack(
          children: [
            for (var i = 0; i < perfis.length; i++)
              Positioned(
                left: i * 19.0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: perfis[i].$3,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0C1238),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    perfis[i].$1,
                    size: 17,
                    color: perfis[i].$2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedVazio extends StatelessWidget {
  const _FeedVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Embaixo, espaço para o botão "Reportar golpe".
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 104),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1233),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2B3A7A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF48CAE4).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  size: 38,
                  color: Color(0xFF48CAE4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ainda não há reportes na comunidade.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Recebeu um golpe? Avise outras pessoas e ajude a rede.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA3A9D6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FalhaCarga extends StatelessWidget {
  const _FalhaCarga({required this.aoTentarDeNovo});

  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Embaixo, espaço para o botão "Reportar golpe".
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 104),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1233),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF8A80).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: Color(0xFFFF8A80),
              ),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar a comunidade. Verifique sua conexão.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const Key('comunidade_tentar_de_novo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF48CAE4),
                  side: const BorderSide(color: Color(0xFF48CAE4)),
                  shape: const StadiumBorder(),
                ),
                onPressed: aoTentarDeNovo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fundo azul-marinho com constelação/rede de nós interligados simbolizando
/// a comunidade conectada, mantendo as formas suaves nos cantos.
class _FundoComunidadePainter extends CustomPainter {
  const _FundoComunidadePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    canvas.drawRect(todo, Paint()..color = const Color(0xFF050A24));

    // Onda suave no canto superior esquerdo.
    final topo = Path()
      ..moveTo(0, 0)
      ..lineTo(0.46 * w, 0)
      ..cubicTo(0.42 * w, 0.06 * h, 0.24 * w, 0.11 * h, 0, 0.15 * h)
      ..close();
    canvas.drawPath(
      topo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3D4DFF), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0, 0, 0.46 * w, 0.15 * h)),
    );

    // Onda suave no canto inferior direito.
    final base = Path()
      ..moveTo(w, h)
      ..lineTo(0.45 * w, h)
      ..cubicTo(0.49 * w, 0.91 * h, 0.75 * w, 0.85 * h, w, 0.84 * h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0xFF0096C7), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0.45 * w, 0.84 * h, 0.55 * w, 0.16 * h)),
    );

    // Rede de conexões entre nós (remetendo à comunidade).
    final linhaRede = Paint()
      ..color = const Color(0xFF48CAE4).withValues(alpha: 0.16)
      ..strokeWidth = 1.1;

    final p1 = Offset(0.14 * w, 0.18 * h);
    final p2 = Offset(0.32 * w, 0.11 * h);
    final p3 = Offset(0.86 * w, 0.14 * h);
    final p4 = Offset(0.76 * w, 0.24 * h);
    final p5 = Offset(0.16 * w, 0.86 * h);
    final p6 = Offset(0.30 * w, 0.92 * h);

    canvas.drawLine(p1, p2, linhaRede);
    canvas.drawLine(p3, p4, linhaRede);
    canvas.drawLine(p5, p6, linhaRede);

    final noCiano = Paint()
      ..color = const Color(0xFF48CAE4).withValues(alpha: 0.55);
    final noRoxo = Paint()
      ..color = const Color(0xFF8FA0FF).withValues(alpha: 0.55);

    canvas.drawCircle(p1, 3.2, noCiano);
    canvas.drawCircle(p2, 2.4, noRoxo);
    canvas.drawCircle(p3, 3.5, noRoxo);
    canvas.drawCircle(p4, 2.5, noCiano);
    canvas.drawCircle(p5, 3.2, noCiano);
    canvas.drawCircle(p6, 2.4, noRoxo);
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}
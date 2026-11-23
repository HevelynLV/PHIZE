import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../data/historico_repository_firestore.dart';
import '../../domain/analise_risco.dart';
import '../../domain/faixa_risco.dart';
import '../../domain/historico_repository.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/aviso_card.dart';

String nomeTipoEntrada(TipoEntrada tipo) => switch (tipo) {
  TipoEntrada.link => 'Link',
  TipoEntrada.imagem => 'Print',
};

/// Histórico de análises (UC06): lista cronológica apenas com o resultado de
/// cada análise, nunca o conteúdo original (RNF01, RNF07).
class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key, this.historicoRepository});

  final HistoricoRepository? historicoRepository;

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  static const _fundo = Color(0xFF050A24);
  static const _ciano = Color(0xFF48CAE4);

  // Resolvido só quando usado: criar o repositório real exige o Firebase
  // inicializado.
  late final HistoricoRepository _repositorio =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late Future<List<AnaliseRisco>> _analises = _repositorio.listar();

  void _tentarDeNovo() {
    setState(() {
      _analises = _repositorio.listar();
    });
  }

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
                Icons.history_rounded,
                color: _ciano,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Histórico de Análises',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _FundoHistoricoPainter(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: FutureBuilder<List<AnaliseRisco>>(
                  future: _analises,
                  builder: (context, carga) {
                    if (carga.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: _ciano),
                      );
                    }
                    final analises = carga.data;
                    if (carga.hasError || analises == null) {
                      return _FalhaCarga(aoTentarDeNovo: _tentarDeNovo);
                    }
                    if (analises.isEmpty) return const _HistoricoVazio();
                    return _ListaAnalises(analises: analises);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 2),
    );
  }
}

class _ListaAnalises extends StatelessWidget {
  const _ListaAnalises({required this.analises});

  final List<AnaliseRisco> analises;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: analises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == analises.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.dark,
              ),
              child: const AvisoCard(
                key: Key('historico_aviso_permanente'),
                texto: RotulosRisco.avisoPermanente,
              ),
            ),
          );
        }
        final analise = analises[index];
        final corFaixa = analise.faixa.corTexto;
        final ehLink = analise.tipoEntrada == TipoEntrada.link;

        return Material(
          color: const Color(0xFF0E1233),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: const Color(0xFF2B3A7A).withValues(alpha: 0.75),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.detalheHistorico, arguments: analise),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Medalha com o score da análise e brilho sutil na cor do risco.
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: corFaixa.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: corFaixa.withValues(alpha: 0.75),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${analise.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analise.faixa.rotulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              ehLink
                                  ? Icons.link_rounded
                                  : Icons.image_outlined,
                              size: 15,
                              color: const Color(0xFF8FA0FF),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${nomeTipoEntrada(analise.tipoEntrada)} · '
                                '${formatarData(analise.data)}',
                                style: const TextStyle(
                                  color: Color(0xFFA3A9D6),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA3A9D6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoricoVazio extends StatelessWidget {
  const _HistoricoVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1233),
            borderRadius: BorderRadius.circular(26),
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
                  Icons.history_rounded,
                  size: 40,
                  color: Color(0xFF48CAE4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não fez nenhuma análise. Quando receber uma '
                'mensagem ou link suspeito, analise aqui no Phize e o resultado '
                'aparece nesta tela.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC3C9F7),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
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
                      color: const Color(0xFF4C6EF5).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.dashboard),
                  child: const Text('Fazer minha primeira análise'),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                'Não foi possível carregar seu histórico. Verifique sua '
                'conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.5),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF48CAE4),
                  side: const BorderSide(color: Color(0xFF48CAE4)),
                  shape: const StadiumBorder(),
                ),
                onPressed: aoTentarDeNovo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fundo azul-marinho com ondas nos cantos, anéis de linha do tempo e estrelas.
class _FundoHistoricoPainter extends CustomPainter {
  const _FundoHistoricoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    canvas.drawRect(todo, Paint()..color = const Color(0xFF050A24));

    // Onda suave no canto superior direito.
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
          colors: [Color(0xFF3D4DFF), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0.55 * w, 0, 0.45 * w, 0.13 * h)),
    );

    // Onda suave no canto inferior esquerdo.
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
          colors: [Color(0xFF0096C7), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0, 0.86 * h, 0.45 * w, 0.14 * h)),
    );

    // Arcos finos decorativos.
    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(0.95 * w, -0.02 * h), 0.56 * w, arco);
    canvas.drawCircle(Offset(-0.05 * w, 1.02 * h), 0.56 * w, arco);

    // Estrelinhas nos cantos.
    final brilhoCiano = Paint()..color = const Color(0xFF48CAE4);
    final brilhoRoxo = Paint()..color = const Color(0xFF8FA0FF);
    _estrela(canvas, Offset(0.14 * w, 0.08 * h), 0.019 * w, brilhoCiano);
    _estrela(canvas, Offset(0.86 * w, 0.90 * h), 0.021 * w, brilhoRoxo);
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/marca_phize.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../domain/golpe_da_semana.dart';
import '../widgets/cartao_golpe_da_semana.dart';

/// Tela inicial: uma pergunta e duas ações, analisar print ou link (RF03,
/// RF04). O print vem primeiro por ser o caso mais comum. Abaixo, o passo a
/// passo, o aviso de privacidade e o cartão "Golpe da semana" (RF17).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.golpeDaSemanaRepository, this.agora});

  final GolpeDaSemanaRepository? golpeDaSemanaRepository;

  /// Relógio do rodízio semanal, para os testes.
  final DateTime Function()? agora;

  static const _fundo = Color(0xFF050A24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const MarcaPhize(tamanho: 32),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _FundoDashboardPainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CartaoPrincipal(),
                      const SizedBox(height: 28),
                      const _ComoFunciona(),
                      const SizedBox(height: 18),
                      const _SeloPrivacidade(),
                      const SizedBox(height: 28),
                      Theme(
                        data: Theme.of(context).copyWith(
                          brightness: Brightness.dark,
                        ),
                        child: CartaoGolpeDaSemana(
                          repositorio: golpeDaSemanaRepository,
                          agora: agora,
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
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 0),
    );
  }
}

/// Cartão hero escuro/azul-marinho com borda luminosa, degradê e as duas ações.
class _CartaoPrincipal extends StatelessWidget {
  const _CartaoPrincipal();

  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _ciano = Color(0xFF48CAE4);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
          color: const Color(0xFF3A4FA8).withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2BFF).withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(-6, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Brilhos suaves de fundo dentro do cartão.
            Positioned(
              right: -45,
              top: -45,
              child: _BrilhoCircular(
                diametro: 180,
                cor: const Color(0xFF4B4BFF).withValues(alpha: 0.24),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -55,
              child: _BrilhoCircular(
                diametro: 150,
                cor: const Color(0xFF00B4D8).withValues(alpha: 0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2666).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _ciano.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: _ciano,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Proteção contra golpes',
                            style: TextStyle(
                              color: Color(0xFFE0E6FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recebeu algo estranho?',
                    style: tema.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veja se é golpe antes de responder.',
                    style: tema.bodyLarge?.copyWith(
                      color: const Color(0xFFC3C9F7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botão principal com degradê vibrante (mesma assinatura do Login).
                  Opacity(
                    opacity: kIsWeb ? 0.5 : 1,
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
                            color:
                                const Color(0xFF4C6EF5).withValues(alpha: 0.45),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        key: const Key('dashboard_analisar_print'),
                        style: FilledButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.85),
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: kIsWeb
                            ? null
                            : () => Navigator.of(context)
                                .pushNamed(AppRoutes.analisarPrint),
                        icon: const Icon(Icons.image_outlined, size: 24),
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Analisar print'),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (kIsWeb)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 6),
                      child: Text(
                        'Disponível apenas em dispositivos móveis (Android/iOS).',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA3A9D6),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Botão secundário estilo glass/contorno luminoso.
                  OutlinedButton.icon(
                    key: const Key('dashboard_analisar_link'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor:
                          const Color(0xFF0E143B).withValues(alpha: 0.65),
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFF3B4FA8),
                        width: 1.2,
                      ),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.analisarLink),
                    icon: const Icon(Icons.link, color: _roxoClaro, size: 24),
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Analisar link'),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Color(0xFFA3A9D6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrilhoCircular extends StatelessWidget {
  const _BrilhoCircular({required this.diametro, required this.cor});

  final double diametro;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [cor, cor.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Três passos curtos que explicam o que o app faz.
class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF48CAE4), Color(0xFF8B5CFF)],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Como funciona',
              style: tema.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _Passo(
          numero: 1,
          icone: Icons.ios_share,
          corDestaque: Color(0xFF48CAE4),
          titulo: 'Envie o que recebeu',
          texto: 'Compartilhe o print ou o link direto do WhatsApp, SMS ou '
              'e-mail.',
        ),
        const SizedBox(height: 12),
        const _Passo(
          numero: 2,
          icone: Icons.speed,
          corDestaque: Color(0xFF8FA0FF),
          titulo: 'Veja o nível de risco',
          texto: 'Um medidor de verde a vermelho mostra o quanto desconfiar.',
        ),
        const SizedBox(height: 12),
        const _Passo(
          numero: 3,
          icone: Icons.school_outlined,
          corDestaque: Color(0xFFA99BFF),
          titulo: 'Entenda o porquê',
          texto: 'Explicamos os sinais do golpe para você reconhecer da '
              'próxima vez.',
        ),
      ],
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({
    required this.numero,
    required this.icone,
    required this.corDestaque,
    required this.titulo,
    required this.texto,
  });

  final int numero;
  final IconData icone;
  final Color corDestaque;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1233),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2B3A7A).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: corDestaque.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: corDestaque.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(icone, color: corDestaque, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero. $titulo',
                  style: tema.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: tema.bodySmall?.copyWith(
                    color: const Color(0xFFA3A9D6),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reforço de confiança: o print é lido no próprio celular (RNF01).
class _SeloPrivacidade extends StatelessWidget {
  const _SeloPrivacidade();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF09172E),
        border: Border.all(
          color: const Color(0xFF0096C7).withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFF48CAE4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seu print é lido no próprio celular e descartado logo depois. '
              'Nada da conversa fica guardado.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFC3C9F7),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundo sutil seguindo a identidade do app: fundo azul-marinho com formas
/// discretas, arcos finos e estrelinhas sem poluir a leitura dos cartões.
class _FundoDashboardPainter extends CustomPainter {
  const _FundoDashboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    // Forma suave no canto superior direito.
    final topo = Path()
      ..moveTo(w, 0)
      ..lineTo(0.55 * w, 0)
      ..cubicTo(0.60 * w, 0.05 * h, 0.78 * w, 0.08 * h, w, 0.12 * h)
      ..close();
    canvas.drawPath(
      topo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D4DFF), Color(0xFF050A24)],
        ).createShader(todo),
    );

    // Forma suave no canto inferior esquerdo.
    final base = Path()
      ..moveTo(0, h)
      ..lineTo(0.45 * w, h)
      ..cubicTo(0.40 * w, 0.93 * h, 0.20 * w, 0.88 * h, 0, 0.87 * h)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF0096C7), Color(0xFF050A24)],
        ).createShader(todo),
    );

    // Arcos finos decorativos.
    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(0.95 * w, -0.02 * h), 0.55 * w, arco);
    canvas.drawCircle(Offset(-0.05 * w, 1.02 * h), 0.55 * w, arco);

    // Estrelinhas discretas nos cantos superiores.
    final brilhoRoxo = Paint()
      ..color = const Color(0xFF5B8DFF).withValues(alpha: 0.75);
    final brilhoCiano = Paint()
      ..color = const Color(0xFF48CAE4).withValues(alpha: 0.75);
    _estrela(canvas, Offset(0.12 * w, 0.07 * h), 0.018 * w, brilhoCiano);
    _estrela(canvas, Offset(0.88 * w, 0.08 * h), 0.022 * w, brilhoRoxo);
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
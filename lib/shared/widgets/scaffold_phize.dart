import 'package:flutter/material.dart';

/// [Scaffold] sobre o fundo azul-marinho do Phize, com ondas nos cantos e
/// arcos finos. Usado pelas telas de todas as áreas do app.
class ScaffoldPhize extends StatelessWidget {
  const ScaffoldPhize({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _FundoPhizePainter(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// Estilo do botão principal: degradê azul e violeta, como nas telas de
/// entrada e no início.
final ButtonStyle estiloBotaoDegrade = FilledButton.styleFrom(
  backgroundColor: Colors.transparent,
  disabledBackgroundColor: Colors.transparent,
  foregroundColor: Colors.white,
  disabledForegroundColor: Colors.white70,
  shadowColor: Colors.transparent,
  minimumSize: const Size.fromHeight(58),
  shape: const StadiumBorder(),
  textStyle: const TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
  ),
).copyWith(
  backgroundBuilder: (context, estados, filho) => DecoratedBox(
    decoration: ShapeDecoration(
      shape: const StadiumBorder(),
      gradient: LinearGradient(
        colors: [
          for (final cor in const [
            Color(0xFF3F8CFF),
            Color(0xFF3A2BFF),
            Color(0xFF8B5CFF),
          ])
            estados.contains(WidgetState.disabled)
                ? cor.withValues(alpha: 0.55)
                : cor,
        ],
      ),
    ),
    child: filho,
  ),
);

class _FundoPhizePainter extends CustomPainter {
  const _FundoPhizePainter();

  static const Color _fundo = Color(0xFF050A24);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _fundo);

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
          colors: [Color(0xFF4B4BFF), _fundo],
        ).createShader(Rect.fromLTWH(0.55 * w, 0, 0.45 * w, 0.13 * h)),
    );

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
          // Escura o bastante para o texto que rola por cima (4,5:1).
          colors: [Color(0xFF003A58), _fundo],
        ).createShader(Rect.fromLTWH(0, 0.86 * h, 0.45 * w, 0.14 * h)),
    );

    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(0.95 * w, -0.02 * h), 0.56 * w, arco);
    canvas.drawCircle(Offset(-0.05 * w, 1.02 * h), 0.56 * w, arco);
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}

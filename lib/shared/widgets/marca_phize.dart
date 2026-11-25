import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Símbolo do Phize: escudo azul em duas faces com uma lupa branca.
/// Desenhado em código, então não precisa de arquivo de imagem e fica nítido
/// em qualquer tamanho.
class LogoPhize extends StatelessWidget {
  const LogoPhize({super.key, this.tamanho = 40});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: CustomPaint(painter: _LogoPhizePainter()),
      ),
    );
  }
}

class _LogoPhizePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    final escudo = Path()
      ..moveTo(0.5 * w, 0.02 * h)
      ..lineTo(0.9 * w, 0.16 * h)
      ..lineTo(0.9 * w, 0.5 * h)
      ..cubicTo(0.9 * w, 0.76 * h, 0.7 * w, 0.92 * h, 0.5 * w, 0.99 * h)
      ..cubicTo(0.3 * w, 0.92 * h, 0.1 * w, 0.76 * h, 0.1 * w, 0.5 * h)
      ..lineTo(0.1 * w, 0.16 * h)
      ..close();

    canvas.save();
    canvas.clipPath(escudo);
    // Face esquerda (mais clara) e face direita (mais escura).
    canvas.drawRect(
      Rect.fromLTRB(0, 0, 0.5 * w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C9BFF), Color(0xFF1F6BFF)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawRect(
      Rect.fromLTRB(0.5 * w, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A62E8), Color(0xFF1536B8)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.restore();

    // Lupa.
    final traco = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.085 * w
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(p(0.46, 0.42), 0.18 * w, traco);
    canvas.drawLine(p(0.59, 0.55), p(0.71, 0.67), traco);
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}

/// Marca completa: símbolo + nome "phize", com o pingo do "i" em destaque.
/// [tamanho] é o tamanho da letra; o símbolo acompanha. [cor] muda a cor do
/// nome (por padrão, a cor de texto do tema).
class MarcaPhize extends StatelessWidget {
  const MarcaPhize({
    super.key,
    this.tamanho = 22,
    this.soSimbolo = false,
    this.cor,
  });

  final double tamanho;

  /// Mostra só o escudo, sem o nome.
  final bool soSimbolo;

  final Color? cor;

  static const Color _corPingo = Color(0xFF6C7BFF);

  @override
  Widget build(BuildContext context) {
    final simbolo = LogoPhize(tamanho: tamanho * 1.5);
    if (soSimbolo) return simbolo;

    final estilo = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: tamanho,
      fontWeight: FontWeight.w800,
      color: cor ?? context.cores.tinta,
    );

    // O nome é parte da marca: não cresce com a fonte grande do sistema.
    return Semantics(
      label: 'phize',
      child: ExcludeSemantics(
        // Em tela estreita, a marca diminui em vez de estourar.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              simbolo,
              SizedBox(width: tamanho * 0.4),
              Text('ph', style: estilo, textScaler: TextScaler.noScaling),
              // "ı" sem pingo + pingo desenhado à parte, na cor da marca.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text('ı', style: estilo, textScaler: TextScaler.noScaling),
                  Positioned(
                    left: tamanho * 0.119 - tamanho * 0.085,
                    top: tamanho * 0.368 - tamanho * 0.085,
                    child: Container(
                      width: tamanho * 0.17,
                      height: tamanho * 0.17,
                      decoration: const BoxDecoration(
                        color: _corPingo,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              Text('ze', style: estilo, textScaler: TextScaler.noScaling),
            ],
          ),
        ),
      ),
    );
  }
}
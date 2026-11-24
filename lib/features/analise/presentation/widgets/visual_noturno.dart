import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Moldura das telas de análise: fundo ilustrado, barra com ícone e corpo
/// rolável. Não altera textos nem regras das telas.
class TelaNoturna extends StatelessWidget {
  const TelaNoturna({
    super.key,
    required this.titulo,
    required this.icone,
    required this.corpo,
    this.acoes,
    this.rodape,
  });

  final String titulo;
  final IconData icone;

  /// Construído já dentro do tema noturno.
  final WidgetBuilder corpo;
  final WidgetBuilder? rodape;
  final List<Widget>? acoes;

  static const Color ciano = Color(0xFF48CAE4);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.noturno,
      child: Builder(
        builder: (context) => ScaffoldPhize(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, color: ciano, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(titulo),
                  ),
                ),
              ],
            ),
            actions: acoes,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: corpo(context),
                ),
              ),
            ),
          ),
          bottomNavigationBar: rodape?.call(context),
        ),
      ),
    );
  }
}

/// Cartão de destaque, com degradê e borda luminosa.
class CartaoDestaque extends StatelessWidget {
  const CartaoDestaque({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141C4E), Color(0xFF0C1238), Color(0xFF091B3A)],
        ),
        border: Border.all(
          color: const Color(0xFF3A4FA8).withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2BFF).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Cartão discreto, para os detalhes.
class CartaoSecao extends StatelessWidget {
  const CartaoSecao({super.key, required this.filhos});

  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    // Material, e não Container: os ListTile pintam o toque sobre ele.
    return Material(
      color: cores.superficie.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: cores.borda.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: filhos,
        ),
      ),
    );
  }
}

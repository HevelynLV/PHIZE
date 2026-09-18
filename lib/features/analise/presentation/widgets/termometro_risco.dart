import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';

/// Termômetro de Risco Visual (RF07): representação semafórica do Score de
/// Risco, recebida como parâmetro — não decide faixa nem calcula score.
class TermometroRisco extends StatelessWidget {
  const TermometroRisco({
    super.key,
    required this.score,
    required this.faixa,
  });

  final int score;
  final FaixaRisco faixa;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: faixa.cor,
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Score de Risco: $score/100',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          faixa.rotulo,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: faixa.cor,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

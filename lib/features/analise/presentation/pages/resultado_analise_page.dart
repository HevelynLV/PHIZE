import 'package:flutter/material.dart';

import '../../domain/analise_risco.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/termometro_risco.dart';

/// Tela de Resultado da Análise (RF07).
///
/// Renderiza inteiramente a partir do [analise] recebido — faixa, score,
/// explicação e sinais são dado de entrada, nunca conteúdo fixo da tela.
/// Isso permite trocar a origem (fixture fictícia → análise real da Fase 4)
/// sem tocar neste widget.
class ResultadoAnalisePage extends StatelessWidget {
  const ResultadoAnalisePage({super.key, required this.analise});

  final AnaliseRisco analise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da Análise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TermometroRisco(score: analise.score, faixa: analise.faixa),
              const SizedBox(height: 24),
              Text(
                'Sinais identificados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (analise.sinais.isEmpty)
                const Text('Nenhum sinal relevante identificado.')
              else
                ...analise.sinais.map(
                  (sinal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(sinal),
                    dense: true,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Explicação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(analise.explicacao),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(child: Text(RotulosRisco.avisoPermanente)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

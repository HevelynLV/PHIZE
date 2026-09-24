import 'package:flutter/material.dart';

import '../../domain/resultado_analise_link.dart';
import '../../domain/rotulos_risco.dart';
import '../../domain/verificacao_link.dart';
import '../widgets/termometro_risco.dart';

/// Tela de Resultado da análise de link (RF03, RF07, UC03 passo 8).
///
/// Renderiza inteiramente a partir do [resultado] recebido — score, faixa e
/// verificações são dado de entrada; a tela não calcula nem ajusta nada.
class ResultadoAnalisePage extends StatelessWidget {
  const ResultadoAnalisePage({super.key, required this.resultado});

  final ResultadoAnaliseLink resultado;

  @override
  Widget build(BuildContext context) {
    final naoConcluidas = resultado.naoConcluidas;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da Análise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TermometroRisco(
                score: resultado.score.pontuacao,
                faixa: resultado.score.faixa,
              ),
              if (naoConcluidas.isNotEmpty) ...[
                const SizedBox(height: 24),
                _AvisoVerificacaoIncompleta(naoConcluidas: naoConcluidas),
              ],
              const SizedBox(height: 24),
              Text(
                'O que verificamos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...resultado.verificacoes.map(
                (v) => _VerificacaoTile(verificacao: v),
              ),
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

class _AvisoVerificacaoIncompleta extends StatelessWidget {
  const _AvisoVerificacaoIncompleta({required this.naoConcluidas});

  final List<VerificacaoLink> naoConcluidas;

  @override
  Widget build(BuildContext context) {
    final titulos = naoConcluidas.map((v) => v.titulo).join('; ');
    return Card(
      key: const Key('resultado_verificacao_incompleta'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verificação incompleta. Não foi possível concluir: '
                '$titulos. Enquanto alguma verificação estiver incompleta, '
                'o resultado nunca é exibido na faixa verde.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificacaoTile extends StatelessWidget {
  const _VerificacaoTile({required this.verificacao});

  final VerificacaoLink verificacao;

  @override
  Widget build(BuildContext context) {
    final (icone, situacao) = switch (verificacao.status) {
      StatusVerificacao.sinalEncontrado => (
        const Icon(Icons.flag, color: Colors.red),
        'Sinal de risco encontrado',
      ),
      StatusVerificacao.semSinal => (
        const Icon(Icons.check_circle_outline),
        'Nenhum sinal de risco nesta verificação',
      ),
      StatusVerificacao.naoConcluida => (
        const Icon(Icons.help_outline, color: Colors.orange),
        'Verificação não concluída',
      ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icone,
      title: Text(verificacao.titulo),
      subtitle: Text(
        '$situacao. ${verificacao.descricao}\n'
        'Fonte: ${verificacao.fonte}',
      ),
      isThreeLine: true,
    );
  }
}

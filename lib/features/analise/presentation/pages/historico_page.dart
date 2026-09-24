import 'package:flutter/material.dart';

import '../../domain/analise_risco.dart';
import '../../domain/faixa_risco.dart';
import '../widgets/phize_bottom_nav.dart';

/// Histórico de análises (RF07 / RNF01): lista apenas o resultado de cada
/// análise (score, faixa, explicação, data) — nunca o conteúdo original.
/// Dado fictício embutido, cobrindo as três faixas de risco, até a
/// persistência seletiva do histórico (UC06, Fase 8). Sem navegação ao
/// Resultado: essa tela exibe apenas análises reais de link (UC03), e o
/// detalhe de um registro do histórico é escopo do UC06.
class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  static final List<AnaliseRisco> _historicoFicticio = [
    AnaliseRisco(
      id: 'hist-1',
      score: 85,
      faixa: FaixaRisco.alto,
      explicacao:
          'A mensagem ameaça bloqueio de conta e pede envio imediato de '
          'código recebido por SMS.',
      sinais: const [
        'Indução de urgência',
        'Solicitação de dados pessoais',
        'Ameaça',
      ],
      data: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AnaliseRisco(
      id: 'hist-2',
      score: 58,
      faixa: FaixaRisco.medio,
      explicacao:
          'O link encaminhado não corresponde ao domínio oficial da '
          'instituição citada.',
      sinais: const ['Link suspeito'],
      data: DateTime.now().subtract(const Duration(days: 3)),
    ),
    AnaliseRisco(
      id: 'hist-3',
      score: 12,
      faixa: FaixaRisco.baixo,
      explicacao: 'Nenhum sinal relevante identificado na mensagem analisada.',
      sinais: const [],
      data: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Análises')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _historicoFicticio.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final analise = _historicoFicticio[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: analise.faixa.cor,
                child: Text(
                  '${analise.score}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              title: Text(analise.faixa.rotulo),
              subtitle: Text(_formatarData(analise.data)),
            ),
          );
        },
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 1),
    );
  }
}

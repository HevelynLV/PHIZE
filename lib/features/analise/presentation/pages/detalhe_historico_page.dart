import 'package:flutter/material.dart';

import '../../../../shared/domain/formatacao_data.dart';
import '../../domain/analise_risco.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/aviso_card.dart';
import '../widgets/o_que_fazer_card.dart';
import '../widgets/termometro_risco.dart';
import '../../../../shared/widgets/scaffold_phize.dart';
import 'historico_page.dart';

/// Detalhe de um registro do histórico (UC06, passos 4 e 5). Mostra só o que
/// foi gravado: o conteúdo analisado não existe mais (Zero-Persistence).
class DetalheHistoricoPage extends StatelessWidget {
  const DetalheHistoricoPage({super.key, required this.analise});

  static const String avisoZeroPersistencia =
      'Por privacidade, o Phize não guarda o print, o texto nem o endereço '
      'analisado. Este registro traz apenas o resultado da análise.';

  final AnaliseRisco analise;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleMedium;
    final categoria = analise.categoria;

    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Detalhe da Análise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TermometroRisco(score: analise.score, faixa: analise.faixa),
              const SizedBox(height: 8),
              Text(
                '${nomeTipoEntrada(analise.tipoEntrada)} analisado em '
                '${formatarData(analise.data)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OQueFazerCard(faixa: analise.faixa),
              if (categoria != null) ...[
                const SizedBox(height: 24),
                Text('Tipo de abordagem', style: titulo),
                const SizedBox(height: 4),
                Text(categoria.nome),
              ],
              const SizedBox(height: 24),
              Text('Por que isso importa', style: titulo),
              const SizedBox(height: 4),
              Text(analise.explicacao),
              const SizedBox(height: 24),
              const AvisoCard(
                key: Key('detalhe_aviso_zero_persistencia'),
                texto: avisoZeroPersistencia,
              ),
              if (analise.tipoEntrada == TipoEntrada.link) ...[
                const SizedBox(height: 12),
                const AvisoCard(texto: RotulosRisco.avisoFalibilidadeReputacao),
              ],
              const SizedBox(height: 12),
              const AvisoCard(
                key: Key('detalhe_aviso_permanente'),
                texto: RotulosRisco.avisoPermanente,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

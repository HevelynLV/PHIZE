import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';
import '../../domain/rotulos_risco.dart';
import '../../domain/sinal_link.dart';
import '../../domain/sinal_texto_print.dart';
import '../widgets/aviso_card.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// "Como o Phize calcula o risco" (RF14, RF07), aberta pelo perfil.
///
/// Explica os sinais, a regra fixa e as três faixas em linguagem simples.
/// Não mostra pesos nem pontos de corte: a fonte única desses números é
/// `docs/score-calibracao.md`, e eles mudam a cada calibragem.
class ComoCalculaRiscoPage extends StatelessWidget {
  const ComoCalculaRiscoPage({super.key});

  static const Map<FaixaRisco, String> _significado = {
    FaixaRisco.baixo:
        'Nenhum sinal foi encontrado. Isso não garante que não haja risco: '
        'continue desconfiando de pedidos de dinheiro, senhas ou códigos.',
    FaixaRisco.medio:
        'Há sinais que pedem cuidado. Não pague nem envie dados antes de '
        'confirmar por um canal oficial.',
    FaixaRisco.alto:
        'Vários sinais juntos, ou um sinal forte. Não envie dinheiro nem '
        'dados.',
  };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final brilho = Theme.of(context).brightness;

    Widget titulo(String texto) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(texto, style: textos.titleMedium),
      ),
    );

    Widget item(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.only(top: 2, right: 10),
              child: Icon(Icons.flag_outlined, size: 20),
            ),
          ),
          Expanded(child: Text(texto)),
        ],
      ),
    );

    return ScaffoldPhize(
      // Título curto: o nome completo, usado no perfil, ficava cortado na
      // barra com letra muito grande (RF14).
      appBar: AppBar(title: const Text('Cálculo do risco')),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('como_calcula_conteudo'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'O Phize procura na mensagem ou no link sinais que costumam '
                'aparecer em golpes. Cada sinal encontrado soma pontos, e o '
                'resultado vai de 0 a 100: quanto maior, mais sinais de golpe.',
              ),
              titulo('Quem decide o número'),
              const Text(
                'Na análise de print, uma inteligência artificial lê o texto e '
                'aponta quais sinais aparecem. Ela não dá a nota. O número sai '
                'de uma regra fixa do próprio app, igual para todo mundo: os '
                'mesmos sinais sempre dão o mesmo número. Às vezes, a '
                'inteligência artificial pode apontar sinais diferentes na '
                'mesma mensagem.',
              ),
              titulo('Sinais procurados nos prints'),
              for (final sinal in SinalTextoPrint.values) item(sinal.titulo),
              titulo('Sinais procurados nos links'),
              for (final sinal in SinalLink.values) item(sinal.titulo),
              const SizedBox(height: 4),
              const Text(
                'Alguns sinais pesam mais que outros, e quanto mais sinais '
                'aparecem juntos, maior o número. Basta um sinal para o '
                'resultado deixar de ser verde.',
              ),
              titulo('O que cada cor quer dizer'),
              for (final faixa in FaixaRisco.values)
                Container(
                  key: Key('como_calcula_faixa_${faixa.name}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: faixa.cor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(color: faixa.cor, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faixa.rotulo,
                        style: textos.titleMedium?.copyWith(
                          color: faixa.corTextoEm(brilho),
                        ),
                      ),
                      Text(_significado[faixa]!),
                    ],
                  ),
                ),
              titulo('Quando uma verificação falha'),
              const Text(
                'Às vezes um serviço consultado não responde, por exemplo '
                'sem internet. A análise continua com o que foi possível '
                'verificar, e a tela de resultado diz qual verificação faltou. '
                'Nesse caso o resultado nunca fica verde: no mínimo aparece em '
                'amarelo, para você conferir com mais cuidado.',
              ),
              titulo('O que o Phize não faz'),
              const Text(
                'O Phize não lê suas conversas por conta própria e não guarda '
                'o print nem o texto analisado. No histórico ficam só o '
                'número, a cor, o tipo de golpe, a explicação e a data.',
              ),
              const SizedBox(height: 24),
              const AvisoCard(texto: RotulosRisco.avisoPermanente),
            ],
          ),
        ),
      ),
    );
  }
}

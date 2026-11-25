import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/golpe_da_semana.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Detalhe do "Golpe da semana" (RF17): nome, sinais de alerta e orientação
/// preventiva, com o texto da ficha revisada, sem reescrita.
class GolpeDaSemanaPage extends StatelessWidget {
  const GolpeDaSemanaPage({super.key, required this.ficha});

  final FichaEducativa ficha;

  static const String nota =
      'Conteúdo da base de golpes do Phize, revisado pela equipe a partir de '
      'fontes públicas. Muda toda semana.';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );

    Widget secao(String titulo, Widget conteudo) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: tema.titleMedium),
          const SizedBox(height: 6),
          conteudo,
        ],
      ),
    );

    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Golpe da semana')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(ficha.categoria.nome, style: secundario),
          const SizedBox(height: 4),
          Text(ficha.modalidade, style: tema.headlineSmall),
          const SizedBox(height: 8),
          Text('Chega por: ${ficha.canais.join(', ')}', style: secundario),
          secao(
            'Frases que costumam aparecer',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final frase in ficha.frasesComuns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: tema.bodyLarge),
                        Expanded(
                          child: Text(
                            '"$frase"',
                            style: tema.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          secao('O que pedem', Text(ficha.oQuePedem, style: tema.bodyLarge)),
          secao(
            'O que fazer',
            Text(
              ficha.oQueFazer,
              key: const Key('golpe_da_semana_o_que_fazer'),
              style: tema.bodyLarge,
            ),
          ),
          if (ficha.fontes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                [
                  for (final fonte in ficha.fontes)
                    'Fonte: ${fonte.publicador}, "${fonte.titulo}"',
                ].join('\n'),
                style: secundario,
              ),
            ),
          const SizedBox(height: 16),
          Text(nota, style: secundario),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tutorial_repository_local.dart';
import '../../domain/resultado_analise_link.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/resultado_score.dart';
import '../../domain/rotulos_risco.dart';
import '../../domain/sinal_texto_print.dart';
import '../../domain/tutorial_repository.dart';
import '../../domain/verificacao_link.dart';
import '../tutorial/tutorial_link.dart';
import '../tutorial/tutorial_page.dart';
import '../tutorial/tutorial_print.dart';
import '../widgets/aviso_card.dart';
import '../widgets/o_que_fazer_card.dart';
import '../widgets/termometro_risco.dart';
import '../widgets/visual_noturno.dart';

/// Tela de Resultado da análise de link (RF03, RF07, UC03 passo 8) e de
/// print (RF04, RF07, UC04 passo 9).
///
/// Renderiza inteiramente a partir do resultado recebido — score, faixa e
/// verificações são dado de entrada; a tela não calcula nem ajusta nada.
/// Em particular, a faixa vem pronta de `CalculadoraScore`, que já aplica a
/// regra de verificação incompleta (inclusive a ausência da base de
/// conhecimento na análise de print); a tela nunca a reavalia.
///
/// Termômetro, rotulagem do RF07 e aviso permanente ficam em [build], comuns
/// aos dois tipos; só o detalhamento muda conforme a entrada.
class ResultadoAnalisePage extends StatelessWidget {
  const ResultadoAnalisePage({
    super.key,
    required ResultadoAnaliseLink resultado,
    this.tutorialRepository,
  }) : _link = resultado,
       _print = null;

  /// O resultado de print não contém a imagem nem o texto inteiro: da conversa,
  /// só chegam aqui os trechos destacados, já mascarados.
  const ResultadoAnalisePage.print({
    super.key,
    required AnalisePrintConcluida resultado,
    this.tutorialRepository,
  }) : _link = null,
       _print = resultado;

  final ResultadoAnaliseLink? _link;
  final AnalisePrintConcluida? _print;

  /// Marca de tutorial visto (RF13). Quem chega pelo compartilhamento não
  /// vê o tutorial antes da análise; o botão "Como funciona?" o oferece aqui.
  final TutorialRepository? tutorialRepository;

  void _abrirTutorial(BuildContext context) {
    final link = _link != null;
    abrirTutorial(
      context,
      tipo: link ? TipoTutorial.link : TipoTutorial.print,
      repositorio: tutorialRepository ?? TutorialRepositoryLocal(),
      construir: (_) =>
          link ? const TutorialLinkPage() : const TutorialPrintPage(),
    );
  }

  /// Volta ao Início num toque, limpando as telas abertas por baixo (a
  /// tela de análise e, depois de um compartilhamento, resultados
  /// anteriores). No ensaio de 2026-11-16, voltar exigia vários toques.
  void _voltarAoInicio(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (_) => false,
    );
  }

  ResultadoScore get _score => _link?.score ?? _print!.score;

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final resultadoLink = _link;
    final resultadoPrint = _print;

    return TelaNoturna(
      titulo: 'Resultado da Análise',
      icone: Icons.shield_outlined,
      acoes: [
        IconButton(
          key: const Key('resultado_como_funciona'),
          tooltip: 'Como funciona',
          icon: const Icon(Icons.help_outline),
          onPressed: () => _abrirTutorial(context),
        ),
      ],
      corpo: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CartaoDestaque(
            child: TermometroRisco(score: score.pontuacao, faixa: score.faixa),
          ),
          const SizedBox(height: 16),
          OQueFazerCard(faixa: score.faixa),
          if (resultadoLink != null) ..._detalhesLink(context, resultadoLink),
          if (resultadoPrint != null)
            ..._detalhesPrint(context, resultadoPrint),
          const SizedBox(height: 12),
          const AvisoCard(
            key: Key('resultado_aviso_permanente'),
            texto: RotulosRisco.avisoPermanente,
          ),
        ],
      ),
      rodape: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.tonalIcon(
            key: const Key('resultado_voltar_inicio'),
            onPressed: () => _voltarAoInicio(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Voltar ao início'),
          ),
        ),
      ),
    );
  }

  List<Widget> _detalhesLink(
    BuildContext context,
    ResultadoAnaliseLink resultado,
  ) {
    final naoConcluidas = resultado.naoConcluidas;
    return [
      if (naoConcluidas.isNotEmpty) ...[
        const SizedBox(height: 16),
        _AvisoVerificacaoIncompleta(
          texto:
              'Verificação incompleta. Não foi possível concluir: '
              '${naoConcluidas.map((v) => v.titulo).join('; ')}. Enquanto '
              'alguma verificação estiver incompleta, o resultado nunca é '
              'exibido na faixa verde.',
        ),
      ],
      const SizedBox(height: 16),
      CartaoSecao(
        filhos: [
          Text(
            'O que verificamos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...resultado.verificacoes.map(
            (v) => _VerificacaoTile(verificacao: v),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const AvisoCard(
        key: Key('resultado_aviso_falibilidade'),
        texto: RotulosRisco.avisoFalibilidadeReputacao,
      ),
    ];
  }

  List<Widget> _detalhesPrint(
    BuildContext context,
    AnalisePrintConcluida resultado,
  ) {
    final titulo = Theme.of(context).textTheme.titleMedium;
    return [
      if (resultado.verificacoesNaoConcluidas.isNotEmpty) ...[
        const SizedBox(height: 16),
        _AvisoVerificacaoIncompleta(
          texto:
              'Verificação incompleta. '
              '${resultado.verificacoesNaoConcluidas.join(' ')}',
        ),
      ],
      const SizedBox(height: 16),
      CartaoSecao(
        filhos: [
          Text('O que encontramos na mensagem', style: titulo),
          const SizedBox(height: 8),
          // Sem ícone de confirmação: ausência de sinais conhecidos não é
          // ausência de risco, e com verificação incompleta o texto diz isso.
          // Nem de alerta: o "?" laranja soava como aviso no resultado verde
          // (ensaio de 2026-11-16). Fica um ícone neutro de informação.
          if (resultado.sinais.isEmpty)
            ListTile(
              key: const Key('resultado_print_sem_sinais'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.info_outline,
                key: const Key('resultado_print_sem_sinais_icone'),
                color: context.cores.textoSecundario,
              ),
              title: Text(
                resultado.verificacoesNaoConcluidas.isEmpty
                    ? 'Não identificamos sinais de golpe conhecidos neste texto.'
                    : 'Não identificamos sinais de golpe conhecidos neste texto, '
                          'mas a verificação não pôde ser completa (veja o aviso '
                          'acima).',
              ),
            )
          else
            for (final sinal in SinalTextoPrint.values)
              if (resultado.sinais.contains(sinal))
                _SinalTile(
                  titulo: sinal.titulo,
                  trechos: [
                    for (final trecho in resultado.trechos)
                      if (trecho.sinal == sinal) trecho.texto,
                  ],
                ),
          if (resultado.trechos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              avisoTrechos,
              key: const Key('resultado_print_aviso_trechos'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      CartaoSecao(
        filhos: [
          Text('Tipo de abordagem', style: titulo),
          const SizedBox(height: 4),
          Text(
            resultado.categoria.nome,
            key: const Key('resultado_print_categoria'),
          ),
          const SizedBox(height: 16),
          Text('Por que isso importa', style: titulo),
          const SizedBox(height: 4),
          Text(resultado.explicacao, key: const Key('resultado_print_explicacao')),
        ],
      ),
    ];
  }

  /// O OCR embarcado às vezes junta palavras curtas ("nascimentoea"), e a
  /// frase é mostrada como foi lida, sem correção (RNF06, limitações
  /// declaradas; ensaio de 2026-11-16).
  static const String avisoTrechos =
      'As frases são lidas do print e podem ter pequenos erros de leitura. '
      'Elas aparecem só nesta tela e não ficam no seu histórico.';
}

class _SinalTile extends StatelessWidget {
  const _SinalTile({required this.titulo, required this.trechos});

  final String titulo;
  final List<String> trechos;

  @override
  Widget build(BuildContext context) {
    final corFaixa = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag, color: corFaixa),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.bodyLarge),
                // A chave fica no filho do Padding: um sinal pode ter mais
                // de uma frase, e chaves iguais entre irmãos quebram a tela.
                for (final trecho in trechos)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      key: const Key('resultado_print_trecho'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('“$trecho”'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoVerificacaoIncompleta extends StatelessWidget {
  const _AvisoVerificacaoIncompleta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: Text(texto)),
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
        const Icon(Icons.flag, color: Color(0xFFFF8A80)),
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

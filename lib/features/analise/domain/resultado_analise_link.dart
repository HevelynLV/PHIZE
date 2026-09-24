import 'resultado_score.dart';
import 'verificacao_link.dart';

/// Saída da análise de link (UC03), entrada da tela de Resultado.
///
/// Não contém o endereço analisado: o resultado pode ser exibido (e, na
/// Fase 8, gravado no histórico) sem carregar a URL em texto puro (UC03,
/// pós-condições).
class ResultadoAnaliseLink {
  const ResultadoAnaliseLink({required this.score, required this.verificacoes});

  final ResultadoScore score;
  final List<VerificacaoLink> verificacoes;

  List<VerificacaoLink> get naoConcluidas => verificacoes
      .where((v) => v.status == StatusVerificacao.naoConcluida)
      .toList();
}

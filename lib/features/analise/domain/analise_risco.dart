import 'faixa_risco.dart';

/// Resultado de uma análise (RF07), usado como entrada da tela de Resultado.
///
/// Layout apenas: nesta fase os valores são fictícios. A Fase 4 substitui a
/// origem dos dados (função determinística de score) sem alterar a tela,
/// que apenas renderiza o que recebe aqui.
class AnaliseRisco {
  const AnaliseRisco({
    required this.id,
    required this.score,
    required this.faixa,
    required this.explicacao,
    required this.sinais,
    required this.data,
  });

  final String id;
  final int score;
  final FaixaRisco faixa;
  final String explicacao;
  final List<String> sinais;
  final DateTime data;
}

import 'faixa_risco.dart';

/// Saída do motor de Score de Risco (RF07).
class ResultadoScore {
  const ResultadoScore({
    required this.pontuacao,
    required this.faixa,
    required this.rotulo,
    required this.versaoConfiguracao,
    required this.verificacaoIncompleta,
  });

  final int pontuacao;
  final FaixaRisco faixa;
  final String rotulo;
  final String versaoConfiguracao;
  final bool verificacaoIncompleta;
}

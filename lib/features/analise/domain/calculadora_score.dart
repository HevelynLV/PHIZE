import 'faixa_risco.dart';
import 'resultado_score.dart';
import 'score_config.dart';
import 'sinais_identificados.dart';

/// Motor de cálculo do Score de Risco (RF07).
///
/// Função determinística pura: sem chamada de API, sem UI. O LLM apenas
/// identifica os sinais de entrada; esta classe converte sinais em número,
/// conforme a regra de RF07 (CLAUDE.md, Seção 4) — a mesma entrada produz
/// sempre a mesma saída.
class CalculadoraScore {
  CalculadoraScore._();

  static ResultadoScore calcular(SinaisIdentificados sinais) {
    final pontuacao = _calcularPontuacao(sinais);
    var faixa = classificarFaixa(pontuacao);

    if (sinais.verificacaoIncompleta && faixa == FaixaRisco.baixo) {
      faixa = FaixaRisco.medio;
    }

    return ResultadoScore(
      pontuacao: pontuacao,
      faixa: faixa,
      rotulo: faixa.rotulo,
      versaoConfiguracao: ScoreConfig.versao,
      verificacaoIncompleta: sinais.verificacaoIncompleta,
    );
  }

  static int _calcularPontuacao(SinaisIdentificados sinais) {
    final somaTextoPrint = sinais.textoPrint.fold<int>(
      0,
      (soma, sinal) => soma + (ScoreConfig.pesosTextoPrint[sinal] ?? 0),
    );
    final somaLink = sinais.link.fold<int>(
      0,
      (soma, sinal) => soma + (ScoreConfig.pesosLink[sinal] ?? 0),
    );

    final soma = somaTextoPrint + somaLink;
    return soma > ScoreConfig.pontuacaoMaxima
        ? ScoreConfig.pontuacaoMaxima
        : soma;
  }

  /// Classifica uma pontuação já calculada nas 3 faixas do RF07, conforme os
  /// pontos de corte definidos em `docs/score-calibracao.md`.
  static FaixaRisco classificarFaixa(int pontuacao) {
    if (pontuacao <= ScoreConfig.faixaBaixoMax) return FaixaRisco.baixo;
    if (pontuacao <= ScoreConfig.faixaMedioMax) return FaixaRisco.medio;
    return FaixaRisco.alto;
  }
}

/// Status da consulta de idade de domínio (RF03/UC03).
enum StatusConsultaDominio {
  /// A consulta obteve uma resposta definitiva do RDAP — inclusive quando
  /// essa resposta é "o domínio não existe".
  concluida,

  /// A consulta não pôde ser concluída (indisponibilidade, timeout,
  /// resposta em formato inesperado ou sem data de registro). Degradação
  /// controlada (CLAUDE.md, Seção 8): isso não interrompe a análise.
  naoConcluida,
}

/// Saída da consulta de idade de registro do domínio via RDAP (RF03/UC03;
/// arquitetura, seção 4, item 3).
class ResultadoConsultaDominio {
  const ResultadoConsultaDominio({
    required this.status,
    this.dataRegistro,
    this.dominioRecente = false,
    this.motivoNaoConcluida,
  });

  final StatusConsultaDominio status;

  /// `null` quando o domínio não existe ou quando a consulta não foi
  /// concluída.
  final DateTime? dataRegistro;

  /// `true` quando o domínio foi registrado há menos dias que o limite de
  /// `docs/score-calibracao.md` (`ScoreConfig.dominioRecenteLimiteDias`).
  /// Sempre `false` quando [dataRegistro] é `null`.
  final bool dominioRecente;

  /// Motivo pelo qual a consulta não foi concluída, em linguagem não
  /// técnica adequada a exibição ao usuário (CLAUDE.md, Seção 8). `null`
  /// quando [status] é [StatusConsultaDominio.concluida].
  final String? motivoNaoConcluida;
}

/// Status da consulta de reputação de domínio no Google Safe Browsing
/// (RF03/UC03; arquitetura, seção 4, etapa 2).
enum StatusConsultaReputacao {
  /// O domínio consta como malicioso no Google Safe Browsing.
  listado,

  /// O domínio não consta nas listas do Google Safe Browsing. Não é
  /// afirmação de ausência de risco: a fonte cobre mal domínios recém-
  /// criados (arquitetura, seção 4, etapa 2).
  naoListado,

  /// A consulta não pôde ser concluída. Degradação controlada (CLAUDE.md,
  /// Seção 8): isso não interrompe a análise.
  naoConcluida,
}

/// Saída da consulta de reputação de domínio.
class ResultadoConsultaReputacao {
  const ResultadoConsultaReputacao({
    required this.status,
    this.tiposAmeaca = const [],
    this.motivoNaoConcluida,
  });

  final StatusConsultaReputacao status;

  /// Categorias informadas pelo Google (ex.: `SOCIAL_ENGINEERING`). Vazia
  /// quando [status] não é [StatusConsultaReputacao.listado].
  final List<String> tiposAmeaca;

  /// Motivo pelo qual a consulta não foi concluída, em linguagem não
  /// técnica adequada a exibição ao usuário (CLAUDE.md, Seção 8). `null`
  /// quando a consulta foi concluída.
  final String? motivoNaoConcluida;
}

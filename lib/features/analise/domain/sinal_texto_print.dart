/// Os 8 sinais do grupo Texto/Print (RF07).
///
/// Identificados pelo modelo de linguagem no conteúdo analisado; os pesos
/// atribuídos a cada um constam exclusivamente de `docs/score-calibracao.md`
/// (ScoreConfig.pesosTextoPrint).
enum SinalTextoPrint {
  correspondenciaPadraoCatalogado,
  pedidoFinanceiro,
  alegacaoTrocaContato,
  solicitacaoDadosPessoais,
  ameaca,
  linkSuspeito,
  ofertaIncompativelMercado,
  inducaoUrgencia,
}

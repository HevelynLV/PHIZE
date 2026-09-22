/// Os sinais do grupo Link (UC03).
///
/// Derivados da verificação de URL (Safe Browsing, typosquatting, RDAP); os
/// pesos atribuídos a cada um constam exclusivamente de
/// `docs/score-calibracao.md` (ScoreConfig.pesosLink).
enum SinalLink {
  listadoSafeBrowsing,
  typosquatting,
  dominioRecemCriado,
}

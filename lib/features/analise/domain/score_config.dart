import 'sinal_link.dart';
import 'sinal_texto_print.dart';

/// Fonte única dos valores numéricos do motor de Score de Risco (RF07).
///
/// Espelha exatamente `docs/score-calibracao.md` — versão da calibragem,
/// pesos dos dois grupos de sinais, pontos de corte das faixas e limite de
/// domínio recém-criado. Nenhum outro ponto do código deve duplicar estes
/// valores (CLAUDE.md, Seção 4).
class ScoreConfig {
  ScoreConfig._();

  static const String versao = '1.0';

  static const int pontuacaoMaxima = 100;

  static const int dominioRecenteLimiteDias = 30;

  static const Map<SinalTextoPrint, int> pesosTextoPrint = {
    SinalTextoPrint.correspondenciaPadraoCatalogado: 40,
    SinalTextoPrint.pedidoFinanceiro: 30,
    SinalTextoPrint.alegacaoTrocaContato: 30,
    SinalTextoPrint.solicitacaoDadosPessoais: 30,
    SinalTextoPrint.ameaca: 25,
    SinalTextoPrint.linkSuspeito: 25,
    SinalTextoPrint.ofertaIncompativelMercado: 25,
    SinalTextoPrint.inducaoUrgencia: 20,
  };

  static const Map<SinalLink, int> pesosLink = {
    SinalLink.listadoSafeBrowsing: 70,
    SinalLink.typosquatting: 40,
    SinalLink.dominioRecemCriado: 25,
  };

  static const int faixaBaixoMin = 0;
  static const int faixaBaixoMax = 19;
  static const int faixaMedioMin = 20;
  static const int faixaMedioMax = 59;
  static const int faixaAltoMin = 60;
  static const int faixaAltoMax = 100;
}

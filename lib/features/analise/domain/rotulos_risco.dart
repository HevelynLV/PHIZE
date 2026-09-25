/// Fonte única das frases obrigatórias do RF07 (CLAUDE.md, Seção 5) e do
/// aviso exigido pelos termos do Google Safe Browsing (arquitetura, seção 4,
/// etapa 2, item c).
///
/// Nenhum outro ponto do código deve reescrever estes textos: a rotulagem
/// das faixas de risco e os avisos são regra centralizada, não conteúdo de
/// tela.
class RotulosRisco {
  RotulosRisco._();

  static const String baixoRisco = 'Não encontramos sinais de golpe';
  static const String medioRisco = 'Atenção: sinais suspeitos';
  static const String altoRisco = 'Alto risco de golpe';

  static const String avisoPermanente =
      'Esta análise é uma ferramenta de apoio à decisão e não substitui a '
      'verificação direta junto à instituição envolvida.';

  /// Exibido em todo resultado de análise de link, qualquer que seja o
  /// status da consulta ao Google Safe Browsing.
  static const String avisoFalibilidadeReputacao =
      'A consulta ao Google Safe Browsing não é infalível: um endereço '
      'legítimo pode ser apontado como perigoso por engano (falso '
      'positivo), e um endereço perigoso pode não ser apontado (falso '
      'negativo).';
}

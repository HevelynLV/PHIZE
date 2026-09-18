/// Fonte única das frases obrigatórias do RF07 (CLAUDE.md, Seção 5).
///
/// Nenhum outro ponto do código deve reescrever estes textos: a rotulagem
/// das faixas de risco e o aviso permanente são regra centralizada, não
/// conteúdo de tela.
class RotulosRisco {
  RotulosRisco._();

  static const String baixoRisco = 'Não encontramos sinais de golpe';
  static const String medioRisco = 'Atenção: sinais suspeitos';
  static const String altoRisco = 'Alto risco de golpe';

  static const String avisoPermanente =
      'Esta análise é uma ferramenta de apoio à decisão e não substitui a '
      'verificação direta junto à instituição envolvida.';
}

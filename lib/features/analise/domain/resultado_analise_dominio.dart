/// Saída da análise de anatomia de URL / typosquatting (RF03/UC03;
/// arquitetura, seção 4, item 4).
class ResultadoAnaliseDominio {
  const ResultadoAnaliseDominio({
    required this.entradaValida,
    this.dominioNormalizado,
    this.typosquattingDetectado = false,
    this.marcaImitada,
  });

  /// `false` quando a entrada não é uma URL/domínio válido — os demais
  /// campos são então irrelevantes (`null`/`false`).
  final bool entradaValida;

  final String? dominioNormalizado;
  final bool typosquattingDetectado;
  final String? marcaImitada;
}

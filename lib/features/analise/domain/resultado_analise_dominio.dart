/// Saída da análise de anatomia de URL / typosquatting (RF03/UC03;
/// arquitetura, seção 4, item 4).
class ResultadoAnaliseDominio {
  const ResultadoAnaliseDominio({
    required this.entradaValida,
    this.dominioNormalizado,
    this.dominioRegistravel,
    this.typosquattingDetectado = false,
    this.marcaImitada,
  });

  /// `false` quando a entrada não é uma URL/domínio válido — os demais
  /// campos são então irrelevantes (`null`/`false`).
  final bool entradaValida;

  final String? dominioNormalizado;

  /// Parte registrável de [dominioNormalizado], sem subdomínios (ex.:
  /// "itau.com.br" para "www2.itau.com.br"). É o que a consulta RDAP
  /// recebe: a data de registro pertence ao domínio registrável, não a
  /// cada subdomínio.
  final String? dominioRegistravel;
  final bool typosquattingDetectado;
  final String? marcaImitada;
}

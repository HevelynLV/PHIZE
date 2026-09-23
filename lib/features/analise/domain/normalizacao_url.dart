/// Normalização de endereço e isolamento do domínio (RF03/UC03; UC05;
/// arquitetura, seção 5.5). Mesma rotina referenciada pela normalização de
/// URL da comunidade de reporte (UC05): descarta esquema, caminho,
/// parâmetros de consulta e fragmento — preservando apenas o domínio — para
/// que variações do mesmo endereço produzam sempre o mesmo resultado.
library;

final RegExp _regexHostValido = RegExp(
  r'^(?:[a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$',
);

/// Retorna o domínio normalizado (minúsculo, sem "www.", esquema, caminho,
/// parâmetros de consulta ou fragmento) ou `null` se [entrada] não for uma
/// URL/domínio válido.
String? normalizarDominio(String entrada) {
  final semEspacosNasPontas = entrada.trim();
  if (semEspacosNasPontas.isEmpty) return null;

  // Um domínio nunca contém espaço; a checagem explícita evita depender do
  // comportamento de Uri.tryParse diante de um caractere que já sabemos ser
  // inválido para essa finalidade.
  if (semEspacosNasPontas.contains(' ')) return null;

  final comEsquema = semEspacosNasPontas.contains('://')
      ? semEspacosNasPontas
      : 'http://$semEspacosNasPontas';

  final uri = Uri.tryParse(comEsquema);
  if (uri == null) return null;

  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) {
    host = host.substring(4);
  }

  // Host com caractere fora de A-Z/0-9/hífen (ex.: "itaú.com.br") chega até
  // aqui já percent-encoded pelo Uri ("ita%C3%BA.com.br"), e o "%" reprova
  // a regex acima: a entrada é tratada como inválida, nunca como o domínio
  // ASCII equivalente. Detecção de homógrafo/IDN (ex.: reconhecer que um
  // domínio com "ú" imita "itau.com.br") está fora do escopo do MVP —
  // exigiria decodificação Punycode e uma tabela de caracteres visualmente
  // equivalentes entre alfabetos, não apenas o descarte seguro já feito
  // aqui.
  if (!_regexHostValido.hasMatch(host)) return null;

  return host;
}

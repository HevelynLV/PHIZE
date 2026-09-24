/// Normalização de endereço (RF03/UC03; UC05; arquitetura, seções 4 e 5.5).
/// Uma única rotina de interpretação da entrada, com duas saídas:
///
/// - [normalizarDominio]: só o domínio. Usada por RDAP, typosquatting e
///   pela comunidade de reporte (UC05) — descarta esquema, caminho,
///   parâmetros de consulta e fragmento para que variações do mesmo
///   endereço produzam sempre o mesmo resultado.
/// - [normalizarUrlReputacao]: domínio E caminho, sem query nem fragmento.
///   Usada só pela consulta de reputação (Safe Browsing).
library;

final RegExp _regexHostValido = RegExp(
  r'^(?:[a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$',
);

/// Interpretação comum às duas normalizações. Devolve `null` se [entrada]
/// não for uma URL/domínio válido.
Uri? _interpretar(String entrada) {
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

  // Host com caractere fora de A-Z/0-9/hífen (ex.: "itaú.com.br") chega até
  // aqui já percent-encoded pelo Uri ("ita%C3%BA.com.br"), e o "%" reprova
  // a regex acima: a entrada é tratada como inválida, nunca como o domínio
  // ASCII equivalente. Detecção de homógrafo/IDN (ex.: reconhecer que um
  // domínio com "ú" imita "itau.com.br") está fora do escopo do MVP —
  // exigiria decodificação Punycode e uma tabela de caracteres visualmente
  // equivalentes entre alfabetos, não apenas o descarte seguro já feito
  // aqui.
  if (!_regexHostValido.hasMatch(uri.host.toLowerCase())) return null;

  return uri;
}

/// Retorna o domínio normalizado (minúsculo, sem "www.", esquema, caminho,
/// parâmetros de consulta ou fragmento) ou `null` se [entrada] não for uma
/// URL/domínio válido.
String? normalizarDominio(String entrada) {
  final uri = _interpretar(entrada);
  if (uri == null) return null;

  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) {
    host = host.substring(4);
  }

  // Revalida depois de remover o "www.": "www.com" não vira "com".
  if (!_regexHostValido.hasMatch(host)) return null;

  return host;
}

/// Retorna a URL a ser enviada à consulta de reputação — esquema, host e
/// caminho — ou `null` se [entrada] não for uma URL válida de esquema
/// `http`/`https`. Executada no dispositivo, antes de qualquer transmissão.
///
/// Por que o caminho é enviado: o Google Safe Browsing cataloga ameaças
/// por URL, não só por domínio. Golpes hospedados em um caminho de site
/// legítimo comprometido (`site-real.com.br/wp-content/banco/login`) só são
/// reconhecidos com o caminho — e "listado no Safe Browsing" é o sinal de
/// maior peso da calibragem (docs/score-calibracao.md).
///
/// Por que a query string e o fragmento NÃO são enviados: é neles que
/// costumam ir dados variáveis e potencialmente pessoais (e-mail, CPF,
/// token de sessão, código de rastreio). O descarte segue o mesmo princípio
/// da seção 5.5 da arquitetura. Pelo mesmo motivo, usuário e senha embutidos
/// no endereço (`https://usuario:senha@host/`) também são descartados.
///
/// Diferente de [normalizarDominio], o "www." é mantido: o Safe Browsing
/// pode listar o subdomínio exato, e a própria API testa os domínios-pai.
String? normalizarUrlReputacao(String entrada) {
  final uri = _interpretar(entrada);
  if (uri == null) return null;

  final esquema = uri.scheme.toLowerCase();
  if (esquema != 'http' && esquema != 'https') return null;

  return Uri(
    scheme: esquema,
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: uri.path.isEmpty ? '/' : uri.path,
  ).toString();
}

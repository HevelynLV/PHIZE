/// Porta de acesso à consulta de reputação de domínio (Google Safe
/// Browsing via camada intermediária; RF03/UC03; arquitetura, seção 4,
/// etapa 2). Abstrai o transporte para que a decisão sobre o resultado
/// possa ser testada com um dublê, sem acesso real à rede.
library;

/// Não há usuário autenticado, ou a Function rejeitou o token (HTTP 401).
class ReputacaoNaoAutenticadoException implements Exception {
  const ReputacaoNaoAutenticadoException();
}

/// A Function recusou a chamada por excesso de consultas do usuário
/// (HTTP 429).
class ReputacaoLimiteExcedidoException implements Exception {
  const ReputacaoLimiteExcedidoException();
}

/// Qualquer outra falha: Function fora do ar, status HTTP de erro, falha de
/// conexão, resposta que não é um JSON válido, etc.
class ReputacaoIndisponivelException implements Exception {
  const ReputacaoIndisponivelException(this.motivo);

  /// Detalhe técnico para depuração. Nunca contém a URL consultada.
  final String motivo;
}

abstract class ReputacaoDominioClient {
  /// Consulta a reputação de [urlNormalizada] (já normalizada no
  /// dispositivo por `normalizarUrlReputacao`: domínio e caminho, sem query
  /// nem fragmento) e devolve o corpo da resposta da Function já
  /// decodificado como JSON.
  ///
  /// Implementações devem lançar apenas as exceções declaradas neste
  /// arquivo — nunca deixar escapar uma exceção de transporte não mapeada.
  Future<Map<String, dynamic>> consultarUrl(String urlNormalizada);
}

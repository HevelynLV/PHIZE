/// Porta de acesso à análise de texto pelo modelo de linguagem, via camada
/// intermediária (UC04, etapas 7 e 8; RNF07, etapa 2; arquitetura, seção
/// 2 — Proteção de Credenciais). Abstrai o transporte para que o pipeline
/// possa ser testado com um dublê, sem acesso real à rede.
library;

/// Não há usuário autenticado, ou a Function rejeitou o token (HTTP 401).
class AnaliseTextoNaoAutenticadoException implements Exception {
  const AnaliseTextoNaoAutenticadoException();
}

/// A Function recusou a chamada por excesso de análises do usuário
/// (HTTP 429).
class AnaliseTextoLimiteExcedidoException implements Exception {
  const AnaliseTextoLimiteExcedidoException();
}

/// Qualquer outra falha: Function fora do ar, status HTTP de erro, falha de
/// conexão, resposta que não é um JSON válido, etc.
class AnaliseTextoIndisponivelException implements Exception {
  const AnaliseTextoIndisponivelException(this.motivo);

  /// Detalhe técnico para depuração. Nunca contém o texto analisado.
  final String motivo;
}

abstract class AnaliseTextoClient {
  /// Envia [textoMascarado] — que já passou pelo mascaramento local
  /// (`mascararTextoLocal`) e pelas duas verificações de volume mínimo — e
  /// devolve o corpo da resposta da Function já decodificado como JSON.
  ///
  /// Implementações devem lançar apenas as exceções declaradas neste
  /// arquivo, e nenhuma delas pode conter o texto.
  Future<Map<String, dynamic>> analisar(String textoMascarado);
}

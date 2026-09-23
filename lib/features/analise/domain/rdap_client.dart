/// Porta de acesso ao serviço RDAP (RF03/UC03; arquitetura, seção 4, item
/// 3). Abstrai o transporte de rede para que a lógica de decisão sobre
/// idade de domínio possa ser testada com um dublê, sem acesso real à
/// internet.
library;

/// Lançada por uma implementação de [RdapClient] quando o RDAP responde
/// que o domínio consultado não está registrado (ex.: HTTP 404).
class RdapDominioInexistenteException implements Exception {
  const RdapDominioInexistenteException();
}

/// Lançada por uma implementação de [RdapClient] para qualquer falha que
/// não seja "domínio inexistente": serviço fora do ar, status HTTP de
/// erro, falha de conexão, resposta que não é um JSON válido, etc.
class RdapIndisponivelException implements Exception {
  const RdapIndisponivelException(this.motivo);

  final String motivo;
}

abstract class RdapClient {
  /// Consulta o RDAP para [dominioNormalizado] (já normalizado pela rotina
  /// `normalizarDominio`) e devolve o corpo da resposta já decodificado
  /// como JSON.
  ///
  /// Implementações devem lançar [RdapDominioInexistenteException] ou
  /// [RdapIndisponivelException] em caso de falha — nunca deixar escapar
  /// uma exceção de transporte não mapeada (timeout, socket, etc.) sem
  /// convertê-la para uma dessas duas.
  Future<Map<String, dynamic>> consultarDominio(String dominioNormalizado);
}

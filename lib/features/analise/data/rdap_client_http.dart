import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/rdap_client.dart';

/// Escolhe o endpoint RDAP correto para [dominioNormalizado] (RF03/UC03;
/// arquitetura, seção 4, item 3): o Registro.br mantém servidor RDAP
/// próprio para domínios ".br"; domínios genéricos usam o bootstrap
/// público rdap.org, que redireciona para o servidor RDAP correto de cada
/// TLD. Função pura, sem efeito colateral — não faz a chamada de rede.
Uri construirUriConsulta(String dominioNormalizado) {
  if (dominioNormalizado.endsWith('.br')) {
    return Uri.parse('https://rdap.registro.br/domain/$dominioNormalizado');
  }
  return Uri.parse('https://rdap.org/domain/$dominioNormalizado');
}

/// Implementação real de [RdapClient], via HTTP (RF03/UC03; arquitetura,
/// seção 4, item 3). Não é exercitada por teste automatizado com acesso à
/// rede real — a lógica de decisão (idade do domínio, mapeamento de
/// falhas para status de verificação) é testada isoladamente em
/// `ConsultaIdadeDominio`, com este cliente substituído por um dublê.
class RdapClientHttp implements RdapClient {
  RdapClientHttp({http.Client? clienteHttp})
    : _clienteHttp = clienteHttp ?? http.Client();

  final http.Client _clienteHttp;

  @override
  Future<Map<String, dynamic>> consultarDominio(
    String dominioNormalizado,
  ) async {
    final uri = construirUriConsulta(dominioNormalizado);

    // Redirecionamentos continuam sendo seguidos automaticamente (padrão do
    // pacote http): o bootstrap rdap.org funciona justamente redirecionando
    // para o servidor RDAP autoritativo de cada TLD, e desligá-los quebraria
    // toda consulta de domínio não ".br". Consequência registrada: um
    // redirecionamento para OUTRO domínio (o Registro.br faz isso para
    // nomes parecidos) chega aqui como um 200 comum, e a única proteção
    // contra atribuir a data de outro domínio ao endereço analisado é a
    // validação do `ldhName` em `ConsultaIdadeDominio`.
    final http.Response resposta;
    try {
      resposta = await _clienteHttp.get(
        uri,
        headers: const {'Accept': 'application/rdap+json'},
      );
    } catch (e) {
      throw RdapIndisponivelException('Falha de conexão: $e');
    }

    if (resposta.statusCode == 404) {
      throw const RdapDominioInexistenteException();
    }
    if (resposta.statusCode != 200) {
      throw RdapIndisponivelException(
        'RDAP retornou status ${resposta.statusCode}',
      );
    }

    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is! Map<String, dynamic>) {
        throw const RdapIndisponivelException(
          'Resposta RDAP não é um objeto JSON.',
        );
      }
      return corpo;
    } on RdapIndisponivelException {
      rethrow;
    } catch (e) {
      throw RdapIndisponivelException(
        'Resposta RDAP não é um JSON válido: $e',
      );
    }
  }
}

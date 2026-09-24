import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/proxy_config.dart';
import '../domain/reputacao_dominio_client.dart';

/// Fornece o ID token do Firebase Auth do usuário atual, ou `null` quando
/// não há sessão.
typedef ObterTokenId = Future<String?> Function();

/// Implementação real de [ReputacaoDominioClient]: chama a Function
/// `reputacaoDominio` da camada intermediária, que detém a chave do Safe
/// Browsing (arquitetura, seção 2 — Proteção de Credenciais). O endereço
/// vem de [ProxyConfig] — emulador nesta fase, Function publicada depois,
/// sem mudança nesta classe.
///
/// A URL consultada vai no corpo do POST, nunca na URL da chamada, e não é
/// incluída em nenhuma mensagem de exceção.
class ReputacaoDominioClientHttp implements ReputacaoDominioClient {
  ReputacaoDominioClientHttp({
    required this._obterToken,
    http.Client? clienteHttp,
    Uri? endpoint,
  }) : _clienteHttp = clienteHttp ?? http.Client(),
       _endpoint = endpoint ?? ProxyConfig.reputacaoDominio;

  /// Usa a sessão atual do Firebase Auth como fonte do token.
  factory ReputacaoDominioClientHttp.comFirebaseAuth({
    http.Client? clienteHttp,
  }) => ReputacaoDominioClientHttp(
    obterToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    clienteHttp: clienteHttp,
  );

  final ObterTokenId _obterToken;
  final http.Client _clienteHttp;
  final Uri _endpoint;

  @override
  Future<Map<String, dynamic>> consultarUrl(String urlNormalizada) async {
    final String? token;
    try {
      token = await _obterToken();
    } catch (_) {
      throw const ReputacaoNaoAutenticadoException();
    }
    if (token == null || token.isEmpty) {
      throw const ReputacaoNaoAutenticadoException();
    }

    final http.Response resposta;
    try {
      resposta = await _clienteHttp.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'url': urlNormalizada}),
      );
    } catch (e) {
      throw ReputacaoIndisponivelException(
        'Falha de conexão com a Function (${e.runtimeType}).',
      );
    }

    if (resposta.statusCode == 401) {
      throw const ReputacaoNaoAutenticadoException();
    }
    if (resposta.statusCode == 429) {
      throw const ReputacaoLimiteExcedidoException();
    }
    if (resposta.statusCode != 200) {
      throw ReputacaoIndisponivelException(
        'Function retornou status ${resposta.statusCode}.',
      );
    }

    final Object? corpo;
    try {
      corpo = jsonDecode(resposta.body);
    } catch (_) {
      throw const ReputacaoIndisponivelException(
        'Resposta da Function não é um JSON válido.',
      );
    }
    if (corpo is! Map<String, dynamic>) {
      throw const ReputacaoIndisponivelException(
        'Resposta da Function não é um objeto JSON.',
      );
    }
    return corpo;
  }
}

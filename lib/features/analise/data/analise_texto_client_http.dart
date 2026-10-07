import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/proxy_config.dart';
import '../domain/analise_texto_client.dart';
import 'reputacao_dominio_client_http.dart' show ObterTokenId;

/// Implementação real de [AnaliseTextoClient]: chama a Function
/// `analiseTexto` da camada intermediária, que detém a chave do Gemini
/// (arquitetura, seção 2 — Proteção de Credenciais). A Function chama o
/// Gemini por HTTPS (RNF07, etapa 2); entre o app e a Function, a Function
/// publicada é HTTPS, e o emulador local responde em HTTP na própria
/// máquina de desenvolvimento.
///
/// O texto vai no corpo do POST, nunca na URL da chamada, e não é incluído
/// em nenhuma mensagem de exceção.
class AnaliseTextoClientHttp implements AnaliseTextoClient {
  AnaliseTextoClientHttp({
    required this._obterToken,
    http.Client? clienteHttp,
    Uri? endpoint,
  }) : _clienteHttp = clienteHttp ?? http.Client(),
       _endpoint = endpoint ?? ProxyConfig.analiseTexto;

  /// Usa a sessão atual do Firebase Auth como fonte do token.
  factory AnaliseTextoClientHttp.comFirebaseAuth({http.Client? clienteHttp}) =>
      AnaliseTextoClientHttp(
        obterToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
        clienteHttp: clienteHttp,
      );

  final ObterTokenId _obterToken;
  final http.Client _clienteHttp;
  final Uri _endpoint;

  @override
  Future<Map<String, dynamic>> analisar(String textoMascarado) async {
    final String? token;
    try {
      token = await _obterToken();
    } catch (_) {
      throw const AnaliseTextoNaoAutenticadoException();
    }
    if (token == null || token.isEmpty) {
      throw const AnaliseTextoNaoAutenticadoException();
    }

    final http.Response resposta;
    try {
      resposta = await _clienteHttp.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'texto': textoMascarado}),
      );
    } catch (e) {
      throw AnaliseTextoIndisponivelException(
        'Falha de conexão com a Function (${e.runtimeType}).',
      );
    }

    if (resposta.statusCode == 401) {
      throw const AnaliseTextoNaoAutenticadoException();
    }
    if (resposta.statusCode == 429) {
      throw const AnaliseTextoLimiteExcedidoException();
    }
    if (resposta.statusCode != 200) {
      throw AnaliseTextoIndisponivelException(
        'Function retornou status ${resposta.statusCode}.',
      );
    }

    final Object? corpo;
    try {
      corpo = jsonDecode(resposta.body);
    } catch (_) {
      throw const AnaliseTextoIndisponivelException(
        'Resposta da Function não é um JSON válido.',
      );
    }
    if (corpo is! Map<String, dynamic>) {
      throw const AnaliseTextoIndisponivelException(
        'Resposta da Function não é um objeto JSON.',
      );
    }
    return corpo;
  }
}

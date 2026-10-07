import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phize/core/config/proxy_config.dart';
import 'package:phize/features/analise/data/analise_texto_client_http.dart';
import 'package:phize/features/analise/data/reputacao_dominio_client_http.dart'
    show ObterTokenId;
import 'package:phize/features/analise/domain/analise_texto_client.dart';

const _texto = 'Oi mãe, troquei de número. Me manda um Pix para [CHAVE_PIX]';

/// Function simulada: nenhum teste deste arquivo acessa a rede.
AnaliseTextoClientHttp _cliente(
  MockClientHandler function, {
  ObterTokenId? obterToken,
}) => AnaliseTextoClientHttp(
  obterToken: obterToken ?? () async => 'token-de-teste',
  clienteHttp: MockClient(function),
  endpoint: Uri.parse('http://function.test/analiseTexto'),
);

MockClientHandler _responde(Object corpo, {int status = 200}) =>
    (_) async => http.Response(
      corpo is String ? corpo : jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Nenhuma exceção pode carregar o texto analisado.
Matcher _semOTexto = isNot(
  predicate<Object>((e) => e.toString().contains('troquei')),
);

void main() {
  test('envia o token e o texto no corpo, nunca na URL da chamada', () async {
    late http.Request enviada;
    final cliente = _cliente((req) async {
      enviada = req;
      return http.Response('{"status":"nao_concluida","motivo":"x"}', 200);
    });

    await cliente.analisar(_texto);

    expect(enviada.method, 'POST');
    expect(enviada.headers['Authorization'], 'Bearer token-de-teste');
    expect(jsonDecode(enviada.body), {'texto': _texto});
    expect(enviada.url.toString(), isNot(contains('troquei')));
  });

  test('devolve o corpo decodificado', () async {
    final corpo = {
      'status': 'concluida',
      'analise': {'sinais': <String>[], 'categoria': 'sem_indicios'},
    };
    final r = await _cliente(_responde(corpo)).analisar(_texto);
    expect(r, corpo);
  });

  test('sem sessão: não autenticado, sem chamada de rede', () async {
    var chamou = false;
    final cliente = _cliente((_) async {
      chamou = true;
      return http.Response('{}', 200);
    }, obterToken: () async => null);

    await expectLater(
      cliente.analisar(_texto),
      throwsA(isA<AnaliseTextoNaoAutenticadoException>()),
    );
    expect(chamou, isFalse);
  });

  final casos = <String, (MockClientHandler, Matcher)>{
    '401': (
      _responde({'erro': 'nao_autenticado'}, status: 401),
      isA<AnaliseTextoNaoAutenticadoException>(),
    ),
    '429': (
      _responde({'erro': 'limite_excedido'}, status: 429),
      isA<AnaliseTextoLimiteExcedidoException>(),
    ),
    '500': (
      _responde('erro', status: 500),
      isA<AnaliseTextoIndisponivelException>(),
    ),
    'corpo não JSON': (
      _responde('<html>'),
      isA<AnaliseTextoIndisponivelException>(),
    ),
    'corpo JSON que não é objeto': (
      _responde('[1, 2]'),
      isA<AnaliseTextoIndisponivelException>(),
    ),
    'falha de conexão': (
      (_) async => throw http.ClientException('sem rede: $_texto'),
      isA<AnaliseTextoIndisponivelException>(),
    ),
  };
  for (final MapEntry(key: nome, value: (handler, tipo)) in casos.entries) {
    test('$nome: exceção declarada, sem o texto na mensagem', () async {
      await expectLater(
        _cliente(handler).analisar(_texto),
        throwsA(allOf(tipo, _semOTexto)),
      );
    });
  }

  test('endereço padrão aponta para a Function analiseTexto', () {
    expect(ProxyConfig.analiseTexto.path, endsWith('/analiseTexto'));
  });
}

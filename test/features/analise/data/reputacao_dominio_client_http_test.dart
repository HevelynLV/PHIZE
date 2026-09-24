import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phize/core/config/proxy_config.dart';
import 'package:phize/features/analise/data/reputacao_dominio_client_http.dart';
import 'package:phize/features/analise/domain/consulta_reputacao_dominio.dart';
import 'package:phize/features/analise/domain/reputacao_dominio_client.dart';
import 'package:phize/features/analise/domain/resultado_consulta_reputacao.dart';

const _dominio = 'golpe-exemplo.com.br';
const _url = 'https://golpe-exemplo.com.br/banco/login';

/// Function simulada: nenhum teste deste arquivo acessa a rede.
ReputacaoDominioClientHttp _cliente(
  MockClientHandler function, {
  ObterTokenId? obterToken,
}) => ReputacaoDominioClientHttp(
  obterToken: obterToken ?? () async => 'token-de-teste',
  clienteHttp: MockClient(function),
  endpoint: Uri.parse('http://function.test/reputacaoDominio'),
);

MockClientHandler _responde(Object corpo, {int status = 200}) =>
    (_) async => http.Response(
      corpo is String ? corpo : jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<ResultadoConsultaReputacao> _consultar(ReputacaoDominioClient c) =>
    ConsultaReputacaoDominio(c).consultar(_url);

void main() {
  test('envia o token e a URL no corpo, nunca na URL da chamada', () async {
    late http.Request enviada;
    final cliente = _cliente((req) async {
      enviada = req;
      return http.Response('{"status":"nao_listado"}', 200);
    });

    await cliente.consultarUrl(_url);

    expect(enviada.method, 'POST');
    expect(enviada.headers['Authorization'], 'Bearer token-de-teste');
    expect(jsonDecode(enviada.body), {'url': _url});
    expect(enviada.url.toString(), isNot(contains(_dominio)));
  });

  test('domínio listado como malicioso', () async {
    final resultado = await _consultar(
      _cliente(
        _responde({
          'status': 'listado',
          'tiposAmeaca': ['SOCIAL_ENGINEERING', 'MALWARE'],
        }),
      ),
    );

    expect(resultado.status, StatusConsultaReputacao.listado);
    expect(resultado.tiposAmeaca, ['SOCIAL_ENGINEERING', 'MALWARE']);
  });

  test('domínio não listado', () async {
    final resultado = await _consultar(
      _cliente(_responde({'status': 'nao_listado'})),
    );

    expect(resultado.status, StatusConsultaReputacao.naoListado);
  });

  group('Function indisponível: verificação não concluída', () {
    for (final status in [500, 503, 404, 400]) {
      test('HTTP $status', () async {
        final resultado = await _consultar(
          _cliente(_responde({'erro': 'x'}, status: status)),
        );
        expect(resultado.status, StatusConsultaReputacao.naoConcluida);
      });
    }

    test('falha de conexão (emulador desligado)', () async {
      final resultado = await _consultar(
        _cliente((_) async => throw http.ClientException('Connection refused')),
      );
      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    });

    test('corpo que não é JSON', () async {
      final resultado = await _consultar(_cliente(_responde('<html>')));
      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    });

    test('JSON que não é objeto', () async {
      final resultado = await _consultar(_cliente(_responde([1, 2])));
      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    });
  });

  test('timeout: verificação não concluída', () async {
    final resultado = await _consultar(
      _cliente(
        (_) => Future.delayed(
          const Duration(seconds: 10),
          () => http.Response('{"status":"nao_listado"}', 200),
        ),
      ),
    );

    expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    expect(resultado.motivoNaoConcluida, contains('tempo limite'));
  }, timeout: const Timeout(Duration(seconds: 10)));

  group('usuário não autenticado: erro tratado, sem travar o app', () {
    test('sem sessão: não chama a Function', () async {
      var chamou = false;
      final resultado = await _consultar(
        _cliente((_) async {
          chamou = true;
          return http.Response('{"status":"nao_listado"}', 200);
        }, obterToken: () async => null),
      );

      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
      expect(resultado.motivoNaoConcluida, contains('sessão'));
      expect(chamou, isFalse);
    });

    test('falha ao obter o token', () async {
      final resultado = await _consultar(
        _cliente(
          _responde({'status': 'nao_listado'}),
          obterToken: () async => throw StateError('token expirado'),
        ),
      );
      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    });

    test('Function rejeita o token (HTTP 401)', () async {
      final resultado = await _consultar(
        _cliente(_responde({'erro': 'nao_autenticado'}, status: 401)),
      );

      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
      expect(resultado.motivoNaoConcluida, contains('sessão'));
    });
  });

  test('limite por usuário excedido (HTTP 429): não concluída', () async {
    final resultado = await _consultar(
      _cliente(_responde({'erro': 'limite_excedido'}, status: 429)),
    );
    expect(resultado.status, StatusConsultaReputacao.naoConcluida);
  });

  test('exceções do cliente não carregam a URL nem o domínio', () async {
    final falhas = <MockClientHandler>[
      (_) async => throw http.ClientException('falha em $_url'),
      _responde({'erro': 'x'}, status: 503),
      _responde('<html>'),
    ];

    for (final falha in falhas) {
      try {
        await _cliente(falha).consultarUrl(_url);
        fail('deveria ter lançado');
      } on ReputacaoIndisponivelException catch (e) {
        expect(e.motivo, isNot(contains(_dominio)));
      }
    }
  });

  test('nenhum caso lança exceção para quem chama', () async {
    final cenarios = <ReputacaoDominioClient>[
      _cliente((_) async => throw Exception('qualquer')),
      _cliente(_responde('', status: 200)),
      _cliente(_responde({'status': 'nao_concluida'}, status: 200)),
      _cliente(_responde({}, status: 502)),
      _cliente(_responde({}), obterToken: () async => ''),
    ];

    for (final cliente in cenarios) {
      await expectLater(_consultar(cliente), completes);
    }
  });

  test('endereço padrão aponta para o emulador nesta fase', () {
    expect(ProxyConfig.urlBase, ProxyConfig.urlEmulador);
    expect(
      ProxyConfig.reputacaoDominio.toString(),
      'http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio',
    );
  });

  group('o que chega à Function (normalização no dispositivo)', () {
    Future<String> urlEnviada(String entrada) async {
      late String enviada;
      final cliente = _cliente((req) async {
        enviada = (jsonDecode(req.body) as Map<String, dynamic>)['url'];
        return http.Response('{"status":"nao_listado"}', 200);
      });
      await ConsultaReputacaoDominio(cliente).consultar(entrada);
      return enviada;
    }

    test('URL com query: a query não chega à Function', () async {
      const entrada =
          'https://golpe-exemplo.com.br/login?cpf=12345678900&email=a@b.com';
      late String corpoBruto;
      final cliente = _cliente((req) async {
        corpoBruto = req.body;
        return http.Response('{"status":"nao_listado"}', 200);
      });

      await ConsultaReputacaoDominio(cliente).consultar(entrada);

      expect(jsonDecode(corpoBruto), {
        'url': 'https://golpe-exemplo.com.br/login',
      });
      expect(corpoBruto, isNot(contains('?')));
      expect(corpoBruto, isNot(contains('12345678900')));
      expect(corpoBruto, isNot(contains('a@b.com')));
    });

    test('URL com fragmento: o fragmento não chega à Function', () async {
      final enviada = await urlEnviada(
        'https://golpe-exemplo.com.br/pagar#token=abc123',
      );

      expect(enviada, 'https://golpe-exemplo.com.br/pagar');
      expect(enviada, isNot(contains('#')));
      expect(enviada, isNot(contains('abc123')));
    });

    test('URL com caminho: o caminho é preservado', () async {
      final enviada = await urlEnviada(
        'https://site-legitimo.com.br/wp-content/banco/login.php',
      );

      expect(
        enviada,
        'https://site-legitimo.com.br/wp-content/banco/login.php',
      );
    });

    test('URL sem caminho: funciona normalmente', () async {
      expect(
        await urlEnviada('golpe-exemplo.com.br'),
        'http://golpe-exemplo.com.br/',
      );
      expect(
        await urlEnviada('https://golpe-exemplo.com.br'),
        'https://golpe-exemplo.com.br/',
      );
    });

    test('entrada inválida: não chama a Function e não trava', () async {
      var chamou = false;
      final cliente = _cliente((_) async {
        chamou = true;
        return http.Response('{"status":"nao_listado"}', 200);
      });

      final resultado = await ConsultaReputacaoDominio(cliente)
          .consultar('isto não é endereço');

      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
      expect(chamou, isFalse);
    });
  });
}

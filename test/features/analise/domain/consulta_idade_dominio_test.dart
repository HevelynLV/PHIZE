import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/consulta_idade_dominio.dart';
import 'package:phize/features/analise/domain/rdap_client.dart';
import 'package:phize/features/analise/domain/resultado_consulta_dominio.dart';
import 'package:phize/features/analise/domain/score_config.dart';

class _RdapClientFalso implements RdapClient {
  _RdapClientFalso.comResposta(Map<String, dynamic> resposta)
    : _resposta = resposta,
      _erro = null,
      _semResposta = false;

  _RdapClientFalso.comErro(Object erro)
    : _resposta = null,
      _erro = erro,
      _semResposta = false;

  _RdapClientFalso.semResponder()
    : _resposta = null,
      _erro = null,
      _semResposta = true;

  final Map<String, dynamic>? _resposta;
  final Object? _erro;
  final bool _semResposta;

  @override
  Future<Map<String, dynamic>> consultarDominio(String dominioNormalizado) {
    // Mais lento que ConsultaIdadeDominio.timeoutConsulta (5s), para
    // acionar o timeout real do orquestrador — mas ainda resolve por conta
    // própria depois, em vez de nunca completar (o que deixaria uma
    // Future pendente para sempre nesse isolate de teste).
    if (_semResposta) {
      return Future.delayed(
        const Duration(seconds: 10),
        () => <String, dynamic>{},
      );
    }
    final erro = _erro;
    if (erro != null) return Future.error(erro);
    return Future.value(_resposta);
  }
}

Map<String, dynamic> _respostaComRegistro(DateTime data) => {
  'events': [
    {'eventAction': 'registration', 'eventDate': data.toIso8601String()},
  ],
};

void main() {
  group('Domínio recém-criado', () {
    test('registrado há 2 dias: recém-criado, consulta concluída', () async {
      final agora = DateTime(2026, 9, 22);
      final dataRegistro = agora.subtract(const Duration(days: 2));
      final cliente = _RdapClientFalso.comResposta(
        _respostaComRegistro(dataRegistro),
      );
      final consulta = ConsultaIdadeDominio(cliente, agora: () => agora);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.status, StatusConsultaDominio.concluida);
      expect(resultado.dominioRecente, isTrue);
      expect(resultado.dataRegistro, dataRegistro);
    });

    test('registrado há 5 anos: não recém-criado, consulta concluída', () async {
      final agora = DateTime(2026, 9, 22);
      final cliente = _RdapClientFalso.comResposta(
        _respostaComRegistro(agora.subtract(const Duration(days: 365 * 5))),
      );
      final consulta = ConsultaIdadeDominio(cliente, agora: () => agora);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.status, StatusConsultaDominio.concluida);
      expect(resultado.dominioRecente, isFalse);
    });
  });

  group('Limite de calibragem (docs/score-calibracao.md)', () {
    test('exatamente no limite não é recém-criado', () async {
      final agora = DateTime(2026, 9, 22);
      final cliente = _RdapClientFalso.comResposta(
        _respostaComRegistro(
          agora.subtract(
            const Duration(days: ScoreConfig.dominioRecenteLimiteDias),
          ),
        ),
      );
      final consulta = ConsultaIdadeDominio(cliente, agora: () => agora);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.dominioRecente, isFalse);
    });

    test('um dia antes do limite é recém-criado', () async {
      final agora = DateTime(2026, 9, 22);
      final cliente = _RdapClientFalso.comResposta(
        _respostaComRegistro(
          agora.subtract(
            const Duration(days: ScoreConfig.dominioRecenteLimiteDias - 1),
          ),
        ),
      );
      final consulta = ConsultaIdadeDominio(cliente, agora: () => agora);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.dominioRecente, isTrue);
    });

    test('um dia depois do limite não é recém-criado', () async {
      final agora = DateTime(2026, 9, 22);
      final cliente = _RdapClientFalso.comResposta(
        _respostaComRegistro(
          agora.subtract(
            const Duration(days: ScoreConfig.dominioRecenteLimiteDias + 1),
          ),
        ),
      );
      final consulta = ConsultaIdadeDominio(cliente, agora: () => agora);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.dominioRecente, isFalse);
    });
  });

  group('Domínio inexistente', () {
    test(
      'consulta concluída, sem data, não marcado como recém-criado',
      () async {
        final cliente = _RdapClientFalso.comErro(
          const RdapDominioInexistenteException(),
        );
        final consulta = ConsultaIdadeDominio(cliente);

        final resultado = await consulta.consultar('nao-existe-exemplo.com.br');

        expect(resultado.status, StatusConsultaDominio.concluida);
        expect(resultado.dataRegistro, isNull);
        expect(resultado.dominioRecente, isFalse);
      },
    );
  });

  group('Verificação não concluída', () {
    test('serviço RDAP indisponível', () async {
      final cliente = _RdapClientFalso.comErro(
        const RdapIndisponivelException('fora do ar'),
      );
      final consulta = ConsultaIdadeDominio(cliente);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.status, StatusConsultaDominio.naoConcluida);
      expect(resultado.motivoNaoConcluida, isNotNull);
    });

    test(
      'timeout',
      () async {
        final cliente = _RdapClientFalso.semResponder();
        final consulta = ConsultaIdadeDominio(cliente);

        final resultado = await consulta.consultar('exemplo.com.br');

        expect(resultado.status, StatusConsultaDominio.naoConcluida);
        expect(resultado.motivoNaoConcluida, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('resposta sem campo de data', () async {
      final cliente = _RdapClientFalso.comResposta(<String, dynamic>{});
      final consulta = ConsultaIdadeDominio(cliente);

      final resultado = await consulta.consultar('exemplo.com.br');

      expect(resultado.status, StatusConsultaDominio.naoConcluida);
      expect(resultado.motivoNaoConcluida, isNotNull);
    });
  });

  group('Nunca lança exceção', () {
    test(
      'nenhum caso de falha lança exceção para quem chama',
      () async {
        final cenarios = <RdapClient>[
          _RdapClientFalso.comErro(
            const RdapIndisponivelException('fora do ar'),
          ),
          _RdapClientFalso.comErro(const RdapDominioInexistenteException()),
          _RdapClientFalso.semResponder(),
          _RdapClientFalso.comResposta(<String, dynamic>{}),
          _RdapClientFalso.comErro(Exception('erro genérico não mapeado')),
        ];

        for (final cliente in cenarios) {
          final consulta = ConsultaIdadeDominio(cliente);
          await expectLater(consulta.consultar('exemplo.com.br'), completes);
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Determinismo', () {
    test('mesma resposta simulada produz sempre o mesmo resultado', () async {
      final agora = DateTime(2026, 9, 22);
      final dataRegistro = agora.subtract(const Duration(days: 2));

      Future<ResultadoConsultaDominio> executar() => ConsultaIdadeDominio(
        _RdapClientFalso.comResposta(_respostaComRegistro(dataRegistro)),
        agora: () => agora,
      ).consultar('exemplo.com.br');

      final primeira = await executar();
      final segunda = await executar();
      final terceira = await executar();

      expect(segunda.status, primeira.status);
      expect(segunda.dominioRecente, primeira.dominioRecente);
      expect(segunda.dataRegistro, primeira.dataRegistro);
      expect(terceira.status, primeira.status);
      expect(terceira.dominioRecente, primeira.dominioRecente);
      expect(terceira.dataRegistro, primeira.dataRegistro);
    });
  });
}

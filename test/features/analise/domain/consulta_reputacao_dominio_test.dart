import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/consulta_reputacao_dominio.dart';
import 'package:phize/features/analise/domain/reputacao_dominio_client.dart';
import 'package:phize/features/analise/domain/resultado_consulta_reputacao.dart';

class _ReputacaoClientFalso implements ReputacaoDominioClient {
  _ReputacaoClientFalso.comResposta(Map<String, dynamic> resposta)
    : _resposta = resposta,
      _erro = null,
      _semResponder = false;

  _ReputacaoClientFalso.comErro(Object erro)
    : _resposta = null,
      _erro = erro,
      _semResponder = false;

  _ReputacaoClientFalso.semResponder()
    : _resposta = null,
      _erro = null,
      _semResponder = true;

  final Map<String, dynamic>? _resposta;
  final Object? _erro;
  final bool _semResponder;

  @override
  Future<Map<String, dynamic>> consultarUrl(String urlNormalizada) {
    // Mais lento que ConsultaReputacaoDominio.timeoutConsulta (5s), para
    // acionar o timeout real — mas resolve depois, sem deixar Future
    // pendente para sempre.
    if (_semResponder) {
      return Future.delayed(
        const Duration(seconds: 10),
        () => <String, dynamic>{'status': 'nao_listado'},
      );
    }
    final erro = _erro;
    if (erro != null) return Future.error(erro);
    return Future.value(_resposta);
  }
}

Future<ResultadoConsultaReputacao> _consultar(ReputacaoDominioClient c) =>
    ConsultaReputacaoDominio(c).consultar('exemplo.com.br');

void main() {
  test('domínio listado como malicioso', () async {
    final resultado = await _consultar(
      _ReputacaoClientFalso.comResposta({
        'status': 'listado',
        'tiposAmeaca': ['SOCIAL_ENGINEERING'],
      }),
    );

    expect(resultado.status, StatusConsultaReputacao.listado);
    expect(resultado.tiposAmeaca, ['SOCIAL_ENGINEERING']);
    expect(resultado.motivoNaoConcluida, isNull);
  });

  test('domínio não listado', () async {
    final resultado = await _consultar(
      _ReputacaoClientFalso.comResposta({'status': 'nao_listado'}),
    );

    expect(resultado.status, StatusConsultaReputacao.naoListado);
    expect(resultado.tiposAmeaca, isEmpty);
    expect(resultado.motivoNaoConcluida, isNull);
  });

  test('Function indisponível: verificação não concluída', () async {
    final resultado = await _consultar(
      _ReputacaoClientFalso.comErro(
        const ReputacaoIndisponivelException('status 503'),
      ),
    );

    expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    expect(resultado.motivoNaoConcluida, contains('Safe Browsing'));
  });

  test(
    'timeout: verificação não concluída',
    () async {
      final resultado = await _consultar(
        _ReputacaoClientFalso.semResponder(),
      );

      expect(resultado.status, StatusConsultaReputacao.naoConcluida);
      expect(resultado.motivoNaoConcluida, contains('tempo limite'));
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test('usuário não autenticado: não concluída, com orientação', () async {
    final resultado = await _consultar(
      _ReputacaoClientFalso.comErro(const ReputacaoNaoAutenticadoException()),
    );

    expect(resultado.status, StatusConsultaReputacao.naoConcluida);
    expect(resultado.motivoNaoConcluida, contains('sessão'));
  });

  test('limite de requisições excedido: não concluída', () async {
    final resultado = await _consultar(
      _ReputacaoClientFalso.comErro(const ReputacaoLimiteExcedidoException()),
    );

    expect(resultado.status, StatusConsultaReputacao.naoConcluida);
  });

  group('não concluída informada pela própria Function', () {
    for (final motivo in [
      'chave_ausente',
      'indisponivel',
      'timeout',
      'resposta_inesperada',
      'motivo_desconhecido',
    ]) {
      test(motivo, () async {
        final resultado = await _consultar(
          _ReputacaoClientFalso.comResposta({
            'status': 'nao_concluida',
            'motivo': motivo,
          }),
        );

        expect(resultado.status, StatusConsultaReputacao.naoConcluida);
        expect(resultado.motivoNaoConcluida, isNotEmpty);
        // A falta de chave é detalhe de servidor, não do usuário.
        expect(resultado.motivoNaoConcluida, isNot(contains('chave')));
      });
    }
  });

  test('formato inesperado nunca vira "não listado"', () async {
    for (final resposta in <Map<String, dynamic>>[
      {},
      {'status': 'outro'},
      {'status': null},
      {'matches': []},
    ]) {
      final resultado = await _consultar(
        _ReputacaoClientFalso.comResposta(resposta),
      );
      expect(
        resultado.status,
        StatusConsultaReputacao.naoConcluida,
        reason: '$resposta',
      );
    }
  });

  test('nenhum caso lança exceção para quem chama', () async {
    final clientes = [
      _ReputacaoClientFalso.comErro(const ReputacaoIndisponivelException('x')),
      _ReputacaoClientFalso.comErro(const ReputacaoNaoAutenticadoException()),
      _ReputacaoClientFalso.comErro(const ReputacaoLimiteExcedidoException()),
      _ReputacaoClientFalso.comErro(StateError('erro não mapeado')),
      _ReputacaoClientFalso.comErro(const FormatException('json')),
      _ReputacaoClientFalso.comErro('erro que nem é Exception'),
      _ReputacaoClientFalso.comResposta({'status': 'listado'}),
      _ReputacaoClientFalso.comResposta({
        'status': 'listado',
        'tiposAmeaca': 'não é lista',
      }),
    ];

    for (final cliente in clientes) {
      await expectLater(_consultar(cliente), completes);
    }
  });
}

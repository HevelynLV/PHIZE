import 'dart:async';

import 'normalizacao_url.dart';
import 'reputacao_dominio_client.dart';
import 'resultado_consulta_reputacao.dart';

/// Consulta de reputação de domínio no Google Safe Browsing, via camada
/// intermediária (RF03/UC03; arquitetura, seção 4, etapa 2). Nunca lança
/// exceção para quem a chama: qualquer falha (Function indisponível,
/// timeout, usuário não autenticado, resposta em formato inesperado) vira
/// status de verificação não concluída, sem interromper a análise
/// (CLAUDE.md, Seção 8 — Degradação Controlada).
class ConsultaReputacaoDominio {
  ConsultaReputacaoDominio(this._client);

  final ReputacaoDominioClient _client;

  /// Alinhado ao RNF03 (latência máxima de 5 segundos): a consulta nunca
  /// pode segurar a análise além desse limite.
  static const Duration timeoutConsulta = Duration(seconds: 5);

  static const String _motivoIndisponivel =
      'O Google Safe Browsing não pôde ser consultado agora.';

  /// [entrada] é o endereço como o usuário o informou. A normalização
  /// (domínio e caminho, sem query nem fragmento — ver
  /// `normalizarUrlReputacao`) acontece aqui, no dispositivo, antes de
  /// qualquer transmissão.
  Future<ResultadoConsultaReputacao> consultar(String entrada) async {
    final urlNormalizada = normalizarUrlReputacao(entrada);
    if (urlNormalizada == null) {
      return _naoConcluida(
        'O endereço informado não pôde ser preparado para a consulta ao '
        'Google Safe Browsing.',
      );
    }

    try {
      final resposta = await _client
          .consultarUrl(urlNormalizada)
          .timeout(timeoutConsulta);
      return _interpretar(resposta);
    } on TimeoutException {
      return _naoConcluida(
        'A consulta ao Google Safe Browsing excedeu o tempo limite de '
        'espera.',
      );
    } on ReputacaoNaoAutenticadoException {
      return _naoConcluida(
        'Não foi possível confirmar sua sessão para consultar o Google '
        'Safe Browsing. Entre novamente no aplicativo.',
      );
    } on ReputacaoLimiteExcedidoException {
      return _naoConcluida(
        'Muitas consultas ao Google Safe Browsing em pouco tempo. Tente '
        'novamente em alguns instantes.',
      );
    } on ReputacaoIndisponivelException {
      return _naoConcluida(_motivoIndisponivel);
    } catch (_) {
      // Rede de segurança: qualquer falha não mapeada acima também vira
      // verificação não concluída — nunca uma exceção propagada.
      return _naoConcluida(_motivoIndisponivel);
    }
  }

  /// Contrato da Function `reputacaoDominio` (functions/src/index.ts).
  /// Qualquer formato fora do contrato é tratado como não concluído —
  /// nunca como "não listado".
  static ResultadoConsultaReputacao _interpretar(
    Map<String, dynamic> resposta,
  ) {
    switch (resposta['status']) {
      case 'listado':
        final tipos = resposta['tiposAmeaca'];
        return ResultadoConsultaReputacao(
          status: StatusConsultaReputacao.listado,
          tiposAmeaca: tipos is List
              ? List.unmodifiable(tipos.whereType<String>())
              : const [],
        );
      case 'nao_listado':
        return const ResultadoConsultaReputacao(
          status: StatusConsultaReputacao.naoListado,
        );
      case 'nao_concluida':
        return _naoConcluida(switch (resposta['motivo']) {
          'timeout' =>
            'A consulta ao Google Safe Browsing excedeu o tempo limite de '
                'espera.',
          'resposta_inesperada' =>
            'O Google Safe Browsing respondeu em um formato não '
                'reconhecido.',
          _ => _motivoIndisponivel,
        });
      default:
        return _naoConcluida(
          'O Google Safe Browsing respondeu em um formato não reconhecido.',
        );
    }
  }

  static ResultadoConsultaReputacao _naoConcluida(String motivo) =>
      ResultadoConsultaReputacao(
        status: StatusConsultaReputacao.naoConcluida,
        motivoNaoConcluida: motivo,
      );
}

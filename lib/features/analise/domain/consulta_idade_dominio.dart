import 'dart:async';

import 'rdap_client.dart';
import 'resultado_consulta_dominio.dart';
import 'score_config.dart';

/// Consulta de idade de registro do domínio via RDAP (RF03/UC03;
/// arquitetura, seção 4, item 3). Nunca lança exceção para quem a chama:
/// qualquer falha (indisponibilidade, timeout, resposta em formato
/// inesperado ou sem data de registro) vira status de verificação não
/// concluída, sem interromper a análise (CLAUDE.md, Seção 8 — Degradação
/// Controlada). O limite de "domínio recém-criado" vem de
/// `ScoreConfig.dominioRecenteLimiteDias`, que espelha
/// `docs/score-calibracao.md` — nunca redefinido aqui.
class ConsultaIdadeDominio {
  ConsultaIdadeDominio(this._client, {DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  final RdapClient _client;
  final DateTime Function() _agora;

  /// Alinhado ao RNF03 (latência máxima de 5 segundos): a consulta nunca
  /// pode segurar a análise além desse limite.
  static const Duration timeoutConsulta = Duration(seconds: 5);

  Future<ResultadoConsultaDominio> consultar(String dominioNormalizado) async {
    try {
      final resposta = await _client
          .consultarDominio(dominioNormalizado)
          .timeout(timeoutConsulta);

      // Validação de identidade da resposta. O Registro.br responde com
      // redirecionamento (HTTP 303) para domínios de nome parecido — ex.:
      // "itau-seguranca.com.br" é redirecionado para
      // "itauseguranca.com.br", registrado em 2009 — e o cliente HTTP segue
      // o redirecionamento (ver `RdapClientHttp`). Aceitar a resposta
      // cegamente atribuiria ao endereço analisado a data de registro de
      // OUTRO domínio, anulando o sinal de domínio recém-criado: justamente
      // o sinal que a seção 4 da arquitetura usa para cobrir a lacuna do
      // Safe Browsing em domínios novos. Resposta sem `ldhName` também é
      // rejeitada: sem ele não há como confirmar a qual domínio a data
      // pertence.
      final ldhName = resposta['ldhName'];
      if (ldhName is! String ||
          _normalizarFqdn(ldhName) != _normalizarFqdn(dominioNormalizado)) {
        return const ResultadoConsultaDominio(
          status: StatusConsultaDominio.naoConcluida,
          motivoNaoConcluida:
              'O RDAP respondeu com os dados de outro endereço, não do '
              'endereço analisado.',
        );
      }

      final dataRegistro = _extrairDataRegistro(resposta);
      if (dataRegistro == null) {
        return const ResultadoConsultaDominio(
          status: StatusConsultaDominio.naoConcluida,
          motivoNaoConcluida:
              'A resposta do RDAP não trouxe uma data de registro '
              'reconhecível.',
        );
      }

      final diasDesdeRegistro = _agora().difference(dataRegistro).inDays;
      return ResultadoConsultaDominio(
        status: StatusConsultaDominio.concluida,
        dataRegistro: dataRegistro,
        dominioRecente:
            diasDesdeRegistro < ScoreConfig.dominioRecenteLimiteDias,
      );
    } on RdapDominioInexistenteException {
      // Resposta definitiva do RDAP: o domínio não está registrado. A
      // consulta foi concluída com sucesso — só não há data nem sinal de
      // "recém-criado" para atribuir.
      return const ResultadoConsultaDominio(
        status: StatusConsultaDominio.concluida,
      );
    } on TimeoutException {
      return const ResultadoConsultaDominio(
        status: StatusConsultaDominio.naoConcluida,
        motivoNaoConcluida:
            'A consulta ao RDAP excedeu o tempo limite de espera.',
      );
    } on RdapIndisponivelException {
      return const ResultadoConsultaDominio(
        status: StatusConsultaDominio.naoConcluida,
        motivoNaoConcluida: 'O serviço RDAP não pôde ser consultado agora.',
      );
    } catch (_) {
      // Rede de segurança: qualquer falha não mapeada pelas cláusulas
      // acima também vira verificação não concluída — nunca uma exceção
      // propagada a quem chamou.
      return const ResultadoConsultaDominio(
        status: StatusConsultaDominio.naoConcluida,
        motivoNaoConcluida: 'Não foi possível concluir a consulta ao RDAP.',
      );
    }
  }

  /// Forma canônica de um nome de domínio para comparação: sem diferença de
  /// maiúsculas e sem o ponto final do FQDN ("Itau.com.br." == "itau.com.br").
  static String _normalizarFqdn(String dominio) {
    final minusculo = dominio.toLowerCase();
    return minusculo.endsWith('.')
        ? minusculo.substring(0, minusculo.length - 1)
        : minusculo;
  }

  static DateTime? _extrairDataRegistro(Map<String, dynamic> resposta) {
    final eventos = resposta['events'];
    if (eventos is! List) return null;

    for (final evento in eventos) {
      if (evento is! Map) continue;
      if (evento['eventAction'] != 'registration') continue;
      final dataBruta = evento['eventDate'];
      if (dataBruta is! String) continue;
      final data = DateTime.tryParse(dataBruta);
      if (data != null) return data;
    }
    return null;
  }
}

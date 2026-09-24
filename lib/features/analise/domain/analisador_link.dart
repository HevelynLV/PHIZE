import 'analisador_typosquatting.dart';
import 'calculadora_score.dart';
import 'consulta_idade_dominio.dart';
import 'marcas_conhecidas.dart';
import 'resultado_analise_dominio.dart';
import 'resultado_analise_link.dart';
import 'resultado_consulta_dominio.dart';
import 'score_config.dart';
import 'sinais_identificados.dart';
import 'sinal_link.dart';
import 'verificacao_link.dart';

/// Orquestra a análise de link do UC03: normalização e anatomia da URL
/// (typosquatting), idade do domínio via RDAP e conversão dos sinais
/// encontrados em entrada do motor de score (RF07). Não calcula pesos:
/// apenas decide quais [SinalLink] estão presentes e delega a pontuação a
/// [CalculadoraScore].
///
/// A consulta de reputação (Google Safe Browsing) ainda não é executada —
/// entra na Fase 5 (docs/ROADMAP.md, Fase 4.3). Até lá ela aparece sempre
/// como verificação não concluída, o que, pela regra de verificação
/// incompleta de `docs/score-calibracao.md`, impede a faixa verde.
class AnalisadorLink {
  AnalisadorLink(this._consultaIdadeDominio);

  final ConsultaIdadeDominio _consultaIdadeDominio;

  static const String _fonteAnatomia =
      'Phize, comparando o endereço com uma lista de endereços oficiais '
      'de bancos e serviços conhecidos';
  static const String _fonteRdap =
      'Cadastro público de domínios na internet (RDAP)';
  static const String _fonteReputacao = 'Google Safe Browsing';

  /// Devolve `null` quando [entrada] não é uma URL/domínio válido — quem
  /// chama deve pedir o reenvio (UC03, fluxo de exceção "Formato
  /// inválido"). Nunca lança exceção: falhas de fontes externas viram
  /// verificação não concluída (CLAUDE.md, Seção 8).
  Future<ResultadoAnaliseLink?> analisar(String entrada) async {
    final anatomia = AnalisadorTyposquatting.analisar(entrada);
    if (!anatomia.entradaValida) return null;

    final idade = await _consultaIdadeDominio.consultar(
      anatomia.dominioRegistravel!,
    );

    final verificacoes = [
      _verificacaoAnatomia(anatomia),
      _verificacaoIdade(idade),
      _verificacaoReputacao(),
    ];

    final sinais = SinaisIdentificados(
      link: {
        if (anatomia.typosquattingDetectado) SinalLink.typosquatting,
        if (idade.dominioRecente) SinalLink.dominioRecemCriado,
      },
      verificacaoIncompleta: verificacoes.any(
        (v) => v.status == StatusVerificacao.naoConcluida,
      ),
    );

    return ResultadoAnaliseLink(
      score: CalculadoraScore.calcular(sinais),
      verificacoes: verificacoes,
    );
  }

  static VerificacaoLink _verificacaoAnatomia(
    ResultadoAnaliseDominio anatomia,
  ) {
    const titulo = 'Imitação de endereço conhecido';
    if (!anatomia.typosquattingDetectado) {
      return const VerificacaoLink(
        titulo: titulo,
        descricao:
            'O endereço não se parece com o de nenhum banco ou serviço da '
            'nossa lista de instituições conhecidas.',
        fonte: _fonteAnatomia,
        status: StatusVerificacao.semSinal,
      );
    }

    final dominioOficial = marcasConhecidas
        .firstWhere((m) => m.nome == anatomia.marcaImitada)
        .dominioOficial;
    return VerificacaoLink(
      titulo: titulo,
      descricao:
          'O endereço se parece com $dominioOficial, mas não é o endereço '
          'oficial. Golpistas usam nomes parecidos para enganar.',
      fonte: _fonteAnatomia,
      status: StatusVerificacao.sinalEncontrado,
    );
  }

  static VerificacaoLink _verificacaoIdade(ResultadoConsultaDominio idade) {
    const titulo = 'Tempo de existência do endereço';
    const limite = ScoreConfig.dominioRecenteLimiteDias;

    if (idade.status == StatusConsultaDominio.naoConcluida) {
      final motivo = idade.motivoNaoConcluida;
      return VerificacaoLink(
        titulo: titulo,
        descricao: [
          'Não foi possível descobrir há quanto tempo o endereço existe.',
          ?motivo,
        ].join(' '),
        fonte: _fonteRdap,
        status: StatusVerificacao.naoConcluida,
      );
    }

    final dataRegistro = idade.dataRegistro;
    if (dataRegistro == null) {
      return const VerificacaoLink(
        titulo: titulo,
        descricao:
            'O endereço não aparece no cadastro público de domínios, então '
            'não há data de criação para avaliar.',
        fonte: _fonteRdap,
        status: StatusVerificacao.semSinal,
      );
    }

    final data = _formatarData(dataRegistro);
    if (idade.dominioRecente) {
      return VerificacaoLink(
        titulo: titulo,
        descricao:
            'O endereço foi criado há menos de $limite dias (em $data). '
            'Golpes costumam usar endereços novos, que duram pouco tempo.',
        fonte: _fonteRdap,
        status: StatusVerificacao.sinalEncontrado,
      );
    }
    return VerificacaoLink(
      titulo: titulo,
      descricao: 'O endereço existe há mais de $limite dias (criado em $data).',
      fonte: _fonteRdap,
      status: StatusVerificacao.semSinal,
    );
  }

  static VerificacaoLink _verificacaoReputacao() {
    return const VerificacaoLink(
      titulo: 'Lista de endereços perigosos',
      descricao:
          'A consulta à lista de endereços já denunciados como perigosos '
          'ainda não está disponível nesta versão do aplicativo.',
      fonte: _fonteReputacao,
      status: StatusVerificacao.naoConcluida,
    );
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

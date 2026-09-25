import 'dart:async';

import 'analisador_typosquatting.dart';
import 'calculadora_score.dart';
import 'consulta_idade_dominio.dart';
import 'consulta_reputacao_dominio.dart';
import 'marcas_conhecidas.dart';
import 'resultado_analise_dominio.dart';
import 'resultado_analise_link.dart';
import 'resultado_consulta_dominio.dart';
import 'resultado_consulta_reputacao.dart';
import 'score_config.dart';
import 'sinais_identificados.dart';
import 'sinal_link.dart';
import 'verificacao_link.dart';

/// Orquestra a análise de link do UC03: normalização e anatomia da URL
/// (typosquatting), idade do domínio via RDAP, reputação no Google Safe
/// Browsing e conversão dos sinais encontrados em entrada do motor de score
/// (RF07). Não calcula pesos: apenas decide quais [SinalLink] estão
/// presentes e delega a pontuação a [CalculadoraScore].
///
/// Uma verificação que não conclui (qualquer das três) marca a análise como
/// incompleta, e a regra de verificação incompleta de
/// `docs/score-calibracao.md` impede a faixa verde.
class AnalisadorLink {
  AnalisadorLink(this._consultaIdadeDominio, this._consultaReputacao);

  final ConsultaIdadeDominio _consultaIdadeDominio;
  final ConsultaReputacaoDominio _consultaReputacao;

  static const String _fonteAnatomia =
      'Phize, comparando o endereço com uma lista de endereços oficiais '
      'de bancos e serviços conhecidos';
  static const String _fonteRdap =
      'Cadastro público de domínios na internet (RDAP)';
  static const String _fonteReputacao =
      'Google Safe Browsing, serviço do Google';

  /// Devolve `null` quando [entrada] não é uma URL/domínio válido — quem
  /// chama deve pedir o reenvio (UC03, fluxo de exceção "Formato
  /// inválido"). Nunca lança exceção: falhas de fontes externas viram
  /// verificação não concluída (CLAUDE.md, Seção 8).
  Future<ResultadoAnaliseLink?> analisar(String entrada) async {
    final anatomia = AnalisadorTyposquatting.analisar(entrada);
    if (!anatomia.entradaValida) return null;

    // RDAP opera só sobre o domínio; a reputação recebe a entrada original
    // e a normaliza (domínio e caminho, sem query nem fragmento) antes de
    // transmitir (arquitetura, seção 4, etapa 2). As duas consultas são
    // independentes e correm em paralelo.
    final (idade, reputacao) = await (
      _consultaIdadeDominio.consultar(anatomia.dominioRegistravel!),
      _consultaReputacao.consultar(entrada),
    ).wait;

    final verificacoes = [
      _verificacaoAnatomia(anatomia),
      _verificacaoIdade(idade),
      _verificacaoReputacao(reputacao),
    ];

    final sinais = SinaisIdentificados(
      link: {
        if (reputacao.status == StatusConsultaReputacao.listado)
          SinalLink.listadoSafeBrowsing,
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

  /// Linguagem de ressalva e fonte atribuída ao Google, conforme os termos
  /// de uso do Safe Browsing (arquitetura, seção 4, etapa 2, itens b e c).
  /// O aviso de que a verificação não é infalível é exibido pela tela de
  /// resultado (`RotulosRisco.avisoFalibilidadeReputacao`).
  static VerificacaoLink _verificacaoReputacao(
    ResultadoConsultaReputacao reputacao,
  ) {
    const titulo = 'Lista de endereços perigosos';

    switch (reputacao.status) {
      case StatusConsultaReputacao.naoConcluida:
        final motivo = reputacao.motivoNaoConcluida;
        return VerificacaoLink(
          titulo: titulo,
          descricao: [
            'Não foi possível consultar a lista de endereços já '
                'identificados como perigosos pelo Google.',
            ?motivo,
          ].join(' '),
          fonte: _fonteReputacao,
          status: StatusVerificacao.naoConcluida,
        );
      case StatusConsultaReputacao.naoListado:
        return const VerificacaoLink(
          titulo: titulo,
          descricao:
              'Segundo o Google, este endereço não aparece na lista de '
              'endereços já identificados como perigosos. Isso não é uma '
              'garantia: endereços novos podem ainda não ter entrado na '
              'lista.',
          fonte: _fonteReputacao,
          status: StatusVerificacao.semSinal,
        );
      case StatusConsultaReputacao.listado:
        final tipos = _descreverTiposAmeaca(reputacao.tiposAmeaca);
        return VerificacaoLink(
          titulo: titulo,
          descricao: [
            'Segundo o Google, este endereço aparece na lista de endereços '
                'identificados como possivelmente perigosos.',
            if (tipos != null) 'Motivo apontado: $tipos.',
            'Evite abrir o link e não informe seus dados nele.',
          ].join(' '),
          fonte: _fonteReputacao,
          status: StatusVerificacao.sinalEncontrado,
        );
    }
  }

  /// Traduz as categorias técnicas do Safe Browsing para linguagem não
  /// técnica (RF03). Categorias desconhecidas são omitidas; `null` quando
  /// nenhuma categoria é reconhecida.
  static String? _descreverTiposAmeaca(List<String> tipos) {
    final descricoes = <String>{
      for (final tipo in tipos)
        ?switch (tipo) {
          'SOCIAL_ENGINEERING' =>
            'página que tenta enganar as pessoas para roubar dados ou '
                'dinheiro',
          'MALWARE' => 'página que pode instalar programas maliciosos',
          'UNWANTED_SOFTWARE' =>
            'página que oferece programas indesejados',
          'POTENTIALLY_HARMFUL_APPLICATION' =>
            'página que oferece aplicativos possivelmente nocivos',
          _ => null,
        },
    };
    return descricoes.isEmpty ? null : descricoes.join('; ');
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

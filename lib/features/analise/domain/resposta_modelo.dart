import 'categoria_ameaca.dart';
import 'sinal_texto_print.dart';

/// Análise devolvida pelo modelo de linguagem, já validada contra o contrato
/// da Function `analiseTexto` (functions/src/analiseTexto.ts).
///
/// Contém apenas sinais, categoria e explicação. Não há campo de score: o
/// modelo identifica sinais, e a pontuação é calculada exclusivamente por
/// `CalculadoraScore` (RF07). Um campo extra enviado pelo modelo (ex.:
/// "score") é ignorado, nunca lido.
class RespostaModelo {
  const RespostaModelo({
    required this.sinais,
    required this.categoria,
    required this.explicacao,
  });

  final Set<SinalTextoPrint> sinais;
  final CategoriaAmeaca categoria;
  final String explicacao;

  static const int tamanhoMaximoExplicacao = 2000;

  /// Códigos trocados com a Function. Sem RAG nesta etapa (decisão de
  /// 2026-10-07), `correspondenciaPadraoCatalogado` não tem código: o
  /// modelo não consulta base alguma e não pode emitir esse sinal.
  static const Map<String, SinalTextoPrint> codigosSinais = {
    'pedido_financeiro': SinalTextoPrint.pedidoFinanceiro,
    'solicitacao_dados_pessoais': SinalTextoPrint.solicitacaoDadosPessoais,
    'alegacao_troca_contato': SinalTextoPrint.alegacaoTrocaContato,
    'inducao_urgencia': SinalTextoPrint.inducaoUrgencia,
    'ameaca': SinalTextoPrint.ameaca,
    'link_suspeito': SinalTextoPrint.linkSuspeito,
    'oferta_incompativel_mercado': SinalTextoPrint.ofertaIncompativelMercado,
  };

  /// Devolve `null` para qualquer desvio do contrato — campo ausente, tipo
  /// errado, sinal ou categoria desconhecidos, explicação vazia ou longa
  /// demais. Resposta fora do formato é descartada inteira, nunca
  /// aproveitada em parte (UC04, "Resposta inválida do modelo").
  static RespostaModelo? deJson(Object? json) {
    if (json is! Map) return null;

    final sinaisJson = json['sinais'];
    if (sinaisJson is! List) return null;
    final sinais = <SinalTextoPrint>{};
    for (final codigo in sinaisJson) {
      final sinal = codigosSinais[codigo];
      if (sinal == null) return null;
      sinais.add(sinal);
    }

    final categoria = CategoriaAmeaca.doCodigo(json['categoria']);
    if (categoria == null) return null;

    final explicacao = json['explicacao'];
    if (explicacao is! String) return null;
    final explicacaoLimpa = explicacao.trim();
    if (explicacaoLimpa.isEmpty ||
        explicacaoLimpa.length > tamanhoMaximoExplicacao) {
      return null;
    }

    return RespostaModelo(
      sinais: Set.unmodifiable(sinais),
      categoria: categoria,
      explicacao: explicacaoLimpa,
    );
  }
}

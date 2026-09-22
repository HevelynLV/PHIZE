import 'sinal_link.dart';
import 'sinal_texto_print.dart';

/// Entrada do motor de Score de Risco (RF07).
///
/// Reúne os sinais identificados pelo LLM no conteúdo (grupo Texto/Print) e/ou
/// pela verificação de URL (grupo Link, UC03/RF03) de uma mesma análise — os
/// dois grupos podem se combinar (ex.: print contendo um link malicioso).
/// [verificacaoIncompleta] indica que alguma fonte de verificação externa
/// falhou (degradação controlada, CLAUDE.md Seção 8).
class SinaisIdentificados {
  const SinaisIdentificados({
    this.textoPrint = const {},
    this.link = const {},
    this.verificacaoIncompleta = false,
  });

  final Set<SinalTextoPrint> textoPrint;
  final Set<SinalLink> link;
  final bool verificacaoIncompleta;
}

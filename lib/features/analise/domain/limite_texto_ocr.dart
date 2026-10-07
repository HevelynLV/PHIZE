import 'mascaramento_local.dart';

/// Volume mínimo de texto extraído por OCR para que a análise de print
/// prossiga (UC04, etapa 5; RF04).
///
/// Espelha exatamente `docs/limite-texto-ocr.md`, fonte única destes
/// valores. Nenhum outro ponto do código deve duplicá-los.
///
/// São duas verificações no pipeline (`AnalisadorPrint`), com critérios
/// próprios: [atende] sobre o texto bruto do OCR, para barrar ruído, e
/// [atendeAposMascaramento] sobre o texto já mascarado, para garantir que
/// restou conteúdo analisável. Falha em qualquer uma interrompe o fluxo sem
/// transmissão à nuvem.
class LimiteTextoOcr {
  LimiteTextoOcr._();

  static const String versao = '1.1';

  /// Primeira verificação, sobre o texto bruto do OCR.
  static const int minimoCaracteres = 20;
  static const int minimoPalavras = 4;

  /// Segunda verificação, sobre o texto mascarado, contando apenas o que
  /// fica fora dos marcadores de mascaramento.
  static const int minimoCaracteresAposMascaramento = 10;
  static const int minimoPalavrasAposMascaramento = 2;

  static final RegExp _espacos = RegExp(r'\s+');

  /// Primeira verificação: `true` quando [texto] atende às duas condições,
  /// cumulativamente.
  ///
  /// Contagem, conforme a tabela de aferição do documento: espaços em
  /// sequência (inclusive quebras de linha do OCR) valem como um só e as
  /// bordas são ignoradas; caracteres incluem espaços e pontuação; palavra
  /// é qualquer trecho entre espaços (ex.: "R$" e "500" contam como duas).
  static bool atende(String texto) =>
      _atende(texto, minimoCaracteres, minimoPalavras);

  /// Segunda verificação: `true` quando o texto fora dos marcadores de
  /// [textoMascarado] atende às duas condições, cumulativamente. Um print
  /// que contém apenas dados estruturados não tem o que ser analisado.
  /// Mesma regra de contagem de [atende].
  static bool atendeAposMascaramento(String textoMascarado) {
    var semMarcadores = textoMascarado;
    for (final marcador in marcadoresMascaramento) {
      semMarcadores = semMarcadores.replaceAll(marcador, ' ');
    }
    return _atende(
      semMarcadores,
      minimoCaracteresAposMascaramento,
      minimoPalavrasAposMascaramento,
    );
  }

  static bool _atende(String texto, int minimoCaracteres, int minimoPalavras) {
    final normalizado = texto.trim().replaceAll(_espacos, ' ');
    if (normalizado.isEmpty) return false;
    final caracteres = normalizado.runes.length;
    final palavras = normalizado.split(' ').length;
    return caracteres >= minimoCaracteres && palavras >= minimoPalavras;
  }
}

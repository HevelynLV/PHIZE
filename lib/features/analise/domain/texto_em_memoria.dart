/// Texto extraído de um print (bruto ou mascarado), mantido apenas em
/// memória durante o pipeline do UC04 (RNF07, etapa 3 — descarte na origem).
///
/// Não há método que grave o texto em lugar algum. [descartar] solta a
/// única referência mantida pelo pipeline. Limitação: `String` em Dart é
/// imutável e não pode ser sobrescrita como os bytes da imagem
/// (`ImagemEmMemoria`); o conteúdo deixa de ser alcançável pela aplicação e
/// é recolhido pelo coletor de lixo.
class TextoEmMemoria {
  TextoEmMemoria(String valor) : _valor = valor;

  String? _valor;

  bool get descartado => _valor == null;

  /// Lança [StateError] se o texto já foi descartado. A mensagem nunca
  /// contém o texto.
  String get valor {
    final valor = _valor;
    if (valor == null) {
      throw StateError('O texto já foi descartado da memória.');
    }
    return valor;
  }

  /// Idempotente e nunca lança exceção: é chamado de blocos `finally`.
  void descartar() {
    _valor = null;
  }
}

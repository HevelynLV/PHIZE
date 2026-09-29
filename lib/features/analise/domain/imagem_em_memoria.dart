import 'dart:typed_data';

/// Imagem submetida à análise de print (UC04), mantida exclusivamente em
/// memória volátil (RNF01, garantia "a"; arquitetura, seção 5.1).
///
/// Não há método que grave os bytes em lugar algum. [descartar] sobrescreve
/// o buffer com zeros e solta a referência: qualquer trecho que ainda
/// segure o [Uint8List] passa a ver apenas zeros, e a imagem não pode mais
/// ser lida por este objeto.
class ImagemEmMemoria {
  ImagemEmMemoria(Uint8List bytes) : _bytes = bytes;

  Uint8List? _bytes;

  bool get descartada => _bytes == null;

  /// Lança [StateError] se a imagem já foi descartada.
  Uint8List get bytes {
    final bytes = _bytes;
    if (bytes == null) {
      throw StateError('A imagem já foi descartada da memória.');
    }
    return bytes;
  }

  /// Idempotente e nunca lança exceção: é chamado de blocos `finally`, onde
  /// uma falha aqui mascararia a exceção original do fluxo.
  void descartar() {
    final bytes = _bytes;
    _bytes = null;
    if (bytes == null) return;
    try {
      bytes.fillRange(0, bytes.length, 0);
    } on UnsupportedError {
      // Buffer não modificável (ex.: visão somente leitura): a referência já
      // foi solta acima, que é o que resta ao alcance da aplicação.
    }
  }
}

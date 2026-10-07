import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/imagem_em_memoria.dart';
import '../domain/reconhecedor_texto.dart';

/// Implementação real de [ReconhecedorTexto] com o Google ML Kit Text
/// Recognition, executado no próprio dispositivo (RNF06; arquitetura, 3.1).
///
/// A imagem nunca passa por arquivo: o PNG/JPEG é decodificado em memória
/// pelo motor do Flutter e entregue ao ML Kit como pixels RGBA
/// (`InputImage.fromBitmap`), sem `fromFilePath` — que exigiria gravar o
/// print em disco, vedado pelo RNF01. O buffer de pixels decodificados é
/// zerado em `finally`, como os bytes originais (`ImagemEmMemoria`).
///
/// Limitação: as cópias feitas pela ponte de plataforma e pelo código
/// nativo do ML Kit ficam fora do alcance da aplicação; são liberadas pelo
/// próprio sistema ao fim do processamento.
///
/// Indisponível na web: lança [ReconhecimentoTextoNaoSuportadoException].
class ReconhecedorTextoMlKit implements ReconhecedorTexto {
  @override
  Future<String> reconhecer(ImagemEmMemoria imagem) async {
    if (kIsWeb) throw const ReconhecimentoTextoNaoSuportadoException();

    final reconhecedor = TextRecognizer(script: TextRecognitionScript.latin);
    ui.Codec? codec;
    ui.Image? quadro;
    Uint8List? pixels;
    try {
      codec = await ui.instantiateImageCodec(imagem.bytes);
      quadro = (await codec.getNextFrame()).image;
      final dados = await quadro.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (dados == null) return '';
      pixels = dados.buffer.asUint8List();

      final resultado = await reconhecedor.processImage(
        InputImage.fromBitmap(
          bitmap: pixels,
          width: quadro.width,
          height: quadro.height,
        ),
      );
      return resultado.text;
    } finally {
      pixels?.fillRange(0, pixels.length, 0);
      quadro?.dispose();
      codec?.dispose();
      try {
        await reconhecedor.close();
      } catch (_) {
        // Liberar o reconhecedor nativo é melhor esforço; não pode mascarar
        // o resultado nem a exceção original.
      }
    }
  }
}

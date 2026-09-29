import 'imagem_em_memoria.dart';
import 'seletor_imagem.dart';

/// Seleção de imagem com Zero-Persistence (UC04, passos 1, 2 e 4; RNF01,
/// garantia "a"; arquitetura, seção 5.1).
///
/// Ciclo garantido por esta classe:
/// 1. resíduos de seleções interrompidas anteriormente são removidos;
/// 2. a imagem escolhida é lida integralmente para a memória;
/// 3. a cópia temporária criada pelo seletor é removida logo em seguida —
///    em `finally`, inclusive se a leitura falhar;
/// 4. a [ImagemEmMemoria] é entregue à etapa seguinte (OCR, na Fase 6.2) e
///    descartada em `finally` assim que ela termina, com sucesso, com
///    exceção ou interrompida.
///
/// Nada é gravado em disco, cache, storage ou banco: esta classe só lê
/// bytes e pede a remoção do temporário.
class CapturaImagem {
  CapturaImagem(this._seletor);

  final SeletorImagem _seletor;

  /// Executa [etapa] sobre a imagem selecionada e devolve o resultado dela.
  /// Devolve `null`, sem executar [etapa], quando o usuário cancela.
  ///
  /// [etapa] não deve guardar a imagem além da própria execução: ao
  /// terminar, os bytes são zerados. Exceções de [etapa], da leitura ou da
  /// remoção do temporário são propagadas depois do descarte, para que quem
  /// chama decida a mensagem ao usuário (sem expor o conteúdo).
  ///
  /// A camada de tela não pode exibir nem registrar em log a exceção
  /// recebida: `FileSystemException` traz o caminho do temporário, que inclui
  /// o nome original do print (ver [ArquivoSelecionado]).
  Future<R?> processar<R>(
    Future<R> Function(ImagemEmMemoria imagem) etapa,
  ) async {
    await _removerResiduos();

    final arquivo = await _seletor.selecionar();
    if (arquivo == null) return null;

    ImagemEmMemoria? imagem;
    try {
      try {
        imagem = ImagemEmMemoria(await arquivo.lerBytes());
      } finally {
        // Com os bytes já em memória, o temporário não tem mais função.
        await arquivo.remover();
      }
      return await etapa(imagem);
    } finally {
      imagem?.descartar();
    }
  }

  /// Limpeza de melhor esforço: a falha em remover um resíduo antigo não
  /// impede uma nova análise, e a próxima execução tenta de novo.
  Future<void> _removerResiduos() async {
    final List<ArquivoSelecionado> residuos;
    try {
      residuos = await _seletor.recuperarResiduos();
    } catch (_) {
      return;
    }
    for (final residuo in residuos) {
      try {
        await residuo.remover();
      } catch (_) {
        // Segue para os demais resíduos.
      }
    }
  }
}

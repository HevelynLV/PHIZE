/// Porta de acesso ao seletor de mídia do sistema operacional (UC04, passo
/// 1). Abstrai a plataforma para que a rotina de Zero-Persistence
/// (`CapturaImagem`) possa ser testada com um dublê, sem tocar no sistema
/// de arquivos real.
///
/// A porta não oferece nenhuma operação de escrita: o único efeito sobre o
/// armazenamento que a aplicação pode pedir é a remoção do arquivo
/// temporário criado pelo próprio seletor (arquitetura, seção 5.1).
library;

import 'dart:typed_data';

/// A plataforma atual não suporta a seleção de imagem com as garantias do
/// RNF01 (ex.: web — ver `SeletorImagemGaleria`).
class SelecaoImagemNaoSuportadaException implements Exception {
  const SelecaoImagemNaoSuportadaException();
}

/// Arquivo entregue pelo seletor de mídia. Em Android, é uma cópia que o
/// seletor grava no cache do aplicativo — por isso precisa ser removido.
///
/// **Exceções:** [lerBytes] e [remover] podem lançar `FileSystemException`,
/// cuja mensagem traz o caminho do arquivo — e o caminho inclui o nome
/// original do print (ex.: `Screenshot_..._WhatsApp.png`). A camada de tela
/// não pode exibir essa exceção ao usuário nem gravá-la em log; deve mostrar
/// mensagem genérica própria (RNF01, RNF07).
abstract class ArquivoSelecionado {
  /// Lê o conteúdo integral para a memória.
  Future<Uint8List> lerBytes();

  /// Remove do armazenamento do dispositivo a cópia temporária criada pelo
  /// seletor. Nunca remove o arquivo original da galeria do usuário.
  Future<void> remover();
}

abstract class SeletorImagem {
  /// Abre a galeria. Devolve `null` quando o usuário cancela a seleção.
  Future<ArquivoSelecionado?> selecionar();

  /// Arquivos temporários deixados por uma seleção interrompida antes de
  /// chegar à aplicação (ex.: o Android encerrou o app enquanto a galeria
  /// estava aberta). Lista vazia quando não há resíduo.
  Future<List<ArquivoSelecionado>> recuperarResiduos();
}

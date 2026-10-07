/// Porta de acesso ao reconhecimento óptico de caracteres embarcado no
/// dispositivo (UC04, etapas 2 e 3; RNF06). Abstrai a plataforma para que o
/// pipeline (`AnalisadorPrint`) possa ser testado com um dublê, sem ML Kit.
///
/// Não há implementação remota: a imagem nunca sai do dispositivo (RNF01,
/// garantia "a"; arquitetura, seção 3.1).
library;

import 'imagem_em_memoria.dart';

/// A plataforma atual não oferece reconhecimento embarcado (ex.: web).
class ReconhecimentoTextoNaoSuportadoException implements Exception {
  const ReconhecimentoTextoNaoSuportadoException();
}

abstract class ReconhecedorTexto {
  /// Extrai o texto de [imagem] no próprio dispositivo. Devolve string
  /// vazia quando nada é reconhecido.
  ///
  /// Não descarta [imagem]: quem chama é responsável por isso. Não pode
  /// gravar a imagem, nem cópia decodificada dela, em disco ou log.
  Future<String> reconhecer(ImagemEmMemoria imagem);
}

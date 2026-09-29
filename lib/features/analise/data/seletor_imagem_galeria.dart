import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/seletor_imagem.dart';

/// Implementação real de [SeletorImagem] sobre o `image_picker`.
///
/// **PLATAFORMA:** este fluxo NÃO é suportado na web. No navegador, a
/// imagem chega como blob gerenciado pelo browser, sem arquivo temporário
/// que a aplicação possa localizar e remover, o que impede demonstrar a
/// garantia de Zero-Persistence (arquitetura, seção 5.1). Na web,
/// [selecionar] lança [SelecaoImagemNaoSuportadaException].
///
/// **TESTE REAL EXIGE ANDROID** (docs/ROADMAP.md, Fase 6): os testes
/// automatizados cobrem a rotina de descarte (`CapturaImagem`) com dublê;
/// a criação e a remoção do temporário pelo seletor só podem ser
/// verificadas em dispositivo ou emulador Android. O comportamento em iOS
/// segue a mesma regra, mas não foi validado.
///
/// No Android, o `image_picker` copia a imagem escolhida para
/// `<cache do app>/<uuid>/<nome>`; essa cópia é o temporário removido por
/// [ArquivoSelecionado.remover]. `requestFullMetadata: false` evita
/// processamento extra de metadados, e nenhum redimensionamento é pedido,
/// porque redimensionar grava uma segunda cópia em disco.
class SeletorImagemGaleria implements SeletorImagem {
  SeletorImagemGaleria({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ArquivoSelecionado?> selecionar() async {
    if (kIsWeb) throw const SelecaoImagemNaoSuportadaException();
    final arquivo = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    // `null` também chega quando a cópia para o cache falha no plugin; o
    // arquivo parcial que sobrar é removido por LimpezaCopiasSeletor na
    // próxima inicialização.
    return arquivo == null ? null : _ArquivoDoSeletor(arquivo.path);
  }

  /// No Android, se o sistema encerrar o app com a galeria aberta, o
  /// `image_picker` guarda o caminho da cópia para entregá-la no próximo
  /// início; ela é recuperada aqui apenas para ser removida.
  @override
  Future<List<ArquivoSelecionado>> recuperarResiduos() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    final resposta = await _picker.retrieveLostData();
    if (resposta.isEmpty) return const [];
    final arquivos = resposta.files ?? [?resposta.file];
    return [for (final a in arquivos) _ArquivoDoSeletor(a.path)];
  }

  /// Só é removido o que é comprovadamente cópia do seletor: no Android,
  /// um arquivo em `<...>/cache/<uuid>/`; no iOS, um arquivo em `<...>/tmp/`.
  /// Qualquer outro caminho pode ser o original da galeria do usuário e
  /// nunca é apagado.
  @visibleForTesting
  static bool ehCopiaTemporariaDoSeletor(
    String caminho, {
    required bool android,
  }) {
    final partes = caminho.split('/');
    if (partes.length < 3 || partes.any((p) => p == '..')) return false;
    return android
        ? partes[partes.length - 3] == 'cache'
        : partes[partes.length - 2] == 'tmp';
  }
}

class _ArquivoDoSeletor implements ArquivoSelecionado {
  _ArquivoDoSeletor(this._caminho);

  final String _caminho;

  @override
  Future<Uint8List> lerBytes() => File(_caminho).readAsBytes();

  @override
  Future<void> remover() async {
    final android = Platform.isAndroid;
    if (!SeletorImagemGaleria.ehCopiaTemporariaDoSeletor(
      _caminho,
      android: android,
    )) {
      return;
    }
    final arquivo = File(_caminho);
    if (await arquivo.exists()) await arquivo.delete();

    // No Android, a pasta <uuid> criada pelo seletor fica vazia; também é
    // removida para não deixar rastro da seleção.
    if (android) {
      final pasta = arquivo.parent;
      if (await pasta.exists() && await pasta.list().isEmpty) {
        await pasta.delete();
      }
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Varredura, na inicialização do app, das cópias de imagem deixadas pelo
/// seletor de mídia no cache (RNF01, garantia "a"; arquitetura, seção 5.1).
///
/// **Por que existe:** no Android, o `image_picker` copia a imagem escolhida
/// para `<cache do app>/<uuid>/<nome>` *antes* de devolver o caminho à
/// aplicação. `CapturaImagem` remove essa cópia logo após a leitura, mas há
/// casos em que ela fica órfã sem que ninguém saiba o caminho:
/// - a remoção do temporário falha;
/// - o app é fechado entre o retorno do seletor e a remoção;
/// - a cópia falha no meio e o plugin devolve `null`, que a aplicação não
///   distingue de um cancelamento — o arquivo parcial fica para trás.
///
/// `retrieveLostData` não cobre esses casos, e o `deleteOnExit` que o
/// próprio plugin registra não é confiável no Android (o processo raramente
/// termina de forma ordenada). Por isso o RNF01 exige esta varredura própria.
///
/// Só é removida uma pasta diretamente dentro do cache cujo nome é um UUID
/// (formato gerado por `UUID.randomUUID()`) e que contém apenas arquivos —
/// nunca outras entradas do cache do app. Nada é registrado em log: nomes de
/// arquivo podem revelar a origem do print.
///
/// Se a varredura coincidir com uma seleção em andamento e remover a cópia
/// antes da leitura, a leitura falha e cai no caminho de exceção de
/// `CapturaImagem`, sem deixar resíduo.
class LimpezaCopiasSeletor {
  LimpezaCopiasSeletor._();

  static final _nomeUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Ponto de entrada chamado em `main`. Nunca lança exceção: a falha na
  /// limpeza não pode impedir o app de abrir, e a próxima inicialização
  /// tenta de novo.
  ///
  /// [android] e [diretorioCache] existem para teste; por padrão, a
  /// plataforma atual e o cache do app (`getTemporaryDirectory`, que no
  /// Android é o mesmo `getCacheDir()` usado pelo seletor).
  static Future<void> executar({
    bool? android,
    Future<Directory> Function()? diretorioCache,
  }) async {
    try {
      if (!(android ?? (!kIsWeb && Platform.isAndroid))) return;
      final cache = await (diretorioCache ?? getTemporaryDirectory)();
      await limpar(cache);
    } catch (_) {
      // Melhor esforço; ver documentação da classe.
    }
  }

  /// Remove de [cache] as pastas do seletor. Nunca lança exceção; a falha
  /// em uma pasta não impede a remoção das demais.
  @visibleForTesting
  static Future<void> limpar(Directory cache) async {
    final List<FileSystemEntity> entradas;
    try {
      entradas = await cache.list(followLinks: false).toList();
    } catch (_) {
      return;
    }
    for (final entrada in entradas) {
      if (entrada is! Directory || !_ehPastaDoSeletor(entrada)) continue;
      try {
        final conteudo = await entrada.list(followLinks: false).toList();
        // A pasta do seletor guarda só a cópia da imagem. Subpasta ou link
        // indica que não é dela: fica intocada.
        if (conteudo.any((e) => e is! File)) continue;
        for (final arquivo in conteudo) {
          await arquivo.delete();
        }
        await entrada.delete();
      } catch (_) {
        // Segue para as demais pastas.
      }
    }
  }

  static bool _ehPastaDoSeletor(Directory pasta) {
    final nome = pasta.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => '',
    );
    return _nomeUuid.hasMatch(nome);
  }
}

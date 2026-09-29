import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/limpeza_copias_seletor.dart';

/// Todos os testes usam sistema de arquivos em memória (`package:file`) e
/// rodam com o sistema de arquivos real bloqueado: qualquer tentativa de
/// criar `File`, `Directory` ou `Link` do `dart:io` falha o teste.
Future<T> _semSistemaDeArquivos<T>(Future<T> Function() corpo) {
  Never proibido(String operacao) =>
      throw StateError('Acesso ao sistema de arquivos: $operacao');
  return io.IOOverrides.runZoned(
    corpo,
    createFile: (caminho) => proibido('arquivo'),
    createDirectory: (caminho) => proibido('pasta'),
    createLink: (caminho) => proibido('link'),
    getSystemTempDirectory: () => proibido('temp do sistema'),
    getCurrentDirectory: () => proibido('diretório atual'),
  );
}

const _cache = '/data/user/0/com.phize.app/cache';
const _uuidA = '3f1c9a2e-0000-4000-8000-000000000001';
const _uuidB = '3f1c9a2e-0000-4000-8000-000000000002';

MemoryFileSystem _novoSistema({
  void Function(String contexto, FileSystemOp operacao)? aoOperar,
}) {
  final fs = aoOperar == null
      ? MemoryFileSystem()
      : MemoryFileSystem(opHandle: aoOperar);
  fs.directory(_cache).createSync(recursive: true);
  return fs;
}

void _criarArquivo(FileSystem fs, String caminho) =>
    fs.file(caminho)
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

void main() {
  test('remove as pastas <uuid>/ do seletor, inclusive cópia parcial e '
      'pasta vazia', () {
    return _semSistemaDeArquivos(() async {
      final fs = _novoSistema();
      _criarArquivo(fs, '$_cache/$_uuidA/print.png');
      // Cópia interrompida no meio: o plugin devolveu null ao app.
      _criarArquivo(fs, '$_cache/$_uuidB/parcial.jpg');
      fs.directory('$_cache/3f1c9a2e-0000-4000-8000-000000000003')
          .createSync();

      await LimpezaCopiasSeletor.limpar(fs.directory(_cache));

      expect(fs.directory(_cache).listSync(), isEmpty);
      expect(fs.directory(_cache).existsSync(), isTrue);
    });
  });

  test('não toca em outros arquivos do cache', () {
    return _semSistemaDeArquivos(() async {
      final fs = _novoSistema();
      final preservados = [
        '$_cache/preferencias.tmp',
        '$_cache/$_uuidA.jpg', // arquivo com nome de UUID, não pasta
        '$_cache/image_cache/foto.png',
        '$_cache/3F1C9A2E-0000-4000-8000-000000000004/x.png', // maiúsculas
        '$_cache/nao-e-uuid-0000/x.png',
        '$_cache/outra/$_uuidB/x.png', // UUID fora da raiz do cache
        '$_cache/$_uuidB/sub/x.png', // pasta com subpasta não é do seletor
        '$_cache/$_uuidB/y.png',
      ];
      for (final caminho in preservados) {
        _criarArquivo(fs, caminho);
      }
      _criarArquivo(fs, '$_cache/$_uuidA/print.png');

      await LimpezaCopiasSeletor.limpar(fs.directory(_cache));

      for (final caminho in preservados) {
        expect(fs.file(caminho).existsSync(), isTrue, reason: caminho);
      }
      expect(fs.directory('$_cache/$_uuidA').existsSync(), isFalse);
    });
  });

  test('link dentro da pasta <uuid>/ não é seguido nem removido', () {
    return _semSistemaDeArquivos(() async {
      final fs = _novoSistema();
      _criarArquivo(fs, '/data/user/0/com.phize.app/files/dados.db');
      fs.directory('$_cache/$_uuidA').createSync();
      fs
          .link('$_cache/$_uuidA/atalho')
          .createSync('/data/user/0/com.phize.app/files/dados.db');

      await LimpezaCopiasSeletor.limpar(fs.directory(_cache));

      expect(fs.link('$_cache/$_uuidA/atalho').existsSync(), isTrue);
      expect(
        fs.file('/data/user/0/com.phize.app/files/dados.db').existsSync(),
        isTrue,
      );
    });
  });

  group('a limpeza falhando não impede o app de iniciar', () {
    test('falha ao obter o diretório de cache: executar conclui sem lançar',
        () {
      return _semSistemaDeArquivos(() async {
        await expectLater(
          LimpezaCopiasSeletor.executar(
            android: true,
            diretorioCache: () async =>
                throw const io.FileSystemException('sem cache'),
          ),
          completes,
        );
      });
    });

    test('cache inexistente: executar conclui sem lançar', () {
      return _semSistemaDeArquivos(() async {
        final fs = MemoryFileSystem();
        await expectLater(
          LimpezaCopiasSeletor.executar(
            android: true,
            diretorioCache: () async => fs.directory(_cache),
          ),
          completes,
        );
      });
    });

    test('remoção de uma pasta falha: não lança e as demais são removidas',
        () {
      return _semSistemaDeArquivos(() async {
        final fs = _novoSistema(
          aoOperar: (contexto, operacao) {
            if (operacao == FileSystemOp.delete && contexto.contains(_uuidA)) {
              throw const io.FileSystemException('ocupado');
            }
          },
        );
        _criarArquivo(fs, '$_cache/$_uuidA/print.png');
        _criarArquivo(fs, '$_cache/$_uuidB/print.png');

        await expectLater(
          LimpezaCopiasSeletor.executar(
            android: true,
            diretorioCache: () async => fs.directory(_cache),
          ),
          completes,
        );

        expect(fs.directory('$_cache/$_uuidA').existsSync(), isTrue);
        expect(fs.directory('$_cache/$_uuidB').existsSync(), isFalse);
      });
    });
  });

  test('fora do Android nada é varrido', () {
    return _semSistemaDeArquivos(() async {
      var cacheConsultado = false;
      await LimpezaCopiasSeletor.executar(
        android: false,
        diretorioCache: () async {
          cacheConsultado = true;
          return MemoryFileSystem().directory(_cache);
        },
      );
      expect(cacheConsultado, isFalse);
    });
  });

  test('o bloqueio do sistema de arquivos real de fato detecta acesso', () {
    // Controle: garante que os testes acima não passam por engano.
    return _semSistemaDeArquivos(() async {
      expect(() => io.Directory(_cache), throwsStateError);
    });
  });
}

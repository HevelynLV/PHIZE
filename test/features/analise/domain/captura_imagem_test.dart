import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/captura_imagem.dart';
import 'package:phize/features/analise/domain/imagem_em_memoria.dart';
import 'package:phize/features/analise/domain/seletor_imagem.dart';

/// Dublê do arquivo temporário do seletor: registra cada operação pedida.
/// A porta não tem operação de escrita, então nenhuma escrita é possível;
/// [operacoes] prova, além disso, que a rotina só lê e remove.
class _ArquivoFalso implements ArquivoSelecionado {
  _ArquivoFalso({
    this._conteudo = const [1, 2, 3, 4],
    this.erroLeitura,
    this.erroRemocao,
  });

  final List<int> _conteudo;
  final Object? erroLeitura;
  final Object? erroRemocao;

  final List<String> operacoes = [];
  bool get removido => operacoes.contains('remover');

  @override
  Future<Uint8List> lerBytes() async {
    operacoes.add('ler');
    final erro = erroLeitura;
    if (erro != null) throw erro;
    return Uint8List.fromList(_conteudo);
  }

  @override
  Future<void> remover() async {
    operacoes.add('remover');
    final erro = erroRemocao;
    if (erro != null) throw erro;
  }
}

class _SeletorFalso implements SeletorImagem {
  _SeletorFalso({
    this.arquivo,
    this.residuos = const [],
    this.erroSelecao,
  });

  /// `null` simula o cancelamento pelo usuário.
  final _ArquivoFalso? arquivo;
  final List<_ArquivoFalso> residuos;
  final Object? erroSelecao;

  @override
  Future<ArquivoSelecionado?> selecionar() async {
    final erro = erroSelecao;
    if (erro != null) throw erro;
    return arquivo;
  }

  @override
  Future<List<ArquivoSelecionado>> recuperarResiduos() async => residuos;
}

class _FalhaNoOcr implements Exception {}

/// Executa [corpo] com o sistema de arquivos real bloqueado: qualquer
/// tentativa de criar arquivo, pasta ou link, ou de usar o diretório
/// temporário do sistema, falha o teste. Prova que a rotina não grava em
/// disco e que nenhum teste toca o sistema de arquivos real.
Future<T> _semSistemaDeArquivos<T>(Future<T> Function() corpo) {
  Never proibido(String operacao) =>
      throw StateError('Acesso ao sistema de arquivos: $operacao');
  return IOOverrides.runZoned(
    corpo,
    createFile: (caminho) => proibido('arquivo'),
    createDirectory: (caminho) => proibido('pasta'),
    createLink: (caminho) => proibido('link'),
    getSystemTempDirectory: () => proibido('temp do sistema'),
    getCurrentDirectory: () => proibido('diretório atual'),
  );
}

void main() {
  test('caminho de sucesso: a etapa recebe a imagem, o temporário é '
      'removido e a imagem é descartada ao final', () {
    return _semSistemaDeArquivos(() async {
      final arquivo = _ArquivoFalso(conteudo: [9, 8, 7]);
      ImagemEmMemoria? recebida;
      Uint8List? bytesVistosPelaEtapa;

      final resultado = await CapturaImagem(
        _SeletorFalso(arquivo: arquivo),
      ).processar((imagem) async {
        recebida = imagem;
        bytesVistosPelaEtapa = imagem.bytes;
        // O temporário já foi removido quando a etapa começa.
        expect(arquivo.removido, isTrue);
        expect(imagem.bytes, [9, 8, 7]);
        return 'texto do OCR';
      });

      expect(resultado, 'texto do OCR');
      expect(arquivo.operacoes, ['ler', 'remover']);
      expect(recebida!.descartada, isTrue);
      expect(() => recebida!.bytes, throwsStateError);
      // Quem guardou uma referência ao buffer vê apenas zeros.
      expect(bytesVistosPelaEtapa, [0, 0, 0]);
    });
  });

  group('caminho de exceção (teste central do RNF01)', () {
    test('falha na etapa seguinte: imagem descartada, temporário removido '
        'e a exceção original propagada', () {
      return _semSistemaDeArquivos(() async {
        final arquivo = _ArquivoFalso(conteudo: [5, 5, 5, 5]);
        ImagemEmMemoria? recebida;
        Uint8List? bytesVistosPelaEtapa;

        await expectLater(
          CapturaImagem(_SeletorFalso(arquivo: arquivo)).processar<String>((
            imagem,
          ) async {
            recebida = imagem;
            bytesVistosPelaEtapa = imagem.bytes;
            throw _FalhaNoOcr();
          }),
          throwsA(isA<_FalhaNoOcr>()),
        );

        expect(arquivo.removido, isTrue);
        expect(recebida!.descartada, isTrue);
        expect(bytesVistosPelaEtapa, [0, 0, 0, 0]);
      });
    });

    test('interrupção do fluxo (erro síncrono no meio da etapa): descarte '
        'ocorre igualmente', () {
      return _semSistemaDeArquivos(() async {
        final arquivo = _ArquivoFalso();
        ImagemEmMemoria? recebida;

        await expectLater(
          CapturaImagem(_SeletorFalso(arquivo: arquivo)).processar<void>((
            imagem,
          ) {
            recebida = imagem;
            throw StateError('fluxo interrompido');
          }),
          throwsStateError,
        );

        expect(arquivo.removido, isTrue);
        expect(recebida!.descartada, isTrue);
      });
    });

    test('falha ao ler a imagem: temporário removido mesmo assim e a etapa '
        'não é executada', () {
      return _semSistemaDeArquivos(() async {
        final arquivo = _ArquivoFalso(
          erroLeitura: const FileSystemException('leitura falhou'),
        );
        var etapaExecutada = false;

        await expectLater(
          CapturaImagem(_SeletorFalso(arquivo: arquivo)).processar((_) async {
            etapaExecutada = true;
          }),
          throwsA(isA<FileSystemException>()),
        );

        expect(arquivo.operacoes, ['ler', 'remover']);
        expect(etapaExecutada, isFalse);
      });
    });

    test('falha ao remover o temporário: a imagem já lida é descartada, a '
        'etapa não é executada e a falha é propagada', () {
      return _semSistemaDeArquivos(() async {
        final arquivo = _ArquivoFalso(
          erroRemocao: const FileSystemException('remoção falhou'),
        );
        var etapaExecutada = false;

        await expectLater(
          CapturaImagem(_SeletorFalso(arquivo: arquivo)).processar((_) async {
            etapaExecutada = true;
          }),
          throwsA(isA<FileSystemException>()),
        );

        expect(arquivo.operacoes, ['ler', 'remover']);
        expect(etapaExecutada, isFalse);
      });
    });

    test('falha no próprio seletor: nada foi lido, nada a descartar', () {
      return _semSistemaDeArquivos(() async {
        await expectLater(
          CapturaImagem(
            _SeletorFalso(
              erroSelecao: const SelecaoImagemNaoSuportadaException(),
            ),
          ).processar((_) async => fail('etapa não deveria rodar')),
          throwsA(isA<SelecaoImagemNaoSuportadaException>()),
        );
      });
    });
  });

  test('o arquivo temporário é removido exatamente uma vez, logo após a '
      'leitura', () {
    return _semSistemaDeArquivos(() async {
      final arquivo = _ArquivoFalso();
      await CapturaImagem(
        _SeletorFalso(arquivo: arquivo),
      ).processar((_) async {});

      expect(arquivo.operacoes, ['ler', 'remover']);
    });
  });

  test('cancelamento pelo usuário: devolve null, sem leitura, sem etapa e '
      'sem resíduo', () {
    return _semSistemaDeArquivos(() async {
      final residuo = _ArquivoFalso();
      var etapaExecutada = false;

      final resultado = await CapturaImagem(
        _SeletorFalso(residuos: [residuo]),
      ).processar((_) async => etapaExecutada = true);

      expect(resultado, isNull);
      expect(etapaExecutada, isFalse);
      // Resíduo de seleção interrompida anterior também é limpo.
      expect(residuo.operacoes, ['remover']);
    });
  });

  test('resíduos de seleções interrompidas são removidos antes de nova '
      'seleção, mesmo que um deles falhe', () {
    return _semSistemaDeArquivos(() async {
      final comFalha = _ArquivoFalso(
        erroRemocao: const FileSystemException('ocupado'),
      );
      final normal = _ArquivoFalso();
      final arquivo = _ArquivoFalso();

      await CapturaImagem(
        _SeletorFalso(arquivo: arquivo, residuos: [comFalha, normal]),
      ).processar((_) async {});

      expect(comFalha.operacoes, ['remover']);
      expect(normal.operacoes, ['remover']);
      // Nenhum resíduo é lido: só removido.
      expect(comFalha.operacoes, isNot(contains('ler')));
      expect(arquivo.operacoes, ['ler', 'remover']);
    });
  });

  test('nenhum caminho escreve em disco: o bloqueio do sistema de arquivos '
      'de fato detecta escrita', () {
    // Controle do próprio teste: garante que _semSistemaDeArquivos pegaria
    // uma gravação, para que os testes acima não passem por engano.
    return _semSistemaDeArquivos(() async {
      expect(
        () => File('qualquer.png').writeAsBytesSync([1]),
        throwsStateError,
      );
    });
  });

  group('ImagemEmMemoria', () {
    test('descartar é idempotente e nunca lança', () {
      final imagem = ImagemEmMemoria(Uint8List.fromList([1, 2]));
      imagem.descartar();
      imagem.descartar();
      expect(imagem.descartada, isTrue);
    });

    test('buffer somente leitura: descarte solta a referência sem lançar',
        () {
      final imagem = ImagemEmMemoria(
        Uint8List.fromList([1, 2]).asUnmodifiableView(),
      );
      imagem.descartar();
      expect(imagem.descartada, isTrue);
    });
  });
}

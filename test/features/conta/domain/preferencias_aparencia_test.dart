import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/conta/data/preferencias_repository_local.dart';
import 'package:phize/features/conta/domain/preferencias_aparencia.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_preferencias_repository.dart';

double _fator(TextScaler escala) => escala.scale(16) / 16;

void main() {
  group('aplicarTamanhoLetra', () {
    test('normal mantém a escala do aparelho', () {
      const aparelho = TextScaler.linear(1.15);
      expect(aplicarTamanhoLetra(aparelho, TamanhoLetra.normal), aparelho);
    });

    test('grande e muito grande ampliam a letra', () {
      expect(
        _fator(aplicarTamanhoLetra(TextScaler.noScaling, TamanhoLetra.grande)),
        TamanhoLetra.grande.fator,
      );
      expect(
        _fator(
          aplicarTamanhoLetra(TextScaler.noScaling, TamanhoLetra.muitoGrande),
        ),
        TamanhoLetra.muitoGrande.fator,
      );
    });

    test('nunca diminui a letra já ampliada no aparelho', () {
      const aparelho = TextScaler.linear(2);
      expect(aplicarTamanhoLetra(aparelho, TamanhoLetra.grande), aparelho);
    });

    test('os tamanhos crescem nessa ordem', () {
      final fatores = TamanhoLetra.values.map((t) => t.fator).toList();
      expect(fatores, orderedEquals([...fatores]..sort()));
      expect(fatores.first, 1);
    });
  });

  group('ControlePreferencias', () {
    test('carrega o que estava gravado', () async {
      final controle = await ControlePreferencias.carregar(
        FakePreferenciasRepository(
          gravadas: const PreferenciasAparencia(
            tamanhoLetra: TamanhoLetra.grande,
          ),
        ),
      );
      expect(controle.atual.tamanhoLetra, TamanhoLetra.grande);
    });

    test('mudar avisa a tela e grava', () async {
      final repositorio = FakePreferenciasRepository();
      final controle = ControlePreferencias(repositorio);
      var avisos = 0;
      controle.addListener(() => avisos++);

      await controle.mudarTamanhoLetra(TamanhoLetra.muitoGrande);

      expect(avisos, 1);
      expect(repositorio.gravadas.tamanhoLetra, TamanhoLetra.muitoGrande);
    });

    test('falha ao gravar mantém a preferência aplicada e lança', () async {
      final controle = ControlePreferencias(
        FakePreferenciasRepository(falhaAoSalvar: true),
      );

      await expectLater(
        controle.mudarTamanhoLetra(TamanhoLetra.grande),
        throwsStateError,
      );
      expect(controle.atual.tamanhoLetra, TamanhoLetra.grande);
    });
  });

  group('PreferenciasRepositoryLocal', () {
    test('sem nada gravado, valem as padrão', () async {
      SharedPreferences.setMockInitialValues({});
      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.normal);
    });

    test('grava e lê de volta', () async {
      SharedPreferences.setMockInitialValues({});
      final repositorio = PreferenciasRepositoryLocal();
      await repositorio.salvar(
        const PreferenciasAparencia(
          tamanhoLetra: TamanhoLetra.muitoGrande,
        ),
      );

      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.muitoGrande);
    });

    test('valor desconhecido volta ao padrão', () async {
      SharedPreferences.setMockInitialValues({
        PreferenciasRepositoryLocal.chaveTamanhoLetra: 'gigante',
      });
      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.normal);
    });
  });
}

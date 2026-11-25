import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferencias_aparencia.dart';

/// Guarda o tamanho da letra no aparelho (RF14), sem Firestore. Vale para o
/// aparelho, e não para a conta: continua depois de sair da conta, e
/// reinstalar o app volta ao padrão.
class PreferenciasRepositoryLocal implements PreferenciasRepository {
  static const String chaveTamanhoLetra = 'preferencia_tamanho_letra';

  @override
  Future<PreferenciasAparencia> ler() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      return PreferenciasAparencia(
        tamanhoLetra: _porNome(
          TamanhoLetra.values,
          preferencias.getString(chaveTamanhoLetra),
          TamanhoLetra.normal,
        ),
      );
    } catch (_) {
      return const PreferenciasAparencia();
    }
  }

  @override
  Future<void> salvar(PreferenciasAparencia preferencias) async {
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      chaveTamanhoLetra,
      preferencias.tamanhoLetra.name,
    );
  }

  static T _porNome<T extends Enum>(List<T> valores, String? nome, T padrao) {
    for (final valor in valores) {
      if (valor.name == nome) return valor;
    }
    return padrao;
  }
}

import 'package:flutter/widgets.dart';

/// Tamanho da letra escolhido no perfil (RF14).
enum TamanhoLetra {
  normal('Normal', 1),
  grande('Grande', 1.3),
  muitoGrande('Muito grande', 1.6);

  const TamanhoLetra(this.rotulo, this.fator);

  final String rotulo;

  /// Ampliação mínima do texto. O app nunca reduz o tamanho já pedido nas
  /// configurações do aparelho.
  final double fator;
}

/// Preferências de acessibilidade, guardadas só no dispositivo (RF14).
class PreferenciasAparencia {
  const PreferenciasAparencia({
    this.tamanhoLetra = TamanhoLetra.normal,
  });

  final TamanhoLetra tamanhoLetra;
}

abstract class PreferenciasRepository {
  /// Nunca lança: sem leitura, valem as preferências padrão.
  Future<PreferenciasAparencia> ler();

  /// Lança em caso de falha.
  Future<void> salvar(PreferenciasAparencia preferencias);
}

/// Escala do texto com a preferência do app sobre a do aparelho: vale a
/// maior das duas, para o app nunca diminuir a letra que a pessoa já
/// ampliou no celular.
TextScaler aplicarTamanhoLetra(TextScaler doAparelho, TamanhoLetra tamanho) {
  if (tamanho == TamanhoLetra.normal) return doAparelho;
  const base = 16.0;
  return doAparelho.scale(base) / base >= tamanho.fator
      ? doAparelho
      : TextScaler.linear(tamanho.fator);
}

/// Preferências em uso no app, lidas na abertura e alteradas pelo perfil.
/// A tela muda na hora; a gravação no dispositivo vem em seguida.
class ControlePreferencias extends ChangeNotifier {
  ControlePreferencias(
    this._repositorio, [
    this._atual = const PreferenciasAparencia(),
  ]);

  final PreferenciasRepository _repositorio;
  PreferenciasAparencia _atual;

  PreferenciasAparencia get atual => _atual;

  /// Lê as preferências gravadas; sem leitura, ficam as padrão.
  static Future<ControlePreferencias> carregar(
    PreferenciasRepository repositorio,
  ) async =>
      ControlePreferencias(repositorio, await repositorio.ler());

  /// Lança se a gravação falhar; a preferência continua aplicada nesta
  /// sessão.
  Future<void> mudarTamanhoLetra(TamanhoLetra tamanho) => _mudar(
        PreferenciasAparencia(tamanhoLetra: tamanho),
      );

  Future<void> _mudar(PreferenciasAparencia novas) async {
    _atual = novas;
    notifyListeners();
    await _repositorio.salvar(novas);
  }
}

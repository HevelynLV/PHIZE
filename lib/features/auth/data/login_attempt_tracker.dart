import 'package:shared_preferences/shared_preferences.dart';

/// Contador de tentativas de login malsucedidas, persistido no dispositivo.
/// Serve apenas como camada de interface (aviso/bloqueio temporário na tela)
/// — a proteção real contra força bruta é o throttling server-side do
/// Firebase Auth (erro `too-many-requests`).
class LoginAttemptTracker {
  LoginAttemptTracker({DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now;

  final DateTime Function() _relogio;

  /// Quantidade de falhas consecutivas que aciona o bloqueio temporário.
  static const int limiteTentativas = 5;

  /// Duração do bloqueio temporário. Valor provisório — ver nota no
  /// CLAUDE.md, pendente de decisão da equipe.
  static const Duration duracaoBloqueio = Duration(minutes: 15);

  static const String _chaveTentativas = 'login_tentativas_falhas';
  static const String _chaveBloqueadoEm = 'login_bloqueado_em';

  Future<int> tentativasFalhas() async {
    await _liberarSeExpirado();
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getInt(_chaveTentativas) ?? 0;
  }

  Future<bool> bloqueado() async {
    await _liberarSeExpirado();
    final preferencias = await SharedPreferences.getInstance();
    return (preferencias.getInt(_chaveTentativas) ?? 0) >= limiteTentativas;
  }

  Future<int> registrarFalha() async {
    final preferencias = await SharedPreferences.getInstance();
    final tentativas = (preferencias.getInt(_chaveTentativas) ?? 0) + 1;
    await preferencias.setInt(_chaveTentativas, tentativas);
    if (tentativas >= limiteTentativas) {
      await preferencias.setInt(
        _chaveBloqueadoEm,
        _relogio().millisecondsSinceEpoch,
      );
    }
    return tentativas;
  }

  Future<void> resetar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chaveTentativas);
    await preferencias.remove(_chaveBloqueadoEm);
  }

  Future<void> _liberarSeExpirado() async {
    final preferencias = await SharedPreferences.getInstance();
    final bloqueadoEmMs = preferencias.getInt(_chaveBloqueadoEm);
    if (bloqueadoEmMs == null) return;

    final bloqueadoEm = DateTime.fromMillisecondsSinceEpoch(bloqueadoEmMs);
    if (_relogio().difference(bloqueadoEm) >= duracaoBloqueio) {
      await preferencias.remove(_chaveTentativas);
      await preferencias.remove(_chaveBloqueadoEm);
    }
  }
}

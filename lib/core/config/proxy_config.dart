/// Endereço da camada intermediária (Cloud Functions; arquitetura, seção 2
/// — Proteção de Credenciais).
///
/// Nesta fase o padrão aponta para o emulador local (docs/ROADMAP.md, Fase
/// 5; docs/emulador-local.md). Para usar a Function publicada, basta passar
/// outra URL na compilação, sem alterar código:
///
/// ```
/// flutter run --dart-define=PHIZE_FUNCTIONS_URL=https://southamerica-east1-phize-de7a1.cloudfunctions.net
/// ```
class ProxyConfig {
  ProxyConfig._();

  /// Emulador do Firebase: `http://<host>:<porta>/<projeto>/<região>`.
  static const String urlEmulador =
      'http://127.0.0.1:5001/phize-de7a1/southamerica-east1';

  static const String urlBase = String.fromEnvironment(
    'PHIZE_FUNCTIONS_URL',
    defaultValue: urlEmulador,
  );

  static Uri get reputacaoDominio => Uri.parse('$urlBase/reputacaoDominio');
}

class AuthException implements Exception {
  const AuthException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

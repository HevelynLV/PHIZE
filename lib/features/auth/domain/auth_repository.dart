// Implementações devem converter falhas do provedor em AuthException já
// com mensagem pronta para exibição — a apresentação nunca lida com
// exceções específicas do Firebase.
abstract class AuthRepository {
  Future<void> cadastrar({required String email, required String senha});

  Future<void> entrar({required String email, required String senha});

  Future<void> enviarEmailRedefinicaoSenha(String email);
}

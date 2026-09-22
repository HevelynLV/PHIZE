import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.erroCadastro, this.erroLogin, this.erroRedefinicaoSenha});

  final AuthException? erroCadastro;
  final AuthException? erroLogin;
  final AuthException? erroRedefinicaoSenha;

  String? emailCadastrado;
  String? emailLogado;
  String? emailRedefinicaoSolicitado;

  @override
  Future<void> cadastrar({required String email, required String senha}) async {
    if (erroCadastro != null) throw erroCadastro!;
    emailCadastrado = email;
  }

  @override
  Future<void> entrar({required String email, required String senha}) async {
    if (erroLogin != null) throw erroLogin!;
    emailLogado = email;
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    if (erroRedefinicaoSenha != null) throw erroRedefinicaoSenha!;
    emailRedefinicaoSolicitado = email;
  }
}

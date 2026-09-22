import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/firebase_auth_repository.dart';
import '../../data/login_attempt_tracker.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';
import '../widgets/esqueci_senha_dialog.dart';

/// Tela de Login (RF02 / UC02).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  final LoginAttemptTracker _tentativas = LoginAttemptTracker();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _erroEmail;
  String? _erroSenha;
  String? _erroGeral;
  bool _carregando = false;
  bool _bloqueado = false;

  static const String _mensagemBloqueio =
      'Muitas tentativas de login incorretas. Por segurança, tente '
      'novamente em alguns minutos.';

  @override
  void initState() {
    super.initState();
    _carregarEstadoBloqueio();
  }

  Future<void> _carregarEstadoBloqueio() async {
    final bloqueado = await _tentativas.bloqueado();
    if (!mounted) return;
    setState(() => _bloqueado = bloqueado);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_bloqueado) return;

    final erroEmail = validarEmail(_emailController.text);
    final erroSenha = _senhaController.text.isEmpty ? 'Informe sua senha.' : null;

    setState(() {
      _erroEmail = erroEmail;
      _erroSenha = erroSenha;
      _erroGeral = null;
    });

    if (erroEmail != null || erroSenha != null) return;

    setState(() => _carregando = true);
    try {
      await _authRepository.entrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      await _tentativas.resetar();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on AuthException catch (e) {
      await _tentativas.registrarFalha();
      final bloqueado = await _tentativas.bloqueado();
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _bloqueado = bloqueado;
        _carregando = false;
      });
    }
  }

  void _abrirEsqueciSenha() {
    showDialog<void>(
      context: context,
      builder: (_) => EsqueciSenhaDialog(authRepository: _authRepository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FlutterLogo(size: 64),
              const SizedBox(height: 32),
              if (_bloqueado)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _mensagemBloqueio,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_erroGeral != null && !_bloqueado)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erroGeral!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextField(
                key: const Key('login_email'),
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail', errorText: _erroEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('login_senha'),
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha', errorText: _erroSenha),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _abrirEsqueciSenha,
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (_carregando || _bloqueado) ? null : _entrar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _carregando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cadastro),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

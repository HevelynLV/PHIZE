import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

/// Tela de Cadastro (RF01 / UC01).
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  String? _erroEmail;
  String? _erroSenha;
  String? _erroConfirmarSenha;
  String? _erroGeral;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final erroEmail = validarEmail(_emailController.text);
    final erroSenha = validarSenha(_senhaController.text);
    final senhasDivergem = _senhaController.text != _confirmarSenhaController.text;

    setState(() {
      _erroEmail = erroEmail;
      _erroSenha = erroSenha;
      _erroConfirmarSenha = senhasDivergem ? 'As senhas não coincidem.' : null;
      _erroGeral = null;
    });

    if (erroEmail != null || erroSenha != null || senhasDivergem) return;

    setState(() => _carregando = true);
    try {
      await _authRepository.cadastrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erroGeral != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erroGeral!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextField(
                key: const Key('cadastro_email'),
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail', errorText: _erroEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('cadastro_senha'),
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha', errorText: _erroSenha),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('cadastro_confirmar_senha'),
                controller: _confirmarSenhaController,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  errorText: _erroConfirmarSenha,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _carregando ? null : _cadastrar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _carregando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar conta'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

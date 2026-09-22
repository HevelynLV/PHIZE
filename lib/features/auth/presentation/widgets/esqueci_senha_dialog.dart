import 'package:flutter/material.dart';

import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

class EsqueciSenhaDialog extends StatefulWidget {
  const EsqueciSenhaDialog({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<EsqueciSenhaDialog> createState() => _EsqueciSenhaDialogState();
}

class _EsqueciSenhaDialogState extends State<EsqueciSenhaDialog> {
  final _emailController = TextEditingController();
  String? _erroEmail;
  String? _mensagem;
  bool _carregando = false;

  static const String _mensagemGenerica =
      'Se este e-mail estiver cadastrado, você receberá um link para '
      'redefinir sua senha.';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final erroEmail = validarEmail(_emailController.text);
    setState(() {
      _erroEmail = erroEmail;
      _mensagem = null;
    });
    if (erroEmail != null) return;

    setState(() => _carregando = true);
    try {
      await widget.authRepository.enviarEmailRedefinicaoSenha(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _mensagem = _mensagemGenerica;
        _carregando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagem = e.mensagem;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Esqueci minha senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail usado no cadastro para receber o link de '
            'redefinição de senha.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('redefinicao_email'),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail',
              errorText: _erroEmail,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_mensagem != null) ...[
            const SizedBox(height: 16),
            Text(_mensagem!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _carregando ? null : _enviar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';

/// Tela de Login (RF02). Apenas layout — sem autenticação real ainda.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FlutterLogo(size: 64),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.dashboard),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Entrar'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.cadastro),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}

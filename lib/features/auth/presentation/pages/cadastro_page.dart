import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';

/// Tela de Cadastro (RF01). Apenas layout — sem criação de conta real ainda.
class CadastroPage extends StatelessWidget {
  const CadastroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Confirmar senha'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.dashboard),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Criar conta'),
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
    );
  }
}

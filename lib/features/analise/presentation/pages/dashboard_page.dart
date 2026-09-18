import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../domain/analise_risco.dart';
import '../../domain/faixa_risco.dart';
import '../widgets/phize_bottom_nav.dart';

/// Painel inicial: ponto de entrada para analisar link ou print (RF03/RF04).
/// Dado fictício embutido — sem chamada a serviço algum.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static final AnaliseRisco _analiseFicticia = AnaliseRisco(
    id: 'demo-link',
    score: 62,
    faixa: FaixaRisco.medio,
    explicacao:
        'A mensagem pede troca de contato para fora do aplicativo oficial e '
        'menciona uma oferta com retorno acima do praticado no mercado.',
    sinais: const [
      'Alegação de troca de contato',
      'Oferta incompatível com o mercado',
    ],
    data: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phize')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, Maria',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text('O que você recebeu e quer verificar?'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.resultado,
                arguments: _analiseFicticia,
              ),
              icon: const Icon(Icons.link),
              label: const Text('Analisar link'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Analisar print'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Disponível apenas em dispositivos móveis (Android/iOS), '
                'via compartilhamento nativo de imagem.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 0),
    );
  }
}

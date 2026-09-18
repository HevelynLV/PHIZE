import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';

/// Navegação inferior compartilhada entre Painel e Histórico — as duas
/// únicas telas da feature analise que precisam dela.
class PhizeBottomNav extends StatelessWidget {
  const PhizeBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        final route = index == 0 ? AppRoutes.dashboard : AppRoutes.historico;
        Navigator.of(context).pushReplacementNamed(route);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
      ],
    );
  }
}

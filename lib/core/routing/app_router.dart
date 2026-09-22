import 'package:flutter/material.dart';

import '../../features/analise/domain/analise_risco.dart';
import '../../features/analise/presentation/pages/dashboard_page.dart';
import '../../features/analise/presentation/pages/historico_page.dart';
import '../../features/analise/presentation/pages/resultado_analise_page.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<void> onGenerateRoute(
    RouteSettings settings, {
    AuthRepository? authRepository,
  }) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(authRepository: authRepository),
        );
      case AppRoutes.cadastro:
        return MaterialPageRoute(
          builder: (_) => CadastroPage(authRepository: authRepository),
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case AppRoutes.historico:
        return MaterialPageRoute(builder: (_) => const HistoricoPage());
      case AppRoutes.resultado:
        final analise = settings.arguments as AnaliseRisco;
        return MaterialPageRoute(
          builder: (_) => ResultadoAnalisePage(analise: analise),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(authRepository: authRepository),
        );
    }
  }
}

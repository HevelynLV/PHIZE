import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const PhizeApp());
}

class PhizeApp extends StatelessWidget {
  const PhizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

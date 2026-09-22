import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/auth/data/login_attempt_tracker.dart';
import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/main.dart';

import 'support/fake_auth_repository.dart';

Widget telaLogin(FakeAuthRepository repo) {
  return MaterialApp(
    onGenerateRoute: (settings) =>
        AppRouter.onGenerateRoute(settings, authRepository: repo),
    initialRoute: AppRoutes.login,
  );
}

Widget telaCadastro(FakeAuthRepository repo) {
  return MaterialApp(
    onGenerateRoute: (settings) =>
        AppRouter.onGenerateRoute(settings, authRepository: repo),
    initialRoute: AppRoutes.cadastro,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App abre na tela de Login', (WidgetTester tester) async {
    await tester.pumpWidget(const PhizeApp());

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('Login com sucesso navega para o Dashboard', (tester) async {
    await tester.pumpWidget(telaLogin(FakeAuthRepository()));

    await tester.enterText(find.byKey(const Key('login_email')), 'maria@exemplo.com');
    await tester.enterText(find.byKey(const Key('login_senha')), 'senha1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Phize'), findsOneWidget);
  });

  testWidgets('Login com credenciais inválidas mostra mensagem genérica e não navega', (tester) async {
    final repo = FakeAuthRepository(
      erroLogin: const AuthException('E-mail ou senha incorretos.'),
    );
    await tester.pumpWidget(telaLogin(repo));

    await tester.enterText(find.byKey(const Key('login_email')), 'maria@exemplo.com');
    await tester.enterText(find.byKey(const Key('login_senha')), 'senhaerrada');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.text('Phize'), findsNothing);
  });

  testWidgets('Esqueci minha senha mostra mensagem genérica', (tester) async {
    await tester.pumpWidget(telaLogin(FakeAuthRepository()));

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('redefinicao_email')), 'qualquer@exemplo.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Se este e-mail estiver cadastrado, você receberá um link para '
        'redefinir sua senha.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Após 5 tentativas de login inválidas, o botão Entrar é bloqueado temporariamente', (tester) async {
    final repo = FakeAuthRepository(
      erroLogin: const AuthException('E-mail ou senha incorretos.'),
    );
    await tester.pumpWidget(telaLogin(repo));

    for (var i = 0; i < LoginAttemptTracker.limiteTentativas; i++) {
      await tester.enterText(find.byKey(const Key('login_email')), 'maria@exemplo.com');
      await tester.enterText(find.byKey(const Key('login_senha')), 'senhaerrada');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();
    }

    expect(
      find.text(
        'Muitas tentativas de login incorretas. Por segurança, tente '
        'novamente em alguns minutos.',
      ),
      findsOneWidget,
    );

    final botaoEntrar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Entrar'),
    );
    expect(botaoEntrar.onPressed, isNull);
  });

  testWidgets('Cadastro com senha curta mostra erro local e não chama o repositório', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(telaCadastro(repo));

    await tester.enterText(find.byKey(const Key('cadastro_email')), 'nova@exemplo.com');
    await tester.enterText(find.byKey(const Key('cadastro_senha')), '123');
    await tester.enterText(find.byKey(const Key('cadastro_confirmar_senha')), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);
    expect(repo.emailCadastrado, isNull);
  });

  testWidgets('Cadastro com sucesso navega direto ao Dashboard', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(telaCadastro(repo));

    await tester.enterText(find.byKey(const Key('cadastro_email')), 'nova@exemplo.com');
    await tester.enterText(find.byKey(const Key('cadastro_senha')), 'senha1234');
    await tester.enterText(find.byKey(const Key('cadastro_confirmar_senha')), 'senha1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Phize'), findsOneWidget);
    expect(repo.emailCadastrado, 'nova@exemplo.com');
  });

  testWidgets('Cadastro com e-mail já cadastrado mostra aviso do servidor', (tester) async {
    final repo = FakeAuthRepository(
      erroCadastro: const AuthException(
        'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.',
      ),
    );
    await tester.pumpWidget(telaCadastro(repo));

    await tester.enterText(find.byKey(const Key('cadastro_email')), 'ja@existe.com');
    await tester.enterText(find.byKey(const Key('cadastro_senha')), 'senha1234');
    await tester.enterText(find.byKey(const Key('cadastro_confirmar_senha')), 'senha1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.'),
      findsOneWidget,
    );
  });

  testWidgets('Dashboard -> Analisar link -> Resultado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.dashboard,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phize'), findsOneWidget);

    final analisarPrint = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Analisar print'),
    );
    expect(analisarPrint.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Analisar link'));
    await tester.pumpAndSettle();

    expect(find.text('Resultado da Análise'), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  });

  testWidgets('Histórico mostra as três faixas e navega ao Resultado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.historico,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsOneWidget);

    await tester.tap(find.text(RotulosRisco.altoRisco));
    await tester.pumpAndSettle();

    expect(find.text('Resultado da Análise'), findsOneWidget);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  });
}

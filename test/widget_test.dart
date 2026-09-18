import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/main.dart';

void main() {
  testWidgets('App abre na tela de Login', (WidgetTester tester) async {
    await tester.pumpWidget(const PhizeApp());

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('Login -> Dashboard -> Analisar link -> Resultado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PhizeApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Phize'), findsOneWidget);

    // Botão "Analisar print" deve estar visível, porém desabilitado.
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

  testWidgets('Histórico mostra as três faixas e navega ao Resultado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PhizeApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Histórico'));
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

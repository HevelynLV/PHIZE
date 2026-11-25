import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/preferencias_aparencia.dart';

/// Disponibiliza as preferências de acessibilidade (RF14) para o app
/// inteiro e aplica o tamanho da letra em todas as telas.
class EscopoPreferencias extends InheritedNotifier<ControlePreferencias> {
  const EscopoPreferencias({
    super.key,
    required ControlePreferencias controle,
    required super.child,
  }) : super(notifier: controle);

  /// `null` fora do app, como em testes de uma tela isolada.
  static ControlePreferencias? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EscopoPreferencias>()
      ?.notifier;
}

/// Monta o [MaterialApp] com o tema do app e o tamanho da letra escolhido.
/// [construir] recebe o tema e o `builder` a repassar.
class AparenciaApp extends StatelessWidget {
  const AparenciaApp({
    super.key,
    required this.controle,
    required this.construir,
  });

  final ControlePreferencias controle;
  final Widget Function(ThemeData tema, TransitionBuilder builder) construir;

  @override
  Widget build(BuildContext context) {
    return EscopoPreferencias(
      controle: controle,
      child: ListenableBuilder(
        listenable: controle,
        builder: (context, _) {
          final preferencias = controle.atual;
          return construir(
            AppTheme.noturno,
            (context, filho) {
              final consulta = MediaQuery.of(context);
              return MediaQuery(
                data: consulta.copyWith(
                  textScaler: aplicarTamanhoLetra(
                    consulta.textScaler,
                    preferencias.tamanhoLetra,
                  ),
                ),
                // Ícones claros na barra de status: o fundo é sempre escuro.
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light,
                  child: filho ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

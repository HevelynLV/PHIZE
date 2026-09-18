import 'package:flutter/material.dart';

import 'rotulos_risco.dart';

/// As três faixas do Score de Risco (RF07), na escala semafórica.
enum FaixaRisco { baixo, medio, alto }

extension FaixaRiscoRotulo on FaixaRisco {
  String get rotulo => switch (this) {
        FaixaRisco.baixo => RotulosRisco.baixoRisco,
        FaixaRisco.medio => RotulosRisco.medioRisco,
        FaixaRisco.alto => RotulosRisco.altoRisco,
      };

  Color get cor => switch (this) {
        FaixaRisco.baixo => Colors.green,
        FaixaRisco.medio => Colors.amber.shade800,
        FaixaRisco.alto => Colors.red,
      };
}

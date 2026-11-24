import 'package:flutter/material.dart';

/// Paleta da direção visual "Leve", no tema claro. As cores do veredito
/// ficam em `FaixaRisco`, porque carregam o significado do semáforo (RF07).
///
/// Telas devem ler as cores por [CoresDoTema.cores], que acompanha o tema
/// escolhido no perfil (RF14). Usar estas constantes direto só onde o
/// desenho é sempre claro, como a tela simulada dentro do tutorial.
class CoresPhize {
  CoresPhize._();

  static const Color azul = Color(0xFF3B5BDB);
  static const Color azulEscuro = Color(0xFF2B46B8);
  static const Color azulClaro = Color(0xFFEEF2FF);
  static const Color tinta = Color(0xFF111B3D);
  static const Color textoSecundario = Color(0xFF56607A);
  static const Color fundoSuave = Color(0xFFF5F6FA);
  static const Color borda = Color(0xFFDDE1EC);
  static const Color erro = Color(0xFFB42318);
  static const Color erroClaro = Color(0xFFFEECEB);
}

/// Cores da marca no tema em uso (RF14). No escuro, todo texto mantém
/// contraste de pelo menos 4,5:1 sobre o fundo e as superfícies.
@immutable
class CoresTema extends ThemeExtension<CoresTema> {
  const CoresTema({
    required this.azul,
    required this.azulEscuro,
    required this.azulClaro,
    required this.tinta,
    required this.textoSecundario,
    required this.fundo,
    required this.superficie,
    required this.fundoSuave,
    required this.borda,
    required this.erro,
    required this.erroClaro,
  });

  static const CoresTema claro = CoresTema(
    azul: CoresPhize.azul,
    azulEscuro: CoresPhize.azulEscuro,
    azulClaro: CoresPhize.azulClaro,
    tinta: CoresPhize.tinta,
    textoSecundario: CoresPhize.textoSecundario,
    fundo: Colors.white,
    superficie: Colors.white,
    fundoSuave: CoresPhize.fundoSuave,
    borda: CoresPhize.borda,
    erro: CoresPhize.erro,
    erroClaro: CoresPhize.erroClaro,
  );

  /// Azul-marinho do app (RF14: um só tema).
  /// Todo texto mantém contraste de pelo menos 4,5:1.
  static const CoresTema noturno = CoresTema(
    azul: Color(0xFF8FA0FF),
    azulEscuro: Color(0xFFC9D4FF),
    azulClaro: Color(0xFF1B2666),
    tinta: Color(0xFFEEF0FA),
    textoSecundario: Color(0xFFA3A9D6),
    fundo: Color(0xFF050A24),
    superficie: Color(0xFF0E1233),
    fundoSuave: Color(0xFF151C4A),
    borda: Color(0xFF2B3A7A),
    erro: Color(0xFFFF8A80),
    erroClaro: Color(0xFF3D1A2A),
  );

  /// Destaque: botões, ícones ativos e progresso.
  final Color azul;

  /// Texto sobre [azulClaro].
  final Color azulEscuro;

  /// Fundo de destaque suave.
  final Color azulClaro;

  /// Texto principal.
  final Color tinta;
  final Color textoSecundario;

  /// Fundo das telas.
  final Color fundo;

  /// Cartões e seções.
  final Color superficie;

  /// Campos e cartões discretos.
  final Color fundoSuave;
  final Color borda;
  final Color erro;
  final Color erroClaro;

  @override
  CoresTema copyWith({
    Color? azul,
    Color? azulEscuro,
    Color? azulClaro,
    Color? tinta,
    Color? textoSecundario,
    Color? fundo,
    Color? superficie,
    Color? fundoSuave,
    Color? borda,
    Color? erro,
    Color? erroClaro,
  }) {
    return CoresTema(
      azul: azul ?? this.azul,
      azulEscuro: azulEscuro ?? this.azulEscuro,
      azulClaro: azulClaro ?? this.azulClaro,
      tinta: tinta ?? this.tinta,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      fundo: fundo ?? this.fundo,
      superficie: superficie ?? this.superficie,
      fundoSuave: fundoSuave ?? this.fundoSuave,
      borda: borda ?? this.borda,
      erro: erro ?? this.erro,
      erroClaro: erroClaro ?? this.erroClaro,
    );
  }

  @override
  CoresTema lerp(CoresTema? other, double t) {
    if (other == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoresTema(
      azul: m(azul, other.azul),
      azulEscuro: m(azulEscuro, other.azulEscuro),
      azulClaro: m(azulClaro, other.azulClaro),
      tinta: m(tinta, other.tinta),
      textoSecundario: m(textoSecundario, other.textoSecundario),
      fundo: m(fundo, other.fundo),
      superficie: m(superficie, other.superficie),
      fundoSuave: m(fundoSuave, other.fundoSuave),
      borda: m(borda, other.borda),
      erro: m(erro, other.erro),
      erroClaro: m(erroClaro, other.erroClaro),
    );
  }
}

extension CoresDoTema on BuildContext {
  /// Cores da marca no tema em uso; sem a extensão no tema, as do claro.
  CoresTema get cores =>
      Theme.of(this).extension<CoresTema>() ?? CoresTema.claro;
}

class AppTheme {
  AppTheme._();

  static const double _raio = 18;

  /// Só para o celular desenhado dentro do tutorial, sempre claro.
  static ThemeData get light => _construir(CoresTema.claro, Brightness.light);

  /// Tema do app.
  static final ThemeData noturno = _construir(
    CoresTema.noturno,
    Brightness.dark,
  );

  static ThemeData _construir(CoresTema c, Brightness brilho) {
    final escuro = brilho == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brilho,
      primary: c.azul,
      onPrimary: escuro ? c.fundo : Colors.white,
      secondary: c.azul,
      onSecondary: escuro ? c.fundo : Colors.white,
      secondaryContainer: c.azulClaro,
      onSecondaryContainer: c.azulEscuro,
      surface: c.superficie,
      onSurface: c.tinta,
      onSurfaceVariant: c.textoSecundario,
      surfaceContainerLowest: c.fundo,
      surfaceContainerLow: c.superficie,
      surfaceContainer: c.superficie,
      surfaceContainerHigh: c.fundoSuave,
      surfaceContainerHighest: c.fundoSuave,
      outline: c.borda,
      outlineVariant: c.borda,
      error: c.erro,
      onError: escuro ? c.fundo : Colors.white,
      errorContainer: c.erroClaro,
      onErrorContainer: c.erro,
      inverseSurface: escuro ? c.tinta : CoresPhize.tinta,
      onInverseSurface: escuro ? c.fundo : Colors.white,
    );

    final formaBotao = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_raio),
    );
    const textoBotao = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );
    const tamanhoBotao = Size.fromHeight(60);
    final bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: colorScheme,
      extensions: [c],
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: c.fundo,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 17, height: 1.45),
        bodyMedium: TextStyle(fontSize: 16, height: 1.45),
        bodySmall: TextStyle(fontSize: 14, height: 1.4),
      ).apply(bodyColor: c.tinta, displayColor: c.tinta),
      appBarTheme: AppBarTheme(
        // No app, a barra deixa ver o fundo ilustrado da tela.
        backgroundColor: escuro ? Colors.transparent : c.fundo,
        foregroundColor: c.tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: c.tinta,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamanhoBotao,
          shape: formaBotao,
          textStyle: textoBotao,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamanhoBotao,
          shape: formaBotao,
          textStyle: textoBotao,
          side: BorderSide(color: c.borda),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textoBotao.copyWith(fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.fundoSuave,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: bordaCampo,
        enabledBorder: bordaCampo,
        focusedBorder: bordaCampo.copyWith(
          borderSide: BorderSide(color: c.azul, width: 2),
        ),
        errorBorder: bordaCampo.copyWith(
          borderSide: BorderSide(color: c.erro),
        ),
        focusedErrorBorder: bordaCampo.copyWith(
          borderSide: BorderSide(color: c.erro, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.fundoSuave,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.fundo,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.azulClaro,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: estados.contains(WidgetState.selected)
                ? c.azulEscuro
                : c.textoSecundario,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

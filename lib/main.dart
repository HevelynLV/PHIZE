import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/emulator_config.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'shared/data/limpeza_copias_seletor.dart';
import 'features/analise/data/receptor_compartilhamento.dart';
import 'features/analise/domain/caixa_compartilhamento.dart';
import 'features/analise/presentation/recepcao_compartilhamento.dart';
import 'features/conta/data/compartilhador_arquivo_nativo.dart';
import 'features/conta/data/conta_repository_firebase.dart';
import 'features/conta/data/preferencias_repository_local.dart';
import 'features/conta/domain/preferencias_aparencia.dart';
import 'features/conta/presentation/escopo_preferencias.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sem await: a varredura de cópias órfãs do seletor (RNF01) nunca lança
  // e não deve atrasar a abertura do app.
  unawaited(LimpezaCopiasSeletor.executar());
  unawaited(CompartilhadorArquivoNativo.removerCopiaLocal());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final emuladores = EmulatorConfig.emuladores;
  final emuladorAuth = emuladores.auth;
  if (emuladorAuth != null) {
    await FirebaseAuth.instance.useAuthEmulator(
      emuladorAuth.host,
      emuladorAuth.porta,
    );
  }
  final emuladorFirestore = emuladores.firestore;
  if (emuladorFirestore != null) {
    FirebaseFirestore.instance.useFirestoreEmulator(
      emuladorFirestore.host,
      emuladorFirestore.porta,
    );
  }
  // Lidas antes do primeiro quadro, para o app já abrir no tema e no
  // tamanho de letra escolhidos (RF14).
  final preferencias = await ControlePreferencias.carregar(
    PreferenciasRepositoryLocal(),
  );
  runApp(
    PhizeApp(rotaInicial: await _rotaInicial(), preferencias: preferencias),
  );
}

/// Com sessão ativa, o app abre direto: é o que permite compartilhar um
/// conteúdo e ver o resultado sem passar pelo login (RF10). Conta com exclusão
/// pendente continua indo para a tela de bloqueio (UC12).
Future<String> _rotaInicial() async {
  final usuario = await FirebaseAuth.instance.authStateChanges().first;
  if (usuario == null) return AppRoutes.login;
  try {
    final pendente = await ContaRepositoryFirebase().exclusaoPendente();
    return pendente ? AppRoutes.exclusaoPendente : AppRoutes.dashboard;
  } catch (_) {
    return AppRoutes.dashboard;
  }
}

class PhizeApp extends StatefulWidget {
  const PhizeApp({
    super.key,
    this.rotaInicial = AppRoutes.login,
    this.preferencias,
  });

  final String rotaInicial;

  /// Sem valor, as preferências padrão, gravadas no aparelho ao mudar.
  final ControlePreferencias? preferencias;

  @override
  State<PhizeApp> createState() => _PhizeAppState();
}

class _PhizeAppState extends State<PhizeApp> {
  final _navegador = GlobalKey<NavigatorState>();
  late final ControlePreferencias _preferencias =
      widget.preferencias ??
      ControlePreferencias(PreferenciasRepositoryLocal());

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: o que chegou com o app fechado abre sobre a
    // tela inicial, que precisa já existir.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ouvirCompartilhamento(),
    );
  }

  Future<void> _ouvirCompartilhamento() async {
    final recepcao = RecepcaoCompartilhamento(
      caixa: CaixaCompartilhamento.instancia,
      sessaoAtiva: () => FirebaseAuth.instance.currentUser != null,
      exclusaoPendente: () => ContaRepositoryFirebase().exclusaoPendente(),
      abrirAnalise: () =>
          _navegador.currentState?.pushNamed(AppRoutes.analiseCompartilhada),
    );
    try {
      await ReceptorCompartilhamento().iniciar(recepcao.receber);
    } catch (_) {
      // Sem a ponte nativa, o app segue funcionando pela galeria e pelo campo
      // de link.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AparenciaApp(
      controle: _preferencias,
      construir: (tema, builder) => MaterialApp(
        navigatorKey: _navegador,
        title: 'Phize',
        debugShowCheckedModeBanner: false,
        theme: tema,
        builder: builder,
        // `initialRoute` empilharia também a rota '/', que cai no login: a
        // tela inicial ganharia uma seta para voltar ao login sem encerrar a
        // sessão.
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(RouteSettings(name: widget.rotaInicial)),
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

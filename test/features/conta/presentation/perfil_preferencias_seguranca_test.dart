import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/login_attempt_tracker.dart';
import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';
import 'package:phize/features/conta/domain/espera_reenvio.dart';
import 'package:phize/features/conta/domain/preferencias_aparencia.dart';
import 'package:phize/features/conta/presentation/escopo_preferencias.dart';
import 'package:phize/features/conta/presentation/pages/perfil_page.dart';
import 'package:phize/features/conta/presentation/widgets/trocar_senha_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_consentimento_repository.dart';
import '../../../support/fake_conta_repository.dart';
import '../../../support/fake_historico_repository.dart';
import '../../../support/fake_preferencias_repository.dart';

const _contaGoogle = IdentidadeConta(
  email: 'jose@exemplo.com',
  emailVerificado: true,
  entraComSenha: false,
  entraComGoogle: true,
);

const _contaNaoVerificada = IdentidadeConta(
  email: 'maria@exemplo.com',
  emailVerificado: false,
  entraComSenha: true,
  entraComGoogle: false,
);

/// Abre o perfil dentro do mesmo [AparenciaApp] do app, para as
/// preferências valerem de verdade.
Future<ControlePreferencias> _abrir(
  WidgetTester tester, {
  FakeContaRepository? conta,
  FakePreferenciasRepository? preferencias,
  EsperaReenvio? espera,
}) async {
  final controle = ControlePreferencias(
    preferencias ?? FakePreferenciasRepository(),
  );
  await tester.pumpWidget(
    AparenciaApp(
      controle: controle,
      construir: (tema, builder) => MaterialApp(
        theme: tema,
        builder: builder,
        home: PerfilPage(
          contaRepository: conta ?? FakeContaRepository(),
          historicoRepository: FakeHistoricoRepository(),
          compartilhador: FakeCompartilhador(),
          authRepository: FakeAuthRepository(),
          consentimentoRepository: FakeConsentimentoRepository(),
          esperaReenvio: espera ?? EsperaReenvio(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controle;
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _preencherTroca(
  WidgetTester tester, {
  required String atual,
  required String nova,
  String? confirmacao,
}) async {
  await tester.enterText(find.byKey(const Key('trocar_senha_atual')), atual);
  await tester.enterText(find.byKey(const Key('trocar_senha_nova')), nova);
  await tester.enterText(
    find.byKey(const Key('trocar_senha_confirmacao')),
    confirmacao ?? nova,
  );
  await tester.tap(find.byKey(const Key('trocar_senha_salvar')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('troca de senha (RF14)', () {
    testWidgets('senha atual certa e nova válida trocam a senha', (
      tester,
    ) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(
        tester,
        atual: conta.senhaAtual,
        nova: 'nova-senha-456',
      );

      expect(conta.novaSenhaGravada, 'nova-senha-456');
      expect(find.byType(TrocarSenhaDialog), findsNothing);
      expect(find.text('Senha alterada.'), findsOneWidget);
    });

    testWidgets('senha atual errada mostra o erro e mantém o diálogo', (
      tester,
    ) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(tester, atual: 'errada-000', nova: 'nova-senha-456');

      expect(conta.novaSenhaGravada, isNull);
      expect(find.byType(TrocarSenhaDialog), findsOneWidget);
      expect(find.text('Senha atual incorreta.'), findsOneWidget);
    });

    testWidgets('a falha na troca não conta como tentativa de login', (
      tester,
    ) async {
      await _abrir(tester);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(tester, atual: 'errada-000', nova: 'nova-senha-456');

      expect(await LoginAttemptTracker().tentativasFalhas(), 0);
    });

    testWidgets('senha fraca é recusada antes de chamar o Firebase', (
      tester,
    ) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(tester, atual: conta.senhaAtual, nova: 'curta');

      expect(conta.novaSenhaGravada, isNull);
      expect(
        find.text('A senha deve ter no mínimo 8 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('confirmação diferente é recusada', (tester) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(
        tester,
        atual: conta.senhaAtual,
        nova: 'nova-senha-456',
        confirmacao: 'nova-senha-457',
      );

      expect(conta.novaSenhaGravada, isNull);
      expect(find.text('As senhas não conferem.'), findsOneWidget);
    });

    testWidgets('falha inesperada mostra mensagem sem detalhe técnico', (
      tester,
    ) async {
      final conta = FakeContaRepository()
        ..erroTrocaSenha = StateError('detalhe interno');
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await _preencherTroca(
        tester,
        atual: conta.senhaAtual,
        nova: 'nova-senha-456',
      );

      expect(find.text(TrocarSenhaDialog.mensagemFalha), findsOneWidget);
      expect(find.textContaining('detalhe interno'), findsNothing);
    });

    testWidgets('cancelar não troca nada', (tester) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_trocar_senha');
      await tester.tap(find.byKey(const Key('trocar_senha_cancelar')));
      await tester.pumpAndSettle();

      expect(find.byType(TrocarSenhaDialog), findsNothing);
      expect(conta.novaSenhaGravada, isNull);
    });

    testWidgets('conta do Google não vê a troca de senha', (tester) async {
      await _abrir(
        tester,
        conta: FakeContaRepository()..identidade = _contaGoogle,
      );

      expect(find.byKey(const Key('perfil_trocar_senha')), findsNothing);
      expect(find.byKey(const Key('perfil_senha_google')), findsOneWidget);
      expect(find.byKey(const Key('perfil_reenviar_verificacao')), findsNothing);
    });
  });

  group('verificação do e-mail (RF14)', () {
    testWidgets('e-mail verificado não oferece reenvio', (tester) async {
      await _abrir(tester);
      expect(find.byKey(const Key('perfil_reenviar_verificacao')), findsNothing);
    });

    testWidgets('reenvia e depois pede para esperar', (tester) async {
      final conta = FakeContaRepository()..identidade = _contaNaoVerificada;
      var agora = DateTime(2026, 11, 12, 10);
      await _abrir(
        tester,
        conta: conta,
        espera: EsperaReenvio(relogio: () => agora),
      );

      await _tocar(tester, 'perfil_reenviar_verificacao');
      expect(conta.reenvios, 1);
      expect(find.textContaining('E-mail enviado.'), findsOneWidget);

      ScaffoldMessenger.of(
        tester.element(find.byType(PerfilPage)),
      ).removeCurrentSnackBar();
      agora = agora.add(const Duration(seconds: 20));
      await _tocar(tester, 'perfil_reenviar_verificacao');
      expect(conta.reenvios, 1);
      expect(
        find.text('Aguarde 40 segundos para pedir outro e-mail.'),
        findsOneWidget,
      );

      agora = agora.add(esperaReenvioVerificacao);
      await _tocar(tester, 'perfil_reenviar_verificacao');
      expect(conta.reenvios, 2);
    });

    testWidgets('limite do Firebase aparece como mensagem da tela', (
      tester,
    ) async {
      final conta = FakeContaRepository()
        ..identidade = _contaNaoVerificada
        ..erroReenvio = const AuthException('Aguarde alguns minutos.');
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_reenviar_verificacao');

      expect(find.text('Aguarde alguns minutos.'), findsOneWidget);
    });

    testWidgets('ao abrir, busca o estado atual do e-mail', (tester) async {
      final conta = FakeContaRepository()
        ..identidade = _contaNaoVerificada
        ..identidadeAtualizada = const IdentidadeConta(
          email: 'maria@exemplo.com',
          emailVerificado: true,
          entraComSenha: true,
          entraComGoogle: false,
        );
      await _abrir(tester, conta: conta);

      expect(find.byKey(const Key('perfil_email_verificado')), findsOneWidget);
      expect(find.byKey(const Key('perfil_reenviar_verificacao')), findsNothing);
    });

    testWidgets('sem conexão, fica o estado já conhecido', (tester) async {
      final conta = FakeContaRepository()
        ..identidade = _contaNaoVerificada
        ..falhaAtualizarIdentidade = true;
      await _abrir(tester, conta: conta);

      expect(find.byKey(const Key('perfil_email_pendente')), findsOneWidget);
    });
  });

  group('acessibilidade (RF14)', () {
    testWidgets('o app tem um só tema, azul-marinho, sem opção no perfil', (
      tester,
    ) async {
      await _abrir(tester, preferencias: FakePreferenciasRepository());
      expect(
        Theme.of(tester.element(find.byType(PerfilPage))).brightness,
        Brightness.dark,
      );
      expect(find.byKey(const Key('perfil_tema')), findsNothing);
    });

    testWidgets('escolher letra muito grande amplia o texto de todas as telas', (
      tester,
    ) async {
      final preferencias = FakePreferenciasRepository();
      await _abrir(tester, preferencias: preferencias);

      await _tocar(tester, 'perfil_tamanho_letra');
      await tester.tap(find.byKey(const Key('tamanho_letra_muitoGrande')));
      await tester.pumpAndSettle();

      final escala = MediaQuery.textScalerOf(
        tester.element(find.byType(PerfilPage)),
      );
      expect(escala.scale(16) / 16, TamanhoLetra.muitoGrande.fator);
      expect(preferencias.gravadas.tamanhoLetra, TamanhoLetra.muitoGrande);
      expect(tester.takeException(), isNull);
    });

    testWidgets('preferência gravada já vale ao abrir', (tester) async {
      final preferencias = FakePreferenciasRepository(
        gravadas: const PreferenciasAparencia(
          tamanhoLetra: TamanhoLetra.grande,
        ),
      );
      final controle = await ControlePreferencias.carregar(preferencias);
      await tester.pumpWidget(
        AparenciaApp(
          controle: controle,
          construir: (tema, builder) => MaterialApp(
            theme: tema,
            builder: builder,
            home: const Scaffold(body: Text('tela')),
          ),
        ),
      );

      final contexto = tester.element(find.text('tela'));
      expect(Theme.of(contexto).brightness, Brightness.dark);
      expect(
        MediaQuery.textScalerOf(contexto).scale(16) / 16,
        TamanhoLetra.grande.fator,
      );
    });

    testWidgets('falha ao gravar avisa e mantém a escolha nesta sessão', (
      tester,
    ) async {
      await _abrir(
        tester,
        preferencias: FakePreferenciasRepository(falhaAoSalvar: true),
      );

      await _tocar(tester, 'perfil_tamanho_letra');
      await tester.tap(find.byKey(const Key('tamanho_letra_grande')));
      await tester.pumpAndSettle();

      expect(find.text(PerfilPage.mensagemFalhaPreferencia), findsOneWidget);
      final escala = MediaQuery.textScalerOf(
        tester.element(find.byType(PerfilPage)),
      );
      expect(escala.scale(16) / 16, TamanhoLetra.grande.fator);
    });
  });
}

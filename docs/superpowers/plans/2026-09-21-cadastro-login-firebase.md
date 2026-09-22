# Cadastro e Login com Firebase Authentication — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement UC01 (Cadastrar Usuário) and UC02 (Realizar Login) with Firebase Authentication + Cloud Firestore, exactly as scoped in the user's 7-point instructions, without social login.

**Architecture:** A `AuthRepository` abstract interface (domain) decouples the Firebase-specific implementation (`FirebaseAuthRepository`, data layer) from the presentation layer, so `LoginPage`/`CadastroPage` can be widget-tested with a hand-written `FakeAuthRepository` — no real Firebase call is ever made in tests. Pure logic (email/password validation, Firebase error → generic Portuguese message mapping, local login-attempt counter) lives in small, independently unit-testable files. `AppRouter.onGenerateRoute` gains an optional `authRepository` parameter so tests can inject the fake through full navigation; production code leaves it `null` and the pages construct the real `FirebaseAuthRepository`.

**Tech Stack:** Flutter/Dart, `firebase_core`, `firebase_auth`, `cloud_firestore`, `shared_preferences` (device-persisted login-attempt counter).

**Spec:** `docs/casos-de-uso.md` (UC01, UC02), `docs/requisitos.md` (RF01, RF02), `CLAUDE.md` (RNF01 data-minimization rule), and the user's 7-point instruction message reproduced below for traceability:

1. Add `firebase_core`, `firebase_auth`, `cloud_firestore`; initialize Firebase in `main.dart` via the existing `lib/firebase_options.dart`.
2. Cadastro (UC01/RF01): e-mail + senha only, no social login; local password validation (min 8 chars); send verification e-mail without blocking access (UC01 redirects straight to Dashboard); create `users/{uid}` in Firestore with only `uid`, `email`, creation date (RNF01 minimization).
3. Login (UC02/RF02): "Esqueci minha senha" sends reset e-mail; error messages never reveal whether an e-mail exists — "E-mail ou senha incorretos" for bad credentials, identical response for password reset whether or not the account exists.
4. Block after 5 attempts (RF02): real brute-force protection is Firebase Auth's own `too-many-requests`; keep a local, device-persisted attempt counter that survives app restarts, purely as a UI layer — document in CLAUDE.md that the local counter is not the security barrier.
5. UC01/UC02 exception flows: e-mail already registered, password outside policy, invalid credentials, connection failure.
6. Firestore rules: deny everything by default, allow read/write on `users/{uid}` only when `request.auth.uid == uid`. Do not publish/deploy — the user deploys manually.
7. Unit tests.

## Global Constraints

- Password minimum length: **8 characters** (RF01 critério de aceitação).
- No Google/Apple social login in this pass (explicit user instruction).
- Login/credential errors must use the exact generic message **"E-mail ou senha incorretos."** — never distinguish "user not found" from "wrong password".
- Password-reset flow must show an **identical** message whether or not the e-mail is registered.
- `users/{uid}` Firestore document contains **only** `uid`, `email`, `createdAt` — nothing else (RNF01 data minimization).
- `firestore.rules` denies all access by default; only `users/{uid}` is readable/writable, and only by its own owner. The file is created but **never deployed** by the agent.
- Local login-attempt counter is UI-only; it must never be presented or implemented as the actual brute-force barrier — that is Firebase Auth's server-side throttling.
- Every commit message ends with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

```
lib/features/auth/
  domain/
    auth_exception.dart          # AuthException — carries an already user-facing message
    auth_repository.dart         # abstract AuthRepository contract
    auth_validators.dart         # validarEmail(), validarSenha() — pure functions
  data/
    auth_error_mapper.dart       # mapearErroAutenticacao(FirebaseAuthException) -> String
    firebase_auth_repository.dart# AuthRepository impl wrapping FirebaseAuth + Firestore
    login_attempt_tracker.dart   # device-persisted failed-login counter (UI layer only)
  presentation/
    pages/login_page.dart        # rewritten: real form, validation, submit, attempt banner
    pages/cadastro_page.dart     # rewritten: real form, validation, submit
    widgets/esqueci_senha_dialog.dart

lib/core/routing/app_router.dart # +optional authRepository param for DI in tests

test/
  features/auth/domain/auth_validators_test.dart
  features/auth/data/auth_error_mapper_test.dart
  features/auth/data/login_attempt_tracker_test.dart
  support/fake_auth_repository.dart
  widget_test.dart               # rewritten to use FakeAuthRepository + real navigation

firestore.rules                  # new, repo root
CLAUDE.md                        # +note documenting the login-attempt-counter decision
```

---

### Task 1: Dependencies and Firebase initialization

**Files:**
- Modify: `pubspec.yaml` (via `flutter pub add`, not hand-edited)
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `Firebase.initializeApp()` is called before `runApp` in every later task; no other task depends on symbols from this one besides the packages being resolvable.

- [ ] **Step 1: Add the packages**

Run:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore shared_preferences
```
Expected: `pubspec.yaml` gains the four dependencies and `pubspec.lock`/`.dart_tool` are regenerated without errors.

- [ ] **Step 2: Initialize Firebase in `main.dart`**

Replace the contents of `lib/main.dart` with:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
```

- [ ] **Step 3: Verify the app still analyzes cleanly**

Run: `flutter analyze`
Expected: no new errors (existing pages still compile; they are rewritten in later tasks).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "$(cat <<'EOF'
chore: adiciona firebase_auth, cloud_firestore e shared_preferences; inicializa Firebase

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Auth domain — `AuthException` and validators

**Files:**
- Create: `lib/features/auth/domain/auth_exception.dart`
- Create: `lib/features/auth/domain/auth_validators.dart`
- Test: `test/features/auth/domain/auth_validators_test.dart`

**Interfaces:**
- Produces: `class AuthException implements Exception { const AuthException(String mensagem); final String mensagem; }`
- Produces: `String? validarEmail(String valor)`, `String? validarSenha(String valor)` (return `null` when valid, an error message otherwise).

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/domain/auth_validators_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/domain/auth_validators.dart';

void main() {
  group('validarEmail', () {
    test('rejeita e-mail vazio', () {
      expect(validarEmail(''), 'Informe seu e-mail.');
    });

    test('rejeita e-mail sem formato válido', () {
      expect(validarEmail('nao-e-email'), 'E-mail inválido.');
    });

    test('aceita e-mail válido', () {
      expect(validarEmail('usuario@exemplo.com'), isNull);
    });
  });

  group('validarSenha', () {
    test('rejeita senha com menos de 8 caracteres', () {
      expect(validarSenha('abc123'), 'A senha deve ter no mínimo 8 caracteres.');
    });

    test('aceita senha com 8 caracteres ou mais', () {
      expect(validarSenha('abc12345'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/auth/domain/auth_validators_test.dart`
Expected: FAIL — `package:phize/features/auth/domain/auth_validators.dart` does not exist.

- [ ] **Step 3: Implement**

Create `lib/features/auth/domain/auth_exception.dart`:

```dart
class AuthException implements Exception {
  const AuthException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
```

Create `lib/features/auth/domain/auth_validators.dart`:

```dart
final RegExp _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validarEmail(String valor) {
  final email = valor.trim();
  if (email.isEmpty) return 'Informe seu e-mail.';
  if (!_regexEmail.hasMatch(email)) return 'E-mail inválido.';
  return null;
}

String? validarSenha(String valor) {
  if (valor.length < 8) return 'A senha deve ter no mínimo 8 caracteres.';
  return null;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/auth/domain/auth_validators_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/auth_exception.dart lib/features/auth/domain/auth_validators.dart test/features/auth/domain/auth_validators_test.dart
git commit -m "$(cat <<'EOF'
feat: validação local de e-mail e senha para cadastro/login

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Auth error mapper (Firebase code → generic Portuguese message)

**Files:**
- Create: `lib/features/auth/data/auth_error_mapper.dart`
- Test: `test/features/auth/data/auth_error_mapper_test.dart`

**Interfaces:**
- Consumes: `firebase_auth`'s `FirebaseAuthException` (constructed directly in tests, no Firebase init needed).
- Produces: `String mapearErroAutenticacao(FirebaseAuthException excecao)`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/data/auth_error_mapper_test.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/auth_error_mapper.dart';

void main() {
  test('mapeia email-already-in-use', () {
    final excecao = FirebaseAuthException(code: 'email-already-in-use');
    expect(
      mapearErroAutenticacao(excecao),
      'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.',
    );
  });

  test('mapeia user-not-found, wrong-password e invalid-credential para a mesma mensagem genérica', () {
    for (final codigo in ['user-not-found', 'wrong-password', 'invalid-credential']) {
      final excecao = FirebaseAuthException(code: codigo);
      expect(mapearErroAutenticacao(excecao), 'E-mail ou senha incorretos.');
    }
  });

  test('mapeia too-many-requests', () {
    final excecao = FirebaseAuthException(code: 'too-many-requests');
    expect(
      mapearErroAutenticacao(excecao),
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
    );
  });

  test('mapeia network-request-failed', () {
    final excecao = FirebaseAuthException(code: 'network-request-failed');
    expect(
      mapearErroAutenticacao(excecao),
      'Falha de conexão. Verifique sua internet e tente novamente.',
    );
  });

  test('mapeia código desconhecido para mensagem padrão', () {
    final excecao = FirebaseAuthException(code: 'algum-erro-novo');
    expect(
      mapearErroAutenticacao(excecao),
      'Não foi possível concluir a operação. Tente novamente.',
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/auth/data/auth_error_mapper_test.dart`
Expected: FAIL — `auth_error_mapper.dart` does not exist.

- [ ] **Step 3: Implement**

Create `lib/features/auth/data/auth_error_mapper.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

String mapearErroAutenticacao(FirebaseAuthException excecao) {
  switch (excecao.code) {
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'weak-password':
      return 'A senha deve ter no mínimo 8 caracteres.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    case 'network-request-failed':
      return 'Falha de conexão. Verifique sua internet e tente novamente.';
    default:
      return 'Não foi possível concluir a operação. Tente novamente.';
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/auth/data/auth_error_mapper_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/auth_error_mapper.dart test/features/auth/data/auth_error_mapper_test.dart
git commit -m "$(cat <<'EOF'
feat: mapeia erros do Firebase Auth para mensagens genéricas em português

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Local login-attempt tracker

**Files:**
- Create: `lib/features/auth/data/login_attempt_tracker.dart`
- Test: `test/features/auth/data/login_attempt_tracker_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences.getInstance()` (mocked in tests via `SharedPreferences.setMockInitialValues`).
- Produces: `class LoginAttemptTracker { Future<int> tentativasFalhas(); Future<int> registrarFalha(); Future<void> resetar(); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/data/login_attempt_tracker_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/login_attempt_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('começa em zero tentativas', () async {
    final tracker = LoginAttemptTracker();
    expect(await tracker.tentativasFalhas(), 0);
  });

  test('registrarFalha incrementa e persiste o contador', () async {
    final tracker = LoginAttemptTracker();
    await tracker.registrarFalha();
    await tracker.registrarFalha();
    expect(await tracker.tentativasFalhas(), 2);

    final outraInstancia = LoginAttemptTracker();
    expect(await outraInstancia.tentativasFalhas(), 2);
  });

  test('resetar zera o contador', () async {
    final tracker = LoginAttemptTracker();
    await tracker.registrarFalha();
    await tracker.resetar();
    expect(await tracker.tentativasFalhas(), 0);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/auth/data/login_attempt_tracker_test.dart`
Expected: FAIL — `login_attempt_tracker.dart` does not exist.

- [ ] **Step 3: Implement**

Create `lib/features/auth/data/login_attempt_tracker.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Contador de tentativas de login malsucedidas, persistido no dispositivo.
/// Serve apenas como camada de interface (aviso ao usuário) — a proteção
/// real contra força bruta é o throttling server-side do Firebase Auth.
class LoginAttemptTracker {
  static const String _chave = 'login_tentativas_falhas';

  Future<int> tentativasFalhas() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getInt(_chave) ?? 0;
  }

  Future<int> registrarFalha() async {
    final preferencias = await SharedPreferences.getInstance();
    final tentativas = (preferencias.getInt(_chave) ?? 0) + 1;
    await preferencias.setInt(_chave, tentativas);
    return tentativas;
  }

  Future<void> resetar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chave);
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/auth/data/login_attempt_tracker_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/login_attempt_tracker.dart test/features/auth/data/login_attempt_tracker_test.dart
git commit -m "$(cat <<'EOF'
feat: contador local de tentativas de login (camada de UI, RF02)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: `AuthRepository` contract and `FirebaseAuthRepository` implementation

**Files:**
- Create: `lib/features/auth/domain/auth_repository.dart`
- Create: `lib/features/auth/data/firebase_auth_repository.dart`

**Interfaces:**
- Consumes: `AuthException` (Task 2), `mapearErroAutenticacao` (Task 3).
- Produces: `abstract class AuthRepository { Future<void> cadastrar({required String email, required String senha}); Future<void> entrar({required String email, required String senha}); Future<void> enviarEmailRedefinicaoSenha(String email); }` and `class FirebaseAuthRepository implements AuthRepository`. These exact method names/signatures are used by `LoginPage`, `CadastroPage`, `EsqueciSenhaDialog` and `FakeAuthRepository` in later tasks.

There is no meaningful unit test for `FirebaseAuthRepository` itself — it is a thin wrapper around the `firebase_auth`/`cloud_firestore` SDKs, which require a running platform and are out of scope for `flutter test`. Its error-mapping and validation logic are already covered by Tasks 2–3; its behavior is exercised end-to-end through the widget tests in Tasks 7 and 9 via `FakeAuthRepository`.

- [ ] **Step 1: Create the domain contract**

Create `lib/features/auth/domain/auth_repository.dart`:

```dart
// Implementações devem converter falhas do provedor em AuthException já
// com mensagem pronta para exibição — a apresentação nunca lida com
// exceções específicas do Firebase.
abstract class AuthRepository {
  Future<void> cadastrar({required String email, required String senha});

  Future<void> entrar({required String email, required String senha});

  Future<void> enviarEmailRedefinicaoSenha(String email);
}
```

- [ ] **Step 2: Implement the Firebase-backed repository**

Create `lib/features/auth/data/firebase_auth_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import 'auth_error_mapper.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<void> cadastrar({required String email, required String senha}) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final uid = credencial.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      try {
        await credencial.user!.sendEmailVerification();
      } catch (_) {
        // Falha no envio do e-mail de verificação não bloqueia o cadastro (UC01).
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  @override
  Future<void> entrar({required String email, required String senha}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Nunca revela se a conta existe: mesma resposta (sucesso silencioso).
      if (e.code == 'user-not-found' || e.code == 'invalid-email') return;
      throw AuthException(mapearErroAutenticacao(e));
    }
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/auth`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/domain/auth_repository.dart lib/features/auth/data/firebase_auth_repository.dart
git commit -m "$(cat <<'EOF'
feat: repositório de autenticação com Firebase Auth e Firestore (uid/email/createdAt)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: `FakeAuthRepository` test support

**Files:**
- Create: `test/support/fake_auth_repository.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `AuthException` (Task 2, Task 5).
- Produces: `class FakeAuthRepository implements AuthRepository` with constructor params `erroCadastro`, `erroLogin`, `erroRedefinicaoSenha` (each `AuthException?`, default `null` = success) and readback fields `emailCadastrado`, `emailLogado`, `emailRedefinicaoSolicitado`. Used by `test/widget_test.dart` in Tasks 7 and 9.

- [ ] **Step 1: Implement**

Create `test/support/fake_auth_repository.dart`:

```dart
import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.erroCadastro, this.erroLogin, this.erroRedefinicaoSenha});

  final AuthException? erroCadastro;
  final AuthException? erroLogin;
  final AuthException? erroRedefinicaoSenha;

  String? emailCadastrado;
  String? emailLogado;
  String? emailRedefinicaoSolicitado;

  @override
  Future<void> cadastrar({required String email, required String senha}) async {
    if (erroCadastro != null) throw erroCadastro!;
    emailCadastrado = email;
  }

  @override
  Future<void> entrar({required String email, required String senha}) async {
    if (erroLogin != null) throw erroLogin!;
    emailLogado = email;
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    if (erroRedefinicaoSenha != null) throw erroRedefinicaoSenha!;
    emailRedefinicaoSolicitado = email;
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze test/support`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add test/support/fake_auth_repository.dart
git commit -m "$(cat <<'EOF'
test: adiciona FakeAuthRepository para testes de widget sem Firebase real

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Rewrite `LoginPage` + `EsqueciSenhaDialog`

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Create: `lib/features/auth/presentation/widgets/esqueci_senha_dialog.dart`
- Modify: `lib/core/routing/app_router.dart` (add optional `authRepository` param, needed so the test in Step 1 below can inject `FakeAuthRepository`)

**Interfaces:**
- Consumes: `AuthRepository`, `AuthException` (Task 2/5), `validarEmail` (Task 2), `LoginAttemptTracker` (Task 4), `FirebaseAuthRepository` (Task 5), `FakeAuthRepository` (Task 6).
- Produces: `LoginPage({Key? key, AuthRepository? authRepository})` with `TextField`s keyed `Key('login_email')` / `Key('login_senha')`, a `FilledButton` labeled `'Entrar'`, a `TextButton` labeled `'Esqueci minha senha'`. `EsqueciSenhaDialog({required AuthRepository authRepository})` with `TextField` keyed `Key('redefinicao_email')` and a `FilledButton` labeled `'Enviar'`.

- [ ] **Step 1: Write the failing widget tests**

Replace the contents of `test/widget_test.dart` with (this file is extended further in Tasks 9 and 10; this step only adds the login-related tests and the shared setup — later steps append to it):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
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
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — `AppRouter.onGenerateRoute` does not accept an `authRepository` named parameter yet, and `Key('login_email')` etc. don't exist.

- [ ] **Step 3: Add DI parameter to `AppRouter`**

In `lib/core/routing/app_router.dart`, add the import and change the method signature:

```dart
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
        return MaterialPageRoute(builder: (_) => LoginPage(authRepository: authRepository));
    }
  }
}
```

- [ ] **Step 4: Implement `EsqueciSenhaDialog`**

Create `lib/features/auth/presentation/widgets/esqueci_senha_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

class EsqueciSenhaDialog extends StatefulWidget {
  const EsqueciSenhaDialog({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<EsqueciSenhaDialog> createState() => _EsqueciSenhaDialogState();
}

class _EsqueciSenhaDialogState extends State<EsqueciSenhaDialog> {
  final _emailController = TextEditingController();
  String? _erroEmail;
  String? _mensagem;
  bool _carregando = false;

  static const String _mensagemGenerica =
      'Se este e-mail estiver cadastrado, você receberá um link para '
      'redefinir sua senha.';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final erroEmail = validarEmail(_emailController.text);
    setState(() {
      _erroEmail = erroEmail;
      _mensagem = null;
    });
    if (erroEmail != null) return;

    setState(() => _carregando = true);
    try {
      await widget.authRepository.enviarEmailRedefinicaoSenha(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _mensagem = _mensagemGenerica;
        _carregando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagem = e.mensagem;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Esqueci minha senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail usado no cadastro para receber o link de '
            'redefinição de senha.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('redefinicao_email'),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail',
              errorText: _erroEmail,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_mensagem != null) ...[
            const SizedBox(height: 16),
            Text(_mensagem!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _carregando ? null : _enviar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Rewrite `LoginPage`**

Replace the contents of `lib/features/auth/presentation/pages/login_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/firebase_auth_repository.dart';
import '../../data/login_attempt_tracker.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';
import '../widgets/esqueci_senha_dialog.dart';

/// Tela de Login (RF02 / UC02).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  final LoginAttemptTracker _tentativas = LoginAttemptTracker();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _erroEmail;
  String? _erroSenha;
  String? _erroGeral;
  bool _carregando = false;
  int _tentativasFalhas = 0;

  static const int _limiteAvisoTentativas = 5;

  @override
  void initState() {
    super.initState();
    _carregarTentativas();
  }

  Future<void> _carregarTentativas() async {
    final tentativas = await _tentativas.tentativasFalhas();
    if (!mounted) return;
    setState(() => _tentativasFalhas = tentativas);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final erroEmail = validarEmail(_emailController.text);
    final erroSenha = _senhaController.text.isEmpty ? 'Informe sua senha.' : null;

    setState(() {
      _erroEmail = erroEmail;
      _erroSenha = erroSenha;
      _erroGeral = null;
    });

    if (erroEmail != null || erroSenha != null) return;

    setState(() => _carregando = true);
    try {
      await _authRepository.entrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      await _tentativas.resetar();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on AuthException catch (e) {
      final tentativas = await _tentativas.registrarFalha();
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _tentativasFalhas = tentativas;
        _carregando = false;
      });
    }
  }

  void _abrirEsqueciSenha() {
    showDialog<void>(
      context: context,
      builder: (_) => EsqueciSenhaDialog(authRepository: _authRepository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FlutterLogo(size: 64),
              const SizedBox(height: 32),
              if (_tentativasFalhas >= _limiteAvisoTentativas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Muitas tentativas de login incorretas. Por segurança, '
                    'aguarde alguns minutos antes de tentar novamente.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_erroGeral != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erroGeral!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextField(
                key: const Key('login_email'),
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail', errorText: _erroEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('login_senha'),
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha', errorText: _erroSenha),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _abrirEsqueciSenha,
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _carregando ? null : _entrar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _carregando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cadastro),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (4 tests). Note: `CadastroPage` still has the old placeholder constructor without `authRepository` — Task 8 fixes it; if `flutter analyze`/compilation fails because `AppRouter` now calls `CadastroPage(authRepository: authRepository)` against the old constructor, proceed directly to Task 8 before running the full suite (Task 8 must land before this test run can pass — treat Tasks 7 and 8 as landing together if the compiler blocks an intermediate state).

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/pages/login_page.dart lib/features/auth/presentation/widgets/esqueci_senha_dialog.dart lib/core/routing/app_router.dart test/widget_test.dart
git commit -m "$(cat <<'EOF'
feat: tela de login real com Firebase Auth, esqueci-minha-senha e aviso de tentativas

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Rewrite `CadastroPage`

**Files:**
- Modify: `lib/features/auth/presentation/pages/cadastro_page.dart`
- Modify: `test/widget_test.dart` (append cadastro tests)

**Interfaces:**
- Consumes: `AuthRepository`, `AuthException`, `validarEmail`, `validarSenha`, `FirebaseAuthRepository`, `FakeAuthRepository` (same as Task 7).
- Produces: `CadastroPage({Key? key, AuthRepository? authRepository})` with `TextField`s keyed `Key('cadastro_email')`, `Key('cadastro_senha')`, `Key('cadastro_confirmar_senha')`, and a `FilledButton` labeled `'Criar conta'`.

Note: the current placeholder `CadastroPage` has an extra "Nome" field. RF01 and the user's instructions scope UC01 to **e-mail and password only** (the `users/{uid}` document stores only `uid`, `email`, `createdAt` — a `nome` field would be collected and silently discarded, which is worse than not asking). This step removes the "Nome" field.

- [ ] **Step 1: Append the failing widget tests**

Add to `test/widget_test.dart` (new imports at the top, new `testWidgets` blocks in `main()`, alongside the ones from Task 7):

```dart
// add to the existing imports:
import 'package:phize/features/auth/presentation/pages/login_page.dart';
```

```dart
Widget telaCadastro(FakeAuthRepository repo) {
  return MaterialApp(
    onGenerateRoute: (settings) =>
        AppRouter.onGenerateRoute(settings, authRepository: repo),
    initialRoute: AppRoutes.cadastro,
  );
}
```

```dart
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
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — `CadastroPage` doesn't accept `authRepository`, and the keyed fields don't exist yet.

- [ ] **Step 3: Implement**

Replace the contents of `lib/features/auth/presentation/pages/cadastro_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

/// Tela de Cadastro (RF01 / UC01).
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  String? _erroEmail;
  String? _erroSenha;
  String? _erroConfirmarSenha;
  String? _erroGeral;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final erroEmail = validarEmail(_emailController.text);
    final erroSenha = validarSenha(_senhaController.text);
    final senhasDivergem = _senhaController.text != _confirmarSenhaController.text;

    setState(() {
      _erroEmail = erroEmail;
      _erroSenha = erroSenha;
      _erroConfirmarSenha = senhasDivergem ? 'As senhas não coincidem.' : null;
      _erroGeral = null;
    });

    if (erroEmail != null || erroSenha != null || senhasDivergem) return;

    setState(() => _carregando = true);
    try {
      await _authRepository.cadastrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erroGeral != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erroGeral!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextField(
                key: const Key('cadastro_email'),
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail', errorText: _erroEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('cadastro_senha'),
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha', errorText: _erroSenha),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('cadastro_confirmar_senha'),
                controller: _confirmarSenhaController,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  errorText: _erroConfirmarSenha,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _carregando ? null : _cadastrar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _carregando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar conta'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (7 tests: the 4 from Task 7 plus the 3 added here).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/pages/cadastro_page.dart test/widget_test.dart
git commit -m "$(cat <<'EOF'
feat: tela de cadastro real com Firebase Auth (e-mail/senha, sem login social)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Restore and adapt the pre-existing dashboard/histórico flow tests

**Files:**
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppRouter.onGenerateRoute` (Task 7), `AppRoutes` (existing), `RotulosRisco` (existing).

The original `test/widget_test.dart` had two tests that reached the Dashboard/Histórico by tapping "Entrar" with no credentials (no real auth existed yet). Those two tests are about the dashboard/history features, not auth, so instead of routing them through login they now start directly at the relevant route — avoiding any coupling to `AuthRepository` for tests that aren't about auth.

- [ ] **Step 1: Append these two tests to `test/widget_test.dart`** (add the needed import `package:phize/features/analise/domain/rotulos_risco.dart` at the top)

```dart
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
```

- [ ] **Step 2: Run the full test file**

Run: `flutter test test/widget_test.dart`
Expected: PASS (9 tests total).

- [ ] **Step 3: Run the entire test suite**

Run: `flutter test`
Expected: PASS — all files under `test/` (validators, error mapper, attempt tracker, widget tests) green.

- [ ] **Step 4: Commit**

```bash
git add test/widget_test.dart
git commit -m "$(cat <<'EOF'
test: migra testes de dashboard/histórico para partir direto da rota, sem depender de login

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: `firestore.rules`

**Files:**
- Create: `firestore.rules` (repo root)

**Interfaces:** none (not wired into any Dart build step; deployed manually by the user).

- [ ] **Step 1: Create the file**

Create `firestore.rules`:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }

    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

- [ ] **Step 2: Do not deploy**

Do not run `firebase deploy --only firestore:rules` or any Firebase CLI deploy command — the user deploys this manually, per their explicit instruction.

- [ ] **Step 3: Commit**

```bash
git add firestore.rules
git commit -m "$(cat <<'EOF'
chore: adiciona firestore.rules (nega tudo por padrão, libera users/{uid} ao dono)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: Document the login-attempt-counter decision in `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Append a new section**

Add this section to `CLAUDE.md`, after "## 8. Degradação Controlada":

```markdown

## 9. Nota de Implementação — Contador Local de Tentativas de Login (RF02)

RF02 exige bloqueio temporário após 5 tentativas de login malsucedidas. A
barreira de segurança real é o próprio Firebase Authentication, que aplica
throttling server-side e retorna o erro `too-many-requests` quando aciona o
bloqueio — essa é a proteção efetiva contra força bruta.

`LoginAttemptTracker` (`lib/features/auth/data/login_attempt_tracker.dart`)
mantém um contador local, persistido no dispositivo via `shared_preferences`,
usado exclusivamente para exibir um aviso na tela de login após 5 tentativas
falhas consecutivas. Esse contador:

- Não bloqueia o botão de login nem impede novas tentativas — é somente
  informativo.
- Pode divergir do estado real do Firebase (ex.: reinstalar o app zera o
  contador local, mas não afeta o throttling do lado do servidor).
- É resetado após um login bem-sucedido.

Qualquer alteração nesse componente não deve ser tratada como mecanismo de
segurança — apenas como camada de UX.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: documenta que o contador local de tentativas de login é apenas UI (RF02)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 12: Final verification

**Files:** none (verification only).

- [ ] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: no errors (warnings pre-existing and unrelated to this change are acceptable, but nothing new from the files touched in this plan).

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all tests pass, including:
- `test/features/auth/domain/auth_validators_test.dart`
- `test/features/auth/data/auth_error_mapper_test.dart`
- `test/features/auth/data/login_attempt_tracker_test.dart`
- `test/widget_test.dart` (9 widgets tests)

- [ ] **Step 3: Manual sanity check (optional but recommended)**

Run: `flutter run` on an Android emulator/device, exercise: cadastro with a new e-mail (verify e-mail arrives, Firestore `users/{uid}` doc has only `uid`/`email`/`createdAt`), cadastro with an already-used e-mail, login with wrong password 5×, "esqueci minha senha" with a real and a fake e-mail.

---

## Known Gaps / Escopo Não Coberto

- **Termos de Uso/Privacidade (UC01 fluxo principal, passo 2):** the user's 7-point instructions don't mention a Terms-of-Use acceptance step and no terms document exists in the repo yet; it was intentionally left out of this pass rather than adding a checkbox with no real content behind it. Flag to the user before the next iteration.
- **iOS Firebase config:** `lib/firebase_options.dart` currently only configures Android and Web (`DefaultFirebaseOptions.currentPlatform` throws `UnsupportedError` on iOS). Out of scope for this plan — pre-existing from the `chore: configuracao do firebase` commit.
- **`FirebaseAuthRepository` has no automated test** exercising real Firebase calls (requires the Firebase Local Emulator Suite, not currently set up in this repo). Its logic is covered indirectly: error mapping (Task 3), validators (Task 2), and the full cadastro/login/reset flows via `FakeAuthRepository` in the widget tests (Tasks 7–9).

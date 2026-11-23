import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/marca_phize.dart';
import '../../../analise/domain/caixa_compartilhamento.dart';
import '../../../conta/data/conta_repository_firebase.dart';
import '../../../conta/domain/conta_repository.dart';
import '../../data/firebase_auth_repository.dart';
import '../../data/login_attempt_tracker.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';
import '../widgets/esqueci_senha_dialog.dart';

/// Tela de Login (RF02 / UC02).
///
/// O visual é sempre escuro, nos dois temas: as cores ficam fixas aqui, com
/// texto claro sobre o fundo azul-marinho (contraste de pelo menos 4,5:1).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.authRepository,
    this.contaRepository,
    this.caixaCompartilhamento,
  });

  final AuthRepository? authRepository;

  /// Usado só para conferir se há exclusão de conta pendente (UC12).
  final ContaRepository? contaRepository;

  /// Conteúdo compartilhado aguardando o login (RF10).
  final CaixaCompartilhamento? caixaCompartilhamento;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _fundo = Color(0xFF050A24);
  static const _campo = Color(0xFF0E1233);
  static const _bordaCampo = Color(0xFF2B3A7A);
  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _textoSuave = Color(0xFFA3A9D6);
  static const _erro = Color(0xFFFF8A80);

  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  final LoginAttemptTracker _tentativas = LoginAttemptTracker();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _erroEmail;
  String? _erroSenha;
  String? _erroGeral;
  bool _carregando = false;
  bool _bloqueado = false;
  bool _ocultarSenha = true;

  static const String _mensagemBloqueio =
      'Muitas tentativas de login incorretas. Por segurança, tente '
      'novamente em alguns minutos.';

  @override
  void initState() {
    super.initState();
    _carregarEstadoBloqueio();
  }

  Future<void> _carregarEstadoBloqueio() async {
    final bloqueado = await _tentativas.bloqueado();
    if (!mounted) return;
    setState(() => _bloqueado = bloqueado);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_bloqueado) return;

    final erroEmail = validarEmail(_emailController.text);
    final erroSenha = _senhaController.text.isEmpty
        ? 'Informe sua senha.'
        : null;

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
      await _seguirAposLogin();
    } on AuthException catch (e) {
      await _tentativas.registrarFalha();
      final bloqueado = await _tentativas.bloqueado();
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _bloqueado = bloqueado;
        _carregando = false;
      });
    }
  }

  Future<void> _seguirAposLogin() async {
    final pendente = await _exclusaoPendente();
    if (!mounted) return;
    final navegador = Navigator.of(context);
    navegador.pushReplacementNamed(
      pendente ? AppRoutes.exclusaoPendente : AppRoutes.dashboard,
    );
    if (!pendente && (widget.caixaCompartilhamento?.temPendente ?? false)) {
      navegador.pushNamed(AppRoutes.analiseCompartilhada);
    }
  }

  /// Quem usa o Google não digita senha: esta entrada não conta nas
  /// tentativas de login (RF02).
  Future<void> _entrarComGoogle() async {
    setState(() {
      _erroGeral = null;
      _carregando = true;
    });
    try {
      final entrou = await _authRepository.entrarComGoogle();
      if (entrou) {
        await _seguirAposLogin();
        return;
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _erroGeral = e.mensagem);
    }
    if (mounted) setState(() => _carregando = false);
  }

  /// A marca fica no aparelho; uma falha ao lê-la não impede o login.
  Future<bool> _exclusaoPendente() async {
    try {
      final conta = widget.contaRepository ?? ContaRepositoryFirebase();
      return await conta.exclusaoPendente();
    } catch (_) {
      return false;
    }
  }

  void _abrirEsqueciSenha() {
    showDialog<void>(
      context: context,
      builder: (_) => EsqueciSenhaDialog(authRepository: _authRepository),
    );
  }

  InputDecoration _decoracao({
    required String dica,
    required IconData icone,
    String? erro,
    Widget? sufixo,
  }) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: cor),
        );

    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: _textoSuave, fontSize: 17),
      errorText: erro,
      errorStyle: const TextStyle(color: _erro, fontSize: 14),
      filled: true,
      fillColor: _campo,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icone, color: const Color(0xFFC3C9F7), size: 26),
      ),
      suffixIcon: sufixo,
      contentPadding: const EdgeInsets.symmetric(vertical: 22),
      enabledBorder: borda(_bordaCampo),
      focusedBorder: borda(_roxoClaro),
      errorBorder: borda(_erro),
      focusedErrorBorder: borda(_erro),
      border: borda(_bordaCampo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _FundoPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: MarcaPhize(tamanho: 52),
                      ),
                      const SizedBox(height: 22),
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 0.8,
                              color: Color(0xFFC3C9F7),
                            ),
                            children: [
                              TextSpan(text: 'Aprenda. Evolua. '),
                              TextSpan(
                                text: 'Descubra.',
                                style: TextStyle(color: _roxoClaro),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      if (widget.caixaCompartilhamento case final caixa?)
                        ListenableBuilder(
                          listenable: caixa,
                          builder: (_, _) => caixa.temPendente
                              ? const Padding(
                                  key: Key('login_conteudo_aguardando'),
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Entre na sua conta para ver a análise do '
                                    'que você compartilhou.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      if (_bloqueado)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            _mensagemBloqueio,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _erro, fontSize: 15),
                          ),
                        ),
                      if (_erroGeral != null && !_bloqueado)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _erroGeral!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _erro, fontSize: 15),
                          ),
                        ),
                      TextField(
                        key: const Key('login_email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 17),
                        cursorColor: _roxoClaro,
                        decoration: _decoracao(
                          dica: 'E-mail',
                          icone: Icons.mail_outline,
                          erro: _erroEmail,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        key: const Key('login_senha'),
                        controller: _senhaController,
                        obscureText: _ocultarSenha,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_carregando && !_bloqueado) _entrar();
                        },
                        style:
                            const TextStyle(color: Colors.white, fontSize: 17),
                        cursorColor: _roxoClaro,
                        decoration: _decoracao(
                          dica: 'Senha',
                          icone: Icons.lock_outline,
                          erro: _erroSenha,
                          sufixo: IconButton(
                            tooltip: _ocultarSenha
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () => setState(
                              () => _ocultarSenha = !_ocultarSenha,
                            ),
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textoSuave,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _abrirEsqueciSenha,
                          style: TextButton.styleFrom(
                            foregroundColor: _roxoClaro,
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              decorationColor: _roxoClaro,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BotaoEntrar(
                        carregando: _carregando,
                        habilitado: !_carregando && !_bloqueado,
                        onPressed: _entrar,
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('login_google'),
                          onPressed: _carregando ? null : _entrarComGoogle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            disabledForegroundColor: _textoSuave,
                            minimumSize: const Size.fromHeight(60),
                            side: const BorderSide(color: _bordaCampo),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Continuar com Google'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _CriarConta(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.cadastro),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão principal com degradê e brilho. É um [FilledButton] de verdade
/// (transparente, com o degradê por baixo) para manter a semântica de botão.
class _BotaoEntrar extends StatelessWidget {
  const _BotaoEntrar({
    required this.carregando,
    required this.habilitado,
    required this.onPressed,
  });

  final bool carregando;
  final bool habilitado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado || carregando ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3F8CFF), Color(0xFF3A2BFF), Color(0xFF8B5CFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C6EF5).withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          key: const Key('login_entrar'),
          onPressed: habilitado ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(66),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: carregando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login, size: 26),
                    SizedBox(width: 14),
                    Text('Entrar'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CriarConta extends StatelessWidget {
  const _CriarConta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const linha = Expanded(
      child: Divider(color: Color(0xFF2B3A9A), thickness: 1, height: 1),
    );

    return Row(
      children: [
        linha,
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFA99BFF),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text(
            'Criar conta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        linha,
      ],
    );
  }
}

/// Fundo: duas formas azuis nos cantos, arcos finos e estrelinhas.
class _FundoPainter extends CustomPainter {
  const _FundoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    // Forma do canto superior esquerdo.
    final topo = Path()
      ..moveTo(0, 0)
      ..lineTo(0.42 * w, 0)
      ..cubicTo(0.40 * w, 0.06 * h, 0.24 * w, 0.10 * h, 0, 0.14 * h)
      ..close();
    canvas.drawPath(
      topo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4B4BFF), Color(0xFF0B1450)],
        ).createShader(todo),
    );

    // Forma do canto inferior direito.
    final base = Path()
      ..moveTo(w, h)
      ..lineTo(0.47 * w, h)
      ..cubicTo(0.50 * w, 0.91 * h, 0.74 * w, 0.84 * h, w, 0.85 * h)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0xFF3D4DFF), Color(0xFF0B1450)],
        ).createShader(todo),
    );

    // Arcos finos.
    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(0.05 * w, -0.02 * h), 0.62 * w, arco);
    canvas.drawCircle(Offset(1.05 * w, 1.02 * h), 0.62 * w, arco);

    // Estrelinhas de quatro pontas.
    final brilho = Paint()..color = const Color(0xFF5B8DFF);
    _estrela(canvas, Offset(0.79 * w, 0.19 * h), 0.032 * w, brilho);
    _estrela(canvas, Offset(0.86 * w, 0.225 * h), 0.016 * w, brilho);
    _estrela(canvas, Offset(0.17 * w, 0.205 * h), 0.017 * w, brilho);
    _estrela(canvas, Offset(0.20 * w, 0.825 * h), 0.021 * w, brilho);
    _estrela(canvas, Offset(0.13 * w, 0.875 * h), 0.012 * w, brilho);
  }

  void _estrela(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter antigo) => false;
}
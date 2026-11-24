import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/marca_phize.dart';
import '../../../analise/domain/caixa_compartilhamento.dart';
import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_validators.dart';

/// Tela de Cadastro (RF01 / UC01).
///
/// O visual é sempre escuro, nos dois temas: as cores ficam fixas aqui, com
/// texto claro sobre o fundo azul-marinho (contraste de pelo menos 4,5:1).
class CadastroPage extends StatefulWidget {
  const CadastroPage({
    super.key,
    this.authRepository,
    this.caixaCompartilhamento,
  });

  final AuthRepository? authRepository;

  /// Conteúdo compartilhado aguardando o fim do cadastro (RF10).
  final CaixaCompartilhamento? caixaCompartilhamento;

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  static const _fundo = Color(0xFF050A24);
  static const _campo = Color(0xFF0E1233);
  static const _bordaCampo = Color(0xFF2B3A7A);
  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _textoSuave = Color(0xFFA3A9D6);
  static const _erro = Color(0xFFFF8A80);

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
  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;

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
    final senhasDivergem =
        _senhaController.text != _confirmarSenhaController.text;

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
      final navegador = Navigator.of(context);
      navegador.pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
      if (widget.caixaCompartilhamento?.temPendente ?? false) {
        navegador.pushNamed(AppRoutes.analiseCompartilhada);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _carregando = false;
      });
    }
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
                        child: MarcaPhize(tamanho: 52, cor: Colors.white),
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
                                  key: Key('cadastro_conteudo_aguardando'),
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Crie sua conta para ver a análise do '
                                    'que você compartilhou.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      if (_erroGeral != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _erroGeral!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _erro, fontSize: 15),
                          ),
                        ),
                      TextField(
                        key: const Key('cadastro_email'),
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
                        key: const Key('cadastro_senha'),
                        controller: _senhaController,
                        obscureText: _ocultarSenha,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
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
                      const SizedBox(height: 18),
                      TextField(
                        key: const Key('cadastro_confirmar_senha'),
                        controller: _confirmarSenhaController,
                        obscureText: _ocultarConfirmarSenha,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_carregando) _cadastrar();
                        },
                        style:
                            const TextStyle(color: Colors.white, fontSize: 17),
                        cursorColor: _roxoClaro,
                        decoration: _decoracao(
                          dica: 'Confirmar senha',
                          icone: Icons.lock_outline,
                          erro: _erroConfirmarSenha,
                          sufixo: IconButton(
                            tooltip: _ocultarConfirmarSenha
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () => setState(
                              () => _ocultarConfirmarSenha =
                                  !_ocultarConfirmarSenha,
                            ),
                            icon: Icon(
                              _ocultarConfirmarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textoSuave,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _BotaoCadastrar(
                        carregando: _carregando,
                        habilitado: !_carregando,
                        onPressed: _cadastrar,
                      ),
                      const SizedBox(height: 20),
                      _JaTenhoConta(
                        onPressed: () => Navigator.of(context).pop(),
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
class _BotaoCadastrar extends StatelessWidget {
  const _BotaoCadastrar({
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
          key: const Key('cadastro_criar_conta'),
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
                    Icon(Icons.person_add_alt_1_outlined, size: 26),
                    SizedBox(width: 14),
                    Flexible(child: Text('Criar conta')),
                  ],
                ),
        ),
      ),
    );
  }
}

class _JaTenhoConta extends StatelessWidget {
  const _JaTenhoConta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const linha = Expanded(
      child: Divider(color: Color(0xFF2B3A9A), thickness: 1, height: 1),
    );

    // Com letra muito grande, o botão pode ocupar a linha toda e quebrar.
    return LayoutBuilder(
      builder: (context, limites) => Row(
        children: [
          linha,
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: limites.maxWidth),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA99BFF),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                'Já tenho conta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          linha,
        ],
      ),
    );
  }
}

/// Fundo: fundo azul-marinho padrão, mas com as formas dos cantos,
/// arcos finos e estrelinhas em ciano para diferenciar do Login.
class _FundoPainter extends CustomPainter {
  const _FundoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    // Forma do canto superior esquerdo em ciano.
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
          colors: [Color(0xFF00B4D8), Color(0xFF0A2E46)],
        ).createShader(todo),
    );

    // Forma do canto inferior direito em ciano.
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
          colors: [Color(0xFF00B4D8), Color(0xFF0A2E46)],
        ).createShader(todo),
    );

    // Arcos finos em ciano.
    final arco = Paint()
      ..color = const Color(0xFF0096C7).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(0.05 * w, -0.02 * h), 0.62 * w, arco);
    canvas.drawCircle(Offset(1.05 * w, 1.02 * h), 0.62 * w, arco);

    // Estrelinhas de quatro pontas em ciano.
    final brilho = Paint()..color = const Color(0xFF48CAE4);
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
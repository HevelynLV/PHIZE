import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../auth/data/firebase_auth_repository.dart';
import '../../../auth/domain/auth_exception.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../data/conta_repository_firebase.dart';
import '../../domain/conta_repository.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Conta bloqueada até a exclusão terminar (UC12, "Falha parcial na
/// exclusão"): daqui só se conclui a remoção ou se sai do aplicativo.
class ExclusaoPendentePage extends StatefulWidget {
  const ExclusaoPendentePage({
    super.key,
    this.contaRepository,
    this.authRepository,
  });

  final ContaRepository? contaRepository;
  final AuthRepository? authRepository;

  @override
  State<ExclusaoPendentePage> createState() => _ExclusaoPendentePageState();
}

class _ExclusaoPendentePageState extends State<ExclusaoPendentePage> {
  late final ContaRepository _conta =
      widget.contaRepository ?? ContaRepositoryFirebase();
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  final _senhaController = TextEditingController();

  bool _processando = false;
  String? _erro;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    final senha = _senhaController.text;
    if (_conta.exigeSenha && senha.isEmpty) {
      setState(() => _erro = 'Informe sua senha.');
      return;
    }

    setState(() {
      _processando = true;
      _erro = null;
    });
    final navegador = Navigator.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await _conta.excluirConta(senha: _conta.exigeSenha ? senha : null);
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Sua conta foi excluída.')),
      );
      await navegador.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } on AuthException catch (e) {
      _mostrarErro(e.mensagem);
    } catch (_) {
      _mostrarErro(
        'A exclusão ainda não terminou. Verifique sua conexão e tente '
        'novamente.',
      );
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _processando = false;
      _erro = mensagem;
    });
  }

  Future<void> _sair() async {
    final navegador = Navigator.of(context);
    try {
      await _auth.sair();
    } catch (_) {
      // Mesmo que o encerramento falhe, o login substitui a sessão atual.
    }
    await navegador.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro;

    return PopScope(
      canPop: false,
      child: ScaffoldPhize(
        appBar: AppBar(
          title: const Text('Exclusão não concluída'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'A exclusão da sua conta começou, mas não terminou. Parte '
                  'dos seus dados pode já ter sido apagada, e isso não pode '
                  'ser desfeito. Sua conta fica bloqueada até a exclusão '
                  'terminar.',
                ),
                const SizedBox(height: 16),
                if (_conta.exigeSenha)
                  TextField(
                    key: const Key('exclusao_pendente_senha'),
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Digite sua senha para continuar',
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('exclusao_pendente_concluir'),
                  style: estiloBotaoDegrade,
                  onPressed: _processando ? null : _concluir,
                  child: const Text('Concluir a exclusão'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _processando ? null : _sair,
                  child: const Text('Sair'),
                ),
                if (_processando) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (erro != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    erro,
                    key: const Key('exclusao_pendente_erro'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

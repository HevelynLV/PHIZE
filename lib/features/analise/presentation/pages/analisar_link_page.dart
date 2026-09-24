import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../domain/analisador_link.dart';

/// Tela "Analisar Link" (UC03, passos 1 e 2): o usuário cola a URL e
/// aciona a verificação. O endereço fica apenas em memória, no campo de
/// texto, e é limpo assim que a análise termina — nunca é persistido
/// (UC03, pós-condições).
class AnalisarLinkPage extends StatefulWidget {
  const AnalisarLinkPage({super.key, required this.analisadorLink});

  final AnalisadorLink analisadorLink;

  @override
  State<AnalisarLinkPage> createState() => _AnalisarLinkPageState();
}

class _AnalisarLinkPageState extends State<AnalisarLinkPage> {
  final _urlController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    // Feedback de carregamento imediato após a submissão (RNF03).
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await widget.analisadorLink.analisar(_urlController.text);
    if (!mounted) return;

    if (resultado == null) {
      setState(() {
        _carregando = false;
        _erro =
            'Isso não parece ser um link. Confira o endereço e envie '
            'novamente (exemplo: site.com.br).';
      });
      return;
    }

    _urlController.clear();
    setState(() => _carregando = false);
    await Navigator.of(context).pushNamed(
      AppRoutes.resultado,
      arguments: resultado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisar link')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cole abaixo o link que você recebeu.'),
              const SizedBox(height: 16),
              TextField(
                key: const Key('analisar_link_url'),
                controller: _urlController,
                enabled: !_carregando,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Link',
                  hintText: 'https://...',
                  border: const OutlineInputBorder(),
                  errorText: _erro,
                  errorMaxLines: 3,
                ),
                onSubmitted: (_) => _carregando ? null : _verificar(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('analisar_link_botao'),
                onPressed: _carregando ? null : _verificar,
                child: const Text('Verificar link'),
              ),
              if (_carregando) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Text(
                  'Analisando o link…',
                  key: Key('analisar_link_carregando'),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

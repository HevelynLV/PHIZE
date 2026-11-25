import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/consentimento_repository.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Pede o consentimento, quando ainda não foi dado, e devolve se a análise de
/// print pode seguir. Só o print envia texto da conversa ao provedor de LLM,
/// por isso a análise de link não passa por aqui.
Future<bool> confirmarConsentimento(
  BuildContext context,
  ConsentimentoRepository repositorio,
) async {
  final navegador = Navigator.of(context);
  bool aceito;
  try {
    aceito = await repositorio.aceito();
  } catch (_) {
    aceito = false;
  }
  if (aceito) return true;

  final resposta = await navegador.push<bool>(
    MaterialPageRoute(
      builder: (_) => ConsentimentoPage(repositorio: repositorio),
    ),
  );
  return resposta ?? false;
}

/// Aviso do que acontece com o print e limites do mascaramento local (T33;
/// RNF07, limitação declarada). Também abre pela aba Perfil, para o usuário
/// rever ou retirar o consentimento.
class ConsentimentoPage extends StatelessWidget {
  const ConsentimentoPage({super.key, required this.repositorio});

  final ConsentimentoRepository repositorio;

  Future<void> _responder(BuildContext context, bool aceitou) async {
    final navegador = Navigator.of(context);
    try {
      await (aceitou ? repositorio.aceitar() : repositorio.revogar());
    } catch (_) {
      // A resposta vale para esta análise; o aviso aparece de novo na próxima.
    }
    navegador.pop(aceitou);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Privacidade')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Antes de analisar um print', style: tema.headlineSmall),
              const SizedBox(height: 20),
              const _Item(
                icone: Icons.smartphone,
                titulo: 'A imagem fica no seu celular',
                texto:
                    'O texto é lido aqui mesmo, e a imagem é descartada logo '
                    'em seguida.',
              ),
              const _Item(
                icone: Icons.send_outlined,
                titulo: 'O texto vai para análise',
                texto:
                    'Enviamos o texto do print ao Gemini, a inteligência '
                    'artificial do Google, para identificar sinais de golpe.',
              ),
              // RNF07, limitação declarada de escopo acadêmico: o nível
              // gratuito do Gemini não veda o uso do texto para treinamento.
              const _Item(
                key: Key('consentimento_aviso_teste'),
                icone: Icons.science_outlined,
                titulo: 'Use só conversas de teste',
                texto:
                    'O Phize é um projeto acadêmico e usa a versão gratuita do '
                    'Gemini. Nela, o Google pode usar o texto enviado para '
                    'melhorar os serviços dele, inclusive com leitura por '
                    'pessoas. Por isso, não analise conversas reais: use '
                    'apenas mensagens de teste.',
              ),
              const _Item(
                icone: Icons.visibility_off_outlined,
                titulo: 'Escondemos parte dos dados, não todos',
                texto:
                    'Antes do envio, escondemos CPF, CNPJ, telefone, e-mail, '
                    'cartão, chave Pix e boleto. Nomes de pessoas e o restante '
                    'da mensagem não são escondidos, e alguns formatos podem '
                    'passar.',
              ),
              const _Item(
                icone: Icons.history,
                titulo: 'A conversa não é guardada',
                texto:
                    'Seu histórico guarda só o resultado da análise. Você pode '
                    'mudar esta escolha na aba Perfil.',
              ),
            ],
          ),
        ),
      ),
      // Botões fixos no rodapé, com o texto rolando acima: no ensaio de
      // 2026-11-16, "Entendi e concordo" ficava abaixo da dobra e a pessoa
      // não o encontrava.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('consentimento_aceitar'),
                style: estiloBotaoDegrade,
                onPressed: () => _responder(context, true),
                child: const Text('Entendi e concordo'),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: const Key('consentimento_recusar'),
                onPressed: () => _responder(context, false),
                child: const Text('Agora não'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: context.cores.azul),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(texto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

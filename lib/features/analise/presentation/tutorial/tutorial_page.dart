import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/tutorial_repository.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Uma etapa do tutorial (RF13): uma cena simulada do app, desenhada num
/// celular, e um cartão com a explicação.
class EtapaTutorial {
  const EtapaTutorial({
    required this.titulo,
    required this.cena,
    required this.explicacao,
  });

  final String titulo;

  /// Cena do celular. [ativa] é verdadeiro quando a etapa está na tela, para
  /// a cena começar a animação só quando for vista.
  final Widget Function(BuildContext context, bool ativa) cena;

  final Widget explicacao;
}

/// Dá às cenas acesso à navegação do tutorial, para que uma ação simulada
/// (como tocar em "Verificar link") leve à etapa seguinte.
class ControleTutorial extends InheritedWidget {
  const ControleTutorial({
    super.key,
    required this.atual,
    required this.avancar,
    required super.child,
  });

  final int atual;
  final VoidCallback avancar;

  static ControleTutorial of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ControleTutorial>()!;

  @override
  bool updateShouldNotify(ControleTutorial antigo) => antigo.atual != atual;
}

/// Tutorial em etapas (RF13): no máximo 4, com barra de progresso, Voltar,
/// Próximo e Pular. Com a redução de movimento do sistema ligada, nada é
/// animado.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.titulo, required this.etapas})
    : assert(etapas.length > 0 && etapas.length <= 4);

  final String titulo;
  final List<EtapaTutorial> etapas;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final _paginas = PageController();
  int _atual = 0;

  bool get _ultima => _atual == widget.etapas.length - 1;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _irPara(int etapa) {
    if (etapa < 0 || etapa >= widget.etapas.length) return;
    if (MediaQuery.of(context).disableAnimations) {
      _paginas.jumpToPage(etapa);
    } else {
      _paginas.animateToPage(
        etapa,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _fechar() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final total = widget.etapas.length;
    final semAnimacao = MediaQuery.of(context).disableAnimations;

    return ControleTutorial(
      atual: _atual,
      avancar: () => _irPara(_atual + 1),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.cores.azulClaro, context.cores.fundo],
              stops: [0, 0.65],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label:
                              '${widget.titulo}. Etapa ${_atual + 1} de '
                              '$total',
                          excludeSemantics: true,
                          child: Row(
                            key: const Key('tutorial_progresso'),
                            children: [
                              for (var i = 0; i < total; i++)
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: semAnimacao
                                        ? Duration.zero
                                        : const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i <= _atual
                                          ? context.cores.azul
                                          : context.cores.borda,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('tutorial_pular'),
                        onPressed: _fechar,
                        child: const Text('Pular'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _paginas,
                    onPageChanged: (etapa) => setState(() => _atual = etapa),
                    children: [
                      for (final (i, etapa) in widget.etapas.indexed)
                        _PaginaEtapa(etapa: etapa, ativa: i == _atual),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      if (_atual > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('tutorial_voltar'),
                            onPressed: () => _irPara(_atual - 1),
                            child: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          key: const Key('tutorial_proximo'),
                          style: estiloBotaoDegrade,
                          onPressed: _ultima
                              ? _fechar
                              : () => _irPara(_atual + 1),
                          child: Text(_ultima ? 'Começar' : 'Próximo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginaEtapa extends StatelessWidget {
  const _PaginaEtapa({required this.etapa, required this.ativa});

  final EtapaTutorial etapa;
  final bool ativa;

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.sizeOf(context).height;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: (altura * 0.5).clamp(260.0, 460.0),
            child: MolduraCelular(child: etapa.cena(context, ativa)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cores.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.cores.borda),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    etapa.titulo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 10),
                etapa.explicacao,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celular desenhado, com a tela do app simulada dentro. O conteúdo é
/// desenhado em tamanho fixo e reduzido para caber: é uma imagem do app,
/// e a explicação, no cartão abaixo, acompanha o tamanho de letra da pessoa.
class MolduraCelular extends StatelessWidget {
  const MolduraCelular({super.key, required this.child});

  static const Size tela = Size(210, 400);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        width: tela.width + 16,
        height: tela.height + 16,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CoresPhize.tinta,
          borderRadius: BorderRadius.circular(40),
          // No tema escuro, a borda separa o aparelho do fundo da tela.
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: context.cores.borda, width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x332B46B8),
              blurRadius: 28,
              spreadRadius: -6,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 12, height: 1.35),
              // A tela simulada é uma imagem do app no tema claro, em
              // qualquer tema escolhido.
              child: Theme(
                data: AppTheme.light,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: CoresPhize.tinta),
                  child: ColoredBox(color: Colors.white, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta que indica onde tocar na cena. Pulsa algumas vezes e para; com
/// a redução de movimento ligada, fica parada.
class DicaToque extends StatefulWidget {
  const DicaToque({super.key, required this.texto});

  final String texto;

  @override
  State<DicaToque> createState() => _DicaToqueState();
}

class _DicaToqueState extends State<DicaToque>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulso.value = 0;
    } else if (!_pulso.isAnimating && _pulso.value == 0) {
      _pulso.repeat(reverse: true, count: 6);
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _pulso, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CoresPhize.azul,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x403B5BDB), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre o tutorial e, ao fechá-lo por qualquer caminho (concluir, pular ou
/// voltar), grava a marca de visto. Falha ao gravar não impede a análise.
Future<void> abrirTutorial(
  BuildContext context, {
  required TipoTutorial tipo,
  required TutorialRepository repositorio,
  required WidgetBuilder construir,
}) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: construir));
  try {
    await repositorio.marcarVisto(tipo);
  } catch (_) {
    // Sem a marca, o tutorial só aparece de novo na próxima abertura.
  }
}

/// Abre o tutorial só se ele ainda não foi visto nesta versão. Se a marca
/// não puder ser lida, não abre: o tutorial nunca bloqueia a análise.
Future<void> abrirTutorialNaPrimeiraVez(
  BuildContext context, {
  required TipoTutorial tipo,
  required TutorialRepository repositorio,
  required WidgetBuilder construir,
}) async {
  final bool visto;
  try {
    visto = await repositorio.visto(tipo);
  } catch (_) {
    return;
  }
  if (visto || !context.mounted) return;
  await abrirTutorial(
    context,
    tipo: tipo,
    repositorio: repositorio,
    construir: construir,
  );
}

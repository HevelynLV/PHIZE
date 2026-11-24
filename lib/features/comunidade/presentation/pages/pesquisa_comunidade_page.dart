import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/feed_repository_firestore.dart';
import '../../domain/feed_repository.dart';
import '../../domain/pesquisa_reportes.dart';
import '../../domain/reporte_comunidade.dart';
import '../widgets/cartao_reporte.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Pesquisa da comunidade (RF15, UC08): por palavras ou colando um link. O
/// link vira hash no aparelho, como no reporte (RF05), e nunca é enviado nem
/// gravado. Reportes ocultos pela moderação não aparecem.
class PesquisaComunidadePage extends StatefulWidget {
  const PesquisaComunidadePage({super.key, this.repositorio});

  final FeedRepository? repositorio;

  static const String ajuda =
      'Pesquise por palavras (exemplo: "boleto", "falso parente") ou cole um '
      'link suspeito. O link é conferido sem sair do seu celular.';

  @override
  State<PesquisaComunidadePage> createState() => _PesquisaComunidadePageState();
}

sealed class _Estado {
  const _Estado();
}

class _Inicio extends _Estado {
  const _Inicio();
}

class _Carregando extends _Estado {
  const _Carregando();
}

class _Falha extends _Estado {
  const _Falha();
}

class _ResultadoLink extends _Estado {
  const _ResultadoLink(this.resultado);

  final ResultadoPesquisaLink resultado;
}

class _ResultadoPalavras extends _Estado {
  const _ResultadoPalavras(this.reportes);

  final List<ReporteComunidade> reportes;
}

class _PesquisaComunidadePageState extends State<PesquisaComunidadePage> {
  late final FeedRepository _repositorio =
      widget.repositorio ?? FeedRepositoryFirestore();
  final _campo = TextEditingController();
  _Estado _estado = const _Inicio();
  String? _aviso;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _pesquisar() async {
    FocusScope.of(context).unfocus();
    final consulta = interpretarPesquisa(_campo.text);
    if (consulta == null) {
      setState(() {
        _aviso = 'Digite uma palavra com pelo menos 3 letras, ou um link.';
        _estado = const _Inicio();
      });
      return;
    }
    setState(() {
      _aviso = null;
      _estado = const _Carregando();
    });
    _Estado novo;
    try {
      novo = switch (consulta) {
        ConsultaPorLink(:final hash) => _ResultadoLink(
          await _repositorio.pesquisarLink(hash),
        ),
        ConsultaPorPalavras(:final palavras) => _ResultadoPalavras(
          await _repositorio.pesquisarPalavras(palavras),
        ),
      };
    } catch (_) {
      novo = const _Falha();
    }
    if (mounted) setState(() => _estado = novo);
  }

  void _abrir(ReporteComunidade reporte) =>
      Navigator.of(context)
          .pushNamed(AppRoutes.detalheReporte, arguments: reporte);

  void _reportar() => Navigator.of(context).pushNamed(AppRoutes.reportarGolpe);

  @override
  Widget build(BuildContext context) {
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );
    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Pesquisar na comunidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            key: const Key('pesquisa_campo'),
            controller: _campo,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _pesquisar(),
            decoration: InputDecoration(
              labelText: 'Palavras ou link',
              errorText: _aviso,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                key: const Key('pesquisa_buscar'),
                tooltip: 'Pesquisar',
                onPressed: _pesquisar,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(PesquisaComunidadePage.ajuda, style: secundario),
          const SizedBox(height: 16),
          ..._resultado(context),
        ],
      ),
    );
  }

  List<Widget> _resultado(BuildContext context) {
    switch (_estado) {
      case _Inicio():
        return const [];
      case _Carregando():
        return const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case _Falha():
        return [
          const Text(
            'Não foi possível pesquisar. Verifique sua conexão e tente de '
            'novo.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _pesquisar,
              child: const Text('Tentar de novo'),
            ),
          ),
        ];
      case _ResultadoLink(:final resultado):
        return [
          if (resultado.validadoPelaEquipe)
            _Destaque(
              key: const Key('pesquisa_validado'),
              texto:
                  'A equipe do Phize confirmou este link como golpe. Não '
                  'abra e não passe dados.',
            ),
          if (resultado.reporte case final reporte?) ...[
            const SizedBox(height: 8),
            CartaoReporte(reporte: reporte, aoTocar: () => _abrir(reporte)),
          ],
          if (resultado.reporte == null && !resultado.validadoPelaEquipe)
            _SemResultado(
              texto: 'Ninguém reportou este link na comunidade ainda.',
              aoReportar: _reportar,
            ),
        ];
      case _ResultadoPalavras(:final reportes):
        if (reportes.isEmpty) {
          return [
            _SemResultado(
              texto: 'Nenhum reporte com essas palavras.',
              aoReportar: _reportar,
            ),
          ];
        }
        return [
          for (final reporte in reportes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CartaoReporte(
                reporte: reporte,
                aoTocar: () => _abrir(reporte),
              ),
            ),
        ];
    }
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cores.erroClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: context.cores.erro),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(color: context.cores.tinta)),
          ),
        ],
      ),
    );
  }
}

/// Sem resultado: informa a ausência e sugere reportar (RF15).
class _SemResultado extends StatelessWidget {
  const _SemResultado({required this.texto, required this.aoReportar});

  final String texto;
  final VoidCallback aoReportar;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pesquisa_sem_resultado'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(texto),
        const SizedBox(height: 4),
        Text(
          'Isso não quer dizer que não seja golpe. Se recebeu algo suspeito, '
          'avise outras pessoas.',
          style: TextStyle(fontSize: 14, color: context.cores.textoSecundario),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('pesquisa_reportar'),
          onPressed: aoReportar,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Reportar golpe'),
        ),
      ],
    );
  }
}

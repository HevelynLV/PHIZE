import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../data/meus_reportes_repository_firestore.dart';
import '../../domain/meus_reportes_repository.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/reporte_comunidade.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// "Meus reportes" (RF16, UC09, UC10): os reportes que a conta publicou, com
/// editar e excluir. Só esta tela mostra que um reporte é da pessoa; o feed
/// continua sem autor.
class MeusReportesPage extends StatefulWidget {
  const MeusReportesPage({super.key, this.repositorio});

  final MeusReportesRepository? repositorio;

  @override
  State<MeusReportesPage> createState() => _MeusReportesPageState();
}

class _MeusReportesPageState extends State<MeusReportesPage> {
  late final MeusReportesRepository _repositorio =
      widget.repositorio ?? MeusReportesRepositoryFirestore();
  late Future<List<MeuReporte>> _reportes = _repositorio.listar();

  void _recarregar() {
    setState(() {
      _reportes = _repositorio.listar();
    });
  }

  Future<void> _editar(ReporteComunidade reporte) async {
    final salvou = await Navigator.of(context)
        .pushNamed<bool>(AppRoutes.editarReporte, arguments: reporte);
    if (!mounted || salvou != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
    _recarregar();
  }

  Future<void> _excluir(MeuReporte meu) async {
    final reporte = meu.reporte;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir reporte?'),
        content: Text(
          reporte == null
              ? 'Este reporte já foi removido pela moderação. Ele sai da sua '
                    'lista.'
              : 'O reporte sai da comunidade e da sua lista. Não dá para '
                    'desfazer.'
                    '${reporte.tipo == TipoReporte.link ? ' Se a equipe já '
                              'confirmou o link como golpe, essa confirmação '
                              'continua, sem o seu nome.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('meus_confirmar_exclusao'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      if (reporte == null) {
        await _repositorio.esquecer(meu.id);
      } else {
        await _repositorio.excluir(meu.id);
      }
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Reporte excluído.')),
      );
    } catch (_) {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. Tente de novo.'),
        ),
      );
    }
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Meus reportes')),
      body: FutureBuilder<List<MeuReporte>>(
        future: _reportes,
        builder: (context, carga) {
          if (carga.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final reportes = carga.data;
          if (carga.hasError || reportes == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível carregar seus reportes. Verifique sua '
                      'conexão.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _recarregar,
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (reportes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Você ainda não publicou reportes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: reportes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _CartaoMeuReporte(
              meu: reportes[i],
              aoEditar: _editar,
              aoExcluir: () => _excluir(reportes[i]),
            ),
          );
        },
      ),
    );
  }
}

class _CartaoMeuReporte extends StatelessWidget {
  const _CartaoMeuReporte({
    required this.meu,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final MeuReporte meu;
  final ValueChanged<ReporteComunidade> aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );
    final reporte = meu.reporte;
    final situacao = switch (reporte?.status) {
      null => 'Removido pela moderação',
      StatusReporte.pendente => 'Aguardando revisão da equipe',
      StatusReporte.aprovado => 'Aprovado pela equipe',
      StatusReporte.oculto => 'Fora do feed, em revisão pela equipe',
    };

    return Card(
      key: Key('meus_${meu.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reporte?.titulo ?? 'Reporte removido',
              style: tema.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              [
                ?reporte?.categoria.nome,
                formatarData(meu.publicadoEm),
              ].join(' · '),
              style: secundario,
            ),
            const SizedBox(height: 4),
            Text(situacao, style: secundario),
            if (reporte != null) ...[
              const SizedBox(height: 4),
              Text(
                reporte.curtidas == 1
                    ? '1 curtida'
                    : '${reporte.curtidas} curtidas',
                style: secundario,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (reporte != null)
                  TextButton.icon(
                    key: Key('meus_editar_${meu.id}'),
                    onPressed: () => aoEditar(reporte),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                TextButton.icon(
                  key: Key('meus_excluir_${meu.id}'),
                  onPressed: aoExcluir,
                  style: TextButton.styleFrom(
                    foregroundColor: context.cores.erro,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(reporte == null ? 'Remover da lista' : 'Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

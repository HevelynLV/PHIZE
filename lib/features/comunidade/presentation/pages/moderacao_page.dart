import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../data/moderacao_repository_firestore.dart';
import '../../domain/moderacao_repository.dart';
import '../../domain/motivo_denuncia.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/reporte_comunidade.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Moderação mínima da comunidade (RF11): aprovar, ocultar ou excluir de vez
/// um reporte. Só aparece para contas da lista `moderadores`; quem garante o
/// acesso são as regras do Firestore, não esta tela.
class ModeracaoPage extends StatefulWidget {
  const ModeracaoPage({super.key, this.repositorio});

  final ModeracaoRepository? repositorio;

  @override
  State<ModeracaoPage> createState() => _ModeracaoPageState();
}

class _ModeracaoPageState extends State<ModeracaoPage> {
  late final ModeracaoRepository _repositorio =
      widget.repositorio ?? ModeracaoRepositoryFirestore();

  /// Começa pelos ocultos: são os que esperam revisão depois de denúncias.
  StatusReporte _lista = StatusReporte.oculto;
  late Future<(List<ReporteComunidade>, Map<String, SituacaoNaBase>)>
  _reportes = _carregar();

  Future<(List<ReporteComunidade>, Map<String, SituacaoNaBase>)>
  _carregar() async {
    final (reportes, situacoes) = await (
      _repositorio.listar(_lista),
      _repositorio.situacoesNaBase(),
    ).wait;
    return (reportes, situacoes);
  }

  void _recarregar() {
    setState(() {
      _reportes = _carregar();
    });
  }

  Future<void> _incluirNaBase(ReporteComunidade reporte) => _executar(
    () => _repositorio.incluirNaBase(reporte),
    'Reporte aprovado. A inclusão na base começou.',
  );

  Future<void> _pedirDeNovo(ReporteComunidade reporte) => _executar(
    () => _repositorio.pedirInclusaoDeNovo(reporte.id),
    'Pedido de inclusão enviado de novo.',
  );

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await acao();
      mensageiro.showSnackBar(SnackBar(content: Text(sucesso)));
    } catch (_) {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível concluir. Tente de novo.'),
        ),
      );
    }
    if (mounted) _recarregar();
  }

  Future<void> _mudarStatus(ReporteComunidade reporte, StatusReporte novo) =>
      _executar(() => _repositorio.mudarStatus(reporte, novo), switch (novo) {
        StatusReporte.aprovado => 'Reporte aprovado.',
        StatusReporte.oculto => 'Reporte ocultado do feed.',
        StatusReporte.pendente => 'Reporte devolvido a pendente.',
      });

  Future<void> _excluir(ReporteComunidade reporte) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir de vez?'),
        content: Text(
          '"${reporte.titulo}" será removido da comunidade. '
          'Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('moderacao_confirmar_exclusao'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    await _executar(
      () => _repositorio.excluir(reporte.id),
      'Reporte excluído.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Moderação')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<StatusReporte>(
              key: const Key('moderacao_lista'),
              segments: [
                for (final status in [
                  StatusReporte.oculto,
                  StatusReporte.pendente,
                  StatusReporte.aprovado,
                ])
                  ButtonSegment(value: status, label: Text(status.nomeLista)),
              ],
              selected: {_lista},
              showSelectedIcon: false,
              onSelectionChanged: (escolha) {
                _lista = escolha.single;
                _recarregar();
              },
            ),
          ),
          Expanded(
            child:
                FutureBuilder<
                  (List<ReporteComunidade>, Map<String, SituacaoNaBase>)
                >(
                  future: _reportes,
                  builder: (context, carga) {
                    if (carga.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final dados = carga.data;
                    if (carga.hasError || dados == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Não foi possível carregar os reportes.',
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
                    final (reportes, situacoes) = dados;
                    if (reportes.isEmpty) {
                      return const Center(
                        child: Text('Nenhum reporte nesta lista.'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: reportes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _CartaoModeracao(
                        key: Key('moderacao_${reportes[i].id}'),
                        reporte: reportes[i],
                        repositorio: _repositorio,
                        aoMudarStatus: (novo) =>
                            _mudarStatus(reportes[i], novo),
                        aoExcluir: () => _excluir(reportes[i]),
                        situacaoNaBase: situacoes[reportes[i].id],
                        aoIncluirNaBase: () => _incluirNaBase(reportes[i]),
                        aoPedirDeNovo: () => _pedirDeNovo(reportes[i]),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _CartaoModeracao extends StatefulWidget {
  const _CartaoModeracao({
    super.key,
    required this.reporte,
    required this.repositorio,
    required this.aoMudarStatus,
    required this.aoExcluir,
    required this.situacaoNaBase,
    required this.aoIncluirNaBase,
    required this.aoPedirDeNovo,
  });

  final ReporteComunidade reporte;
  final ModeracaoRepository repositorio;
  final ValueChanged<StatusReporte> aoMudarStatus;
  final VoidCallback aoExcluir;

  /// `null` se nunca houve pedido de inclusão na base.
  final SituacaoNaBase? situacaoNaBase;
  final VoidCallback aoIncluirNaBase;
  final VoidCallback aoPedirDeNovo;

  @override
  State<_CartaoModeracao> createState() => _CartaoModeracaoState();
}

class _CartaoModeracaoState extends State<_CartaoModeracao> {
  Future<Map<MotivoDenuncia, int>>? _motivos;

  @override
  void initState() {
    super.initState();
    if (widget.reporte.denuncias > 0) {
      _motivos = widget.repositorio.motivosDasDenuncias(widget.reporte.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reporte.titulo, style: tema.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${reporte.categoria.nome} · ${reporte.tipo.nome} · '
              '${formatarData(reporte.criadoEm)}',
              style: secundario,
            ),
            if (reporte.relato.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reporte.relato, style: tema.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              '${reporte.denuncias} denúncia(s) · ${reporte.curtidas} '
              'curtida(s) · ${reporte.incidencias} relato(s)',
              style: secundario,
            ),
            if (_motivos case final motivos?)
              FutureBuilder<Map<MotivoDenuncia, int>>(
                future: motivos,
                builder: (context, carga) {
                  final contagem = carga.data;
                  if (contagem == null || contagem.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        for (final MapEntry(key: motivo, value: n)
                            in contagem.entries)
                          '${motivo.nome}: $n',
                      ].join('\n'),
                      style: secundario,
                    ),
                  );
                },
              ),
            if (widget.situacaoNaBase case final situacao?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  situacao.descricao,
                  key: Key('moderacao_base_${reporte.id}'),
                  style: secundario,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                // Curadoria (RNF05): só relato e print, que o índice compara
                // como texto, e só se ainda não há pedido em andamento.
                if (reporte.tipo != TipoReporte.link &&
                    widget.situacaoNaBase == null)
                  TextButton(
                    key: Key('moderacao_incluir_base_${reporte.id}'),
                    onPressed: widget.aoIncluirNaBase,
                    child: const Text('Aprovar e incluir na base'),
                  ),
                if (widget.situacaoNaBase?.estado
                    case EstadoNaBase.recusado || EstadoNaBase.falhou)
                  TextButton(
                    key: Key('moderacao_incluir_de_novo_${reporte.id}'),
                    onPressed: widget.aoPedirDeNovo,
                    child: const Text('Tentar incluir de novo'),
                  ),
                if (reporte.status != StatusReporte.aprovado)
                  TextButton(
                    key: Key('moderacao_aprovar_${reporte.id}'),
                    onPressed: () =>
                        widget.aoMudarStatus(StatusReporte.aprovado),
                    child: const Text('Aprovar'),
                  ),
                if (reporte.status != StatusReporte.oculto)
                  TextButton(
                    key: Key('moderacao_ocultar_${reporte.id}'),
                    onPressed: () => widget.aoMudarStatus(StatusReporte.oculto),
                    child: const Text('Ocultar'),
                  ),
                TextButton(
                  key: Key('moderacao_excluir_${reporte.id}'),
                  onPressed: widget.aoExcluir,
                  style: TextButton.styleFrom(
                    foregroundColor: context.cores.erro,
                  ),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

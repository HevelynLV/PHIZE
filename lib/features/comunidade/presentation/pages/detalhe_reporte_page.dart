import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../data/compartilhador_texto_nativo.dart';
import '../../data/feed_repository_firestore.dart';
import '../../domain/compartilhador_texto.dart';
import '../../domain/feed_repository.dart';
import '../../domain/mensagem_alerta.dart';
import '../../domain/motivo_denuncia.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/reporte_comunidade.dart';
import '../../../../shared/widgets/scaffold_phize.dart';

/// Detalhe de um reporte da comunidade (RF08), com curtir (RF06) e
/// compartilhar (RF09) e denunciar (RF11). Sem autor: aparece como
/// "Usuário do Phize".
class DetalheReportePage extends StatefulWidget {
  const DetalheReportePage({
    super.key,
    required this.reporte,
    this.repositorio,
    this.compartilhador,
  });

  final ReporteComunidade reporte;
  final FeedRepository? repositorio;
  final CompartilhadorTexto? compartilhador;

  static const String avisoComunidade =
      'Conteúdo enviado pela comunidade. Na dúvida, confirme direto com a '
      'instituição envolvida, pelos canais oficiais.';

  @override
  State<DetalheReportePage> createState() => _DetalheReportePageState();
}

class _DetalheReportePageState extends State<DetalheReportePage> {
  late final FeedRepository _repositorio =
      widget.repositorio ?? FeedRepositoryFirestore();
  late final CompartilhadorTexto _compartilhador =
      widget.compartilhador ?? CompartilhadorTextoNativo();

  late ReporteComunidade _reporte = widget.reporte;

  /// `null` enquanto confere se a conta já curtiu.
  bool? _curtiu;
  bool _curtindo = false;

  /// `null` enquanto confere se a conta já denunciou.
  bool? _denunciou;
  bool _denunciando = false;

  @override
  void initState() {
    super.initState();
    _conferirCurtida();
    _conferirDenuncia();
  }

  Future<void> _conferirCurtida() async {
    bool curtiu;
    try {
      curtiu = await _repositorio.jaCurtiu(_reporte.id);
    } catch (_) {
      // Sem conferência, o botão fica disponível; as regras impedem o voto
      // duplicado de qualquer jeito.
      curtiu = false;
    }
    if (mounted) setState(() => _curtiu = curtiu);
  }

  Future<void> _conferirDenuncia() async {
    bool denunciou;
    try {
      denunciou = await _repositorio.jaDenunciou(_reporte.id);
    } catch (_) {
      // As regras impedem a denúncia duplicada de qualquer jeito.
      denunciou = false;
    }
    if (mounted) setState(() => _denunciou = denunciou);
  }

  Future<void> _denunciar() async {
    final motivo = await showDialog<MotivoDenuncia>(
      context: context,
      builder: (contexto) => SimpleDialog(
        key: const Key('detalhe_motivos'),
        title: const Text('Por que denunciar?'),
        children: [
          for (final motivo in MotivoDenuncia.values)
            SimpleDialogOption(
              key: Key('motivo_${motivo.codigo}'),
              onPressed: () => Navigator.of(contexto).pop(motivo),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(motivo.nome),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () => Navigator.of(contexto).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
    if (motivo == null || !mounted) return;

    setState(() => _denunciando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await _repositorio.denunciar(_reporte.id, motivo);
      if (!mounted) return;
      setState(() => _denunciou = true);
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Denúncia enviada. A equipe vai revisar o reporte.'),
        ),
      );
    } catch (_) {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar a denúncia. Tente de novo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _denunciando = false);
    }
  }

  Future<void> _curtir() async {
    setState(() => _curtindo = true);
    try {
      await _repositorio.curtir(_reporte.id);
      if (!mounted) return;
      setState(() {
        _reporte = _reporte.comMaisUmaCurtida();
        _curtiu = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar a curtida. Tente de novo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _curtindo = false);
    }
  }

  Future<void> _compartilhar() async {
    try {
      await _compartilhador.compartilhar(mensagemDoAlerta(_reporte));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o compartilhamento.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );
    final reporte = _reporte;
    final pessoas = reporte.incidencias == 1
        ? '1 pessoa relatou este golpe.'
        : '${reporte.incidencias} pessoas relataram este golpe.';
    final curtidas = reporte.curtidas == 1
        ? '1 curtida'
        : '${reporte.curtidas} curtidas';
    final curtiu = _curtiu == true;

    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Alerta da comunidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(reporte.categoria.nome, style: secundario),
          const SizedBox(height: 4),
          Text(reporte.titulo, style: tema.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${ReporteComunidade.autorAnonimo} · '
            '${formatarData(reporte.criadoEm)}',
            style: secundario,
          ),
          if (reporte.status == StatusReporte.pendente)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Ainda não revisado pela equipe.', style: secundario),
            ),
          if (reporte.relato.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(reporte.relato, style: tema.bodyLarge),
          ],
          if (reporte.tipo == TipoReporte.link) ...[
            const SizedBox(height: 16),
            Text(
              'Reporte de link suspeito. O Phize não guarda nem mostra o '
              'endereço.',
              style: tema.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Text(pessoas, style: tema.bodyMedium),
          const SizedBox(height: 4),
          Text(curtidas, key: const Key('detalhe_curtidas'), style: secundario),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('detalhe_curtir'),
                  onPressed: _curtiu == null || curtiu || _curtindo
                      ? null
                      : _curtir,
                  icon: Icon(curtiu ? Icons.thumb_up : Icons.thumb_up_outlined),
                  label: Text(curtiu ? 'Você curtiu' : 'Curtir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('detalhe_compartilhar'),
                  onPressed: _compartilhar,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartilhar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cores.fundoSuave,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: context.cores.textoSecundario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DetalheReportePage.avisoComunidade,
                    style: tema.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Denúncia (RF11): acessível em qualquer alerta, uma por conta.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('detalhe_denunciar'),
              onPressed: _denunciou == null || _denunciou! || _denunciando
                  ? null
                  : _denunciar,
              icon: const Icon(Icons.flag_outlined),
              label: Text(
                _denunciou == true
                    ? 'Você denunciou este reporte'
                    : 'Denunciar este reporte',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

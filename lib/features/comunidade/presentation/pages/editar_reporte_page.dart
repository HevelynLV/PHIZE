import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/meus_reportes_repository_firestore.dart';
import '../../domain/meus_reportes_repository.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/preparacao_reporte.dart';
import '../../domain/reporte_comunidade.dart';
import '../../../../shared/widgets/scaffold_phize.dart';
import 'reportar_golpe_page.dart';

/// Edição de um reporte pelo autor (RF16, UC09): só título e relato, que
/// passam de novo pelo mascaramento no aparelho. Tipo, categoria e link não
/// mudam (o link só existe como hash). Volta `true` se salvou.
class EditarReportePage extends StatefulWidget {
  const EditarReportePage({super.key, required this.reporte, this.repositorio});

  final ReporteComunidade reporte;
  final MeusReportesRepository? repositorio;

  @override
  State<EditarReportePage> createState() => _EditarReportePageState();
}

class _EditarReportePageState extends State<EditarReportePage> {
  late final MeusReportesRepository _repositorio =
      widget.repositorio ?? MeusReportesRepositoryFirestore();
  late final _titulo = TextEditingController(text: widget.reporte.titulo);
  late final _relato = TextEditingController(text: widget.reporte.relato);
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _relato.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final reporte = widget.reporte;
    final preparo = prepararEdicao(
      tipo: reporte.tipo,
      titulo: _titulo.text,
      relato: _relato.text,
      categoria: reporte.categoria,
    );
    if (preparo is MotivoRecusaReporte) {
      setState(() => _erro = preparo.mensagem);
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repositorio.editar(reporte.id, preparo as EdicaoPronta);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro =
            'Não foi possível salvar. Verifique sua conexão e tente de novo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );
    return ScaffoldPhize(
      appBar: AppBar(title: const Text('Editar reporte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            '${reporte.tipo.nome} · ${reporte.categoria.nome}',
            style: secundario,
          ),
          if (reporte.tipo == TipoReporte.link) ...[
            const SizedBox(height: 4),
            Text(
              'O link não pode ser alterado. Para outro link, faça um reporte '
              'novo.',
              style: secundario,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const Key('editar_titulo'),
            controller: _titulo,
            maxLength: tamanhoMaximoTitulo,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('editar_relato'),
            controller: _relato,
            maxLength: tamanhoMaximoRelato,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: reporte.tipo == TipoReporte.link
                  ? 'O que aconteceu (opcional)'
                  : 'O que aconteceu',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(ReportarGolpePage.avisoPublico, style: secundario),
          if (_erro case final erro?) ...[
            const SizedBox(height: 12),
            Text(
              erro,
              key: const Key('editar_erro'),
              style: TextStyle(color: context.cores.erro),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('editar_salvar'),
            style: estiloBotaoDegrade,
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar alterações'),
          ),
        ],
      ),
    );
  }
}

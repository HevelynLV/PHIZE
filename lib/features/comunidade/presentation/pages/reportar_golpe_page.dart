import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/domain/captura_imagem.dart';
import '../../../../shared/domain/categoria_ameaca.dart';
import '../../../../shared/domain/reconhecedor_texto.dart';
import '../../data/reporte_repository_firestore.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/preparacao_reporte.dart';
import '../../domain/reporte_repository.dart';

/// Tela "Reportar golpe" (RF05, UC05). Tudo o que vai para a comunidade é
/// preparado no aparelho: link só como hash, título e relato mascarados e
/// sem links, print só como texto (a imagem é descartada logo depois da
/// leitura, RNF01). O reporte fica só em memória até ser publicado; numa
/// falha de envio, continua na tela para nova tentativa, sem cache (RNF07,
/// etapa 3).
class ReportarGolpePage extends StatefulWidget {
  const ReportarGolpePage({
    super.key,
    required this.captura,
    required this.reconhecedor,
    this.repositorio,
  });

  final CapturaImagem captura;
  final ReconhecedorTexto reconhecedor;
  final ReporteRepository? repositorio;

  static const String avisoPublico =
      'Seu reporte aparece para outras pessoas do Phize, sem seu nome. '
      'Escondemos CPF, telefone, e-mail, cartão e links, mas nomes e o resto '
      'do texto ficam visíveis. Use só conteúdo de teste.';

  @override
  State<ReportarGolpePage> createState() => _ReportarGolpePageState();
}

class _ReportarGolpePageState extends State<ReportarGolpePage> {
  // Paleta combinando o azul-marinho original do app com semáforo de alerta
  // (amarelo, verde e vermelho).
  static const _fundo = Color(0xFF050A24);
  static const _campo = Color(0xFF0E1233);
  static const _bordaCampo = Color(0xFF2B3A7A);
  static const _roxoClaro = Color(0xFF8FA0FF);
  static const _textoSuave = Color(0xFFA3A9D6);
  static const _amarelo = Color(0xFFFFD166);
  static const _verde = Color(0xFF06D6A0);
  static const _vermelho = Color(0xFFFF5A5F);

  late final ReporteRepository _repositorio =
      widget.repositorio ?? ReporteRepositoryFirestore();

  final _link = TextEditingController();
  final _titulo = TextEditingController();
  final _relato = TextEditingController();
  TipoReporte _tipo = TipoReporte.link;
  CategoriaAmeaca _categoria = CategoriaAmeaca.outroGolpe;
  bool _enviando = false;
  bool _lendoPrint = false;
  String? _erro;

  static final _categorias = CategoriaAmeaca.values
      .where((c) => c != CategoriaAmeaca.semIndicios)
      .toList();

  @override
  void dispose() {
    _link.dispose();
    _titulo.dispose();
    _relato.dispose();
    super.dispose();
  }

  Future<void> _colar() async {
    String? texto;
    try {
      texto = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    } catch (_) {
      texto = null;
    }
    if (!mounted) return;
    setState(() {
      if (texto == null || texto.isEmpty) {
        _erro =
            'Nenhum link copiado. Na conversa, toque e segure o link, '
            'escolha "Copiar" e volte aqui.';
      } else {
        _link.text = texto;
        _erro = null;
      }
    });
  }

  /// Lê o texto do print no aparelho e já o deixa mascarado no campo, para a
  /// pessoa revisar antes de publicar. A imagem é descartada por
  /// [CapturaImagem] ao fim da leitura, com sucesso ou falha.
  Future<void> _escolherPrint() async {
    setState(() {
      _lendoPrint = true;
      _erro = null;
    });
    String? textoPublicoDoPrint;
    String? erro;
    try {
      final lido = await widget.captura.processar(
        (imagem) => widget.reconhecedor.reconhecer(imagem),
      );
      if (lido != null) {
        textoPublicoDoPrint = textoPublico(lido);
        if (textoPublicoDoPrint.isEmpty) {
          erro = 'Não encontramos texto nesse print. Tente outro.';
        }
      }
    } catch (_) {
      // Sem expor a exceção: ela pode trazer o nome original do arquivo.
      erro = 'Não foi possível ler o print. Tente de novo.';
    }
    if (!mounted) return;
    setState(() {
      _lendoPrint = false;
      _erro = erro;
      if (erro == null && textoPublicoDoPrint != null) {
        _relato.text = textoPublicoDoPrint.length > tamanhoMaximoRelato
            ? textoPublicoDoPrint.substring(0, tamanhoMaximoRelato)
            : textoPublicoDoPrint;
      }
    });
  }

  Future<void> _publicar() async {
    final PreparacaoReporte preparacao;
    try {
      preparacao = prepararReporte(
        tipo: _tipo,
        titulo: _titulo.text,
        relato: _relato.text,
        categoria: _categoria,
        link: _link.text,
      );
    } catch (_) {
      setState(() => _erro = 'Não foi possível preparar o reporte.');
      return;
    }
    switch (preparacao) {
      case ReporteRecusado(:final motivo):
        setState(() => _erro = motivo.mensagem);
        return;
      case ReportePronto(:final reporte):
        setState(() {
          _enviando = true;
          _erro = null;
        });
        ResultadoPublicacao resultado;
        try {
          resultado = await _repositorio.publicar(reporte);
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _enviando = false;
            _erro =
                'Não foi possível enviar o reporte agora. Confira a conexão '
                'e tente de novo.';
          });
          return;
        }
        if (!mounted) return;
        _link.clear();
        _titulo.clear();
        _relato.clear();
        setState(() => _enviando = false);
        await _mostrarResultado(resultado);
        if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _mostrarResultado(ResultadoPublicacao resultado) {
    final (titulo, texto) = switch (resultado) {
      ResultadoPublicacao.publicado => (
        'Obrigado!',
        'Seu reporte foi publicado na comunidade e aguarda revisão da '
            'equipe.',
      ),
      ResultadoPublicacao.incidenciaRegistrada => (
        'Obrigado!',
        'Esse link já tinha sido reportado. Contamos o seu como mais um caso.',
      ),
      ResultadoPublicacao.jaRegistradoPorVoce => (
        'Você já reportou este link',
        'Cada conta conta uma vez por link.',
      ),
      ResultadoPublicacao.emRevisao => (
        'Link em revisão',
        'Esse link já foi reportado e está em revisão pela equipe.',
      ),
    };
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        key: const Key('reportar_resultado'),
        backgroundColor: _campo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _verde.withValues(alpha: 0.55)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: _verde),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          texto,
          style: const TextStyle(color: Color(0xFFC3C9F7)),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: const Color(0xFF03231B),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracao({
    required String rotulo,
    String? dica,
    IconData? icone,
    Widget? sufixo,
    bool alinharNoTopo = false,
  }) {
    OutlineInputBorder borda(Color cor, [double largura = 1.1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: _textoSuave, fontSize: 15),
      floatingLabelStyle: const TextStyle(
        color: _amarelo,
        fontWeight: FontWeight.w600,
      ),
      hintText: dica,
      hintStyle: TextStyle(
        color: _textoSuave.withValues(alpha: 0.6),
        fontSize: 15,
      ),
      alignLabelWithHint: alinharNoTopo,
      filled: true,
      fillColor: _campo,
      counterStyle: const TextStyle(color: _textoSuave, fontSize: 12),
      prefixIcon: icone != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icone, color: _roxoClaro, size: 22),
            )
          : null,
      suffixIcon: sufixo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: borda(_bordaCampo),
      focusedBorder: borda(_amarelo, 1.5),
      disabledBorder: borda(_bordaCampo.withValues(alpha: 0.45)),
      border: borda(_bordaCampo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _enviando || _lendoPrint;
    final rotuloRelato = switch (_tipo) {
      TipoReporte.link => 'O que dizia a mensagem (opcional)',
      TipoReporte.relato => 'O que aconteceu',
      TipoReporte.print => 'Texto do print (revise antes de publicar)',
    };

    return Scaffold(
      backgroundColor: _fundo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, color: _vermelho, size: 24),
            SizedBox(width: 8),
            Text(
              'Reportar golpe',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _FundoSemaforoPainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cartão de aviso com destaque em amarelo (atenção/cuidado).
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1718).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _amarelo.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _amarelo.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.privacy_tip_outlined,
                                color: _amarelo,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ReportarGolpePage.avisoPublico,
                                key: const Key('reportar_aviso'),
                                style: const TextStyle(
                                  color: Color(0xFFF3E9C6),
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Seletor de tipo estilizado com o fundo original e seleção em amarelo.
                      SegmentedButton<TipoReporte>(
                        key: const Key('reportar_tipo'),
                        style: SegmentedButton.styleFrom(
                          backgroundColor: _campo,
                          foregroundColor: _textoSuave,
                          selectedBackgroundColor:
                              _amarelo.withValues(alpha: 0.2),
                          selectedForegroundColor: _amarelo,
                          disabledForegroundColor:
                              _textoSuave.withValues(alpha: 0.4),
                          side: const BorderSide(color: _bordaCampo),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        segments: [
                          for (final tipo in TipoReporte.values)
                            ButtonSegment(
                              value: tipo,
                              label: Text(tipo.nome),
                              // Sem galeria nem OCR embarcado na web.
                              enabled: !(kIsWeb && tipo == TipoReporte.print),
                            ),
                        ],
                        selected: {_tipo},
                        showSelectedIcon: false,
                        onSelectionChanged: ocupado
                            ? null
                            : (selecao) => setState(() {
                                  _tipo = selecao.first;
                                  _erro = null;
                                }),
                      ),
                      const SizedBox(height: 20),
                      if (_tipo == TipoReporte.link) ...[
                        TextField(
                          key: const Key('reportar_link'),
                          controller: _link,
                          enabled: !ocupado,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: _amarelo,
                          decoration: _decoracao(
                            rotulo: 'Link suspeito',
                            dica: 'https://...',
                            icone: Icons.link,
                            sufixo: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TextButton(
                                key: const Key('reportar_colar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _amarelo,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: ocupado ? null : _colar,
                                child: const Text('Colar'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_tipo == TipoReporte.print) ...[
                        OutlinedButton.icon(
                          key: const Key('reportar_escolher_print'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _campo,
                            foregroundColor: _amarelo,
                            minimumSize: const Size.fromHeight(54),
                            side: BorderSide(
                              color: _amarelo.withValues(alpha: 0.65),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: ocupado ? null : _escolherPrint,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Escolher print'),
                        ),
                        if (_lendoPrint) ...[
                          const SizedBox(height: 12),
                          const Center(
                            child: CircularProgressIndicator(color: _amarelo),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        key: const Key('reportar_titulo'),
                        controller: _titulo,
                        enabled: !ocupado,
                        maxLength: tamanhoMaximoTitulo,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: _amarelo,
                        decoration: _decoracao(
                          rotulo: 'Título',
                          dica: 'Ex.: Falso parente pedindo Pix',
                          icone: Icons.title,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<CategoriaAmeaca>(
                        key: const Key('reportar_categoria'),
                        initialValue: _categoria,
                        isExpanded: true,
                        dropdownColor: _campo,
                        iconEnabledColor: _amarelo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: _decoracao(
                          rotulo: 'Tipo de golpe',
                          icone: Icons.warning_amber_rounded,
                        ),
                        items: [
                          for (final categoria in _categorias)
                            DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria.nome),
                            ),
                        ],
                        onChanged: ocupado
                            ? null
                            : (categoria) => setState(
                                  () => _categoria = categoria ?? _categoria,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('reportar_relato'),
                        controller: _relato,
                        enabled: !ocupado,
                        minLines: 3,
                        maxLines: 8,
                        maxLength: tamanhoMaximoRelato,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: _amarelo,
                        decoration: _decoracao(
                          rotulo: rotuloRelato,
                          alinharNoTopo: true,
                        ),
                      ),
                      // Caixa de erro em vermelho alerta.
                      if (_erro case final erro?) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _vermelho.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _vermelho.withValues(alpha: 0.65),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: _vermelho,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  erro,
                                  key: const Key('reportar_erro'),
                                  style: const TextStyle(
                                    color: Color(0xFFFFB3B6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      // Botão de publicação em verde (ação positiva de proteger a comunidade).
                      Opacity(
                        opacity: ocupado ? 0.6 : 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF06D6A0),
                                Color(0xFF059669),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _verde.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            key: const Key('reportar_publicar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFF03231B),
                              disabledForegroundColor: const Color(0xFF03231B),
                              shadowColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(60),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: ocupado ? null : _publicar,
                            child: _enviando
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF03231B),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined, size: 22),
                                      SizedBox(width: 10),
                                      Text('Publicar reporte'),
                                    ],
                                  ),
                          ),
                        ),
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

/// Fundo azul-marinho original do app com detalhes nos cantos nas cores de
/// alerta (vermelho, amarelo e verde) preenchendo 100% da tela.
class _FundoSemaforoPainter extends CustomPainter {
  const _FundoSemaforoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Rect.fromLTWH(0, 0, w, h);

    // Garante que o fundo azul-marinho cubra toda a área pintada.
    canvas.drawRect(todo, Paint()..color = const Color(0xFF050A24));

    // Forma do canto superior esquerdo (vermelho/alerta).
    final topo = Path()
      ..moveTo(0, 0)
      ..lineTo(0.45 * w, 0)
      ..cubicTo(0.42 * w, 0.06 * h, 0.24 * w, 0.11 * h, 0, 0.15 * h)
      ..close();
    canvas.drawPath(
      topo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0x99FF5A5F), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0, 0, 0.45 * w, 0.15 * h)),
    );

    // Forma do canto inferior direito (verde/proteção) encostando bem no canto.
    final base = Path()
      ..moveTo(w, h)
      ..lineTo(0.45 * w, h)
      ..cubicTo(0.49 * w, 0.91 * h, 0.75 * w, 0.85 * h, w, 0.84 * h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0x8806D6A0), Color(0xFF050A24)],
        ).createShader(Rect.fromLTWH(0.45 * w, 0.84 * h, 0.55 * w, 0.16 * h)),
    );

    // Arcos finos no azul original.
    final arco = Paint()
      ..color = const Color(0xFF2B3A9A).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(0.05 * w, -0.02 * h), 0.62 * w, arco);
    canvas.drawCircle(Offset(1.05 * w, 1.02 * h), 0.62 * w, arco);

    // Estrelinhas em amarelo, vermelho e verde.
    final estrelaAmarela = Paint()..color = const Color(0xFFFFD166);
    final estrelaVermelha = Paint()..color = const Color(0xFFFF5A5F);
    final estrelaVerde = Paint()..color = const Color(0xFF06D6A0);

    _estrela(canvas, Offset(0.84 * w, 0.08 * h), 0.024 * w, estrelaAmarela);
    _estrela(canvas, Offset(0.90 * w, 0.11 * h), 0.013 * w, estrelaVermelha);
    _estrela(canvas, Offset(0.12 * w, 0.92 * h), 0.020 * w, estrelaVerde);
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
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analise_texto_client.dart';
import 'calculadora_score.dart';
import 'captura_imagem.dart';
import 'imagem_em_memoria.dart';
import 'limite_texto_ocr.dart';
import 'mascaramento_local.dart';
import 'reconhecedor_texto.dart';
import 'resposta_modelo.dart';
import 'resultado_analise_print.dart';
import 'seletor_imagem.dart';
import 'sinais_identificados.dart';
import 'texto_em_memoria.dart';

/// Orquestra a análise de print do UC04 (Prompt 6.2), nesta ordem exata:
///
/// 1. imagem em memória (`CapturaImagem`, Fase 6.1);
/// 2. OCR embarcado no dispositivo ([ReconhecedorTexto], RNF06);
/// 3. descarte da imagem — antes de qualquer outra etapa;
/// 4. verificação de volume mínimo ([LimiteTextoOcr]);
/// 5. mascaramento local (`mascararTextoLocal`, RNF07 etapa 1);
/// 6. segunda verificação de volume mínimo, sobre o texto mascarado e
///    contando apenas o que fica fora dos marcadores;
/// 7. envio do texto mascarado ao LLM via Function ([AnaliseTextoClient]);
/// 8. identificação dos sinais, validada por [RespostaModelo];
/// 9. score pelo motor determinístico ([CalculadoraScore], RF07);
/// 10. descarte do texto (RNF07 etapa 3), em `finally`.
///
/// Garantias:
/// - a imagem nunca sai do dispositivo: não há etapa que a transmita;
/// - nenhum texto é transmitido antes do mascaramento e das duas
///   verificações de volume mínimo; falha em qualquer delas encerra o
///   fluxo sem transmissão;
/// - sem RAG nesta etapa (docs/ROADMAP.md, decisão de 2026-10-07): o
///   modelo julga apenas o texto recebido, e a análise é tratada como
///   verificação incompleta — a faixa verde fica impedida e o usuário é
///   informado de que a comparação com padrões catalogados não foi feita
///   (docs/score-calibracao.md, regra de verificação incompleta);
/// - o modelo não calcula score; um score enviado por ele é ignorado;
/// - nada é persistido aqui, e nada do conteúdo vai para log ou para a
///   mensagem de interrupção;
/// - nunca lança exceção para quem chama: toda falha vira
///   [AnalisePrintInterrompida] com mensagem própria.
class AnalisadorPrint {
  AnalisadorPrint({
    required this._reconhecedor,
    required this._cliente,
    this._mascarar = mascararTextoLocal,
    Future<void> Function(Duration intervalo)? aguardar,
    DateTime Function()? agora,
    @visibleForTesting this._aoCriarTexto,
  }) : _aguardar = aguardar ?? Future<void>.delayed,
       _agora = agora ?? DateTime.now;

  final ReconhecedorTexto _reconhecedor;
  final AnaliseTextoClient _cliente;
  final String Function(String texto) _mascarar;
  final Future<void> Function(Duration intervalo) _aguardar;
  final DateTime Function() _agora;
  final void Function(TextoEmMemoria texto)? _aoCriarTexto;

  /// Tempo máximo de espera pela Function, por tentativa. Maior que o
  /// timeout da Function para o Gemini, para que ela responda "não
  /// concluída" antes de o app desistir.
  static const Duration timeoutAnalise = Duration(seconds: 30);

  /// `false` enquanto a base de conhecimento (RAG, Fase 7) não existir.
  /// Nessa condição, toda análise de print é verificação incompleta.
  static const bool baseConhecimentoDisponivel = false;

  /// Informado ao usuário enquanto [baseConhecimentoDisponivel] for `false`.
  static const String motivoSemBaseConhecimento =
      'A comparação com padrões de golpe já catalogados não foi realizada: '
      'a base de conhecimento do Phize ainda não está disponível. Por isso, '
      'mesmo sem sinais encontrados, o resultado não aparece na faixa verde.';

  /// Intervalos progressivos entre novas tentativas quando o provedor
  /// recusa por limite de uso (UC04). Esgotados, o usuário é orientado a
  /// repetir a consulta em instantes.
  static const List<Duration> intervalosNovaTentativa = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  /// Seleciona o print na galeria e executa o pipeline completo.
  ///
  /// A imagem é descartada — e o temporário do seletor removido — por
  /// `CapturaImagem.processar` assim que o OCR termina, antes do
  /// mascaramento. `FileSystemException` e qualquer outra falha da captura
  /// viram mensagem genérica: a da exceção traz o nome original do print.
  Future<ResultadoAnalisePrint> analisarCaptura(CapturaImagem captura) async {
    final String? textoExtraido;
    try {
      textoExtraido = await captura.processar(_reconhecerEDescartar);
    } on SelecaoImagemNaoSuportadaException {
      return const AnalisePrintInterrompida(
        MotivoInterrupcaoPrint.plataformaNaoSuportada,
      );
    } on _FalhaReconhecimento catch (falha) {
      return AnalisePrintInterrompida(falha.motivo);
    } catch (_) {
      return const AnalisePrintInterrompida(
        MotivoInterrupcaoPrint.falhaCaptura,
      );
    }

    if (textoExtraido == null) return const AnalisePrintCancelada();
    return _analisarTextoExtraido(textoExtraido);
  }

  /// Executa o pipeline sobre uma imagem já em memória (ex.: recebida por
  /// compartilhamento nativo, UC11). A imagem é descartada logo após o
  /// OCR, com sucesso ou falha.
  Future<ResultadoAnalisePrint> analisarImagem(ImagemEmMemoria imagem) async {
    final String textoExtraido;
    try {
      textoExtraido = await _reconhecerEDescartar(imagem);
    } on _FalhaReconhecimento catch (falha) {
      return AnalisePrintInterrompida(falha.motivo);
    }
    return _analisarTextoExtraido(textoExtraido);
  }

  /// OCR seguido do descarte imediato da imagem, em `finally`. Falhas do
  /// reconhecedor viram [_FalhaReconhecimento], sem a exceção original.
  Future<String> _reconhecerEDescartar(ImagemEmMemoria imagem) async {
    try {
      return await _reconhecedor.reconhecer(imagem);
    } on ReconhecimentoTextoNaoSuportadoException {
      throw const _FalhaReconhecimento(
        MotivoInterrupcaoPrint.plataformaNaoSuportada,
      );
    } catch (_) {
      throw const _FalhaReconhecimento(
        MotivoInterrupcaoPrint.falhaReconhecimento,
      );
    } finally {
      imagem.descartar();
    }
  }

  Future<ResultadoAnalisePrint> _analisarTextoExtraido(
    String textoExtraido,
  ) async {
    final bruto = _guardar(textoExtraido);
    TextoEmMemoria? mascarado;
    try {
      if (!LimiteTextoOcr.atende(bruto.valor)) {
        return const AnalisePrintInterrompida(
          MotivoInterrupcaoPrint.textoInsuficiente,
        );
      }

      try {
        mascarado = _guardar(_mascarar(bruto.valor));
      } catch (_) {
        // Inclui o StateError de restauração do isolamento de URL/domínio:
        // a mensagem dele nunca chega ao usuário nem a log.
        return const AnalisePrintInterrompida(
          MotivoInterrupcaoPrint.falhaMascaramento,
        );
      }
      // O texto bruto não tem mais função: só o mascarado segue adiante.
      bruto.descartar();

      if (!LimiteTextoOcr.atendeAposMascaramento(mascarado.valor)) {
        return const AnalisePrintInterrompida(
          MotivoInterrupcaoPrint.textoInsuficienteAposMascaramento,
        );
      }

      final envio = await _enviarComNovaTentativa(mascarado.valor);
      // Concluída a resposta, o texto é removido da memória (RNF07, 3).
      mascarado.descartar();

      return switch (envio) {
        _EnvioFalhou(:final motivo) => AnalisePrintInterrompida(motivo),
        _EnvioConcluido(:final resposta) => AnalisePrintConcluida(
          score: CalculadoraScore.calcular(
            SinaisIdentificados(
              textoPrint: resposta.sinais,
              verificacaoIncompleta: !baseConhecimentoDisponivel,
            ),
          ),
          sinais: resposta.sinais,
          categoria: resposta.categoria,
          explicacao: resposta.explicacao,
          data: _agora(),
          verificacoesNaoConcluidas: const [
            if (!baseConhecimentoDisponivel) motivoSemBaseConhecimento,
          ],
        ),
      };
    } catch (_) {
      // Rede de segurança: nenhuma falha não prevista escapa para quem
      // chama, nem com a mensagem original.
      return const AnalisePrintInterrompida(
        MotivoInterrupcaoPrint.indisponivel,
      );
    } finally {
      bruto.descartar();
      mascarado?.descartar();
    }
  }

  TextoEmMemoria _guardar(String valor) {
    final texto = TextoEmMemoria(valor);
    _aoCriarTexto?.call(texto);
    return texto;
  }

  Future<_ResultadoEnvio> _enviarComNovaTentativa(String textoMascarado) async {
    for (var tentativa = 0; ; tentativa++) {
      final resultado = await _enviar(textoMascarado);
      final podeRepetir = tentativa < intervalosNovaTentativa.length;
      if (resultado is _EnvioFalhou &&
          resultado.motivo == MotivoInterrupcaoPrint.limiteProvedor &&
          podeRepetir) {
        await _aguardar(intervalosNovaTentativa[tentativa]);
        continue;
      }
      return resultado;
    }
  }

  Future<_ResultadoEnvio> _enviar(String textoMascarado) async {
    final Map<String, dynamic> resposta;
    try {
      resposta = await _cliente
          .analisar(textoMascarado)
          .timeout(timeoutAnalise);
    } on TimeoutException {
      return const _EnvioFalhou(MotivoInterrupcaoPrint.timeout);
    } on AnaliseTextoNaoAutenticadoException {
      return const _EnvioFalhou(MotivoInterrupcaoPrint.naoAutenticado);
    } on AnaliseTextoLimiteExcedidoException {
      return const _EnvioFalhou(MotivoInterrupcaoPrint.limiteUsuario);
    } catch (_) {
      return const _EnvioFalhou(MotivoInterrupcaoPrint.indisponivel);
    }
    return _interpretar(resposta);
  }

  /// Contrato da Function `analiseTexto` (functions/src/index.ts). Qualquer
  /// formato fora do contrato é descartado inteiro — nunca tratado como
  /// "sem sinais", o que levaria à faixa verde.
  static _ResultadoEnvio _interpretar(Map<String, dynamic> resposta) {
    switch (resposta['status']) {
      case 'concluida':
        final analise = RespostaModelo.deJson(resposta['analise']);
        return analise == null
            ? const _EnvioFalhou(MotivoInterrupcaoPrint.respostaInvalida)
            : _EnvioConcluido(analise);
      case 'nao_concluida':
        return _EnvioFalhou(switch (resposta['motivo']) {
          'limite_provedor' => MotivoInterrupcaoPrint.limiteProvedor,
          'timeout' => MotivoInterrupcaoPrint.timeout,
          'resposta_invalida' => MotivoInterrupcaoPrint.respostaInvalida,
          _ => MotivoInterrupcaoPrint.indisponivel,
        });
      default:
        return const _EnvioFalhou(MotivoInterrupcaoPrint.respostaInvalida);
    }
  }
}

/// Falha do OCR já traduzida em motivo, sem a exceção original.
class _FalhaReconhecimento implements Exception {
  const _FalhaReconhecimento(this.motivo);

  final MotivoInterrupcaoPrint motivo;
}

sealed class _ResultadoEnvio {
  const _ResultadoEnvio();
}

final class _EnvioConcluido extends _ResultadoEnvio {
  const _EnvioConcluido(this.resposta);

  final RespostaModelo resposta;
}

final class _EnvioFalhou extends _ResultadoEnvio {
  const _EnvioFalhou(this.motivo);

  final MotivoInterrupcaoPrint motivo;
}

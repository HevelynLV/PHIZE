import 'categoria_ameaca.dart';
import 'resultado_score.dart';
import 'sinal_texto_print.dart';

/// Tipo de entrada analisada, registrado no histórico (arquitetura, 5.4).
enum TipoEntrada { link, imagem }

/// Saída do pipeline do UC04 (`AnalisadorPrint`). Nunca contém o texto
/// analisado nem a imagem: nenhum dos tipos abaixo tem campo para isso.
sealed class ResultadoAnalisePrint {
  const ResultadoAnalisePrint();
}

/// Análise concluída. Os campos são exatamente os que a persistência
/// seletiva admite (RNF07, etapa 4; arquitetura, 5.4): score, categoria,
/// explicação, tipo de entrada e data — mais os sinais e as verificações
/// não concluídas, que a tela de resultado lista e que não são conteúdo da
/// conversa.
final class AnalisePrintConcluida extends ResultadoAnalisePrint {
  const AnalisePrintConcluida({
    required this.score,
    required this.sinais,
    required this.categoria,
    required this.explicacao,
    required this.data,
    this.verificacoesNaoConcluidas = const [],
  });

  /// Calculado por `CalculadoraScore` a partir de [sinais] (RF07).
  final ResultadoScore score;
  final Set<SinalTextoPrint> sinais;
  final CategoriaAmeaca categoria;
  final String explicacao;
  final DateTime data;

  /// Quais verificações não puderam ser concluídas, em linguagem não
  /// técnica, para exibição ao usuário (CLAUDE.md, Seção 8). Não vazia
  /// sempre que `score.verificacaoIncompleta` for `true`.
  final List<String> verificacoesNaoConcluidas;

  TipoEntrada get tipoEntrada => TipoEntrada.imagem;
}

/// O usuário cancelou a seleção da imagem.
final class AnalisePrintCancelada extends ResultadoAnalisePrint {
  const AnalisePrintCancelada();
}

/// O fluxo foi interrompido. [mensagem] é sempre uma das mensagens próprias
/// de [MotivoInterrupcaoPrint] — nunca a de uma exceção, que pode trazer o
/// caminho do print ou trecho do texto.
final class AnalisePrintInterrompida extends ResultadoAnalisePrint {
  const AnalisePrintInterrompida(this.motivo);

  final MotivoInterrupcaoPrint motivo;

  String get mensagem => motivo.mensagem;

  /// UC04: resposta inválida do modelo oferece nova tentativa.
  bool get permiteNovaTentativa => motivo.permiteNovaTentativa;
}

enum MotivoInterrupcaoPrint {
  /// Plataforma sem seleção de imagem ou sem OCR embarcado (ex.: web).
  plataformaNaoSuportada(
    'A análise de prints não está disponível nesta versão do aplicativo. '
    'Use o Phize no celular.',
  ),

  /// Falha ao abrir, ler ou remover o print (inclui `FileSystemException`,
  /// cuja mensagem traz o nome original do arquivo).
  falhaCaptura(
    'Não foi possível abrir a imagem escolhida. Tente selecionar o print '
    'novamente.',
  ),

  /// O reconhecimento embarcado falhou.
  falhaReconhecimento(
    'Não foi possível ler o texto desta imagem. Tente novamente com outro '
    'print.',
  ),

  /// OCR vazio, ilegível ou abaixo do volume mínimo antes do mascaramento.
  textoInsuficiente(
    'Não conseguimos ler texto suficiente nesta imagem. Envie um print mais '
    'nítido, em que a mensagem apareça inteira.',
  ),

  /// Falha na rotina de mascaramento local (ex.: `StateError`). Por
  /// proteção, nada é enviado.
  falhaMascaramento(
    'Não foi possível preparar o texto com segurança para a análise. Por '
    'proteção, nada foi enviado. Tente novamente.',
  ),

  /// Após o mascaramento, o texto ficou abaixo do volume mínimo: o print
  /// continha basicamente dados pessoais, sem mensagem a analisar.
  textoInsuficienteAposMascaramento(
    'Esta imagem mostra basicamente dados pessoais, como CPF, telefone ou '
    'cartão, e quase nenhuma mensagem para analisar. Envie um print que '
    'mostre a conversa.',
  ),

  /// A análise excedeu o tempo limite (UC04, "Timeout nas APIs").
  timeout('A análise demorou mais que o esperado. Tente novamente mais tarde.'),

  /// Resposta fora do formato esperado, descartada sem exibição parcial.
  respostaInvalida(
    'Não conseguimos concluir a análise desta vez. Toque para tentar '
    'novamente.',
    permiteNovaTentativa: true,
  ),

  /// O provedor de LLM recusou por cota, mesmo após as novas tentativas.
  limiteProvedor(
    'O serviço de análise está muito procurado agora. Repita a consulta em '
    'instantes.',
  ),

  /// O próprio usuário excedeu o limite de análises da Function.
  limiteUsuario(
    'Você fez muitas análises em pouco tempo. Repita a consulta em '
    'instantes.',
  ),

  /// Sem sessão válida para chamar a Function.
  naoAutenticado(
    'Não foi possível confirmar sua sessão. Entre novamente no aplicativo.',
  ),

  /// Function ou provedor indisponível.
  indisponivel(
    'O serviço de análise não está disponível agora. Tente novamente mais '
    'tarde.',
  );

  const MotivoInterrupcaoPrint(
    this.mensagem, {
    this.permiteNovaTentativa = false,
  });

  final String mensagem;
  final bool permiteNovaTentativa;
}

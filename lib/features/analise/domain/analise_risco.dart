import 'faixa_risco.dart';

/// Registro de uma análise no Histórico (RF07 / RNF01): apenas o resultado,
/// nunca o conteúdo analisado.
///
/// Por ora alimentado por dado fictício na tela de Histórico; a origem real
/// (persistência seletiva no Firestore) é a Fase 8 (UC06).
class AnaliseRisco {
  const AnaliseRisco({
    required this.id,
    required this.score,
    required this.faixa,
    required this.explicacao,
    required this.sinais,
    required this.data,
  });

  final String id;
  final int score;
  final FaixaRisco faixa;
  final String explicacao;
  final List<String> sinais;
  final DateTime data;
}

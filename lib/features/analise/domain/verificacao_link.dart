/// Resultado de uma verificação individual da análise de link (RF03/UC03).
enum StatusVerificacao {
  /// A verificação foi concluída e encontrou um sinal de risco.
  sinalEncontrado,

  /// A verificação foi concluída e não encontrou sinal de risco.
  semSinal,

  /// A verificação não pôde ser concluída (degradação controlada,
  /// CLAUDE.md, Seção 8).
  naoConcluida,
}

/// Uma verificação da análise de link, apresentada individualmente ao
/// usuário em linguagem não técnica e com a fonte consultada atribuída
/// (RF03, critérios de aceitação).
class VerificacaoLink {
  const VerificacaoLink({
    required this.titulo,
    required this.descricao,
    required this.fonte,
    required this.status,
  });

  final String titulo;
  final String descricao;
  final String fonte;
  final StatusVerificacao status;
}

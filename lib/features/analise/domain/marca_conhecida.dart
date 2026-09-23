/// Uma marca (banco ou serviço financeiro) frequentemente imitada em golpes
/// de typosquatting no Brasil (RF03/UC03; arquitetura, seção 4, item 4).
class MarcaConhecida {
  const MarcaConhecida({
    required this.nome,
    required this.dominioOficial,
    this.apelidos = const [],
  });

  /// Nome-base usado na comparação por distância de edição (minúsculo, sem
  /// espaços ou acentos — ex.: "itau", não "Itaú"). Corresponde sempre ao
  /// primeiro rótulo do domínio registrável de [dominioOficial].
  final String nome;

  /// Domínio legítimo já normalizado (minúsculo, sem "www.", esquema,
  /// caminho ou parâmetros de consulta — ex.: "itau.com.br").
  final String dominioOficial;

  /// Apelidos curtos de uso comum pelos quais a marca também é conhecida
  /// (ex.: "inter" para o Banco Inter, cujo domínio usa "bancointer"). Cada
  /// apelido é comparado exatamente como [nome]: participa da checagem de
  /// pedaço isolado e da distância de edição, com o próprio limite de
  /// distância calculado a partir do tamanho do apelido, não do nome
  /// principal.
  final List<String> apelidos;
}

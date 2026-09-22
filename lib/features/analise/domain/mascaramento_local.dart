/// Mascaramento local de dados pessoais estruturados (RNF07, etapa 1;
/// arquitetura 5.2).
///
/// Função pura executada no dispositivo, sem chamada de API: substitui por
/// marcadores genéricos os padrões de dado pessoal de formato previsível
/// (CPF, CNPJ, telefone, e-mail, chave Pix aleatória, cartão e boleto),
/// preservando integralmente verbos de urgência, valores monetários,
/// domínios/URLs e a estrutura argumentativa do texto — nenhum desses
/// elementos corresponde aos padrões abaixo, então nunca são tocados.
library;

// Ponto de código da Área de Uso Privado do Unicode: não aparece em texto
// real, então serve como marcador temporário sem risco de colidir com
// nenhuma das expressões abaixo enquanto uma URL/domínio está isolado.
const int _placeholderBase = 0xE000;

final RegExp _regexEmail = RegExp(
  r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
);

// URLs e domínios são isolados do texto ANTES de qualquer outra máscara e
// reinseridos ao final, intactos (arquitetura 5.2: "a rotina preserva
// integralmente... domínios"). Isso vale tanto para URLs completas (com
// esquema, ex.: "https://banco.com/pag/123") quanto para domínios nus, com
// ou sem caminho depois da barra (ex.: "whatsapp-seguro11987654321.com" ou
// "bb-seguranca.net/pagamento/123") — um dígito colado ao hostname ou ao
// caminho nunca deve ser lido como CPF/telefone/cartão. Sem uma barra
// depois do TLD, a exigência de fronteira de palavra (`\b`) é mantida tal
// como antes, preservando o comportamento já validado. Os dois padrões
// exigem um segmento de TLD só de letras, o que os distingue
// estruturalmente de CPF/CNPJ/telefone/cartão/boleto: nenhum desses
// formatos contém letras, então nunca competem com esta extração.
final RegExp _regexUrl = RegExp(r'https?://\S+');
final RegExp _regexDominio = RegExp(
  r'\b(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?:/\S*|\b)',
);

final RegExp _regexChavePix = RegExp(
  r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}\b',
);

// Linha digitável de boleto. A faixa (40 a 50 dígitos) é deliberadamente
// mais larga que os tamanhos reais (bancário: 47; convênio: 48): o texto
// chega via OCR, sujeito a erro de leitura que pode inserir ou omitir um
// dígito. Mascarar um número que não é exatamente um boleto real é
// preferível a deixar vazar um que é — o custo de mascarar a mais é
// perder um número do texto; o custo de vazar é dado financeiro sensível
// trafegando para a nuvem. Avaliada antes do cartão no pipeline abaixo,
// para que uma linha digitável nunca seja lida como cartão.
final RegExp _regexBoleto = RegExp(r'(?<!\d)\d{40,50}(?!\d)');

final RegExp _regexCnpjFormatado = RegExp(r'\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}');

// Guarda de valor monetário: um número de 11 ou 14 dígitos sem separadores
// pode coincidir em tamanho com um CPF/CNPJ (case-limite explícito).
// Quando precedido por "R$" e seguido de ",dd" (centavos), é tratado como
// valor monetário e preservado, nunca mascarado. Isso nunca entra em
// conflito com um CPF/CNPJ formatado (ex.: "123.456.789-00"): o formato
// deles usa ponto a cada 3 dígitos e hífen antes dos 2 últimos, enquanto
// um valor monetário usa ponto como separador de milhar e vírgula antes
// dos centavos — as duas máscaras nunca miram o mesmo trecho de texto, daí
// "CPF 123.456.789-00" e "R$ 1.500,00" na mesma frase resultarem em só o
// CPF mascarado, sem precisar de nenhuma regra especial para isso.
final RegExp _regexCnpjSemPontuacao = RegExp(
  r'(?<!R\$)(?<!R\$ )(?<!\d)\d{14}(?!\d)(?!,\d{2})',
);

final RegExp _regexCpfFormatado = RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}');

final RegExp _regexCpfSemPontuacao = RegExp(
  r'(?<!R\$)(?<!R\$ )(?<!\d)\d{11}(?!\d)(?!,\d{2})',
);

// Cartão: com separadores (espaço ou hífen, 4x4) ou corrido (13 a 16
// dígitos — faixa real das bandeiras: Amex tem 15, a maioria 16, algumas
// 13). "(?<!\+)" exclui o dígito de telefone com DDI sem separador (ex.:
// "+5511912345678", 13 dígitos após o "+"), tratado à parte pela regra de
// telefone; a mesma guarda de valor monetário do CPF/CNPJ também se
// aplica aqui, pelo mesmo motivo.
final RegExp _regexCartao = RegExp(
  r'(?<!\d)\d{4}[ -]\d{4}[ -]\d{4}[ -]\d{4}(?!\d)'
  r'|(?<!R\$)(?<!R\$ )(?<!\+)(?<!\d)\d{13,16}(?!\d)(?!,\d{2})',
);

// Três variantes, nesta ordem de alternância: com DDI (+55, com ou sem
// separadores), com DDD entre parênteses, e sem DDD (exige hífen — sem ele,
// um número solto de 8/9 dígitos seria indistinguível de um valor
// numérico qualquer).
final RegExp _regexTelefone = RegExp(
  r'(\+55\s?\(?\d{2}\)?[\s-]?9?\d{4}-?\d{4})'
  r'|(\(\d{2}\)\s?9?\d{4}-\d{4})'
  r'|((?<!\d)9?\d{4}-\d{4}(?!\d))',
);

String mascararTextoLocal(String texto) {
  // Os marcadores de isolamento de URL/domínio nunca são fixos: partem de
  // _placeholderBase mas avançam até um ponto de código ausente do texto
  // de ENTRADA real, para que um caractere da Área de Uso Privado já
  // presente no texto original nunca seja confundido com um marcador
  // nosso e sobrescrito na restauração.
  final codigosNoTextoOriginal = texto.runes.toSet();
  var proximoCodigo = _placeholderBase;
  int proximoMarcadorLivre() {
    while (codigosNoTextoOriginal.contains(proximoCodigo)) {
      proximoCodigo++;
    }
    return proximoCodigo++;
  }

  var resultado = texto.replaceAll(_regexEmail, '[EMAIL]');

  final urlsEDominios = <String>[];
  final marcadoresUsados = <int>[];
  String isolar(Match match) {
    urlsEDominios.add(match.group(0)!);
    final codigo = proximoMarcadorLivre();
    marcadoresUsados.add(codigo);
    return String.fromCharCode(codigo);
  }

  resultado = resultado.replaceAllMapped(_regexUrl, isolar);
  resultado = resultado.replaceAllMapped(_regexDominio, isolar);

  resultado = resultado.replaceAll(_regexChavePix, '[CHAVE_PIX]');
  resultado = resultado.replaceAll(_regexBoleto, '[BOLETO]');
  resultado = resultado.replaceAll(_regexCnpjFormatado, '[CNPJ]');
  resultado = resultado.replaceAll(_regexCnpjSemPontuacao, '[CNPJ]');
  resultado = resultado.replaceAll(_regexCpfFormatado, '[CPF]');
  resultado = resultado.replaceAll(_regexCpfSemPontuacao, '[CPF]');
  resultado = resultado.replaceAll(_regexCartao, '[CARTAO]');
  resultado = resultado.replaceAll(_regexTelefone, '[TELEFONE]');

  for (var i = 0; i < urlsEDominios.length; i++) {
    resultado = resultado.replaceAll(
      String.fromCharCode(marcadoresUsados[i]),
      urlsEDominios[i],
    );
  }

  // Checagem defensiva: nenhum marcador de isolamento pode sobreviver à
  // restauração. Se algum sobrar aqui, o texto está corrompido — é
  // preferível interromper a análise com um erro explícito a devolver ao
  // restante do pipeline (e, no fim, à nuvem) um texto adulterado que
  // ninguém percebeu estar errado.
  final codigosRestantes = resultado.runes.toSet();
  if (marcadoresUsados.any(codigosRestantes.contains)) {
    throw StateError(
      'mascararTextoLocal: marcador de isolamento de URL/domínio não foi '
      'restaurado; abortando em vez de devolver texto corrompido.',
    );
  }

  return resultado;
}

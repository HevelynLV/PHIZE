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

/// Marcadores genéricos que [mascararTextoLocal] insere no lugar dos dados
/// pessoais. A segunda verificação de volume mínimo (`LimiteTextoOcr`)
/// conta apenas o texto fora deles.
const List<String> marcadoresMascaramento = [
  '[CPF]',
  '[CNPJ]',
  '[TELEFONE]',
  '[EMAIL]',
  '[CHAVE_PIX]',
  '[CARTAO]',
  '[BOLETO]',
];

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

// Chave Pix aleatória sem hífens: os mesmos 32 caracteres hexadecimais,
// corridos. Avaliada logo após a forma com hífens e antes de boleto, CNPJ,
// CPF e cartão, para que a chave nunca seja partida por essas regras (o
// trecho numérico final de uma chave se parece com um cartão corrido).
final RegExp _regexChavePixSemHifens = RegExp(
  r'(?<![0-9A-Za-z])[0-9a-fA-F]{32}(?![0-9A-Za-z])',
);

// Linha digitável de boleto. A faixa (40 a 50 dígitos) é deliberadamente
// mais larga que os tamanhos reais (bancário: 47; convênio: 48): o texto
// chega via OCR, sujeito a erro de leitura que pode inserir ou omitir um
// dígito. Mascarar um número que não é exatamente um boleto real é
// preferível a deixar vazar um que é — o custo de mascarar a mais é
// perder um número do texto; o custo de vazar é dado financeiro sensível
// trafegando para a nuvem. Avaliada antes do cartão no pipeline abaixo,
// para que uma linha digitável nunca seja lida como cartão.
const int _minDigitosBoleto = 40;
const int _maxDigitosBoleto = 50;
final RegExp _regexBoleto = RegExp(
  '(?<!\\d)\\d{$_minDigitosBoleto,$_maxDigitosBoleto}(?!\\d)',
);

// Linha digitável no formato impresso: blocos de dígitos separados por
// pontos, hífens e espaços — bancário (ex.: "23793.38128 60000.000003
// 00000.000400 1 84340000012345") e convênio, como contas de luz e água
// (ex.: "83640000001-1 47530000000-1 ..."). Captura qualquer sequência de
// blocos assim e só a mascara se o total de dígitos cair na mesma faixa de
// _regexBoleto (ver _mascararBoletoFormatado); fora dela — CPF formatado,
// telefone, data —, o trecho fica intacto e segue para as demais máscaras. Avaliada junto com _regexBoleto, antes de CNPJ e
// cartão, pelo mesmo motivo. As guardas nas bordas impedem que a sequência
// absorva os centavos de um valor monetário vizinho ("R$ 150,00 2379...")
// ou o próprio valor ("R$ 500 2379..."): o bloco não pode começar logo
// após "R$", após "dígito," nem após ponto, e não pode terminar antes de
// ",dígito".
final RegExp _regexBoletoFormatado = RegExp(
  r'(?<!R\$)(?<!R\$ )(?<![\d.])(?<!\d,)\d+(?:(?:\s*[.-]\s*|\s+)\d+)+'
  r'(?!\d)(?!,\d)',
);

final RegExp _regexNaoDigito = RegExp(r'\D');

String _mascararBoletoFormatado(Match match) {
  final trecho = match.group(0)!;
  final digitos = trecho.replaceAll(_regexNaoDigito, '').length;
  return digitos >= _minDigitosBoleto && digitos <= _maxDigitosBoleto
      ? '[BOLETO]'
      : trecho;
}

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

// CNPJ em qualquer combinação de separadores — ponto, barra, hífen ou
// espaço, ou nenhum — entre os blocos 2-3-3-4-2 (ex.: "12 345 678 0001
// 95", "12.345.678/0001 95"), numérico ou alfanumérico. O CNPJ
// alfanumérico, vigente desde 2026, tem raiz (8) e ordem (4) com letras
// maiúsculas ou dígitos e os dois dígitos verificadores numéricos (ex.:
// "12.ABC.345/01DE-35"). Avaliada depois das duas regras acima, que cobrem
// as formas canônicas numéricas. As guardas impedem pegar parte de um
// token maior e os centavos de um valor monetário.
//
// A forma alfanumérica pontuada ("12.ABC...") tem cara de domínio e seria
// protegida pela isolação de URL/domínio; por isso as ocorrências que
// contêm letra são mascaradas ANTES dessa isolação (ver
// _mascararCnpjAlfanumerico). As puramente numéricas seguem na ordem
// normal, depois dela, preservando os números dentro de URLs.
final RegExp _regexCnpjVariante = RegExp(
  r'(?<!R\$)(?<!R\$ )(?<![0-9A-Za-z])'
  r'[0-9A-Z]{2}(?:\s*[./-]\s*|\s+)?[0-9A-Z]{3}(?:\s*[./-]\s*|\s+)?'
  r'[0-9A-Z]{3}(?:\s*[./-]\s*|\s+)?[0-9A-Z]{4}(?:\s*[./-]\s*|\s+)?\d{2}'
  r'(?![0-9A-Za-z])(?!,\d)',
);

final RegExp _regexLetra = RegExp('[A-Z]');

String _mascararCnpjAlfanumerico(Match match) {
  final trecho = match.group(0)!;
  return _regexLetra.hasMatch(trecho) ? '[CNPJ]' : trecho;
}

final RegExp _regexCpfFormatado = RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}');

// Variações do CPF formatado comuns em texto de OCR, que troca ou omite
// pontuação: espaço no lugar dos pontos ou do hífen ("123 456 789 00",
// "123.456.789 00") e barra ou ponto no lugar do hífen ("123.456.789/00").
// Avaliada depois de _regexCpfFormatado, que já cobre o formato canônico.
// As guardas impedem pegar um trecho de uma sequência numérica maior. O
// rótulo segue a mesma heurística de _rotuloOnzeDigitos.
final RegExp _regexCpfVariante = RegExp(
  r'(?<!\d)(?<!\d\.)\d{3}[.\s]\d{3}[.\s]\d{3}[-/.\s]\d{2}(?!\d)(?!\.\d)',
);

final RegExp _regexCpfSemPontuacao = RegExp(
  r'(?<!R\$)(?<!R\$ )(?<!\d)\d{11}(?!\d)(?!,\d{2})',
);

// Um celular brasileiro sem separadores (DDD + 9 + 8 dígitos) tem os
// mesmos 11 dígitos de um CPF sem pontuação, e os dois casam com
// _regexCpfSemPontuacao. A distinção é HEURÍSTICA: a sequência é tratada
// como celular quando os dois primeiros dígitos são um DDD válido e o
// terceiro é 9 (o "nono dígito" dos celulares). Um CPF pode, por acaso,
// ter esse formato e sair como [TELEFONE] — e um celular com DDD fora da
// lista sai como [CPF]. Em dúvida, [CPF] é o lado seguro: o dado é
// mascarado de todo modo, e só o rótulo fica impreciso.
const Set<String> _dddsValidos = {
  '11', '12', '13', '14', '15', '16', '17', '18', '19', //
  '21', '22', '24', '27', '28', //
  '31', '32', '33', '34', '35', '37', '38', //
  '41', '42', '43', '44', '45', '46', '47', '48', '49', //
  '51', '53', '54', '55', //
  '61', '62', '63', '64', '65', '66', '67', '68', '69', //
  '71', '73', '74', '75', '77', '79', //
  '81', '82', '83', '84', '85', '86', '87', '88', '89', //
  '91', '92', '93', '94', '95', '96', '97', '98', '99', //
};

String _rotuloOnzeDigitos(String digitos) {
  final pareceCelular =
      _dddsValidos.contains(digitos.substring(0, 2)) && digitos[2] == '9';
  return pareceCelular ? '[TELEFONE]' : '[CPF]';
}

String _mascararOnzeDigitos(Match match) => _rotuloOnzeDigitos(match.group(0)!);

String _mascararCpfVariante(Match match) =>
    _rotuloOnzeDigitos(match.group(0)!.replaceAll(_regexNaoDigito, ''));

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

// Cinco variantes, nesta ordem de alternância: com DDI (+55, com ou sem
// separadores), com DDD entre parênteses, com DDD separado por espaço
// (ex.: "11 98765 4321", "11 98765-4321", "11 987654321"), sem DDD com
// hífen ("98765-4321", "3456-7890"), e celular sem DDD com espaço ou sem
// separador ("98765 4321", "987654321"). Nas três primeiras, as duas
// metades do número podem vir separadas por espaço ou hífen. Sem DDD, o
// espaço e a ausência de separador só valem para celular (9 dígitos
// começando em 9): um fixo de 8 dígitos assim seria indistinguível de um
// valor numérico qualquer. O celular de 11 dígitos corridos é tratado à
// parte (ver _mascararOnzeDigitos).
final RegExp _regexTelefone = RegExp(
  r'(\+55\s?\(?\d{2}\)?[\s-]?9?\d{4}[\s-]?\d{4})'
  r'|(\(\d{2}\)\s?9?\d{4}[\s-]\d{4})'
  r'|((?<!\d)\d{2}\s9?\d{4}[\s-]?\d{4}(?!\d))'
  r'|((?<!\d)9?\d{4}-\d{4}(?!\d))'
  r'|((?<!R\$)(?<!R\$ )(?<!\d)9\d{4}\s?\d{4}(?!\d)(?!,\d))',
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
  resultado = resultado.replaceAllMapped(
    _regexCnpjVariante,
    _mascararCnpjAlfanumerico,
  );

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
  resultado = resultado.replaceAll(_regexChavePixSemHifens, '[CHAVE_PIX]');
  resultado = resultado.replaceAllMapped(
    _regexBoletoFormatado,
    _mascararBoletoFormatado,
  );
  resultado = resultado.replaceAll(_regexBoleto, '[BOLETO]');
  resultado = resultado.replaceAll(_regexCnpjFormatado, '[CNPJ]');
  resultado = resultado.replaceAll(_regexCnpjSemPontuacao, '[CNPJ]');
  resultado = resultado.replaceAll(_regexCnpjVariante, '[CNPJ]');
  resultado = resultado.replaceAll(_regexCpfFormatado, '[CPF]');
  resultado = resultado.replaceAllMapped(
    _regexCpfVariante,
    _mascararCpfVariante,
  );
  resultado = resultado.replaceAllMapped(
    _regexCpfSemPontuacao,
    _mascararOnzeDigitos,
  );
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

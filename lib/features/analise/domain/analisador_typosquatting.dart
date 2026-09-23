/// Análise de anatomia de URL para detecção de typosquatting (RF03/UC03;
/// arquitetura, seção 4, item 4). Função pura, sem chamada de rede: compara
/// o domínio normalizado com a lista curada de `marcasConhecidas`, tanto
/// por igualdade exata de pedaço isolado quanto por distância de edição
/// (algoritmo de Levenshtein), incluindo os apelidos de cada marca.
library;

import 'marcas_conhecidas.dart';
import 'normalizacao_url.dart';
import 'resultado_analise_dominio.dart';

class AnalisadorTyposquatting {
  AnalisadorTyposquatting._();

  // TLDs de segundo nível reconhecidas sob ".br", usadas para isolar o nome
  // registrável quando o domínio segue o padrão "nome.<categoria>.br" (ex.:
  // "itau.com.br"). Sem essa lista, "com" seria tratado como o nome do
  // domínio e "itau" como subdomínio, apontando falsamente um mimetismo de
  // subdomínio inexistente.
  static const _segundosNiveisBr = {'com', 'gov', 'org', 'net', 'edu'};

  // Confusões visuais deliberadamente curta: cobre só os disfarces mais
  // comuns observados em typosquatting de marcas brasileiras (dobrar uma
  // letra para imitar outra, ou usar dígito no lugar de letra parecida).
  // Pode crescer conforme novos padrões forem observados; aplicada apenas
  // ao pedaço analisado, antes do cálculo de distância de edição — nunca
  // aos nomes/apelidos de referência da lista, nem à checagem de pedaço
  // isolado (que precisa continuar exata).
  static const _confusoesVisuais = {
    'll': 'l',
    'rn': 'm',
    'vv': 'w',
    '1': 'l',
    '0': 'o',
    '5': 's',
  };

  static ResultadoAnaliseDominio analisar(String entrada) {
    final dominio = normalizarDominio(entrada);
    if (dominio == null) {
      return const ResultadoAnaliseDominio(entradaValida: false);
    }

    final rotulos = dominio.split('.');
    final registravel = _labelsRegistravel(rotulos);
    final subdominios = rotulos.sublist(
      0,
      rotulos.length - registravel.length,
    );
    final nomeRegistravel = registravel.first;
    final dominioRegistravel = registravel.join('.');

    // Domínio exatamente igual ao de alguma marca da lista: é a marca
    // legítima, nunca typosquatting dela mesma. Tem precedência sobre todo
    // o restante da análise.
    final ehDominioLegitimo = marcasConhecidas.any(
      (m) => m.dominioOficial == dominioRegistravel,
    );
    if (ehDominioLegitimo) {
      return ResultadoAnaliseDominio(
        entradaValida: true,
        dominioNormalizado: dominio,
      );
    }

    // Pedaços do host inteiro, quebrado tanto por ponto (subdomínios) como
    // por hífen dentro de cada rótulo, para capturar o nome de uma marca
    // embutido num rótulo composto (ex.: "itau-seguranca.com.br",
    // "meu-itau.atendimento-cliente.net"). O nome/apelido que corresponde
    // ao domínio registrável INTEIRO (sem hífen, ex.: "inter" em
    // "inter.com.br") nunca entra aqui como pedaço isolado: esse caso já é
    // resolvido pela distância de edição abaixo (distância zero = mesmo
    // nome, não é golpe).
    final pedacos = <String>{
      ...subdominios.expand((rotulo) => rotulo.split('-')),
      ...nomeRegistravel.split('-'),
    }..remove(nomeRegistravel);

    final nomeRegistravelNormalizado = _normalizarVisual(nomeRegistravel);

    for (final marca in marcasConhecidas) {
      for (final nome in [marca.nome, ...marca.apelidos]) {
        // Pedaço isolado exatamente igual ao nome/apelido da marca: golpe
        // que embute o nome real dentro de um rótulo composto. A
        // correspondência aqui é exata, não por distância de edição — o
        // golpe explora o nome verdadeiro da marca para parecer legítimo à
        // primeira vista, não uma variação dele. Por isso
        // "interior-moveis.com.br" não dispara para o apelido "inter": o
        // pedaço isolado é "interior", não "inter".
        if (pedacos.contains(nome)) {
          return ResultadoAnaliseDominio(
            entradaValida: true,
            dominioNormalizado: dominio,
            typosquattingDetectado: true,
            marcaImitada: marca.nome,
          );
        }

        // O limite de distância é calculado a partir do tamanho do nome
        // efetivamente comparado (nome principal ou apelido), não do nome
        // principal da marca: um apelido curto (ex.: "inter", "xp")
        // precisa da mesma proteção contra falso positivo que qualquer
        // outro nome curto teria isoladamente.
        final distanciaMaxima = _distanciaMaximaPermitida(nome.length);
        if (distanciaMaxima == 0) continue;

        final distancia = _distanciaEdicao(nomeRegistravelNormalizado, nome);
        if (distancia > 0 && distancia <= distanciaMaxima) {
          return ResultadoAnaliseDominio(
            entradaValida: true,
            dominioNormalizado: dominio,
            typosquattingDetectado: true,
            marcaImitada: marca.nome,
          );
        }
      }
    }

    return ResultadoAnaliseDominio(
      entradaValida: true,
      dominioNormalizado: dominio,
    );
  }

  static List<String> _labelsRegistravel(List<String> rotulos) {
    if (rotulos.length >= 3 &&
        rotulos.last == 'br' &&
        _segundosNiveisBr.contains(rotulos[rotulos.length - 2])) {
      return rotulos.sublist(rotulos.length - 3);
    }
    return rotulos.sublist(rotulos.length - 2);
  }

  static String _normalizarVisual(String pedaco) {
    var resultado = pedaco;
    for (final confusao in _confusoesVisuais.entries) {
      resultado = resultado.replaceAll(confusao.key, confusao.value);
    }
    return resultado;
  }

  // Distância máxima de edição tolerada, em função do tamanho do nome
  // comparado (nome principal ou apelido da marca). Nomes muito curtos (até
  // 3 caracteres, ex.: "bb", "xp") ficam restritos a correspondência exata:
  // uma distância de 1 já cobriria uma proporção grande de domínios curtos
  // não relacionados (ex.: "cb", "ab"), gerando falso positivo. Nomes de 4
  // a 6 caracteres toleram 1 edição — o padrão mais comum de
  // typosquatting: uma letra trocada, a mais ou a menos (após a
  // normalização visual, que já resolve casos como "itall" para "ital").
  // Nomes maiores toleram 2, por terem mais margem antes de colidir com uma
  // palavra não relacionada.
  static int _distanciaMaximaPermitida(int tamanhoNome) {
    if (tamanhoNome <= 3) return 0;
    if (tamanhoNome <= 6) return 1;
    return 2;
  }

  static int _distanciaEdicao(String a, String b) {
    final custos = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      var anterior = custos[0];
      custos[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final custoAnteriorDiagonal = custos[j];
        if (a[i - 1] == b[j - 1]) {
          custos[j] = anterior;
        } else {
          final menor = [
            anterior,
            custos[j],
            custos[j - 1],
          ].reduce((x, y) => x < y ? x : y);
          custos[j] = 1 + menor;
        }
        anterior = custoAnteriorDiagonal;
      }
    }
    return custos[b.length];
  }
}

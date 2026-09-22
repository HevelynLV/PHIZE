import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/domain/score_config.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_link.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';

void main() {
  group('Cenários de validação (docs/score-calibracao.md)', () {
    test('falso parente pedindo dinheiro (60, vermelho)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {
            SinalTextoPrint.pedidoFinanceiro,
            SinalTextoPrint.alegacaoTrocaContato,
          },
        ),
      );

      expect(resultado.pontuacao, 60);
      expect(resultado.faixa, FaixaRisco.alto);
    });

    test('falso parente com indução de urgência (80, vermelho)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {
            SinalTextoPrint.pedidoFinanceiro,
            SinalTextoPrint.alegacaoTrocaContato,
            SinalTextoPrint.inducaoUrgencia,
          },
        ),
      );

      expect(resultado.pontuacao, 80);
      expect(resultado.faixa, FaixaRisco.alto);
    });

    test('falsa central bancária (75, vermelho)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {
            SinalTextoPrint.ameaca,
            SinalTextoPrint.solicitacaoDadosPessoais,
            SinalTextoPrint.inducaoUrgencia,
          },
        ),
      );

      expect(resultado.pontuacao, 75);
      expect(resultado.faixa, FaixaRisco.alto);
    });

    test('loja real com "só hoje" (20, amarelo)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {SinalTextoPrint.inducaoUrgencia},
        ),
      );

      expect(resultado.pontuacao, 20);
      expect(resultado.faixa, FaixaRisco.medio);
    });

    test('amigo pedindo Pix (30, amarelo)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {SinalTextoPrint.pedidoFinanceiro},
        ),
      );

      expect(resultado.pontuacao, 30);
      expect(resultado.faixa, FaixaRisco.medio);
    });

    test('typosquatting com domínio recente (65, vermelho)', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          link: {
            SinalLink.typosquatting,
            SinalLink.dominioRecemCriado,
          },
        ),
      );

      expect(resultado.pontuacao, 65);
      expect(resultado.faixa, FaixaRisco.alto);
    });

    test('mensagem comum, sem sinais (0, verde)', () {
      final resultado = CalculadoraScore.calcular(const SinaisIdentificados());

      expect(resultado.pontuacao, 0);
      expect(resultado.faixa, FaixaRisco.baixo);
    });
  });

  group('Limites das faixas', () {
    test('0 é faixa baixa (verde)', () {
      expect(CalculadoraScore.classificarFaixa(0), FaixaRisco.baixo);
    });

    test('19 é faixa baixa (verde)', () {
      expect(CalculadoraScore.classificarFaixa(19), FaixaRisco.baixo);
    });

    test('20 é faixa média (amarela)', () {
      expect(CalculadoraScore.classificarFaixa(20), FaixaRisco.medio);
    });

    test('59 é faixa média (amarela)', () {
      expect(CalculadoraScore.classificarFaixa(59), FaixaRisco.medio);
    });

    test('60 é faixa alta (vermelha)', () {
      expect(CalculadoraScore.classificarFaixa(60), FaixaRisco.alto);
    });

    test('100 é faixa alta (vermelha)', () {
      expect(CalculadoraScore.classificarFaixa(100), FaixaRisco.alto);
    });
  });

  group('Teto de 100 pontos', () {
    test('todos os sinais juntos resultam em 100', () {
      final resultado = CalculadoraScore.calcular(
        SinaisIdentificados(
          textoPrint: SinalTextoPrint.values.toSet(),
          link: SinalLink.values.toSet(),
        ),
      );

      expect(resultado.pontuacao, 100);
      expect(resultado.faixa, FaixaRisco.alto);
    });
  });

  group('Determinismo', () {
    test('mesma entrada produz sempre a mesma saída', () {
      const sinais = SinaisIdentificados(
        textoPrint: {
          SinalTextoPrint.pedidoFinanceiro,
          SinalTextoPrint.ameaca,
        },
        link: {SinalLink.typosquatting},
        verificacaoIncompleta: true,
      );

      final primeiraExecucao = CalculadoraScore.calcular(sinais);
      final segundaExecucao = CalculadoraScore.calcular(sinais);
      final terceiraExecucao = CalculadoraScore.calcular(sinais);

      for (final resultado in [segundaExecucao, terceiraExecucao]) {
        expect(resultado.pontuacao, primeiraExecucao.pontuacao);
        expect(resultado.faixa, primeiraExecucao.faixa);
        expect(resultado.rotulo, primeiraExecucao.rotulo);
        expect(
          resultado.versaoConfiguracao,
          primeiraExecucao.versaoConfiguracao,
        );
        expect(
          resultado.verificacaoIncompleta,
          primeiraExecucao.verificacaoIncompleta,
        );
      }
    });
  });

  group('Regra de verificação incompleta', () {
    test('verde vira amarelo com a pontuação mantida em 0', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(verificacaoIncompleta: true),
      );

      expect(resultado.pontuacao, 0);
      expect(resultado.faixa, FaixaRisco.medio);
      expect(resultado.verificacaoIncompleta, isTrue);
    });

    test('verde vira amarelo mesmo com pontuação parcial na faixa baixa', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          link: {SinalLink.dominioRecemCriado},
          verificacaoIncompleta: true,
        ),
      );

      expect(resultado.pontuacao, 25);
      expect(resultado.faixa, FaixaRisco.medio);
    });

    test('amarelo não muda de faixa', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {SinalTextoPrint.pedidoFinanceiro},
          verificacaoIncompleta: true,
        ),
      );

      expect(resultado.pontuacao, 30);
      expect(resultado.faixa, FaixaRisco.medio);
    });

    test('vermelho não muda de faixa', () {
      final resultado = CalculadoraScore.calcular(
        const SinaisIdentificados(
          textoPrint: {
            SinalTextoPrint.pedidoFinanceiro,
            SinalTextoPrint.alegacaoTrocaContato,
          },
          verificacaoIncompleta: true,
        ),
      );

      expect(resultado.pontuacao, 60);
      expect(resultado.faixa, FaixaRisco.alto);
    });
  });

  group('Rotulagem obrigatória (RF07)', () {
    test('rótulo "Seguro" não aparece em nenhuma saída', () {
      final resultados = [
        CalculadoraScore.calcular(const SinaisIdentificados()),
        CalculadoraScore.calcular(
          const SinaisIdentificados(
            textoPrint: {SinalTextoPrint.pedidoFinanceiro},
          ),
        ),
        CalculadoraScore.calcular(
          const SinaisIdentificados(
            textoPrint: {
              SinalTextoPrint.pedidoFinanceiro,
              SinalTextoPrint.alegacaoTrocaContato,
            },
          ),
        ),
        CalculadoraScore.calcular(
          const SinaisIdentificados(verificacaoIncompleta: true),
        ),
      ];

      for (final resultado in resultados) {
        expect(resultado.rotulo.toLowerCase(), isNot(contains('seguro')));
      }

      expect(RotulosRisco.baixoRisco.toLowerCase(), isNot(contains('seguro')));
      expect(RotulosRisco.medioRisco.toLowerCase(), isNot(contains('seguro')));
      expect(RotulosRisco.altoRisco.toLowerCase(), isNot(contains('seguro')));
    });

    test('rótulos correspondem exatamente aos definidos no RF07', () {
      expect(
        CalculadoraScore.calcular(const SinaisIdentificados()).rotulo,
        'Não encontramos sinais de golpe',
      );
      expect(
        CalculadoraScore.calcular(
          const SinaisIdentificados(
            textoPrint: {SinalTextoPrint.pedidoFinanceiro},
          ),
        ).rotulo,
        'Atenção: sinais suspeitos',
      );
      expect(
        CalculadoraScore.calcular(
          const SinaisIdentificados(
            textoPrint: {
              SinalTextoPrint.pedidoFinanceiro,
              SinalTextoPrint.alegacaoTrocaContato,
            },
          ),
        ).rotulo,
        'Alto risco de golpe',
      );
    });
  });

  group('Configuração centralizada (docs/score-calibracao.md)', () {
    test('versão da calibragem é 1.0', () {
      expect(ScoreConfig.versao, '1.0');
      expect(
        CalculadoraScore.calcular(const SinaisIdentificados()).versaoConfiguracao,
        '1.0',
      );
    });

    test('limite de domínio recém-criado é 30 dias', () {
      expect(ScoreConfig.dominioRecenteLimiteDias, 30);
    });
  });
}

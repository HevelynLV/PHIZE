# Calibração do Score de Risco (RF07)

Este documento é a **fonte única** dos valores numéricos do motor de Score de Risco: pesos dos sinais, pontos de corte das faixas e cenários de validação. Nenhum outro documento do projeto deve reproduzir estes números — `docs/requisitos.md`, `docs/arquitetura.md`, `docs/relatorio-completo.md` e `CLAUDE.md` referenciam este arquivo em vez de repeti-los.

## Versão 1.0 (proposta, 2026-09-22)

Pendente de validação pela equipe. Ver seção "Registro de calibragens" ao final.

## Princípio de calibragem

Nenhum sinal isolado pesa menos de 20 pontos, e a faixa verde vai de 0 a 19. Isso garante que a faixa verde só é atingida na ausência de qualquer sinal identificado, de modo que o rótulo obrigatório "Não encontramos sinais de golpe" nunca seja emitido diante de um sinal real — ainda que único.

## Faixas

| Faixa | Cor | Pontuação | Rótulo obrigatório (RF07) |
| --- | --- | --- | --- |
| Baixo risco | Verde | 0–19 | "Não encontramos sinais de golpe" |
| Risco médio | Amarelo | 20–59 | "Atenção: sinais suspeitos" |
| Alto risco | Vermelho | 60–100 | "Alto risco de golpe" |

## Pesos — Grupo TEXTO/PRINT (8 sinais do RF07)

| Sinal | Peso |
| --- | --- |
| Correspondência com padrão catalogado na base de conhecimento | 40 |
| Pedido financeiro | 30 |
| Alegação de troca de contato | 30 |
| Solicitação de dados pessoais | 30 |
| Ameaça | 25 |
| Link suspeito | 25 |
| Oferta incompatível com o mercado | 25 |
| Indução de urgência | 20 |

## Pesos — Grupo LINK (UC03)

| Sinal | Peso |
| --- | --- |
| Domínio listado no Google Safe Browsing | 70 |
| Typosquatting | 40 |
| Domínio recém-criado | 25 |

**Domínio recém-criado:** registro há menos de 30 dias, conforme consulta RDAP.

## Regra de verificação incompleta

Se alguma fonte de verificação falhar (indisponibilidade, timeout etc.) e a faixa resultante dos sinais disponíveis for verde, a faixa exibida é elevada para amarelo. A pontuação numérica real apurada com os sinais disponíveis é mantida — não é artificialmente inflada — e o usuário é informado explicitamente de qual verificação específica não pôde ser concluída. A regra existe para que a ausência de sinais detectados nunca seja confundida com a confirmação de ausência de risco quando a verificação está incompleta.

## Regra de soma

- Soma simples dos pesos dos sinais identificados, com teto de 100 pontos.
- Cada sinal conta uma única vez por análise, independentemente de quantas vezes seu padrão apareça no conteúdo.
- Sinais dos grupos TEXTO/PRINT e LINK podem se somar na mesma análise (ex.: um print que contém um link malicioso).

## Cenários de validação

| Cenário | Score | Faixa |
| --- | --- | --- |
| Falso parente pedindo dinheiro | 60 | Vermelho |
| Falso parente com indução de urgência | 80 | Vermelho |
| Falsa central bancária | 75 | Vermelho |
| Loja real com "só hoje" | 20 | Amarelo |
| Amigo pedindo Pix | 30 | Amarelo |
| Typosquatting com domínio recente | 65 | Vermelho |
| Mensagem comum, sem sinais | 0 | Verde |

## Registro de calibragens

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-09-22 | Equipe Phize | Proposta inicial de pesos, faixas e regra de verificação incompleta. Pendente de validação pela equipe. |

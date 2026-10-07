# Volume Mínimo de Texto do OCR (UC04)

Este documento é a **fonte única** do volume mínimo de texto extraído por OCR exigido para que a análise de print prossiga. Nenhum outro documento do projeto deve reproduzir estes números — `docs/requisitos.md` (RF04), `docs/casos-de-uso.md` (UC04, etapa 5) e o código referenciam este arquivo em vez de repeti-los.

## Versão 1.0 (2026-10-07)

Pendente de validação pela equipe. Ver seção "Registro de calibragens" ao final.

## Limite

O texto só segue no fluxo se atender às **duas condições, cumulativamente**:

| Condição | Mínimo |
| --- | --- |
| Caracteres | 20 |
| Palavras | 4 |

Atender a apenas uma das condições não basta: o texto é considerado insuficiente.

## Justificativa

O limite existe para barrar ruído de OCR — imagem borrada, print sem texto, apenas ícones — antes de qualquer transmissão à nuvem (UC04, etapa 5).

O erro tem custo nos dois sentidos:

- **Errar para cima** rejeita golpe real.
- **Errar para baixo** envia ruído ao modelo, que não encontra sinais e devolve faixa verde. Falsa tranquilidade é pior que ausência de resposta.

## Tabela de aferição

| Entrada | Caracteres | Palavras | Resultado |
| --- | --- | --- | --- |
| "Oi mãe, troquei de número" | 25 | 5 | Passa |
| "Pix de R$ 500 por favor" | 23 | 6 | Passa |
| "Seu CPF foi bloqueado" | 21 | 4 | Passa |
| Ruído de OCR típico | — | — | Não passa |

O falso parente é o caso mais apertado e define o teto do limite.

## Verificação antes e depois do mascaramento

A verificação é aplicada **duas vezes**: antes e depois do mascaramento local (RNF07).

Um print contendo apenas um dado estruturado vira "[CPF]" após o mascaramento e não tem conteúdo a analisar. Nesse caso o fluxo é interrompido com mensagem própria, em vez de seguir e produzir verde.

## Registro de calibragens

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-10-07 | Equipe Phize | Proposta inicial: mínimo de 20 caracteres e 4 palavras, cumulativos, verificado antes e depois do mascaramento. Pendente de validação pela equipe. |

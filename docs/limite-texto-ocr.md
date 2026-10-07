# Volume Mínimo de Texto do OCR (UC04)

Este documento é a **fonte única** do volume mínimo de texto extraído por OCR exigido para que a análise de print prossiga. Nenhum outro documento do projeto deve reproduzir estes números — `docs/requisitos.md` (RF04), `docs/casos-de-uso.md` (UC04, etapa 5) e o código referenciam este arquivo em vez de repeti-los.

## Versão 1.1 (2026-10-07)

Pendente de validação pela equipe. Ver seção "Registro de calibragens" ao final.

## Limite — primeira verificação (texto bruto do OCR)

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

## Limite — segunda verificação (texto mascarado)

Depois do mascaramento local (RNF07), o texto passa por uma segunda verificação, que conta **apenas o texto fora dos marcadores de mascaramento** (`[CPF]`, `[CNPJ]`, `[TELEFONE]`, `[EMAIL]`, `[CHAVE_PIX]`, `[CARTAO]`, `[BOLETO]`). As duas condições também são **cumulativas**:

| Condição | Mínimo |
| --- | --- |
| Caracteres fora dos marcadores | 10 |
| Palavras fora dos marcadores | 2 |

A contagem segue a mesma regra da primeira verificação, aplicada ao texto que sobra depois de retirados os marcadores.

| Texto mascarado | Fora dos marcadores | Resultado |
| --- | --- | --- |
| "Pix para [CHAVE_PIX] agora" | "Pix para agora" | Passa |
| "[TELEFONE] [EMAIL] [CPF] [CNPJ]" | (vazio) | Não passa |
| "[CARTAO] 12/29" | "12/29" | Não passa |

### Justificativa das duas verificações

As duas verificações têm finalidades diferentes, por isso têm critérios próprios:

- A **primeira** barra ruído de OCR sobre o texto bruto, antes de qualquer outra etapa.
- A **segunda** garante que restou conteúdo analisável depois do mascaramento. Um print contendo apenas dados estruturados não tem o que ser analisado: depois do mascaramento, sobram só marcadores. Contá-los como texto deixaria esse print seguir para o modelo, que não encontraria sinais e devolveria faixa verde.

Falha em qualquer uma das duas interrompe o fluxo sem transmissão à nuvem. Na segunda, a interrupção usa mensagem própria.

## Registro de calibragens

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-10-07 | Equipe Phize | Proposta inicial: mínimo de 20 caracteres e 4 palavras, cumulativos, verificado antes e depois do mascaramento. Pendente de validação pela equipe. |
| 1.1 | 2026-10-07 | Equipe Phize | Segunda verificação com critério próprio: conta apenas o texto fora dos marcadores de mascaramento, com mínimo de 10 caracteres e 2 palavras, cumulativos. A primeira verificação não muda. Pendente de validação pela equipe. |

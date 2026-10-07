# Categorias de Ameaça (UC04)

Este documento é a **fonte** das categorias de ameaça atribuídas à análise de print. A categoria é escolhida pelo modelo de linguagem dentro desta lista fechada e gravada no histórico junto com score, explicação pedagógica, tipo de entrada e data (RNF07, etapa 4; arquitetura, seção 5.4).

O código espelha esta lista em dois pontos, que devem mudar junto com ela:

- `functions/src/analiseTexto.ts` (`CATEGORIAS_PERMITIDAS`), que restringe a resposta do modelo;
- `lib/features/analise/domain/categoria_ameaca.dart` (`CategoriaAmeaca`), que valida a resposta no app.

## Versão 1.0 (2026-10-07)

**Provisória, pendente de validação pela equipe.** Os documentos do projeto não definiam as categorias; esta lista foi proposta para destravar o Prompt 6.2. Ver seção "Registro de versões" ao final.

## Por que lista fechada

- **Privacidade:** a categoria é persistida. Um rótulo escolhido de uma lista conhecida garante que nada além dele chegue ao histórico. Uma categoria em texto livre, escrita pelo modelo, poderia repetir nomes ou outros dados da conversa.
- **Validação:** resposta com categoria fora da lista é tratada como resposta inválida e descartada inteira (UC04).
- **Histórico consultável:** categorias fixas permitem agrupar e filtrar análises (UC06).

## Categorias

| Código | Nome | Quando se aplica | Justificativa |
| --- | --- | --- | --- |
| `falso_contato` | Falso contato | Alguém se passa por parente, amigo ou conhecido, em geral alegando troca de número, para pedir dinheiro ou favor. | Modalidade citada nos documentos como o falso parente que alega troca de número (relatório, seção 2; viabilidade, seção 1). Corresponde aos sinais "alegação de troca de contato" e "pedido financeiro" do RF07. |
| `falsa_central_ou_instituicao` | Falsa central ou instituição | A mensagem finge vir de banco, central de segurança, empresa ou órgão público para obter dados, senhas ou transferências. | Modalidade citada nos documentos como a falsa central de segurança bancária. É a abordagem que mais se apoia na autoridade de uma organização legítima. |
| `cobranca_ou_boleto_falso` | Cobrança ou boleto falso | Cobrança indevida, boleto adulterado ou débito inexistente, com pressão para pagamento. | Modalidades citadas nos documentos: o boleto adulterado e o falso boleto de órgão estadual (RNF05). |
| `oferta_ou_premio_falso` | Oferta ou prêmio falso | Promoção, prêmio, investimento, emprego ou venda com condições incompatíveis com o mercado. | Corresponde ao sinal "oferta incompatível com a realidade de mercado" do RF07. Inclui a fraude do falso leilão de veículos, citada no RNF05. |
| `ameaca_ou_extorsao` | Ameaça ou extorsão | Intimidação, chantagem ou ameaça de prejuízo, bloqueio ou exposição caso a vítima não aja. | Corresponde ao sinal "ameaça" do RF07. Tem orientação preventiva própria: não ceder à pressão e procurar a instituição ou a autoridade. |
| `roubo_de_dados` | Roubo de dados | Pedido de dados pessoais, senhas, códigos de verificação ou acesso a link para "confirmar" cadastro, sem outra modalidade predominante. | Corresponde aos sinais "solicitação de dados pessoais" e "link suspeito" do RF07, quando o objetivo principal é capturar dados e não um pagamento imediato. |
| `outro_golpe` | Outro golpe | Há sinais de golpe, mas a abordagem não se encaixa nas categorias acima. | Evita forçar a mensagem em uma categoria errada, o que comprometeria a explicação pedagógica e o histórico. |
| `sem_indicios` | Sem indícios | Nenhum sinal de golpe foi identificado no texto. | Necessária para registrar no histórico as análises sem sinais. Não afirma que a mensagem é segura: o rótulo exibido continua sendo o da faixa (RF07), e o termo "Seguro" segue proibido. |

## Pontos para a validação

- A devolução de Pix indevido, citada nos documentos como modalidade brasileira, não tem categoria própria. Hoje ela cairia em `falsa_central_ou_instituicao` ou `outro_golpe`, conforme a abordagem.
- Uma mensagem pode combinar modalidades (ex.: falsa central com ameaça). O modelo escolhe uma só, a predominante; os sinais identificados continuam sendo listados todos.

## Registro de versões

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-10-07 | Equipe Phize | Proposta inicial das 8 categorias, para o Prompt 6.2. Pendente de validação pela equipe. |

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 1. Resumo do Produto

O Phize é um aplicativo móvel (Android/iOS) de segurança preventiva e educação digital que analisa links e capturas de tela (prints) recebidos por compartilhamento nativo para identificar golpes de engenharia social. O sistema extrai texto via OCR, cruza o conteúdo com uma base de conhecimento curada de fraudes brasileiras (RAG) e retorna um Score de Risco visual acompanhado de explicação pedagógica. O diferencial competitivo não está no uso de LLMs, mas na base de padrões de fraude nacionais e na correção pedagógica no momento exato do risco. O MVP cobre autenticação, análise de link/print e privacidade; a camada comunitária (reporte, feed, moderação) é escopo de expansão pós-MVP.

## 2. Stack Tecnológica

- **Frontend:** Flutter (Dart) — código único para Android e iOS (RNF02).
- **Autenticação:** Firebase Authentication.
- **Banco de Dados:** Cloud Firestore (NoSQL) — histórico de análises e base comunitária.
- **Visão Computacional:** Google Cloud Vision (OCR).
- **IA/PLN:** LLM sob arquitetura RAG, consultando índice vetorial próprio de padrões de fraude.
- **Análise de URL:** Google Safe Browsing API (reputação — licenciada apenas para uso não comercial; qualquer evolução do produto para modelo de receita exige migração prévia para a Web Risk API), RDAP (idade de domínio), detecção de typosquetting por distância de edição.
- As credenciais de APIs de terceiros não são embarcadas no app; chamadas passam por camada intermediária gerenciada pelo servidor.

## 3. Regras Invioláveis de Privacidade

Estas regras derivam de RNF01 e RNF07 e **não podem ser flexibilizadas, contornadas ou reinterpretadas** por conveniência de implementação. Qualquer código que viole uma destas garantias deve ser tratado como defeito crítico.

### RNF01 — Três garantias cumulativas (todas obrigatórias simultaneamente)

1. Imagens submetidas são processadas exclusivamente em memória volátil e descartadas imediatamente após a extração textual — nunca gravadas em disco local ou em servidor.
2. O texto extraído sofre mascaramento local de dados pessoais estruturados antes de qualquer transmissão à nuvem.
3. Nenhum conteúdo de conversa (imagem ou texto) é persistido no banco de dados — o histórico armazena apenas o resultado da análise (Score de Risco, categoria da ameaça, explicação pedagógica e data).

### RNF07 — Quatro etapas obrigatórias do ciclo de vida do dado textual (nesta ordem)

1. **Mascaramento local:** antes da transmissão, o dispositivo aplica regex sobre o texto extraído, substituindo por marcadores genéricos (ex.: `[TELEFONE]`) os dados estruturados: CPF, CNPJ, telefone, e-mail, chave Pix aleatória, número de cartão e código de barras de boleto.
2. **Transmissão:** texto mascarado enviado ao provedor de LLM via TLS 1.2+, exclusivamente por APIs corporativas cujos termos vedem uso do conteúdo para treinamento de modelos.
3. **Descarte na origem:** concluída a resposta, o texto é removido da memória da aplicação — nunca escrito em cache, log ou arquivo temporário.
4. **Persistência seletiva:** grava-se no Cloud Firestore somente score numérico, categoria da ameaça, explicação pedagógica e timestamp. O texto analisado **não é gravado em nenhuma hipótese**.

> Limitação declarada (RNF07): o mascaramento local cobre apenas dados de formato previsível. Nomes próprios e conteúdo livre não são mascarados no dispositivo — mitigado por provedores com retenção zero e não persistência do texto.

## 4. Regra do RF07 — Cálculo do Score de Risco

O Score de Risco (0–100) **nunca é calculado pelo modelo de linguagem**. O LLM é responsável apenas por identificar sinais no conteúdo (pedido financeiro, solicitação de dados pessoais, alegação de troca de contato, indução de urgência, ameaça, link suspeito, oferta incompatível com o mercado, correspondência com a base de conhecimento) e por gerar a explicação pedagógica. A conversão dos sinais em número é feita exclusivamente por **função determinística implementada na aplicação**, com pesos pré-definidos, versionados e centralizados em módulo único de configuração, somados com teto de 100 pontos. A mesma entrada deve sempre produzir o mesmo score (propriedade testável por teste automatizado). Delegar o cálculo ao modelo é proibido porque LLMs não produzem probabilidades calibradas nem reprodutíveis, o que violaria o RNF04 (veda respostas não fundamentadas) e tornaria o veredito não auditável.

## 5. Rotulagem Obrigatória das Faixas de Risco

O veredito segue sempre a escala semafórica de três faixas com rótulos fixos. **O termo "Seguro" (ou qualquer equivalente que afirme ausência absoluta de risco) é proibido em qualquer texto de veredito.**

| Faixa | Cor | Rótulo obrigatório |
| --- | --- | --- |
| Baixo risco | Verde | "Não encontramos sinais de golpe" |
| Risco médio | Amarelo | "Atenção: sinais suspeitos" |
| Alto risco | Vermelho | "Alto risco de golpe" |

Toda tela de resultado deve conter aviso permanente de que a análise é ferramenta de apoio à decisão e não substitui verificação direta junto à instituição envolvida.

## 6. Estrutura de Pastas e Convenções de Código

O projeto ainda não possui código de aplicação. Ao iniciar a implementação, seguir a estrutura abaixo, alinhada aos módulos definidos em `docs/requisitos.md` e às entidades de `docs/uml.md`:

```
lib/
  core/           # configuração, roteamento, tema, constantes
  data/           # integrações externas: Firebase, Cloud Vision (OCR),
                  # LLM/RAG, Safe Browsing, RDAP
  domain/         # modelos de domínio: Usuario, AnaliseRisco, ReporteComunidade
  features/
    auth/         # RF01, RF02 — cadastro e login
    analise/      # RF03, RF04, RF07, RF10 — URL checker, análise de print,
                  # score de risco, compartilhamento nativo
    comunidade/   # RF05, RF06, RF08, RF09, RF11 — reporte, upvote, feed,
                  # busca, compartilhamento externo, moderação
    conta/        # RF12 — exportação e exclusão de dados pessoais
  shared/         # widgets e utilitários reutilizáveis entre features
```

Convenções:

- Linguagem Dart, formatação e nomenclatura padrão Flutter (arquivos em `snake_case`, classes em `UpperCamelCase`).
- A tabela de pesos do Score de Risco (RF07) deve residir em módulo único de configuração, versionado, com registro das calibragens realizadas — nunca duplicada ou hardcoded em múltiplos pontos do código.
- Qualquer rotina que manipule imagem ou texto extraído por OCR deve implementar descarte explícito (inclusive em blocos de tratamento de exceção), em conformidade com a Seção 3 deste documento.

## 7. Precedência dos Documentos

Em caso de conflito entre o código implementado e o conteúdo dos documentos em `/docs` (`requisitos.md`, `arquitetura.md`, `casos-de-uso.md`, `uml.md`, `viabilidade.md`, `stakeholders.md`), **os documentos prevalecem**. Ajustes de código devem ser conformados aos documentos; caso um documento pareça desatualizado, sinalizar ao usuário em vez de implementar em desacordo com ele.

`docs/requisitos.md` é a fonte canônica dos requisitos funcionais (RF) e não funcionais (RNF). `docs/relatorio-completo.md` os reproduz para fins acadêmicos; em caso de divergência entre os dois, `docs/requisitos.md` prevalece.

## 8. Degradação Controlada

A indisponibilidade de uma fonte externa **não interrompe a análise**. O sistema apresenta o resultado com os sinais disponíveis e informa explicitamente ao usuário qual verificação específica não pôde ser concluída. Referência: seção 6 de `docs/arquitetura.md` e fluxos de exceção do UC03 em `docs/casos-de-uso.md`.

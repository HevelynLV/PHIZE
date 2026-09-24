# ROADMAP DE DESENVOLVIMENTO — PROJETO PHIZE

Guia de execução do projeto com Claude Code.
Cada fase contém os prompts a serem usados e os pontos de verificação.

---

## ONDE PARAMOS

- **Data:** 2026-09-24
- **Última tarefa concluída:** Fase 5 — camada intermediária com endpoint de reputação validado
- **Próximo passo:** Fase 5.1 — Conectar o Safe Browsing à tela de resultado

---

## COMO LER ESTE DOCUMENTO

Todo comando ou prompt está marcado com o lugar onde vai:

| Marcação | O que é | Como identificar |
|---|---|---|
| **[TERMINAL]** | Shell do Windows dentro do VS Code | Prompt tipo `PS C:\dev\Phize>`. Abre com `Ctrl+'` |
| **[CLAUDE CODE]** | Sessão da IA | Abre digitando `claude` no terminal. Sai com `/exit` |
| **[WINDOWS]** | Interface gráfica | Menu iniciar, explorador de arquivos, navegador |

Regra prática: **texto em português explicando o que você quer → Claude Code. Comando curto em inglês → terminal.**

---

## REGRAS DE TRABALHO

Estas três valem para o projeto inteiro e importam mais que os prompts em si.

**1. Um commit por prompt.**
Se o resultado sair errado, você reverte com `git checkout .` e refaz o prompt melhor. Sem Git, você tenta consertar conversando com a IA — e isso quase sempre piora.

**2. Peça o teste junto com o código, no mesmo prompt.**
Depois é sempre pior.

**3. Quando o Claude Code contrariar a documentação, a documentação ganha.**
Corrija o `CLAUDE.md` em vez de corrigir o mesmo erro toda sessão.

**4. Sempre leia o que ele gerou antes de aceitar.**
Principalmente em arquivos de configuração e regras de segurança.

---

## AMBIENTE — CONCLUÍDO

- [x] Flutter 3.47.4 instalado em `C:\src\flutter`
- [x] PATH configurado
- [x] VS Code com extensões Flutter e Dart
- [x] Chrome verde no `flutter doctor`
- [x] Projeto criado com `flutter create`
- [ ] Android Studio — **instalar em paralelo, não bloqueia agora**

### Decisão de plataforma

O desenvolvimento começa pelo **Chrome** (`flutter run -d chrome`). O Android só se torna obrigatório a partir da Fase 6.

**Itens que NÃO funcionam na web** e exigirão teste em Android real:
- RF10 / UC11 — compartilhamento nativo
- UC04 — seleção de imagem da galeria

Depois de instalar o Android Studio:

**[TERMINAL]**
```
flutter doctor --android-licenses
```

### Nota sobre o `flutter doctor`

- ✗ em **Visual Studio** → ignorar. É só para app desktop Windows, fora do escopo.
- ✗ em **Xcode** → ignorar. iOS só compila em Mac.

---

## FASE 0 — CONTEXTO

Objetivo: fazer o Claude Code conhecer o projeto antes de escrever qualquer código.

### Status

- [x] Documentos convertidos para `.md` em `docs/`
- [x] `CLAUDE.md` gerado e revisado
- [x] `docs/BACKLOG.md` gerado
- [x] Git inicializado

### Prompt 0.1 — CLAUDE.md (feito)

**[CLAUDE CODE]**
```
Leia os documentos do projeto Phize:
@docs/requisitos.md
@docs/arquitetura.md
@docs/casos-de-uso.md
@docs/uml.md
@docs/viabilidade.md
@docs/stakeholders.md

Com base neles, crie um arquivo CLAUDE.md na raiz do projeto contendo:

1. Resumo do produto em até 5 linhas
2. Stack definida: Flutter/Dart, Firebase Authentication, Cloud Firestore
3. As 3 garantias cumulativas de privacidade do RNF01, e as 4 etapas
   do ciclo de vida do dado textual do RNF07 — marcadas como regras
   invioláveis
4. A regra do RF07: o Score de Risco NUNCA é calculado pelo modelo
   de linguagem, apenas por função determinística na aplicação
5. A rotulagem obrigatória das 3 faixas, registrando que o termo
   "Seguro" é proibido
6. Estrutura de pastas e convenções de código do projeto
7. Uma instrução final: em caso de conflito entre o código e os
   documentos em /docs, os documentos prevalecem

Não crie nenhum outro arquivo e não escreva código de aplicação ainda.
```

### Prompt 0.1b — Correções do CLAUDE.md

**[CLAUDE CODE]**
```
Edite o CLAUDE.md (não crie arquivo novo) com três acréscimos:

1. Na Seção 2, ao lado da Google Safe Browsing API, registre que ela é
   licenciada apenas para uso não comercial, e que qualquer evolução
   para modelo de receita exige migração prévia para a Web Risk API.

2. Crie uma nova seção "Degradação Controlada", com a regra:
   a indisponibilidade de uma fonte externa NÃO interrompe a análise.
   O sistema apresenta o resultado com os sinais disponíveis e informa
   ao usuário qual verificação específica não pôde ser concluída.
   Referência: seção 6 da arquitetura e fluxos de exceção do UC03.

3. Na Seção 7, registre que docs/requisitos.md é a fonte canônica dos
   RF e RNF. O docs/relatorio-completo.md os reproduz para fins
   acadêmicos e, em caso de divergência entre os dois, requisitos.md
   prevalece.

Não altere nenhuma outra parte do arquivo.
```

Corrigir manualmente: o typo `typosquetting` → `typosquatting` na Seção 2.

### Prompt 0.2 — Backlog

**[CLAUDE CODE]**
```
Leia @docs/requisitos.md e @docs/casos-de-uso.md.

Crie o arquivo docs/BACKLOG.md com as tarefas técnicas derivadas
dos RF01-RF12 e RNF01-RNF07.

Formato: uma tabela com as colunas
ID | Tarefa | Requisito de origem | MVP ou Expansão | Depende de

Regras:
- toda tarefa cita o RF/RNF de origem
- a coluna "Depende de" usa os IDs das outras tarefas desta mesma
  tabela; tarefa sem dependência fica em branco
- classifique como MVP ou Expansão conforme a seção 2 de requisitos.md,
  não pelo seu próprio julgamento
- ao final, liste separadamente as decisões que ainda NÃO estão
  definidas nos documentos e que bloqueiam implementação

Não escreva código.
```

**A lista de lacunas ao final do arquivo é a parte mais importante.** Ela vira a pauta da próxima reunião da equipe.

### Git

**[TERMINAL]**
```
git init
```
```
git add .
```
```
git commit -m "chore: setup inicial, documentacao e CLAUDE.md"
```

---

## DECISÕES PENDENTES DA EQUIPE

Nenhuma delas está nos documentos. São decisões humanas — se ninguém definir, o Claude Code inventa um número plausível no meio do código.

| Decisão | Bloqueia | Origem |
|---|---|---|
| ~~Tabela de pesos dos 8 sinais~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Pontos de corte entre as 3 faixas de cor~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Limite de domínio recém-criado~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Regra de verificação incompleta~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| Volume mínimo de texto do OCR | Fase 6 | UC04 |
| Limiar de denúncias para ocultar reporte | Fase 9 | RF11 |
| ~~Estrutura de pastas: por camada ou por feature~~ — **decidido: por feature** | ~~Fase 1~~ Resolvida | CLAUDE.md §6, commit `f17bb5c` |
| Bloquear acesso de usuário com e-mail não verificado? | Fase 1 (pode ser revista depois) | RF01 / UC01 |
| Tempo de expiração do bloqueio de login (provisório: 15 min) | Revisão | RF02 |
| Bloquear usuário com e-mail não verificado (padrão atual: não) | Revisão | RF01/UC01 |
| Validação da tabela v1.0 (docs/score-calibracao.md) pela equipe | Não bloqueante | RF07 |
| Ativar o plano Blaze para deploy das Cloud Functions | Publicação e testes em dispositivo real | Fase 5 |

> Padrão adotado: **não bloquear**, seguindo o UC01.

---

## PENDÊNCIAS TÉCNICAS

- `firestore.rules` não cobre subcoleções de `users/{uid}`; o histórico (Fases 4 e 8) exigirá regra nova.
- Restringir os campos graváveis em `users/{uid}` aos três previstos (melhoria de segurança).
- Adicionar ao roadmap os passos de publicação das regras pelo console e teste no Playground.
- Sincronizar os .docx acadêmicos com as alterações de RF07, arquitetura 3.3 e 6, UC03 e relatório 4.8.
- A rotina de mascaramento local pode lançar `StateError` (falha na restauração do isolamento de URL/domínio). O fluxo do UC04 (Fase 6) deve tratar essa exceção interrompendo a análise, sem expor o texto ao usuário nem a log.
- O cálculo do domínio registrável reconhece apenas `com`/`gov`/`org`/`net`/`edu` sob `.br`. Sufixos como `app.br`, `adv.br` e `co.uk` fazem a consulta RDAP no próprio sufixo, e a idade do domínio nunca é avaliada para eles. Degrada com segurança (verificação não concluída, nunca verde nem data falsa), mas a mensagem ao usuário é imprecisa. Solução futura: lista completa de sufixos públicos.
- Dois testes de widget anteriores perderam asserções de rótulo e aviso ao eliminar o caminho fictício da tela de Resultado; a cobertura passou para `test/features/analise/presentation/analise_link_flow_test.dart`.
- A tela de Histórico exibe rótulos de faixa sem o aviso permanente; avaliar na Fase 8 (UC06).
- Restam dados fictícios fora do fluxo de análise: lista do Histórico e saudação do Dashboard.
- Migrar do emulador para a Function publicada antes de qualquer teste em Android real ou entrega que não rode na máquina de desenvolvimento.
- Restringir no console as chaves públicas do Firebase às APIs do Firebase, impedindo que sejam usadas para chamar o Safe Browsing direto e contornar a Function.
- O contador de rate limiting é mantido em memória e zera a cada reinício da Function; migrar para armazenamento compartilhado antes do deploy com mais de uma instância.
- O mapa do rate limiting nunca remove usuários antigos.
- Chamadas com URL inválida consomem o limite antes da validação; comportamento deliberado, a documentar.
- ~~A Function nunca foi exercitada contra o Safe Browsing real; validar com a chave configurada.~~ — **resolvida: validada em 2026-09-24, ver Fase 5**
- A Function passou a receber caminho de URL além do domínio; avaliar se o ciclo de vida desse dado merece registro próprio na documentação, já que o RNF07 trata apenas do texto de OCR.

---

## FASE 1 — FUNDAÇÃO

### Prompt 1.1 — Esqueleto de navegação (concluído)

**[CLAUDE CODE]**
```
Crie o esqueleto de navegação do app, substituindo o contador padrão
gerado pelo flutter create.

Telas (apenas layout, sem lógica de negócio):
- Login
- Cadastro
- Dashboard
- Histórico
- Resultado da Análise

Requisitos:
- siga a estrutura de pastas definida no CLAUDE.md
- use dados fictícios embutidos nas telas; sem Firebase, sem API
- na tela de Resultado, já aplique a rotulagem obrigatória das
  três faixas e o aviso permanente do RF07
- navegação funcional entre as telas

Não implemente autenticação ainda.
```

**Verificação [TERMINAL]:**
```
flutter run -d chrome
```
Navegue por todas as telas. Depois commit.

### Firebase — configuração manual

**[WINDOWS]** No console do Firebase:
1. Criar projeto
2. Ativar Authentication → provedor E-mail/senha
3. Criar o Firestore

> **ATENÇÃO:** ao criar o Firestore, escolha **modo produção**, não modo teste.
> Modo teste deixa o banco aberto para qualquer pessoa ler e escrever por 30 dias.
> Para um app cujo diferencial declarado é privacidade, é um começo ruim.

### Pré-requisitos (não constavam na versão original)

**[WINDOWS]** Instalar o Node.js LTS (nodejs.org), sem marcar "Tools for Native Modules". Reiniciar o VS Code.

**[TERMINAL]** Se o npm for bloqueado por política de execução:
```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**[TERMINAL]**
```
npm install -g firebase-tools
```
```
firebase login
```

**[WINDOWS]** Adicionar ao PATH do usuário a pasta `C:\Users\<usuario>\AppData\Local\Pub\Cache\bin`, fechar TODAS as janelas do VS Code e reabrir. Verificar com:
```
flutterfire --version
```

**[TERMINAL]**
```
dart pub global activate flutterfire_cli
```
```
flutterfire configure
```

No `flutterfire configure`, marcar apenas **android** e **web**.

> **Nota:** a `apiKey` presente em `lib/firebase_options.dart` é um identificador público do projeto Firebase, não um segredo; a proteção do banco é feita pelas `firestore.rules`. A regra de não embarcar chaves (seção 2 da arquitetura) se aplica às APIs pagas, que passarão pela Cloud Function na Fase 5.

### Prompt 1.2 — Autenticação (concluído)

**[CLAUDE CODE]**
```
Leia o @CLAUDE.md e implemente UC01 (cadastro) e UC02 (login)
conforme @docs/casos-de-uso.md, usando Firebase Authentication.

1. Dependências e inicialização
- adicione firebase_core, firebase_auth e cloud_firestore
- inicialize o Firebase no main.dart usando o
  lib/firebase_options.dart já gerado pelo flutterfire configure

2. Cadastro (UC01 / RF01)
- apenas e-mail e senha; NÃO implemente login social
  (Google/Apple) neste passo
- validação local de senha com mínimo de 8 caracteres
- envio de e-mail de verificação após o cadastro, sem bloquear
  o acesso (o UC01 redireciona direto ao Dashboard)
- criação do documento do usuário em users/{uid} no Firestore,
  contendo SOMENTE uid, e-mail e data de criação (princípio de
  minimização do RNF01)

3. Login (UC02 / RF02)
- opção "Esqueci minha senha" com envio de e-mail de redefinição
- mensagens de erro genéricas que NUNCA revelem se um e-mail
  existe na base: use "E-mail ou senha incorretos" para
  credenciais inválidas, e resposta idêntica na redefinição de
  senha, exista ou não a conta

4. Bloqueio após 5 tentativas (RF02)
- a proteção real contra força bruta é a do próprio Firebase
  Auth: trate o erro too-many-requests com mensagem clara
- mantenha um contador local de tentativas persistido no
  dispositivo, que sobreviva ao reinício do app, apenas como
  camada de interface
- registre essa decisão no CLAUDE.md, explicando que o contador
  local não é a barreira de segurança

5. Fluxos de exceção do UC01 e UC02
e-mail já cadastrado, senha fora do padrão, credenciais
inválidas, falha de conexão

6. Regras do Firestore
crie firestore.rules negando tudo por padrão e liberando apenas
leitura e escrita em users/{uid} quando request.auth.uid == uid.
Não publique as regras; eu faço isso manualmente.

7. Testes unitários
- validador de senha, incluindo casos-limite (7 e 8 caracteres,
  vazia)
- conversão dos códigos de erro do Firebase em mensagens,
  provando que nenhuma mensagem revela a existência do e-mail
- contador de tentativas (incremento, bloqueio na 5ª, reset
  após login bem-sucedido)

Restrições:
- nunca registre senha ou e-mail em log ou print
- conecte às telas de Login e Cadastro já existentes, seguindo
  a estrutura por feature do CLAUDE.md
- ao final, liste os arquivos criados e alterados
```

**O que revisar no resultado:**

1. **Bloqueio após 5 tentativas** — se foi implementado só com uma variável na tela, não serve: some quando o app reinicia. Pergunte onde o contador persiste.
2. **Mensagens de erro** — não podem revelar se o e-mail existe na base. "E-mail ou senha incorretos" é o certo; "senha incorreta" entrega ao atacante que aquela conta existe.
3. **`firestore.rules`** — precisa ser publicado no console, não basta existir no repositório. Teste tentando ler documento de outro usuário.

### Prompt de auditoria (usar após cada prompt de implementação)

Prompt somente leitura — não pede alterações de código, só compara o que foi pedido com o que existe no repositório.

**[CLAUDE CODE]**
```
Não altere nenhum arquivo. Isto é uma auditoria somente leitura.

Releia o prompt de implementação [colar o prompt do passo concluído]
e compare item por item com o código atual do repositório.

Para cada item do prompt, verifique no código se foi de fato
implementado, parcialmente implementado ou não implementado, e
cite o arquivo e trecho que comprova a conclusão (ou a ausência
dela).

Retorne uma tabela:
Item | Status | Evidência

Ao final, liste separadamente qualquer desvio em relação ao
CLAUDE.md ou aos documentos em /docs.
```

A auditoria não pode se limitar a conferir se a suíte de testes passa: deve incluir a execução mental de textos reais de exemplo, cobrindo casos que os testes existentes talvez não previram. Foi esse método — e não a suíte de testes, que passava integralmente — que revelou, na Fase 3, três problemas na rotina de mascaramento local: vazamento de número de cartão sem separadores, corrupção de domínio por dígito colado ao hostname, e colisão do marcador temporário de isolamento de URL.

### Prompt de auditoria de tela (usar após prompts que montam tela)

Complementa o prompt de auditoria acima quando o passo conecta lógica a uma tela. Também somente leitura. Foi a execução do fluxo sobre entradas reais — e não a suíte de testes — que revelou, na Fase 4, a data de registro de outro domínio atribuída ao endereço analisado (redirecionamento do Registro.br).

**[CLAUDE CODE]**
```
Auditoria SOMENTE DE LEITURA. Não altere nada.

1. Percorra o código e informe, para cada entrada de exemplo,
   score, faixa (com o rótulo exibido), sinais e avisos:
   [listar as entradas: caso legítimo, caso de golpe, caso que
   soma sinais, entrada inválida, fonte externa fora do ar]

2. Tabela (Item | Status | Evidência com arquivo e trecho):
   - "Seguro" (ou equivalente) não aparece em nenhuma saída
   - o aviso permanente aparece em todos os resultados
   - nada do conteúdo analisado é persistido nem escrito em log,
     inclusive em mensagens de erro e de verificação não concluída
   - nada é gravado no Firestore fora do previsto no passo
   - nenhum teste acessa a rede
   - nenhum teste anterior foi removido ou enfraquecido
   - nenhum dado fictício permaneceu como fallback

Conclua em uma frase: fase completa, parcial ou incompleta.
```

---

## FASE 2 — MOTOR DE SCORE

Lógica pura em Dart. Sem custo, sem API, 100% testável.

### Prompt 2.1 — usa os valores de docs/score-calibracao.md

---

## FASE 3 — MASCARAMENTO LOCAL (RNF07) — concluída

Também lógica pura. Pré-requisito legal de qualquer envio à nuvem.

**[CLAUDE CODE]**
```
Implemente a rotina de mascaramento local do RNF07.

Expressões regulares para: CPF, CNPJ, telefone, e-mail,
chave Pix aleatória, número de cartão e linha digitável de boleto.
Substituir por marcadores genéricos ([TELEFONE], [CPF], etc).

Escreva testes com exemplos reais de cada formato,
incluindo casos-limite (CPF com e sem pontuação,
telefone com e sem DDI).

A rotina não pode alterar verbos de urgência, valores
monetários ou domínios — teste isso também.
```

---

## FASE 4 — TRILHA DO LINK (UC03) — concluída

Primeiro fluxo ponta a ponta. RDAP e análise de anatomia são gratuitos.

### Prompt 4.1 — Typosquatting (concluído)

**[CLAUDE CODE]**
```
Implemente a análise de anatomia de URL (typosquatting):
normalização do endereço, isolamento de domínio, e comparação
por distância de edição contra uma lista curada de marcas
brasileiras frequentemente imitadas.

Comece a lista com os 20 principais bancos e serviços do Brasil.
Testes obrigatórios.
```

### Prompt 4.2 — RDAP (concluído)

**[CLAUDE CODE]**
```
Implemente a consulta de idade de registro do domínio via RDAP.

Trate: domínio inexistente, RDAP indisponível, timeout.

Em caso de falha, o sistema deve seguir com os demais sinais
e informar ao usuário qual verificação não foi concluída
(degradação controlada, seção 6 da arquitetura).
```

### Prompt 4.3 — Tela de resultado (concluído)

**[CLAUDE CODE]**
```
Monte a tela de resultado do UC03 conectando:
anatomia + RDAP + motor de score da Fase 2.

Exiba o termômetro semafórico, a lista de sinais verificados
com atribuição de fonte, e o aviso permanente de que
a análise não substitui verificação junto à instituição.

Ainda sem Safe Browsing e sem LLM.
```

Sem Safe Browsing (Fase 5), a verificação de link fica incompleta e, pela regra do score v1.0, nunca resulta em verde. Comportamento esperado, não é bug.

**Marco:** aqui o app já é demonstrável, sem ter gasto um centavo.

---

## FASE 5 — CAMADA INTERMEDIÁRIA — concluída

> **DECISÃO (2026-09-23):** a Cloud Function é desenvolvida e testada com o emulador local do Firebase, sem deploy. O plano Blaze é obrigatório para publicar Functions e exige cartão cadastrado, ainda que a cota gratuita cubra o uso previsto. A decisão de ativar o Blaze fica com a equipe e não bloqueia o desenvolvimento: o código da Function é o mesmo, muda apenas o endereço que o app chama.
>
> Consequências enquanto o emulador for usado:
> - a Function só responde com o emulador rodando na máquina de quem desenvolve
> - a demonstração precisa do emulador ativo junto com o app
> - testes em Android real ou por outros integrantes exigem o deploy
> - a chave do Safe Browsing é gratuita e **NÃO** depende do Blaze

> **ESCOPO DIVIDIDO:** nesta fase foi implementado o endpoint de reputação (Safe Browsing), que recebe a URL normalizada; o nome `reputacaoDominio` foi mantido por decisão. Os endpoints de OCR e de LLM são acrescentados à mesma Function nas Fases 6 e 7, quando houver consumidor real para eles.

> **VALIDAÇÃO (2026-09-24):** a consulta foi validada contra o Safe Browsing real, pela Function no emulador, com usuário autenticado no Auth emulado (`docs/emulador-local.md`). Os endereços oficiais de teste do Google retornaram listado, e um domínio legítimo retornou não listado.

> **DECISÃO — escopo da consulta de reputação:** a Function recebe a URL normalizada com domínio e caminho; a query string e o fragmento são descartados no dispositivo, antes da transmissão (arquitetura, seção 4, etapa 2). Motivo: os endereços de teste só aparecem como listados com o caminho completo, o que confirma que enviar apenas o domínio deixaria passar golpes hospedados em caminho de site legítimo. RDAP e typosquatting continuam usando só o domínio.

Obrigatória antes de qualquer API paga.

**[CLAUDE CODE]**
```
Implemente uma Cloud Function que funcione como proxy
para as APIs externas (Safe Browsing, Vision, LLM).

Requisito de segurança: nenhuma chave de API pode estar
no pacote do aplicativo (seção 2 da arquitetura).

O app autentica na Function via token do Firebase Auth.
Inclua rate limiting por usuário.
```

---

## FASE 5.1 — CONECTAR O SAFE BROWSING À TELA DE RESULTADO

Substituir o marcador provisório da Fase 4 em `analisador_link.dart` pela consulta real, passando o sinal ao motor de score conforme `docs/score-calibracao.md`, e remover a condição de verificação sempre incompleta para a reputação.

---

## FASE 6 — TRILHA DO PRINT (UC04)

**A partir daqui o Android é obrigatório.**

### Prompt 6.1 — Captura e descarte

**[CLAUDE CODE]**
```
Implemente a seleção de imagem da galeria com Zero-Persistence:
carregamento em memória volátil, remoção do arquivo temporário
gerado pelo seletor de mídia, e descarte garantido por bloco
finally executado inclusive em caso de falha.

Escreva o teste que prova o descarte no caminho de exceção.
```

### Prompt 6.2 — OCR e pipeline

**[CLAUDE CODE]**
```
Conecte o fluxo do UC04: imagem → OCR via proxy → descarte
da imagem → verificação de suficiência do texto → mascaramento
local (Fase 3) → envio ao LLM → score (Fase 2) → descarte do texto.

Trate todas as exceções listadas no UC04.
```

---

## FASE 7 — BASE DE CONHECIMENTO E RAG

A catalogação é **trabalho manual humano** (RDEV04). A IA ajuda a estruturar e indexar, não a curar.

### Prompt 7.1 — Índice vetorial

**[CLAUDE CODE]**
```
Crie o schema padronizado dos documentos da base de conhecimento
conforme a seção 3.2(a) da arquitetura, mais um script que lê os
arquivos catalogados manualmente, gera embeddings e persiste o
índice vetorial em arquivo local versionado no repositório.
```

### Prompt 7.2 — Recuperação e prompt do LLM

**[CLAUDE CODE]**
```
Implemente a recuperação RAG e o prompt do LLM.

O modelo deve: identificar os 8 sinais do RF07, fundamentar
o veredito nos padrões recuperados, declarar ausência de
correspondência quando não houver similaridade suficiente,
e retornar JSON estruturado.

O modelo NÃO retorna score numérico.

Valide o JSON; resposta fora do formato é descartada
sem exibição parcial ao usuário.
```

---

## FASE 8 — FECHAMENTO DO MVP

**[CLAUDE CODE]**
```
Implemente UC06 (histórico com persistência seletiva),
UC12 (exportação e exclusão de dados — RF12) e
UC11/RF10 (recebimento por compartilhamento nativo).
```

---

## FASE 9 — EXPANSÃO (PÓS-MVP)

Comunidade (UC05, UC07–UC10) e moderação (RF11).
Só depois do MVP validado, como o documento de Requisitos posiciona.

---

## COMANDOS DE REFERÊNCIA

Todos em **[TERMINAL]**:

| Comando | O que faz |
|---|---|
| `flutter run -d chrome` | Roda o app no Chrome (`q` para sair) |
| `flutter doctor` | Verifica o ambiente |
| `flutter test` | Roda os testes |
| `claude` | Abre a sessão da IA (`/exit` para sair) |
| `git status` | Mostra o que mudou |
| `git add .` | Prepara tudo para o commit |
| `git commit -m "mensagem"` | Salva o ponto de retorno |
| `git checkout .` | Desfaz tudo que não foi commitado |

# ROADMAP DE DESENVOLVIMENTO — PROJETO PHIZE

Guia de execução do projeto com Claude Code.
Cada fase contém os prompts a serem usados e os pontos de verificação.

---

## ONDE PARAMOS

- **Data:** 2026-09-18
- **Última tarefa concluída:** Prompt 1.1 — Esqueleto de navegação entre telas (commit `1c1afaf`)
- **Próximo passo:** Configuração manual do Firebase (Authentication + Firestore) e, em seguida, Prompt 1.2 — Autenticação

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
| Tabela de pesos dos 8 sinais | Fase 2 | RF07 |
| Pontos de corte entre as 3 faixas de cor | Fase 2 | RF07 |
| Volume mínimo de texto do OCR | Fase 6 | UC04 |
| Limiar de denúncias para ocultar reporte | Fase 9 | RF11 |
| ~~Estrutura de pastas: por camada ou por feature~~ — **decidido: por feature** | ~~Fase 1~~ Resolvida | CLAUDE.md §6, commit `f17bb5c` |

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

**[TERMINAL]**
```
dart pub global activate flutterfire_cli
```
```
flutterfire configure
```

### Prompt 1.2 — Autenticação

**[CLAUDE CODE]**
```
Implemente UC01 (cadastro) e UC02 (login) conforme
@docs/casos-de-uso.md, usando Firebase Authentication.

Inclua:
- validação local de força de senha, mínimo 8 caracteres (RF01)
- envio de e-mail de verificação
- criação do documento do usuário no Cloud Firestore após o cadastro
- bloqueio temporário após 5 tentativas falhas consecutivas (RF02)
- todos os fluxos de exceção descritos no UC01 e UC02:
  e-mail já cadastrado, senha fora do padrão, credenciais inválidas,
  falha de conexão

Crie também o arquivo firestore.rules com regras restritivas:
cada usuário só acessa os próprios documentos.

Conecte às telas de Login e Cadastro criadas no passo anterior.
```

**O que revisar no resultado:**

1. **Bloqueio após 5 tentativas** — se foi implementado só com uma variável na tela, não serve: some quando o app reinicia. Pergunte onde o contador persiste.
2. **Mensagens de erro** — não podem revelar se o e-mail existe na base. "E-mail ou senha incorretos" é o certo; "senha incorreta" entrega ao atacante que aquela conta existe.
3. **`firestore.rules`** — precisa ser publicado no console, não basta existir no repositório. Teste tentando ler documento de outro usuário.

---

## FASE 2 — MOTOR DE SCORE

Lógica pura em Dart. Sem custo, sem API, 100% testável.
**Pré-requisito: tabela de pesos definida pela equipe.**

**[CLAUDE CODE]**
```
Implemente o módulo de cálculo do Score de Risco (RF07).

Requisitos:
- função determinística pura, sem chamada de API
- tabela de pesos centralizada em UM arquivo de configuração,
  versionada (use os pesos fornecidos abaixo)
- soma com teto de 100 pontos
- classificação em 3 faixas com a rotulagem exata do RF07
- testes unitários provando que entradas idênticas
  geram sempre o mesmo score

Pesos: [colar a tabela definida pela equipe]
```

---

## FASE 3 — MASCARAMENTO LOCAL (RNF07)

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

## FASE 4 — TRILHA DO LINK (UC03)

Primeiro fluxo ponta a ponta. RDAP e análise de anatomia são gratuitos.

### Prompt 4.1 — Typosquatting

**[CLAUDE CODE]**
```
Implemente a análise de anatomia de URL (typosquatting):
normalização do endereço, isolamento de domínio, e comparação
por distância de edição contra uma lista curada de marcas
brasileiras frequentemente imitadas.

Comece a lista com os 20 principais bancos e serviços do Brasil.
Testes obrigatórios.
```

### Prompt 4.2 — RDAP

**[CLAUDE CODE]**
```
Implemente a consulta de idade de registro do domínio via RDAP.

Trate: domínio inexistente, RDAP indisponível, timeout.

Em caso de falha, o sistema deve seguir com os demais sinais
e informar ao usuário qual verificação não foi concluída
(degradação controlada, seção 6 da arquitetura).
```

### Prompt 4.3 — Tela de resultado

**[CLAUDE CODE]**
```
Monte a tela de resultado do UC03 conectando:
anatomia + RDAP + motor de score da Fase 2.

Exiba o termômetro semafórico, a lista de sinais verificados
com atribuição de fonte, e o aviso permanente de que
a análise não substitui verificação junto à instituição.

Ainda sem Safe Browsing e sem LLM.
```

**Marco:** aqui o app já é demonstrável, sem ter gasto um centavo.

---

## FASE 5 — CAMADA INTERMEDIÁRIA

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

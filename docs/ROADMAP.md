# ROADMAP DE DESENVOLVIMENTO — PROJETO PHIZE

Guia de execução do projeto com Claude Code.
Cada fase contém os prompts a serem usados e os pontos de verificação.

---

## ONDE PARAMOS

- **Data:** 2026-11-16
- **Últimas tarefas concluídas (2026-11-16):**
  - Ensaio dos testes com pessoas no emulador e correção dos oito achados de produto (seção "Achados de produto do ensaio", na Fase 9), mais um defeito da tela de resultado achado na conferência.
  - Decisões da equipe: tutorial aprovado; próprio `gov.br` como verificação concluída; sem sessões com participantes e sem logo (seção "Fechamento da Fase 9").
- **Tarefas de 2026-11-12:**
  - Prompts 9.8 a 9.12: tutorial interativo do link e do print (RF13) e Perfil completo (RF14): nome de exibição, troca de senha, reenvio da verificação, tamanho da letra, tema escuro, Aprender e Sobre.
  - Teste de todos os fluxos no emulador e correção dos achados: build de release do Android, aquecimento das Functions (`tool/emuladores/aquecer_functions.sh`), títulos com letra muito grande.
  - Decisão de usar só recursos gratuitos: limitação acadêmica declarada no RNF07 e nos demais documentos; consentimento na versão 2 ("Use só conversas de teste").
  - RAG: etapa 2 (só as mensagens recebidas do print), etapa 3 (situações legítimas testadas e retiradas do prompt, sem ganho confirmado) e etapa 4 (três fichas novas). Com a base: 63 de 63 golpes do conjunto de teste detectados e as 26 legítimas verdes.
- **Testes:** 785 no app, 102 na Function e 83 das regras do Firestore.
- **Correções aplicadas na Fase 6.3:** D1 a D4 (primeira auditoria); D1-a, D3-a e D3-b (segunda auditoria) — falha de rede ao obter o token deixou de ser tratada como falha de autenticação nos clientes de análise de texto e de reputação de domínio; texto da tela de seleção ajustado ao que de fato é enviado
- **Base de conhecimento:** 21 fichas revisadas e indexadas (2026-11-12: entraram `comprovante-pix-falso`, `falso-sequestro` e `falso-consignado-inss`); nenhum rascunho pendente
- **Fase 9 fechada no app (2026-11-16):** texto do "Cálculo do risco" aprovado, limitação do RNF03 declarada, UC03 sem RAG no link, sem login com a Apple, teste em Android real declarado como não feito por enquanto. Ficam para o fim o ícone e as mudanças nos .docx e nas imagens dos diagramas.
- **Fase 10 planejada (2026-11-16):** sete decisões da equipe e etapa 10.0 (requisitos e documentos) feita; RF15, RF16 e RF17 criados.
- **Etapa 10.1 feita (2026-11-16):** modelo de dados e regras da comunidade, com 56 testes das regras (`docs/comunidade-dados.md`).
- **Etapa 10.2 feita (2026-11-16):** reportar golpe (link, relato e print), com código comum movido para `lib/shared/`.
- **Etapa 10.3 feita (2026-11-16):** aba Comunidade, com feed "Em alta" e "Mais recentes", detalhe, curtir e compartilhar; barra inferior com quatro abas.
- **Etapa 10.4 feita (2026-11-16):** denúncia com motivo, ocultação automática com 3 denúncias (gatilho na Function) e tela mínima de moderação.
- **Etapa 10.5 feita (2026-11-17):** pesquisa por palavras ou link, "Meus reportes" (editar e excluir) e a comunidade na exportação e na exclusão de conta.
- **Etapa 10.6 feita (2026-11-17):** cartão "Golpe da semana" no Início, com rodízio semanal entre as 21 fichas revisadas.
- **Etapa 10.7 feita (2026-11-17):** "Aprovar e incluir na base" na moderação vale como curadoria; a entrada da comunidade entra no RAG sem reescrita e sai quando o reporte é excluído, ocultado ou editado.
- **Fase 10 fechada (2026-11-17):** etapas 10.0 a 10.7 feitas; 10.8 (comentários) fora da fase, por decisão da equipe. Orientação padrão das entradas da comunidade aprovada; reporte aprovado e editado pelo autor continua aprovado.
- **Documentação atualizada (2026-11-17):** os seis .docx acadêmicos levados ao texto dos `.md`, em alterações controladas para a equipe revisar e aceitar no Word, e os cinco diagramas UML refeitos em Mermaid (`docs/diagramas/`). Detalhes na seção "Atualização da documentação".
- **Próximo passo:** a equipe revisar e aceitar as alterações dos `_atualizado.docx` (em `docs/DOCS/`); depois o ícone e a nova rodada de design. Projeto só com recursos gratuitos (decisão de 2026-11-12).
- **Pendências sem pressa:** no RAG, a ficha vizinha apontada em `consignado-informal`, a medição geral com 3 repetições e o "vetor por gatilho".
- **Depois do MVP:** notícias e comunidade (Fase 10) e, em seguida, nova rodada de design.

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
- UC04 / RNF06 — reconhecimento de texto embarcado (Google ML Kit Text Recognition)

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
| ~~Volume mínimo de texto do OCR~~ — **decidido: v1.1, ver docs/limite-texto-ocr.md** | ~~Fase 6~~ Resolvida | UC04 |
| ~~Limiar de denúncias para ocultar reporte~~ — **decidido (2026-11-16): 3 denúncias de contas distintas** (RF11) | ~~Fase 10~~ Resolvida | RF11 |
| ~~Estrutura de pastas: por camada ou por feature~~ — **decidido: por feature** | ~~Fase 1~~ Resolvida | CLAUDE.md §6, commit `f17bb5c` |
| Bloquear acesso de usuário com e-mail não verificado? | Fase 1 (pode ser revista depois) | RF01 / UC01 |
| Tempo de expiração do bloqueio de login (provisório: 15 min) | Revisão | RF02 |
| Bloquear usuário com e-mail não verificado (padrão atual: não) | Revisão | RF01/UC01 |
| Validação da tabela v1.0 (docs/score-calibracao.md) pela equipe | Não bloqueante | RF07 |
| ~~Ativar o plano Blaze para deploy das Cloud Functions~~ — **decidido (2026-11-12): não ativar.** Projeto acadêmico, só com recursos gratuitos. As Functions rodam apenas no emulador local, inclusive nas demonstrações; Auth e Firestore seguem no plano gratuito (Spark) | ~~Publicação~~ Resolvida | Fase 5 |
| ~~Provedor de LLM com termos que vedem uso para treinamento (RNF07)~~ — **decidido: contratado** | ~~Fase 6.2~~ Resolvida | custo recorrente |
| ~~Ativar faturamento no projeto da chave do Gemini~~ — **decidido (2026-11-12): não ativar.** A exceção ao RNF07 da Fase 6.3 deixa de ser temporária e vale para todo o projeto acadêmico, com as mesmas condições: só conteúdo fictício é enviado ao modelo, inclusive nos testes com pessoas. Limitação declarada no RNF07 de `docs/requisitos.md` e de `docs/relatorio-completo.md` ("Limitação declarada (escopo acadêmico)") | ~~Revisão do documento~~ Resolvida | RNF07 |
| ~~Ativar Cloud Vision e criar chave restrita~~ — **dispensado: OCR embarcado (decisão de 2026-10-07)** | ~~Fase 6.2~~ Resolvida | console |
| Validação da troca do OCR para reconhecimento embarcado (ML Kit), decisão de 2026-10-07 | Não bloqueante | RNF06 |
| Validação das categorias de ameaça v1.0 (docs/categorias-ameaca.md) | Não bloqueante | RNF07 / UC04 |
| Validação do limite de texto v1.1 (docs/limite-texto-ocr.md) | Não bloqueante | RF04 / UC04 |
| **Catalogar as modalidades iniciais da base de conhecimento** — trabalho manual da equipe (RDEV04), uma ficha por modalidade | Prompt 7.2 (validação com fichas reais) | RNF05 / RDEV04 |
| ~~Limiar de similaridade para "correspondência com padrão catalogado"~~ — **proposto: v1.0, ver docs/calibracao-recuperacao.md** | ~~Prompt 7.2~~ Resolvida | RF07 / RNF05 |
| Validação da calibração da recuperação v1.0 (docs/calibracao-recuperacao.md) | Não bloqueante | RF07 / RNF05 |
| ~~RAG na análise de link (UC03, passo 6 do fluxo principal)~~ — **decidido (2026-11-16): sem RAG no link;** UC03 ajustado | ~~Fechamento da Fase 9~~ Resolvida | UC03 / RNF05 |
| ~~Declarar a limitação do RNF03 (5 s) no nível gratuito do Gemini~~ — **feito (2026-11-16)** | ~~Fechamento da Fase 9~~ Resolvida | RNF03 |
| ~~Teste em Android real (WhatsApp e OCR com prints reais, RNF06)~~ — **decidido (2026-11-16): não feito por enquanto** | ~~Fechamento da Fase 9~~ Resolvida | RNF06 / RF10 |
| ~~Login com Apple fora do escopo acadêmico?~~ — **decidido (2026-11-16): não haverá** | ~~Fechamento da Fase 9~~ Resolvida | RF01 / T02/T04 |
| Ícone provisório ("p") passa a definitivo? — fica para o fim (2026-11-16) | Última etapa | Design |
| ~~Texto da tela "Como o Phize calcula o risco"~~ — **aprovado (2026-11-16)** | ~~Fechamento da Fase 9~~ Resolvida | RF14 |
| ~~Tratamento do próprio `gov.br` no RDAP~~ — **decidido (2026-11-16):** verificação concluída, sem sinal | ~~Achado do ensaio~~ Resolvida | RF07 / UC03 |
| ~~Tema claro, escuro ou do sistema (RF14)~~ — **decidido (2026-11-24):** o app passa a ter um só tema, azul-marinho, em todas as telas. A opção Tema sai do Perfil; o tamanho da letra continua. RF14 atualizado em `docs/requisitos.md` e `docs/relatorio-completo.md`; falta levar aos .docx acadêmicos | ~~Visual novo~~ Resolvida | RF14 |
| ~~Testes com pessoas e logo definitivo~~ — **decidido (2026-11-16): não serão feitos** | ~~Fase 9~~ Resolvida | Fase 9, itens 5 e 6 |
| Texto aprovado da política de privacidade e do contato da equipe, para a seção "Sobre o Phize" do perfil (hoje só versão e aviso) | Publicação | RF14 / LGPD |
| Espera entre reenvios do e-mail de verificação (provisório: 60 s) | Revisão | RF14 |
| Categoria própria para o golpe do Pix enviado por engano (hoje cai em "Outro golpe" pela lista fechada v1.0) | Não bloqueante | `docs/categorias-ameaca.md` |
| ~~Exigência de comitê de ética (CEP) para os testes com pessoas~~ — **decidido (2026-11-16):** sem consulta à instituição; testes enquadrados como avaliação de usabilidade do projeto acadêmico, sem dados que identifiquem os participantes, com termo de consentimento. Risco aceito: a instituição entender depois que a aprovação era necessária (`docs/roteiro-testes-pessoas.md`, seção 3) | ~~Testes com pessoas~~ Resolvida | Fase 9, item 5 |
| ~~Índice da base dentro da Function: a atualização da base passa a exigir nova publicação das Functions, não nova versão do app~~ — **documento ajustado (2026-11-16):** arquitetura, seção 3.2 b | ~~Revisão do documento~~ Resolvida | Arquitetura 3.2 b |

> Padrão adotado: **não bloquear**, seguindo o UC01.

---

## PENDÊNCIAS TÉCNICAS

- ~~`firestore.rules` não cobre subcoleções de `users/{uid}`~~ — **resolvida no Prompt 8.1**; publicar as regras novas no console junto com o deploy.
- ~~Restringir os campos graváveis em `users/{uid}` aos previstos~~ — **resolvida no Prompt 9.10**; publicar as regras novas no console junto com o deploy.
- Adicionar ao roadmap os passos de publicação das regras pelo console e teste no Playground.
- ~~Sincronizar os .docx acadêmicos com as alterações de RF07, arquitetura 3.3 e 6, UC03 e relatório 4.8.~~ — **feito em 2026-11-17** (alterações controladas nos `_atualizado.docx`).
- A rotina de mascaramento local pode lançar `StateError` (falha na restauração do isolamento de URL/domínio). O fluxo do UC04 (Fase 6) deve tratar essa exceção interrompendo a análise, sem expor o texto ao usuário nem a log.
- ~~O cálculo do domínio registrável reconhece apenas `com`/`gov`/`org`/`net`/`edu` sob `.br`~~ — **resolvida em 2026-11-16** (achado 1 do ensaio): `dominio_registravel.dart` com as 147 categorias do Registro.br. Sufixos compostos de outros países (`co.uk`) continuam sem tratamento.
- Dois testes de widget anteriores perderam asserções de rótulo e aviso ao eliminar o caminho fictício da tela de Resultado; a cobertura passou para `test/features/analise/presentation/analise_link_flow_test.dart`.
- ~~A tela de Histórico exibe rótulos de faixa sem o aviso permanente~~ — **resolvida no Prompt 8.1**.
- ~~Resta dado fictício fora do fluxo de análise: saudação do Dashboard~~ — **resolvida no Prompt 8.2**.
- ~~Migrar do emulador para a Function publicada antes de qualquer teste em Android real~~ — **superada pela decisão de 2026-11-12** (sem Blaze, Functions só no emulador). Um teste em Android real usa o celular no cabo USB ligado aos emuladores do computador.
- Restringir no console as chaves públicas do Firebase às APIs do Firebase, impedindo que sejam usadas para chamar o Safe Browsing direto e contornar a Function.
- O contador de rate limiting é mantido em memória e zera a cada reinício da Function; migrar para armazenamento compartilhado antes do deploy com mais de uma instância.
- O mapa do rate limiting nunca remove usuários antigos.
- Chamadas com URL inválida consomem o limite antes da validação; comportamento deliberado, a documentar.
- ~~A Function nunca foi exercitada contra o Safe Browsing real; validar com a chave configurada.~~ — **resolvida: validada em 2026-09-24, ver Fase 5**
- A Function passou a receber caminho de URL além do domínio; avaliar se o ciclo de vida desse dado merece registro próprio na documentação, já que o RNF07 trata apenas do texto de OCR.
- Conectar o RAG ao fluxo do UC04 na Fase 7; o Prompt 6.2 é implementado sem recuperação na base de conhecimento (ver decisão de 2026-10-07 na Fase 6).
- A limpeza de cópias órfãs do seletor cobre apenas Android; no iOS o seletor grava em `tmp/` e isso não foi tratado nem validado.
- A remoção real do temporário nunca foi validada em dispositivo ou emulador Android; os testes usam sistema de arquivos em memória.
- Quando o fluxo for ligado à tela (6.2), avaliar a coincidência de tempo entre a limpeza da inicialização e uma seleção em curso.
- A camada de tela não pode exibir nem gravar em log a `FileSystemException` da captura: a mensagem traz o caminho do temporário, que inclui o nome original do print.
- Validar o reconhecimento embarcado (ML Kit) em aparelho Android, com prints reais de WhatsApp e SMS, em tema claro e escuro, antes de considerar o RNF06 cumprido. Declarado como não feito, por enquanto (2026-11-16).
- A arquitetura (3.2) não define onde o texto analisado é convertido em embedding para a recuperação RAG. Se a conversão ocorrer por API, haverá uma segunda etapa remota, o que afeta o RNF03 e exige registro no ciclo de vida do dado textual do RNF07. Definir na Fase 7.
- Validar a chamada ao Gemini real (Function `analiseTexto`) com a chave configurada em `functions/.env.local`.
- O mascaramento local não cobre todas as grafias dos dados listados; os formatos não cobertos estão registrados na limitação declarada do RNF07 (`docs/requisitos.md`).
- O modelo é instruído a nunca afirmar que a mensagem é segura, mas o código não verifica a explicação devolvida.
- ~~Os trechos destacados do RF04 não são devolvidos pelo pipeline do UC04~~ — **resolvida no Prompt 9.3**.
- O streaming do RNF03 não foi implementado: a medição do Prompt 9.4 mostrou ganho de só 0,5 s. Limitação declarada no RNF03 (2026-11-16); reavaliar só com plano pago.
- ~~O build de release do Android falha (R8: classes ausentes do ML Kit)~~ — **resolvida em 2026-11-12**: `android/app/proguard-rules.pro` com `-dontwarn` para as escritas chinesa, devanágari, japonesa e coreana, que o app não usa. `flutter build apk --release` gera o APK (83,3 MB). O APK de release não fala com os emuladores do Firebase (sem exceção de HTTP); os testes de fluxo usam o build de debug.
- A limitação acadêmica do RNF07 (nível gratuito do Gemini, só conteúdo fictício; 2026-11-12) foi declarada em `docs/requisitos.md` e `docs/relatorio-completo.md` e alinhada em `docs/arquitetura.md` (custos e transmissão a terceiros), `docs/viabilidade.md`, na tarefa T13 do `docs/BACKLOG.md` e na Seção 3 do `CLAUDE.md`. Falta levar o texto aos .docx acadêmicos, que ficam fora do repositório.
- ~~Sincronizar os .docx acadêmicos com os RF13 e RF14 (2026-11-12); `docs/relatorio-completo.md` já os traz (2026-11-16). O diagrama de classes de `docs/uml.md` (imagem) precisa do atributo `nomeExibicao` em Usuário depois do Prompt 9.10.~~ — **feito em 2026-11-17:** texto nos `_atualizado.docx` e diagrama de classes refeito com `nomeExibicao`.
- ~~`ReconhecedorTextoMlKit` passou a organizar o texto do print~~ — **registrado na arquitetura, seção 3.1 (2026-11-16).**

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

Sem Safe Browsing (Fase 5), a verificação de link fica incompleta e, pela regra do score v1.0, nunca resulta em verde. Comportamento esperado, não é bug. Essa limitação valeu apenas até a Fase 5.1, quando o Safe Browsing foi conectado e a faixa verde voltou a ser possível.

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

> **ESCOPO DIVIDIDO:** nesta fase foi implementado o endpoint de reputação (Safe Browsing), que recebe a URL normalizada; o nome `reputacaoDominio` foi mantido por decisão. Os endpoints de OCR e de LLM são acrescentados à mesma Function nas Fases 6 e 7, quando houver consumidor real para eles. **[Superado pela decisão de 2026-10-07 quanto ao endpoint de OCR — ver ATUALIZAÇÃO abaixo.]**

> **ATUALIZAÇÃO (2026-10-07):** com a troca para OCR embarcado (decisão registrada na Fase 6), o endpoint de OCR não será necessário. Apenas o endpoint de LLM é acrescentado à Function, na Fase 6.2.

> **VALIDAÇÃO (2026-09-24):** a consulta foi validada contra o Safe Browsing real, pela Function no emulador, com usuário autenticado no Auth emulado (`docs/emulador-local.md`). Os endereços oficiais de teste do Google retornaram listado, e um domínio legítimo retornou não listado.

> **DECISÃO — escopo da consulta de reputação:** a Function recebe a URL normalizada com domínio e caminho; a query string e o fragmento são descartados no dispositivo, antes da transmissão (arquitetura, seção 4, etapa 2). Motivo: os endereços de teste só aparecem como listados com o caminho completo, o que confirma que enviar apenas o domínio deixaria passar golpes hospedados em caminho de site legítimo. RDAP e typosquatting continuam usando só o domínio.

Obrigatória antes de qualquer API paga.

> **[Superado pela decisão de 2026-10-07 quanto ao Vision:]** o prompt abaixo é mantido como registro histórico. O proxy para a API de visão não será implementado, pois o OCR passou a ser embarcado no dispositivo; a Function atende apenas Safe Browsing e LLM.

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

## FASE 5.1 — CONECTAR O SAFE BROWSING À TELA DE RESULTADO — concluída

> **VALIDAÇÃO (2026-09-25):** a faixa verde foi validada no app, com as três verificações (typosquatting, RDAP e Safe Browsing) concluindo sem sinais.

Substituir o marcador provisório da Fase 4 em `analisador_link.dart` pela consulta real, passando o sinal ao motor de score conforme `docs/score-calibracao.md`, e remover a condição de verificação sempre incompleta para a reputação.

---

## FASE 6 — TRILHA DO PRINT (UC04) — concluída quanto ao código

**A partir daqui o Android é obrigatório.**

### Prompt 6.1 — Captura e descarte (concluído)

**[CLAUDE CODE]**
```
Implemente a seleção de imagem da galeria com Zero-Persistence:
carregamento em memória volátil, remoção do arquivo temporário
gerado pelo seletor de mídia, e descarte garantido por bloco
finally executado inclusive em caso de falha.

Escreva o teste que prova o descarte no caminho de exceção.
```

Após a auditoria, que apontou cópias órfãs do seletor em caso de falha na remoção ou fechamento do app no meio do fluxo:

**[CLAUDE CODE]**
```
Corrija a lacuna apontada na auditoria do 6.1. Não altere nada
além do necessário.

1. Limpeza na inicialização
Implemente uma rotina que, ao iniciar o app, remova as pastas
<uuid>/ deixadas pelo seletor de imagem no diretório de cache.
Ela fecha os cenários d e e, em que a cópia fica órfã sem que
retrieveLostData a recupere.

Requisitos:
- a limpeza não pode lançar exceção nem impedir o app de abrir
- deve remover apenas o que pertence ao seletor, nunca outros
  arquivos de cache do app
- nenhum nome de arquivo é escrito em log
- documente no código por que ela existe: o plugin copia a imagem
  para o cache antes de devolver o caminho, e deleteOnExit não é
  confiável no Android, então o RNF01 exige uma varredura própria

2. Falha de cópia tratada como cancelamento
Quando a cópia falhar no plugin e ele devolver null, a rotina de
limpeza acima passa a cobrir eventual arquivo parcial.

3. A mensagem de FileSystemException traz o caminho, que inclui o
nome original do print. Registre no código que essa exceção não
pode ser exibida ao usuário nem gravada em log pela camada de
tela.

Testes obrigatórios:
- a limpeza remove as pastas do seletor
- a limpeza não toca em outros arquivos do cache
- a limpeza falhando não impede o app de iniciar
- nenhum teste acessa o sistema de arquivos real

Rode flutter analyze e flutter test e me mostre o resultado dos
dois. Trabalhe na branch atual, sem commits.
```

### Prompt 6.2 — OCR e pipeline (concluído)

> **DESBLOQUEADO (2026-10-07):** as quatro definições de que dependia foram resolvidas — volume mínimo de texto do OCR (`docs/limite-texto-ocr.md`), provedor de LLM (contratado), chave do Cloud Vision (dispensada pelo OCR embarcado) e execução sem RAG antes da Fase 7 (decisão abaixo).

> **DECISÃO (2026-10-07, pendente de validação pela equipe):** a extração de caracteres passa a ser executada no próprio dispositivo, com reconhecimento de texto embarcado (Google ML Kit Text Recognition), em vez da API de visão computacional em nuvem. Justificativa, em ordem de importância:
> 1. **Privacidade:** a imagem deixa de ser transmitida a terceiros. A seção 5.1 da arquitetura já define a captura de tela como o dado mais sensível manipulado pela aplicação; com o processamento local, a mídia não sai do dispositivo em nenhuma hipótese, e a questão de retenção pelo provedor de OCR deixa de existir.
> 2. **Independência de infraestrutura:** elimina a necessidade de endpoint de OCR na camada intermediária e de chave de API para essa etapa.
> 3. **Custo operacional nulo** para a extração, como consequência.
>
> Limitações:
> - precisão inferior à de serviços em nuvem em imagens de baixa qualidade, aceitável para prints de conversa, que são texto limpo sobre fundo uniforme
> - aumento do tamanho do pacote do aplicativo
> - indisponível na plataforma web, que já não suportava a seleção de imagem da galeria
> - o reconhecimento embarcado não substitui o restante do fluxo: o texto extraído continua sendo transmitido ao modelo de linguagem, de modo que o RNF07 permanece integralmente aplicável

> **DECISÃO (2026-10-07):** o Prompt 6.2 é implementado **SEM RAG**. A recuperação na base de conhecimento é acrescentada na Fase 7, conforme o RNF05, que a define como condição de operação da camada de PLN. Até lá o veredito do modelo não é fundamentado em padrões catalogados, o que deve ser considerado em qualquer demonstração.

> **DECISÃO (2026-10-07):** enquanto a base de conhecimento não existir, a análise de print é tratada como **verificação incompleta**. Aplica-se a regra de `docs/score-calibracao.md` que impede a faixa verde, preservando a pontuação real, e o usuário é informado de que a comparação com padrões catalogados não foi realizada. A regra deixa de valer quando o RAG for conectado ao UC04 na Fase 7.

**[CLAUDE CODE]**
```
Conecte o fluxo do UC04: imagem → OCR embarcado no dispositivo
(Google ML Kit Text Recognition) → descarte da imagem →
verificação de suficiência do texto → mascaramento local (Fase 3)
→ nova verificação de suficiência → envio ao LLM via proxy (novo
endpoint na Function da Fase 5) → score (Fase 2) → descarte do
texto.

A imagem não é transmitida em nenhuma etapa. Não crie endpoint
de OCR na Function.

Trate todas as exceções listadas no UC04.
```

> **REGISTRO — mascaramento local na Fase 6:** a rotina de mascaramento recebeu cinco rodadas de correção durante a Fase 6 (boleto em formato impresso; boleto de convênio; telefone com espaços e celular de 11 dígitos rotulado como CPF; CPF com espaços ou barra e telefone sem DDD; chave Pix sem hífens e CNPJ com espaços ou alfanumérico). Somadas às duas rodadas da Fase 3, são sete. Todas as lacunas foram encontradas pela execução do código sobre textos reais, não pela suíte de testes, que passava integralmente a cada rodada. Os formatos que permanecem sem cobertura estão na limitação declarada do RNF07.

---

## FASE 6.3 — CONECTAR O PIPELINE DO PRINT À INTERFACE — concluída quanto ao código

Análoga à Fase 5.1 para a trilha do link: o pipeline do UC04 (`analisador_print.dart`), implementado e testado no Prompt 6.2, passa a ser acionado pela interface. O pipeline não foi alterado.

Escopo:
- **Dashboard:** o botão "Analisar print", antes desabilitado, fica ao lado de "Analisar link", com a mesma hierarquia visual, e abre a nova tela "Analisar print". (Revisto em 2026-11-24, decisão da equipe sobre o visual novo: "Analisar print" é a ação principal, preenchida, e "Analisar link" a secundária, contornada.) Na web segue desabilitado, porque não há seleção de imagem com Zero-Persistence nem OCR embarcado nessa plataforma.
- **Tela "Analisar print"** (`analisar_print_page.dart`): aciona a seleção na galeria pelo `SeletorImagemGaleria`, executa o pipeline com `ReconhecedorTextoMlKit` e `AnaliseTextoClientHttp` (todos já existentes em `data/`) e exibe o feedback de carregamento imediatamente após o acionamento (RNF03). Cancelamento da seleção volta ao estado inicial sem mensagem.
- **Interrupções:** cada motivo de `MotivoInterrupcaoPrint` é exibido com a mensagem própria dele, em linguagem não técnica (RNF04) — texto insuficiente antes e depois do mascaramento, falha de OCR, falha na chamada ao modelo e resposta inválida, esta com botão "Tentar novamente", que refaz a seleção (a imagem anterior já foi descartada). A tela nunca exibe nem registra em log a exceção original; em especial, a `FileSystemException` da captura, que traz o nome original do print.
- **Tela de resultado** (`resultado_analise_page.dart`): passa a exibir os dois tipos — `ResultadoAnalisePage(resultado:)` para link, inalterado, e `ResultadoAnalisePage.print(resultado:)` para print. Termômetro, rótulo do RF07 e aviso permanente ficam num único ponto, comuns aos dois. Para o print, a tela lista os sinais identificados, a categoria da ameaça e a explicação pedagógica, além do aviso de verificação incompleta. O aviso de falibilidade do Safe Browsing continua exclusivo do link.
- **Faixa verde bloqueada sem RAG:** a tela exibe a faixa que vem pronta de `CalculadoraScore`, que já recebe `verificacaoIncompleta: true` do pipeline enquanto `AnalisadorPrint.baseConhecimentoDisponivel` for `false`. A tela não recalcula nem reavalia a faixa e mostra `motivoSemBaseConhecimento` ao usuário.
- **Nenhum conteúdo em estado:** a tela guarda apenas o indicador de carregamento e o motivo da interrupção. `AnalisePrintConcluida` não tem campo para imagem ou texto, e nada é persistido (a gravação no histórico é da Fase 8).

> **PENDÊNCIA (Fase 6.3):** o RF04 e o UC04 (passo 9) pedem o destaque, na interface, das frases que motivaram cada gatilho. Isso não foi implementado: o resultado do pipeline não traz trechos do texto, por desenho (RNF07, descarte na origem), e o contrato da Function não devolve trechos. Exibir trechos exige decidir como conciliar o destaque com o descarte do texto — decisão da equipe, não da implementação.

> **PENDÊNCIA (Fase 6.3):** o RNF03 prevê streaming progressivo do texto gerado. A tela exibe carregamento imediato, mas o resultado aparece de uma só vez, porque a Function devolve a resposta completa e validada.

> **CORREÇÕES (auditoria da Fase 6.3):** D1 — sem sessão reconhecida pela Function, a mensagem deixou de usar a palavra "sessão" e a tela oferece o botão "Entrar de novo", que encerra a sessão (`AuthRepository.sair()`, método acrescentado sem alterar as demais regras de autenticação) e leva ao login; D2 — o estado vazio do resultado de print perdeu o ícone de confirmação e passou a dizer que nenhum sinal de golpe conhecido foi identificado e que a verificação não pôde ser completa; D3 — o texto da tela de seleção diz que a imagem não sai do celular e que o texto, com os dados estruturados escondidos, é enviado para análise; D4 — na resposta inválida, mensagem e botão ("Escolher o print de novo") deixam claro que o print precisa ser escolhido outra vez.

> **CORREÇÕES (segunda auditoria da Fase 6.3):** D1-a — sem conexão para renovar o token vencido (`network-request-failed`) ou com tempo esgotado, os clientes `AnaliseTextoClientHttp` e `ReputacaoDominioClientHttp` passaram a lançar a exceção de indisponibilidade, como já faziam para falha de conexão no POST; token rejeitado, usuário desativado e demais códigos seguem como não autenticado. No print, a falha de rede mantém o caminho de nova tentativa; no link, aparece como verificação não concluída por indisponibilidade, com a faixa elevada pela regra de verificação incompleta. D3-a e D3-b — o texto da tela de seleção passou a dizer que é enviado o texto que aparece no print e que o app procura esconder dados como CPF, telefone e cartão.

> **PENDÊNCIAS (auditoria da Fase 6.3, sem implementação):**
> - Sair da tela "Analisar print" durante o processamento não interrompe a transmissão do texto mascarado já em curso: o pipeline segue até o fim e só o resultado é descartado.
> - O aviso permanente do RF07 fica no fim da tela de resultado e pode exigir rolagem quando a explicação é longa. Definir se "permanente" significa sempre visível (ex.: fixo no rodapé).
> - A regra que impede a faixa verde sem base de conhecimento vive apenas no pipeline (`AnalisadorPrint`). Construtores futuros de `AnalisePrintConcluida`, como o histórico da Fase 8 e o compartilhamento do UC11, poderiam produzir score inconsistente sem que a tela detecte. Avaliar validação defensiva na camada de apresentação.
> - Os clientes HTTP instanciados no `builder` das rotas de link e de print (`app_router.dart`) nunca são fechados.

> **VALIDAÇÃO CONCLUÍDA (2026-11-03):** o fluxo completo (galeria, ML Kit, mascaramento, Function, Gemini, motor de score e tela de resultado) foi exercitado no emulador Android, com Functions, Auth e Firestore emulados, usando os quatro prints de `tools/gerador-prints/`. Os scores e as faixas conferiram com `docs/score-calibracao.md`, inclusive o teto da soma e a faixa verde impedida sem a base de conhecimento; no cenário com CPF e telefone, a explicação não reproduziu nenhum dos dois. Ajustes feitos a partir da validação: o aviso de verificação incompleta deixou de dizer "mesmo sem sinais encontrados", que soava errado quando havia sinais; e a instrução do Gemini passou a exigir acentuação, porque uma das explicações veio sem acentos. Respostas 503 do nível gratuito do Gemini apareceram de forma intermitente como "serviço indisponível"; repetir a análise resolveu.
>
> **Para revisar na Fase 7:** no cenário da falsa central, o modelo marcou também `inducao_urgencia` a partir da ameaça de encerramento da conta, sinal que o `README.md` do gerador não lista. O motor somou corretamente; a decisão é se a instrução do modelo deve separar ameaça de urgência.

> **EXCEÇÃO TEMPORÁRIA AO RNF07 (2026-10-27, decisão da equipe):** a validação da Fase 6.3 usa uma chave do Gemini no **nível gratuito**, cujos termos permitem ao Google usar o conteúdo enviado para melhorar os produtos, inclusive com revisão humana. Isso contraria o RNF07 (transmissão só por APIs que vedem uso para treinamento) e foi aceito conscientemente para destravar os testes. Condições: enviar **somente** os prints fictícios de `tools/gerador-prints/`, nunca conversa real nem dado pessoal real; a exceção termina quando o faturamento for ativado no projeto da chave, antes de qualquer demonstração com conteúdo real. O nível gratuito também é atendido por último em picos de demanda (respostas 503), o que aparece no app como "serviço indisponível".

> **MODELO (2026-10-27):** o `gemini-2.5-flash` deixou de ser oferecido a chaves novas (404). O padrão da Function passou a `gemini-3.8-flash` (`functions/src/config.ts`); a variável `GEMINI_MODEL` no `.env.local` permite trocar sem alterar código. A validação de 2026-11-03 usou `gemini-3.5-flash-lite`, definido em `GEMINI_MODEL` no `.env.local`, e a resposta seguiu o esquema JSON da Function; o padrão `gemini-3.8-flash` não foi exercitado.

> **FERRAMENTA (validação manual):** `tools/gerador-prints/` tem uma página HTML autocontida que desenha e exporta em PNG quatro conversas fictícias: falso parente com troca de número, falsa central bancária, conversa cotidiana sem sinais e mensagem com CPF e telefone inventados, para validar o mascaramento. O RNF07 veda enviar conversas reais ao provedor de LLM nesta fase. O `README.md` da pasta lista os sinais esperados de cada cenário e explica como colocar as imagens na galeria do emulador. Os pesos e as faixas continuam apenas em `docs/score-calibracao.md`.

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

> **CONCLUÍDO (2026-11-03):** fichas em `functions/base-conhecimento/fichas/`, uma por modalidade, com os campos da seção 3.2 (a) da arquitetura, a categoria de `docs/categorias-ameaca.md` e, obrigatoriamente, fontes e curadoria (quem revisou e quando). `npm run indexar-base` valida as fichas, gera embeddings com o `gemini-embedding-2` (768 dimensões, `functions/src/config.ts`) só para as fichas novas ou alteradas e grava `indice.json`; `--verificar` confere sem chamar a API, e o `npm test` reprova ficha inválida ou índice desatualizado. Instruções de catalogação em `functions/base-conhecimento/README.md`. A base versionada está vazia: o conteúdo é catalogado pela equipe (RDEV04).
>
> **ÍNDICE NA FUNCTION:** o índice fica em `functions/` porque a consulta precisa do embedding do texto mascarado, gerado com a chave do Gemini, que só existe na camada intermediária. Consequência: atualizar a base exige publicar as Functions de novo, e não lançar nova versão do app como diz a arquitetura (seção 3.2 b). O índice continua em arquivo local versionado no repositório, como a arquitetura prevê. Pendente de revisão do documento pela equipe.
>
> **RASCUNHOS (2026-11-03):** 10 fichas em `functions/base-conhecimento/rascunhos/`, escritas com ajuda da IA a partir de duas páginas da Febraban (os 10 golpes mais aplicados em 2024 e o golpe do WhatsApp), com a curadoria em branco. Ficam fora do índice até a revisão de alguém da equipe. A troca de cartão na maquininha ficou de fora, por ser presencial e não aparecer em print. Numa cópia temporária indexada fora do repositório, o texto fictício dos prints de golpe teve a ficha da modalidade certa em primeiro lugar, e as conversas comuns ficaram abaixo de todas as fichas relacionadas a golpe.
>
> **PRIMEIRO LOTE REVISADO E SEGUNDO LOTE (2026-11-03):** as 10 fichas do primeiro lote foram revisadas pela equipe, sem alteração de conteúdo, e indexadas. O segundo lote tem 10 rascunhos a partir de páginas oficiais: falso leilão de veículos (Detran-PR), boleto falso de IPVA (Sefaz-MT), Pix errado (Febraban), falso consignado (INSS), falsa vaga de emprego (Febraban), falso sequestro (Sejusp-MS, alerta de 2017), golpe do amor (Agência Brasília), falso prêmio (Sefa-PR), taxa falsa de encomenda (Receita Federal) e falsa cobrança de dívida ativa (PGFN). O "valores a receber" do Banco Central ficou de fora: a página oficial não pôde ser lida. Numa cópia temporária com as 20 fichas, 11 mensagens fictícias de golpe tiveram a ficha da modalidade certa em primeiro lugar, e 4 conversas comuns ficaram abaixo de todas as mensagens de golpe.
>
> **AUDITORIA DA BASE (2026-11-03):** sobre as 20 fichas, comparação par a par dos embeddings, busca por gatilhos repetidos, teste de recuperação com uma mensagem fictícia por ficha e 6 conversas comuns (incluindo um racha de conta por Pix e um aviso legítimo de compra no cartão), e leitura de cada ficha contra a fonte. Sem duplicatas: as 20 mensagens recuperaram a ficha da modalidade certa em primeiro lugar. Pares próximos (falsa central, mão fantasma e phishing; devolução de empréstimo e Pix errado; IPVA e leilão; falsa venda e taxa de encomenda) são modalidades distintas nas fontes; trocar gatilhos não aumentou a separação, e as fichas foram mantidas. Uma variante do texto de embedding sem rótulos nem canais não melhorou a recuperação; o formato atual foi mantido. Corrigidas duas fichas com trechos sem respaldo na fonte citada: `falso-sequestro` (pedido) e `falso-consignado-inss` (pedido e gatilhos, com o Procon Goiás como segunda fonte); as duas voltaram para revisão. A fonte do falso sequestro é de 2017 e deve ser trocada por uma mais recente quando houver.
>
> **RECOMENDAÇÃO PARA O 7.2:** a conversa comum mais parecida com golpe (aviso legítimo de compra no cartão) ficou a poucos centésimos da mensagem de golpe menos parecida com a sua ficha. A similaridade sozinha não separa os dois casos: recuperar as três fichas mais próximas, usar o limiar só para descartar o que claramente não tem relação e deixar o modelo decidir se há correspondência (arquitetura, seção 3.2 c). As mensagens fictícias da auditoria servem de ponto de partida para a calibração.
>
> **SONDAGEM PARA O 7.2:** com duas fichas de teste fora do repositório, o texto fictício de cada print ficou mais próximo da ficha da sua modalidade, e a conversa comum ficou abaixo das duas. A distância entre "relacionado" e "sem relação" foi pequena, então o limiar de similaridade precisa ser calibrado com fichas reais e registrado em documento de calibração.

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

> **CONCLUÍDO (2026-11-03):** a Function `analiseTexto` gera o embedding do texto mascarado, recupera as fichas mais parecidas (`functions/src/recuperacao.ts`; quantidade e limiar em `docs/calibracao-recuperacao.md`) e as envia ao Gemini junto com a mensagem. O modelo só emite `correspondencia_padrao_catalogado` apontando em `padraoCorrespondente` uma das fichas enviadas; sinal sem padrão, padrão sem sinal ou padrão não enviado descartam a resposta inteira. A resposta informa `baseConsultada`; no app, só `true` remove o aviso de verificação incompleta, e correspondência sem base consultada é descartada. Se o índice faltar ou o embedding da consulta falhar, a análise segue sem a base e a faixa verde fica impedida (degradação controlada). Timeout do app passou a 35 s, acima da soma dos timeouts da Function. `npm run avaliar-recuperacao` mede a recuperação com as mensagens fictícias de `functions/base-conhecimento/avaliacao/`.
>
> **VALIDAÇÃO COM A API (2026-11-03):** pelo mesmo caminho da Function, sem o app: os prints fictícios de golpe e quatro golpes da avaliação apontaram a ficha certa, com explicação que cita a modalidade e a orientação da ficha; três mensagens legítimas que recebem fichas próximas (racha de conta, aviso de compra no cartão, boleto de condomínio) não tiveram correspondência; os prints comuns não passaram do limiar. Duas explicações vieram sem parte dos acentos, apesar da instrução: limitação do `gemini-3.5-flash-lite`, a observar na troca de modelo ou no faturamento.
>
> **VALIDAÇÃO CONCLUÍDA NO EMULADOR (2026-11-03):** fluxo completo no emulador Android, com Functions, Auth e Firestore emulados e os quatro prints de `tools/gerador-prints/`. Os prints de golpe mostraram o sinal "Semelhança com golpe já catalogado" e a explicação citou a modalidade, com score e faixa conforme `docs/score-calibracao.md`, inclusive o teto da soma. Os dois prints sem golpe saíram na faixa verde, sem o aviso de verificação incompleta; no print com CPF e celular, a explicação não reproduziu nenhum dos dois, e veio de novo sem parte dos acentos. Essa validação não exercitou o caminho de falha da base (índice ausente ou embedding indisponível), coberto só pelos testes automatizados.

---

## FASE 8 — FECHAMENTO DO MVP

**[CLAUDE CODE]**
```
Implemente UC06 (histórico com persistência seletiva),
UC12 (exportação e exclusão de dados — RF12) e
UC11/RF10 (recebimento por compartilhamento nativo).
```

### Prompt 8.1 — Histórico (UC06) (concluído)

- **Onde:** cada análise concluída vira um documento em `users/{uid}/analises/{id}`. A tela de Histórico lê essa coleção, e tocar em um registro abre o detalhe.
- **Campos:** score, faixa, categoria, explicação, tipo de entrada e data. `firestore.rules` só aceita esta lista, e um registro não pode ser alterado depois de gravado.
- **Faixa gravada (decisão da equipe, 2026-11-03):** a regra de verificação incompleta pode exibir em amarelo uma pontuação que seria verde, então a faixa não pode ser recalculada do score. RNF01, RNF07, arquitetura 5.4 e CLAUDE.md foram atualizados.
- **Link (decisão da equipe, 2026-11-03):** sem categoria, com explicação montada no app a partir dos títulos fixos das verificações, sem o endereço analisado e sem chamar a IA.
- **Falha na gravação:** a tela de Resultado abre normalmente e o usuário recebe um aviso de que a análise não foi guardada (CLAUDE.md, Seção 8).
- **Validação:** `flutter test`, `flutter analyze` e 18 conferências das regras no emulador do Firestore, com campo extra, outro usuário e usuário sem login recusados. No emulador Android, duas análises do mesmo link deram score 0: a primeira, com a reputação não concluída, voltou do histórico em amarelo, e a segunda em verde, na ordem mais recente primeiro. O documento gravado não trazia o endereço. Um print fictício de falso parente também foi gravado com os seis campos permitidos, com categoria e score 100, sem o texto da conversa.

> **Pontos para a equipe:**
> - A explicação do print vem do modelo, instruído a não repetir dados pessoais; o código não verifica isso, e o texto é gravado. A limitação já existia na decisão de persistir a explicação (RNF07), mas agora passa a valer na prática.
> - O campo `data` usa o relógio do aparelho.
> - Na primeira chamada depois de ligar os emuladores, a reputação ficou como não concluída; a mesma consulta funcionou em seguida, o que sugere tempo limite na partida a frio da Function. A causa não foi confirmada. Vale medir isso na Function publicada.

### Prompt 8.2 — Exportação e exclusão de dados (UC12) (concluído)

- **Onde:** ícone de perfil no Painel, que abre a tela Meus dados (`lib/features/conta/`).
- **Exportação:** arquivo `phize-meus-dados.json` com e-mail, data do cadastro e histórico, entregue pelo menu de compartilhamento do sistema (`share_plus`). A cópia que fica no cache do app é removida na abertura seguinte e na exclusão da conta.
- **Exclusão:** aviso de irreversibilidade e senha. A ordem é confirmar a senha, remover as análises, remover o perfil e remover a credencial. Senha errada não apaga nada.
- **Falha parcial:** só a etapa de remoção pode deixar a conta pela metade. Nesse caso a exclusão fica marcada no aparelho, e a conta só abre a tela de bloqueio, de onde se conclui a remoção ou se sai. Repetir a exclusão é seguro. Falha antes dessa etapa não apaga nada e não bloqueia a conta.
- **Validação:** `flutter test`, `flutter analyze`, compilação web e, no emulador Android, exportação com e sem internet, senha errada e exclusão com remoção da credencial, do perfil e das análises da conta. A tela de bloqueio foi coberta só por testes automáticos.
- **Auditoria (2026-11-03), corrigido antes do commit:**
  - sem internet logo após a senha, a conta era bloqueada mesmo sem nada ter sido apagado;
  - o tempo limite na remoção da credencial podia bloquear uma conta já removida;
  - a exportação sem internet podia entregar só o cache, como se fosse a íntegra dos dados;
  - o arquivo exportado não trazia o identificador do usuário;
  - a saudação "Olá, Maria" era fictícia;
  - após login ou cadastro, a seta de voltar levava ao login sem encerrar a sessão; a tela Meus dados ganhou "Sair da conta", que o app não tinha;
  - a ordem da exclusão passou a ter testes próprios.

> **Pontos para a equipe:**
> - A marca de exclusão pendente fica só no aparelho. Reinstalar o app ou entrar por outro aparelho a perde, e a conta volta a abrir, possivelmente sem parte dos dados. Uma Function que conclua a remoção no servidor resolveria isso, e depende do plano Blaze.
> - O arquivo exportado é JSON: legível, mas pouco amigável para o público idoso. Vale avaliar na validação com usuários.
> - A exclusão usa senha porque só há login por e-mail. O login social (T02/T04) exigirá outra forma de confirmação.

### Prompt 8.3 — Compartilhamento nativo (UC11/RF10) (concluído no Android)

- **Recebimento:** o Phize aparece no menu de compartilhar para imagem e texto. `MainActivity.kt` lê a imagem direto para a memória, sem arquivo intermediário; por isso não se usa pacote pronto, que gravaria uma cópia no cache, o que o RF10 proíbe.
- **Roteamento:** imagem vai ao pipeline do print, sem a galeria; link vai à análise de link. Imagem com link pede a escolha; imagem com legenda sem link é só imagem. O resultado entra no histórico como nas outras análises.
- **Texto sem link (decisão da equipe, 2026-11-03):** mostra aviso e orienta a compartilhar um print. O UC11 foi detalhado; o RF10 fala em "texto", então vale rever se ele deve dizer "link".
- **Sem sessão:** o conteúdo espera em memória (`CaixaCompartilhamento`), a tela de login avisa, e a análise abre sozinha ao entrar. Conta com exclusão pendente fica no bloqueio.
- **Abertura do app:** com sessão ativa, o app abre direto no Painel, sem pedir login a cada abertura. Sem isso, todo compartilhamento pararia no login.
- **Android:** `launchMode` passou a `singleTask`, para o compartilhamento não abrir uma segunda instância do app; o nome exibido passou a "Phize".
- **Validação no emulador:** Google Fotos -> compartilhar -> Phize, com resultado direto e registro no histórico, sem cópia da imagem no aparelho; link sem sessão, com análise após o cadastro; app fechado com sessão; texto sem link; tipo não suportado. Reabrir o app não repete a análise.

> **Pontos para a equipe:**
> - **iOS não implementado:** exige Share Extension, projeto iOS configurado e testes em Mac. Só o Android recebe compartilhamento.
> - **Imagem com link** coberta só por testes automáticos. Falta testar com o WhatsApp instalado em aparelho real.
> - **Imagem acima de 25 MB** é recusada como não suportada.
> - **O ícone do app** ainda é o padrão do Flutter, e ele aparece no menu de compartilhar.
> - **Validade da sessão:** com a abertura direta, quem usa um aparelho desbloqueado vê o histórico sem senha. Vale avaliar na validação de privacidade.

---

## FASE 9 — DESIGN, FECHAMENTO E VALIDAÇÃO DO MVP

Plano definido em 2026-11-04. O design vem antes dos itens restantes para que eles já nasçam no visual novo.

1. **Design:** direção Leve (Prompt 9.1).
2. **Itens do MVP fora das fases anteriores:** tela de consentimento (T33), destaque das frases suspeitas (T19), resposta progressiva (T32), login com Google e Apple (T02/T04).
3. **Validação da base:** mensagens de teste escritas por outras pessoas, comparação da análise com e sem a base, variação do score entre execuções. Pode correr em paralelo aos itens acima.
4. **Ambiente real:** faturamento do Gemini, plano Blaze, publicação das Functions e das regras do Firestore, teste com WhatsApp em aparelho real. Faturamento e Blaze descartados (2026-11-12, só recursos gratuitos); o teste em aparelho real está em "Fechamento da Fase 9".
5. ~~**Testes com pessoas**~~ — **cancelado (decisão de 2026-11-16).** O plano era: idosos e pessoas com menos familiaridade digital, com consentimento dos participantes. Roteiro em `docs/roteiro-testes-pessoas.md` (v1.0, 2026-11-16, para revisão da equipe): só conteúdo fictício, celular de teste ligado ao computador da equipe, 8 tarefas, ficha de observação, questionário SUS e modelo de termo de consentimento. Antes das sessões: gerar os prints e fazer o ensaio. Comitê de ética: sem consulta à instituição (decisão de 2026-11-16), os testes seguem como avaliação de usabilidade do projeto acadêmico, sem dados que identifiquem os participantes e com termo de consentimento (roteiro, seção 3).
6. ~~**Logo definitivo**~~ — **cancelado (decisão de 2026-11-16).**
7. **Orientação e perfil (plano de 2026-11-12):** tutorial de primeiro uso (RF13) e tela de perfil (RF14), Prompts 9.8 a 9.12. Página inicial com notícias e comunidade ficam para a Fase 10.

### Prompt 9.1 — Design Leve (concluído no código)

- **Tema:** `lib/core/theme/app_theme.dart` concentra cores, tipografia e componentes. Fonte Plus Jakarta Sans embutida no app, com licença em `assets/fonts/OFL.txt`.
- **Termômetro:** medidor em arco de 0 a 100, que atende melhor ao RF07 que o círculo anterior.
- **O que fazer agora:** orientação fixa por faixa em `RotulosRisco`, sem passar pelo modelo.
- **Navegação:** abas Início, Histórico e Conta. A aba Conta abre Meus dados, e `PhizeBottomNav` passou para `lib/shared/`, por ser usada por duas features.
- **Cores do semáforo:** o medidor usa a cor forte, e o texto usa uma variação mais escura, para ter contraste sobre o branco.
- **Ícone:** provisório, com a letra "p", até a criação do logo. Só o Android foi atualizado.
- **Decisão de tela:** explicação, verificações e fontes continuam abertas na tela de resultado, abaixo da orientação, em vez de recolhidas em "Ver mais". O RF07 pede exibição junto com a resposta da IA, e o UC03 e os termos do Safe Browsing pedem as fontes e o aviso visíveis.

> **Pontos para a equipe:** a orientação fixa é genérica por faixa; uma versão por categoria exigiria textos revisados. As telas foram conferidas no emulador Android.

### Prompt 9.2 — Tela de consentimento (T33) (concluído)

- **Quando aparece:** na primeira análise de print, pela galeria ou por compartilhamento. Sem aceite, a galeria não abre, e a imagem compartilhada é descartada sem envio. A análise de link não passa por aqui, porque não envia texto da conversa.
- **O que informa:** a imagem fica no aparelho, o texto vai ao Gemini, os dados que são escondidos e os que não são, e a conversa não é guardada.
- **Como retirar:** aba Conta, "Privacidade da análise de print".
- **Registro:** versão aceita, por usuário, só no aparelho (`versaoConsentimentoAnalise`). Mudar o aviso exige aumentar a versão.
- **Validação no emulador:** recusar mantém a galeria fechada; aceitar abre a galeria. A remoção da marca na exclusão da conta e o caminho do compartilhamento têm só testes automáticos ou revisão de código.

> **Pontos para a equipe:**
> - O texto não passou por revisão jurídica.
> - O aceite fica só no aparelho: não serve como prova de consentimento nem entra na exportação (RF12). Se a equipe precisar de registro, ele deve ir para `users/{uid}`.
> - O aviso não promete que o texto não é usado para treinamento, porque isso só será verdade com o faturamento do Gemini ativo (exceção temporária ao RNF07). Depois disso, vale incluir essa garantia e aumentar a versão.
> - **Versão 2 do consentimento (2026-11-12):** com a decisão de ficar no nível gratuito, o aviso ganhou o item "Use só conversas de teste": o Phize é acadêmico, o Google pode usar o texto enviado (inclusive com leitura por pessoas) e só mensagens de teste devem ser analisadas (RNF07, limitação de escopo acadêmico). `versaoConsentimentoAnalise` passou a 2, e quem aceitou a versão 1 vê o aviso de novo. Conferido no emulador.

### Prompt 9.3 — Destaque das frases suspeitas (T19) (concluído)

- **Trechos:** o modelo devolve até 5 frases, cada uma ligada a um sinal. A Function confere se cada frase existe no texto mascarado e se o sinal foi emitido; o que não passa é descartado sozinho, sem invalidar a análise. Sinais e score não dependem dos trechos.
- **Tela:** cada sinal mostra suas frases na tela de resultado, com o aviso de que elas não ficam no histórico.
- **Privacidade:** os trechos saem do texto já mascarado, ficam em memória só enquanto o resultado está aberto, e não existem no registro do histórico, nas regras do Firestore nem em log. A sequência do UC04 exibe o destaque (passo 9) antes do descarte (passo 10).
- **Explicação:** o prompt pede no máximo 3 frases e 50 palavras. Em 6 mensagens fictícias com a API real, a maior teve 37 palavras.
- **Validação:** análise de print fictício no emulador Android, com frases destacadas e registro sem conteúdo da conversa.

> **Pontos para a equipe:**
> - Os trechos não têm nomes mascarados, como o restante do texto (RNF07, limitação declarada). Eles voltam só para o aparelho de quem enviou o print.
> - Se a equipe entender que a etapa 3 do RNF07 exige descarte antes da exibição, o texto do requisito precisa prever o destaque do RF04.
> - O limite de tamanho da explicação é só instrução ao modelo; o código continua aceitando até 2.000 caracteres.
> - A explicação às vezes vem sem acentos com `gemini-3.5-flash-lite`, apesar da instrução. Vale reavaliar ao ativar o faturamento e trocar o modelo.

### Prompt 9.4 — Retorno durante a análise (T32) (parcial)

- **Feito:** a tela mostra as três etapas reais do pipeline (ler o texto, esconder os dados, comparar com golpes conhecidos) e, depois de 10 segundos, avisa que a análise continua.
- **Medição (2026-11-04):** com 6 mensagens fictícias e `gemini-3.5-flash-lite` no nível gratuito, a consulta à base levou de 0,5 a 1,7 s. O primeiro pedaço da resposta levou de 4,3 a 21 s, e o restante chegou cerca de 0,5 s depois. Reduzir o raciocínio do modelo não ajudou: `thinkingLevel: minimal` levou de 10 a 48 s, e `thinkingBudget: 0` foi recusado.
- **Decisão técnica:** streaming não foi implementado, porque a espera acontece antes do primeiro pedaço. Ele adicionaria complexidade para ganhar meio segundo e entraria em conflito com o UC04, que veda exibição parcial de resposta inválida.

> **Pontos para a equipe:**
> - **O RNF03 continua não atendido ao pé da letra:** a primeira porção do resultado não aparece em até 5 segundos. A causa provável é a fila do nível gratuito, mas isso ainda não foi confirmado.
> - Repetir a medição com o faturamento ativo. Se a demora cair, o requisito pode ser atendido sem streaming. Se continuar, revisar o RNF03.

### Prompt 9.5 — Login com Google (T02/T04) (concluído; Apple pendente)

- **Feito:** botão "Continuar com Google" na tela de login, que cria a conta e o documento `users/{uid}` no primeiro acesso. Essa entrada não conta nas tentativas de login do RF02.
- **Exclusão de conta:** quem não tem senha confirma pelo Google, na exclusão e na tela de bloqueio.
- **Configuração feita em 2026-11-04:** provedor Google ativado em Firebase Authentication, SHA-1 de depuração cadastrado no app Android e `android/app/google-services.json` atualizado.
- **Validação no emulador Android, com conta Google real e Auth emulado:** login, criação do perfil sem senha, confirmação da exclusão pelo Google e remoção da conta e do perfil. Sair, desistir na escolha de conta e a tela de bloqueio dessas contas têm só testes automáticos.

> **Pontos para a equipe:**
> - **Apple não implementado** — fora do escopo acadêmico (decisão de 2026-11-16): exige conta de desenvolvedor Apple, projeto iOS e um Mac. Vale lembrar que a App Store costuma exigir login da Apple em app com login social.
> - O botão usa um ícone genérico; as diretrizes do Google pedem o logo oficial antes da publicação.
> - O SHA-1 de produção precisará ser cadastrado ao criar a chave de assinatura definitiva.

### Prompt 9.6 — Comparação com e sem a base (preparada, falta a coleta)

- **Script:** `npm run avaliar-analise -- --arquivo independente.json --repeticoes 3`. Roda cada mensagem com e sem a base e mede golpes detectados, falsos alarmes, correspondência com a ficha certa e variação dos sinais. O relatório guarda identificadores e sinais, nunca o texto.
- **Detecção:** ter ao menos um sinal, o que já tira a mensagem da faixa verde. Assim o script não duplica os pesos do score.
- **Trava:** o script recusa mensagem com CPF, telefone ou e-mail sem marcador, antes de enviar qualquer coisa.
- **Coleta:** [documento para as pessoas preencherem](https://claude.ai/artifact/5Ra1FxgdbR7x5Me7E3yLif), com meta de 20 golpes e 20 mensagens legítimas difíceis. Ao terminar, as mensagens vão para `functions/base-conhecimento/avaliacao/independente.json`.
- **Piloto, só para testar o script:** 5 golpes e 5 mensagens comuns escritas pela IA, 2 repetições. Com a base: 5 de 5 golpes, nenhum falso alarme, 5 correspondências certas. Sem a base: 5 de 5 golpes, 1 falso alarme. Amostra pequena e não independente: não prova o diferencial.

### Prompt 9.7 — Teste da recuperação sem coleta (concluído)

A coleta de mensagens com outras pessoas ficou inviável para a equipe agora. Plano do RAG sem coleta, em 5 etapas: (1) conjunto de teste confiável; (2) texto com cara de print real, com OCR de prints sintéticos e uso só das mensagens recebidas; (3) ajustes na busca, como um vetor por gatilho e o campo `situacoesLegitimas`; (4) mais fichas a partir de fontes públicas; (5) medir a mudança de faixa com e sem a base, no motor de score do app.

- **Feito (etapa 1):** trava contra cópia (`functions/src/sobreposicaoFichas.ts`, `npm run conferir-teste`), aplicada antes de qualquer chamada à API em `avaliar-recuperacao` e `avaliar-analise`. Conjunto `avaliacao/teste.json` com 63 golpes e 26 mensagens legítimas difíceis. Detalhes e números em `docs/calibracao-recuperacao.md`, seção "Conjunto de teste".
- **Resultado:** a ficha certa continua em 1º lugar em 52 de 54 golpes sem palavras copiadas, mas o limiar de 0,70 quase não filtra. 14 de 26 mensagens legítimas e 5 de 5 golpes fora da base chegam ao modelo com fichas. A medição anterior (3 de 8) era otimista: 13 das 28 mensagens de `mensagens.json` copiam frases das fichas.

- **Feito (etapa 5):** faixas com e sem a base calculadas pelo motor do app (`test/avaliacao/`), a partir dos sinais gravados por `avaliar-analise`. Os pesos continuam só em `ScoreConfig`.
- **Resultado do modelo:** nenhuma correspondência errada em 14 legítimas e 5 golpes fora da base que receberam fichas; 51 de 54 correspondências certas. Com a base, 28 golpes subiram de amarelo para vermelho, e nenhuma mensagem legítima subiu de faixa. O comprovante falso de pagamento passou sem sinal: candidato a ficha nova (etapa 4).

- **Feito (etapa 2):** 89 prints sintéticos (`tool/prints_sinteticos/`) passados pelo ML Kit no emulador, como o app faz. `organizarTextoPrint` (`lib/shared/domain/organizacao_texto_print.dart`) põe o texto em ordem de leitura, tira a interface e fica só com as mensagens recebidas; `ReconhecedorTextoMlKit` passou a usá-la. Detalhes em `docs/calibracao-recuperacao.md`, seção sobre texto de print.
- **Resultado:** na busca, a ficha certa em 1º lugar cai de 52 para 45 de 54 com o texto bruto e volta a 52 só com as recebidas. No modelo, só com as recebidas: 53 correspondências certas (50 no bruto) e o falso vermelho do bruto (`legit-leilao-judicial` ligado a `falso-leilao-de-veiculos`) some. Resta `legit-codigo-proprio`, que subiu de verde para amarelo, ligado a `whatsapp-pedido-de-codigo` (candidato à etapa 3), e `consignado-informal`, que aponta a ficha vizinha `devolucao-de-emprestimo` sem mudar a faixa.

- **Feito (etapa 3, parte 1):** campo opcional `situacoesLegitimas` nas fichas (schema, prompt e trava contra cópia), com duas situações reais por ficha escritas com ajuda da IA a partir da orientação e das fontes de cada uma. Não entra no embedding: busca e limiar inalterados, índice regravado sem vetor novo. `avaliar-analise` ganhou `--sufixo` e `--sem-base-de` (refaz só a análise com a base). Detalhes em `docs/calibracao-recuperacao.md`, seção "Situações legítimas nas fichas".
- **Resultado:** com a base, as 26 legítimas ficaram verdes (`legit-codigo-proprio` deixou de ser ligado ao golpe do código) e nenhum golpe mudou de faixa. As correspondências certas foram de 53 para 50, numa única repetição, com variação visível entre execuções; o falso advogado (sem ficha) foi ligado ao falso prêmio.
- **Repetição (3×, 5 mensagens, com e sem as situações):** o ganho não se confirmou (sem as situações, o código próprio também não foi ligado ao golpe) e uma perda se confirmou (`emprego-informal` perdeu a ficha nas 3, sem mudar de faixa). As demais diferenças eram variação do modelo. Detalhes na mesma seção.
- **Decisão (2026-11-12):** as situações legítimas saíram do prompt; o campo fica nas fichas, guardado. O conteúdo enviado ao modelo voltou a ser o de antes da etapa 3. O "vetor por gatilho" segue para depois.
- **Etapa 4 (feita, 2026-11-12):** `comprovante-pix-falso`, `falso-sequestro` e `falso-consignado-inss` revisados pela curadoria e indexados (21 fichas, 3 embeddings novos). Com a base: 63 de 63 golpes detectados (o comprovante falso saiu do verde para o vermelho), 55 correspondências certas (eram 53) e as 26 legítimas verdes. Detalhes em `docs/calibracao-recuperacao.md`, seção "Fichas novas".
- **Histórico da etapa 4:** rascunho `functions/base-conhecimento/rascunhos/comprovante-pix-falso.json`, escrito com ajuda da IA a partir de páginas da Cielo, da Serasa e do Neon (as matérias de imprensa que citam a Febraban não abriram para leitura). Categoria `outro_golpe`. Passa na validação, exceto a curadoria em branco, e na trava contra cópia. Só entra no índice depois de revisado. Ao entrar, a mensagem `fora-comprovante-falso` do conjunto de teste deixa de ser "fora da base": a equipe decide se troca o rótulo dela ou escreve outra mensagem para medir a ficha.

> **Pontos para a equipe:**
> - O conjunto foi escrito com ajuda da IA e não substitui mensagens de outras pessoas. No relatório acadêmico, deixar claro que a medida usa mensagens sintéticas.
> - O limiar não foi alterado: o conjunto de teste serve para medir, não para ajustar.

### Plano de orientação e perfil (2026-11-12)

A equipe propôs quatro melhorias no app. Duas entram agora, como requisitos do MVP registrados em `docs/requisitos.md`: **RF13** (tutorial de primeiro uso) e **RF14** (perfil e preferências). As tarefas são T47 a T55 do `docs/BACKLOG.md`. As outras duas ficam para a Fase 10:

- **Página inicial com notícias de golpes:** viável com notícias automáticas de fontes oficiais, lidas por RSS numa Function agendada (exige o plano Blaze). Mostrar só título, fonte, data e link; nunca reescrever nem resumir com IA, porque a licença comum do gov.br veda obras derivadas (conferir em cada fonte). Começar com conteúdo próprio, como o "golpe da semana" tirado das fichas da base.
- **Comunidade:** relato estruturado com mascaramento local, sem imagem no início; links desativados; notícias só como cartão com link; termos de uso; denúncia e moderação desde o primeiro dia (RF11). Comentários só numa segunda etapa.

Ordem: 9.8 e 9.9 (tutorial), depois 9.10 a 9.12 (perfil). Cada prompt é um commit.

### Prompt 9.8 — Tutorial: estrutura, exemplo e análise de link (RF13; T47, T48, T50) (concluído)

**[CLAUDE CODE]**
```
Implemente o RF13 para a análise de link (docs/requisitos.md), tarefas
T47, T48 e T50 do docs/BACKLOG.md.

Estrutura (em lib/features/analise/presentation/tutorial/, e domain/ se
houver regra):
- tutorial em até 4 etapas, com indicador de progresso, botões Voltar,
  Próximo e "Pular"; animações curtas que respeitam a redução de
  movimento do sistema
- marca de tutorial visto em shared_preferences, por usuário e com
  versão (como o consentimento do Prompt 9.2), para reexibir se o
  conteúdo mudar; repositório com interface, para testes
- exibido na primeira abertura de AnalisarLinkPage; botão de ajuda (?)
  na tela para reabrir

Conteúdo do tutorial do link, em linguagem simples (perfil Dona Neuza):
1. onde encontrar o link e como colar ou compartilhar com o Phize
2. o que o Phize confere: endereço parecido com o de empresa
   conhecida, idade do site e reputação no Google Safe Browsing
3. exemplo interativo (abaixo)
4. como ler as três faixas e o aviso de ferramenta de apoio

Exemplo interativo (T50):
- link fictício, sem domínio real de empresa (use .example ou
  semelhante) e sem marca de terceiros
- o resultado sai de CalculadoraScore com sinais fixos do exemplo;
  nenhum peso ou ponto de corte copiado (fonte única:
  docs/score-calibracao.md); nada é chamado na rede nem gravado no
  histórico
- reaproveite o termômetro e os rótulos oficiais (RotulosRisco); o termo
  "Seguro" é proibido

Testes: aparece só na primeira vez; "Pular" e concluir gravam a marca;
o botão de ajuda reabre; o exemplo não chama rede nem histórico e usa os
rótulos oficiais; funciona com letra ampliada (textScaler 1.6) sem
estouro de layout; semântica para leitor de tela nos botões.
```

**Verificação [TERMINAL]:** `flutter analyze` e `flutter test`; abrir a análise de link no emulador duas vezes. Depois commit.

**Feito (2026-11-12):**
- **Estrutura:** `TutorialPage` (`lib/features/analise/presentation/tutorial/`), com até 4 etapas, barra de progresso lida pelo leitor de tela ("Etapa 2 de 4"), Voltar, Próximo, Pular e "Começar" na última. Cada etapa tem uma **cena simulada num celular desenhado** (`MolduraCelular`) e um cartão com a explicação. O conteúdo do celular tem tamanho fixo; a explicação acompanha o tamanho de letra da pessoa. Com a redução de movimento do sistema ligada, nada é animado.
- **Marca de visto:** `TutorialRepositoryLocal`, por usuário, por tipo e com versão (`versaoTutorial`). Concluir, pular ou voltar grava a marca. Se a marca não puder ser lida, o tutorial não abre e a análise segue. A exclusão da conta apaga as marcas.
- **Tela de link:** o tutorial abre na primeira vez, e o botão "?" da barra o reabre.
- **Simulação (revisão de design pedida pela equipe, 2026-11-12):** a pessoa repete o caminho do app no celular desenhado: (1) toca e segura o link numa conversa fictícia e vê "Link copiado"; (2) toca em "Colar" e "Verificar link" na tela simulada do Phize; (3) acompanha as três verificações sendo concluídas uma a uma; (4) lê o resultado e pode trocar entre outros exemplos. Etiquetas pulsantes indicam onde tocar. Pular e Próximo continuam disponíveis o tempo todo: ninguém fica preso na simulação.
- **Exemplos:** três links inventados no domínio reservado `.example`, da loja fictícia "Loja Feliz". O resultado sai de `CalculadoraScore`, sem números próprios, sem rede e sem histórico.
- **"Como ler o resultado":** cartão comum aos dois tutoriais (`ComoLerResultado`, em `etapas_comuns.dart`), com os rótulos de `RotulosRisco` e o aviso permanente.
- **Testes:** 18 novos, incluindo a simulação completa, letra 1,6× num celular pequeno, redução de movimento e ausência do termo "Seguro". Os testes do fluxo de link passam um tutorial já visto.
- **Validação visual:** imagens de cada passo da simulação geradas por teste, com a fonte do app, em letra normal e 1,6×. O emulador não foi usado, porque o app completo exige login.

> **Pontos para a equipe:** revisar os textos do tutorial, que estão em `tutorial_link.dart` e `etapas_comuns.dart`. O exemplo fictício imita uma loja inventada, não uma marca real.

### Prompt 9.9 — Tutorial da análise de print (RF13; T49) (concluído)

**[CLAUDE CODE]**
```
Implemente o tutorial do RF13 para a análise de print, tarefa T49,
reaproveitando a estrutura do Prompt 9.8.

Conteúdo:
1. como tirar o print da conversa e enviar ao Phize (compartilhar ou
   escolher na galeria)
2. o que acontece com a imagem: lida no próprio aparelho, nunca
   guardada; só o texto das mensagens recebidas, com CPF, telefone e
   outros dados escondidos, vai para a análise; nomes não são
   escondidos (limitação do RNF07)
3. exemplo interativo com conversa fictícia, como no 9.8
4. como ler as três faixas e o aviso de ferramenta de apoio

Regras:
- aparece na primeira abertura de AnalisarPrintPage, antes da escolha
  da imagem; a tela de consentimento (Prompt 9.2) continua aparecendo
  ao tocar na galeria, e o tutorial não substitui o consentimento
- não interrompe a análise iniciada por compartilhamento nativo (RF10);
  nesse caminho, oferecer "Como funciona?" na tela de resultado
- imagem ilustrativa desenhada com widgets, sem print real nem logotipo
  de aplicativo de terceiros

Testes: primeira abertura, compartilhamento sem tutorial, ordem entre
tutorial e consentimento, letra ampliada e leitor de tela.
```

**Verificação [TERMINAL]:** `flutter analyze` e `flutter test`; no emulador, abrir a análise de print pela primeira vez e analisar um print compartilhado. Depois commit.

**Feito (2026-11-12):**
- **Simulação, no mesmo estilo do 9.8:** (1) a pessoa "tira o print" de uma conversa fictícia de falso parente, com clarão e aviso "Print salvo na galeria"; (2) toca no Phize no menu de compartilhar; (3) acompanha as etapas reais da análise (`EtapaAnalisePrint`, as mesmas da tela de progresso) e vê **o que sai do celular**: só as mensagens recebidas, com `[TELEFONE]` e `[CPF]` gerados pelo `mascararTextoLocal` real, e o aviso de que a imagem e a resposta da pessoa não saem; (4) lê o resultado e troca entre três exemplos: falso parente, banco fictício e clínica fictícia (faixa verde).
- **Exemplos:** `ExemploTutorialPrint`, com números que não pertencem a ninguém e nomes de empresa inventados. Os sinais são fixos, porque no app quem os aponta é o modelo; o número sai de `CalculadoraScore`. A etapa 4 explica essa divisão (RF07).
- **Ordem com o consentimento:** o tutorial abre na primeira entrada em "Analisar print"; a tela de consentimento continua aparecendo ao tocar em "Escolher print". O tutorial não substitui o consentimento.
- **Compartilhamento (RF10):** o print compartilhado vai direto à análise, sem tutorial. A tela de resultado ganhou o botão "?" ("Como funciona"), que abre o tutorial do tipo analisado. O botão aparece também no resultado de link, que tem o mesmo caminho por compartilhamento.
- **Reaproveitamento:** os nomes dos sinais saíram da tela de resultado para `SinalTextoPrintTitulo` (domínio), usados pelos dois. As peças das cenas comuns aos dois tutoriais ficaram em `cenas_comuns.dart`.
- **Testes:** 6 da simulação, 5 dos exemplos e 3 no fluxo de print (primeira abertura antes do consentimento, botão de ajuda, compartilhamento sem tutorial com "Como funciona?" no resultado). Suíte: 580 testes.
- **Validação visual:** imagens de cada passo geradas por teste, com a fonte do app, em letra normal e 1,6×. Emulador não usado (o app completo exige login).

> **Pontos para a equipe:** revisar os textos do tutorial em `tutorial_print.dart`. A dica de captura de tela ("botão de ligar e de abaixar o volume") vale para a maioria dos Android; o iPhone usa outra combinação.

### Prompt 9.10 — Perfil: reorganização e nome de exibição (RF14; T51, T52) (concluído)

**[CLAUDE CODE]**
```
Implemente o RF14, tarefas T51 e T52 do docs/BACKLOG.md.

- a aba Conta passa a abrir a tela de Perfil, com seções: Identificação,
  Segurança, Acessibilidade, Aprender, Privacidade e dados, Sobre. Nesta
  etapa, preencha Identificação e Privacidade e dados; as demais ficam
  para os Prompts 9.11 e 9.12 (sem seção vazia na tela)
- Privacidade e dados reúne o que hoje está em MeusDadosPage:
  exportar, excluir, privacidade da análise de print e sair
- Identificação: nome de exibição opcional (até 40 caracteres, sem
  validação de nome real), e-mail só para leitura com selo de verificado
  ou não, e forma de login (e-mail ou Google)
- o nome vai para users/{uid}.nomeExibicao; inclua-o na exportação do
  RF12 e confirme que a exclusão o remove
- restrinja em firestore.rules os campos graváveis de users/{uid} aos
  previstos (uid, email, createdAt, nomeExibicao), com tipo e tamanho;
  isso resolve a pendência técnica correspondente
- nenhum outro dado pessoal novo (sem foto, telefone, CPF, nascimento)

Testes: salvar, limpar e limite do nome; exportação com o nome; regras
recusando campo extra ou nome longo (teste das regras no emulador do
Firestore, se o projeto já tiver esse tipo de teste; senão, registre como
pendência).
```

**Verificação [TERMINAL]:** `flutter analyze` e `flutter test`; no emulador, editar o nome, exportar e conferir o arquivo. Depois commit; publicar as regras novas junto com o próximo deploy.

**Feito (2026-11-12):**
- **Tela de Perfil:** `PerfilPage` substitui "Meus dados"; a aba e a rota passaram a se chamar Perfil (`AppRoutes.perfil`). No topo, um cartão com a inicial, o nome (ou "Olá!"), o e-mail e o selo de e-mail verificado ou não. Seções **Identificação** (nome de exibição, e-mail e forma de login) e **Privacidade e dados** (exportar, privacidade da análise de print, excluir conta), e "Sair da conta" no fim.
- **Nome de exibição:** opcional, até 40 caracteres, sem conferência de nome real. Espaços sobrando são removidos, e campo vazio apaga o nome (`nome_exibicao.dart`). Fica em `users/{uid}.nomeExibicao`, entra na exportação e sai com o documento na exclusão da conta.
- **Identificação sem rede:** e-mail, verificação e forma de login vêm do Firebase Authentication (`ContaRepository.identidade`); só o nome é lido do Firestore.
- **Regras do Firestore:** o perfil passou a ter lista fechada de campos (`uid`, `email`, `createdAt`, `nomeExibicao`), e depois do cadastro só o nome pode mudar, com tipo e tamanho conferidos. Conferidas no emulador do Firestore com 18 casos, entre aceitos e recusados: `tool/regras_firestore/conferir_perfil.mjs` (exige Java 11 ou mais novo; o do Android Studio serve).
- **Testes:** 13 novos (nome, identificação, exportação) e os testes de "Meus dados" adaptados ao Perfil. Suíte: 593 testes.
- **Validação visual:** imagens da tela com nome, de conta Google sem nome e com letra 1,6×, geradas por teste. Emulador do app não usado (exige login).

> **Pontos para a equipe:** as regras novas só valem depois de publicadas no console. Contas criadas antes desta versão continuam válidas, porque já têm os três campos do cadastro.

### Prompt 9.11 — Perfil: segurança e acessibilidade (RF14; T53, T54) (concluído)

**[CLAUDE CODE]**
```
Implemente as seções Segurança e Acessibilidade do RF14, tarefas T53 e
T54.

Segurança (só para contas de e-mail e senha):
- trocar senha: pede a senha atual (nova autenticação no Firebase), a
  nova com a regra do RF01 e a confirmação; erros em português, sem
  detalhes técnicos; a troca não conta como tentativa de login do
  LoginAttemptTracker
- reenviar e-mail de verificação, com espera mínima entre envios
- contas do Google não veem a troca de senha

Acessibilidade:
- tamanho da letra: normal, grande e muito grande (textScaler aplicado
  no MaterialApp); conferir todas as telas no maior tamanho
- tema: claro, escuro ou do sistema; criar a variante escura em
  lib/core/theme/app_theme.dart, mantendo o contraste das cores e dos
  rótulos das três faixas
- preferências só no dispositivo (shared_preferences), sem Firestore

Testes: troca de senha com senha errada, fraca e certa; contas Google
sem a opção; preferências persistidas e aplicadas; telas principais sem
estouro de layout no maior tamanho e no tema escuro.
```

**Verificação [TERMINAL]:** `flutter analyze` e `flutter test`; percorrer as telas no emulador com letra muito grande e tema escuro. Depois commit.

**Feito (2026-11-12):**
- **Segurança:** "Trocar senha" pede a senha atual (nova autenticação no Firebase), a nova com a regra do RF01 e a repetição; o diálogo fica aberto com o erro em português ("Senha atual incorreta.") e nunca mostra detalhe técnico. A troca passa por `ContaRepository.trocarSenha` e não toca o `LoginAttemptTracker`. Contas só do Google veem um aviso de que a senha é cuidada pelo Google.
- **Verificação do e-mail:** "Reenviar e-mail de verificação" aparece só para conta de e-mail e senha não verificada, com espera de 60 segundos entre pedidos (`EsperaReenvio`), além do limite do próprio Firebase. Ao abrir, o perfil busca o estado atual da conta (`atualizarIdentidade`), para o selo mudar depois de verificar o e-mail.
- **Tamanho da letra:** Normal, Grande (1,3×) e Muito grande (1,6×), aplicados a todas as telas pelo `builder` do `MaterialApp`. Vale o maior entre o tamanho do app e o do celular: o app nunca diminui a letra já ampliada no aparelho.
- **Tema:** claro, escuro ou igual ao do celular. Variante escura em `app_theme.dart`, com as cores da marca numa extensão de tema (`context.cores`); as telas deixaram de usar cor fixa. As faixas de risco ganharam tons claros para texto no escuro (`FaixaRisco.corTextoEm`), com contraste de pelo menos 4,5:1 conferido por teste. A tela simulada dentro do tutorial continua clara, como imagem do app.
- **Preferências:** só no aparelho (`PreferenciasRepositoryLocal`, `shared_preferences`), lidas antes do primeiro quadro; valem para o aparelho, e não para a conta. Falha ao gravar mantém a escolha até fechar o app, com aviso.
- **Correção:** a tela "Analisar print" não rolava e estourava com letra muito grande em celular pequeno; agora rola.
- **Testes:** 54 novos. Troca de senha (certa, atual errada, fraca, repetição diferente, falha inesperada, cancelar, conta Google), reenvio e espera, preferências gravadas e aplicadas, e as telas principais e os dois tutoriais sem estouro de layout com letra muito grande nos dois temas (`test/core/telas_acessibilidade_test.dart`). Suíte: 647 testes.
- **Validação visual:** imagens do perfil, do resultado, do tutorial e do diálogo de senha no tema escuro, geradas por teste. Emulador do app não usado (exige login).

> **Pontos para a equipe:** a espera de 60 segundos entre reenvios é provisória, como a do bloqueio de login (RF02). Revisar o tom das cores escuras com a identidade visual.

### Prompt 9.12 — Perfil: aprender e sobre (RF14; T55) (concluído)

**[CLAUDE CODE]**
```
Implemente as seções Aprender e Sobre do RF14, tarefa T55.

Aprender:
- "Ver tutorial da análise de link" e "Ver tutorial da análise de
  print" (reabrem os tutoriais do RF13)
- "Como o Phize calcula o risco": tela que explica, em linguagem
  simples, os sinais de texto e de link, que o número vem de uma regra
  fixa do app e não da IA (RF07), as três faixas com os rótulos
  oficiais e o que acontece quando uma verificação não é concluída.
  Sem pesos nem pontos de corte: a fonte única é
  docs/score-calibracao.md

Sobre:
- versão do app (package_info_plus ou equivalente)
- aviso permanente de ferramenta de apoio à decisão
- contato da equipe e política de privacidade: só se a equipe já tiver
  o texto aprovado; caso contrário, não exibir e registrar a pendência

Testes: botões dos tutoriais, ausência do termo "Seguro", nenhum número
de peso na tela de explicação.
```

**Verificação [TERMINAL]:** `flutter analyze` e `flutter test`. Depois commit.

**Feito (2026-11-12):**
- **Aprender:** "Ver tutorial da análise de link" e "da análise de print" reabrem os tutoriais do RF13, mesmo já vistos. "Como o Phize calcula o risco" (`ComoCalculaRiscoPage`, em `analise/presentation/pages/`) explica em linguagem simples os 8 sinais de texto e os 3 de link (títulos vindos dos próprios enums), que a IA aponta os sinais e uma regra fixa do app dá o número, as três faixas com os rótulos oficiais, que basta um sinal para sair do verde, e a regra de verificação não concluída. Nenhum peso nem ponto de corte: só os extremos 0 e 100 aparecem, conferido por teste.
- **Sobre o Phize:** versão do app (`package_info_plus`, nova dependência) e o aviso permanente de ferramenta de apoio. Contato e política de privacidade **não exibidos**: ainda não há texto aprovado (registrado em Decisões Pendentes).
- **Testes:** 11 novos (tutoriais reabertos e marcados como vistos, explicação com sinais e faixas, ausência de "Seguro" e de números de peso, versão e falha ao lê-la, explicação sem estouro com letra muito grande nos dois temas). Suíte: 658 testes.

> **Pontos para a equipe:**
> - ~~Aprovar o texto dos tutoriais~~ — **tutorial aprovado (2026-11-16).** Texto da tela "Como o Phize calcula o risco" aprovado (2026-11-16).
> - A política de privacidade e o contato da equipe ainda não existem como texto aprovado.
> - O nome de exibição só terá uso visível na comunidade (Fase 10); até lá, aparece no perfil e na exportação.

### Teste dos fluxos no emulador (2026-11-12)

Build de debug no emulador Android (API 37), com Functions, Auth e Firestore emulados, Safe Browsing e Gemini no nível gratuito. Só conteúdo fictício: o endereço de teste oficial do Google e prints de `build/prints_sinteticos/`.

**Funcionou:**
- Cadastro, saída, login (senha errada recusada com "E-mail ou senha incorretos."), exclusão da conta: depois dela não sobra conta no Auth nem documento em `users` ou `analises`.
- Tutoriais do link e do print abrem sozinhos na primeira vez, com as interações das cenas; "Pular" funciona; reabrem pelo Perfil.
- Análise de link: o endereço de teste do Safe Browsing deu 70, "Alto risco de golpe"; idade do domínio pelo RDAP.
- Análise de print: consentimento antes da primeira escolha, seletor de fotos do Android, OCR, Gemini (1,9 s na Function): 90, "Alto risco de golpe", com três sinais e as frases destacadas.
- Compartilhar um link de outro app (RF10) abre direto o resultado.
- Histórico e detalhe; o Firestore guarda só score, faixa, categoria (print), explicação, tipo e data (RNF07, etapa 4).
- Perfil: nome de exibição gravado e aceito pelas regras novas; reenvio da verificação e a espera de 60 s; depois de verificar o e-mail no emulador, o selo muda sozinho; troca de senha (atual errada recusada; a nova vale no login seguinte e a antiga deixa de valer); tema escuro e letra muito grande em todas as telas, mantidos depois de fechar o app à força; versão 1.0.0 (1).
- `flutter build apk --release` gera o APK.

**Achados:**
- **Corrigido — primeira consulta de reputação depois de ligar os emuladores dava "verificação não concluída" por tempo limite.** O emulador só inicia cada Function na primeira chamada, e a partida passa dos 5 s de `timeoutConsulta` (o aquecimento das duas levou 14 s); as chamadas seguintes levam menos de 0,4 s. O tempo limite não foi aumentado, porque o RF03 exige o status do link em menos de 5 s. Em vez disso, `tool/emuladores/aquecer_functions.sh` chama as Functions sem login e sem conteúdo logo depois de ligar os emuladores, passo 2 de `docs/emulador-local.md`. Conferido: emuladores religados, aquecidos, e a primeira análise do app deu 70, com a Function em 0,35 s.
- **Corrigido:** a tela de consentimento mandava mudar a escolha "na aba Conta"; a aba se chama Perfil desde o Prompt 9.10.
- **Corrigido — títulos com letra muito grande:** a tela de explicação passou a se chamar "Cálculo do risco" na barra superior (o item do perfil mantém o nome completo); o diálogo de exclusão passou a "Excluir sua conta?", com "Para confirmar, digite sua senha." acima do campo "Senha". Conferido no emulador.
- **Sem correção no código:** o print do golpe do Pix enviado por engano saiu com tipo "Outro golpe", o que está certo pela lista fechada de `docs/categorias-ameaca.md`, que não tem categoria para esse golpe. Criar uma categoria é decisão da equipe (registrada em Decisões Pendentes). O trecho destacado reproduz um erro do OCR ("pixX"), limitação já declarada do reconhecimento embarcado.
- Não testados: login com Google (exige conta Google no emulador), exportação dos dados (abre a folha de compartilhar do Android), bloqueio após 5 tentativas de login (coberto por teste automático) e compartilhamento de imagem.

### Fechamento da Fase 9 (2026-11-16)

**Decisões da equipe (2026-11-16):**

- **Tutorial (RF13) aprovado.**
- **Próprio `gov.br` mantido como verificação concluída** (achado 1 do ensaio): a idade do domínio é dada como concluída sem sinal quando o endereço é a própria categoria do Registro.br, e o link pode chegar ao verde.
- **Sem sessões com participantes** (item 5): o roteiro (`docs/roteiro-testes-pessoas.md`) fica como registro do ensaio e dos achados.
- **Sem logo** (item 6).

**Falta decidir para fechar a fase:**

1. ~~Aprovar o texto da tela "Como o Phize calcula o risco"~~ — **aprovado (2026-11-16).**
2. ~~**RNF03 (5 segundos)**~~ — **feito (2026-11-16):** limitação de escopo acadêmico declarada no RNF03 de `docs/requisitos.md` e de `docs/relatorio-completo.md`, e citada na seção 6 de `docs/arquitetura.md`.
3. ~~**RAG na análise de link**~~ — **feito (2026-11-16):** UC03 ajustado (`docs/casos-de-uso.md`, passo 6): a explicação do link vem de textos da aplicação, sem base de conhecimento nem modelo de linguagem. A equipe deve conferir se a imagem do diagrama de sequência (`docs/uml.md`, "Print ou Link") mostra o link passando pelo modelo.
4. **Teste em Android real** — **declarado como não feito, por enquanto (decisão de 2026-11-16).** Fica pendente a validação do RNF06 em aparelho (OCR com prints reais em tema claro e escuro) e do compartilhamento pelo WhatsApp. Quando for feito, o jeito mais simples e gratuito é a depuração por Wi-Fi (Android 11+) com `adb reverse` para os emuladores do computador, sem mudança no projeto.
5. ~~**Login com Apple**~~ — **decidido (2026-11-16): não haverá.** RF01 de `docs/requisitos.md` e de `docs/relatorio-completo.md` e a tarefa T02 do `docs/BACKLOG.md` ajustados.
6. **Ícone do app:** decisão da equipe (2026-11-16): fica para o fim. Hoje só o Android tem o ícone provisório, com a letra "p".

**Situação (2026-11-16):** com as decisões acima, a Fase 9 está fechada no app. Ficam para o fim, por decisão da equipe, o ícone e as mudanças na documentação fora do repositório.

**Documentos sincronizados (2026-11-16):** RF13 e RF14 em `docs/relatorio-completo.md`; em `docs/arquitetura.md`, a organização do texto do print (seção 3.1) e a atualização da base por nova publicação das Functions (seção 3.2 b). **Falta, fora do repositório, com a equipe (últimas a serem feitas, decisão de 2026-11-16):** .docx acadêmicos (RNF07, RF13, RF14 e as mudanças de 2026-11-16: RNF03, RF01 sem Apple, UC03 passo 6), a imagem do diagrama de classes (`nomeExibicao`) e a conferência da imagem do diagrama de sequência ("Print ou Link") com o novo UC03.

**Não bloqueiam:** validação das tabelas v1.0 (pesos do score, categorias de ameaça, limite de texto do OCR, calibração da busca); valores provisórios (bloqueio de login de 15 min, espera de 60 s entre reenvios, não bloquear e-mail não verificado); categoria própria para o "Pix enviado por engano". Só importam numa publicação: política de privacidade e contato no "Sobre" e logo oficial do Google no botão de login.

### Achados de produto do ensaio (2026-11-16)

Observados no ensaio dos testes com pessoas (`docs/roteiro-testes-pessoas.md`, seção 11). Todos tratados em 2026-11-16.

1. ~~**Links oficiais `www.gov.br/...` dão amarelo.**~~ **Corrigido em 2026-11-16.** Causa: o app tratava `gov.br` como domínio registrável e consultava a categoria no RDAP, que não tem data de registro. A lista de categorias `.br` também tinha só 5 itens (com, gov, org, net, edu), e por isso `www.tse.jus.br` consultava `jus.br`. Agora `lib/shared/domain/dominio_registravel.dart` traz as 147 categorias do Registro.br (Lista de Sufixos Públicos); quando o endereço é a própria categoria, a idade é dada como concluída sem sinal, com explicação na tela. Conferido no emulador: `www.gov.br/inss` deu 0, verde. **Decisão da equipe (2026-11-16):** mantido; o próprio `gov.br` conta como verificação concluída.
2. ~~**Tutorial do link diferente da tela real.**~~ **Corrigido em 2026-11-16:** a tela "Analisar link" ganhou o botão "Colar" dentro do campo, como na cena do tutorial (desenho pedido pela equipe em 2026-11-12). Ele lê a área de transferência só quando tocado; sem nada copiado, explica como copiar o link. Conferido no emulador.
3. ~~**Resultado do link mostra o motivo do vermelho por último.**~~ **Corrigido em 2026-11-16:** as verificações aparecem em ordem de importância: as que encontraram sinal, depois as não concluídas e por último as sem sinal (o tutorial segue a mesma ordem). Conferido no emulador: a lista do Google aparece primeiro, na primeira tela.
4. ~~**"Está demorando um pouco mais que o normal" aparece cedo.**~~ **Corrigido em 2026-11-16.** Causa: os 10 segundos do aviso começavam a contar ao tocar em "Escolher print", com a galeria ainda aberta; o tempo de escolha entrava na conta. Agora a contagem começa quando a imagem é escolhida. Conferido no emulador com 20 segundos na galeria: sem aviso. Na mesma conferência apareceu um defeito anterior: quando um sinal tinha duas frases destacadas, a tela de resultado quebrava (chave repetida; bloco vermelho em depuração, cinza na versão final). Corrigido junto, com teste.
5. ~~**Navegação depois do resultado.**~~ **Corrigido em 2026-11-16:** a tela de resultado ganhou o botão "Voltar ao início", sempre visível no rodapé; ele leva ao Início num toque e fecha as telas abertas por baixo, inclusive resultados anteriores de compartilhamento. Conferido no emulador: depois do botão, "voltar" no Início sai do app, sem resultado por baixo.
6. ~~**Ícone laranja de interrogação no resultado verde.**~~ **Corrigido em 2026-11-16:** o estado vazio do resultado de print usa um ícone neutro de informação, na cor de texto secundário do tema (vale também no tema escuro). Continua sem ícone de confirmação, como pede a correção D2 da Fase 6.3. O "?" laranja segue só nas verificações de link não concluídas, onde é aviso de fato. Conferido no emulador com o print 3.
7. ~~**Botão do aviso de privacidade abaixo da dobra.**~~ **Corrigido em 2026-11-16:** "Entendi e concordo" e "Agora não" ficam fixos no rodapé, e o texto rola acima deles. Teste novo em tela de 360×640. Conferido no emulador.
8. ~~**Erros do OCR nos trechos destacados.**~~ **Tratado em 2026-11-16 (decisão da equipe: aviso na tela).** Causa: o ML Kit às vezes junta palavras curtas mesmo em print nítido ("nascimento e a" → "nascimentoea"), e a frase destacada só aparece se existir igual no texto lido, então o erro passa adiante. O aviso abaixo das frases passou a dizer que elas são lidas do print e podem ter pequenos erros de leitura (RNF06, limitações declaradas). Os sinais e o score não dependem das frases. Alternativa não adotada: permitir ao modelo corrigir só espaços, com a Function comparando sem espaços; exigiria mudar o prompt e medir no Gemini.

---

## FASE 10 — EXPANSÃO (PÓS-MVP)

Comunidade (RF05, RF06, RF08, RF09, RF11, RF15, RF16; UC05, UC07–UC10), golpe da semana (RF17) e curadoria dos reportes (RNF05). Plano definido em 2026-11-16. Projeto só com recursos gratuitos: as Functions seguem no emulador local (gatilhos do Firestore funcionam lá; agendamento não dispara sozinho) e só conteúdo fictício circula, inclusive na comunidade.

### Decisões da equipe (2026-11-16)

1. **Print no reporte:** só o texto extraído e mascarado no dispositivo; a imagem é descartada, sem envio nem armazenamento (RNF01; o Firebase Storage também exigiria o Blaze). RF05 e T38 ajustados.
2. **Limiar de denúncias:** 3 denúncias de contas distintas ocultam o reporte do feed até revisão (RF11, T44).
3. **Autoria:** anônima no conteúdo público ("Usuário do Phize"); a autoria fica só para editar, excluir (RF16) e exclusão de conta (RF12).
4. **Moderação:** contas da equipe registradas como moderadoras numa lista no Firestore que só a equipe edita.
5. **Notícias:** começar pelo "Golpe da semana" (RF17), com conteúdo das fichas revisadas e rodízio semanal; RSS de fontes externas fica para depois.
6. **Comentários:** fora desta fase; reavaliar no fim.
7. **Marca oficial:** reporte de link cujo domínio é o endereço oficial de uma marca da lista da análise de link é recusado, com explicação (RF05, T56).

**Documentos (etapa 10.0, feita em 2026-11-16):** RF05 e RF11 ajustados e RF15 (pesquisa), RF16 (meus reportes) e RF17 (golpe da semana) criados em `docs/requisitos.md` e `docs/relatorio-completo.md`; UC05 e UC09 em `docs/casos-de-uso.md`; seções 5.5 e 5.7 de `docs/arquitetura.md`; tarefas T38, T44 e T56 a T61 em `docs/BACKLOG.md`. No UC05, a falha de comunicação deixou de prever "cache local para envio posterior", que contrariava o RNF07 (etapa 3): o reporte fica só em memória e o app oferece nova tentativa.

### Etapas

| Etapa | Entrega | Tarefas |
| --- | --- | --- |
| 10.0 | Requisitos e documentos (feita) | — |
| 10.1 | Modelo de dados e regras do Firestore (reportes, votos, denúncias, moderadores), com testes das regras no emulador (feita) | T39 (base) |
| 10.2 | Reportar golpe: link com hash, relato e print mascarados, aviso de duplicado, recusa de marca oficial (feita) | T36, T37, T38, T39, T56 |
| 10.3 | Aba "Comunidade": feed ("Em alta" e "Mais recentes"), detalhe, curtir e compartilhar (feita) | T40, T41, T42 |
| 10.4 | Denúncia, ocultação automática (gatilho na Function) e tela mínima de moderação (feita) | T43, T44, T45 |
| 10.5 | Pesquisa, "Meus reportes" (editar e excluir) e reportes na exportação e na exclusão de conta (feita) | T57, T58, T59, T60 |
| 10.6 | Cartão "Golpe da semana" na tela inicial (feita) | T61 |
| 10.7 | Curadoria: reporte aprovado entra na base de conhecimento pela moderação (feita; plano mudou em 2026-11-17, ver a seção da etapa) | T46 |
| 10.8 | Comentários (fora da fase, decisão da equipe de 2026-11-17) | — |

A barra inferior passa a ter quatro abas: Início, Comunidade, Histórico e Perfil.

### Atualização da documentação (2026-11-17)

Os .docx acadêmicos (em `docs/DOCS/`, fora do git) eram anteriores até à decisão do OCR embarcado (2026-10-07): ainda citavam Google Cloud Vision, remoção de EXIF, "cache local para envio posterior", login com a Apple e histórico com o texto analisado. A comparação com os `.md` mostrou que todo texto presente só nos .docx era versão antiga, já substituída nos `.md`, que são a fonte (CLAUDE.md, seção 7).

- **Textos:** seis .docx levados ao texto dos `.md` como **alterações controladas** do Word, com a formatação original mantida; os originais (`_corrigido.docx`) ficaram intactos e as cópias novas são os `_atualizado.docx`. Com as alterações aceitas, o texto dos sete documentos fica igual ao dos `.md` (conferido por script). O de stakeholders já estava igual. Cada arquivo foi aberto no Word e conferido em PDF.
- **Diagramas:** os cinco diagramas do UML refeitos em Mermaid (`docs/diagramas/*.mmd`, com as imagens `.png`) e trocados no .docx do UML também como alteração controlada:
  - casos de uso com pesquisa, "Meus reportes", denúncia, moderação, "Golpe da semana", tutorial e perfil;
  - sequência da análise com o OCR e o mascaramento no aparelho e o score calculado no app;
  - cadastro com o login Google;
  - reportes com a hash, a incidência e a retirada da base;
  - classes sem `textoAnalisado` nem autor no reporte, e com as entidades da comunidade.
- **Legendas do UML (`docs/uml.md`):** duas frases corrigidas. A da sequência dizia que a IA devolve o Score de Risco, mas pelo RF07 ele é calculado no app. A das classes citava a "classificação de táticas como o mimetismo visual", que não é categoria do sistema.
- **Ferramentas:** scripts em `tool/documentacao/` (README com o passo a passo), para repetir a sincronização quando os `.md` mudarem.

> **Para a equipe:**
> - Abrir cada `_atualizado.docx` no Word, revisar as alterações (Revisão > Alterações) e aceitar. O autor das alterações aparece como "Claude (atualização da documentação)".
> - Depois de aceitar, conferir a numeração das páginas e o sumário, se houver.
> - O ícone continua pendente (decisão de deixá-lo para o fim).

**Fase 10 fechada (2026-11-17).** Etapas 10.0 a 10.7 concluídas. Decisões de fechamento da equipe: a etapa 10.8 (comentários) fica fora da fase; a orientação padrão das entradas da comunidade foi aprovada como está; reporte aprovado e editado pelo autor continua aprovado. Os documentos do repositório foram atualizados em cada etapa; falta levá-los aos .docx acadêmicos e às imagens dos diagramas.

### Etapa 10.1 — Modelo de dados e regras (concluída, 2026-11-16)

- **Modelo:** `docs/comunidade-dados.md`. Reporte público em `reportes/{id}`, sem autor e sem link em texto puro; autoria privada em `users/{uid}/reportes/{id}`; marcas de curtida, denúncia e incidência, uma por conta; `moderadores/{uid}` editável só pelo console; `ameacas/{hash}` para as hashes validadas (RF12).
- **Regras:** `firestore.rules`. Reporte de link usa a hash como identificador (um reporte por link); contadores só sobem de 1 em 1, junto com a marca da conta; só o autor edita título e relato e exclui; só a moderação muda o status e lê ocultos.
- **Testes:** 56 testes das regras contra o emulador do Firestore, num projeto de teste separado (`cd functions && npm run test:regras`). Dependências novas, só de desenvolvimento: `@firebase/rules-unit-testing` 6.0.0 e `firebase` 13.1.0. Os 87 testes da Function seguem passando.

> **Pontos para a equipe:**
> - O `npm audit` aponta vulnerabilidades em dependências indiretas (gRPC, body-parser e outras). As novas são só de desenvolvimento e rodam na máquina local; revisar antes de qualquer publicação.
> - Para moderar, a conta precisa de um documento em `moderadores/{uid}`, criado pela equipe no console do Firestore (ou na interface do emulador).

### Etapa 10.2 — Reportar golpe (concluída, 2026-11-16)

- **Tela:** `ReportarGolpePage` (`lib/features/comunidade/presentation/pages/`), com Link, Relato ou Print, título, tipo de golpe (as 7 categorias, sem "Sem indícios") e texto. Aviso fixo de que o reporte é público, sem nome, e de que só conteúdo de teste deve ser usado. Entrada provisória no Início ("Reportar um golpe à comunidade") até a aba Comunidade (10.3).
- **No aparelho, antes do envio** (`preparacao_reporte.dart`): título e texto passam pelo mascaramento local e têm links trocados por `[LINK]` (função nova `esconderLinks`); o link vira SHA-256 do domínio normalizado; domínio oficial de marca da lista, ou a própria categoria `gov.br`, é recusado com explicação. O print é lido pelo OCR no aparelho e o texto mascarado aparece no campo para revisão; a imagem é descartada logo depois (RNF01).
- **Publicação** (`ReporteRepositoryFirestore`): reporte e autoria gravados juntos; link já reportado vira +1 incidência; a mesma conta não conta duas vezes; falha de envio mantém o reporte só na tela, sem cache.
- **Código compartilhado:** mascaramento, normalização de URL, domínio registrável, marcas conhecidas, categorias e a captura e leitura de imagem passaram de `lib/features/analise/` para `lib/shared/`, por serem usados pelas duas features (CLAUDE.md, seção 6). Pacote `crypto` 3.0.6 passou a dependência direta (SHA-256).
- **Achado na conferência no emulador:** ler um reporte que ainda não existe era negado pelas regras (a condição de status falhava sem documento), e o app mostrava "Link em revisão" para um link novo. Regra corrigida, com teste (57 testes das regras).
- **Testes:** 23 novos no app (preparação, campos gravados, tela); 701 no total. Conferido no emulador: link novo publicado, a variante `www.entrega-taxa.example/?id=9` reconhecida como o mesmo link ("Você já reportou este link"), e o print 4 publicado com `[CPF]` e `[TELEFONE]`; no Firestore, nenhum autor, link ou imagem.

> **Pontos para a equipe:**
> - A comunidade só terá conteúdo fictício (RNF07, limitação de escopo acadêmico): serve para demonstrar o funcionamento, não para medir engajamento.
> - O limiar de 3 denúncias é adequado ao volume pequeno da versão acadêmica; com usuários reais, reavaliar.
> - Ninguém da comunidade é exposto: o feed não mostra link (só a hash é guardada, arquitetura 5.5), nome nem e-mail.

### Etapa 10.3 — Aba Comunidade (concluída, 2026-11-16)

- **Navegação:** a barra inferior passou a ter quatro abas: Início, Comunidade, Histórico e Perfil. O botão provisório "Reportar um golpe à comunidade" saiu do Início; o reporte agora abre pelo botão "Reportar golpe" da aba Comunidade.
- **Feed (RF08, UC07):** `ComunidadePage`, com "Em alta" (mais curtidos, depois os mais novos) e "Mais recentes", até 50 reportes. Cada cartão mostra título, tipo de golpe, data e curtidas, e "Ainda não revisado" nos pendentes. Aviso fixo de que os relatos vêm de pessoas do Phize, sem nome, e de que nem todos foram revisados. Falha de conexão mostra "Tentar de novo"; o próprio Firestore usa o que tiver em cache no aparelho (UC07). O feed recarrega ao voltar do detalhe ou do reporte.
- **Consultas:** filtram o status (`pendente` e `aprovado`), como as regras exigem; sem o filtro, ou incluindo `oculto`, a consulta inteira é recusada (3 testes novos das regras, 60 no total). Os índices compostos estão em `firestore.indexes.json`; o emulador não precisa deles, um projeto publicado sim.
- **Detalhe (RF06, RF09):** `DetalheReportePage`, com autor "Usuário do Phize", relato mascarado, quantas pessoas relataram e aviso de que o conteúdo é da comunidade e não substitui a confirmação com a instituição. Curtir grava +1 com a marca da conta; quem já curtiu vê "Você curtiu", sem novo voto (as regras não permitem desfazer a curtida). Compartilhar abre o menu do aparelho com mensagem padronizada (`mensagem_alerta.dart`): aviso de segurança, título, tipo, relato, número de relatos e a identidade do Phize, sem link.
- **Código compartilhado:** a formatação de data passou a `lib/shared/domain/formatacao_data.dart`, usada pelo histórico e pela comunidade.
- **Testes:** 23 novos no app (mensagem, leitura do documento, feed, detalhe, curtir, compartilhar, e as duas telas no teste de letra muito grande, que apontou um estouro no cartão com letra grande, corrigido); 724 no total. Conferido no emulador: feed com os reportes da 10.2, curtida gravada pelas regras reais, menu de compartilhamento com a mensagem e contagem atualizada no feed.

> **Pontos para a equipe:**
> - Curtida não se desfaz: as regras só aceitam +1, para impedir voto duplicado (RF06). Permitir "descurtir" exige regra e teste novos.
> - "Em alta" ordena só por curtidas, como diz o RF08. Se a equipe quiser contar também as incidências ("também recebi"), é uma mudança pequena na consulta e no índice.

### Etapa 10.4 — Denúncia e moderação (concluída, 2026-11-16)

- **Denúncia (RF11, T43):** "Denunciar este reporte" no detalhe de qualquer alerta, com os quatro motivos das regras: informação falsa ou que não é golpe, conteúdo ofensivo, repete outro reporte, acusa uma empresa ou órgão legítimo. Uma por conta: depois, o botão vira "Você denunciou este reporte". A denúncia grava +1 no reporte junto com a marca da conta e o motivo.
- **Ocultação automática (T44):** Function `ocultarReporteDenunciado` (`functions/src/index.ts`), acionada pela gravação da denúncia. Em transação, passa a `oculto` o reporte **pendente** que chega a 3 denúncias (`LIMIAR_DENUNCIAS_OCULTACAO` em `functions/src/config.ts`; regra em `functions/src/moderacao.ts`). O log traz só o identificador do reporte, nunca texto, motivo ou conta.
- **Moderação (T45):** `ModeracaoPage`, aberta pelo escudo na barra da aba Comunidade, que só aparece para contas em `moderadores`. Listas "Ocultos" (primeira, a dos que esperam revisão), "Pendentes" e "Aprovados"; cada reporte mostra denúncias, curtidas, relatos e a contagem por motivo. Ações: aprovar, ocultar e excluir de vez (com confirmação). Quem barra o acesso são as regras; o botão escondido é só conveniência.
- **Testes:** 6 da regra de ocultação na Function (93 no total); 2 das regras (moderação lista ocultos e lê os motivos; conta comum não), 62 no total; 13 no app (denúncia, moderação e a tela de moderação no teste de letra muito grande), 736 no total.
- **Conferido no emulador:** uma denúncia pelo app e duas de contas fictícias criadas só no emulador, todas pelas regras reais. Na terceira, a Function ocultou o reporte e ele saiu do feed. A conta de teste do app foi registrada como moderadora no emulador (como a equipe fará pelo console); a moderação mostrou o reporte com "Informação falsa ou que não é golpe: 3", e ao aprovar ele voltou ao feed.

> **Pontos para a equipe:**
> - **Reporte aprovado não é ocultado de novo** por novas denúncias: a aprovação já é a revisão manual que o RF11 pede. Se a equipe preferir reocultar com novas denúncias depois da aprovação, é preciso contar só as posteriores (mudança no modelo de dados).
> - **Excluir pela moderação** remove o reporte público, mas não a autoria privada do autor (`users/{uid}/reportes/{id}`), que só o dono apaga, nem as marcas de curtida e denúncia (o Firestore não apaga subcoleções sozinho). Nada disso aparece no app; "Meus reportes" (10.5) deve tratar a autoria de reporte que não existe mais.
> - Para moderar, a conta precisa de um documento em `moderadores/{uid}`, criado pela equipe no console (ou na interface do emulador).

### Etapa 10.5 — Pesquisa, "Meus reportes" e direitos do titular (concluída, 2026-11-17)

**Decisões da equipe (2026-11-17), na exclusão de conta (RF12):**
1. **Reportes da conta:** todos são excluídos, com a autoria. Fica só a hash de link validado pela equipe, em `ameacas`, sem autor.
2. **Curtidas e denúncias da conta** nos reportes de outras pessoas: também são apagadas, com -1 no contador. Para isso, cada curtida e denúncia passa a ter um índice privado da conta (`users/{uid}/curtidas` e `users/{uid}/denuncias`), e as regras passam a aceitar retirar a própria marca junto com o -1. Efeito colateral aceito: as regras passam a permitir "descurtir" e retirar a denúncia (o app não oferece esses botões).

- **Pesquisa (RF15, UC08, T57):** lupa na barra da aba Comunidade. Texto sem espaços que seja um endereço vira link: passa pela mesma normalização e hash do reporte, no aparelho, e só a hash é consultada. O resto vira palavras de busca (sem acento, 3 letras ou mais, até 10), comparadas às palavras do título e da categoria gravadas no reporte. Ocultos não aparecem. Se a hash estiver em `ameacas`, a tela avisa que a equipe confirmou o link como golpe, mesmo que o reporte de origem já tenha sido excluído. Sem resultado, informa e oferece "Reportar golpe".
- **"Meus reportes" (RF16, UC09, UC10, T58, T59):** ícone na barra da aba Comunidade. Mostra a situação de cada reporte (aguardando revisão, aprovado, fora do feed em revisão, removido pela moderação); o autor lê o próprio reporte mesmo oculto (regra nova). Editar muda só título e relato, que passam de novo pelo mascaramento e pela troca de links (`prepararEdicao`); o link não é editável. Excluir pede confirmação irreversível e avisa que a confirmação da equipe sobre o link continua, sem o nome. Reporte já removido pela moderação sai da lista apagando só a autoria.
- **Hash validada:** aprovar um reporte de link na moderação grava a hash em `ameacas` na mesma gravação; ocultar ou devolver a pendente retira. Antes desta etapa, nada gravava `ameacas`.
- **Exportação (RF12, T60):** o arquivo ganhou a seção `comunidade`: os reportes publicados (com a situação), as curtidas, as denúncias (com o motivo) e os "também recebi". O texto do Perfil diz isso.
- **Exclusão de conta (RF12, T60):** antes do perfil e das análises, a conta apaga os próprios reportes e autorias, retira curtidas e denúncias dos reportes de outras pessoas (com -1, ou sem ele se o reporte já não existe) e apaga as marcas de "também recebi". O diálogo de confirmação e o texto do Perfil citam os reportes. Uma falha no meio mantém a pendência, como antes, e a exclusão pode ser retomada.
- **Testes:** 14 novos das regras (76 no total): índice obrigatório, retirada com -1, recusas, reporte já excluído, autor lendo o próprio oculto, consulta da pesquisa e aprovação com hash. 29 novos no app (765 no total): pesquisa, edição, telas de pesquisa, "Meus reportes" e edição (também no teste de letra muito grande) e a exportação com a comunidade.
- **Conferido no emulador**, com a conta fictícia de `docs/emulador-local.md`:
  - a conta curtiu e denunciou o reporte de outra conta fictícia;
  - publicou um link e o achou pela palavra e pela variação `https://www.pagamento-urgente.example/pagar?id=7`;
  - editou o relato com um CPF e um link fictícios, gravados como `Pediram o CPF [CPF] no site [LINK]`;
  - como moderadora, aprovou o próprio link (hash gravada em `ameacas`);
  - excluiu a conta. Depois: reporte, perfil, índices, marcas e credencial removidos; contadores do outro reporte de volta a 0; hash validada mantida.

> **Pontos para a equipe:**
> - `moderadores/{uid}` continua depois da exclusão de uma conta moderadora: só a equipe edita essa lista, pelo console. Remover a pessoa da lista faz parte de desligá-la da moderação.
> - Curtidas e denúncias gravadas antes desta etapa não têm o índice privado e não seriam achadas na exclusão de conta. Na versão acadêmica, os dados do emulador são fictícios e somem quando ele reinicia; numa base real, seria preciso migrar.
> - A pesquisa por palavras faz duas consultas (pendentes e aprovados) e ordena no aparelho, até 50 de cada. Com muitos reportes, rever. Os índices compostos estão em `firestore.indexes.json`.

### Etapa 10.6 — Golpe da semana (concluída, 2026-11-17)

- **Conteúdo (RF17, T61):** `tool/gerar_golpe_da_semana.dart` copia das fichas revisadas (curadoria preenchida) nome, categoria, canais, gatilhos ("frases que costumam aparecer"), pedido financeiro ("o que pedem"), orientação preventiva ("o que fazer") e publicador e título das fontes, sem reescrita, para `assets/conteudo/golpe_da_semana.json`, embutido no app. Ficam de fora quem revisou, os links das fontes e as situações legítimas. Um teste compara o arquivo com as fichas e falha se estiver desatualizado; o passo foi incluído em `functions/base-conhecimento/README.md`.
- **Por que embutido:** a exibição não faz chamada de rede nem envia nada (RF17), funciona sem conexão e não depende da Function. Contrapartida: ficha nova só entra no cartão numa nova versão do app.
- **Rodízio:** semana contada no horário de Brasília, virando na segunda-feira à meia-noite, independente do fuso do aparelho; a ficha é a da posição `semana % total`, em ordem de identificador. Todos os usuários da mesma versão veem a mesma modalidade na mesma semana.
- **Telas:** cartão no Início, abaixo de "Analisar link", com o nome e a primeira frase típica; o toque abre o detalhe com canais, frases, o que pedem, o que fazer, a fonte e a nota de que o conteúdo é revisado pela equipe e muda toda semana. Se o arquivo não puder ser lido, o cartão some e o Início segue normal.
- **Testes:** 16 novos (781 no total): virada da semana, independência do fuso, rodízio, sincronia com as fichas, ausência de quem revisou e de links, curadoria obrigatória, cartão, detalhe e o detalhe no teste de letra muito grande.
- **Conferido no emulador:** semana de 16/11/2026, "Falsa venda em loja, site ou perfil falso", com as seis frases, o pedido, a orientação e a fonte (Febraban).

> **Pontos para a equipe:**
> - Incluir ou retirar uma ficha muda o tamanho do rodízio e, com isso, a ficha das semanas seguintes. Não é problema para a versão acadêmica; se a ordem importar, dá para fixar uma lista de rodízio.
> - O RF17 também prevê notícias de fontes externas como evolução posterior (só título, fonte, data e link). Não entrou nesta etapa.

### Etapa 10.7 — Curadoria dos reportes (concluída, 2026-11-17)

**Decisão da equipe (2026-11-17):** o plano era gerar um rascunho de ficha para revisão. A equipe pediu que o reporte fosse ao RAG sem nova revisão; como o RNF05 exige curadoria humana e a arquitetura (3.2 d) protege contra envenenamento do índice, ficou decidido que **a inclusão expressa pela moderação vale como curadoria**, e o resto é automático. Documentos atualizados: RNF05 e RF17 (`docs/requisitos.md` e `docs/relatorio-completo.md`), arquitetura 3.2 (a), (b) e (d), UC10 e `functions/base-conhecimento/README.md` (seção "Entradas da comunidade").

- **Moderação:** botão "Aprovar e incluir na base", separado de "Aprovar" (que só libera o feed), para relato e print. A tela mostra a situação: incluindo, na base, ou não entrou (com o motivo e "Tentar incluir de novo").
- **Entrada gerada, sem reescrita** (`functions/src/fichaComunidade.ts`): modalidade = título; gatilhos = frases do relato mascarado (até 30, de até 300 caracteres, sem pedaços curtos ou só de marcadores); categoria do reporte; canais e pedido "Não informado"; orientação padrão da categoria; fonte "Reporte aprovado da comunidade Phize" (publicador "Comunidade Phize", sem link); curadoria "Moderação da comunidade", sem nome nem identificador de quem moderou.
- **Functions:** `incluirReporteNaBase` (acionada pelo pedido em `curadoriaComunidade`) gera o embedding e grava `baseComunidade/{id}`, só se o reporte continuar aprovado e com o mesmo texto; `retirarReporteDaBase` (acionada por qualquer gravação em `reportes`) apaga a entrada e o pedido quando o reporte é excluído (autor, exclusão de conta ou moderação), sai de "aprovado" ou tem título ou relato editado. Os logs trazem só o identificador.
- **Consulta:** a análise soma ao `indice.json` as entradas de `baseComunidade`, lidas do Firestore e guardadas por até 30 segundos; uma retirada vale em até 30 segundos. Falha de leitura não interrompe a análise.
- **Regras:** só a moderação cria e lê o pedido, e só para reporte aprovado de relato ou print, junto com a aprovação; o resultado é gravado pela Function; `baseComunidade` não é lida nem gravada pelo app.
- **Golpe da semana:** continua só com as fichas de fontes públicas (`fichas/`); as entradas da comunidade ficam fora.
- **Testes:** 9 na Function (102 no total): frases, recusas, campos padrão, orientação de todas as categorias, sem "Seguro", regra de retirada, filtro e soma dos índices. 7 das regras (83 no total). 4 no app (785 no total): botão, link sem o botão, situação na base e nova tentativa.
- **Conferido no emulador:**
  - na moderação, "Aprovar e incluir na base" no relato fictício "Vaga de emprego pedindo taxa";
  - a entrada foi gravada com o título, a frase do relato, os campos padrão, a fonte "Comunidade Phize" e 768 dimensões;
  - uma mensagem fictícia parecida foi analisada pela Function e apontou `padraoCorrespondente: comunidade-<id>`;
  - ao ocultar o reporte, a entrada e o pedido sumiram.
  - Na mesma sessão, o Gemini gratuito devolveu "indisponível" em algumas análises, inclusive em texto sem relação com a comunidade: oscilação do provedor, não da mudança.

> **Pontos para a equipe:**
> - ~~**Orientação padrão por categoria**~~ — **aprovada pela equipe (2026-11-17)** como está (`ORIENTACAO_PADRAO` em `functions/src/fichaComunidade.ts`, versão 1.0).
> - **Só com conteúdo fictício:** os gatilhos reproduzem o relato, que pode ter nomes não mascarados (RNF07); essas frases vão ao prompt do Gemini nas análises parecidas. Antes de uso com pessoas reais, reavaliar (arquitetura, 3.2 d).
> - ~~**Edição de reporte aprovado**~~ — **decidido (2026-11-17): continua aprovado.** O autor edita título e relato, o reporte segue aprovado no feed, e a entrada da base sai na edição (a moderação pode incluí-lo de novo).
> - **Primeira inclusão demora** no emulador (cerca de 20 s, partida do processo da Function); depois, cerca de 1 s.

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

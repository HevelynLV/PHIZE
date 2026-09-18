# BACKLOG — Projeto Phize

Tarefas técnicas derivadas dos Requisitos Funcionais (RF01–RF12) e Não Funcionais (RNF01–RNF07) descritos em `docs/requisitos.md`, com apoio dos fluxos detalhados em `docs/casos-de-uso.md`. A classificação MVP/Expansão segue estritamente a Seção 2 (Escopo) de `requisitos.md`.

| ID | Tarefa | Requisito de origem | MVP ou Expansão | Depende de |
| --- | --- | --- | --- | --- |
| T01 | Configurar projeto Flutter multiplataforma (Android/iOS) integrado ao Firebase (Authentication + Firestore) | RNF02 | MVP | |
| T02 | Implementar cadastro de usuário (e-mail/senha e provedores sociais Google/Apple), com validação de senha (mínimo 8 caracteres) e envio de e-mail de verificação | RF01 | MVP | T01 |
| T03 | Inicializar o documento do usuário no Cloud Firestore no momento do cadastro | RF01 | MVP | T02 |
| T04 | Implementar login (e-mail/senha e social) com persistência de sessão no dispositivo | RF02 | MVP | T01 |
| T05 | Implementar bloqueio temporário de login após 5 tentativas falhas consecutivas | RF02 | MVP | T04 |
| T06 | Registrar o aplicativo como destino no menu de compartilhamento nativo do sistema operacional para os tipos MIME de imagem e texto | RF10 | MVP | T01 |
| T07 | Implementar retenção em memória do conteúdo recebido por compartilhamento até a conclusão do login, sem gravação em disco, quando o usuário não estiver autenticado | RF10 | MVP | T06, T04 |
| T08 | Implementar roteamento automático do conteúdo recebido (imagem, texto ou link) para o fluxo de análise correspondente | RF10 | MVP | T06 |
| T09 | Integrar a API do Google Cloud Vision para extração de caracteres (OCR) | RNF06 | MVP | T01 |
| T10 | Implementar carregamento da imagem em memória volátil com descarte imediato após o OCR, inclusive em bloco de tratamento de exceção | RNF01, RF04 | MVP | T09 |
| T11 | Implementar verificação de suficiência do texto extraído, interrompendo o fluxo sem transmissão à nuvem quando o volume for insuficiente | RF04 | MVP | T09 |
| T12 | Implementar rotina de mascaramento local (regex) de dados pessoais estruturados: CPF, CNPJ, telefone, e-mail, chave Pix, número de cartão e código de barras de boleto | RNF07 | MVP | T09 |
| T13 | Implementar transmissão do texto mascarado ao provedor de LLM via TLS 1.2+, restrita a APIs corporativas cujos termos vedem uso do conteúdo para treinamento | RNF07 | MVP | T12 |
| T14 | Implementar descarte do texto da memória da aplicação após a resposta da IA, sem gravação em cache, log ou arquivo temporário | RNF07 | MVP | T13 |
| T15 | Constituir a base de conhecimento vetorial inicial de padrões de fraude brasileiros a partir de fontes públicas/oficiais, com curadoria humana | RNF05 | MVP | T01 |
| T16 | Implementar recuperação semântica dos padrões de maior similaridade e injeção no prompt do modelo (RAG) | RNF05 | MVP | T15 |
| T17 | Integrar modelo de linguagem para identificação dos sinais fraudulentos (urgência, ameaça, pedido financeiro, solicitação de dados, falso contato) | RF04 | MVP | T13, T16 |
| T18 | Implementar geração de explicação pedagógica em linguagem clara, objetiva e sem jargões técnicos ou alucinações | RNF04 | MVP | T17 |
| T19 | Implementar destaque das frases suspeitas identificadas na interface | RF04 | MVP | T17 |
| T20 | Definir e versionar a tabela de pesos dos sinais objetivos em módulo único de configuração, com registro das calibragens realizadas | RF07 | MVP | T01 |
| T21 | Implementar função determinística de cálculo do Score de Risco (soma de pesos com teto de 100 pontos) | RF07 | MVP | T20, T17 |
| T22 | Implementar teste automatizado que garanta que entradas idênticas produzam sempre o mesmo Score de Risco | RF07 | MVP | T21 |
| T23 | Implementar componente visual do termômetro de risco com padrão semafórico e rotulagem calibrada das três faixas | RF07 | MVP | T21 |
| T24 | Implementar aviso permanente na tela de resultado informando que a análise é ferramenta de apoio à decisão e não substitui a verificação direta junto à instituição | RF07 | MVP | T23 |
| T25 | Implementar campo de entrada/colagem de URL com validação de formato | RF03 | MVP | T01 |
| T26 | Implementar detecção de mimetismo de domínio (typosquatting) por distância de edição | RF03 | MVP | T25 |
| T27 | Implementar consulta de idade de registro de domínio | RF03 | MVP | T25 |
| T28 | Implementar consulta assíncrona de reputação de domínio (blacklists) | RF03 | MVP | T25 |
| T29 | Implementar exibição individualizada dos sinais verificados em linguagem não técnica, com atribuição da fonte consultada | RF03 | MVP | T26, T27, T28 |
| T30 | Integrar os sinais do URL Checker ao cálculo do Score de Risco | RF03, RF07 | MVP | T28, T21 |
| T31 | Implementar persistência seletiva no histórico (apenas Score de Risco, categoria da ameaça, explicação pedagógica, tipo de entrada e data — sem o conteúdo analisado) | RNF01, RNF07 | MVP | T21, T14 |
| T32 | Implementar feedback visual de carregamento imediato com streaming progressivo, apresentando a primeira porção do resultado em até 5 segundos | RNF03 | MVP | T17 |
| T33 | Implementar tela de consentimento informando a limitação do mascaramento local (nomes próprios e conteúdo livre não são mascarados no dispositivo) | RNF07 | MVP | T12 |
| T34 | Implementar exportação dos dados vinculados à conta em formato legível | RF12 | MVP | T03 |
| T35 | Implementar exclusão definitiva de conta (remoção dos documentos no Cloud Firestore e da credencial no Firebase Authentication) com confirmação explícita de irreversibilidade | RF12 | MVP | T03 |
| T36 | Implementar fluxo de reporte de golpe (URL, print ou relato), concluído em até 3 cliques | RF05 | Expansão | T01 |
| T37 | Implementar normalização do endereço reportado (isolamento de domínio, descarte de parâmetros variáveis) e geração de hash SHA-256 | RF05 | Expansão | T36 |
| T38 | Implementar remoção de metadados EXIF de imagens anexadas ao reporte | RF05 | Expansão | T36 |
| T39 | Implementar registro do reporte com status "pendente" no Cloud Firestore, sem ingresso automático na base de conhecimento | RF05 | Expansão | T37, T38 |
| T40 | Implementar feed público de alertas com título, data e contagem de curtidas, filtrável entre "Em alta" e "Mais recentes" | RF08 | Expansão | T39 |
| T41 | Implementar mecanismo de upvote com prevenção de votos duplicados pela mesma conta e influência na ordenação do feed | RF06 | Expansão | T40 |
| T42 | Implementar compartilhamento externo de um alerta específico via menu de compartilhamento nativo, com mensagem padronizada | RF09 | Expansão | T40 |
| T43 | Implementar mecanismo de denúncia de reportes comunitários, com registro do motivo selecionado e prevenção de denúncias duplicadas pela mesma conta | RF11 | Expansão | T39 |
| T44 | Implementar ocultação automática do feed público de reportes denunciados acima do limiar definido | RF11 | Expansão | T43 |
| T45 | Implementar interface administrativa mínima para aprovação, ocultação ou remoção definitiva de reportes | RF11 | Expansão | T43 |
| T46 | Implementar incorporação dos reportes comunitários validados à base de conhecimento, mediante curadoria humana | RNF05 | Expansão | T39, T15 |

## Decisões não definidas nos documentos (bloqueiam implementação)

- **Limiar de denúncias para ocultação automática (RF11):** o requisito determina que reportes "denunciados acima de limiar definido" sejam ocultados, mas não especifica o valor numérico do limiar. Bloqueia T44.
- **Volume mínimo de texto extraído (RF04 / UC04):** o caso de uso UC04 menciona que "volume inferior ao mínimo configurado interrompe o fluxo", mas nenhum documento define esse valor mínimo. Bloqueia T11.
- **Periodicidade de atualização da base de conhecimento (RNF05):** o requisito exige "processo de atualização periódica documentado", sem definir a frequência nem o processo formal de execução. Impacta o planejamento operacional de T15/T46, sem bloquear a implementação inicial.
- **Critérios de complexidade de senha (RF01):** definido apenas o mínimo de 8 caracteres; não há definição sobre exigência de maiúsculas, números, caracteres especiais ou política de expiração/reuso.
- **Funcionalidade de Pesquisa de Reportes (UC08):** citada apenas no Escopo de Expansão (seção 2.2, "pesquisa") e detalhada em UC08, mas sem RF formal com critérios de aceitação em `requisitos.md`. Não há tarefa correspondente na tabela por ausência de requisito de origem citável.
- **Edição e exclusão de reportes pelo autor (UC09 e UC10):** descritas em `casos-de-uso.md`, mas sem RF/RNF correspondente em `requisitos.md` — não há definição de quais campos são editáveis, nem de condições específicas para exclusão além do exigido para RF05. Não há tarefa correspondente na tabela por ausência de requisito de origem citável.
- **Consulta de Histórico de Alertas (UC06):** a persistência dos dados do histórico está coberta por RNF01/RNF07 (T31), mas não há RF específico definindo critérios de aceitação para a tela de listagem, ordenação cronológica e visualização de detalhe.
- **Dissociação de hashes na exclusão de conta (RF12) vs. dependência de RF05 (Expansão):** RF12 exige que "hashes de ameaças validadas permaneçam na base comunitária de forma dissociada do autor", mas hashes só passam a existir com a funcionalidade de Comunidade (RF05), classificada como Expansão. Não está definido se essa regra de dissociação deve ser preparada no schema já durante o MVP ou implementada apenas junto da Expansão.

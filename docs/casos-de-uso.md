**CENTRO UNIVERSITÁRIO CESUSC**

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: DESCRIÇÃO DE CASOS DE USO**

FLORIANÓPOLIS - SC

2026

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL**

Documento técnico contendo as descrições detalhadas dos Casos de Uso do Projeto Phize, apresentado como requisito de avaliação prático. Orientador: Prof. Sérgio

FLORIANÓPOLIS - SC

2026

# **OBJETIVOS**

A elaboração das descrições de Casos de Uso tem como objetivo principal detalhar e padronizar o comportamento do sistema sob a perspectiva das interações entre os usuários (atores) e as funcionalidades do aplicativo. Este mapeamento transcende a listagem básica de requisitos funcionais, pois documenta o fluxo passo a passo de cada ação, estabelecendo um escopo claro sobre como o software deve operar em cenários ideais (fluxo principal) e como deve reagir diante de erros, restrições ou comportamentos inesperados (fluxos alternativos e exceções).

No contexto deste projeto, essas descrições são fundamentais para alinhar o desenvolvimento entre a interface visual e a infraestrutura de retaguarda (backend e APIs de inteligência artificial). Além de servirem como base fundamental para a futura construção dos diagramas comportamentais da UML — em especial os Diagramas de Sequência —, o detalhamento a seguir garante que as necessidades específicas dos perfis de usuários mapeados sejam rigorosamente traduzidas em rotinas computacionais seguras, mantendo a coesão com a proposta de educação preventiva do ecossistema.

# **DESCRIÇÕES DE CASOS DE USO**

### **UC01: Cadastrar Usuário**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário não autenticado. |
| **Pré-condições** | O aplicativo deve estar instalado no dispositivo móvel e possuir conexão ativa com a internet. |
| **Fluxo Principal** | 1. O usuário acessa a tela inicial e seleciona “Criar Conta”. 2. Preenche os campos obrigatórios e aceita os Termos de Uso/Privacidade. 3. Clica em “Cadastrar”. 4. O sistema valida localmente o e-mail e a força da senha. 5. O app envia os dados criptografados para o Firebase Authentication. 6. O Firebase cria a credencial e retorna o token. 7. O sistema inicializa o documento do usuário no Cloud Firestore. 8. Redirecionamento para a tela principal (Dashboard). |
| **Fluxos Alternativos / Exceções** | E-mail já cadastrado: o sistema exibe aviso sugerindo recuperação de senha ou login. Senha fora do padrão: validação local bloqueia e orienta sobre requisitos mínimos. |
| **Pós-condições** | Usuário devidamente cadastrado, autenticado e com banco de dados inicializado. |

### **UC02: Realizar Login**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário cadastrado. |
| **Pré-condições** | Cadastro prévio válido e conexão ativa com a internet. |
| **Fluxo Principal** | 1. O usuário acessa o aplicativo e seleciona “Entrar”. 2. Insere credenciais (e-mail e senha). 3. O sistema requisita a validação ao Firebase Authentication. 4. O Firebase verifica e retorna o token de sessão. 5. O sistema carrega os dados do Cloud Firestore e libera o acesso ao app. |
| **Fluxos Alternativos / Exceções** | Credenciais inválidas: mensagem de erro e opção “Esqueci minha senha”. Falha de conexão: aviso de impossibilidade de comunicação com o servidor. |
| **Pós-condições** | Usuário autenticado e apto a utilizar os módulos do sistema. |

### **UC03: Analisar Link Suspeito (URL Checker)**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Link copiado para a área de transferência e sistema autenticado. |
| **Fluxo Principal** | 1. O usuário acessa “Analisar Link” e cola a URL. 2. Aciona o botão de verificação. 3. O sistema avalia a anatomia da URL, verificando mimetismo de domínios oficiais (typosquatting). 4. O sistema consulta a idade de registro do domínio junto ao serviço público de dados cadastrais (RDAP). 5. Realiza consulta assíncrona de reputação à Google Safe Browsing API e cruza o endereço normalizado com a base comunitária. 6. Recupera da base de conhecimento os padrões de fraude de maior similaridade e submete o conjunto de sinais ao modelo de linguagem para geração da explicação pedagógica. 7. Calcula o Score de Risco pela função determinística definida no RF07. 8. Exibe o termômetro de periculosidade, a lista de sinais verificados com a respectiva fonte, a correção pedagógica e o aviso de que a verificação não é infalível. |
| **Fluxos Alternativos / Exceções** | Formato inválido: sistema detecta que não é uma URL e solicita reenvio. Nova ameaça: link malicioso inédito gera sugestão de reporte para a Comunidade. Fonte de reputação indisponível: o sistema prossegue com os demais sinais e informa ao usuário que a consulta de reputação não pôde ser concluída. |
| **Pós-condições** | Resultado gravado no histórico de segurança do usuário, sem persistência do endereço analisado em texto puro. |

### **UC04: Analisar Captura de Tela (Prints)**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Captura de tela salva e permissão concedida à galeria do dispositivo, ou conteúdo recebido por compartilhamento nativo (UC11). |
| **Fluxo Principal** | 1. O usuário aciona a análise de imagem, selecionando o print na galeria ou enviando-o diretamente pelo menu de compartilhamento nativo do sistema operacional (RF10). 2. O aplicativo carrega a imagem em memória volátil e aciona o serviço de reconhecimento óptico de caracteres. 3. Realização do OCR e retorno do texto bruto. 4. Aplicação do Zero-Persistence: a imagem é descartada da memória e eventual arquivo temporário gerado pelo seletor de mídia é removido do armazenamento do dispositivo, em bloco de tratamento executado inclusive em caso de falha. 5. Verificação de suficiência do texto extraído. Volume inferior ao mínimo configurado interrompe o fluxo sem transmissão à nuvem. 6. Mascaramento local: o dispositivo aplica a rotina de sanitização definida no RNF07, substituindo por marcadores genéricos os dados pessoais de formato estruturado antes de qualquer transmissão. 7. O texto mascarado é submetido ao modelo de linguagem, acompanhado dos padrões recuperados da base de conhecimento, para análise semântica. 8. Identificação dos gatilhos presentes no conteúdo (urgência, ameaça, pedido financeiro, solicitação de dados, falso contato). 9. Cálculo do Score de Risco pela função determinística definida no RF07 e exibição do diagnóstico, com destaque dos trechos que motivaram cada gatilho. 10. Descarte do texto analisado da memória da aplicação. |
| **Fluxos Alternativos / Exceções** | OCR vazio ou ilegível: aborto do envio ao LLM e solicitação de imagem nítida. Timeout nas APIs: indicador de falha com instrução para tentar mais tarde. Resposta inválida do modelo: retorno fora do formato esperado é descartado, sem exibição parcial ao usuário, com oferta de nova tentativa. Limite de uso do provedor atingido: nova tentativa automática com intervalo progressivo e, persistindo a falha, orientação para repetir a consulta em instantes. |
| **Pós-condições** | Resultado da análise gravado no Cloud Firestore (score, categoria, explicação pedagógica e data). Imagem descartada da memória e texto extraído descartado após o retorno da IA, nenhum conteúdo da conversa é persistido. Usuário orientado quanto à natureza preventiva e não conclusiva do diagnóstico. |

### **UC05: Reportar Novo Golpe (Comunidade)**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Identificação de fraude não catalogada. |
| **Fluxo Principal** | 1. O usuário acessa a “Comunidade de Reporte”. 2. Insere a URL suspeita ou descrição do golpe. 3. Clica em “Denunciar/Reportar”. 4. O sistema normaliza o endereço submetido, isolando o domínio e descartando parâmetros de consulta variáveis, e gera a hash correspondente para fins de indexação e correspondência entre denúncias. 5. Envio da hash e dos dados textuais para o Cloud Firestore, com remoção prévia dos metadados EXIF de eventuais imagens anexadas. 6. Atualização da base comunitária. O reporte permanece com status pendente e não ingressa automaticamente na base de conhecimento, condicionando sua incorporação à curadoria humana prevista na Especificação da Arquitetura. 7. Exibição de mensagem de agradecimento. |
| **Fluxos Alternativos / Exceções** | Ameaça já reportada: incremento do contador de incidência no banco, sem duplicidade. Falha de comunicação: salvamento em cache local para envio posterior. |
| **Pós-condições** | Base contra ameaças expandida de forma criptografada e anônima, com o reporte aguardando validação. |

### **UC06: Consultar Histórico de Alertas**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Existência de análises prévias vinculadas ao perfil. |
| **Fluxo Principal** | 1. O usuário acessa a aba “Histórico”. 2. Consulta assíncrona na coleção do Cloud Firestore. 3. Renderização da lista cronológica de alertas com Scores de Risco. 4. O usuário seleciona um registro. 5. Exibição detalhada da correção pedagógica correspondente. |
| **Fluxos Alternativos / Exceções** | Histórico vazio: exibição de interface orientando a primeira análise. Ausência de imagem: aviso explicativo sobre o princípio de Zero-Persistence. |
| **Pós-condições** | Usuário ciente de suas validações sem comprometimento de armazenamento. |

### **UC07: Visualizar Página de Golpes da Comunidade**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Conexão ativa com a internet. |
| **Fluxo Principal** | 1. O usuário acessa a aba “Comunidade”. 2. Consulta assíncrona aos dados públicos no Cloud Firestore. 3. Retorno de descrições e táticas em alta, sem dados sensíveis e excluídos os reportes ocultados por moderação (RF11). 4. Renderização de um feed interativo contendo os alertas comunitários. |
| **Fluxos Alternativos / Exceções** | Falha de conexão: exibição de dados em cache, se houver, e botão para recarregar. |
| **Pós-condições** | Usuário atualizado sobre as tendências recentes de fraudes virtuais. |

### **UC08: Pesquisar por um Reporte**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | O usuário encontra-se na tela da Comunidade. |
| **Fluxo Principal** | 1. O usuário acessa a barra de pesquisa. 2. Insere palavras-chave ou cola uma URL suspeita. 3. Se for URL, o sistema aplica a mesma rotina de normalização do UC05 antes de gerar a hash de consulta, de modo que variações de parâmetros não impeçam a correspondência. 4. Execução de consulta parametrizada no Firestore. 5. Exibição dos reportes compatíveis com a pesquisa. |
| **Fluxos Alternativos / Exceções** | Nenhum resultado: interface indica ausência do padrão e sugere a criação de um novo reporte (UC05). |
| **Pós-condições** | Dúvida sanada a respeito de uma ameaça isolada. |

### **UC09: Editar um Reporte**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado (autor do documento). |
| **Pré-condições** | Usuário visualizando a seção “Meus Reportes” com itens cadastrados. |
| **Fluxo Principal** | 1. O usuário seleciona a opção “Editar” em um reporte próprio. 2. O sistema carrega os dados no formulário. 3. O usuário altera os textos permitidos. 4. Clica em “Salvar Alterações”. 5. Envio do comando de atualização (update) ao Firestore. 6. Confirmação de sucesso e atualização visual da lista. |
| **Fluxos Alternativos / Exceções** | Violação de privilégios: ação bloqueada pelo Firebase Security Rules. Edição de link: campo bloqueado para manter a integridade da hash. |
| **Pós-condições** | Dados textuais da denúncia devidamente corrigidos no banco comunitário. |

### **UC10: Excluir um Reporte**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado (autor do documento). |
| **Pré-condições** | Usuário visualizando a seção “Meus Reportes”. |
| **Fluxo Principal** | 1. O usuário clica em “Excluir” em um reporte ativo. 2. O sistema exibe aviso (modal) de ação irreversível. 3. O usuário confirma a exclusão. 4. O app envia comando de deleção (delete) ao Firestore. 5. Documento removido do perfil e lista atualizada com aviso de sucesso. |
| **Fluxos Alternativos / Exceções** | Cancelamento: ação abortada no passo 2. Ameaça validada: o reporte é removido da interface e da autoria do usuário. A hash da ameaça, por não constituir dado pessoal, permanece dissociada na base comunitária. Caso o padrão já tenha sido incorporado à base de conhecimento por curadoria humana, sua permanência independe da exclusão do reporte de origem. |
| **Pós-condições** | Reporte desvinculado permanentemente da conta e da visualização pública. |

### **UC11: Analisar Conteúdo por Compartilhamento Nativo**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário. |
| **Pré-condições** | Aplicativo instalado e registrado como destino de compartilhamento para os tipos MIME de imagem e texto. |
| **Fluxo Principal** | 1. O usuário seleciona a mensagem, imagem ou link em aplicativo de terceiros e aciona o menu de compartilhamento do sistema operacional. 2. Seleciona o Phize entre os destinos disponíveis. 3. O aplicativo recebe o conteúdo em memória e identifica automaticamente o tipo de entrada. 4. O fluxo prossegue conforme o UC03, para links e textos, ou conforme o UC04, para imagens, a partir da respectiva etapa de processamento. 5. O resultado é apresentado sem que o usuário precise navegar até a galeria ou colar o endereço manualmente. |
| **Fluxos Alternativos / Exceções** | Tipo não suportado: aviso de que o formato recebido não pode ser analisado. Conteúdo misto: havendo imagem e texto na mesma submissão, o sistema solicita ao usuário a definição do alvo da análise. |
| **Pós-condições** | Análise concluída a partir de ação única do usuário, mantendo-se as garantias de descarte previstas no RNF01 e no RNF07. |

### **UC12: Exportar ou Excluir Dados Pessoais**

| **Parâmetro** | **Descrição** |
| --- | --- |
| **Ator Principal** | Usuário logado. |
| **Pré-condições** | Conta ativa com registros vinculados. |
| **Fluxo Principal** | 1. O usuário acessa a área de conta e seleciona “Meus dados”. 2. Escolhe entre exportar os dados vinculados à conta ou excluir a conta definitivamente. 3. Na exportação, o sistema compila os registros de histórico e perfil em arquivo legível e o disponibiliza ao usuário. 4. Na exclusão, o sistema exibe aviso de irreversibilidade e solicita confirmação explícita. 5. Confirmada a exclusão, todos os documentos vinculados ao identificador do usuário são removidos do Cloud Firestore e a credencial é removida do Firebase Authentication. |
| **Fluxos Alternativos / Exceções** | Cancelamento: ação abortada na etapa de confirmação. Falha parcial na exclusão: o sistema registra a pendência e reprocessa a remoção, mantendo a conta bloqueada até a conclusão. |
| **Pós-condições** | Direitos de acesso e eliminação atendidos conforme o Art. 18 da Lei nº 13.709/2018. Hashes de ameaças validadas permanecem dissociadas na base comunitária, por não constituírem dado pessoal. |
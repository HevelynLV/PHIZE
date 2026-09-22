**CENTRO UNIVERSITÁRIO CESUSC**

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL**

FLORIANÓPOLIS - SC

2026

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL**

Relatório completo do Projeto Phize, contendo introdução, justificativa, objetivos, metodologias, levantamento de requisitos e modelagem, apresentado como requisito de avaliação prático. Orientador: Prof. Sérgio

FLORIANÓPOLIS - SC

2026

# **1 INTRODUÇÃO**

O Brasil vive hoje uma crise de segurança que transcende as barreiras tecnológicas e ataca diretamente a mente dos usuários. Em 2024, mais da metade dos brasileiros (51%) foram vítimas de fraudes digitais. O país registrou mais de 11,5 milhões de tentativas de fraude ao longo do ano, o que equivale a uma ocorrência a cada 2,8 segundos. Apenas os golpes envolvendo transações via Pix causaram um prejuízo estimado em R$ 4,9 bilhões, fazendo mais de 24 milhões de vítimas. Esse cenário revela uma criminalidade cada vez mais sofisticada, focada essencialmente na exploração de falhas humanas e na vulnerabilidade do usuário final.

O grande diferencial das ameaças modernas é a sua sutileza e o uso de engenharia social. Os ataques chegam disfarçados de oportunidades, urgências ou falsos contatos de familiares, manipulando emocionalmente o alvo e construindo falsas relações de confiança. A população idosa sofre de forma desproporcional com essas táticas; segundo dados da Serasa Experian (2025), as tentativas de fraude contra pessoas acima de 60 anos tiveram um aumento de 11,9% no último ano. A vulnerabilidade econômica e tecnológica faz com que aposentados e idosos sejam os alvos prioritários dos golpistas.

Diante dessa evolução, ferramentas de segurança tradicionais se tornaram insuficientes. Antivírus focam em proteger as máquinas contra invasões de sistema, mas não conseguem blindar o usuário contra a persuasão e a linguagem humana. Além disso, o simples acesso à informação teórica — como ler uma notícia alertando sobre um novo golpe — não garante proteção no momento do ataque. No calor do dia a dia, quando as fraudes acontecem de maneira velada e sutil, a vítima não possui mecanismos para comprovar a veracidade do que está acessando, caindo na armadilha por falta de ferramentas práticas de checagem.

# **2 JUSTIFICATIVA**

O objetivo principal desta solução tecnológica consiste em proteger e educar os usuários frente ao crescimento de fraudes e golpes no cenário digital. Mais do que apenas mitigar riscos de forma automatizada ou servir como um canal passivo de notícias sobre crimes virtuais, o que frequentemente mantém o cidadão vulnerável por não saber como agir no momento do ataque, o foco do projeto é viabilizar a prática contínua da proteção. Busca-se estabelecer uma rotina em que o usuário possa ativamente validar a veracidade das informações recebidas no dia a dia, desenvolvendo um hábito preventivo e integrando-se a uma rede de suporte mútuo.

A justificativa para o desenvolvimento desta plataforma reside justamente na superação das limitações das ferramentas de segurança tradicionais, consolidando o seu principal diferencial na aplicação avançada de Inteligência Artificial (IA) para a análise contextual ativa de ameaças. Enquanto os antivírus convencionais atuam de forma restrita ao bloqueio de códigos maliciosos ou invasões de sistema, a inovação deste ecossistema concentra-se na capacidade de interpretar a linguagem humana e desestruturar as táticas de persuasão psicológica empregadas na engenharia social moderna.

Cabe registrar que a adoção de modelos de linguagem, isoladamente considerada, não constitui vantagem defensável, por ser tecnologia acessível a qualquer concorrente mediante contratação de API. O diferencial estruturante do projeto reside na base curada de padrões de fraude praticados no Brasil e na correção pedagógica aplicada no momento exato do risco. Modalidades como o falso parente que alega troca de número, a falsa central de segurança bancária, o boleto adulterado e a devolução de Pix indevido possuem gatilhos linguísticos e contexto operacional específicos, insuficientemente representados nas soluções internacionais disponíveis.

Na prática, a solução se diferencia ao capacitar o software a identificar automaticamente padrões complexos que seriam imperceptíveis ao olho humano ou a softwares de proteção comuns, tais como o mimetismo de domínios oficiais (typosquatting), o senso de urgência artificial e pedidos financeiros anômalos. Desse modo, o projeto justifica-se por preencher a lacuna existente entre a sofisticação dos golpes cibernéticos contemporâneos e a vulnerabilidade comportamental dos usuários, transformando o processamento computacional inteligente em um mecanismo de autodefesa diário, pedagógico e acessível.

# **3 OBJETIVOS**

## **3.1 Objetivo Geral**

O objetivo geral deste projeto consiste em desenvolver um aplicativo móvel de segurança preventiva que proteja e eduque os usuários contra fraudes virtuais e ataques de engenharia social, utilizando inteligência artificial para realizar análises contextuais em tempo real.

## **3.2 Objetivos Específicos**

Para a consecução do objetivo geral, estabelecem-se as seguintes metas específicas:

- Desenvolver um módulo de acesso com cadastro e autenticação segura integrado ao ecossistema Firebase para criptografia de dados e salvamento do histórico de alertas;

- Construir um analisador de links (URL Checker) capaz de realizar consultas assíncronas de reputação, verificar a idade de registro do domínio e avaliar a anatomia das URLs para a detecção de typosquatting;

- Integrar uma camada de inteligência artificial multimodal utilizando a API do Google Cloud Vision para a extração de caracteres (OCR) a partir de capturas de tela;

- Implementar processamento de linguagem natural (PLN) via grandes modelos de linguagem (LLM) acoplados à metodologia RAG para identificar urgência artificial e pedidos financeiros anômalos em textos extraídos;

- Estruturar um mecanismo de Score de Risco que consolide, por função determinística de pesos, os sinais de fraude identificados na análise, apresentando o resultado em componente visual intuitivo (termômetro de risco) acompanhado de rotulagem textual calibrada;

- Desenvolver o conceito de correção pedagógica just-in-time, fornecendo aos usuários explicações didáticas sobre a natureza do perigo identificado;

- Criar uma Comunidade de Reporte colaborativa para que os usuários possam catalogar e registrar novos padrões de golpes em um banco de dados comunitário, dotada de mecanismo de moderação;

- Assegurar a privacidade dos dados em conformidade com a LGPD por meio de três garantias cumulativas: processamento das imagens em memória volátil com descarte imediato, mascaramento local dos dados pessoais estruturados antes de qualquer transmissão à nuvem, e não persistência do conteúdo analisado em base própria, limitando-se o histórico ao resultado da análise.

# **4 METODOLOGIAS DE DESENVOLVIMENTO**

## **4.1 Flutter e Dart**

O Flutter é o framework utilizado para a construção da interface (front-end). Trabalhando em conjunto com a linguagem de programação Dart, esta tecnologia permite o desenvolvimento multiplataforma. Atua diretamente como a camada visual do aplicativo, ou seja, é o módulo que o usuário instala e com o qual interage no celular. A escolha desta tecnologia se justifica por garantir a manutenção de um código único para entregar uma interface fluida, acessível e de alta performance simultaneamente para sistemas Android e iOS.

## **4.2 Google Cloud Vision**

Trata-se de uma API de inteligência artificial multimodal voltada para a visão computacional. A tecnologia permite o mapeamento estrutural da captura de tela enviada e realiza o Reconhecimento Óptico de Caracteres (OCR). Na prática, ela varre a matriz de pixels da imagem e converte os padrões visuais encontrados em caracteres de texto plano, disponibilizando os dados para processamento lógico. Aplicada ao contexto do projeto, é a camada responsável pelo reconhecimento do conteúdo das imagens enviadas pelo usuário.

## **4.3 Modelos de Linguagem (LLMs)**

As APIs de modelos de linguagem atuam como o componente analítico do sistema. Esses modelos recebem o texto já extraído pela camada de OCR, e previamente mascarado no dispositivo, e executam algoritmos de Processamento de Linguagem Natural (PLN) para analisar a semântica da mensagem e detectar indicativos de fraude, como senso de urgência artificial e pedidos anômalos de dinheiro. Cabe destacar que o papel do modelo se limita à identificação dos sinais e à geração da explicação pedagógica: o valor numérico do Score de Risco é calculado por regra determinística implementada na própria aplicação, conforme detalhado na seção 4.8.

## **4.4 Estrutura RAG (Retrieval-Augmented Generation)**

É uma arquitetura de Inteligência Artificial responsável por conectar o modelo a bases de dados externas. Em vez de gerar uma resposta baseada unicamente em seu treinamento prévio, o modelo é alimentado por uma biblioteca especializada em padrões de golpes antes de produzir a resposta final. Aplicada ao projeto, a arquitetura atua nos bastidores da análise de links e prints para calibrar os modelos, garantindo que o veredito final exibido ao usuário seja ancorado em parâmetros de ameaças reais e não em alucinações da máquina.

A base é constituída previamente pela equipe a partir de fontes públicas e oficiais, mantida por processo de atualização documentado e submetida a curadoria humana, de modo que nenhum conteúdo ingressa no índice de forma automática. Essa condição protege o sistema contra o envenenamento intencional da base por meio de reportes falsos.

## **4.5 Firebase (BaaS - Backend as a Service)**

O ecossistema Firebase atua como a plataforma de Backend as a Service (BaaS), abstraindo a configuração de servidores. Foi adotado para gerenciar a arquitetura de retaguarda do projeto, com foco primário na autenticação segura (cadastro e login) dos usuários e na persistência dos dados da comunidade e do histórico.

Registra-se que as chaves de acesso às APIs de terceiros não são embarcadas no pacote do aplicativo. As chamadas aos provedores de inteligência artificial trafegam por camada intermediária gerenciada, de modo que a credencial permaneça sob controle do servidor e não seja extraível a partir do binário distribuído nas lojas de aplicativos.

## **4.6 Cloud Firestore (Banco de Dados NoSQL)**

É um banco de dados não relacional orientado a documentos. Em vez de gravar dados em tabelas rígidas, armazena as informações em coleções flexíveis de documentos, permitindo consultas assíncronas e alta escalabilidade. Dentro do projeto, é empregado estritamente para registrar o resultado das análises vinculadas a cada perfil e armazenar os dados da funcionalidade de Comunidade de Reporte. O conteúdo analisado, seja em imagem ou em texto, não é gravado em nenhuma hipótese.

## **4.7 Tecnologia de Hash**

Tecnicamente, é uma função matemática de via única que processa uma quantidade variável de dados e a transforma em uma sequência de caracteres de tamanho fixo. Dentro do projeto, atua na indexação da base de dados comunitária: a plataforma não salva os links denunciados em texto puro, convertendo-os em hashes no momento do reporte. O endereço é previamente normalizado no dispositivo, com isolamento do domínio e descarte de parâmetros de consulta variáveis, condição necessária para que variações irrelevantes de um mesmo endereço não produzam hashes distintas e impeçam o reconhecimento de uma mesma campanha de fraude.

## **4.8 Cálculo do Score de Risco**

O valor exibido no termômetro de periculosidade resulta de função determinística implementada na aplicação, que atribui pesos previamente definidos e versionados a cada sinal identificado na análise, somando-os com teto de 100 pontos e classificando o resultado em três faixas. A separação entre identificação, a cargo do modelo de linguagem, e quantificação, a cargo da regra, decorre de uma limitação conhecida dos modelos generativos: as probabilidades que produzem não são calibradas, e a mesma entrada pode gerar percentuais distintos entre execuções. A regra determinística assegura reprodutibilidade, permite teste automatizado do comportamento do sistema e mantém rastreável a razão pela qual determinada análise recebeu determinada pontuação.

O motor opera sobre dois grupos de sinais: o grupo Texto/Print, correspondente aos oito sinais do RF07, e o grupo Link, derivado da verificação de URL descrita no capítulo 4 (RF03/UC03). Quando a verificação de uma fonte externa fica incompleta e a faixa resultante dos sinais disponíveis seria a verde, a faixa exibida é elevada para amarelo, preservando a pontuação real e informando ao usuário qual verificação não pôde ser concluída. Os valores de pesos e os pontos de corte das faixas constam exclusivamente de `docs/score-calibracao.md`, fonte única desses dados.

# **5 DESENVOLVIMENTO DO PROJETO**

Responsáveis pela sua execução: Hevelyn Leivas, Maisa Grundler e Gabriel Mascia.

Período de tempo para sua execução: seis meses.

# **6 DESCRIÇÃO DOS PRINCIPAIS USUÁRIOS**

As User Stories foram elaboradas considerando três perfis principais de usuários para o contexto de segurança digital:

- **Dona Neuza (Usuária Vulnerável): **aposentada, utiliza o WhatsApp para falar com a família. Tem receio de cair em golpes de Pix ou clonagem, mas não sabe identificar links maliciosos sozinha. Precisa de uma ferramenta simples que indique com clareza o nível de risco identificado e diga, em linguagem direta, o que fazer em seguida. Registra-se que a demanda espontânea desse perfil é por uma resposta binária do tipo seguro ou perigoso; o sistema, contudo, adota deliberadamente uma escala de três faixas com rotulagem calibrada, uma vez que a afirmação de segurança absoluta é tecnicamente insustentável e induziria confiança indevida no usuário mais vulnerável.

- **Ricardo (Entusiasta de Tecnologia / Protetor): **jovem adulto que entende de tecnologia e costuma ajudar parentes com dúvidas de segurança. Quer um app para validar suspeitas rapidamente e reportar novos golpes que encontra, ajudando a proteger a comunidade.

- **Ana (Profissional Autônoma): **recebe muitas mensagens de clientes desconhecidos e SMS com promoções e boletos. Como tem uma rotina corrida, precisa de uma análise instantânea de prints de conversas para saber se aquela abordagem é uma tentativa de engenharia social.

# **7 LEVANTAMENTO DOS REQUISITOS**

O detalhamento integral dos requisitos, incluindo critérios de aceitação e justificativas, consta do documento Levantamento de Requisitos de Software do Projeto Phize, cujo conteúdo é reproduzido a seguir em sua versão vigente.

## **7.1 Requisitos Funcionais**

### **RF01 — Cadastro do Usuário**

**Identificador: **RF01

**Nome: **Cadastro do Usuário

**Módulo: **Acesso

**Prioridade: **Alta

**Descrição: **O sistema deve permitir que novos usuários criem uma conta fornecendo e-mail e senha, ou através de integração com provedores sociais (Google/Apple), para que possam salvar seu histórico de alertas e interagir com a comunidade.

**Critérios de Aceitação: **O cadastro deve validar a força da senha (mínimo de 8 caracteres) e enviar um e-mail de verificação para contas não vinculadas a redes sociais.

### **RF02 — Login**

**Identificador: **RF02

**Nome: **Login

**Módulo: **Acesso

**Prioridade: **Alta

**Descrição: **O sistema deve autenticar usuários previamente cadastrados (via e-mail/senha ou autenticação social), mantendo a sessão do usuário ativa no dispositivo para agilizar consultas futuras.

**Critérios de Aceitação: **O login deve ser concluído em até 3 segundos. O sistema deve aplicar bloqueio temporário após 5 tentativas falhas consecutivas para evitar ataques de força bruta.

### **RF03 — Analisador de Links Maliciosos (URL Checker)**

**Identificador: **RF03

**Nome: **Analisador de Links Maliciosos (URL Checker)

**Módulo: **Core / Segurança

**Prioridade: **Alta

**Descrição: **O usuário deve poder colar um link para que o sistema verifique a integridade do domínio, checando se é recém-criado, se está em blacklists ou se utiliza mimetismo (typosquatting) para se passar por uma instituição real.

**Critérios de Aceitação: **A consulta deve processar a URL e retornar um status visual claro em menos de 5 segundos, acompanhado de uma explicação breve do risco. A rotulagem textual do veredito segue obrigatoriamente a escala calibrada definida no RF07, sendo vedado o emprego do termo “Seguro” ou equivalente que afirme ausência absoluta de risco. Os sinais verificados devem ser apresentados individualmente ao usuário em linguagem não técnica, com atribuição da fonte consultada.

### **RF04 — Analisador de Prints (IA Contextual)**

**Identificador: **RF04

**Nome: **Analisador de Prints (IA Contextual)

**Módulo: **IA / Vision

**Prioridade: **Alta

**Descrição: **O sistema deve processar imagens (prints de WhatsApp, SMS, e-mail) utilizando OCR e Processamento de Linguagem Natural para identificar abordagens fraudulentas, como gatilhos de urgência, ameaças ou pedidos financeiros suspeitos.

**Critérios de Aceitação: **A IA deve extrair o texto, destacar as frases suspeitas na interface e explicar de forma didática o porquê de serem consideradas características de um golpe. O envio do texto à nuvem é condicionado à aplicação prévia da rotina de mascaramento local definida no RNF07.

### **RF05 — Reportar Golpe**

**Identificador: **RF05

**Nome: **Reportar Golpe

**Módulo: **Comunidade / Segurança

**Prioridade: **Média

**Descrição: **O usuário deve poder denunciar uma nova tentativa de fraude, inserindo o link suspeito, um print ou um breve relato, para ajudar a alimentar o banco de dados de ameaças do aplicativo.

**Critérios de Aceitação: **O fluxo de reporte deve ser simples, concluído em até 3 cliques. O aplicativo deve limpar metadados de imagens anexadas para garantir o anonimato de quem denuncia. O reporte é registrado com status pendente e não ingressa automaticamente na base de conhecimento.

### **RF06 — Curtir Alertas da Comunidade (Upvote)**

**Identificador: **RF06

**Nome: **Curtir Alertas da Comunidade (Upvote)

**Módulo: **Comunidade / Social

**Prioridade: **Média

**Descrição: **O usuário deve poder curtir (dar upvote) nos alertas reportados no feed da comunidade para aumentar a relevância e visibilidade de um alerta real.

**Critérios de Aceitação: **O sistema deve registrar a curtida do usuário, impedindo votos duplicados pela mesma conta. O total de curtidas deve influenciar diretamente a ordem de exibição dos golpes catalogados, sem substituir o mecanismo de moderação previsto no RF11.

### **RF07 — Termômetro de Risco Visual (Score de Risco)**

**Identificador: **RF07

**Nome: **Termômetro de Risco Visual (Score de Risco)

**Módulo: **Core / UX

**Prioridade: **Alta

**Descrição: **O sistema deve processar a análise da ameaça (link ou print) e renderizar um componente visual em formato de termômetro, indicando o nível de periculosidade em escala numérica de 0 a 100. O valor é obtido por função determinística implementada na própria aplicação, que atribui pesos previamente definidos aos sinais objetivos identificados na análise — pedido financeiro, solicitação de dados pessoais, alegação de troca de contato, indução de urgência, ameaça, presença de link suspeito, oferta incompatível com a realidade de mercado e correspondência com padrão catalogado na base de conhecimento. O modelo de linguagem é responsável pela identificação dos sinais e pela explicação pedagógica, não pelo cálculo do valor exibido.

**Critérios de Aceitação: **O componente deve ser exibido simultaneamente à resposta da IA, utilizando padrão de cores semafórico (Verde, Amarelo e Vermelho) para facilitar a interpretação rápida. A rotulagem textual do veredito deve empregar linguagem calibrada, que comunique o resultado da verificação sem afirmar segurança absoluta — adota-se “Não encontramos sinais de golpe” para a faixa verde, “Atenção: sinais suspeitos” para a amarela e “Alto risco de golpe” para a vermelha. A tela de resultado deve conter aviso permanente de que a análise é uma ferramenta de apoio à decisão e não substitui a verificação direta junto à instituição envolvida. A tabela de pesos deve estar centralizada em módulo único de configuração, versionada e acompanhada de registro das calibragens realizadas. Valores idênticos de entrada devem produzir sempre o mesmo score, permitindo verificação por teste automatizado.

**Justificativa: **Modelos de linguagem não produzem estimativas de probabilidade calibradas: a mesma entrada pode gerar percentuais distintos entre execuções, e o valor devolvido não corresponde a uma medida estatística de risco. Delegar o cálculo ao modelo tornaria o indicador irreprodutível e incompatível com o RNF04, que veda respostas não fundamentadas. A separação entre identificação (modelo) e quantificação (regra determinística) preserva a explicabilidade do veredito e permite auditar a decisão do sistema.

**Calibração: **O motor opera sobre dois grupos de sinais: o grupo Texto/Print, com os oito sinais listados na Descrição, e o grupo Link, derivado da verificação de URL do RF03/UC03. Quando a verificação de uma fonte externa fica incompleta e a faixa resultante dos sinais disponíveis seria a verde, a faixa exibida é elevada para amarelo, preservando a pontuação real e informando ao usuário qual verificação não pôde ser concluída. Os valores numéricos de pesos e faixas constam exclusivamente de `docs/score-calibracao.md`, que é a fonte única desses dados.

### **RF08 — Visualizar Feed da Comunidade**

**Identificador: **RF08

**Nome: **Visualizar Feed da Comunidade

**Módulo: **Comunidade / Social

**Prioridade: **Média

**Descrição: **O sistema deve disponibilizar uma tela (feed) onde o usuário possa acessar os alertas reportados por outros usuários, permitindo a visualização dos golpes mais populares ou mais recentes.

**Critérios de Aceitação: **O feed deve carregar os dados rapidamente, exibindo o título, a data e a quantidade de curtidas de cada reporte. Deve permitir que o usuário filtre a visualização entre “Em alta” (mais curtidos) e “Mais recentes”. Reportes ocultados por moderação não são exibidos no feed público.

### **RF09 — Compartilhar Alertas Externamente**

**Identificador: **RF09

**Nome: **Compartilhar Alertas Externamente

**Módulo: **Comunidade / Social

**Prioridade: **Média

**Descrição: **O usuário deve poder compartilhar um alerta específico do feed para aplicativos externos, visando avisar pessoas fora da plataforma sobre fraudes ativas.

**Critérios de Aceitação: **A ação deve acionar o menu de compartilhamento nativo do dispositivo e gerar uma mensagem padronizada contendo o aviso de segurança, os detalhes da ameaça e a identidade do Phize.

### **RF10 — Análise por Compartilhamento Nativo**

**Identificador: **RF10

**Nome: **Análise por Compartilhamento Nativo

**Módulo: **Core / UX

**Prioridade: **Alta

**Descrição: **O sistema deve registrar-se como destino no menu de compartilhamento nativo do dispositivo, permitindo que o usuário envie uma imagem, um texto ou um link diretamente de qualquer aplicativo de mensagens para o Phize, sem necessidade de abrir o aplicativo previamente e localizar o arquivo na galeria.

**Critérios de Aceitação: **O aplicativo deve figurar entre as opções de compartilhamento para os tipos MIME de imagem e texto. Ao receber o conteúdo, deve iniciar a análise automaticamente e apresentar o resultado, reduzindo o fluxo de interação a uma única ação deliberada do usuário. Caso o usuário não esteja autenticado, o conteúdo permanece em memória até a conclusão do login, sem gravação em disco.

**Justificativa de prioridade: **a fraude por engenharia social explora a pressa. Um fluxo que exige cinco etapas manuais compete diretamente com o estado emocional induzido pelo golpista. A captura por compartilhamento insere a verificação no mesmo contexto em que a ameaça chega.

### **RF11 — Moderação de Conteúdo Comunitário**

**Identificador: **RF11

**Nome: **Moderação de Conteúdo Comunitário

**Módulo: **Comunidade / Segurança

**Prioridade: **Alta (dentro do escopo de expansão)

**Descrição: **O sistema deve disponibilizar mecanismo de denúncia de reportes publicados na comunidade, permitindo sinalizar conteúdo falso, ofensivo, duplicado ou que impute conduta fraudulenta a organização legítima. Reportes denunciados acima de limiar definido devem ser automaticamente ocultados do feed público até revisão manual pela equipe.

**Critérios de Aceitação: **A ação de denúncia deve estar acessível na tela de detalhe de qualquer alerta. O sistema deve registrar o motivo selecionado e impedir denúncias duplicadas pela mesma conta. Deve existir interface administrativa, ainda que mínima, para aprovação, ocultação ou remoção definitiva de reportes.

**Justificativa: **O mecanismo de upvote previsto no RF06 mede popularidade, não veracidade, e não oferece proteção contra a publicação de acusação infundada contra empresa ou pessoa identificável, situação que expõe o projeto a risco reputacional e jurídico. A ausência de moderação também permite o uso da base comunitária como vetor de desinformação, comprometendo a confiabilidade da própria funcionalidade.

### **RF12 — Exportação e Exclusão de Dados Pessoais**

**Identificador: **RF12

**Nome: **Exportação e Exclusão de Dados Pessoais

**Módulo: **Acesso / Legal

**Prioridade: **Alta

**Descrição: **O sistema deve permitir que o usuário autenticado exporte a íntegra dos dados vinculados à sua conta em formato legível e solicite a exclusão definitiva da conta e de todos os registros associados, diretamente pela interface do aplicativo.

**Critérios de Aceitação: **A exclusão deve remover todos os documentos vinculados ao identificador do usuário no Cloud Firestore e a credencial no Firebase Authentication, precedida de confirmação explícita com aviso de irreversibilidade. Hashes de ameaças validadas permanecem na base comunitária de forma dissociada do autor, por não constituírem dado pessoal.

**Justificativa: **Atendimento aos direitos de acesso, portabilidade e eliminação previstos no Art. 18 da Lei nº 13.709/2018.

## **7.2 Requisitos Não Funcionais**

### **RNF01 — Privacidade e Conformidade com a LGPD**

**Identificador: **RNF01

**Nome: **Privacidade e Conformidade com a LGPD

**Módulo: **Segurança / Legal

**Prioridade: **Alta

**Descrição: **O sistema deve tratar o dado do usuário sob o princípio de minimização, aplicando três garantias cumulativas: (a) as imagens submetidas são processadas exclusivamente em memória volátil e descartadas imediatamente após a extração textual, não sendo gravadas em disco local nem em servidor; (b) o texto extraído sofre mascaramento local de dados pessoais estruturados antes de qualquer transmissão à nuvem; (c) nenhum conteúdo de conversa, em imagem ou em texto, é persistido no banco de dados, o histórico armazena apenas o resultado da análise (Score de Risco, categoria da ameaça, explicação pedagógica e data).

**Justificativa: **Assegurar a confidencialidade das comunicações privadas do usuário e atender aos princípios de finalidade, necessidade e minimização previstos no Art. 6º da Lei nº 13.709/2018 (LGPD). A limitação do dado persistido reduz a superfície de exposição em caso de incidente e dispensa o tratamento de dado pessoal sensível em base própria.

### **RNF02 — Framework e Desenvolvimento Mobile**

**Identificador: **RNF02

**Nome: **Framework e Desenvolvimento Mobile

**Módulo: **Tecnologia

**Prioridade: **Alta

**Descrição: **O aplicativo será desenvolvido utilizando o framework Flutter no front-end, integrado ao Firebase para autenticação e banco de dados (armazenamento de hashes e alertas).

**Justificativa: **Permite manter uma única base de código para deploy em Android e iOS, garantindo performance nativa, interface fluida e facilidade de manutenção para a equipe.

### **RNF03 — Latência da IA**

**Identificador: **RNF03

**Nome: **Latência da IA

**Módulo: **Performance

**Prioridade: **Média

**Descrição: **O processamento das requisições via API de LLM/Vision deve iniciar o feedback visual de carregamento imediatamente, devendo a primeira porção do resultado ser apresentada em até 5 segundos, mediante streaming progressivo do texto gerado. A cadeia de processamento envolve extração de caracteres, recuperação na base de conhecimento e inferência do modelo de linguagem, etapas cuja soma raramente se conclui abaixo desse patamar; o requisito prioriza, portanto, a percepção contínua de atividade do sistema sobre a redução do tempo total.

**Justificativa: **Prevenir que o usuário abandone o aplicativo achando que travou durante o processamento de modelos de inteligência artificial.

### **RNF04 — Coesão Contextual da IA**

**Identificador: **RNF04

**Nome: **Coesão Contextual da IA

**Módulo: **IA / UX

**Prioridade: **Alta

**Descrição: **Os retornos da Inteligência Artificial devem ser gerados em uma linguagem clara, acessível, objetiva e livre de jargões técnicos complexos ou “alucinações”, focando sempre em instruções de prevenção.

**Justificativa: **O público-alvo pode incluir usuários com pouco letramento digital; portanto, as explicações dos riscos devem ser facilmente compreendidas por qualquer pessoa para que o app cumpra seu papel de utilidade pública.

### **RNF05 — Base de Conhecimento de Fraudes e Arquitetura RAG**

**Identificador: **RNF05

**Nome: **Base de Conhecimento de Fraudes e Arquitetura RAG

**Módulo: **Tecnologia / IA

**Prioridade: **Alta

**Descrição: **O processamento de linguagem natural deve operar sob arquitetura RAG (Retrieval-Augmented Generation), cruzando o texto analisado com uma base vetorial própria de padrões de fraude praticados no Brasil. A base deve ser constituída antes do início da operação, a partir de fontes públicas e oficiais, e mantida por processo de atualização periódica documentado. A recuperação deve retornar os padrões de maior similaridade semântica, que são injetados no contexto do modelo como fundamento do veredito. Nenhum conteúdo ingressa na base de forma automática, sendo a curadoria humana condição de incorporação.

**Justificativa: **Modelos de linguagem genéricos reconhecem táticas universais de engenharia social, mas desconhecem a especificidade local. A base de conhecimento brasileira constitui o diferencial competitivo estruturante do projeto, por ser o único componente não replicável por meio da simples contratação de uma API, e por ganhar densidade à medida que o produto é utilizado.

### **RNF06 — Integração de Visão Computacional (OCR)**

**Identificador: **RNF06

**Nome: **Integração de Visão Computacional (OCR)

**Módulo: **Tecnologia / Integração

**Prioridade: **Alta

**Descrição: **A extração de caracteres das capturas de tela deve ser executada primariamente via integração com serviços otimizados para OCR de alta precisão (ex: Google Cloud Vision API).

**Justificativa: **Assegurar a leitura correta de textos em diferentes resoluções, fontes e fundos variados (modo escuro/claro), características comuns em prints de WhatsApp ou SMS.

### **RNF07 — Ciclo de Vida do Dado Textual**

**Identificador: **RNF07

**Nome: **Ciclo de Vida do Dado Textual

**Módulo: **Segurança / IA

**Prioridade: **Alta

**Descrição: **O texto resultante do OCR deve percorrer um ciclo de vida documentado e auditável, composto por quatro etapas obrigatórias:

- Mascaramento local: antes da transmissão, o dispositivo aplica expressões regulares sobre o texto extraído, substituindo por marcadores genéricos os dados pessoais de formato estruturado CPF, CNPJ, números de telefone, endereços de e-mail, chaves Pix aleatórias, números de cartão e códigos de barras de boleto. Exemplo: um telefone é substituído por [TELEFONE].

- Transmissão: o texto mascarado é enviado ao provedor de LLM sobre canal criptografado (TLS 1.2 ou superior), exclusivamente por meio de APIs corporativas cujos termos vedem o uso do conteúdo para treinamento de modelos.

- Descarte na origem: concluída a resposta, o texto é removido da memória da aplicação, não sendo escrito em cache, log ou arquivo temporário.

- Persistência seletiva: grava-se no Cloud Firestore somente o resultado da análise, score numérico, categoria da ameaça, explicação pedagógica gerada e timestamp. O texto analisado não é gravado em nenhuma hipótese.

**Justificativa: **A garantia de não persistência da imagem é insuficiente isoladamente, pois o texto extraído preserva o mesmo teor sensível da conversa original. A especificação explícita do ciclo completo do dado textual torna a política de privacidade verificável em auditoria e delimita com precisão o que o sistema efetivamente conhece sobre o usuário.

**Limitação declarada: **o mascaramento local cobre dados de formato previsível. Nomes próprios e conteúdo livre não são mascarados no dispositivo, pois o reconhecimento de entidades nomeadas exigiria modelo de PLN embarcado, fora do escopo do MVP. Essa limitação é mitigada pela contratação de provedores com política de retenção zero e pela não persistência do texto em base própria, devendo ser informada ao usuário na tela de consentimento.

## **7.3 Requisitos de Desenvolvimento**

### **RDEV01 — Estudo de Modelos LLM**

**Identificador: **RDEV01

**Módulo: **IA

**Descrição: **Estudo de APIs (OpenAI, Google Gemini) focadas em detecção de fraude e análise de sentimentos, com avaliação obrigatória dos termos de retenção e uso de dados de cada fornecedor, conforme condição estabelecida no RNF07.

### **RDEV02 — Prototipagem em Figma**

**Identificador: **RDEV02

**Módulo: **Design

**Descrição: **Criação de interface limpa com foco em acessibilidade para usuários iniciantes.

### **RDEV03 — Banco de Dados de Ameaças**

**Identificador: **RDEV03

**Módulo: **Infraestrutura

**Descrição: **Integração com Firebase para autenticação e armazenamento de hashes de links denunciados.

### **RDEV04 — Constituição da Base de Conhecimento de Fraudes**

**Identificador: **RDEV04

**Módulo: **IA / Dados

**Descrição: **Catalogação manual das modalidades de fraude a partir de fontes públicas e oficiais, com normalização em estrutura padronizada, geração de embeddings e construção do índice vetorial inicial. Constitui pré-requisito para a operação da camada de PLN.

# **8 UML DO PROJETO**

A Linguagem de Modelagem Unificada (UML) atua como a planta baixa arquitetônica do Phize. Antes da implementação do código, a modelagem UML é utilizada para documentar, padronizar e visualizar estruturalmente como o sistema se comporta e como os usuários interagem com as tecnologias propostas. No contexto do projeto, a modelagem garante que os requisitos de software e o código evoluam de maneira alinhada, dividindo-se essencialmente em duas perspectivas comportamentais.

## **Diagrama de Casos de Uso**

Representa a visão macro das interações. Ele mapeia de forma clara quem são os atores do sistema, segmentados por perfis de vulnerabilidade e conhecimento técnico, e quais ações eles podem executar, como analisar um print com IA, verificar um link ou reportar um golpe à comunidade.

## **Diagrama de Sequência**

Representa o mapeamento cronológico e detalhado do fluxo de dados. Ele ilustra o passo a passo da comunicação entre as camadas do projeto ao longo do tempo. É neste artefato que se consolida a documentação das regras de negócio críticas, desenhando as chamadas do frontend (Flutter) para o backend (Firebase) durante a autenticação, e a requisição das imagens para as APIs externas, evidenciando a etapa de mascaramento local anterior à transmissão, o descarte imediato da mídia e do texto analisado, e o cumprimento dos parâmetros de latência definidos no RNF03.

# **REFERÊNCIAS**

CNN BRASIL. Mais da metade dos brasileiros foram vítimas de golpes digitais em 2024. CNN Brasil, São Paulo, 5 dez. 2025. Disponível em: https://www.cnnbrasil.com.br/nacional/brasil/metade-dos-brasileiros-foram-vitimas-de-golpes-digitais-em-2024-diz-estudo/. Acesso em: 22 maio 2026.

DEFENSORIA PÚBLICA DO ESTADO DE MATO GROSSO (DPEMT). Aposentados são os principais alvos de golpes com Pix entre atendidos pela Defensoria Pública. DPEMT, Cuiabá, 23 out. 2024. Disponível em: https://www.defensoria.mt.def.br/dpmt/noticias/aposentados-sao-os-principais-alvos-de-golpes-com-pix-entre-atendidos-pela-defensoria-publica. Acesso em: 22 maio 2026.

SENADO FEDERAL. Mais de 24 milhões de pessoas foram vítimas de golpes pelo PIX. Rádio Senado, Brasília, DF, 18 ago. 2025. Disponível em: https://www12.senado.leg.br/radio/1/noticia/2025/08/18/mais-de-24-milhoes-de-pessoas-foram-vitimas-de-golpes-pelo-pix. Acesso em: 22 maio 2026.

SERASA EXPERIAN. Tentativas de fraude contra idosos aumentam em quase 12% em 2024, revela Serasa Experian. Serasa Experian: Sala de Imprensa, São Paulo, 19 mar. 2025. Disponível em: https://www.serasaexperian.com.br/sala-de-imprensa/prevencao-a-fraude/tentativas-de-fraude-contra-idosos-aumentam-em-quase-12-em-2024-revela-serasa-experian/. Acesso em: 22 maio 2026.
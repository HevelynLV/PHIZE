**CENTRO UNIVERSITÁRIO CESUSC**

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**ESPECIFICAÇÃO DA ARQUITETURA TECNOLÓGICA: PHIZE**

FLORIANÓPOLIS - SC

2026

GABRIEL MASCIA

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL**

Documento técnico contendo a especificação da arquitetura tecnológica do Projeto Phize, apresentado como requisito de avaliação prático. Orientador: Prof. Sérgio

FLORIANÓPOLIS - SC

2026

# **TERMINOLOGIAS**

- **Typosquatting:** técnica de fraude na qual o golpista registra domínios com erros de digitação de sites conhecidos para enganar o usuário.

- **Zero-Persistence:** princípio de privacidade segundo o qual determinados dados, como os prints de conversas, nunca são gravados permanentemente em disco ou banco de dados.

- **Anonymization:** processo de remoção das informações que identifiquem uma pessoa (nomes, CPFs, números de telefone) antes de o dado ser processado ou compartilhado.

- **RAG:** arquitetura de IA que permite ao modelo consultar uma base externa antes de responder. Em vez de gerar a resposta apenas a partir do treinamento prévio, o modelo recupera padrões de uma base curada de golpes e fundamenta o veredito nesses registros.

- **Google Cloud Vision:** ferramenta de inteligência artificial multimodal do Google voltada à visão computacional. Sua função de OCR (Reconhecimento Óptico de Caracteres) converte os pixels de uma imagem em texto processável.

- **Flutter:** framework utilizado para construir a interface do aplicativo instalado no celular do usuário.

- **Hash:** resultado de um algoritmo matemático que transforma uma quantidade variável de dados em uma sequência de caracteres de tamanho fixo.

- **RDAP:** protocolo público de consulta a dados cadastrais de domínios, sucessor do WHOIS, utilizado para verificar a data de registro de um endereço.

# **1 ARQUITETURA DE FRONTEND**

O módulo de frontend constitui a interface de interação com o usuário, sendo o ambiente de aplicação direta dos requisitos de usabilidade e acessibilidade.

- **Tecnologia e Linguagem:** utilização do framework Flutter com a linguagem Dart.

- **Justificativa Técnica:** adoção de desenvolvimento multiplataforma para garantir código único, interface fluida e alta performance em sistemas Android e iOS, atendendo ao RNF02.

# **2 BACKEND E GESTÃO DE DADOS**

Este módulo assegura a funcionalidade lógica do sistema e a persistência dos dados da funcionalidade de Comunidade de Reporte (RF05).

- **Plataforma BaaS:** utilização do ecossistema Firebase (Google).

- **Banco de Dados:** emprego do Cloud Firestore (NoSQL) para o armazenamento de hashes de links denunciados e gestão do histórico de segurança do usuário.

- **Custos Operacionais:** A camada de backend gerenciado (Firebase Authentication e Cloud Firestore) opera sob o plano gratuito, cujas cotas são suficientes para o volume previsto na fase de validação. A camada de inteligência artificial constitui exceção deliberada: o RNF07 condiciona a transmissão de texto a provedores cujos termos vedem o uso do conteúdo para treinamento de modelos, condição não oferecida pelas camadas gratuitas de uso, que em regra reservam ao fornecedor o direito de utilizar as entradas para melhoria de modelos. A contratação de plano com retenção controlada é, portanto, requisito de privacidade e não escolha de desempenho, e representa o único custo operacional recorrente previsto para o MVP. Durante a fase de prototipação e testes internos, admite-se o uso de camada gratuita exclusivamente com dados fictícios ou previamente descaracterizados, vedado o processamento de conversas reais de usuários nessa condição.

- **Proteção de Credenciais:** as chaves de acesso às APIs de terceiros não são embarcadas no pacote do aplicativo. As chamadas aos provedores de inteligência artificial trafegam por camada intermediária gerenciada, de modo que a credencial permaneça sob controle do servidor e não seja extraível a partir do binário distribuído nas lojas de aplicativos.

# **3 CAMADA DE INTELIGÊNCIA ARTIFICIAL E PROCESSAMENTO**

A camada de inteligência é responsável pela execução dos requisitos de IA e Processamento de Linguagem Natural (PLN).

## **3.1 Visão Computacional (OCR)**

Para o cumprimento da Análise de Print (RF04), o sistema utiliza a API do Google Cloud Vision para a extração técnica de caracteres e textos a partir de capturas de tela enviadas.

## **3.2 Processamento Contextual (PLN) e Base de Conhecimento**

O texto sanitizado é submetido a um modelo de linguagem sob arquitetura RAG. A camada é composta por quatro elementos:

**a) Fontes de constituição da base. **A base inicial é formada por conteúdo público e de acesso irrestrito, catalogado manualmente pela equipe: cartilhas e boletins de segurança da Febraban e do Banco Central; alertas de golpe publicados por órgãos estaduais e federais de defesa do consumidor; comunicados de segurança de instituições financeiras; e registros de modalidades de fraude descritos em fontes jornalísticas de veículos de referência. Cada entrada é normalizada em um documento estruturado contendo: nome da modalidade, canal de ocorrência, gatilhos linguísticos característicos, padrão de solicitação financeira e orientação preventiva correspondente.

**b) Indexação vetorial. **Os documentos são convertidos em embeddings e armazenados em índice vetorial. Para o MVP, adota-se persistência do índice em arquivo local versionado junto ao repositório, dada a cardinalidade reduzida da base inicial — solução que dispensa a contratação de banco vetorial dedicado e mantém o custo operacional nulo nesta fase. Registra-se como consequência que a atualização da base, nessa modalidade, ocorre por nova versão do aplicativo; a migração para índice remoto está prevista para a fase de expansão, quando a frequência de atualização passar a exigir independência do ciclo de release.

**c) Recuperação. **A consulta submete o texto sanitizado ao índice e recupera os padrões de maior similaridade, que são inseridos no prompt como referência factual. O modelo é instruído a fundamentar o veredito nos padrões recuperados e a declarar ausência de correspondência quando não houver similaridade suficiente, em vez de inferir livremente.

**d) Governança e atualização. **A base é revisada em ciclo definido, com incorporação de novas modalidades identificadas nas fontes oficiais. Na fase de expansão, os reportes comunitários validados passam a alimentar a base, estabelecendo o ciclo de retroalimentação que caracteriza o efeito de rede do produto. A curadoria permanece humana: nenhum reporte ingressa na base de forma automática, evitando envenenamento intencional do índice.

## **3.3 Cálculo do Score de Risco**

O valor numérico exibido no termômetro de periculosidade (RF07) não é gerado pelo modelo de linguagem. O modelo é responsável por identificar, no conteúdo analisado, a presença dos sinais previstos e por produzir a explicação pedagógica correspondente. A conversão desses sinais em um número decorre de função determinística implementada na aplicação, que aplica pesos previamente definidos e versionados a cada sinal identificado, somando-os com teto de 100 pontos e classificando o resultado em três faixas.

A separação entre identificação e quantificação decorre de uma limitação conhecida dos modelos generativos: as probabilidades que produzem não são calibradas, e a mesma entrada pode gerar percentuais distintos entre execuções. A regra determinística assegura reprodutibilidade, permite teste automatizado do comportamento do sistema e mantém rastreável a razão pela qual determinada análise recebeu determinada pontuação.

O motor opera sobre dois grupos de sinais: o grupo Texto/Print, correspondente aos oito sinais do RF07, e o grupo Link, derivado da verificação de URL descrita no capítulo 4 (RF03/UC03). Quando a verificação de uma fonte externa fica incompleta e a faixa resultante dos sinais disponíveis seria a verde, a faixa exibida é elevada para amarelo, preservando a pontuação real e informando ao usuário qual verificação não pôde ser concluída. Os valores de pesos e os pontos de corte das faixas constam exclusivamente de `docs/score-calibracao.md`, fonte única desses dados.

# **4 PROCESSO DE ANÁLISE DE LINKS (URL)**

A verificação de integridade de links (RF03) segue um protocolo de etapas encadeadas para garantir a precisão do Score de Risco:

**1. Entrada de Dados. **O usuário insere a URL no campo de busca ou a submete pelo menu de compartilhamento nativo.

**2. Consulta de Reputação. **O sistema realiza chamadas assíncronas a APIs de reputação de domínio, com a Google Safe Browsing API como fonte primária, para identificar endereços previamente catalogados como maliciosos. A adoção dessa API impõe três condicionantes contratuais incorporadas ao projeto: (a) o uso é restrito a finalidades não comerciais, de modo que qualquer evolução do produto para modelo de receita exige migração para a Web Risk API; (b) os avisos exibidos ao usuário devem empregar linguagem de ressalva e atribuir a fonte ao Google; (c) a interface deve informar que a verificação não é infalível e está sujeita a falsos positivos e falsos negativos. Registra-se ainda a limitação técnica da fonte: por operar sobre listas de ameaças conhecidas, a cobertura é reduzida para domínios recém-criados, lacuna endereçada pela análise de anatomia e de idade de registro do domínio descrita nas etapas seguintes.

**3. Idade do Domínio. **Consulta ao serviço público RDAP para obtenção da data de registro. Domínios criados há poucos dias e que imitam instituições conhecidas constituem sinal de risco elevado, característico de campanhas de fraude de curta duração.

**4. Análise de Domínio. **O sistema analisa a anatomia do link para detecção de typosquatting, comparando o endereço submetido com uma lista curada de marcas frequentemente imitadas em golpes praticados no Brasil, por meio de medida de distância de edição.

# **5 SEGURANÇA E PRIVACIDADE DE DADOS**

Em observância à LGPD e aos requisitos RNF01 e RNF07, o sistema adota a abordagem de Privacy by Design, na qual a proteção da informação é uma propriedade da arquitetura e não uma camada acessória. O desenho da solução parte da premissa de que capturas de tela de conversas constituem o dado mais sensível manipulado pela aplicação e, por consequência, aquele cuja permanência deve ser reduzida ao mínimo técnico necessário.

## **5.1 Persistência Zero da Mídia**

As imagens submetidas para análise são carregadas em memória volátil, encaminhadas à API de visão computacional e descartadas imediatamente após o retorno do texto. Não há gravação em disco local, cache de aplicação, storage em nuvem ou banco de dados. Eventual arquivo temporário criado pelo seletor de mídia do sistema operacional é removido na mesma rotina. Em caso de falha ou interrupção do fluxo, o descarte ocorre igualmente, por meio de bloco de tratamento de exceção.

## **5.2 Mascaramento Local de Dados Estruturados**

Antes da transmissão à nuvem, o texto extraído é submetido a uma rotina de sanitização executada no dispositivo, que identifica e substitui por marcadores genéricos os padrões de dado pessoal com formato determinístico: CPF, CNPJ, telefone, e-mail, chave Pix aleatória, número de cartão e linha digitável de boleto. A rotina preserva integralmente os elementos relevantes à detecção de fraude — verbos de urgência, solicitações financeiras, domínios e estrutura argumentativa —, de modo que a sanitização não degrada a acurácia da análise semântica.

## **5.3 Transmissão e Retenção em Terceiros**

A comunicação com as APIs externas ocorre sobre TLS. A contratação dos provedores de OCR e LLM restringe-se a planos corporativos cujos termos de serviço vedem expressamente o uso do conteúdo submetido para treinamento de modelos e estabeleçam retenção nula ou de curta duração para fins exclusivos de abuso. Essa condição é requisito de seleção de fornecedor, não preferência: provedores que não a ofereçam ficam inelegíveis para a arquitetura. A relação dos terceiros efetivamente empregados, bem como a finalidade de cada transmissão, deve constar da política de privacidade apresentada ao usuário.

## **5.4 Persistência Seletiva no Histórico**

O Cloud Firestore armazena, por análise, apenas: identificador do usuário, score de risco, categoria da ameaça, explicação pedagógica, tipo de entrada (link ou imagem) e data. O conteúdo analisado não é gravado. Em decorrência, o histórico informa ao usuário o que foi verificado e qual foi o veredito, sem reconstituir a conversa original — inclusive para a própria equipe de desenvolvimento, que não dispõe de meio técnico para acessar o teor das mensagens analisadas.

## **5.5 Proteção da Base Comunitária**

Os reportes enviados à comunidade não armazenam URLs em texto puro. O endereço é previamente normalizado no dispositivo, com isolamento do domínio e descarte de parâmetros de consulta variáveis, e em seguida convertido em hash SHA-256, permitindo a verificação de correspondência entre denúncias sem expor o link original na base. A normalização é condição de funcionamento do mecanismo: sem ela, variações irrelevantes do endereço produziriam hashes distintas e impediriam o reconhecimento de uma mesma campanha de fraude. Metadados EXIF de imagens eventualmente anexadas a reportes são removidos no dispositivo antes do envio, preservando o anonimato do denunciante.

## **5.6 Direitos do Titular**

O usuário dispõe, na própria interface, das funções de exportação e exclusão integral de seu histórico e de sua conta, atendendo aos direitos de acesso e eliminação previstos no Art. 18 da LGPD, conforme especificado no RF12. A exclusão de conta remove todos os documentos vinculados ao identificador do usuário. Hashes de ameaças validadas, por não conterem dado pessoal, permanecem na base comunitária de forma dissociada.

## **5.7 Moderação e Integridade do Conteúdo Comunitário**

A base comunitária admite conteúdo submetido por terceiros e, por essa razão, incorpora mecanismo de denúncia e revisão descrito no RF11. Reportes sinalizados acima de limiar definido são ocultados do feed público até revisão humana. A medida protege a aplicação contra a publicação de acusação infundada a organização legítima e contra o uso da funcionalidade como vetor de desinformação, riscos que o mecanismo de upvote, por medir popularidade e não veracidade, não é capaz de endereçar.

# **6 REQUISITOS DE PERFORMANCE E USABILIDADE**

Para assegurar a viabilidade operacional e evitar o abandono do usuário (RNF03), o sistema estabelece limites técnicos de desempenho:

- **Latência de Resposta:** o feedback visual de carregamento é exibido imediatamente após a submissão. A primeira porção do resultado deve ser apresentada em até 5 segundos, mediante streaming progressivo do texto, valor referenciado no RNF03.

- **Feedback de Interface:** implementação de Skeleton Screens e indicadores de carregamento durante o processamento assíncrono para garantir a percepção de atividade do sistema.

- **Degradação Controlada:** indisponibilidade de uma fonte externa não interrompe a análise. O sistema apresenta o resultado obtido com os sinais disponíveis e informa ao usuário qual verificação não pôde ser concluída. Se a faixa resultante dos sinais disponíveis for a verde, ela é elevada para amarelo enquanto a verificação estiver incompleta, conforme detalhado em `docs/score-calibracao.md`.
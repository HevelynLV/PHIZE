**CENTRO UNIVERSITÁRIO CESUSC**

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: LEVANTAMENTO DE REQUISITOS DE SOFTWARE**

FLORIANÓPOLIS - SC

2026

HEVELYN LEIVAS

MAISA GRUNDLER

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL**

Documento técnico contendo o levantamento de requisitos funcionais, não funcionais e a especificação de escopo do Projeto Phize, apresentado como requisito de avaliação prático. Orientador: Prof. Sérgio

FLORIANÓPOLIS - SC

2026

# **1 PROPÓSITO DO DOCUMENTO DE LEVANTAMENTO DE REQUISITOS**

Este documento tem como propósito definir, documentar e alinhar as diretrizes centrais do aplicativo de segurança preventiva, estabelecendo uma compreensão comum entre a equipe de desenvolvimento e os stakeholders. O objetivo é delimitar as capacidades do sistema, suas restrições tecnológicas e seu contexto de aplicação, fornecendo uma base sólida para as fases subsequentes de arquitetura e engenharia de software. Ao documentar essas premissas, o documento garante que o desenvolvimento focado em Inteligência Artificial e processamento de linguagem mantenha seu alinhamento com a meta principal: a proteção e educação do usuário contra fraudes baseadas em engenharia social.

# **2 ESCOPO**

O escopo do projeto engloba a construção de um aplicativo móvel multiplataforma (Android e iOS) focado na análise contextual de ameaças virtuais. A entrega é organizada em duas camadas de prioridade, de modo a garantir a maturidade funcional do núcleo do produto antes da expansão de funcionalidades sociais.

## **2.1 Escopo do Produto Mínimo Viável (MVP)**

O MVP concentra-se no fluxo que materializa a proposta de valor central — submeter um conteúdo suspeito e obter um veredito compreensível com explicação. Integram o MVP:

- **Módulo de Autenticação:** estruturação no ecossistema Firebase (BaaS), com Cloud Firestore para o histórico de análises.

- **Módulo de Captura por Compartilhamento Nativo:** recebimento de imagens e textos diretamente pelo menu de compartilhamento do sistema operacional, dispensando a navegação manual até a galeria.

- **Módulo de Visão Computacional:** integração com Google Cloud Vision para extração de caracteres (OCR).

- **Módulo de Processamento Lógico (IA):** PLN via LLM calibrado por arquitetura RAG, para identificação de urgência artificial e solicitações financeiras anômalas.

- **Módulo de Análise de URLs (URL Checker):** detecção de mimetismo de domínios (typosquatting), verificação da idade de registro do domínio e consulta de reputação assíncrona.

- **Módulo de Retorno ao Usuário:** Score de Risco calculado por função determinística, apresentado em componente visual com correção pedagógica just-in-time.

- **Privacidade e Tratamento de Dados:** implementação integral dos princípios definidos em RNF01 e RNF07.

- **Direitos do Titular:** funções de exportação e exclusão de dados pessoais, conforme RF12.

## **2.2 Escopo de Expansão (pós-MVP)**

As funcionalidades comunitárias dependem de massa crítica de usuários para gerar valor e, por essa razão, são posicionadas como evolução planejada e não como condição de validação do produto:

- Comunidade de Reporte colaborativo, com normalização de endereços e conversão de dados maliciosos em hashes criptográficas.

- Feed público de alertas, mecanismo de upvote, pesquisa e compartilhamento externo.

- Mecanismo de moderação de conteúdo comunitário, conforme RF11.

- Incorporação dos reportes comunitários validados à base de conhecimento, mediante curadoria humana, conforme processo de governança definido na Especificação da Arquitetura.

## **2.3 Fora de Escopo**

Estão fora do escopo do projeto o desenvolvimento de mecanismos tradicionais de antivírus, como varredura de malwares em discos rígidos locais, interceptação de pacotes de rede (firewalls) e bloqueio de invasões em nível de sistema operacional.

# **3 VISÃO DO PRODUTO**

O produto visa preencher a lacuna tecnológica entre a sofisticação dos crimes cibernéticos modernos e a vulnerabilidade comportamental do cidadão. A visão central é transcender as ferramentas de segurança convencionais e passivas, entregando um ecossistema ativo de autodefesa diária. O software não atua apenas na mitigação automatizada de ameaças, mas funciona como um agente educativo que desestrutura táticas de persuasão psicológica, ensinando o usuário, no calor do momento, a interpretar a periculosidade do conteúdo. A solução transforma a capacidade analítica da inteligência artificial em um hábito preventivo, pedagógico e coletivo.

# **4 USUÁRIO E CONTEXTO**

O cenário de atuação do software é pautado pela crise de segurança digital do mercado brasileiro, no qual ataques são camuflados como oportunidades ou urgências no cotidiano das comunicações. A aplicação é delineada para atender a três personas principais, cada qual com um contexto de uso específico:

- **Usuário Vulnerável (Exemplo: Dona Neuza):** Representa o público idoso, aposentado ou com letramento tecnológico reduzido. Utiliza aplicativos de mensagens para comunicação básica e possui forte receio de fraudes financeiras. O contexto de uso deste perfil exige ausência de jargões técnicos e demanda um diagnóstico visual imediato, acompanhado de orientação prática sobre o que fazer em seguida. Registra-se que a demanda espontânea desse perfil é por uma resposta binária do tipo seguro ou perigoso; o sistema, contudo, adota deliberadamente uma escala de três faixas com rotulagem calibrada (RF07), uma vez que a afirmação de segurança absoluta é tecnicamente insustentável e induziria confiança indevida no usuário mais vulnerável.

- **Profissional Autônomo (Exemplo: Ana):** Usuária inserida em uma rotina comercial ágil, exposta diariamente a um alto volume de interações com contatos desconhecidos, recebimento de links e boletos. Seu contexto de uso é utilitário e imediato; demanda análises instantâneas de capturas de tela para validar abordagens sem prejudicar o tempo útil do seu trabalho.

- **Entusiasta/Protetor (Exemplo: Ricardo):** Usuário jovem ou adulto com alto nível de proficiência tecnológica, que atua informalmente como suporte de segurança para sua família e círculo social. Seu contexto de uso envolve a validação ativa de suspeitas mais complexas e o desejo de colaboração coletiva, sendo o principal alimentador do banco de dados na catalogação de novos golpes por meio da comunidade de reporte.

# **5 REQUISITOS FUNCIONAIS**

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

**Justificativa: **Atendimento aos direitos de acesso, portabilidade e eliminação previstos no Art. 18 da Lei nº 13.709/2018. A garantia consta da Especificação da Arquitetura (seção 5.6) e requer requisito formal correspondente para ingressar no escopo de desenvolvimento.

# **6 REQUISITOS NÃO FUNCIONAIS**

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

**Justificativa: **Modelos de linguagem genéricos reconhecem táticas universais de engenharia social, mas desconhecem a especificidade local — o golpe do falso boleto de órgão estadual, a fraude do falso leilão de veículos, o padrão de domínio usado em campanhas de Pix regionais. A base de conhecimento brasileira constitui o diferencial competitivo estruturante do projeto, por ser o único componente não replicável por meio da simples contratação de uma API, e por ganhar densidade à medida que o produto é utilizado.

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

# **7 REQUISITOS DE DESENVOLVIMENTO**

### **RDEV01 — Estudo de Modelos LLM**

**Identificador: **RDEV01

**Nome: **Estudo de Modelos LLM

**Módulo: **IA

**Descrição: **Estudo de APIs (OpenAI, Google Gemini) focadas em detecção de fraude e análise de sentimentos, com avaliação obrigatória dos termos de retenção e uso de dados de cada fornecedor, conforme condição estabelecida no RNF07.

### **RDEV02 — Prototipagem em Figma**

**Identificador: **RDEV02

**Nome: **Prototipagem em Figma

**Módulo: **Design

**Descrição: **Criação de interface limpa com foco em acessibilidade para usuários iniciantes.

### **RDEV03 — Banco de Dados de Ameaças**

**Identificador: **RDEV03

**Nome: **Banco de Dados de Ameaças

**Módulo: **Infraestrutura

**Descrição: **Integração com Firebase para autenticação e armazenamento de hashes de links denunciados.

### **RDEV04 — Constituição da Base de Conhecimento de Fraudes**

**Identificador: **RDEV04

**Nome: **Constituição da Base de Conhecimento de Fraudes

**Módulo: **IA / Dados

**Descrição: **Catalogação manual das modalidades de fraude a partir de fontes públicas e oficiais, com normalização em estrutura padronizada, geração de embeddings e construção do índice vetorial inicial. Constitui pré-requisito para a operação da camada de PLN.
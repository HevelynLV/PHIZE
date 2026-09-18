**CENTRO UNIVERSITÁRIO CESUSC**

**GABRIEL MASCIA,** **HEVELYN LEIVAS,** **MAISA GRUNDLER**

**PROJETO PHIZE: MODELAGEM DE SISTEMA E DIAGRAMAS UML **

**FLORIANÓPOLIS - SC** **2026**

**GABRIEL MASCIA** **HEVELYN LEIVAS** **MAISA GRUNDLER** 

**PROJETO PHIZE: APLICATIVO DE SEGURANÇA PREVENTIVA E EDUCAÇÃO DIGITAL **

Documento técnico contendo a arquitetura visual e os diagramas da Linguagem de Modelagem Unificada (UML) do Projeto Phize, apresentado como requisito de avaliação prático. Orientador(a): Sérgio

**FLORIANÓPOLIS - SC** **2026** 

**1 INTRODUÇÃO**

O presente documento tem como objetivo apresentar a modelagem arquitetônica e comportamental do Projeto Phize, um aplicativo de segurança preventiva focado na detecção de fraudes digitais e engenharia social. O escopo desta entrega concentra-se exclusivamente na representação visual do ecossistema por meio da Linguagem de Modelagem Unificada (UML).

Para garantir a precisão técnica da documentação, os fluxos de interação entre os usuários, a interface em Flutter, o banco de dados Firebase e as APIs de inteligência artificial (Google Cloud Vision e LLMs) foram mapeados utilizando Diagramas de Casos de Uso e Diagramas de Sequência. O detalhamento destas estruturas visa fornecer uma base sólida e padronizada para as fases de implementação e engenharia de software da solução.

**2 MODELAGEM DO SISTEMA (UML)**

Esta seção destina-se à representação visual da arquitetura do aplicativo...

**2.1 Diagramas de Casos de Uso** 

**2.2 Diagramas de Sequência** 
	

1. O diagrama abaixo detalha o fluxo temporal e a troca de mensagens para a validação de ameaças. Ele evidencia a lógica condicional do sistema, onde o envio de uma imagem aciona primeiramente a extração de texto (OCR), seguida do descarte da mídia e da rotina local de mascaramento de dados pessoais, etapas que antecedem obrigatoriamente qualquer transmissão à camada de análise semântica. Em seguida, demonstra a consulta da IA ao repositório de padrões e o retorno do Score de Risco, finalizando com o salvamento assíncrono do histórico no banco de dados. 

Fluxo do Diagrama de Sequência: Análise de Ameaças (Print ou Link) 

2. O diagrama de sequência abaixo ilustra o fluxo de autenticação inicial e criação de conta no aplicativo. O processo detalha desde a submissão das credenciais na interface em Flutter e as validações locais de formatação, até a comunicação assíncrona com o *Firebase Authentication* para a geração do *token* de acesso. Adicionalmente, o diagrama demonstra a etapa de inicialização do banco de dados, evidenciando o momento em que a arquitetura cria o documento matriz do perfil no *Cloud Firestore*, estruturando as coleções necessárias para o futuro armazenamento do histórico de análises e liberando o acesso do usuário aos módulos de proteção. 

Fluxo do Diagrama de Sequência: Cadastro do usuário.

3. O diagrama de sequência referente ao gerenciamento de reportes comunitários demonstra o ciclo de vida completo de uma denúncia no sistema. Ele mapeia as requisições assíncronas entre a interface móvel e o banco de dados, detalhando o fluxo de criação de um novo alerta criptografado via *hash* e a consulta de visualização do *feed* público. Adicionalmente, o diagrama evidencia o mecanismo de segurança para as operações de edição e exclusão, demonstrando a validação de privilégios que garante que apenas o autor original do documento tenha permissão para modificar ou remover o registro da base de dados. 

Diagrama de Sequência de Gerenciamento de Reportes (CRUD)

**2.3 Diagramas de Classe**

1. A representação estrutural abaixo mapeia a arquitetura estática da aplicação, definindo os modelos de dados que trafegam entre a interface em *Flutter* e o banco de dados *Cloud Firestore*. O diagrama destaca os atributos essenciais das entidades centrais ( **Usuário****, ****AnaliseRisco**** **e** ****ReporteComunidade**) e a utilização de classes enumeradoras (*Enums*) para padronizar parâmetros do sistema, como o termômetro de periculosidade e a classificação de táticas como o mimetismo visual. Além disso, demonstra as regras de multiplicidade, indicando como a conta de um usuário se relaciona com seus múltiplos registros de histórico e denúncias na comunidade. 

Diagrama de Classes: Estrutura de Entidades e Modelos de Dados
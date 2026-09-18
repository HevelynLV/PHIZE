**RELATÓRIO DE VIABILIDADE E POSICIONAMENTO DE MERCADO: PHIZE**

**Projeto:** Projeto Multidisciplinar Integrador 

**Integrantes:** Hevelyn Leivas, Gabriel Mascia e Maisa Grundler.

**1 ANÁLISE DE MERCADO**

O mercado de segurança digital no Brasil é urgente e está em plena expansão devido ao alto índice de crimes cibernéticos. Embora existam soluções consolidadas, elas focam majoritariamente em aspectos técnicos (vírus e spam), deixando uma lacuna na análise de engenharia social:

- **Truecaller e Whoscall:** Atuam como líderes na identificação de chamadas e SMS de *spam*, mas não analisam o conteúdo de conversas em aplicativos de mensagens ou links de forma profunda.

- **Avast e Norton (Antivírus Mobile):** Focam em proteger o sistema contra *malwares* e arquivos infectados, mas possuem limitações operacionais para detectar golpes baseados puramente em texto e persuasão psicológica.

- **Assistentes de verificação de golpes baseados em IA:** ferramentas que analisam mensagens, links e capturas de tela por meio de modelos de linguagem, bem como os mecanismos nativos de detecção de fraude incorporados a aplicativos de mensagem. Representam os concorrentes funcionalmente mais próximos da proposta e operam majoritariamente em inglês, sobre padrões de fraude do mercado norte-americano.

- **Diferencial de Mercado:** a vantagem defensável do Phize não reside na adoção de modelos de linguagem, tecnologia acessível por contratação de API a qualquer concorrente, mas na base curada de padrões de fraude praticados no Brasil e na correção pedagógica aplicada no momento exato do risco. Modalidades como o falso parente que alega troca de número, a falsa central de segurança bancária, o boleto adulterado e a devolução de Pix indevido possuem gatilhos linguísticos e contexto operacional específicos, insuficientemente representados nas soluções internacionais. Esse acervo constitui o único componente do produto que não pode ser replicado pela simples contratação de um fornecedor.

**2 *****STAKEHOLDERS***** EXTERNOS**

Além do ambiente acadêmico, diversos atores possuem interesse direto no sucesso operacional e na escalabilidade deste projeto:

- **Usuários finais (vítimas em potencial):** Especialmente idosos e pessoas com menor letramento digital, que buscam proteção prática e vereditos de segurança rápidos.

- **Empresas de tecnologia em IA:** Atuam como parceiros fundamentais para o fornecimento de APIs de processamento visual (OCR) e Processamento de Linguagem Natural (ex.: Google Cloud Vision, Google Gemini, OpenAI), cuja seleção está condicionada à oferta de termos contratuais que vedem o uso do conteúdo submetido para treinamento de modelos, conforme RNF07.

- **Instituições Financeiras e Fintechs:** Entidades bancárias que poderiam integrar a tecnologia em seus ecossistemas para reduzir o volume de fraudes via PIX contra seus clientes.

- **Órgãos de Segurança Pública:** Entidades responsáveis pelo combate a crimes cibernéticos, que podem utilizar os dados agregados e anonimizados da comunidade para identificar e desarticular novas redes de golpistas.

**3 PROPOSTA DE DIFERENCIAÇÃO**

A solução Phize estabelece sua vantagem competitiva baseada em três pilares principais de diferenciação técnica:

- **Análise Contextual de Prints:** Utilização de Inteligência Artificial para interpretar a intenção intrínseca por trás de mensagens de texto em imagens, identificando falsos sensos de urgência e solicitações financeiras suspeitas.

- **Score de Risco em Tempo Real:** Fornecimento de um indicador visual claro e imediato acerca do nível de perigo de um link ou conversa, facilitando o processo de tomada de decisão, especialmente para o usuário leigo.

- **Foco Educativo:** A aplicação não atua apenas de forma restritiva (bloqueio), mas atua com correção pedagógica, explicando os pilares do golpe detectado para promover o aumento contínuo da consciência digital do usuário a longo prazo.

**4 VIABILIDADE**

Para assegurar a execução sustentável do projeto, os desafios de implementação foram categorizados em duas frentes de viabilidade:

**4.1 Viabilidade Técnica**

- **Desafio:** O processamento ininterrupto de imagens (via OCR) acoplado à análise por Grandes Modelos de Linguagem (LLM) possui o potencial de gerar alta latência de resposta e custos elevados de infraestrutura em servidores.

- **Solução:** Iniciar o Produto Mínimo Viável (MVP) utilizando modelos de linguagem otimizados e APIs de baixo custo. A arquitetura priorizará o processamento do texto já extraído localmente, reduzindo drasticamente o volume de dados brutos enviados para a nuvem.

**4.2 Viabilidade de Mercado**

- **Desafio:** Estabelecer um vínculo de confiança com o usuário final para que este sinta segurança ao compartilhar capturas de tela de conversas privadas, dada a natureza altamente sensível dessas informações.

- **Solução:** Adotar uma estratégia arquitetural rígida de privacidade (*Privacy by Design*), garantindo sistemicamente que as imagens não sejam armazenadas (Persistência Zero), que os dados pessoais de formato estruturado sejam mascarados no próprio dispositivo antes de qualquer transmissão, e que o conteúdo analisado não seja persistido em base própria, de modo que o histórico registre o veredito sem permitir a reconstituição da conversa original, inclusive pela equipe de desenvolvimento. Paralelamente, o foco inicial de aquisição será direcionado ao nicho de usuários que já sofreram fraudes, possuindo maior propensão à adoção de medidas de segurança ativas.

- **Desafio de licenciamento:** a API de reputação de domínios adotada no MVP é licenciada para uso não comercial. Solução: a evolução do produto para modelo de receita, incluindo eventual integração com instituições financeiras, exige migração prévia para a modalidade comercial equivalente, condição a ser considerada no planejamento de custos de qualquer estratégia de monetização.
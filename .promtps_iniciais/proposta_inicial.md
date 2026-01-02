# n-agent - Assistente pessoal de viagens

Vamos criar uma plataforma de criação e configuração de um agente pessoal que vai ter capacidade de conectar em serviços e ajudar na organização pessoal e de trabalho de uma pessoa em idade produtiva. 

# Ideia geral

Um serviço de plataforma que vende pacotes de um assistente pessoal para organização de atividades em agendas de viagens.  

O objetivo é apoiar pessoas normais a entender, estruturar, organizar a viagem. Também, vai oferecer serviços relacionado a turismo dentro da plataforma.

---

# Modelo de Negócio e Monetização

## Planos e Pricing

| Plano | Preço | Limites | Funcionalidades |
|-------|-------|---------|-----------------|
| **Gratuito** | R$ 0 | 1 viagem/ano, até 4 pessoas | Fases 1-2 (Conhecimento + Planejamento básico), sem concierge |
| **Planejador** | R$ 49/viagem | Ilimitado pessoas, 1 viagem ativa | Fases 1-3, documentos ricos, versionamento de roteiros |
| **Concierge** | R$ 149/viagem | Ilimitado pessoas, 3 viagens ativas | Todas as fases, alertas em tempo real, suporte prioritário |
| **Família (Anual)** | R$ 399/ano | Até 5 viagens/ano, ilimitado pessoas | Tudo do Concierge + desconto em parceiros |

## Fontes de Receita Adicionais

1. **Comissões de Afiliados**: 3-8% em reservas via links de Booking/Airbnb/Skyscanner
2. **Serviços Premium**: Impressão de álbum de memórias (R$ 89-199)
3. **Parcerias B2B**: Agências de viagem usando a plataforma white-label
4. **Upsell de Seguros**: Comissão em seguros viagem vendidos via plataforma

## KPIs de Sucesso do MVP

| Métrica | Meta 6 meses | Meta 12 meses |
|---------|--------------|---------------|
| Usuários cadastrados | 1.000 | 5.000 |
| Conversão Free → Paid | 8% | 12% |
| NPS pós-viagem | > 40 | > 50 |
| Retenção (2ª viagem) | 30% | 45% |
| Receita média/usuário pago | R$ 80 | R$ 120 |

---

# Requisitos funcionais

## Interface com o usuário

### Interação do site

Teremos um site web público para:

1. divulgação do produto
2. contratação do serviço
3. painel de controle do usuário e visualização de documentos de resposta de conteúdo rico da IA (veja mais detalhes abaixo) 
4. painel de controle de parceiros/fornecedores
5. painel de controle de administradores
6. Central de Ajuda e FAQ Dinâmico: Uma área onde dúvidas comuns sobre o uso da IA são respondidas automaticamente.

Os usuários poderão receber respostas da IA no formato de relatórios com conteúdo ricos, como imagens de mapas, links, tabelas, informações de preços, etc. Vamos usar a estrutura do site para exibir este conteúdo para o usuário.

[Dúvida] Deveríamos ter um app mobile para capturar a localização, dando mais informações sobre a viagem para o agente? Assim, conseguimos mais contexto. [Todo] Se seguirmos por este caminho, como trabalhar a privacidade dos dados?

### Interação padrão do usuário

Os inputs do usuário se dará exclusivamente via chat com a IA "n-agent" e via interface web para pequenas rotinas (como finalização de itens em listas de tarefas). O chat se dará em duas interfaces: **chat via interface web** (MVP) e chat via WhatsApp (pós-MVP, aguardando aprovação Meta). Ambas interfaces devem suportar os seguintes tipos de input:

> **📝 Nota MVP**: A integração com WhatsApp foi movida para pós-MVP pois a Meta ainda não liberou o acesso à API. Ver [MVP_SCOPE_UPDATE.md](./fases_implementacao/MVP_SCOPE_UPDATE.md)
    
- texto (o mais comum, com suporte a emoticons, links e formatação MD)
- imagens 
- áudio
- localização
- documentos

Interfaces especiais:

- O usuário pode encaminhar e-mails (ex: confirmações de reserva) diretamente para um e-mail do bot. O reconhecimento da viagem se dará por contexto (endereço de e-mail do usuário e data da ação descrita).
- O usuário poderá encaminhar mensagens de outros usuários via encaminhamento do Whatsapp para o bot guardar os registros. Por exemplo: "fiz a reserva do observatório The Edge para 23/05 para todos nós". 


Os outputs podersão ser:

- texto (com suporte a emoticons, links e formatação)
- localização (um link para abertura do aplicativo de localização padrão do celular, como o Google Maps ou Apple Map)
- Link para um documento rico, gerado e exibido em uma interface web com a resposta a solicitação do usuário.
- Listas de tarefas ou dúvidas
- Botões de Ação Rápida (Quick Replies): No WhatsApp e Web, oferecer botões como "Confirmar", "Ver Mais Detalhes", "Alterar Roteiro" para agilizar a interação e evitar digitação.

## Integrações e capacidades do agente

Vamos dividir este projeto em fases, sendo a fase atual o MVP do produto. Nesta primeira fase o agente deve ter as seguintes capacidades:

1. Fase de conhecimento do cliente e da viagem: é a fase onde montamos um dossiê de informações sobre a viagem, acompanhantes, objetivos (pessoais e do grupo de viagem), destinos, itinerário desejado, budget e datas. Estas informações devem ser persistidas e devem permear todas as fases posteriores.
    - [Requisito Adicional] Perfilamento de Risco e Acessibilidade: Identificar restrições alimentares, alergias, dificuldades de locomoção (acessibilidade) ou medos (ex: medo de avião) dos integrantes.
    - Entender restrições de locais e atrações por pessoa ou para todo o grupo. Por exemplo: medo de lugares fechados, medo de altura. Isso não deve limitar as sugestões, mas deve ajudar no rankeamento das opções.
2. Fase de planejamento da viagem: usando as informações do passo anterior, devemos estudar os requisitos para atingir os objetivos da viagem. Devemos apresentar um resumo das atrações e um detalhamento dos custos e esforços de atingir os objetivos, com timelines e riscos, para auxiliar na tomada de decisão dos roteiros. Esta é a fase mais complicada porque a viagem ainda pode estar em momento de definição da quantidade de destinos, quantidade de pessoas, etc. Devemos usar todas as ferramentas possíveis para diminuir custos e oferecer experiências condizentes com os objetivos dos usuários.
    - [Requisito Adicional] Versionamento de Roteiros: O sistema deve permitir salvar "Versão A (Econômica)" e "Versão B (Conforto)" para comparação lado a lado. Também tem que guardar versões das alterações dos roteiros para ajudar a entender motivações das alterações do roteiro.
    - [Dúvida] Seria possível criar um roteiro onde os administradores do roteiro recebem sugestões de outros usuários e avaliam as sugestões para então incrementar no roteiro base? Por exemplo: o filho sugere uma adição de passar em uma livraria. O pai recebe esta alteração, com a IA calculando os impactos desta mudança no roteiro.
3. Fase de contratação de serviços e gestão da viagem: é a fase onde vamos começar a concretizar a viagem, organizando os momentos certos de contratar serviços e organizar as informações da viagem, sempre com o cuidado de revisar cada aspecto da viagem para antecipar problemas para evitar transtornos para os usuários. Vamos guardar cada aspecto da viagem: agenda, locais, ingressos, custos, documentos, informações sobre os locais de visita, serviços contratados, etc.
    - [Sugestão] Gestão de Vouchers Offline: Garantir que todos os PDFs e QRCodes essenciais sejam enviados para o WhatsApp, Google Drive ou e-mail para acesso mesmo sem internet.
4. Fase de execução da viagem (concierge): nesta fase já temos todos os serviços definidos e viagem começou! Vamos desde o início auxiliar a visita com resumos do roterio, mensagens com lembretes e informações, chat para tirar dúvidas ou auxiliar em casos de incidentes. A IA entraria em contato um pouco antes de cada evento para dar insights e informações para auxiliar em momentos chave, como o link para um ingresso um pouco antes do momento de entrar na atração ou informações sobre o portão de embarque e como fazer para chegar até o local. 
    - [Requisito Crítico] Modo Offline/Baixa Conexão: A IA deve saber quando o usuário pode estar sem internet e enviar pacotes de informação (resumo do dia seguinte) com antecedência via WhatsApp.
    - [Requisito Adicional] Fuso Horário Inteligente: O agente deve considerar proativamente o jet lag e ajustar sugestões de atividades no primeiro dia, além de saber o horário local exato para envio de alertas.
6. Fase de organização de memórias: aqui a plataforma vai trabalhar com a montagem de informações sobre a viagem, organizando albúns, locais no mapa, informações da viagem para preseravar a memória do usuário e de seu grupo.

Para realizar estas capacidades, temos que entregar as seguintes ferramentas para a plataforma:

- Um conjunto de agentes capazes de trabalhar com as ferramentas de trabalho necessárias para atender a plataforma e para performar análise crítica do pedido do usuário.
- Ferramentas compartilhadas da plataforma: contexto rápido, local para guardar dados persistentes, ferramenta para armazenas tarefas preenchidas para controle da IA, seleção de IA
- Ferramentas de mapas: Google Maps
- Ferramentas de recomendação e ranking: TripAdvisor, Google Maps, Booking,Blogs de viagem do Google Search
- Ferramentas para hospedagem: AirBnB, Booking, Kayak, Trivago
- Ferramentas para passagens: Kayak, Google Flights, Sky Scanner, ViajaNet, MaxMilhas
- Regras de viagem para países: Sherpa
- Integração com aeroportos para identificar status de voos
- Fontes de dicas que estão na moda: Instagram, Youtube
- Integração com 
    - Whatsapp para interface com o usuário, 
    - Google Maps para apresentação/criação de marcadores de visita, 
    - Integração com Google Calendar ou Outlook para gestão da agenda da visita,
    - Integração com aplicativos de notas e tarefas, como o Google Keep, Microsoft Todo e Evernote para criação de listas com tarefas para os integrantes do grupo de viagem.
    - Integrações com serviço de clima e canais do Youtube com informações para viajantes da época visitada
    - [Nova Integração] Câmbio e Conversão: API para cotação de moedas em tempo real (ex: Open Exchange Rates) para ajudar na decisão de compras.
    - [Nova Integração] Serviços de Tradução: Integração com DeepL ou Google Translate API para tradução automática de cardápios via foto ou negociações locais.
    - [Nova Integração] Clima e Alertas: APIs meteorológicas (ex: OpenWeather) para avisar sobre chuva e sugerir roteiros alternativos indoor automaticamente.

# Requisitos técnicos

## Infraestrutura e arquitetura

- Toda a plataforma deve ser definida com IaC e infraestrutura 100% AWS, com a maior quantidade de serviços serverless
- Vamos usar uma estrutura de microserviços Lambda + Bedrock Agents para tornar o ambiente pay as you Go, com foco em otimização de custos vs vantagens das soluções implementadas
- Banco de dados DynamoDB, com modelagem a seu critério
- ~~[Sugestão] Cache Strategy (ElastiCache/Redis)~~: **REMOVIDO** - AgentCore Memory já implementa caching de sessões nativamente. Ver [MVP_SCOPE_UPDATE.md](./fases_implementacao/MVP_SCOPE_UPDATE.md)
- Backend em node, com frontend em React
- Interface visual respeitando o Material Design M3 Expressive
- BFF para controle e orquestração das informações
- endpoint específico para integrações com aplicações terceiras
- Solução agnóstica ao modelo de IA para processamento do fluxo, usando uma mescla de AWS Nova, Gemini e Claude para as tarefas
- [Requisito de Segurança] Privacidade e LGPD/GDPR: Como a plataforma lida com dados sensíveis (Passaportes, cartões, dados de menores), é crucial implementar criptografia em repouso e políticas claras de retenção e exclusão de dados.

## Website

- Ter domínio público para promoção da plataforma e captação de clientes, com integração com solução de pagamentos seguros do serviço
- Painel de controle para clientes, com um menu de gestão da conta, meios de pagamento, criação de acessos para participantes do grupo de viagem
    - [Funcionalidade] Gestão de Permissões do Grupo: Definir quem pode alterar o roteiro (ex: Pai/Mãe) e quem pode apenas visualizar (ex: Filhos/Amigos), para evitar que alguém cancele um hotel sem querer.
- Painel de controle para gestão do ambiente, usados pelos administradores
- Painel de controle para terceiros, como fornecedores e parceiros
- Para o painel de clientes, ter um sistema de documentos com formatação rica, como o Evernote, onde o conteúdo é apresentado em um sistemas de fichário, onde os documentos podem ser compartilhados ou acessíveis via link gerado pela IA


## Fluxos

1. Criação de conta e contratação do serviço

    - Sou um interessado no uso da plataforma e quero levar a minha família para uma viagem na Europa. 
    - Entrei no site público do n-agent e me interessei pelo serviço. Criei a minha conta usando como chave meu e-mail e número do Whatsapp, além de outros dados básicos cadastrais.
    - Para acessar o painel, tive que validar o meu número do Whatsapp com um código enviado e o e-mail (caso seja um e-mail integrado via OAUTH com Google e Mirosoft, não é necessário verificar).
    - Sou apresentado ao console onde eu posso criar uma nova viagem, gerir minha conta ou ver mais informações na documentação. Criei um nova viagem que chamei Eurotrip 2027, sem data definida e com 7 membros.
    - Após a criação da viagem, sou questionado sobre os tipos de contratação por viagem: gratuito, planejador ou concierge, com valores e limitações por tipo. 
    - Informei dados de faturamento e paguei com o meu cartão de crédito o plano concierge, onde eu terei o agente para organizar e o antes, durante e finalizar a minha viagem.

2. Fase de conhecimento

    - Com a confirmação do pagamento, eu recebi a mensagem do meu agente no Whatsapp se apresentando e explicando resumidamente o processo de planejamento, dividido nas fases conhecimento, planejamento, contratação, concierge e memórias. E ele começou a pedir informações da fase de conhecimento. 
    - Informei os seguintes dados para o agente: quero viajar pela Europa com minha família composta por mim, esposa, dois filhos e dois sobrinhos. Estamos pensando em viajar pela Inglaterra, França e Itália, ainda sem cidades planejadas. Se der tempo, quem sabe visitar a Espanha também. Nossas férias estão marcadas para o mês inteiro de agosto de 2027, mas podemos considerar 10 dias antes e depois deste mês como datas possíveis. A quantidade de dias deve ficar entre 18 e 22 dias. Nossos últimos 5 dias devem ser em Roma e Florença, onde vamos encontrar um casal de amigos e vamos dividir a hospedagem com eles. 
    - A IA então confirmou que guardou os dados e perguntou qual era o objetivo da viagem, com exemplos por quais atrações gostaríamos de visitar. Respondi: nosso objetivo é visitar as capitais (Londres, Paris, Roma) algumas cidades que acharmos interessanes na Itália e as suas atrações principais, com mistura de atrações pagas e gratuitas, sempre tentando equilibrar os custos. 
    - A IA confirmou o registro e pediu dados sobre a forma de transporte, com algumas sugestões. Pedi: transporte público é a preferencia já que queremos economizar e temos um grupo jovem e disposto. Preferência em casas de aluguel para economizar com a quantidade de pessoas. Trem seria a forma mais interesante de transporte entre as cidades, mas podemos pensar em avião se o roteiro tiver cidades muito distantes. Na região da Toscana, eu gostaria de alugar um carro para passear um ou dois dias pela região.
    - A IA gerou um resumo das informações e confirmou que podemos passar para a próxima fase, mesmo com algumas informações sem definição, como as cidades, datas e locais de preferência. A IA informou um link que cai em uma página do painel do agente, com um documento de título, Fase 1 - Conhecendo a viagem, contendo o resumo das informações dadas, um mapa com um ícone de alfinete para cada local informando uma agenda simplificada com os ranges de datas. Finalizou perguntando: podemos seguir para a fase de planejamento?
    - Informei então que eu estava preocupado com informações sobre documentação necessária para a viagem já que um dos sobrinhos é menor de idade e eu quero dirigir um carro alugado. A IA então respondeu com as informações que ela achou: todos temos que ter passaportes com data de vencimento menor do que 6 meses da data da viagem, uma forma de comprovar que temos ao menos 30 euros por dia por pessoa, taxas para autorização de viagem na Europa, PID para direção internacional e que eu posso levar meu sobrinho se ele tiver a observação em seu passaporte que ele pode viajar desacompanhado. Gerou um relatório no painel onde eu cliquei e revi os detalhes do resumo que ele passou. Por exemplo, como eu deveria revisar os dados do passaporte, a opção de enviar as fotos dos passaportes para a IA revisar e registrar na pasta de documentos.
    - Definimos um budget com teto de gastos e informações sobre documentação que já temos (2 pessoas do nosso grupo ainda não tem passaprote brasileiro)
    - Parei de interagir com a IA neste dia, deixando tarefas pendentes.
    - [Sugestão de Melhoria]: Na etapa de documentos, a IA deve validar automaticamente a validade do passaporte lendo a data da foto enviada (OCR) e alertar se expira antes ou durante a viagem, não apenas confiar no texto do usuário.

3. Fase de planejamento

    - No dia seguinte a IA mandou uma mensagem me cumprimentando e dizendo que estava pronta para continuar a discutir a fase de conhecimento ou passar para a fase de planejamento. Não respondi nada. Só voltei a mexer no final de semana, quando a IA enviou outro lembrete. 
    - Comecei pedindo para ela uma sugestão de roteiro e uma sugestão de custos. A IA pediu para eu aguardar enquanto ela gerada um primeiro esboço. Me respondeu com um resumo, sugerindo um voo de São Paulo para Londres no dia 02/08/2027, 4 dias de visita, um trem para Paris, 5 dias de visita, um voo para Nápoles, com 2 dias de visita, um trem para Roma com 4 dias de visita, um trem para Florença, com 4 dias de visita e o voo de retorno para São Paulo. Deu um valor médio de hospedagem usando uma mistura de AirBnB e Booking e sugeriu valores médios de transporte local e alimentação. Gerou o link com o relatório completo, onde detalhou muito mais as informações levantadas com locais sugeridos de hospedagem (próximas a metrôs), lembrou dos meus amigos nos últimos dias de viagem onde aumentamos a quantidade de pessoas para 9 na hospedagem e sugeriu as atrações principais. Tudo com links para visitas.
    - Revisamos ponto a ponto cada sugestão, começando pelas passagens e revisão dos hotéis, optando por hospedagens com ao menos 2 banheiros e que estivessem fácil acesso a atrações. Pedi um estudo de quanto vale a pena ficar longe da cidade e economizar na estadia, mas gastar mais tempo e dinheiro no deslocamento, o que foi prontamente feito, alterando as sugestões de hospedagem. 
    - Deposi revisamos a alimentação, transporte, atrações. Adequamos as sugestões de atrações com público de maioria jovem, com algumas lojas de grife, visitas a bibliotecas, museus e até um show. Mudamos algumas sugestões de datas para conseguirmos visitar locais icônicos, como a Disneyland Paris e o palácio de Versalhes.
    - Por último, o agente me ajudou a entender como devemos nos preparar com checklists de documentos, serviços (seguro viagem, seguro de carro, aluguel de carro), dicas para economia sugerindo e revisando o tipo do meu cartão de crédito para usar serviços no exterior, comparando ofertas de serviços de roaming internacional para internet no local de visita, sugerindo locais de alimentação para datas especiais, etc.
    - Os documentos desta fase foram organizados com resumos, links, condições e pré-requisitos, uma timeline para acompanhamento das datas limites (por exemplo, o ticket do coliseu deve ser comprado com 30 dias de antecedência, nem antes nem depois, mas a maioria precisa ser comprada com antedência).
    - [Funcionalidade]: "Edição Manual do Usuário". Se a IA sugerir algo que o usuário odeia, ele deve ter uma forma fácil no painel web de clicar e substituir ou excluir o item, e a IA deve recalcular o resto (replanejamento dinâmico). 

4. Contratação de serviços

    - A IA criou listas de serviços, datas e preços para eu realizar a contratação de dados os serviços, desde a passagem até o guia turístico sugerido. Com a ajuda da IA, contratei de serviço a serviço. Alguns deles, pedi para a IA me lembrar depois para ajudar a dividir as parcelas das despesas em meses diferentes. 
    - Para cada serviço contratado, anexei os comprovantes e tickets para a IA revisar os dados (como datas, condições de pagamento, horários de check-in, regras restritivas). As informações validadas são adicionadas no meu roteiro, com links para os documentos originais na plataforma. 
    - A IA registrou todos os pagamentos e criou dashboards com os valores e datas de pagamentos das parcelas. Também me ajudou a criar cofres no Picpay para juntar o dinheiro para alimentação e transporte, afim de provisionar os fundos da viagem e das compras pretendidas pelo grupo, com uma lista de desejos de produtos por pessoa pelo Google Keep.
    - Recebi alertas para lembrar com alguns dias de antecedência a contratação e pagamentos de serviços. A IA também me ajudou na tradução de contratos em inglês de guias turísticos e na avaliação de contratos de seguro saúde. 
    - [Sugestão]: Controle Financeiro Multi-moeda. O painel deve mostrar o gasto estimado em Reais (convertido) e na moeda original (Euro/Libra), permitindo input manual de câmbio pago para controle real do cartão de crédito.
    - [Dúvidas]: Exportação das informações para outros sistemas de controle?.

5. Concierge

    - Alguns dias antes da viagem, todos os integrantes do meu grupo de viagem receberam listas de check-up de itens de malas (tipos de roupas, carregadores, aplicativos de celular instalados, itens de higiene pessoal, etc.), documentos e as previsões do tempo para cada dia. 
    - Algumas horas da viagem eu recebi um link para traçar a rota para o aeroporto no Google Maps, assim como os links para as passagens aéreas de todos do meu grupo. Também recebemos links com a localização e uso de salas VIPs no aeroporto, contextualizadas para o meu cartão de crédito, informações do roteiro do dia com duração do voo.
    - Ao chegar no aeroporto recebi uma mensagem do agente com previsão de qual portão de embarque do meu voo e informações de que o voo estava no horário previsto. 
    - Meu sobrinho trouxe uma mala acima do peso e foi informado que havia cobrança para despacho. Pedi para a IA verificar se havia alguma forma de evitar este custo e ela respondeu que um dos cartões de crédito registrados no sistema dava o benefício de despachos de mala com um peso adequado para meu sobrinho. Economizamos o valor do despacho.
    - Ao chegar no aeroporto de Londres, recebi uma mensagem do agente com as direções para pegarmos o metrô até o AirBnB. As informações continham as direções, valores da tarifa, forma de pagamento (com cartão direto na catraca) e baldiações necessárias, além do tempo médio com um link do Google Maps para acompanhamento.
    - Durante a viagem recebemos diversos alertas, informações sobre o local. Documentos contendo os ingressos, direções e valores ajudaram a preencher informações. Por exemplo, 2 horas antes de retirar o carro alugado, a IA listou os documentos necessários e a direção no Google Maps para o local de retirada. Também alertou de um valor de reserva no cartão de crédito em nome do motorista de 3000 euros, descrito no documento de reserva do veículo. 
    - Em uma das atrações, um dos meus filhos apresentou dor de estômago severa. Perguntei instruções para a IA e de pronto fui informado do telefone de atendimento do seguro viagem em portguês e um template de como eu deveria pedir auxílio. Fui orientado pela atendente a ir a uma clínica conveniada onde fomos atendidos sem custo direto para mim. A IA ajudou no entendimento das regras do seguro sem eu precisar revisar documentos ou pesquisar os contatos.
    - Perdemos a hora de uma atração, o Coliseu. Com isso, não conseguimos mais entrar. A IA informou que não haviam mais ingressos disponíveis e deu duas alternativas: enfrentar a fila da bilheteria, com horas de espera e possibilidade de esgotamento de ingressos, ou comprar bilhete por um tour guiado que a IA encontrou em um site de viagens. A IA conversou com o contato com o tour guiado via Whatsapp e negociou valor e disponibilidade para o meu grupo, eliminando este gasto de tempo. Também sugeriu adiantar outras atrações, alterando a agenda de atrações do dia em nosso roteiro para ocupar o tempo que seria gasto no coliseu.
    - Na última cidade do roteiro, a hospedagem de um apartamento em Florença via Booking tinha um detalhe diferente do esperado, um único banheiro. A IA revisou o artigo da hospedagem e confirmou a informação que haviam dois banheiros e sugeriu contato com o ponto de contato via telefone ou mensagem na plataforma do Booking, sugerindo um template de manesagem em Italiano questionando a falta do banheiro. Não tivemos êxito no contato, com a IA sugerindo contato com o suporte da plataforma do Booking e apresentou 3 possíveis caminhos: aceitar a situação e depois pedir reembolso de valores referentes a falta do recurso contratado, receber uma opção de troca do ponto de contato ou do time de suporte do Booking ou reservar um outra estadia, apresentando opções próximas com valores mais altos da diária, mas condições similares. Usamos a terceira opção e a IA recalculou o controle de gastos para adicionar uma tarifa de ônibus diferente, o valor da diária e ajustou o roteiro com rotas. 
    - [Cenário de Crise]: Adicionar fluxo para "Perda de Documentos" (onde ir, consulado mais próximo, o que levar) e "Greves de Transporte" (muito comum na Europa/França). A IA deve monitorar notícias locais para antecipar greves de trem.

6. Memórias

    - A IA entregou um resumo do roteiro percorrido, um calendário com fotos do local e descrições das mudanças ocorridas durante a viagem.
    - Com uma integração com o Google Fotos, criou um álbum compartilhado com todos os participantes, criando separações por local no álbum para organização. 
    - Ofertou um serviço de impressão do álbum por um valor adicional. 
    - [Sugestão]: Mapa de Calor (Heatmap) dos locais visitados baseado no histórico de localização (se o usuário permitir), criando uma visualização bonita do trajeto real vs. planejado.

## Informações sobre o MVP

> **⚠️ ATUALIZAÇÃO DE ESCOPO**: Consulte [MVP_SCOPE_UPDATE.md](./fases_implementacao/MVP_SCOPE_UPDATE.md) para alterações recentes.

### Escopo Reduzido para MVP (Fase 1 - 3 meses)

Para garantir viabilidade financeira e time-to-market adequado, o MVP terá escopo reduzido:

**Integrações Core (obrigatórias):**
- 🔲 WhatsApp Business API *(estrutura apenas - aguardando aprovação Meta)*
- ✅ **Chat Web** *(interface principal do MVP)*
- ✅ Google Maps Platform (Places + Directions)
- ✅ Booking.com Affiliate API (hospedagem altenativa e atrações)
- ✅ Airbnb (hospedagem principal)
- ✅ AviationStack API (dados de voos e aeroportos em tempo real)
- ✅ OpenWeather API (clima básico)
- ✅ Gemini 2.0 Flash + Google Search Grounding (IA com busca web atualizada)
- Google Calendar (sincronização de agenda)

**Integrações Fase 2 (pós-validação - 3 meses após MVP):**
- **WhatsApp Business API** *(quando aprovado pela Meta)*
- Skyscanner/Amadeus (busca de voos para compra)
- Google Flight
- Open Exchange Rates (câmbio em tempo real)
- DeepL/Google Translate (tradução)
- Car rental (aluguel de carros)

**Integrações Fase 3 (escala - 6+ meses):**
- TripAdvisor, tradução, OCR de documentos

### Funcionalidades do MVP

| Funcionalidade | MVP | Fase 2 | Fase 3 |
|----------------|-----|--------|--------|
| Chat Web | ✅ | ✅ | ✅ |
| Chat WhatsApp | 🔲 estrutura | ✅ | ✅ |
| Fase Conhecimento | ✅ | ✅ | ✅ |
| Fase Planejamento | ✅ (básico) | ✅ (completo) | ✅ |
| Fase Contratação | ❌ (links apenas) | ✅ (parcial) | ✅ |
| Fase Concierge | ❌ | ✅ (básico) | ✅ |
| Fase Memórias | ❌ | ❌ | ✅ |
| Documentos Ricos | ✅ (HTML interativo) | ✅ | ✅ |
| Versionamento Roteiros | ❌ | ✅ | ✅ |
| Multi-moeda | ❌ | ✅ | ✅ |
| OCR Passaporte | ❌ | ❌ | ✅ |

### Limitações Conhecidas do MVP

- Não faremos a contratação de serviços automática, usando o agente, apenas vamos avaliar e indicar as melhores ofertas/serviços encontradas nas integrações para atender o roteiro e oferecer o link para a contratação. Mas no futuro queremos integrar as informações.
- [Estratégia]: Deixar claro nos Termos de Uso que a responsabilidade final da reserva (datas e nomes corretos) é do usuário, já que a IA apenas sugere o link, para evitar processos caso o usuário compre algo errado.
- **Sem modo offline real**: Apenas envio antecipado de informações via WhatsApp
- **Sem integração de pagamentos in-app**: Redirecionamento para sites parceiros
- **Grupos limitados a 10 pessoas**: Para controlar complexidade inicial

---

# Gestão de Grupos e Permissões

## Modelo de Acesso Multiusuário

### Papéis Disponíveis

| Papel | Permissões |
|-------|------------|
| **OWNER** | Tudo: editar, excluir, convidar, pagar, ver financeiro |
| **ADMIN** | Editar roteiro, convidar membros, ver tudo exceto financeiro |
| **EDITOR** | Editar apenas itens próprios, sugerir alterações |
| **VIEWER** | Apenas visualização, receber alertas |

### Fluxo de Convite

1. Owner cria viagem e define orçamento
2. Owner convida membros via WhatsApp ou email
3. Membro recebe link único com token temporário (7 dias)
4. Membro aceita e cria conta (ou vincula existente)
5. Owner aprova e define papel do membro

### Split de Custos (Fase 2)

- Dashboard mostrando "Minha parte" vs "Total da viagem"
- Integração futura com Splitwise ou cálculo interno
- Notificação de "Fulano pagou R$ X, falta você pagar R$ Y"

---

# Fluxos Adicionais

## 7. Cancelamento e Reembolso

- Usuário pode cancelar plano a qualquer momento
- Reembolso proporcional se cancelar antes de 50% do período
- Dados mantidos por 90 dias após cancelamento (LGPD)
- Possibilidade de "pausar" viagem sem perder dados

## 8. Onboarding Gamificado

- Progress bar: "Sua viagem está 40% planejada"
- Conquistas: "Primeiro hotel escolhido! 🏨"
- Checklist visual de tarefas pendentes por membro
- Comparativo: "Viajantes como você geralmente..."

## 9. Cenários de Crise Cobertos

| Cenário | Ação da IA |
|---------|------------|
| Perda de passaporte | Endereço do consulado, documentos necessários, template de BO |
| Greve de transporte | Monitorar notícias, sugerir alternativas, recalcular roteiro |
| Emergência médica | Contato do seguro, hospitais próximos, tradução de sintomas |
| Voo cancelado | Direitos do passageiro, rebooking, compensação |
| Overbooking hotel | Template de reclamação, alternativas próximas |
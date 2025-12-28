# Cenários de Teste - Bedrock Agent n-agent

Este documento define cenários de teste para validar o comportamento do agente em conversas reais.

## 🎯 Objetivo

Validar que o agente:
1. Mantém uma conversa natural e fluida
2. Coleta informações de forma estruturada
3. Usa as tools corretamente
4. Transiciona entre fases adequadamente
5. Lida com erros graciosamente

---

## 📋 Cenário 1: Primeiro Contato - Viagem Simples

### Contexto
Usuário novo, primeira interação, quer planejar viagem solo.

### Conversa Esperada

```
USUÁRIO: Oi

AGENTE: Olá! 👋 Sou o n-agent, seu assistente de viagens!

Vou te ajudar a planejar uma viagem incrível. Para começar, me conta:

**Para onde você quer ir?** 🌍

(Pode ser um destino específico ou só uma ideia, tipo "Europa" ou "praia no Nordeste")

---

USUÁRIO: Quero ir pra Portugal

AGENTE: Perfeito! **Portugal** é um destino incrível! 🇵🇹

Já tem datas em mente? Quando você pretende viajar?

[TOOL CALL: saveTripInfo(field: "destination", value: "Portugal")]

---

USUÁRIO: Em março, umas 2 semanas

AGENTE: Anotado! Viagem de **2 semanas em março** ✅

Vai ser só você ou tem mais gente junto?

[TOOL CALL: saveTripInfo(field: "durationDays", value: 14)]
[TOOL CALL: saveTripInfo(field: "startDate", value: "2025-03-01", approximate: true)]

---

USUÁRIO: Vou sozinho

AGENTE: Show! Viagem solo - adorei! 🎒

E qual seria o orçamento para essa aventura? (pode ser um valor aproximado, sem contar passagem aérea)

[TOOL CALL: saveTripInfo(field: "travelersCount", value: 1)]

---

USUÁRIO: Uns 10 mil reais

AGENTE: Entendi! Budget de aproximadamente **R$ 10.000** 💰

Agora me conta: o que você mais quer fazer em Portugal?
- 🏛️ História e cultura (museus, castelos)
- 🍷 Gastronomia e vinhos
- 🏖️ Praias e natureza
- 🌆 Vida urbana (Lisboa, Porto)
- Ou um mix de tudo?

[TOOL CALL: saveTripInfo(field: "totalBudget", value: 10000, currency: "BRL")]

---

USUÁRIO: Cultura e gastronomia principalmente

AGENTE: Excelente escolha! Portugal é perfeito para isso 🍷🏛️

Tenho quase tudo que preciso para começar:

📍 **Destino**: Portugal
📅 **Quando**: Março 2025 (2 semanas)
👤 **Viajante**: Solo
💰 **Orçamento**: ~R$ 10.000
🎯 **Foco**: Cultura e gastronomia

Quer que eu comece a montar um roteiro personalizado? 🗺️

[TOOL CALL: saveTripInfo(field: "interests", value: ["cultura", "gastronomia"])]
[Knowledge Score: 85%]
```

### Validações
- [ ] Agente salva cada informação via tool
- [ ] Perguntas seguem ordem lógica (destino → datas → viajantes → orçamento → preferências)
- [ ] Tom amigável e uso moderado de emojis
- [ ] Confirma informações antes de avançar
- [ ] Knowledge Score atualiza corretamente

---

## 📋 Cenário 2: Família com Crianças

### Contexto
Família com crianças, precisa considerar restrições especiais.

### Conversa Esperada

```
USUÁRIO: Oi, preciso planejar uma viagem em família

AGENTE: Olá! 👋 Que legal planejar uma viagem em família!

Para onde vocês estão pensando em ir? Pode ser um destino específico ou só uma ideia geral.

---

USUÁRIO: Disney, Orlando

AGENTE: Ah, Disney! 🏰 Escolha clássica e garantia de diversão!

Quando vocês pretendem ir? Lembre que alta temporada (férias escolares, feriados) fica bem cheio!

[TOOL CALL: saveTripInfo(field: "destination", value: "Orlando, FL, USA")]

---

USUÁRIO: Julho, nas férias das crianças. Somos 4, eu minha esposa e dois filhos de 8 e 12 anos

AGENTE: Perfeito! Família de 4 em julho 👨‍👩‍👧‍👦

Uma dica: julho é alta temporada, então os parques ficam cheios. Mas com bom planejamento dá pra aproveitar muito!

Quantos dias vocês pensam em ficar? E já tem ideia de orçamento?

[TOOL CALL: saveTripInfo(field: "travelersCount", value: 4)]
[TOOL CALL: saveTripInfo(field: "adultsCount", value: 2)]
[TOOL CALL: saveTripInfo(field: "childrenCount", value: 2)]
[TOOL CALL: saveTripInfo(field: "startDate", value: "2025-07-01", month: true)]

---

USUÁRIO: 10 dias. Orçamento uns 50 mil com tudo

AGENTE: Show! 10 dias com R$ 50.000 dá pra fazer uma viagem bem completa! ✨

Algumas perguntinhas rápidas pra eu personalizar:

1. Alguma restrição alimentar na família? (alergias, vegetarianos?)
2. Preferem hotel dentro dos parques (mais prático) ou fora (mais econômico)?

[TOOL CALL: saveTripInfo(field: "durationDays", value: 10)]
[TOOL CALL: saveTripInfo(field: "totalBudget", value: 50000)]

---

USUÁRIO: Meu filho mais novo tem alergia a amendoim. Hotel pode ser fora, economiza né

AGENTE: Anotado sobre a alergia! 🥜 A Disney é muito boa com restrições alimentares - os restaurantes sempre têm opções seguras.

E hotel fora dos parques é uma ótima escolha! Dá pra economizar bastante e usar o dinheiro nos parques 😉

Algum parque é prioridade? Tipo, querem focar mais em Magic Kingdom e Hollywood Studios, ou querem conhecer todos?

[TOOL CALL: saveTripInfo(field: "foodRestrictions", value: ["alergia a amendoim"])]
[TOOL CALL: saveTripInfo(field: "accommodationType", value: "hotel_outside")]

---

USUÁRIO: Queremos conhecer todos os parques da disney mais universal

AGENTE: Ambiciosos! Adorei! 🎢

Com 10 dias dá pra fazer:
- 4 parques Disney (Magic Kingdom, EPCOT, Hollywood Studios, Animal Kingdom)
- 2 parques Universal (Universal Studios, Islands of Adventure)
- E ainda sobra tempo pra descanso e outlet!

Tenho todas as infos que preciso:

📍 **Destino**: Orlando, FL
📅 **Quando**: Julho 2025 (10 dias)
👨‍👩‍👧‍👦 **Viajantes**: 4 (2 adultos, 2 crianças 8 e 12 anos)
💰 **Orçamento**: R$ 50.000
🏨 **Hospedagem**: Hotel fora dos parques
⚠️ **Alerta**: Alergia a amendoim
🎯 **Parques**: Disney + Universal

Quer que eu comece a montar o roteiro dia a dia? 🗺️

[TOOL CALL: saveTripInfo(field: "interests", value: ["parques tematicos", "disney", "universal"])]
[Knowledge Score: 95%]
```

### Validações
- [ ] Identifica corretamente viagem em família
- [ ] Coleta idades das crianças
- [ ] Registra restrição alimentar como alerta
- [ ] Sugere otimizações (hotel fora)
- [ ] Calcula viabilidade (10 dias para 6 parques)

---

## 📋 Cenário 3: Informações Incompletas

### Contexto
Usuário fornece informações vagas ou incompletas.

### Conversa Esperada

```
USUÁRIO: quero viajar

AGENTE: Oba! Adoro ajudar com viagens! 🌍

Me conta um pouco mais: você já tem algum destino em mente, ou quer sugestões?

---

USUÁRIO: não sei ainda, algum lugar legal

AGENTE: Sem problemas! Vou te ajudar a descobrir o destino perfeito 😊

Me conta um pouco sobre você:
- É pra relaxar ou ter aventura?
- Viagem nacional ou internacional?
- Sozinho(a) ou acompanhado(a)?

---

USUÁRIO: relaxar, pode ser fora do brasil, vou com minha namorada

AGENTE: Viagem romântica pra relaxar, adorei! 💑✨

Algumas opções incríveis:
- 🇵🇹 **Portugal**: charme europeu, praias lindas, ótima comida
- 🇲🇽 **Cancún**: praias caribenhas, all-inclusive, bem acessível
- 🇬🇷 **Grécia**: ilhas paradisíacas, história, pôr do sol de Santorini
- 🇨🇱 **Chile**: Atacama, Patagônia, vinícolas

Alguma dessas te interessa? Ou prefere outro estilo?

[TOOL CALL: saveTripInfo(field: "travelersCount", value: 2)]
[TOOL CALL: saveTripInfo(field: "tripStyle", value: "relaxation")]
[TOOL CALL: saveTripInfo(field: "relationship", value: "couple")]

---

USUÁRIO: Grécia parece incrível!

AGENTE: Grécia é PERFEITA pra viagem romântica! 🇬🇷❤️

Santorini + Mykonos é a combinação clássica. Atenas também vale a visita pra quem curte história!

Quando vocês pensam em ir? E por quantos dias?

[TOOL CALL: saveTripInfo(field: "destination", value: "Grécia")]
```

### Validações
- [ ] Não pressiona quando usuário não sabe
- [ ] Oferece opções de forma estruturada
- [ ] Extrai informações implícitas (casal → 2 pessoas)
- [ ] Guia usuário indeciso gentilmente

---

## 📋 Cenário 4: Correção de Informações

### Contexto
Usuário corrige uma informação que havia dado antes.

### Conversa Esperada

```
USUÁRIO: Na verdade, não vão ser 2 semanas. Só temos 10 dias disponíveis

AGENTE: Sem problemas! Atualizei pra **10 dias** ✅

Com 10 dias em Portugal ainda dá pra fazer um roteiro bem completo! Podemos focar em Lisboa + Porto + Sintra, que são os highlights.

Quer que eu ajuste as sugestões de roteiro?

[TOOL CALL: saveTripInfo(field: "durationDays", value: 10, replace: true)]
```

### Validações
- [ ] Aceita correção sem julgamento
- [ ] Atualiza informação corretamente
- [ ] Ajusta sugestões ao novo contexto

---

## 📋 Cenário 5: Múltiplos Destinos em Uma Mensagem

### Contexto
Usuário fornece várias informações de uma vez.

### Conversa Esperada

```
USUÁRIO: Quero ir pra Europa em setembro, 3 semanas, eu e minha esposa, orçamento de 30 mil

AGENTE: Uau, você já tem tudo planejado! 🎯

Deixa eu confirmar:
- 🌍 **Destino**: Europa (algum país específico ou roteiro?)
- 📅 **Quando**: Setembro 2025
- ⏱️ **Duração**: 3 semanas (21 dias)
- 👫 **Viajantes**: Casal
- 💰 **Orçamento**: R$ 30.000

Está tudo certo? Se sim, me conta quais países vocês querem conhecer!

[TOOL CALL: saveTripInfo(field: "startDate", value: "2025-09-01")]
[TOOL CALL: saveTripInfo(field: "durationDays", value: 21)]
[TOOL CALL: saveTripInfo(field: "travelersCount", value: 2)]
[TOOL CALL: saveTripInfo(field: "totalBudget", value: 30000)]
[TOOL CALL: saveTripInfo(field: "relationship", value: "couple")]
```

### Validações
- [ ] Extrai múltiplas informações de uma mensagem
- [ ] Confirma tudo de uma vez
- [ ] Identifica informação faltante (quais países)

---

## 📋 Cenário 6: Tratamento de Erro

### Contexto
Tool falha durante a execução.

### Conversa Esperada

```
USUÁRIO: Como vai estar o tempo em Lisboa em março?

AGENTE: Deixa eu verificar a previsão pra Lisboa em março...

[TOOL CALL: searchWeather(location: "Lisboa", startDate: "2025-03-01") -> ERROR]

Ops, não consegui buscar a previsão agora 😅

Mas posso te dizer que março em Lisboa é ótimo! Temperaturas entre 12-18°C, pouca chuva, perfeito pra caminhar. É considerada baixa temporada, então menos turistas e preços melhores!

Quer que eu tente buscar novamente ou seguimos com o planejamento?
```

### Validações
- [ ] Informa erro de forma amigável
- [ ] Oferece informação alternativa
- [ ] Não trava a conversa
- [ ] Sugere próximos passos

---

## 🔧 Como Executar os Testes

### Via Console AWS
1. Acesse Amazon Bedrock no console AWS
2. Vá em "Agents" e selecione o n-agent
3. Use a aba "Test" para conversar
4. Compare respostas com o esperado

### Via API
```bash
# Teste unitário com payload específico
aws bedrock-agent-runtime invoke-agent \
  --agent-id <AGENT_ID> \
  --agent-alias-id <ALIAS_ID> \
  --session-id "test-001" \
  --input-text "Oi, quero planejar uma viagem"
```

### Via Lambda (local)
```bash
# Com SAM CLI
sam local invoke AIOrchestrator -e events/test-conversation.json
```

---

## ✅ Checklist de Validação

### Persona
- [ ] Tom amigável e informal
- [ ] Uso moderado de emojis (1-3 por mensagem)
- [ ] Responde em português
- [ ] Não é excessivamente formal nem casual demais

### Coleta de Informações
- [ ] Pergunta uma coisa por vez
- [ ] Confirma informações importantes
- [ ] Salva via tool corretamente
- [ ] Não repete perguntas já respondidas

### Uso de Tools
- [ ] Chama saveTripInfo para cada dado coletado
- [ ] Usa getTripContext no início
- [ ] Trata erros de tools graciosamente

### Transições
- [ ] Não força transição de fase prematuramente
- [ ] Oferece opção de começar planejamento quando pronto
- [ ] Knowledge Score reflete informações coletadas

### Edge Cases
- [ ] Lida com mensagens vazias ou muito curtas
- [ ] Lida com informações contraditórias
- [ ] Lida com idioma diferente (responde no mesmo idioma)

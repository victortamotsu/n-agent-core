# Fase 2 - Core AI (Semanas 5-7)

## Semana 5: Bedrock Agent Setup

### Tarefas
- [ ] Criar Agent no Amazon Bedrock
- [ ] Definir prompt base do agente (persona, regras, contexto)
- [ ] Configurar Action Groups (estrutura de tools)
- [ ] Criar Lambda orquestradora para invocar o Agent
- [ ] Testar conversa básica via console

### Prompts Iniciais
- System prompt: persona do "assistente de viagens n-agent"
- Prompt de fase conhecimento: perguntas estruturadas
- Prompt de sumarização: gerar resumos de viagem

## Semana 6: Tools do Agente

### Tarefas
- [ ] Tool: `get_trip_context` - busca dados da viagem no DynamoDB
- [ ] Tool: `save_trip_info` - persiste informações coletadas
- [ ] Tool: `search_weather` - consulta OpenWeather API
- [ ] Tool: `search_places` - consulta Google Places API
- [ ] Criar schema OpenAPI para cada tool

### Arquitetura
```
User → WhatsApp → Lambda Ingestion → EventBridge → Lambda Agent → Bedrock Agent → Tools → Response
```

## Semana 7: Persistência e Contexto

### Tarefas
- [ ] Implementar histórico de conversa no DynamoDB
- [ ] Criar janela de contexto (últimas N mensagens)
- [ ] Implementar estado da viagem (fase atual, dados coletados)
- [ ] Criar fluxo de transição entre fases (conhecimento → planejamento)
- [ ] Integrar Gemini + Search para buscas web

### Modelo de Estado
```typescript
interface TripState {
  tripId: string;
  phase: 'KNOWLEDGE' | 'PLANNING' | 'BOOKING' | 'CONCIERGE';
  collectedData: {
    destinations?: string[];
    dates?: { start: string; end: string };
    travelers?: number;
    budget?: number;
    preferences?: string[];
  };
  lastInteraction: string;
}
```

---

## Checklist de Conclusão Fase 2

- [ ] Agent Bedrock configurado e respondendo
- [ ] Tools funcionando (busca, persistência, clima)
- [ ] Histórico de conversa persistido
- [ ] Fluxo de fase conhecimento completo
- [ ] Integração Gemini + Search funcionando

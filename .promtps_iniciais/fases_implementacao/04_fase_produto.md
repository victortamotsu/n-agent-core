# Fase 4 - Produto (Semanas 10-11)

## Semana 10: Frontend Base

### Setup
- [ ] Criar app React + Vite em `/apps/web-client`
- [ ] Configurar Material UI (M3 Expressive)
- [ ] Implementar layout base (header, sidebar, main)
- [ ] Configurar rotas (React Router)
- [ ] Integrar autenticação (Cognito)

### Páginas Públicas
- [ ] Landing page (apresentação do produto)
- [ ] Página de planos e preços
- [ ] Login/Signup
- [ ] FAQ

### Painel do Usuário
- [ ] Dashboard (lista de viagens)
- [ ] Criar nova viagem
- [ ] Detalhe da viagem (timeline)
- [ ] Configurações da conta

## Semana 11: Chat Web + Documentos

### Chat Web
- [ ] Componente de chat (input, mensagens, histórico)
- [ ] WebSocket para tempo real (API Gateway WebSocket)
- [ ] Renderização de mensagens ricas (cards, carousels)
- [ ] Quick replies (botões de ação)
- [ ] Upload de arquivos (imagens, docs)

### Documentos Ricos
- [ ] Lambda `doc-generator` para criar HTML/PDF
- [ ] Templates: roteiro, checklist, voucher
- [ ] Visualizador de documentos no painel
- [ ] Geração de links compartilháveis (URLs assinadas S3)

### BFF (Backend for Frontend)
- [ ] Endpoint `/api/trips` - CRUD viagens
- [ ] Endpoint `/api/trips/{id}/dashboard` - dados do painel
- [ ] Endpoint `/api/chat/{tripId}` - histórico de chat
- [ ] Endpoint `/api/docs/{docId}` - documentos

---

## Checklist de Conclusão Fase 4

- [ ] Site rodando e acessível
- [ ] Login/cadastro funcionando
- [ ] Painel mostrando viagens
- [ ] Chat web enviando e recebendo mensagens
- [ ] Documentos sendo gerados e visualizados
- [ ] Design M3 aplicado consistentemente

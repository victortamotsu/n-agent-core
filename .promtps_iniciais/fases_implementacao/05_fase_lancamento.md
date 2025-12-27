# Fase 5 - Lançamento (Semana 12)

## Testes

### Testes Automatizados
- [ ] Testes unitários (Jest) - cobertura mínima 70%
- [ ] Testes de integração (APIs externas mockadas)
- [ ] Testes E2E básicos (Playwright/Cypress)

### Testes Manuais
- [ ] Fluxo completo: signup → criar viagem → chat → ver roteiro
- [ ] Teste em dispositivos móveis (responsividade)
- [ ] Teste de carga básico (Artillery/k6)

## Segurança

### Checklist
- [ ] WAF configurado no CloudFront
- [ ] Rate limiting no API Gateway
- [ ] Secrets no AWS Secrets Manager
- [ ] Criptografia S3 (SSE-KMS)
- [ ] Logs de auditoria habilitados
- [ ] CORS configurado corretamente
- [ ] Headers de segurança (CSP, HSTS)

### LGPD
- [ ] Termos de uso e política de privacidade
- [ ] Mecanismo de exclusão de dados
- [ ] Consentimento explícito no cadastro

## Deploy Produção

### Infraestrutura
- [ ] Criar ambiente `prod` no Terraform
- [ ] Configurar domínio e SSL (Route53 + ACM)
- [ ] Deploy via pipeline (branch main → prod)
- [ ] Configurar CloudWatch Alarms
- [ ] Configurar backups automáticos

### Go-Live
- [ ] Smoke tests em produção
- [ ] Monitoramento 24h inicial
- [ ] Documentação de operação (runbooks)
- [ ] Canal de suporte (email/chat)

---

## Checklist Final MVP

- [ ] Usuário cria conta e viagem via WhatsApp
- [ ] IA coleta informações e sugere roteiro
- [ ] Painel web mostra viagem e documentos
- [ ] Pagamento de planos funcionando
- [ ] Latência < 10s, uptime > 99%
- [ ] Zero vulnerabilidades críticas
- [ ] Pronto para beta testers!

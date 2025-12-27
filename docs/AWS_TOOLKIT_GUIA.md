# 🚀 Guia: Desenvolvimento de Lambdas com AWS Toolkit

## 📋 Pré-requisitos (Já Configurados)
✅ AWS Toolkit instalado
✅ AWS CLI configurado
✅ Docker instalado (necessário para SAM Local)

## 🎯 Como Usar: 3 Métodos

### **Método 1: Debug com Breakpoints (RECOMENDADO)**

#### Passo a Passo:

1. **Bundle a Lambda** (sempre antes de debugar):
   ```powershell
   node scripts/bundle-lambdas.js
   ```

2. **Abra o arquivo da Lambda** que você quer debugar:
   - `services/trip-planner/src/index.ts`
   - `services/whatsapp-bot/src/webhook.ts`
   - `services/integrations/src/index.ts`

3. **Coloque breakpoints** (clique na margem esquerda da linha)

4. **Vá para Debug Panel** (Ctrl+Shift+D) e selecione:
   - `Debug Trip Planner - Health Check`
   - `Debug Trip Planner - Create Trip`
   - `Debug WhatsApp Bot - Webhook Verify`
   - `Debug WhatsApp Bot - Receive Message`
   - `Debug Integrations - Health`

5. **Pressione F5** ou clique no botão verde "▶ Start Debugging"

6. **Interaja com o código**:
   - Veja variáveis
   - Execute passo a passo (F10)
   - Entre em funções (F11)
   - Continue execução (F5)

#### 💡 Exemplo Prático:

```typescript
// services/trip-planner/src/index.ts
export async function handler(event: APIGatewayProxyEventV2) {
  const method = event.requestContext.http.method;  // 👈 Coloque breakpoint aqui
  const path = event.rawPath;
  
  if (path === '/health') {  // 👈 Ou aqui para ver o resultado
    return {
      statusCode: 200,
      body: JSON.stringify({ status: 'healthy' })
    };
  }
}
```

---

### **Método 2: Invoke Local via Linha de Comando**

Útil para testes rápidos sem debug:

```powershell
# 1. Bundle primeiro
node scripts/bundle-lambdas.js

# 2. Teste Trip Planner
sam local invoke TripPlannerFunction -e events/health-check.json

# 3. Teste WhatsApp Bot (verificação)
sam local invoke WhatsAppBotFunction -e events/whatsapp-webhook-verify.json

# 4. Teste WhatsApp Bot (mensagem)
sam local invoke WhatsAppBotFunction -e events/whatsapp-message.json

# 5. Teste com create trip
sam local invoke TripPlannerFunction -e events/create-trip.json
```

---

### **Método 3: API Local Completa**

Inicia um servidor local que simula API Gateway:

```powershell
# 1. Bundle
node scripts/bundle-lambdas.js

# 2. Inicie a API local
sam local start-api --port 3000

# 3. Em outro terminal, teste:
curl http://localhost:3000/health
curl http://localhost:3000/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=local_test_token&hub.challenge=test123
curl -X POST http://localhost:3000/api/v1/trips -H "Content-Type: application/json" -d '{\"name\":\"Paris\"}'
```

---

## 🔧 Workflow de Desenvolvimento

### Opção A: Debug Intensivo (Problemas Complexos)

```powershell
# 1. Edite o código
# 2. Bundle
node scripts/bundle-lambdas.js

# 3. F5 para debugar (coloque breakpoints)
# 4. Repita até funcionar
```

### Opção B: Teste Rápido Local

```powershell
# 1. Edite o código
# 2. Bundle
node scripts/bundle-lambdas.js

# 3. Teste via SAM
sam local invoke TripPlannerFunction -e events/health-check.json

# 4. Se OK, repita ou vá para AWS
```

### Opção C: Teste Direto na AWS

```powershell
# 1. Edite o código
# 2. Deploy rápido
.\scripts\quick-deploy.ps1 -Service trip-planner -Environment dev

# 3. Teste na AWS real
curl https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/health

# 4. Ver logs
pnpm run logs:trips
```

---

## 📁 Arquivos Criados

```
template.yaml                    # SAM template para local
.vscode/launch.json             # Configurações de debug
events/
  ├── health-check.json         # Evento de health check
  ├── create-trip.json          # Evento de criar viagem
  ├── whatsapp-webhook-verify.json  # Verificação webhook
  └── whatsapp-message.json     # Mensagem WhatsApp
```

---

## 🐛 Debug Tips

### Ver Logs no Console
```typescript
console.log('Debug:', { method, path, body });  // Aparece no terminal
```

### Modificar Eventos de Teste
Edite os arquivos em `events/*.json` para testar diferentes cenários

### Ver Variáveis de Ambiente
No debug, veja a aba "Variables" → "Local" → `process.env`

### Testar Erros
Adicione código que lança erro:
```typescript
throw new Error('Teste de erro');
```

---

## ⚡ Atalhos Úteis

| Atalho | Ação |
|--------|------|
| `F5` | Iniciar debug |
| `Shift+F5` | Parar debug |
| `F10` | Próxima linha (step over) |
| `F11` | Entrar na função (step into) |
| `Shift+F11` | Sair da função (step out) |
| `Ctrl+Shift+D` | Abrir painel de debug |

---

## 🎯 Próximos Passos

1. **Teste o Debug Agora:**
   ```powershell
   node scripts/bundle-lambdas.js
   # Depois pressione F5 no VSCode
   ```

2. **Modifique e Teste:**
   - Edite `services/trip-planner/src/index.ts`
   - Adicione um `console.log`
   - Bundle novamente
   - F5 para ver o log

3. **Quando Estiver OK:**
   ```powershell
   git add .
   git commit -m "feat: nova funcionalidade"
   git push  # Deploy automático via CI/CD
   ```

---

## 🆘 Troubleshooting

### "Docker not found"
```powershell
# Instale Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### "Cannot find module"
```powershell
# Bundle novamente
node scripts/bundle-lambdas.js
```

### "Port 3000 already in use"
```powershell
# Use outra porta
sam local start-api --port 3001
```

### Evento não funcionando
1. Verifique o formato em `events/*.json`
2. Compare com o formato esperado no handler
3. Use breakpoint no início do handler para ver o event completo

---

## 📚 Recursos Adicionais

- [AWS SAM CLI Docs](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-command-reference.html)
- [AWS Toolkit VSCode](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/welcome.html)
- [Lambda Debug Best Practices](https://aws.amazon.com/blogs/compute/debugging-lambda-functions-locally-using-sam/)

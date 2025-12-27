# Guia de Testes - API de Autenticação

Este guia mostra como testar os endpoints de autenticação do n-agent.

## 📋 Pré-requisitos

- API Gateway implantado
- Cognito User Pool criado
- Client ID configurado
- `curl` ou ferramenta similar (Postman, Insomnia)

## 🔗 URL Base

```
https://<api-gateway-url>
```

**Produção**: `https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com`

## 🧪 Endpoints de Autenticação

### 1. Criar Conta (Signup)

Cria um novo usuário no Cognito.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com",
    "password": "SenhaForte123!",
    "name": "João Silva"
  }'
```

**Resposta de Sucesso (201)**:
```json
{
  "message": "User created successfully",
  "userSub": "12345678-1234-1234-1234-123456789012",
  "emailVerificationRequired": true
}
```

**Erros Comuns**:
- `400`: Email, password ou name faltando
- `400`: Senha não atende requisitos (mínimo 8 caracteres, maiúsculas, minúsculas, números, símbolos)
- `400`: Usuário já existe

### 2. Confirmar Email

Confirma o email usando o código recebido por email.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com",
    "code": "123456"
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "message": "Email confirmed successfully"
}
```

### 3. Login

Autentica o usuário e retorna tokens JWT.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com",
    "password": "SenhaForte123!"
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "accessToken": "eyJraWQiOiJ...",
  "idToken": "eyJraWQiOiJ...",
  "refreshToken": "eyJjdHkiOiJ...",
  "expiresIn": 3600
}
```

**Erros Comuns**:
- `400`: Email ou password faltando
- `401`: Credenciais inválidas
- `401`: Usuário não confirmado (precisa confirmar email primeiro)

### 4. Refresh Token

Atualiza o access token usando o refresh token.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJjdHkiOiJ..."
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "accessToken": "eyJraWQiOiJ...",
  "idToken": "eyJraWQiOiJ...",
  "expiresIn": 3600
}
```

### 5. Esqueci a Senha

Envia código de recuperação por email.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com"
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "message": "Password reset code sent to email"
}
```

### 6. Resetar Senha

Reseta a senha usando o código recebido.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com",
    "code": "123456",
    "newPassword": "NovaSenhaForte456!"
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "message": "Password reset successfully"
}
```

### 7. Reenviar Código

Reenvia o código de confirmação de email.

```bash
curl -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/resend-code \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com"
  }'
```

**Resposta de Sucesso (200)**:
```json
{
  "message": "Confirmation code resent"
}
```

## 🔒 Testando Rotas Protegidas

### Acessar Rota Sem Autenticação

```bash
curl https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/api/v1/trips
```

**Resposta Esperada (401)**:
```json
{
  "message": "Unauthorized"
}
```

### Acessar Rota Com Token

```bash
# 1. Fazer login e obter token
ACCESS_TOKEN=$(curl -s -X POST https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@exemplo.com",
    "password": "SenhaForte123!"
  }' | jq -r '.accessToken')

# 2. Usar token para acessar rota protegida
curl https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com/api/v1/trips \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Resposta Esperada (200)**:
```json
{
  "trips": []
}
```

## 🧪 Script de Teste Completo

Salve como `test-auth.sh`:

```bash
#!/bin/bash

API_URL="https://j4f1m6rrak.execute-api.us-east-1.amazonaws.com"
EMAIL="teste-$(date +%s)@exemplo.com"
PASSWORD="TesteSenha123!"
NAME="Usuario Teste"

echo "=== Teste Completo de Autenticação ==="
echo ""

# 1. Signup
echo "1. Criando usuário..."
SIGNUP_RESPONSE=$(curl -s -X POST "$API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"name\": \"$NAME\"
  }")
echo "$SIGNUP_RESPONSE" | jq '.'
USER_SUB=$(echo "$SIGNUP_RESPONSE" | jq -r '.userSub')
echo "User Sub: $USER_SUB"
echo ""

# 2. Aguardar código (em produção, verificar email)
echo "2. Digite o código de confirmação recebido por email:"
read CONFIRMATION_CODE

# 3. Confirm
echo "3. Confirmando email..."
curl -s -X POST "$API_URL/auth/confirm" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"code\": \"$CONFIRMATION_CODE\"
  }" | jq '.'
echo ""

# 4. Login
echo "4. Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")
echo "$LOGIN_RESPONSE" | jq '.'
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken')
REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.refreshToken')
echo ""

# 5. Testar rota protegida
echo "5. Testando acesso a rota protegida..."
curl -s "$API_URL/api/v1/trips" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
echo ""

# 6. Refresh token
echo "6. Atualizando token..."
curl -s -X POST "$API_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }" | jq '.'
echo ""

# 7. Forgot password
echo "7. Testando esqueci senha..."
curl -s -X POST "$API_URL/auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\"
  }" | jq '.'
echo ""

echo "=== Teste Concluído ==="
```

Execute:
```bash
chmod +x test-auth.sh
./test-auth.sh
```

## 🔍 Decodificando JWT Tokens

### Online
Acesse [jwt.io](https://jwt.io) e cole o token.

### Via CLI
```bash
# Instalar jq se necessário
# sudo apt-get install jq  # Linux
# brew install jq          # macOS

echo "eyJraWQiOiJ..." | cut -d. -f2 | base64 -d | jq '.'
```

### Estrutura do Token

**ID Token** contém informações do usuário:
```json
{
  "sub": "12345678-1234-1234-1234-123456789012",
  "email_verified": true,
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx",
  "cognito:username": "usuario@exemplo.com",
  "aud": "xxxxxxxxxxxxxxxxxxxxx",
  "token_use": "id",
  "auth_time": 1234567890,
  "exp": 1234571490,
  "iat": 1234567890,
  "email": "usuario@exemplo.com",
  "name": "João Silva"
}
```

**Access Token** é usado para autorização:
```json
{
  "sub": "12345678-1234-1234-1234-123456789012",
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx",
  "client_id": "xxxxxxxxxxxxxxxxxxxxx",
  "token_use": "access",
  "scope": "openid email profile",
  "auth_time": 1234567890,
  "exp": 1234571490,
  "iat": 1234567890
}
```

## 📊 Casos de Teste

### ✅ Casos de Sucesso

| Teste | Endpoint | Status | Descrição |
|-------|----------|--------|-----------|
| 1 | POST /auth/signup | 201 | Criar usuário novo |
| 2 | POST /auth/confirm | 200 | Confirmar email |
| 3 | POST /auth/login | 200 | Login com credenciais |
| 4 | GET /api/v1/trips | 200 | Acesso com token válido |
| 5 | POST /auth/refresh | 200 | Renovar token |
| 6 | POST /auth/forgot-password | 200 | Solicitar reset de senha |
| 7 | POST /auth/reset-password | 200 | Resetar senha |

### ❌ Casos de Erro

| Teste | Endpoint | Status | Descrição |
|-------|----------|--------|-----------|
| 1 | POST /auth/signup | 400 | Senha fraca |
| 2 | POST /auth/signup | 400 | Email duplicado |
| 3 | POST /auth/login | 401 | Senha incorreta |
| 4 | POST /auth/login | 401 | Usuário não confirmado |
| 5 | GET /api/v1/trips | 401 | Sem token |
| 6 | GET /api/v1/trips | 403 | Token expirado |
| 7 | POST /auth/confirm | 400 | Código inválido |

## 🐛 Troubleshooting

### Token Expirado
**Erro**: `Token is expired`
**Solução**: Use refresh token para obter novo access token

### Token Inválido
**Erro**: `Invalid token`
**Solução**: Verifique se o token está completo e correto

### Usuário Não Confirmado
**Erro**: `User is not confirmed`
**Solução**: Confirme o email primeiro com POST /auth/confirm

### Senha Fraca
**Erro**: `Password does not meet requirements`
**Solução**: Use senha com 8+ caracteres, incluindo maiúsculas, minúsculas, números e símbolos

## 📚 Próximos Passos

1. Integrar frontend com API de autenticação
2. Implementar refresh automático de tokens
3. Adicionar logout (invalidar tokens)
4. Implementar OAuth com Google/Facebook
5. Adicionar MFA (Multi-Factor Authentication)

## 🔗 Links Úteis

- [JWT.io](https://jwt.io) - Decoder de tokens JWT
- [Postman](https://www.postman.com/) - Cliente HTTP
- [Insomnia](https://insomnia.rest/) - Cliente HTTP alternativo
- [AWS Cognito Docs](https://docs.aws.amazon.com/cognito/)

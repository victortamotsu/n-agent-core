# Guia de Configuração OAuth com Amazon Cognito

Este guia explica como configurar providers OAuth (Google, Facebook, etc.) no Amazon Cognito User Pool.

## 📋 Pré-requisitos

- User Pool criado e configurado
- Aplicação web registrada (URL de callback definida)
- Conta de desenvolvedor no provider OAuth desejado

## 🔐 Configuração do Cognito User Pool

### 1. Callbacks URLs Configuradas

As seguintes URLs de callback já estão configuradas no Terraform:

```terraform
callback_urls = [
  "http://localhost:3000/auth/callback",
  "https://n-agent.com/auth/callback"
]
```

### 2. OAuth Flows Habilitados

- **Authorization code grant**: Fluxo recomendado para aplicações web
- **Implicit grant**: Fluxo legado para SPAs (menos seguro)

### 3. OAuth Scopes

Os seguintes scopes estão disponíveis:
- `openid` - Identificador único do usuário
- `email` - Endereço de email do usuário
- `profile` - Informações do perfil (nome, foto, etc.)

## 🔧 Configurando Providers OAuth

### Google OAuth 2.0

#### 1. Criar Aplicação no Google Cloud Console

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Vá para **APIs & Services** > **Credentials**
4. Clique em **Create Credentials** > **OAuth 2.0 Client ID**
5. Configure:
   - **Application type**: Web application
   - **Name**: n-agent-web
   - **Authorized redirect URIs**:
     ```
     https://<user-pool-domain>.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
     ```

#### 2. Obter Credenciais

Após criar, você receberá:
- **Client ID**: `xxxxx.apps.googleusercontent.com`
- **Client Secret**: `xxxxxxxxxxxxxxxxxxxxxxxx`

#### 3. Configurar no Cognito

1. Acesse o AWS Console > Cognito > User Pool
2. Vá para **Sign-in experience** > **Federated identity provider sign-in**
3. Clique em **Add identity provider**
4. Selecione **Google**
5. Configure:
   - **Client ID**: Cole o Client ID do Google
   - **Client Secret**: Cole o Client Secret do Google
   - **Authorized scopes**: `openid profile email`

#### 4. Atualizar Terraform

Adicione Google aos providers suportados:

```terraform
resource "aws_cognito_user_pool_client" "web_client" {
  # ... outras configurações
  
  supported_identity_providers = ["COGNITO", "Google"]
}
```

#### 5. Aplicar Alterações

```bash
cd infra/environments/prod
terraform apply
```

### Facebook Login

#### 1. Criar Aplicação no Facebook Developers

1. Acesse [Facebook Developers](https://developers.facebook.com/)
2. Clique em **My Apps** > **Create App**
3. Selecione **Consumer** como tipo de app
4. Configure:
   - **App Name**: n-agent
   - **Contact Email**: seu@email.com

#### 2. Adicionar Facebook Login

1. No dashboard do app, clique em **Add Product**
2. Selecione **Facebook Login** > **Set Up**
3. Escolha **Web** como plataforma
4. Em **Settings** > **Basic**:
   - Anote o **App ID** e **App Secret**
5. Em **Facebook Login** > **Settings**:
   - **Valid OAuth Redirect URIs**:
     ```
     https://<user-pool-domain>.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
     ```

#### 3. Configurar no Cognito

1. Acesse o AWS Console > Cognito > User Pool
2. Vá para **Sign-in experience** > **Federated identity provider sign-in**
3. Clique em **Add identity provider**
4. Selecione **Facebook**
5. Configure:
   - **App ID**: Cole o App ID do Facebook
   - **App Secret**: Cole o App Secret do Facebook
   - **Authorized scopes**: `public_profile,email`

#### 4. Atualizar Terraform

```terraform
resource "aws_cognito_user_pool_client" "web_client" {
  # ... outras configurações
  
  supported_identity_providers = ["COGNITO", "Google", "Facebook"]
}
```

## 🌐 Configurar Cognito Domain

Para usar OAuth, você precisa configurar um domínio do Cognito:

### 1. Via Console AWS

1. Acesse User Pool > **App integration** > **Domain**
2. Escolha entre:
   - **Cognito domain**: `n-agent-auth.auth.us-east-1.amazoncognito.com`
   - **Custom domain**: `auth.n-agent.com` (requer certificado SSL)

### 2. Via Terraform

Adicione ao `resources.tf`:

```terraform
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "n-agent-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}
```

## 🔗 URLs de Autenticação

Após configurar o domínio, use estas URLs:

### Login (Authorization Code Flow)

```
https://<cognito-domain>/oauth2/authorize?
  client_id=<client_id>&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=<callback_url>
```

### Login com Google

```
https://<cognito-domain>/oauth2/authorize?
  identity_provider=Google&
  client_id=<client_id>&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=<callback_url>
```

### Login com Facebook

```
https://<cognito-domain>/oauth2/authorize?
  identity_provider=Facebook&
  client_id=<client_id>&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=<callback_url>
```

### Logout

```
https://<cognito-domain>/logout?
  client_id=<client_id>&
  logout_uri=<logout_callback_url>
```

## 💻 Implementação no Frontend

### 1. Botão de Login com Google

```typescript
const loginWithGoogle = () => {
  const cognitoDomain = 'https://n-agent-auth.auth.us-east-1.amazoncognito.com';
  const clientId = process.env.VITE_COGNITO_CLIENT_ID;
  const redirectUri = window.location.origin + '/auth/callback';
  
  const authUrl = `${cognitoDomain}/oauth2/authorize?` +
    `identity_provider=Google&` +
    `client_id=${clientId}&` +
    `response_type=code&` +
    `scope=openid+email+profile&` +
    `redirect_uri=${redirectUri}`;
  
  window.location.href = authUrl;
};
```

### 2. Processar Callback

```typescript
// Em /auth/callback
const handleCallback = async () => {
  const urlParams = new URLSearchParams(window.location.search);
  const code = urlParams.get('code');
  
  if (!code) {
    console.error('No authorization code received');
    return;
  }
  
  // Trocar code por tokens
  const response = await fetch(`${cognitoDomain}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: clientId,
      code: code,
      redirect_uri: redirectUri,
    }),
  });
  
  const tokens = await response.json();
  // Armazenar tokens.access_token, tokens.id_token, tokens.refresh_token
};
```

## 🔒 Segurança

### Boas Práticas

1. **SEMPRE use HTTPS** em produção
2. **NÃO exponha** Client Secret no frontend (use Cognito Hosted UI ou backend)
3. **Valide tokens** no backend antes de confiar
4. **Use PKCE** (Proof Key for Code Exchange) quando possível
5. **Implemente logout** adequadamente
6. **Rotacione secrets** periodicamente

### Validação de Token JWT

```typescript
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: `https://cognito-idp.us-east-1.amazonaws.com/${userPoolId}/.well-known/jwks.json`
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}

jwt.verify(token, getKey, {
  algorithms: ['RS256'],
  issuer: `https://cognito-idp.us-east-1.amazonaws.com/${userPoolId}`
}, (err, decoded) => {
  if (err) {
    console.error('Token validation failed:', err);
    return;
  }
  console.log('Token is valid:', decoded);
});
```

## 📊 Testando a Configuração

### 1. Teste via Cognito Hosted UI

Acesse:
```
https://<cognito-domain>/login?client_id=<client_id>&response_type=code&scope=openid+email+profile&redirect_uri=<callback_url>
```

Você deve ver:
- Opção de login com email/senha (COGNITO)
- Botão "Continue with Google" (se configurado)
- Botão "Continue with Facebook" (se configurado)

### 2. Teste Programático

Use o seguinte script:

```bash
# 1. Obter authorization code (abre navegador)
# URL gerada no passo anterior

# 2. Trocar code por tokens
curl -X POST https://<cognito-domain>/oauth2/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=authorization_code' \
  -d 'client_id=<client_id>' \
  -d 'code=<authorization_code>' \
  -d 'redirect_uri=<callback_url>'

# 3. Verificar token
curl https://api.n-agent.com/api/v1/trips \
  -H "Authorization: Bearer <access_token>"
```

## 🐛 Troubleshooting

### Erro: "redirect_uri_mismatch"

**Causa**: URL de callback não corresponde às configuradas

**Solução**: Verifique se a URL exata está configurada em:
1. Cognito User Pool Client
2. Google Cloud Console / Facebook Developers

### Erro: "invalid_client"

**Causa**: Client ID ou Secret incorretos

**Solução**: Verifique as credenciais no AWS Secrets Manager ou variáveis de ambiente

### Erro: "unauthorized_client"

**Causa**: Provider não está habilitado no Cognito

**Solução**: Adicione o provider em `supported_identity_providers`

## 📚 Referências

- [AWS Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [OAuth 2.0 Authorization Code Flow](https://oauth.net/2/grant-types/authorization-code/)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login](https://developers.facebook.com/docs/facebook-login/)
- [JWT Token Validation](https://jwt.io/)

## ✅ Checklist de Implementação

- [ ] User Pool criado com configurações de segurança
- [ ] Client ID e Secret gerados
- [ ] Domínio Cognito configurado
- [ ] Google OAuth configurado (opcional)
- [ ] Facebook Login configurado (opcional)
- [ ] URLs de callback atualizadas
- [ ] Frontend implementado com fluxo OAuth
- [ ] Testes de autenticação realizados
- [ ] Validação de JWT implementada
- [ ] Logout implementado
- [ ] Documentação atualizada

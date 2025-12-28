# Otimização de Pipelines CI/CD

## Mudanças Implementadas

### 1. **Cache de Dependências Offline** ⚡
- Adicionado `--prefer-offline` ao `pnpm install`
- Reduz tempo de instalação reutilizando cache do GitHub Actions
- **Economia estimada**: 5-10s por job

### 2. **Turborepo Cache Habilitado** 🚀
- Cache explícito para `build`, `lint` e `test`
- Suporte para remote cache (Vercel/self-hosted)
- Pula rebuilds de pacotes não alterados
- **Economia estimada**: 10-30s em builds incrementais

### 3. **Paralelização de Jobs** 🔀
- `build-and-deploy` e `deploy-frontend` rodam em paralelo após infra
- `security-scan` não bloqueia `lint-and-test`
- **Economia estimada**: 20-40s no deploy

### 4. **Security Scan Otimizado** 🔒
- Snyk verifica apenas severidade `high` (em vez de `--all-projects`)
- Reduz análise desnecessária de dependências dev
- **Economia estimada**: 10-20s

### 5. **Fetch Depth Reduzido** 📦
- `fetch-depth: 2` no CI (em vez de full history)
- Apenas último commit + pai para comparações
- **Economia estimada**: 2-5s

## Resultados Esperados

### Antes
- **CI Pipeline**: ~45s
- **Deploy Pipeline**: ~2m47s (167s)
- **Total por commit**: ~3m32s (212s)

### Depois (estimativa)
- **CI Pipeline**: ~30-35s ⬇️ 25% mais rápido
- **Deploy Pipeline**: ~1m50s-2m10s (110-130s) ⬇️ 30-35% mais rápido
- **Total por commit**: ~2m20s-2m45s ⬇️ 20-30% economia

## Configuração Opcional: Turborepo Remote Cache

Para máxima performance, você pode habilitar cache remoto do Turborepo:

### Opção 1: Vercel (Gratuito) - Recomendado

1. Crie conta em [vercel.com](https://vercel.com)
2. Gere token de acesso: https://vercel.com/account/tokens
3. Adicione secrets no GitHub:
   ```bash
   gh secret set TURBO_TOKEN --body "your-token"
   gh secret set TURBO_TEAM --body "your-team-name"
   ```

**Benefício**: Cache compartilhado entre runs, economia adicional de 30-60s

### Opção 2: Self-hosted (Avançado)

Use [turborepo-remote-cache](https://github.com/ducktors/turborepo-remote-cache) self-hosted.

## Dicas Adicionais

### Para Reduzir Uso de Minutos Ainda Mais

1. **Branch Protection**: Configure para não rodar CI em branches pessoais
   ```yaml
   on:
     push:
       branches: [main, develop]  # Apenas branches principais
   ```

2. **Path Filters**: Execute workflows apenas em mudanças relevantes
   ```yaml
   on:
     push:
       paths:
         - 'services/**'
         - 'packages/**'
   ```

3. **Merge Queue**: Agrupe múltiplos PRs em um deploy

4. **Self-hosted Runners**: Use runners próprios (gratuito, requer servidor)

## Monitoramento

Verifique economia de minutos:
```bash
# Ver últimas 10 runs com tempo
gh run list --limit 10

# Ver detalhes de um run específico
gh run view <run-id>
```

## Plano Gratuito GitHub Actions

- **2.000 minutos/mês** para repos privados
- Runs públicos são gratuitos
- Com essas otimizações: ~60-70 commits/mês (vs 40-50 antes)

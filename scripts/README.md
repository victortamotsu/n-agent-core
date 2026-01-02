# Scripts de Automação - n-agent

## WSL 2 Quick Start

Script automatizado para configurar o ambiente completo de desenvolvimento no WSL 2.

### O que o script faz?

✅ Atualiza sistema Ubuntu  
✅ Instala Python 3.11, pip, build tools  
✅ Instala uv (Python package manager)  
✅ Instala AWS CLI  
✅ Copia AWS credentials do Windows  
✅ Copia projeto para filesystem do WSL  
✅ Cria venv com Python 3.11  
✅ Instala todas as dependências  
✅ Gera requirements.txt  
✅ Roda testes para validar  
✅ Verifica configuração do AgentCore  

### Como usar?

#### 1. Instalar WSL 2 (se ainda não tiver)

No PowerShell como Administrador:

```powershell
wsl --install
```

Reinicie o Windows após a instalação.

#### 2. Abrir Ubuntu

Após reiniciar, o Ubuntu abrirá automaticamente. Configure usuário e senha quando solicitado.

#### 3. Rodar o quick start script

```bash
# Copiar script do Windows para WSL
cp /mnt/c/Users/victo/Projetos/n-agent-core/scripts/wsl2-quickstart.sh ~/

# Dar permissão de execução
chmod +x ~/wsl2-quickstart.sh

# Executar
~/wsl2-quickstart.sh
```

#### 4. Seguir os próximos passos

Após o script concluir, você verá instruções para:
- Ativar venv
- Rodar dev mode
- Deploy para AWS
- Testar endpoint

### Tempo estimado

- **Setup inicial (primeira vez)**: ~10-15 minutos
- **Instalações**: ~5 minutos
- **Cópia do projeto**: ~2 minutos
- **Instalação de dependências**: ~3 minutos

### Troubleshooting

#### Erro: "Este script deve ser executado dentro do WSL 2!"

Você está rodando no PowerShell/CMD do Windows. Execute dentro do Ubuntu (WSL).

#### Erro: "Projeto não encontrado"

Verifique se o caminho está correto no script:
```bash
nano ~/wsl2-quickstart.sh
# Alterar linha: /mnt/c/Users/victo/Projetos/n-agent-core
```

#### Erro: AWS credentials não encontradas

Configure manualmente após o script:
```bash
aws configure
```

#### Performance lenta

Certifique-se de que o projeto foi copiado para `~/n-agent-core` (filesystem do WSL), não `/mnt/c/...` (Windows).

### Comandos úteis após setup

```bash
# Entrar no projeto
cd ~/n-agent-core/agent
source .venv/bin/activate

# Dev mode
uv run agentcore dev

# Testes
uv run pytest tests/ -v

# Linter
uv run ruff check src/ --fix

# Formatter
uv run ruff format src/

# Deploy
uv run agentcore launch

# Status
uv run agentcore status

# Logs
uv run agentcore logs
```

### Integração com VS Code

1. Instalar extensão **WSL** no VS Code (Windows)
2. Clicar no ícone verde (canto inferior esquerdo) → "Connect to WSL"
3. Abrir pasta: `File` → `Open Folder` → `~/n-agent-core`
4. Selecionar Python interpreter: `Ctrl+Shift+P` → "Python: Select Interpreter" → `~/.venv/bin/python`

### Próximos passos

Após setup completo, siga o [Checklist da Fase 1](../.promtps_iniciais/fases_implementacao/CHECKLIST_FASE1.md) para completar o deploy.

### Documentação completa

[WSL 2 Setup Guide](../docs/WSL2_SETUP.md) - Guia completo com todos os detalhes.

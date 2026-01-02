#!/bin/bash
# Quick Start Script para WSL 2
# Automatiza o setup completo do ambiente de desenvolvimento n-agent

set -e  # Exit on error

echo "🚀 n-agent WSL 2 Quick Start"
echo "=============================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para print colorido
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# 1. Verificar se estamos no WSL
if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    print_error "Este script deve ser executado dentro do WSL 2!"
    exit 1
fi
print_status "Rodando no WSL 2"

# 2. Atualizar sistema
print_info "Atualizando sistema Ubuntu..."
sudo apt update && sudo apt upgrade -y
print_status "Sistema atualizado"

# 3. Instalar dependências do sistema
print_info "Instalando dependências do sistema..."
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    zip \
    unzip \
    curl \
    git \
    jq
print_status "Dependências do sistema instaladas"

# 4. Instalar uv
if ! command -v uv &> /dev/null; then
    print_info "Instalando uv (Python package manager)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    print_status "uv instalado"
else
    print_status "uv já instalado"
fi

# 5. Instalar AWS CLI
if ! command -v aws &> /dev/null; then
    print_info "Instalando AWS CLI..."
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    print_status "AWS CLI instalado"
else
    print_status "AWS CLI já instalado"
fi

# 6. Configurar AWS credentials
if [ ! -f ~/.aws/credentials ]; then
    print_info "Configurando AWS credentials..."
    if [ -f /mnt/c/Users/victo/.aws/credentials ]; then
        mkdir -p ~/.aws
        cp /mnt/c/Users/victo/.aws/credentials ~/.aws/
        cp /mnt/c/Users/victo/.aws/config ~/.aws/
        print_status "AWS credentials copiadas do Windows"
    else
        print_info "Execute: aws configure"
        print_info "  AWS Access Key ID: [sua key]"
        print_info "  AWS Secret Access Key: [sua secret]"
        print_info "  Default region: us-east-1"
        print_info "  Default output format: json"
    fi
else
    print_status "AWS credentials já configuradas"
fi

# 7. Clonar/copiar projeto
PROJECT_DIR="$HOME/n-agent-core"
if [ ! -d "$PROJECT_DIR" ]; then
    print_info "Copiando projeto para filesystem do WSL..."
    if [ -d "/mnt/c/Users/victo/Projetos/n-agent-core" ]; then
        cp -r /mnt/c/Users/victo/Projetos/n-agent-core "$HOME/"
        print_status "Projeto copiado para $PROJECT_DIR"
    else
        print_error "Projeto não encontrado em /mnt/c/Users/victo/Projetos/n-agent-core"
        print_info "Clone manualmente: git clone <seu-repo> $PROJECT_DIR"
        exit 1
    fi
else
    print_status "Projeto já existe em $PROJECT_DIR"
fi

# 8. Setup do projeto
print_info "Configurando ambiente Python..."
cd "$PROJECT_DIR/agent"

# Remover venv antigo se existir
if [ -d ".venv" ]; then
    rm -rf .venv
    print_info "Venv anterior removido"
fi

# Criar novo venv com Python 3.11
uv venv --python 3.11
print_status "Venv criado com Python 3.11"

# Ativar e instalar dependências
source .venv/bin/activate
uv sync
print_status "Dependências instaladas"

# Verificar que pywin32 NÃO foi instalado
if uv pip list | grep -q pywin32; then
    print_error "ATENÇÃO: pywin32 foi instalado (não deveria no Linux!)"
else
    print_status "pywin32 não instalado (correto para Linux)"
fi

# Gerar requirements.txt
uv pip compile pyproject.toml -o requirements.txt --universal
print_status "requirements.txt gerado"

# 9. Rodar testes
print_info "Rodando testes..."
if uv run pytest tests/ -v --tb=short; then
    print_status "Todos os testes passaram!"
else
    print_error "Alguns testes falharam"
fi

# 10. Verificar Memory ID
MEMORY_ID=$(grep "memory_id:" .bedrock_agentcore.yaml | awk '{print $2}')
if [ -n "$MEMORY_ID" ]; then
    print_status "Memory ID configurado: $MEMORY_ID"
else
    print_error "Memory ID não encontrado no .bedrock_agentcore.yaml"
fi

# 11. Summary
echo ""
echo "=============================="
echo "🎉 Setup completo!"
echo "=============================="
echo ""
echo "Próximos passos:"
echo ""
echo "1. Ativar ambiente virtual:"
echo "   cd $PROJECT_DIR/agent"
echo "   source .venv/bin/activate"
echo ""
echo "2. Rodar em dev mode:"
echo "   uv run agentcore dev"
echo ""
echo "3. Deploy para AWS:"
echo "   uv run agentcore launch"
echo ""
echo "4. Verificar status:"
echo "   uv run agentcore status"
echo ""
echo "5. Testar endpoint:"
echo "   uv run agentcore invoke '{\"prompt\": \"Olá!\"}'"
echo ""
echo "6. Ver logs:"
echo "   uv run agentcore logs"
echo ""
echo "Documentação completa: $PROJECT_DIR/docs/WSL2_SETUP.md"
echo ""

"""
Agent Router - Classificador de Queries Multi-Agente

Este módulo implementa o Router Agent que classifica queries e direciona
para o modelo mais adequado (Nova Micro/Lite/Pro ou Claude Sonnet).

Economia estimada: 76% vs usar apenas Nova Pro (de $6.40 para $1.52/mês)

USANDO STRANDS AGENTS SDK:
- Usa Strands Agent para classificação inteligente
- Integra com AgentCore Memory para session management
- Best practices da AWS documentadas
"""

import re
from enum import Enum
from typing import Dict, Any, Optional
from datetime import datetime

from strands import Agent
from strands.models import BedrockModel
from bedrock_agentcore.memory import MemoryClient
from bedrock_agentcore.memory.integrations.strands.config import AgentCoreMemoryConfig
from bedrock_agentcore.memory.integrations.strands.session_manager import (
    AgentCoreMemorySessionManager,
)


class QueryComplexity(Enum):
    """Tipos de complexidade de queries."""

    TRIVIAL = "trivial"  # "Oi", "Ok", "Obrigado" → Nova Lite
    INFORMATIVE = "informative"  # "Qual meu hotel?" → Nova Lite + Memory
    COMPLEX = "complex"  # "Planeje 3 dias em Roma" → Nova Pro + Tools
    VISION = "vision"  # "Analise este documento" → Claude Sonnet
    CRITICAL = "critical"  # Contratos, docs legais → Claude Sonnet


class AgentRouter:
    """Router que classifica queries e direciona para o modelo adequado usando Strands SDK."""

    def __init__(self, memory_id: Optional[str] = None, region_name: str = "us-east-1"):
        """
        Inicializa o Router com Strands Agent para classificação.

        Args:
            memory_id: ID da memória AgentCore (opcional, cria uma nova se não fornecido)
            region_name: Região AWS (padrão: us-east-1)
        """
        self.region_name = region_name
        self.memory_id = memory_id

        # Configuração de modelos (custos por 1M tokens)
        self.models = {
            "router": {
                "id": "us.amazon.nova-micro-v1:0",
                "cost_input": 0.035,  # $0.035/1M
                "cost_output": 0.14,  # $0.14/1M
            },
            "chat": {
                "id": "us.amazon.nova-lite-v1:0",
                "cost_input": 0.06,  # $0.06/1M
                "cost_output": 0.24,  # $0.24/1M
            },
            "planning": {
                "id": "us.amazon.nova-pro-v1:0",
                "cost_input": 0.80,  # $0.80/1M
                "cost_output": 3.20,  # $3.20/1M
            },
            "vision": {
                "id": "anthropic.claude-3-sonnet-20240229-v1:0",
                "cost_input": 3.00,  # $3.00/1M
                "cost_output": 0,  # Não usado (vision apenas lê)
            },
        }

        # Padrões para classificação rápida (antes de chamar Router)
        self.trivial_patterns = [
            r"^(oi|olá|hey|hi|hello)[\s!?]*$",
            r"^(obrigad[oa]|thanks|valeu)[\s!?]*$",
            r"^(ok|certo|tudo bem|sim|não|yes|no)[\s!?]*$",
            r"^👍|👋|😊|❤️$",  # Apenas emojis
        ]

        # Configuração do modelo Bedrock para Strands (usando BedrockModel)
        self.model_config = BedrockModel(model_id=self.models["router"]["id"])

        # Inicializar AgentCore Memory se memory_id fornecido
        self.memory_client = None
        self.session_manager = None
        if memory_id:
            self._setup_memory(memory_id)

    def _setup_memory(
        self,
        memory_id: str,
        session_id: Optional[str] = None,
        actor_id: Optional[str] = None,
    ):
        """
        Configura AgentCore Memory seguindo best practices da documentação.

        Args:
            memory_id: ID da memória AgentCore
            session_id: ID da sessão (gerado automaticamente se não fornecido)
            actor_id: ID do usuário (gerado automaticamente se não fornecido)
        """
        self.memory_client = MemoryClient(region_name=self.region_name)

        # Gerar IDs únicos se não fornecidos
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        session_id = session_id or f"router_session_{timestamp}"
        actor_id = actor_id or f"router_actor_{timestamp}"

        # Configurar memória seguindo padrão da documentação
        agentcore_memory_config = AgentCoreMemoryConfig(
            memory_id=memory_id, session_id=session_id, actor_id=actor_id
        )

        # Criar session manager para Strands
        self.session_manager = AgentCoreMemorySessionManager(
            agentcore_memory_config=agentcore_memory_config,
            region_name=self.region_name,
        )

    def is_trivial_pattern(self, message: str) -> bool:
        """Verifica se mensagem é trivial sem chamar Router (economia)."""
        message_lower = message.lower().strip()

        # Mensagens muito curtas (<= 3 palavras) geralmente são triviais
        if len(message_lower.split()) <= 3:
            for pattern in self.trivial_patterns:
                if re.match(pattern, message_lower, re.IGNORECASE):
                    return True
        return False

    def classify_query(
        self,
        user_message: str,
        has_image: bool = False,
        trip_context: Optional[Dict] = None,
    ) -> QueryComplexity:
        """
        Usa Nova Micro para classificar complexidade da query.

        Args:
            user_message: Mensagem do usuário
            has_image: Se há imagem anexada
            trip_context: Contexto da viagem (opcional)

        Returns:
            QueryComplexity enum
        """

        # 1. Detecção rápida: imagem = visão
        if has_image:
            return QueryComplexity.VISION

        # 2. Detecção rápida: padrões triviais (economiza chamada ao Router)
        if self.is_trivial_pattern(user_message):
            return QueryComplexity.TRIVIAL

        # 3. Usar Router Agent (Strands) para classificação inteligente
        prompt = self._build_classification_prompt(user_message, trip_context)

        try:
            # Criar agente Strands para classificação usando Nova Micro
            classifier_agent = Agent(
                system_prompt="""Você é um classificador de mensagens de usuários em um assistente de viagens.
Responda APENAS uma palavra: TRIVIAL, INFORMATIVE, COMPLEX ou CRITICAL.""",
                model=self.model_config,
                session_manager=self.session_manager if self.session_manager else None,
            )

            # Invocar agente para classificação
            result = classifier_agent(prompt)

            # Parse da resposta do Strands Agent (result.message['content'][0]['text'])
            if hasattr(result, "message") and "content" in result.message:
                classification = result.message["content"][0]["text"].strip().upper()
            else:
                # Fallback: tentar converter para string
                classification = str(result).strip().upper()

            # Parse da classificação
            return QueryComplexity(classification.lower())

        except (KeyError, ValueError, Exception) as e:
            # Fallback se classificação inválida
            print(f"⚠️ Erro na classificação: {e}, usando INFORMATIVE")
            return QueryComplexity.INFORMATIVE

    def _build_classification_prompt(
        self, user_message: str, trip_context: Optional[Dict]
    ) -> str:
        """Constrói prompt de classificação com exemplos."""

        # Adiciona contexto da viagem se disponível
        context_info = ""
        if trip_context:
            context_info = f"""
CONTEXTO DA VIAGEM:
- Status: {trip_context.get("status", "KNOWLEDGE")}
- Destinos: {", ".join(trip_context.get("destinations", []))}
- Datas: {trip_context.get("start_date")} → {trip_context.get("end_date")}
"""

        return f"""
Você é um classificador de mensagens de usuários em um assistente de viagens.

{context_info}

MENSAGEM DO USUÁRIO:
"{user_message}"

Classifique a complexidade respondendo APENAS UMA das palavras abaixo:

TRIVIAL → Saudações, agradecimentos, confirmações simples ("Oi", "Ok", "Obrigado")
INFORMATIVE → Perguntas sobre informações já coletadas ("Qual meu hotel?", "A que horas é o voo?")
COMPLEX → Solicitações de planejamento ou busca de novas informações ("Planeje 3 dias em Roma", "Busque hotéis perto do Coliseu")
CRITICAL → Solicitações envolvendo documentos importantes ou decisões críticas ("Revise meu contrato de seguro", "Valide minha reserva de voo")

EXEMPLOS:
- "Bom dia!" → TRIVIAL
- "Qual o nome do hotel em Paris?" → INFORMATIVE
- "Quero visitar o Louvre amanhã, me ajuda?" → COMPLEX
- "Preciso cancelar minha reserva urgente" → CRITICAL

CLASSIFICAÇÃO (responda apenas UMA palavra):
"""

    def get_model_for_complexity(self, complexity: QueryComplexity) -> Dict[str, Any]:
        """Retorna configuração do modelo adequado para a complexidade."""
        mapping = {
            QueryComplexity.TRIVIAL: self.models["chat"],
            QueryComplexity.INFORMATIVE: self.models["chat"],
            QueryComplexity.COMPLEX: self.models["planning"],
            QueryComplexity.VISION: self.models["vision"],
            QueryComplexity.CRITICAL: self.models["vision"],
        }
        return mapping[complexity]

    def route(
        self,
        user_message: str,
        has_image: bool = False,
        trip_context: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Classifica e retorna configuração completa para o agente.

        Returns:
            dict: Configuração com model_id, complexity, use_tools, use_memory, etc.
        """

        start_time = datetime.now()

        # 1. Classificar query
        complexity = self.classify_query(user_message, has_image, trip_context)

        # 2. Selecionar modelo
        model_config = self.get_model_for_complexity(complexity)

        # 3. Configurações específicas do agente
        # use_memory=True sempre, exceto para emojis puros (trivial com len<5)
        # Isso permite que o agente lembre contexto mesmo em queries simples
        use_memory = (
            len(user_message.strip()) >= 5 or complexity != QueryComplexity.TRIVIAL
        )

        config = {
            "model_id": model_config["id"],
            "complexity": complexity.value,
            "use_tools": complexity
            in [QueryComplexity.COMPLEX, QueryComplexity.CRITICAL],
            "use_memory": use_memory,
            "enable_cache": True,  # Prompt caching habilitado
            "cost_input_per_1m": model_config["cost_input"],
            "cost_output_per_1m": model_config["cost_output"],
            "routing_time_ms": int(
                (datetime.now() - start_time).total_seconds() * 1000
            ),
        }

        # 4. Log de roteamento (para métricas)
        print(
            f"🔀 Router: '{user_message[:50]}...' → {complexity.value} ({model_config['id']}) em {config['routing_time_ms']}ms"
        )

        return config


# Exemplo de uso (será integrado no main.py na Fase 1)
if __name__ == "__main__":
    # Inicializar router sem memória para testes simples
    router = AgentRouter()

    # Testes
    test_cases = [
        ("Oi!", False, None),
        ("Qual meu hotel em Roma?", False, {"status": "PLANNING"}),
        ("Planeje 3 dias em Roma com visitas ao Coliseu", False, None),
        ("", True, None),  # Imagem
    ]

    print("\n🧪 TESTANDO ROUTER AGENT COM STRANDS SDK\n")
    for message, has_img, context in test_cases:
        config = router.route(message, has_img, context)
        print(f"\n✅ '{message}' → {config['complexity']} ({config['model_id']})")

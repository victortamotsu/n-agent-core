"""
n-agent - Assistente Pessoal de Viagens

Entrypoint principal do AgentCore Runtime.
Implementa arquitetura multi-agente com Router Agent para otimização de custos.

FASE 1 - FUNDAÇÃO:
- BedrockAgentCoreApp() para runtime protocol
- Strands Agent para lógica de negócio
- AgentCore Memory para session management
- Router Agent para cost optimization

BEST PRACTICES SEGUIDAS:
- Lazy initialization para Memory (graceful degradation se não configurado)
- Strands Agent com prompt context do Memory
- Router Agent para cost optimization
"""

import os
from typing import Dict, Any, Optional
from datetime import datetime, timezone

from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent

# Importar Router Agent e Memory
try:
    from router.agent_router import AgentRouter
    from memory.agentcore_memory import AgentCoreMemory
except ImportError:
    from src.router.agent_router import AgentRouter
    from src.memory.agentcore_memory import AgentCoreMemory

# Inicializar BedrockAgentCoreApp seguindo best practices
app = BedrockAgentCoreApp()

# Configurar IDs de recursos AgentCore
MEMORY_ID = os.getenv("BEDROCK_AGENTCORE_MEMORY_ID")
REGION = os.getenv("AWS_REGION", "us-east-1")

# Inicializar componentes
router = AgentRouter(region_name=REGION)
memory: Optional[AgentCoreMemory] = None

# Lazy init do Memory (só quando configurado)
if MEMORY_ID:
    memory = AgentCoreMemory(memory_id=MEMORY_ID, region_name=REGION)
    print(f"✅ AgentCore Memory configured: {MEMORY_ID[:20]}...")
else:
    print("⚠️ Memory not configured. Set BEDROCK_AGENTCORE_MEMORY_ID to enable.")


def get_strands_agent(model_id: str, context: str = "") -> Agent:
    """Create a Strands Agent with the appropriate model and context.

    Args:
        model_id: Bedrock model ID (e.g., us.amazon.nova-lite-v1:0)
        context: Previous conversation context from Memory

    Returns:
        Configured Strands Agent
    """
    system_prompt = f"""Você é o n-agent, um assistente pessoal de viagens inteligente e amigável.

🎯 Seu objetivo é ajudar os usuários a planejar, organizar e aproveitar suas viagens.

📋 Suas capacidades:
- Responder perguntas sobre destinos, atrações e dicas de viagem
- Ajudar a criar roteiros de viagem personalizados
- Fornecer informações sobre voos, hotéis e transportes
- Lembrar de preferências e contexto da conversa
- Ser proativo em sugerir melhorias no planejamento

💬 Estilo de comunicação:
- Seja simpático e prestativo
- Use emojis com moderação para tornar a conversa agradável
- Seja conciso, mas completo nas respostas
- Pergunte quando precisar de mais informações

{f"📝 Contexto da Conversa:{chr(10)}{context}" if context else ""}
"""

    return Agent(
        model=model_id,
        system_prompt=system_prompt,
    )


@app.entrypoint
def invoke(payload: Dict[str, Any], context=None) -> Dict[str, Any]:
    """
    Entrypoint do AgentCore Runtime - Fase 1 com Memory Integration.

    Args:
        payload: Dict contendo:
            - prompt: Mensagem do usuário (requerido)
            - trip_id: ID da viagem (opcional)
            - has_image: Se há imagem anexada (opcional)
        context: Contexto do AgentCore Runtime (session_id, headers, etc.)

    Returns:
        dict: Resposta seguindo formato AgentCore
    """
    # Extrair dados do payload
    user_message = payload.get("prompt", "")
    trip_id = payload.get("trip_id")
    has_image = payload.get("has_image", False)

    # Obter session_id - prioridade: payload > context > default
    # Em dev mode, session_id vem no payload; em runtime, vem no context
    session_id = payload.get("session_id")
    if not session_id and context:
        session_id = getattr(context, "session_id", None)
    if not session_id:
        session_id = "default"

    # Obter actor_id do contexto ou payload
    actor_id = payload.get("actor_id", "user")
    if context and hasattr(context, "headers"):
        actor_id = context.headers.get(
            "X-Amzn-Bedrock-AgentCore-Runtime-Custom-Actor-Id", actor_id
        )

    print(f"🔵 [Session: {session_id}] Processando: '{user_message[:50]}...'")

    # 1. ROUTER AGENT: Classificar query e selecionar modelo
    routing_config = router.route(
        user_message=user_message,
        has_image=has_image,
        trip_context={"trip_id": trip_id} if trip_id else None,
    )

    print(f"🔀 Router: {routing_config['complexity']} → {routing_config['model_id']}")

    # 2. MEMORY: Recuperar contexto da conversa (se configurado)
    memory_context = ""
    if memory and memory.is_configured() and routing_config.get("use_memory", False):
        memory_context = memory.format_context_for_prompt(
            actor_id=actor_id,
            session_id=session_id,
            current_query=user_message,
            include_summary=True,
        )
        if memory_context:
            print(f"📝 Memory context loaded ({len(memory_context)} chars)")

    # 3. STRANDS AGENT: Executar agente com modelo selecionado
    agent = get_strands_agent(
        model_id=routing_config["model_id"],
        context=memory_context,
    )

    try:
        response = agent(user_message)
        response_text = str(response)
    except Exception as e:
        print(f"❌ Agent error: {e}")
        response_text = (
            "Desculpe, tive um problema ao processar sua mensagem. "
            "Pode tentar novamente?"
        )

    # 4. MEMORY: Salvar interação (se configurado)
    if memory and memory.is_configured():
        try:
            memory.add_interaction(
                actor_id=actor_id,
                session_id=session_id,
                user_message=user_message,
                agent_response=response_text,
            )
            print("💾 Interaction saved to Memory")
        except Exception as e:
            print(f"⚠️ Failed to save to Memory: {e}")

    # 5. Retornar resposta
    return {
        "response": response_text,
        "metadata": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "session_id": session_id,
            "actor_id": actor_id,
            "trip_id": trip_id,
            "routing": {
                "complexity": routing_config["complexity"],
                "model_id": routing_config["model_id"],
                "routing_time_ms": routing_config["routing_time_ms"],
                "use_tools": routing_config["use_tools"],
                "use_memory": routing_config["use_memory"],
            },
            "memory_enabled": memory is not None and memory.is_configured(),
            "phase": "1-foundation",
        },
    }


# Para testes locais com agentcore dev
if __name__ == "__main__":
    print("🚀 Iniciando n-agent localmente (Fase 1 - Foundation)...")
    print('📝 Use: agentcore invoke --dev \'{"prompt": "sua mensagem"}\'')
    print(f"🧠 Memory: {'✅ Configured' if MEMORY_ID else '❌ Not configured'}")
    app.run()

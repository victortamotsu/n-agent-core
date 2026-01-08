"""AgentCore Memory implementation for RouterAgent.

This module implements session memory using AgentCore Memory's fully managed service.
No vector store (OpenSearch/S3 Vectors) is required - AWS handles storage internally.

Cost: $0 extra (included in AgentCore Runtime pricing)

References:
  - https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html
  - https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-sdk-memory.html
"""

import os
from typing import List, Dict, Optional

from bedrock_agentcore.memory import MemoryClient


class AgentCoreMemory:
    """Wrapper for AgentCore Memory with session management.

    Uses the simplified tuple-based API from AgentCore SDK.
    """

    def __init__(self, memory_id: Optional[str] = None, region_name: str = "us-east-1"):
        """Initialize Memory client.

        Args:
            memory_id: Memory resource ID (from environment or parameter)
            region_name: AWS region
        """
        self.memory_id = memory_id or os.environ.get("BEDROCK_AGENTCORE_MEMORY_ID")
        self.region_name = region_name
        self._client: Optional[MemoryClient] = None

    @property
    def client(self) -> MemoryClient:
        """Lazy initialization of MemoryClient."""
        if self._client is None:
            self._client = MemoryClient(region_name=self.region_name)
        return self._client

    def is_configured(self) -> bool:
        """Check if Memory is properly configured."""
        return self.memory_id is not None

    def add_interaction(
        self, actor_id: str, session_id: str, user_message: str, agent_response: str
    ) -> None:
        """Save user-agent interaction to memory using create_event API.

        Uses the official documented API with tuple-based messages format.

        Args:
            actor_id: User identifier (e.g., phone number, email)
            session_id: Session identifier
            user_message: User's message
            agent_response: Agent's response
        """
        if not self.memory_id:
            print("⚠️ Memory not configured, skipping save")
            return

        # Use create_event API (official documented method)
        self.client.create_event(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            messages=[
                (user_message, "USER"),
                (agent_response, "ASSISTANT"),
            ],
        )

    def add_conversation(
        self, actor_id: str, session_id: str, messages: List[tuple]
    ) -> None:
        """Save multiple messages at once using create_event API.

        Uses the official documented API with tuple-based messages format.

        Args:
            actor_id: User identifier
            session_id: Session identifier
            messages: List of (content, role) tuples where role is USER, ASSISTANT, or TOOL
        """
        if not self.memory_id:
            print("⚠️ Memory not configured, skipping save")
            return

        # Use create_event for batch saving (official documented method)
        self.client.create_event(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            messages=messages,
        )

    def retrieve_context(
        self, actor_id: str, session_id: str, query: str, top_k: int = 5
    ) -> List[Dict]:
        """Retrieve last K conversation turns for context.

        Uses get_last_k_turns API which is designed for conversation history.

        Args:
            actor_id: User identifier
            session_id: Session identifier
            query: Current user query (not used, kept for API compatibility)
            top_k: Number of conversation turns to retrieve

        Returns:
            List of memory records with content and metadata
        """
        if not self.memory_id:
            return []

        # Use get_last_k_turns for conversation history
        turns = self.client.get_last_k_turns(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            k=top_k,
        )

        # Flatten turns into list of messages
        # Each turn is a list of [user_input, agent_response]
        memories = []
        for turn in turns:
            if isinstance(turn, list):
                for msg in turn:
                    if isinstance(msg, dict):
                        # Extract content - can be dict with 'text' key or direct string
                        content = msg.get("content", "")
                        if isinstance(content, dict):
                            content = content.get("text", str(content))

                        memories.append(
                            {
                                "content": content,
                                "timestamp": msg.get("timestamp"),
                                "role": msg.get("role", ""),
                                "score": 1.0,  # get_last_k_turns doesn't have relevance scores
                            }
                        )
        return memories

    def get_session_summary(self, actor_id: str, session_id: str) -> Optional[str]:
        """Get AI-generated summary of session.

        Note: This requires summaryMemoryStrategy to be configured on the Memory.
        If not configured, returns None.

        Args:
            actor_id: User identifier
            session_id: Session identifier

        Returns:
            Session summary or None if not available
        """
        if not self.memory_id:
            return None

        try:
            # Try to retrieve summary using retrieve_memories
            # This may fail if summary strategy is not configured
            namespace = f"/summaries/{actor_id}/{session_id}"
            response = self.client.retrieve_memories(
                memory_id=self.memory_id,
                namespace=namespace,
                query="session summary",
                actor_id=actor_id,
                top_k=1,
            )

            memories = response if isinstance(response, list) else []
            if memories:
                first = memories[0]
                return (
                    first.get("content")
                    if isinstance(first, dict)
                    else getattr(first, "content", None)
                )
        except Exception:
            # Summary strategy may not be configured
            pass
        return None

    def format_context_for_prompt(
        self,
        actor_id: str,
        session_id: str,
        current_query: str,
        include_summary: bool = True,
    ) -> str:
        """Format memory context for agent prompt.

        Args:
            actor_id: User identifier
            session_id: Session identifier
            current_query: Current user query
            include_summary: Whether to include session summary

        Returns:
            Formatted context string for prompt
        """
        if not self.memory_id:
            return ""

        context_parts = []

        # Get session summary
        if include_summary:
            summary = self.get_session_summary(actor_id, session_id)
            if summary:
                context_parts.append(f"# Session Summary\n{summary}\n")

        # Get relevant memories
        memories = self.retrieve_context(actor_id, session_id, current_query, top_k=5)
        if memories:
            context_parts.append("# Relevant Previous Context")
            for i, mem in enumerate(memories, 1):
                score = mem.get("score", 0.0)
                # Extract text from content (can be dict with 'text' key or string)
                content = mem.get("content", "")
                if isinstance(content, dict):
                    content = content.get("text", str(content))
                context_parts.append(
                    f"{i}. [{mem['role']}] {content} (relevance: {score:.2f})"
                )

        return "\n".join(context_parts) if context_parts else ""


def create_memory_if_not_exists(
    memory_name: str = "n-agent-memory",
    region_name: str = "us-east-1",
    with_strategies: bool = True,
) -> str:
    """Create a new AgentCore Memory resource if it doesn't exist.

    Args:
        memory_name: Name for the memory resource
        region_name: AWS region
        with_strategies: Whether to include long-term memory strategies

    Returns:
        Memory ID (existing or newly created)
    """
    client = MemoryClient(region_name=region_name)

    # Check if memory already exists
    try:
        memories = client.list_memories()
        existing = [
            m for m in memories.get("memories", []) if m.get("name") == memory_name
        ]
        if existing:
            memory_id = existing[0].get("id")
            print(f"✅ Using existing memory: {memory_id}")
            return memory_id
    except Exception:
        pass  # Continue to create

    # Create new memory
    strategies = []
    if with_strategies:
        strategies = [
            {
                "summaryMemoryStrategy": {
                    "name": "TripSessionSummarizer",
                    "namespaces": ["/summaries/{actorId}/{sessionId}"],
                }
            },
            {
                "userPreferenceMemoryStrategy": {
                    "name": "TravelPreferences",
                    "namespaces": ["/users/{actorId}/preferences"],
                }
            },
        ]

    print(f"🔄 Creating new memory: {memory_name}...")
    memory = client.create_memory_and_wait(
        name=memory_name,
        description="Session memory for n-agent travel assistant",
        strategies=strategies if strategies else None,
    )

    memory_id = memory.get("id")
    print(f"✅ Memory created: {memory_id}")
    return memory_id


# Example usage
def example_usage():
    """Example of using AgentCore Memory in RouterAgent."""

    # Skip if no memory configured
    memory = AgentCoreMemory()
    if not memory.is_configured():
        print("⚠️ Memory not configured. Run setup script first.")
        return

    # Add interaction
    memory.add_interaction(
        actor_id="user123",
        session_id="session-abc",
        user_message="Estou planejando uma viagem para Paris em junho",
        agent_response="Que legal! Paris em junho é ótimo. Quantos dias você pretende ficar?",
    )

    # Retrieve context for next message
    context = memory.format_context_for_prompt(
        actor_id="user123",
        session_id="session-abc",
        current_query="Quero visitar a Torre Eiffel",
    )

    print(f"Context for prompt:\n{context}")


if __name__ == "__main__":
    example_usage()

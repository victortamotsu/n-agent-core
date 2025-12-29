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
from bedrock_agentcore.memory.types import (
    ConversationalMessage,
    MessageRole,
    CreateEventRequest,
    RetrieveMemoriesRequest
)


class AgentCoreMemory:
    """Wrapper for AgentCore Memory with session management."""
    
    def __init__(self, memory_id: Optional[str] = None, region_name: str = "us-east-1"):
        """Initialize Memory client.
        
        Args:
            memory_id: Memory resource ID (from environment or parameter)
            region_name: AWS region
        """
        self.memory_id = memory_id or os.environ.get("BEDROCK_AGENTCORE_MEMORY_ID")
        if not self.memory_id:
            raise ValueError(
                "BEDROCK_AGENTCORE_MEMORY_ID environment variable not set. "
                "Create memory via AWS CLI first."
            )
        
        self.client = MemoryClient(region_name=region_name)
    
    def add_interaction(
        self,
        actor_id: str,
        session_id: str,
        user_message: str,
        agent_response: str
    ) -> None:
        """Save user-agent interaction to memory.
        
        Args:
            actor_id: User identifier (e.g., phone number, email)
            session_id: Session identifier
            user_message: User's message
            agent_response: Agent's response
        """
        request = CreateEventRequest(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            messages=[
                ConversationalMessage(
                    content=user_message,
                    role=MessageRole.USER
                ),
                ConversationalMessage(
                    content=agent_response,
                    role=MessageRole.ASSISTANT
                )
            ]
        )
        
        self.client.create_event(request)
    
    def retrieve_context(
        self,
        actor_id: str,
        session_id: str,
        query: str,
        top_k: int = 5
    ) -> List[Dict]:
        """Retrieve relevant memories for context.
        
        Args:
            actor_id: User identifier
            session_id: Session identifier
            query: Current user query
            top_k: Number of relevant memories to retrieve
            
        Returns:
            List of memory records with content and metadata
        """
        request = RetrieveMemoriesRequest(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            query=query,
            max_results=top_k
        )
        
        response = self.client.retrieve_memories(request)
        
        return [
            {
                "content": memory.content,
                "timestamp": memory.timestamp,
                "role": memory.role,
                "score": memory.score
            }
            for memory in response.memories
        ]
    
    def get_session_summary(
        self,
        actor_id: str,
        session_id: str
    ) -> Optional[str]:
        """Get AI-generated summary of session.
        
        AgentCore Memory automatically generates summaries of long conversations.
        
        Args:
            actor_id: User identifier
            session_id: Session identifier
            
        Returns:
            Session summary or None if not available
        """
        # Retrieve summaries namespace
        request = RetrieveMemoriesRequest(
            memory_id=self.memory_id,
            actor_id=actor_id,
            session_id=session_id,
            namespace_prefix=f"/summaries/{actor_id}/{session_id}",
            max_results=1
        )
        
        response = self.client.retrieve_memories(request)
        
        if response.memories:
            return response.memories[0].content
        return None
    
    def format_context_for_prompt(
        self,
        actor_id: str,
        session_id: str,
        current_query: str,
        include_summary: bool = True
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
                context_parts.append(
                    f"{i}. [{mem['role']}] {mem['content']} "
                    f"(relevance: {mem['score']:.2f})"
                )
        
        return "\n".join(context_parts) if context_parts else ""


# Example usage in RouterAgent
def example_usage():
    """Example of using AgentCore Memory in RouterAgent."""
    
    memory = AgentCoreMemory()
    
    # Add interaction
    memory.add_interaction(
        actor_id="user123",
        session_id="session-abc",
        user_message="Estou planejando uma viagem para Paris em junho",
        agent_response="Que legal! Paris em junho é ótimo. Quantos dias você pretende ficar?"
    )
    
    # Retrieve context for next message
    context = memory.format_context_for_prompt(
        actor_id="user123",
        session_id="session-abc",
        current_query="Quero visitar a Torre Eiffel"
    )
    
    print(f"Context for prompt:\n{context}")


if __name__ == "__main__":
    example_usage()

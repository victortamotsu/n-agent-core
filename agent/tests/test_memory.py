"""
Unit tests for AgentCore Memory integration.

Tests the Memory wrapper and its integration with the main entrypoint.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
import os


class TestAgentCoreMemory:
    """Test suite for AgentCoreMemory class."""

    @pytest.fixture
    def mock_memory_client(self):
        """Create mock MemoryClient."""
        with patch("src.memory.agentcore_memory.MemoryClient") as mock:
            client_instance = Mock()
            mock.return_value = client_instance
            yield client_instance

    def test_memory_init_with_env_var(self, mock_memory_client):
        """Test Memory initialization with environment variable."""
        with patch.dict(os.environ, {"BEDROCK_AGENTCORE_MEMORY_ID": "mem-test-123"}):
            from src.memory.agentcore_memory import AgentCoreMemory

            memory = AgentCoreMemory()
            assert memory.memory_id == "mem-test-123"
            assert memory.is_configured() is True

    def test_memory_init_with_param(self, mock_memory_client):
        """Test Memory initialization with parameter."""
        from src.memory.agentcore_memory import AgentCoreMemory

        memory = AgentCoreMemory(memory_id="mem-param-456")
        assert memory.memory_id == "mem-param-456"
        assert memory.is_configured() is True

    def test_memory_init_without_config(self, mock_memory_client):
        """Test Memory initialization without configuration (graceful)."""
        with patch.dict(os.environ, {}, clear=True):
            # Remove the env var if it exists
            os.environ.pop("BEDROCK_AGENTCORE_MEMORY_ID", None)

            from src.memory.agentcore_memory import AgentCoreMemory

            memory = AgentCoreMemory()
            assert memory.is_configured() is False

    def test_add_interaction_when_configured(self, mock_memory_client):
        """Test add_interaction when Memory is configured."""
        from src.memory.agentcore_memory import AgentCoreMemory

        memory = AgentCoreMemory(memory_id="mem-test-123")
        memory.add_interaction(
            actor_id="user123",
            session_id="session-abc",
            user_message="Olá!",
            agent_response="Olá! Como posso ajudar?",
        )

        # Verify create_event was called with tuple messages
        mock_memory_client.create_event.assert_called_once()
        call_kwargs = mock_memory_client.create_event.call_args[1]
        assert call_kwargs["memory_id"] == "mem-test-123"
        assert call_kwargs["actor_id"] == "user123"
        assert call_kwargs["session_id"] == "session-abc"
        assert len(call_kwargs["messages"]) == 2
        assert call_kwargs["messages"][0] == ("Olá!", "USER")
        assert call_kwargs["messages"][1] == ("Olá! Como posso ajudar?", "ASSISTANT")

    def test_add_interaction_when_not_configured(self, mock_memory_client, capsys):
        """Test add_interaction gracefully skips when not configured."""
        with patch.dict(os.environ, {}, clear=True):
            os.environ.pop("BEDROCK_AGENTCORE_MEMORY_ID", None)

            from src.memory.agentcore_memory import AgentCoreMemory

            memory = AgentCoreMemory()
            memory.add_interaction(
                actor_id="user123",
                session_id="session-abc",
                user_message="Olá!",
                agent_response="Olá!",
            )

            # Should not call create_event
            mock_memory_client.create_event.assert_not_called()
            captured = capsys.readouterr()
            assert "Memory not configured" in captured.out

    def test_retrieve_context_when_configured(self, mock_memory_client):
        """Test retrieve_context returns formatted memories from get_last_k_turns."""
        from src.memory.agentcore_memory import AgentCoreMemory

        # Setup mock response - get_last_k_turns returns List[List[Dict]]
        # Each turn is a list of [user_input, agent_response]
        mock_memory_client.get_last_k_turns.return_value = [
            [
                {"content": "User asked about Paris", "timestamp": "2025-01-01T10:00:00Z", "role": "USER"},
                {"content": "Agent provided Paris tips", "timestamp": "2025-01-01T10:00:01Z", "role": "ASSISTANT"},
            ],
        ]

        memory = AgentCoreMemory(memory_id="mem-test-123")
        result = memory.retrieve_context(
            actor_id="user123",
            session_id="session-abc",
            query="Paris travel",
            top_k=5,
        )

        assert len(result) == 2
        assert result[0]["content"] == "User asked about Paris"
        assert result[0]["score"] == 1.0  # get_last_k_turns doesn't have relevance scores
        assert result[1]["role"] == "ASSISTANT"

    def test_retrieve_context_when_not_configured(self, mock_memory_client):
        """Test retrieve_context returns empty list when not configured."""
        with patch.dict(os.environ, {}, clear=True):
            os.environ.pop("BEDROCK_AGENTCORE_MEMORY_ID", None)

            from src.memory.agentcore_memory import AgentCoreMemory

            memory = AgentCoreMemory()
            result = memory.retrieve_context(
                actor_id="user123",
                session_id="session-abc",
                query="test",
            )

            assert result == []
            mock_memory_client.retrieve_memories.assert_not_called()

    def test_format_context_for_prompt(self, mock_memory_client):
        """Test format_context_for_prompt generates proper context string."""
        from src.memory.agentcore_memory import AgentCoreMemory

        # Setup mock responses
        # Mock get_last_k_turns for context retrieval
        mock_memory_client.get_last_k_turns.return_value = [
            [
                {"content": "Planning Paris trip", "role": "USER"},
            ],
        ]
        # Mock retrieve_memories for summary (returns empty)
        mock_memory_client.retrieve_memories.return_value = []

        memory = AgentCoreMemory(memory_id="mem-test-123")
        context = memory.format_context_for_prompt(
            actor_id="user123",
            session_id="session-abc",
            current_query="What about the Eiffel Tower?",
            include_summary=True,
        )

        assert "Relevant Previous Context" in context
        assert "Planning Paris trip" in context
        assert "1.00" in context  # Score formatted (now always 1.0)

    def test_add_conversation_batch(self, mock_memory_client):
        """Test add_conversation with multiple messages."""
        from src.memory.agentcore_memory import AgentCoreMemory

        memory = AgentCoreMemory(memory_id="mem-test-123")
        messages = [
            ("Olá!", "USER"),
            ("Olá! Como posso ajudar?", "ASSISTANT"),
            ("Quero planejar uma viagem", "USER"),
            ("Ótimo! Para onde você gostaria de ir?", "ASSISTANT"),
        ]

        memory.add_conversation(
            actor_id="user123",
            session_id="session-abc",
            messages=messages,
        )

        # Verify create_event was called
        mock_memory_client.create_event.assert_called_once()
        call_kwargs = mock_memory_client.create_event.call_args[1]
        assert len(call_kwargs["messages"]) == 4


class TestMainWithMemory:
    """Test main.py integration with Memory."""

    @pytest.fixture
    def mock_router(self):
        """Mock router for tests."""
        with patch("src.main.router") as mock:
            mock.route.return_value = {
                "model_id": "us.amazon.nova-lite-v1:0",
                "complexity": "informative",
                "use_tools": False,
                "use_memory": True,
                "routing_time_ms": 50,
            }
            yield mock

    @pytest.fixture
    def mock_agent(self):
        """Mock Strands Agent."""
        with patch("src.main.Agent") as mock:
            instance = Mock()
            instance.return_value = "Test response from agent"
            mock.return_value = instance
            yield mock

    @pytest.fixture
    def mock_memory_module(self):
        """Mock the memory module."""
        with patch("src.main.memory") as mock:
            mock.is_configured.return_value = True
            mock.format_context_for_prompt.return_value = "Previous context..."
            mock.add_interaction.return_value = None
            yield mock

    def test_invoke_uses_memory_context(
        self, mock_router, mock_agent, mock_memory_module
    ):
        """Test that invoke retrieves and uses memory context."""
        from src.main import invoke

        payload = {"prompt": "What about the Eiffel Tower?"}
        context = Mock()
        context.session_id = "test-session"
        context.headers = {}

        result = invoke(payload, context)

        # Verify memory was queried for context
        mock_memory_module.format_context_for_prompt.assert_called_once()

        # Verify response structure
        assert "response" in result
        assert result["metadata"]["memory_enabled"] is True

    def test_invoke_saves_to_memory(self, mock_router, mock_agent, mock_memory_module):
        """Test that invoke saves interaction to memory."""
        from src.main import invoke

        payload = {"prompt": "Hello!"}
        context = Mock()
        context.session_id = "test-session"
        context.headers = {"X-Amzn-Bedrock-AgentCore-Runtime-Custom-Actor-Id": "user1"}

        invoke(payload, context)

        # Verify interaction was saved
        mock_memory_module.add_interaction.assert_called_once()
        call_kwargs = mock_memory_module.add_interaction.call_args[1]
        assert call_kwargs["actor_id"] == "user1"
        assert call_kwargs["session_id"] == "test-session"
        assert call_kwargs["user_message"] == "Hello!"

    @patch("src.main.memory", None)
    def test_invoke_works_without_memory(self, mock_router, mock_agent):
        """Test that invoke works gracefully without memory configured."""
        from src.main import invoke

        payload = {"prompt": "Hello!"}

        result = invoke(payload, None)

        assert "response" in result
        assert result["metadata"]["memory_enabled"] is False

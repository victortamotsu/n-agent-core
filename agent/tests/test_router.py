"""
Unit tests for Agent Router
Tests classification logic, model selection, and cost optimization
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.router.agent_router import AgentRouter, QueryComplexity


class TestAgentRouter:
    """Test suite for AgentRouter class."""
    
    @pytest.fixture
    def router(self):
        """Create router instance for tests."""
        return AgentRouter(region_name='us-east-1')
    
    def test_trivial_pattern_detection(self, router):
        """Test fast detection of trivial messages without API calls."""
        trivial_messages = [
            "Oi!",
            "Olá",
            "Obrigado",
            "Ok",
            "Sim",
            "👍"
        ]
        
        for message in trivial_messages:
            assert router.is_trivial_pattern(message), f"'{message}' should be trivial"
    
    def test_non_trivial_pattern_detection(self, router):
        """Test that complex messages are not detected as trivial."""
        complex_messages = [
            "Qual meu hotel em Roma?",
            "Planeje 3 dias",
            "Onde fica o Coliseu?"
        ]
        
        for message in complex_messages:
            assert not router.is_trivial_pattern(message), f"'{message}' should not be trivial"
    
    def test_vision_detection(self, router):
        """Test that images are immediately classified as VISION."""
        result = router.classify_query(
            user_message="Analise este documento",
            has_image=True
        )
        assert result == QueryComplexity.VISION
    
    @patch('src.router.agent_router.Agent')
    def test_classification_with_mocked_agent(self, mock_agent_class, router):
        """Test classification logic with mocked Strands Agent."""
        # Setup mock
        mock_agent_instance = MagicMock()
        mock_agent_class.return_value = mock_agent_instance
        
        # Simulate agent returning "COMPLEX"
        mock_result = MagicMock()
        mock_result.message = {'content': [{'text': 'COMPLEX'}]}
        mock_agent_instance.return_value = mock_result
        
        # Test
        result = router.classify_query(
            user_message="Planeje 3 dias em Roma"
        )
        
        assert result == QueryComplexity.COMPLEX
        mock_agent_class.assert_called_once()
    
    def test_model_selection_for_trivial(self, router):
        """Test that trivial queries use Nova Lite (cheapest)."""
        config = router.get_model_for_complexity(QueryComplexity.TRIVIAL)
        assert config['id'] == 'us.amazon.nova-lite-v1:0'
        assert config['cost_input'] == 0.06
    
    def test_model_selection_for_complex(self, router):
        """Test that complex queries use Nova Pro (powerful)."""
        config = router.get_model_for_complexity(QueryComplexity.COMPLEX)
        assert config['id'] == 'us.amazon.nova-pro-v1:0'
        assert config['cost_input'] == 0.80
    
    def test_model_selection_for_vision(self, router):
        """Test that vision queries use Claude Sonnet."""
        config = router.get_model_for_complexity(QueryComplexity.VISION)
        assert config['id'] == 'anthropic.claude-3-sonnet-20240229-v1:0'
        assert config['cost_input'] == 3.00
    
    @patch('src.router.agent_router.Agent')
    def test_route_returns_complete_config(self, mock_agent_class, router):
        """Test that route() returns all expected fields."""
        # Setup mock for trivial pattern (no agent call)
        config = router.route(user_message="Oi!")
        
        # Verify all required fields present
        assert 'model_id' in config
        assert 'complexity' in config
        assert 'use_tools' in config
        assert 'use_memory' in config
        assert 'enable_cache' in config
        assert 'cost_input_per_1m' in config
        assert 'cost_output_per_1m' in config
        assert 'routing_time_ms' in config
        
        # Verify trivial doesn't use tools
        assert config['complexity'] == 'trivial'
        assert config['use_tools'] is False
    
    @patch('src.router.agent_router.Agent')
    def test_complex_query_enables_tools(self, mock_agent_class, router):
        """Test that complex queries enable tool usage."""
        # Setup mock
        mock_agent_instance = MagicMock()
        mock_agent_class.return_value = mock_agent_instance
        mock_result = MagicMock()
        mock_result.message = {'content': [{'text': 'COMPLEX'}]}
        mock_agent_instance.return_value = mock_result
        
        # Test
        config = router.route(user_message="Planeje 3 dias em Roma")
        
        assert config['complexity'] == 'complex'
        assert config['use_tools'] is True
    
    def test_fallback_on_classification_error(self, router):
        """Test that router falls back to INFORMATIVE on errors."""
        # Force error by passing invalid data
        with patch('src.router.agent_router.Agent', side_effect=Exception("Test error")):
            result = router.classify_query(user_message="Test")
            assert result == QueryComplexity.INFORMATIVE
    
    @patch('src.router.agent_router.AgentCoreMemorySessionManager')
    @patch('src.router.agent_router.MemoryClient')
    def test_memory_setup(self, mock_memory_client, mock_session_manager):
        """Test AgentCore Memory configuration."""
        # Use valid memory ID format: [a-zA-Z][a-zA-Z0-9-_]{0,99}-[a-zA-Z0-9]{10}
        memory_id = "test-memory-1234567890"
        
        # Mock the memory client and session manager to avoid AWS API calls
        router = AgentRouter(memory_id=memory_id, region_name='us-east-1')
        
        assert router.memory_id == memory_id
        # Verify memory client was initialized
        mock_memory_client.assert_called_once_with(region_name='us-east-1')


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

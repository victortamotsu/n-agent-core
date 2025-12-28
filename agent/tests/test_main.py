"""
Unit tests for main.py
Tests BedrockAgentCoreApp entrypoint and integration
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.main import invoke
from src.router.agent_router import QueryComplexity


class TestMainEntrypoint:
    """Test suite for main entrypoint."""
    
    @pytest.fixture
    def mock_context(self):
        """Create mock context object."""
        context = Mock()
        context.session_id = 'test-session-123'
        context.headers = {
            'X-Amzn-Bedrock-AgentCore-Runtime-Custom-Actor-Id': 'test-user'
        }
        return context
    
    @pytest.fixture
    def basic_payload(self):
        """Create basic test payload."""
        return {
            "prompt": "Olá! Quero planejar uma viagem.",
            "trip_id": None,
            "has_image": False
        }
    
    @patch('src.main.router')
    def test_invoke_with_basic_payload(self, mock_router, basic_payload, mock_context):
        """Test invoke function with basic payload."""
        # Setup mock router
        mock_router.route.return_value = {
            'model_id': 'us.amazon.nova-lite-v1:0',
            'complexity': 'informative',
            'use_tools': False,
            'use_memory': True,
            'routing_time_ms': 100,
            'enable_cache': True,
            'cost_input_per_1m': 0.06,
            'cost_output_per_1m': 0.24
        }
        
        # Call invoke
        result = invoke(basic_payload, mock_context)
        
        # Verify router was called
        mock_router.route.assert_called_once()
        
        # Verify result structure
        assert 'response' in result
        assert 'metadata' in result
        assert result['metadata']['session_id'] == 'test-session-123'
        assert result['metadata']['actor_id'] == 'test-user'
        assert 'routing' in result['metadata']
    
    @patch('src.main.router')
    def test_invoke_with_image(self, mock_router, mock_context):
        """Test invoke function with image payload."""
        # Setup
        payload = {
            "prompt": "Analise este documento",
            "has_image": True
        }
        
        mock_router.route.return_value = {
            'model_id': 'anthropic.claude-3-sonnet-20240229-v1:0',
            'complexity': 'vision',
            'use_tools': False,
            'use_memory': True,
            'routing_time_ms': 0,
            'enable_cache': True,
            'cost_input_per_1m': 3.00,
            'cost_output_per_1m': 0
        }
        
        # Call
        result = invoke(payload, mock_context)
        
        # Verify vision complexity
        assert result['metadata']['routing']['complexity'] == 'vision'
        assert 'claude' in result['metadata']['routing']['model_id']
    
    @patch('src.main.router')
    def test_invoke_without_context(self, mock_router, basic_payload):
        """Test invoke function without context (defaults)."""
        mock_router.route.return_value = {
            'model_id': 'us.amazon.nova-lite-v1:0',
            'complexity': 'informative',
            'use_tools': False,
            'use_memory': True,
            'routing_time_ms': 100,
            'enable_cache': True,
            'cost_input_per_1m': 0.06,
            'cost_output_per_1m': 0.24
        }
        
        # Call without context
        result = invoke(basic_payload, None)
        
        # Should use default values
        assert result['metadata']['session_id'] == 'default'
        assert result['metadata']['actor_id'] == 'user'
    
    @patch('src.main.router')
    def test_invoke_with_trip_context(self, mock_router, mock_context):
        """Test invoke with trip_id in payload."""
        payload = {
            "prompt": "Qual meu hotel?",
            "trip_id": "trip-rome-2024",
            "has_image": False
        }
        
        mock_router.route.return_value = {
            'model_id': 'us.amazon.nova-lite-v1:0',
            'complexity': 'informative',
            'use_tools': False,
            'use_memory': True,
            'routing_time_ms': 50,
            'enable_cache': True,
            'cost_input_per_1m': 0.06,
            'cost_output_per_1m': 0.24
        }
        
        result = invoke(payload, mock_context)
        
        # Verify trip_id passed to router
        call_args = mock_router.route.call_args
        assert call_args[1]['trip_context'] == {'trip_id': 'trip-rome-2024'}
        
        # Verify trip_id in metadata
        assert result['metadata']['trip_id'] == 'trip-rome-2024'
    
    @patch('src.main.router')
    def test_response_includes_all_required_fields(self, mock_router, basic_payload, mock_context):
        """Test that response includes all required fields."""
        mock_router.route.return_value = {
            'model_id': 'us.amazon.nova-lite-v1:0',
            'complexity': 'informative',
            'use_tools': False,
            'use_memory': True,
            'routing_time_ms': 100,
            'enable_cache': True,
            'cost_input_per_1m': 0.06,
            'cost_output_per_1m': 0.24
        }
        
        result = invoke(basic_payload, mock_context)
        
        # Top level fields
        assert 'response' in result
        assert 'metadata' in result
        assert isinstance(result['response'], str)
        assert isinstance(result['metadata'], dict)
        
        # Metadata fields
        metadata = result['metadata']
        assert 'timestamp' in metadata
        assert 'session_id' in metadata
        assert 'actor_id' in metadata
        assert 'routing' in metadata
        assert 'phase' in metadata
        
        # Routing fields
        routing = metadata['routing']
        assert 'complexity' in routing
        assert 'model_id' in routing
        assert 'routing_time_ms' in routing
        assert 'use_tools' in routing
        assert 'use_memory' in routing
    
    @patch('src.main.router')
    def test_complex_query_routing(self, mock_router, mock_context):
        """Test that complex queries are routed correctly."""
        payload = {
            "prompt": "Planeje 3 dias em Roma com visitas ao Coliseu e Vaticano"
        }
        
        mock_router.route.return_value = {
            'model_id': 'us.amazon.nova-pro-v1:0',
            'complexity': 'complex',
            'use_tools': True,
            'use_memory': True,
            'routing_time_ms': 450,
            'enable_cache': True,
            'cost_input_per_1m': 0.80,
            'cost_output_per_1m': 3.20
        }
        
        result = invoke(payload, mock_context)
        
        # Verify complex routing
        assert result['metadata']['routing']['complexity'] == 'complex'
        assert result['metadata']['routing']['use_tools'] is True
        assert 'nova-pro' in result['metadata']['routing']['model_id']


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

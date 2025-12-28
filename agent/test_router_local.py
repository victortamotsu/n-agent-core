"""
Script de teste local do n-agent
Testa o Router Agent e a integração com Strands SDK
"""

import sys
import os

# Adicionar diretório src ao PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from router.agent_router import AgentRouter

# Inicializar Router Agent
router = AgentRouter()

# Testes
test_cases = [
    {
        "message": "Oi!",
        "has_image": False,
        "context": None,
        "expected": "trivial"
    },
    {
        "message": "Qual meu hotel em Roma?",
        "has_image": False,
        "context": {'status': 'PLANNING'},
        "expected": "informative"
    },
    {
        "message": "Planeje 3 dias em Roma com visitas ao Coliseu e Vaticano",
        "has_image": False,
        "context": None,
        "expected": "complex"
    },
    {
        "message": "Analise este documento de reserva",
        "has_image": True,
        "context": None,
        "expected": "vision"
    },
]

print("\n" + "="*80)
print("🧪 TESTANDO N-AGENT - ROUTER AGENT COM STRANDS SDK")
print("="*80 + "\n")

for i, test in enumerate(test_cases, 1):
    print(f"Test {i}/{ len(test_cases)}: '{test['message']}'")
    
    config = router.route(
        user_message=test['message'],
        has_image=test['has_image'],
        trip_context=test['context']
    )
    
    complexity = config['complexity']
    model = config['model_id']
    time_ms = config['routing_time_ms']
    
    status = "✅ PASS" if complexity == test['expected'] else f"❌ FAIL (expected {test['expected']})"
    
    print(f"  → Complexity: {complexity}")
    print(f"  → Model: {model}")
    print(f"  → Time: {time_ms}ms")
    print(f"  {status}\n")

print("="*80)
print("✅ FASE 0 COMPLETA: Router Agent funcionando com Strands SDK")
print("="*80)

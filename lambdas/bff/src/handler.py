"""
Lambda BFF (Backend-for-Frontend) para n-agent

Recebe requests do API Gateway e invoca o AgentCore Runtime.
Extrai user_id do JWT token do Cognito.
"""

import json
import os
import boto3
from typing import Dict, Any

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-agent-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# Environment variables
AGENT_ID = os.environ.get('AGENTCORE_AGENT_ID')
AGENT_ALIAS_ID = os.environ.get('AGENTCORE_AGENT_ALIAS_ID', 'TSTALIASID')


def extract_user_info(event: Dict[str, Any]) -> Dict[str, str]:
    """
    Extrai informações do usuário do JWT token (Cognito).
    
    Args:
        event: Evento do API Gateway
        
    Returns:
        Dict com user_id, email, name
    """
    # JWT claims do Cognito vêm em requestContext.authorizer.jwt.claims
    claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
    
    return {
        'user_id': claims.get('sub', 'anonymous'),
        'email': claims.get('email', ''),
        'name': claims.get('name', ''),
        'cognito_username': claims.get('cognito:username', '')
    }


def invoke_agentcore(
    prompt: str,
    session_id: str,
    user_id: str,
    trip_id: str = None,
    has_image: bool = False
) -> Dict[str, Any]:
    """
    Invoca o AgentCore Runtime.
    
    Args:
        prompt: Mensagem do usuário
        session_id: ID da sessão
        user_id: ID do usuário
        trip_id: ID da viagem (opcional)
        has_image: Se há imagem anexada
        
    Returns:
        Resposta do agent
    """
    # Preparar input para o agent
    agent_input = {
        'prompt': prompt,
        'trip_id': trip_id,
        'has_image': has_image
    }
    
    # Invocar agent via Bedrock Agent Runtime
    try:
        response = bedrock_runtime.invoke_agent(
            agentId=AGENT_ID,
            agentAliasId=AGENT_ALIAS_ID,
            sessionId=session_id,
            inputText=json.dumps(agent_input),
            sessionState={
                'sessionAttributes': {
                    'user_id': user_id,
                    'trip_id': trip_id or ''
                }
            }
        )
        
        # Processar resposta streaming
        result = ""
        completion = response.get('completion', [])
        
        for event in completion:
            if 'chunk' in event:
                chunk_data = event['chunk']
                if 'bytes' in chunk_data:
                    result += chunk_data['bytes'].decode('utf-8')
        
        return {
            'success': True,
            'response': result,
            'session_id': session_id
        }
        
    except Exception as e:
        print(f"Error invoking agent: {str(e)}")
        return {
            'success': False,
            'error': str(e),
            'response': "Desculpe, tive um problema ao processar sua mensagem. Tente novamente."
        }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handler principal da Lambda.
    
    Args:
        event: Evento do API Gateway
        context: Contexto do Lambda
        
    Returns:
        Response para API Gateway
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Extract user info from JWT
    user_info = extract_user_info(event)
    user_id = user_info['user_id']
    
    # Parse request body
    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    
    # Extract request parameters
    prompt = body.get('prompt', body.get('message', ''))
    trip_id = body.get('trip_id')
    has_image = body.get('has_image', False)
    session_id = body.get('session_id', f"session-{user_id}")
    
    # Validate prompt
    if not prompt:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Missing prompt or message in request'
            })
        }
    
    # Invoke AgentCore
    agent_response = invoke_agentcore(
        prompt=prompt,
        session_id=session_id,
        user_id=user_id,
        trip_id=trip_id,
        has_image=has_image
    )
    
    # Return response
    if agent_response['success']:
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': agent_response['response'],
                'session_id': agent_response['session_id'],
                'user_id': user_id,
                'trip_id': trip_id
            })
        }
    else:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Agent invocation failed',
                'details': agent_response.get('error', 'Unknown error'),
                'response': agent_response['response']
            })
        }

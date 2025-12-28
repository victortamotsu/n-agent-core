/**
 * AI Orchestrator - Lambda Handler
 * 
 * Serviço central de orquestração de AI
 * Invoca o Bedrock Agent e gerencia o fluxo de conversação
 */

import {
  BedrockAgentRuntimeClient,
  InvokeAgentCommand,
  InvokeAgentCommandInput,
} from '@aws-sdk/client-bedrock-agent-runtime';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createLogger } from '@n-agent/logger';
import type { AgentSession, ChatMessage, TripState } from '@n-agent/core-types';
import { KNOWLEDGE_PHASE_PROMPT, PLANNING_PHASE_PROMPT } from './prompts.js';

// =============================================================================
// CONFIGURAÇÃO
// =============================================================================

const logger = createLogger('ai-orchestrator');

const AGENT_ID = process.env.BEDROCK_AGENT_ID!;
const AGENT_ALIAS_ID = process.env.BEDROCK_AGENT_ALIAS_ID!;
const TABLE_NAME = process.env.DYNAMODB_TABLE!;
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

// Clientes AWS
const bedrockClient = new BedrockAgentRuntimeClient({ region: AWS_REGION });
const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient({ region: AWS_REGION }));

// =============================================================================
// TIPOS
// =============================================================================

export interface OrchestratorInput {
  userId: string;
  message: string;
  sessionId?: string;
  tripId?: string;
  platform: 'whatsapp' | 'web' | 'api';
  metadata?: {
    messageId?: string;
    timestamp?: string;
  };
}

export interface OrchestratorOutput {
  sessionId: string;
  tripId?: string;
  response: string;
  phase: string;
  knowledgeScore?: number;
  suggestedActions?: string[];
}

// =============================================================================
// FUNÇÕES AUXILIARES
// =============================================================================

/**
 * Gera um ID único
 */
function generateId(prefix: string): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 8);
  return `${prefix}_${timestamp}${random}`;
}

/**
 * Busca ou cria uma sessão de conversa
 */
async function getOrCreateSession(userId: string, sessionId?: string): Promise<AgentSession> {
  if (sessionId) {
    const result = await ddbClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `SESSION#${sessionId}`, SK: 'METADATA' },
    }));
    
    if (result.Item) {
      return result.Item as AgentSession;
    }
  }
  
  // Criar nova sessão
  const newSession: AgentSession = {
    sessionId: generateId('sess'),
    userId,
    platform: 'whatsapp',
    isActive: true,
    startedAt: new Date().toISOString(),
    lastActivityAt: new Date().toISOString(),
    messageCount: 0,
  };
  
  await ddbClient.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `SESSION#${newSession.sessionId}`,
      SK: 'METADATA',
      ...newSession,
    },
  }));
  
  return newSession;
}

/**
 * Busca a viagem ativa do usuário
 */
async function getActiveTrip(userId: string): Promise<TripState | null> {
  const result = await ddbClient.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `USER#${userId}`, SK: 'ACTIVE_TRIP' },
  }));
  
  if (result.Item?.tripId) {
    const tripResult = await ddbClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TRIP#${result.Item.tripId}`, SK: 'METADATA' },
    }));
    return tripResult.Item as TripState | null;
  }
  
  return null;
}

/**
 * Salva uma mensagem no histórico
 */
async function saveMessage(sessionId: string, role: 'user' | 'assistant', content: string): Promise<void> {
  const message: ChatMessage = {
    messageId: generateId('msg'),
    sessionId,
    role,
    content,
    timestamp: new Date().toISOString(),
  };
  
  await ddbClient.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: {
      PK: `SESSION#${sessionId}`,
      SK: `MSG#${message.timestamp}#${message.messageId}`,
      ...message,
    },
  }));
}

/**
 * Busca mensagens recentes da sessão (TODO: implementar)
 */
// @ts-expect-error - Função não utilizada, será implementada futuramente
// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function _getRecentMessages(_sessionId: string, _limit: number = 10): Promise<ChatMessage[]> {
  // TODO: Implementar query com limit e ordenação
  return [];
}

/**
 * Monta o contexto para o agente
 */
async function buildAgentContext(_userId: string, trip: TripState | null): Promise<string> {
  const parts: string[] = [];
  
  if (trip) {
    parts.push(`## Estado Atual da Viagem`);
    parts.push(`- ID: ${trip.tripId}`);
    parts.push(`- Fase: ${trip.currentPhase}`);
    parts.push(`- Knowledge Score: ${trip.knowledgeScore}%`);
    
    if (trip.destinations.length > 0) {
      parts.push(`- Destinos: ${trip.destinations.map((d: { name: string }) => d.name).join(', ')}`);
    }
    if (trip.dates.startDate) {
      parts.push(`- Data início: ${trip.dates.startDate}`);
    }
    if (trip.dates.endDate) {
      parts.push(`- Data fim: ${trip.dates.endDate}`);
    }
    if (trip.travelers.count > 0) {
      parts.push(`- Viajantes: ${trip.travelers.count} (${trip.travelers.adults} adultos, ${trip.travelers.children} crianças)`);
    }
    if (trip.budget.totalAmount) {
      parts.push(`- Orçamento: ${trip.budget.currency} ${trip.budget.totalAmount}`);
    }
    
    if (trip.pendingQuestions.length > 0) {
      parts.push(`\n## Informações Pendentes`);
      parts.push(trip.pendingQuestions.join('\n- '));
    }
  } else {
    parts.push(`## Novo Usuário`);
    parts.push(`Este usuário ainda não tem viagens em planejamento.`);
    parts.push(`Inicie com uma saudação amigável e pergunte sobre seus planos de viagem.`);
  }
  
  return parts.join('\n');
}

/**
 * Obtém o prompt específico da fase
 */
function getPhasePrompt(phase: string): string {
  switch (phase) {
    case 'KNOWLEDGE':
      return KNOWLEDGE_PHASE_PROMPT;
    case 'PLANNING':
      return PLANNING_PHASE_PROMPT;
    default:
      return '';
  }
}

// =============================================================================
// INVOCAÇÃO DO BEDROCK AGENT
// =============================================================================

/**
 * Invoca o Bedrock Agent com a mensagem do usuário
 */
async function invokeBedrockAgent(
  sessionId: string,
  message: string,
  context: string,
  phase: string
): Promise<string> {
  // Monta o prompt completo
  const fullPrompt = [
    context,
    getPhasePrompt(phase),
    `\n## Mensagem do Usuário:\n${message}`,
  ].join('\n\n');
  
  logger.info('Invoking Bedrock Agent', {
    sessionId,
    agentId: AGENT_ID,
    messageLength: message.length,
  });
  
  const input: InvokeAgentCommandInput = {
    agentId: AGENT_ID,
    agentAliasId: AGENT_ALIAS_ID,
    sessionId,
    inputText: fullPrompt,
  };
  
  try {
    const command = new InvokeAgentCommand(input);
    const response = await bedrockClient.send(command);
    
    // Processa o stream de resposta
    let fullResponse = '';
    
    if (response.completion) {
      for await (const event of response.completion) {
        if (event.chunk?.bytes) {
          fullResponse += new TextDecoder().decode(event.chunk.bytes);
        }
      }
    }
    
    logger.info('Bedrock Agent response received', {
      sessionId,
      responseLength: fullResponse.length,
    });
    
    return fullResponse || 'Desculpe, não consegui processar sua mensagem. Pode tentar novamente?';
    
  } catch (error) {
    logger.error('Error invoking Bedrock Agent', { error, sessionId });
    throw error;
  }
}

// =============================================================================
// HANDLER PRINCIPAL
// =============================================================================

/**
 * Handler principal do orchestrator
 */
export async function orchestrate(input: OrchestratorInput): Promise<OrchestratorOutput> {
  const { userId, message, platform } = input;
  
  logger.info('Orchestrator invoked', { userId, messageLength: message.length, platform });
  
  try {
    // 1. Obtém ou cria sessão
    const session = await getOrCreateSession(userId, input.sessionId);
    
    // 2. Busca viagem ativa
    const trip = await getActiveTrip(userId);
    
    // 3. Salva mensagem do usuário
    await saveMessage(session.sessionId, 'user', message);
    
    // 4. Monta contexto
    const context = await buildAgentContext(userId, trip);
    const phase = trip?.currentPhase || 'KNOWLEDGE';
    
    // 5. Invoca Bedrock Agent
    const response = await invokeBedrockAgent(session.sessionId, message, context, phase);
    
    // 6. Salva resposta do agente
    await saveMessage(session.sessionId, 'assistant', response);
    
    // 7. Atualiza sessão
    await ddbClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `SESSION#${session.sessionId}`, SK: 'METADATA' },
      UpdateExpression: 'SET lastActivityAt = :now, messageCount = messageCount + :inc',
      ExpressionAttributeValues: {
        ':now': new Date().toISOString(),
        ':inc': 2, // user + assistant
      },
    }));
    
    logger.info('Orchestration complete', {
      sessionId: session.sessionId,
      tripId: trip?.tripId,
      phase,
    });
    
    return {
      sessionId: session.sessionId,
      tripId: trip?.tripId,
      response,
      phase,
      knowledgeScore: trip?.knowledgeScore,
    };
    
  } catch (error) {
    logger.error('Orchestration failed', { error, userId });
    
    return {
      sessionId: input.sessionId || 'error',
      response: 'Ops, tive um probleminha técnico 😅 Pode tentar novamente em alguns segundos?',
      phase: 'ERROR',
    };
  }
}

// =============================================================================
// LAMBDA HANDLER
// =============================================================================

interface LambdaEvent {
  body?: string;
  detail?: OrchestratorInput;
}

interface LambdaResponse {
  statusCode: number;
  body: string;
  headers?: Record<string, string>;
}

/**
 * Lambda handler para invocação direta ou via API Gateway
 */
export async function handler(event: LambdaEvent): Promise<LambdaResponse> {
  logger.info('Lambda invoked', { eventType: event.detail ? 'EventBridge' : 'APIGateway' });
  
  try {
    // Parse input (pode vir de API Gateway ou EventBridge)
    let input: OrchestratorInput;
    
    if (event.detail) {
      input = event.detail;
    } else if (event.body) {
      input = JSON.parse(event.body);
    } else {
      throw new Error('Invalid event format');
    }
    
    // Validação básica
    if (!input.userId || !input.message) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'userId and message are required' }),
      };
    }
    
    // Processa
    const output = await orchestrate(input);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(output),
    };
    
  } catch (error) {
    logger.error('Lambda handler error', { error });
    
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
}

export default handler;

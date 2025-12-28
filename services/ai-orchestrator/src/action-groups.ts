/**
 * Action Groups Lambda
 * 
 * Lambda que implementa as tools/actions do Bedrock Agent
 * Chamada automaticamente pelo Agent quando precisa executar ações
 */

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createLogger } from '@n-agent/logger';
import type { TripState, TripPhase, TripStatus, Destination } from '@n-agent/core-types';
import { calculateKnowledgeScore, canAdvanceToPlanning } from '@n-agent/core-types';

// =============================================================================
// CONFIGURAÇÃO
// =============================================================================

const logger = createLogger('action-groups');

const TABLE_NAME = process.env.DYNAMODB_TABLE!;
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient({ region: AWS_REGION }));

// =============================================================================
// TIPOS BEDROCK ACTION GROUP
// =============================================================================

interface BedrockActionEvent {
  messageVersion: string;
  agent: {
    name: string;
    id: string;
    alias: string;
    version: string;
  };
  inputText: string;
  sessionId: string;
  actionGroup: string;
  apiPath: string;
  httpMethod: string;
  parameters?: Array<{
    name: string;
    type: string;
    value: string;
  }>;
  requestBody?: {
    content: {
      'application/json': {
        properties: Array<{
          name: string;
          type: string;
          value: string;
        }>;
      };
    };
  };
}

interface BedrockActionResponse {
  messageVersion: string;
  response: {
    actionGroup: string;
    apiPath: string;
    httpMethod: string;
    httpStatusCode: number;
    responseBody: {
      'application/json': {
        body: string;
      };
    };
  };
}

// =============================================================================
// FUNÇÕES AUXILIARES
// =============================================================================

function generateId(prefix: string): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 8);
  return `${prefix}_${timestamp}${random}`;
}

function getParameter(event: BedrockActionEvent, name: string): string | undefined {
  return event.parameters?.find(p => p.name === name)?.value;
}

function getBodyProperty(event: BedrockActionEvent, name: string): string | undefined {
  return event.requestBody?.content?.['application/json']?.properties?.find(p => p.name === name)?.value;
}

function createResponse(event: BedrockActionEvent, statusCode: number, body: unknown): BedrockActionResponse {
  return {
    messageVersion: '1.0',
    response: {
      actionGroup: event.actionGroup,
      apiPath: event.apiPath,
      httpMethod: event.httpMethod,
      httpStatusCode: statusCode,
      responseBody: {
        'application/json': {
          body: JSON.stringify(body),
        },
      },
    },
  };
}

// =============================================================================
// ACTION: GET TRIP CONTEXT
// =============================================================================

async function getTripContext(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  const userId = getParameter(event, 'userId');
  const tripId = getParameter(event, 'tripId');

  logger.info('getTripContext called', { userId, tripId });

  if (!userId) {
    return createResponse(event, 400, { error: 'userId is required' });
  }

  try {
    let trip: TripState | null = null;

    if (tripId) {
      // Busca trip específica
      const result = await ddbClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
      }));
      trip = result.Item as TripState | null;
    } else {
      // Busca trip ativa do usuário
      const activeResult = await ddbClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `USER#${userId}`, SK: 'ACTIVE_TRIP' },
      }));

      if (activeResult.Item?.tripId) {
        const tripResult = await ddbClient.send(new GetCommand({
          TableName: TABLE_NAME,
          Key: { PK: `TRIP#${activeResult.Item.tripId}`, SK: 'METADATA' },
        }));
        trip = tripResult.Item as TripState | null;
      }
    }

    if (!trip) {
      return createResponse(event, 200, {
        tripId: null,
        phase: 'KNOWLEDGE',
        status: 'NEW_USER',
        knowledgeScore: 0,
        destinations: [],
        dates: {},
        travelers: {},
        budget: {},
        preferences: {},
        pendingQuestions: [
          'Para onde você quer viajar?',
          'Quando pretende ir?',
          'Quantas pessoas vão?',
        ],
        summary: 'Usuário novo, sem viagens em planejamento. Inicie coletando informações básicas.',
      });
    }

    // Monta resumo textual
    const summaryParts: string[] = [];
    if (trip.destinations.length > 0) {
      summaryParts.push(`Destino: ${trip.destinations.map((d: { name: string }) => d.name).join(', ')}`);
    }
    if (trip.dates.startDate) {
      summaryParts.push(`Data: ${trip.dates.startDate}${trip.dates.endDate ? ` a ${trip.dates.endDate}` : ''}`);
    }
    if (trip.travelers.count > 0) {
      summaryParts.push(`Viajantes: ${trip.travelers.count}`);
    }
    if (trip.budget.totalAmount) {
      summaryParts.push(`Orçamento: ${trip.budget.currency} ${trip.budget.totalAmount}`);
    }

    const pendingQuestions = getPendingQuestions(trip);

    return createResponse(event, 200, {
      tripId: trip.tripId,
      phase: trip.currentPhase,
      status: trip.status,
      knowledgeScore: trip.knowledgeScore,
      destinations: trip.destinations,
      dates: trip.dates,
      travelers: trip.travelers,
      budget: trip.budget,
      preferences: trip.preferences,
      pendingQuestions,
      summary: summaryParts.length > 0
        ? `Viagem em planejamento: ${summaryParts.join('. ')}. Score: ${trip.knowledgeScore}%`
        : 'Viagem criada mas sem informações coletadas ainda.',
    });
  } catch (error) {
    logger.error('Error in getTripContext', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

function getPendingQuestions(trip: TripState): string[] {
  const questions: string[] = [];

  if (trip.destinations.length === 0) {
    questions.push('Para onde você quer viajar?');
  }
  if (!trip.dates.startDate && !trip.dates.durationDays) {
    questions.push('Quando pretende ir? Por quantos dias?');
  }
  if (trip.travelers.count === 0) {
    questions.push('Quantas pessoas vão nessa viagem?');
  }
  if (!trip.budget.totalAmount && !trip.budget.perPersonAmount) {
    questions.push('Qual é o orçamento previsto?');
  }
  if (trip.preferences.style.length === 0) {
    questions.push('O que você mais quer fazer na viagem? (relaxar, aventura, cultura?)');
  }

  return questions;
}

// =============================================================================
// ACTION: SAVE TRIP INFO
// =============================================================================

async function saveTripInfo(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  const userId = getBodyProperty(event, 'userId');
  let tripId = getBodyProperty(event, 'tripId');
  const field = getBodyProperty(event, 'field');
  const valueStr = getBodyProperty(event, 'value');
  // const confidence = parseFloat(getBodyProperty(event, 'confidence') || '0.8');

  logger.info('saveTripInfo called', { userId, tripId, field, value: valueStr });

  if (!userId || !field || valueStr === undefined) {
    return createResponse(event, 400, { error: 'userId, field, and value are required' });
  }

  try {
    // Parse value baseado no tipo esperado
    let value: unknown;
    try {
      value = JSON.parse(valueStr);
    } catch {
      value = valueStr;
    }

    // Se não tem tripId, busca ou cria
    if (!tripId) {
      const activeResult = await ddbClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `USER#${userId}`, SK: 'ACTIVE_TRIP' },
      }));

      if (activeResult.Item?.tripId) {
        tripId = activeResult.Item.tripId;
      } else {
        // Cria nova trip
        tripId = generateId('trip');
        const newTrip = createEmptyTrip(tripId, userId);

        await ddbClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `TRIP#${tripId}`,
            SK: 'METADATA',
            ...newTrip,
          },
        }));

        // Marca como trip ativa
        await ddbClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: 'ACTIVE_TRIP',
            tripId,
            updatedAt: new Date().toISOString(),
          },
        }));
      }
    }

    // Atualiza o campo específico
    await updateTripField(tripId!, field!, value);

    // Recalcula knowledge score
    const tripResult = await ddbClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
    }));

    const trip = tripResult.Item as TripState;
    const newScore = calculateKnowledgeScore(trip);

    await ddbClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
      UpdateExpression: 'SET knowledgeScore = :score, updatedAt = :now',
      ExpressionAttributeValues: {
        ':score': newScore,
        ':now': new Date().toISOString(),
      },
    }));

    const pendingQuestions = getPendingQuestions(trip);
    const nextQuestion = pendingQuestions.length > 0 ? pendingQuestions[0] : null;

    return createResponse(event, 200, {
      success: true,
      tripId,
      updatedField: field,
      newKnowledgeScore: newScore,
      canAdvanceToPlanning: canAdvanceToPlanning(trip),
      nextSuggestedQuestion: nextQuestion,
    });
  } catch (error) {
    logger.error('Error in saveTripInfo', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

function createEmptyTrip(tripId: string, ownerId: string): TripState {
  const now = new Date().toISOString();
  return {
    tripId,
    ownerId,
    status: 'DRAFT' as TripStatus,
    currentPhase: 'KNOWLEDGE' as TripPhase,
    createdAt: now,
    updatedAt: now,
    destinations: [],
    dates: {
      isFlexible: true,
    },
    travelers: {
      count: 0,
      adults: 0,
      children: 0,
      infants: 0,
      travelers: [],
    },
    budget: {
      currency: 'BRL',
      flexibility: 'moderate',
      includesFlights: false,
      includesAccommodation: false,
    },
    preferences: {
      style: [],
      accommodation: [],
      interests: [],
      mustSee: [],
      mustAvoid: [],
      pacePreference: 'moderate',
      earlyBird: false,
      foodPriority: 'medium',
      shoppingPriority: 'low',
    },
    knowledgeScore: 0,
    collectedFields: [],
    pendingQuestions: [],
    lastInteraction: now,
    interactionCount: 0,
  };
}

async function updateTripField(tripId: string, field: string, value: unknown): Promise<void> {
  let updateExpression: string;
  let expressionValues: Record<string, unknown>;

  const now = new Date().toISOString();

  switch (field) {
    case 'destination': {
      const destination: Destination = {
        id: generateId('dest'),
        name: value as string,
        isPrimary: true,
        priority: 1,
      };
      updateExpression = 'SET destinations = list_append(if_not_exists(destinations, :empty), :dest), updatedAt = :now';
      expressionValues = {
        ':dest': [destination],
        ':empty': [],
        ':now': now,
      };
      break;
    }

    case 'startDate':
      updateExpression = 'SET dates.startDate = :val, updatedAt = :now';
      expressionValues = { ':val': value, ':now': now };
      break;

    case 'endDate':
      updateExpression = 'SET dates.endDate = :val, updatedAt = :now';
      expressionValues = { ':val': value, ':now': now };
      break;

    case 'durationDays':
      updateExpression = 'SET dates.durationDays = :val, updatedAt = :now';
      expressionValues = { ':val': parseInt(value as string), ':now': now };
      break;

    case 'travelersCount':
      updateExpression = 'SET travelers.#count = :val, updatedAt = :now';
      expressionValues = { ':val': parseInt(value as string), ':now': now };
      break;

    case 'adultsCount':
      updateExpression = 'SET travelers.adults = :val, updatedAt = :now';
      expressionValues = { ':val': parseInt(value as string), ':now': now };
      break;

    case 'childrenCount':
      updateExpression = 'SET travelers.children = :val, updatedAt = :now';
      expressionValues = { ':val': parseInt(value as string), ':now': now };
      break;

    case 'totalBudget':
      updateExpression = 'SET budget.totalAmount = :val, updatedAt = :now';
      expressionValues = { ':val': parseFloat(value as string), ':now': now };
      break;

    case 'perPersonBudget':
      updateExpression = 'SET budget.perPersonAmount = :val, updatedAt = :now';
      expressionValues = { ':val': parseFloat(value as string), ':now': now };
      break;

    case 'tripStyle':
      updateExpression = 'SET preferences.style = list_append(if_not_exists(preferences.style, :empty), :val), updatedAt = :now';
      expressionValues = {
        ':val': Array.isArray(value) ? value : [value],
        ':empty': [],
        ':now': now,
      };
      break;

    case 'interests':
      updateExpression = 'SET preferences.interests = list_append(if_not_exists(preferences.interests, :empty), :val), updatedAt = :now';
      expressionValues = {
        ':val': Array.isArray(value) ? value : [value],
        ':empty': [],
        ':now': now,
      };
      break;

    case 'accommodationType':
      updateExpression = 'SET preferences.accommodation = list_append(if_not_exists(preferences.accommodation, :empty), :val), updatedAt = :now';
      expressionValues = {
        ':val': Array.isArray(value) ? value : [value],
        ':empty': [],
        ':now': now,
      };
      break;

    case 'foodRestrictions':
      updateExpression = 'SET preferences.foodRestrictions = :val, updatedAt = :now';
      expressionValues = {
        ':val': Array.isArray(value) ? value : [value],
        ':now': now,
      };
      break;

    case 'tripName':
      updateExpression = 'SET #name = :val, updatedAt = :now';
      expressionValues = { ':val': value, ':now': now };
      break;

    default:
      logger.warn('Unknown field', { field });
      return;
  }

  const expressionNames: Record<string, string> = {};
  if (field === 'travelersCount') {
    expressionNames['#count'] = 'count';
  }
  if (field === 'tripName') {
    expressionNames['#name'] = 'name';
  }

  await ddbClient.send(new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
    UpdateExpression: updateExpression,
    ExpressionAttributeValues: expressionValues,
    ...(Object.keys(expressionNames).length > 0 && { ExpressionAttributeNames: expressionNames }),
  }));
}

// =============================================================================
// ACTION: CREATE TRIP
// =============================================================================

async function createTrip(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  const userId = getBodyProperty(event, 'userId');
  const name = getBodyProperty(event, 'name');
  const initialDestination = getBodyProperty(event, 'initialDestination');

  logger.info('createTrip called', { userId, name });

  if (!userId) {
    return createResponse(event, 400, { error: 'userId is required' });
  }

  try {
    const tripId = generateId('trip');
    const trip = createEmptyTrip(tripId, userId);

    if (name) {
      trip.name = name;
    }

    if (initialDestination) {
      trip.destinations.push({
        id: generateId('dest'),
        name: initialDestination,
        isPrimary: true,
        priority: 1,
      });
      trip.knowledgeScore = calculateKnowledgeScore(trip);
    }

    await ddbClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `TRIP#${tripId}`,
        SK: 'METADATA',
        ...trip,
      },
    }));

    // Marca como trip ativa
    await ddbClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `USER#${userId}`,
        SK: 'ACTIVE_TRIP',
        tripId,
        updatedAt: new Date().toISOString(),
      },
    }));

    return createResponse(event, 201, {
      tripId,
      status: trip.status,
      phase: trip.currentPhase,
      createdAt: trip.createdAt,
    });
  } catch (error) {
    logger.error('Error in createTrip', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

// =============================================================================
// ACTION: UPDATE TRIP PHASE
// =============================================================================

async function updateTripPhase(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  const tripId = getBodyProperty(event, 'tripId');
  const newPhase = getBodyProperty(event, 'newPhase') as TripPhase;

  logger.info('updateTripPhase called', { tripId, newPhase });

  if (!tripId || !newPhase) {
    return createResponse(event, 400, { error: 'tripId and newPhase are required' });
  }

  try {
    // Busca trip atual
    const result = await ddbClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
    }));

    if (!result.Item) {
      return createResponse(event, 404, { error: 'Trip not found' });
    }

    const trip = result.Item as TripState;
    const previousPhase = trip.currentPhase;

    // Valida transição
    if (newPhase === 'PLANNING' && !canAdvanceToPlanning(trip)) {
      return createResponse(event, 400, {
        error: 'Cannot advance to PLANNING phase',
        message: 'Informações insuficientes. Knowledge Score mínimo: 60%',
        currentScore: trip.knowledgeScore,
      });
    }

    // Atualiza fase
    await ddbClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TRIP#${tripId}`, SK: 'METADATA' },
      UpdateExpression: 'SET currentPhase = :phase, updatedAt = :now',
      ExpressionAttributeValues: {
        ':phase': newPhase,
        ':now': new Date().toISOString(),
      },
    }));

    return createResponse(event, 200, {
      success: true,
      tripId,
      previousPhase,
      currentPhase: newPhase,
      message: `Viagem avançou de ${previousPhase} para ${newPhase}`,
    });
  } catch (error) {
    logger.error('Error in updateTripPhase', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

// =============================================================================
// ACTION: GET USER PROFILE
// =============================================================================

async function getUserProfile(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  const userId = getParameter(event, 'userId');

  logger.info('getUserProfile called', { userId });

  if (!userId) {
    return createResponse(event, 400, { error: 'userId is required' });
  }

  try {
    const result = await ddbClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `USER#${userId}`, SK: 'PROFILE' },
    }));

    if (!result.Item) {
      return createResponse(event, 200, {
        userId,
        name: null,
        defaultPreferences: {
          currency: 'BRL',
          language: 'pt-BR',
          foodRestrictions: [],
          accessibilityNeeds: [],
          favoriteStyles: [],
        },
        pastTripsCount: 0,
        lastTripDestination: null,
      });
    }

    return createResponse(event, 200, result.Item);
  } catch (error) {
    logger.error('Error in getUserProfile', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

// =============================================================================
// HANDLER PRINCIPAL - ROUTER
// =============================================================================

export async function handler(event: BedrockActionEvent): Promise<BedrockActionResponse> {
  logger.info('Action Group invoked', {
    actionGroup: event.actionGroup,
    apiPath: event.apiPath,
    httpMethod: event.httpMethod,
  });

  const path = event.apiPath;
  const method = event.httpMethod;

  try {
    // Route para a action correta
    if (path === '/get-trip-context' && method === 'GET') {
      return await getTripContext(event);
    }

    if (path === '/save-trip-info' && method === 'POST') {
      return await saveTripInfo(event);
    }

    if (path === '/create-trip' && method === 'POST') {
      return await createTrip(event);
    }

    if (path === '/update-trip-phase' && method === 'POST') {
      return await updateTripPhase(event);
    }

    if (path === '/get-user-profile' && method === 'GET') {
      return await getUserProfile(event);
    }

    // Placeholders para actions futuras
    if (path === '/search-weather' || path === '/search-places') {
      return createResponse(event, 501, {
        error: 'Not implemented yet',
        message: 'Esta funcionalidade será implementada na próxima fase',
      });
    }

    // Action não encontrada
    logger.warn('Unknown action', { path, method });
    return createResponse(event, 404, { error: `Unknown action: ${method} ${path}` });

  } catch (error) {
    logger.error('Handler error', { error });
    return createResponse(event, 500, { error: 'Internal server error' });
  }
}

export default handler;

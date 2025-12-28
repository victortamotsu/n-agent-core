/**
 * Action Groups Lambda Handler
 * 
 * Lambda invocada pelo Bedrock Agent para executar ações específicas
 * Implementa as tools definidas em action-groups.json
 */

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createLogger } from '@n-agent/logger';
import type { TripState } from '@n-agent/core-types';

const logger = createLogger('action-groups');

const dynamoClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE || 'n-agent-core-prod';

// =============================================================================
// TYPES
// =============================================================================

interface BedrockAgentEvent {
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
      [contentType: string]: {
        properties: Array<{
          name: string;
          type: string;
          value: string;
        }>;
      };
    };
  };
}

interface BedrockAgentResponse {
  messageVersion: string;
  response: {
    actionGroup: string;
    apiPath: string;
    httpMethod: string;
    httpStatusCode: number;
    responseBody: {
      [contentType: string]: {
        body: string;
      };
    };
  };
  sessionAttributes?: Record<string, string>;
  promptSessionAttributes?: Record<string, string>;
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

function getParameter(event: BedrockAgentEvent, name: string): string | undefined {
  return event.parameters?.find(p => p.name === name)?.value;
}

function getRequestBodyProperty(event: BedrockAgentEvent, name: string): string | undefined {
  const content = event.requestBody?.content?.['application/json'];
  return content?.properties?.find(p => p.name === name)?.value;
}

function createResponse(
  event: BedrockAgentEvent,
  statusCode: number,
  body: any
): BedrockAgentResponse {
  return {
    messageVersion: '1.0',
    response: {
      actionGroup: event.actionGroup,
      apiPath: event.apiPath,
      httpMethod: event.httpMethod,
      httpStatusCode: statusCode,
      responseBody: {
        'application/json': {
          body: JSON.stringify(body)
        }
      }
    }
  };
}

// =============================================================================
// ACTION HANDLERS
// =============================================================================

async function getTripContext(event: BedrockAgentEvent): Promise<BedrockAgentResponse> {
  const userId = getParameter(event, 'userId');
  const tripId = getParameter(event, 'tripId');

  if (!userId) {
    return createResponse(event, 400, { error: 'userId is required' });
  }

  try {
    let trip: TripState | null = null;

    if (tripId) {
      // Buscar trip específica
      const result = await docClient.send(new GetCommand({
        TableName: DYNAMODB_TABLE,
        Key: { PK: `USER#${userId}`, SK: `TRIP#${tripId}` }
      }));
      trip = result.Item as TripState | undefined || null;
    } else {
      // Buscar trip ativa mais recente
      const result = await docClient.send(new QueryCommand({
        TableName: DYNAMODB_TABLE,
        KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
        ExpressionAttributeValues: {
          ':pk': `USER#${userId}`,
          ':sk': 'TRIP#'
        },
        ScanIndexForward: false,
        Limit: 1
      }));
      trip = result.Items?.[0] as TripState | undefined || null;
    }

    if (!trip) {
      return createResponse(event, 404, { 
        message: 'No trip found for this user',
        userId,
        tripId
      });
    }

    return createResponse(event, 200, {
      trip,
      message: 'Trip context retrieved successfully'
    });

  } catch (error) {
    logger.error('Error getting trip context', { error, userId, tripId });
    return createResponse(event, 500, { 
      error: 'Failed to retrieve trip context',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

async function saveTripInfo(event: BedrockAgentEvent): Promise<BedrockAgentResponse> {
  const userId = getRequestBodyProperty(event, 'userId');
  const tripId = getRequestBodyProperty(event, 'tripId');
  const infoType = getRequestBodyProperty(event, 'infoType');
  const infoValue = getRequestBodyProperty(event, 'infoValue');

  if (!userId || !infoType || !infoValue) {
    return createResponse(event, 400, { 
      error: 'userId, infoType, and infoValue are required' 
    });
  }

  try {
    const pk = `USER#${userId}`;
    const sk = tripId ? `TRIP#${tripId}` : `TRIP#${Date.now()}`;

    // Mapeamento de infoType para campos do TripState
    const fieldMapping: Record<string, string> = {
      'destination': 'destinations',
      'startDate': 'startDate',
      'endDate': 'endDate',
      'budget': 'budget',
      'travelers': 'travelers',
      'preferences': 'preferences',
      'purpose': 'travelPurpose'
    };

    const field = fieldMapping[infoType] || infoType;

    await docClient.send(new UpdateCommand({
      TableName: DYNAMODB_TABLE,
      Key: { PK: pk, SK: sk },
      UpdateExpression: `SET #field = :value, updatedAt = :now`,
      ExpressionAttributeNames: {
        '#field': field
      },
      ExpressionAttributeValues: {
        ':value': infoValue,
        ':now': new Date().toISOString()
      }
    }));

    return createResponse(event, 200, {
      message: 'Trip information saved successfully',
      userId,
      tripId: sk.replace('TRIP#', ''),
      infoType,
      field
    });

  } catch (error) {
    logger.error('Error saving trip info', { error, userId, tripId, infoType });
    return createResponse(event, 500, { 
      error: 'Failed to save trip information',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

async function createTrip(event: BedrockAgentEvent): Promise<BedrockAgentResponse> {
  const userId = getRequestBodyProperty(event, 'userId');
  const destination = getRequestBodyProperty(event, 'destination');
  const purpose = getRequestBodyProperty(event, 'purpose');

  if (!userId) {
    return createResponse(event, 400, { error: 'userId is required' });
  }

  try {
    const tripId = Date.now().toString();
    const now = new Date().toISOString();

    const trip: TripState = {
      PK: `USER#${userId}`,
      SK: `TRIP#${tripId}`,
      tripId,
      userId,
      status: 'planning',
      phase: 'knowledge',
      destinations: destination ? [destination] : [],
      travelPurpose: purpose,
      createdAt: now,
      updatedAt: now
    };

    await docClient.send(new PutCommand({
      TableName: DYNAMODB_TABLE,
      Item: trip
    }));

    return createResponse(event, 201, {
      message: 'Trip created successfully',
      trip
    });

  } catch (error) {
    logger.error('Error creating trip', { error, userId });
    return createResponse(event, 500, { 
      error: 'Failed to create trip',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

async function updateTripPhase(event: BedrockAgentEvent): Promise<BedrockAgentResponse> {
  const userId = getRequestBodyProperty(event, 'userId');
  const tripId = getRequestBodyProperty(event, 'tripId');
  const newPhase = getRequestBodyProperty(event, 'newPhase');

  if (!userId || !tripId || !newPhase) {
    return createResponse(event, 400, { 
      error: 'userId, tripId, and newPhase are required' 
    });
  }

  try {
    await docClient.send(new UpdateCommand({
      TableName: DYNAMODB_TABLE,
      Key: { 
        PK: `USER#${userId}`, 
        SK: `TRIP#${tripId}` 
      },
      UpdateExpression: 'SET phase = :phase, updatedAt = :now',
      ExpressionAttributeValues: {
        ':phase': newPhase,
        ':now': new Date().toISOString()
      }
    }));

    return createResponse(event, 200, {
      message: 'Trip phase updated successfully',
      userId,
      tripId,
      newPhase
    });

  } catch (error) {
    logger.error('Error updating trip phase', { error, userId, tripId, newPhase });
    return createResponse(event, 500, { 
      error: 'Failed to update trip phase',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

// =============================================================================
// MAIN HANDLER
// =============================================================================

export const handler = async (event: BedrockAgentEvent): Promise<BedrockAgentResponse> => {
  logger.info('Action Groups Lambda invoked', {
    apiPath: event.apiPath,
    httpMethod: event.httpMethod,
    actionGroup: event.actionGroup,
    sessionId: event.sessionId
  });

  try {
    // Router baseado no apiPath
    switch (event.apiPath) {
      case '/get-trip-context':
        return await getTripContext(event);
      
      case '/save-trip-info':
        return await saveTripInfo(event);
      
      case '/create-trip':
        return await createTrip(event);
      
      case '/update-trip-phase':
        return await updateTripPhase(event);
      
      default:
        logger.warn('Unknown API path', { apiPath: event.apiPath });
        return createResponse(event, 404, {
          error: 'Not Found',
          message: `API path ${event.apiPath} not implemented`
        });
    }

  } catch (error) {
    logger.error('Unhandled error in action groups handler', { error });
    return createResponse(event, 500, {
      error: 'Internal Server Error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
};

import { ITrip } from '@n-agent/core-types';
import { createLogger } from '@n-agent/logger';
import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';

const logger = createLogger('trip-planner');

// Lambda Handler for API Gateway
export async function handler(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  logger.info('Received request', { 
    method: event.requestContext.http.method,
    path: event.rawPath 
  });

  try {
    const method = event.requestContext.http.method;
    const path = event.rawPath;

    // Health check
    if (path === '/health') {
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'healthy',
          service: 'trip-planner',
          timestamp: new Date().toISOString(),
          environment: process.env.ENVIRONMENT || 'unknown'
        })
      };
    }

    // Create trip
    if (method === 'POST' && path.startsWith('/api/v1/trips')) {
      const body = event.body ? JSON.parse(event.body) : {};
      const trip = await createTrip(body);
      
      return {
        statusCode: 201,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(trip)
      };
    }

    // Get trip
    if (method === 'GET' && path.match(/\/api\/v1\/trips\/[^/]+$/)) {
      const tripId = path.split('/').pop();
      if (!tripId) {
        return {
          statusCode: 400,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ error: 'Trip ID is required' })
        };
      }

      const trip = await getTrip(tripId);
      
      if (!trip) {
        return {
          statusCode: 404,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ error: 'Trip not found' })
        };
      }

      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(trip)
      };
    }

    // Route not found
    return {
      statusCode: 404,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        error: 'Route not found',
        path,
        method
      })
    };

  } catch (error) {
    logger.error('Handler error', { error });
    
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

export async function createTrip(input: Partial<ITrip>): Promise<ITrip> {
  logger.info('Creating trip', { input });

  // TODO: Persist to DynamoDB
  const trip: ITrip = {
    id: `TRIP-${Date.now()}`,
    userId: input.userId || '',
    name: input.name || 'Nova Viagem',
    phase: 'KNOWLEDGE',
    status: 'DRAFT',
    destinations: input.destinations || [],
    currency: input.currency || 'BRL',
    travelers: input.travelers || 1,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  logger.info('Trip created', { tripId: trip.id });
  return trip;
}

export async function getTrip(tripId: string): Promise<ITrip | null> {
  logger.info('Getting trip', { tripId });
  // TODO: Fetch from DynamoDB
  return null;
}

export async function updateTrip(tripId: string, updates: Partial<ITrip>): Promise<ITrip> {
  logger.info('Updating trip', { tripId, updates });
  // TODO: Update in DynamoDB
  throw new Error('Not implemented');
}

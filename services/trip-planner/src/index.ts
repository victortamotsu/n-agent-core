import { ITrip } from '@n-agent/core-types';
import { createLogger } from '@n-agent/logger';

const logger = createLogger('trip-planner');

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

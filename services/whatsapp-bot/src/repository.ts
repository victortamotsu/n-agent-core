import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { 
  DynamoDBDocumentClient, 
  PutCommand, 
  QueryCommand,
  QueryCommandInput 
} from '@aws-sdk/lib-dynamodb';
import { createLogger } from '@n-agent/logger';
import { NormalizedMessage, ChatMessageEntity } from './types.js';

const logger = createLogger('chat-repository');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'n-agent-core-prod';

/**
 * Save a message to DynamoDB
 */
export async function saveMessage(
  message: NormalizedMessage,
  direction: 'inbound' | 'outbound',
  tripId?: string
): Promise<void> {
  // Use phone number as partition key if no trip associated yet
  const pk = tripId ? `TRIP#${tripId}` : `USER#${message.from}`;
  const timestamp = message.timestamp.toISOString();
  const sk = `MSG#${timestamp}#${message.messageId}`;

  const entity: ChatMessageEntity = {
    PK: pk,
    SK: sk,
    messageId: message.messageId,
    from: message.from,
    fromName: message.fromName,
    direction,
    type: message.type,
    content: JSON.stringify(message.content),
    metadata: {
      phoneNumberId: message.phoneNumberId,
      isForwarded: message.isForwarded,
      replyTo: message.replyTo,
    },
    createdAt: timestamp,
    // TTL: 90 days for messages without trip association
    ...(!tripId && { TTL: Math.floor(Date.now() / 1000) + 90 * 24 * 60 * 60 }),
  };

  try {
    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: entity,
    }));

    logger.info('Message saved', { pk, sk, direction });
  } catch (error) {
    logger.error('Failed to save message', { error, pk, sk });
    throw error;
  }
}

/**
 * Save an outbound message (bot response)
 */
export async function saveOutboundMessage(
  _to: string,
  messageId: string,
  text: string,
  tripId?: string
): Promise<void> {
  const message: NormalizedMessage = {
    messageId,
    from: 'bot',
    fromName: 'n-agent',
    timestamp: new Date(),
    type: 'text',
    content: { text },
    isForwarded: false,
    phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID || '',
  };

  await saveMessage(message, 'outbound', tripId);
}

/**
 * Get recent messages for a user or trip
 */
export async function getRecentMessages(
  identifier: string,
  limit: number = 20
): Promise<ChatMessageEntity[]> {
  // Determine if it's a trip ID or phone number
  const pk = identifier.startsWith('TRIP#') || identifier.startsWith('USER#') 
    ? identifier 
    : `USER#${identifier}`;

  const params: QueryCommandInput = {
    TableName: TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
    ExpressionAttributeValues: {
      ':pk': pk,
      ':prefix': 'MSG#',
    },
    ScanIndexForward: false, // Most recent first
    Limit: limit,
  };

  try {
    const result = await docClient.send(new QueryCommand(params));
    return (result.Items || []) as ChatMessageEntity[];
  } catch (error) {
    logger.error('Failed to get messages', { error, pk });
    throw error;
  }
}

/**
 * Find user's active trip (if any)
 */
export async function findUserTrip(phoneNumber: string): Promise<string | null> {
  // Check GSI1 for user's trips
  const params: QueryCommandInput = {
    TableName: TABLE_NAME,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :pk AND begins_with(GSI1SK, :prefix)',
    ExpressionAttributeValues: {
      ':pk': `USER#${phoneNumber}`,
      ':prefix': 'TRIP#',
    },
    Limit: 1,
  };

  try {
    const result = await docClient.send(new QueryCommand(params));
    if (result.Items && result.Items.length > 0) {
      // Extract trip ID from GSI1SK
      const gsi1sk = result.Items[0].GSI1SK as string;
      return gsi1sk.replace('TRIP#', '');
    }
    return null;
  } catch (error) {
    logger.error('Failed to find user trip', { error, phoneNumber });
    return null;
  }
}

/**
 * Get or create user record
 */
export async function getOrCreateUser(phoneNumber: string, name: string): Promise<void> {
  const pk = `USER#${phoneNumber}`;
  const sk = 'PROFILE';

  try {
    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: pk,
        SK: sk,
        phoneNumber,
        name,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
      ConditionExpression: 'attribute_not_exists(PK)',
    }));
    logger.info('New user created', { phoneNumber, name });
  } catch (error: unknown) {
    // User already exists, that's fine
    if ((error as { name?: string }).name === 'ConditionalCheckFailedException') {
      logger.debug('User already exists', { phoneNumber });
    } else {
      throw error;
    }
  }
}

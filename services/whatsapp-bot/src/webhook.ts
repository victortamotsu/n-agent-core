import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { createLogger } from '@n-agent/logger';
import { WhatsAppWebhookPayload } from './types.js';
import { normalizeWebhookPayload, getMessageText } from './normalizer.js';
import { createWhatsAppClient } from './client.js';
import { handleMessage, handleInteraction } from './bot-handler.js';
import { saveMessage, saveOutboundMessage, getOrCreateUser } from './repository.js';

const logger = createLogger('whatsapp-webhook');

export async function handler(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  logger.info('WhatsApp webhook received', { 
    method: event.requestContext.http.method,
    path: event.rawPath 
  });

  const method = event.requestContext.http.method;

  // Webhook verification (GET request from Meta)
  if (method === 'GET') {
    return handleVerification(event);
  }

  // Handle incoming messages (POST)
  if (method === 'POST') {
    return handleIncomingMessage(event);
  }

  return {
    statusCode: 405,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: 'Method not allowed' }),
  };
}

/**
 * Handle webhook verification from Meta
 */
function handleVerification(event: APIGatewayProxyEventV2): APIGatewayProxyResultV2 {
  const params = event.queryStringParameters || {};
  const mode = params['hub.mode'];
  const token = params['hub.verify_token'];
  const challenge = params['hub.challenge'];

  logger.info('Webhook verification attempt', { mode, tokenProvided: !!token });

  if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
    logger.info('Webhook verified successfully');
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'text/plain' },
      body: challenge || '',
    };
  }

  logger.warn('Webhook verification failed', { mode, tokenMatch: token === process.env.WEBHOOK_VERIFY_TOKEN });
  return {
    statusCode: 403,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: 'Forbidden' }),
  };
}

/**
 * Handle incoming WhatsApp messages
 */
async function handleIncomingMessage(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  try {
    // Parse and validate payload
    const payload: WhatsAppWebhookPayload = event.body ? JSON.parse(event.body) : {};
    
    // Always respond 200 immediately to Meta (required within 5 seconds)
    // Process messages asynchronously
    
    // Check if this is a status update (not a message)
    const hasMessages = payload.entry?.some(entry => 
      entry.changes?.some(change => 
        change.value?.messages && change.value.messages.length > 0
      )
    );

    if (!hasMessages) {
      logger.debug('No messages in payload (likely status update)');
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'ok' }),
      };
    }

    // Normalize messages
    const messages = normalizeWebhookPayload(payload);
    
    if (messages.length === 0) {
      logger.debug('No processable messages after normalization');
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'ok' }),
      };
    }

    // Process each message
    for (const message of messages) {
      try {
        await processMessage(message);
      } catch (error) {
        logger.error('Error processing individual message', { 
          error, 
          messageId: message.messageId,
          from: message.from 
        });
        // Continue processing other messages
      }
    }

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        status: 'ok',
        processed: messages.length,
        timestamp: new Date().toISOString()
      }),
    };
  } catch (error) {
    logger.error('Error handling incoming message', { error });
    
    // Still return 200 to prevent Meta from retrying
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        status: 'error',
        message: 'Internal processing error'
      }),
    };
  }
}

/**
 * Process a single normalized message
 */
async function processMessage(message: import('./types.js').NormalizedMessage): Promise<void> {
  logger.info('Processing message', {
    messageId: message.messageId,
    from: message.from,
    fromName: message.fromName,
    type: message.type,
    content: message.type === 'text' ? getMessageText(message).substring(0, 100) : `[${message.type}]`
  });

  // Create or get user record
  await getOrCreateUser(message.from, message.fromName);

  // Save inbound message to DynamoDB
  await saveMessage(message, 'inbound');

  // Create WhatsApp client for responses
  const client = createWhatsAppClient(message.phoneNumberId);

  // Mark message as read
  try {
    await client.markAsRead(message.messageId);
  } catch (error) {
    logger.warn('Failed to mark message as read', { error });
  }

  // Handle the message based on type
  let responseMessageId: string;
  
  if (message.type === 'interactive' || message.type === 'button') {
    responseMessageId = await handleInteraction(message, client);
  } else {
    responseMessageId = await handleMessage(message, client);
  }

  // Save outbound message
  if (responseMessageId) {
    await saveOutboundMessage(
      message.from,
      responseMessageId,
      '[Response sent]' // We could store the actual response text here
    );
  }

  logger.info('Message processed successfully', {
    messageId: message.messageId,
    responseMessageId
  });
}

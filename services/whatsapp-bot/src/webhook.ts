import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { createLogger } from '@n-agent/logger';

const logger = createLogger('whatsapp-bot');

export async function handler(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  logger.info('WhatsApp webhook received', { 
    method: event.requestContext.http.method,
    path: event.rawPath 
  });

  const method = event.requestContext.http.method;

  // Webhook verification (GET request from Meta)
  if (method === 'GET') {
    const params = event.queryStringParameters || {};
    const mode = params['hub.mode'];
    const token = params['hub.verify_token'];
    const challenge = params['hub.challenge'];

    if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
      logger.info('Webhook verified');
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'text/plain' },
        body: challenge || '',
      };
    }

    return {
      statusCode: 403,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Forbidden' }),
    };
  }

  // Handle incoming messages (POST)
  if (method === 'POST') {
    try {
      const body = event.body ? JSON.parse(event.body) : {};
      logger.info('WhatsApp message received', { body });

      // TODO: Process message and send to EventBridge
      // TODO: Call Bedrock Agent

      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          message: 'Message received',
          timestamp: new Date().toISOString()
        }),
      };
    } catch (error) {
      logger.error('Error processing WhatsApp message', { error });
      return {
        statusCode: 500,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          error: 'Internal server error',
          message: error instanceof Error ? error.message : 'Unknown error'
        }),
      };
    }
  }

  return {
    statusCode: 405,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ error: 'Method not allowed' }),
  };
}

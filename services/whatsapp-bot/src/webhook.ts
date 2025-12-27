import { APIGatewayProxyHandler } from 'aws-lambda';
import { createLogger } from '@n-agent/logger';

const logger = createLogger('whatsapp-bot');

export const handler: APIGatewayProxyHandler = async (event) => {
  logger.info('WhatsApp webhook received', { body: event.body });

  // Webhook verification (GET request from Meta)
  if (event.httpMethod === 'GET') {
    const params = event.queryStringParameters || {};
    const mode = params['hub.mode'];
    const token = params['hub.verify_token'];
    const challenge = params['hub.challenge'];

    if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
      logger.info('Webhook verified');
      return {
        statusCode: 200,
        body: challenge || '',
      };
    }

    return {
      statusCode: 403,
      body: 'Forbidden',
    };
  }

  // Handle incoming messages (POST)
  if (event.httpMethod === 'POST') {
    try {
      const body = JSON.parse(event.body || '{}');
      logger.info('WhatsApp message received', { body });

      // TODO: Process message and send to EventBridge
      // TODO: Call Bedrock Agent

      return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Message received' }),
      };
    } catch (error) {
      logger.error('Error processing WhatsApp message', { error });
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Internal server error' }),
      };
    }
  }

  return {
    statusCode: 405,
    body: 'Method not allowed',
  };
};

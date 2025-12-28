// WhatsApp Bot Lambda Handler
// Entry point for the Lambda function

export { handler } from './webhook.js';

// Re-export useful types and utilities
export * from './types.js';
export { WhatsAppClient, createWhatsAppClient } from './client.js';
export { normalizeWebhookPayload, getMessageText } from './normalizer.js';
export { saveMessage, saveOutboundMessage, getRecentMessages } from './repository.js';

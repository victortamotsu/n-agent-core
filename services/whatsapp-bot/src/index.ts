// WhatsApp Bot Lambda Handler
// Entry point for the Lambda function

export { handler } from './webhook';

// Re-export useful types and utilities
export * from './types';
export { WhatsAppClient, createWhatsAppClient } from './client';
export { normalizeWebhookPayload, getMessageText } from './normalizer';
export { saveMessage, saveOutboundMessage, getRecentMessages } from './repository';

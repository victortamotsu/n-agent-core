import { createLogger } from '@n-agent/logger';
import {
  WhatsAppWebhookPayload,
  WhatsAppMessage,
  WhatsAppContact,
  NormalizedMessage,
} from './types.js';

const logger = createLogger('whatsapp-normalizer');

/**
 * Normalizes WhatsApp webhook payload into a standardized message format
 */
export function normalizeWebhookPayload(payload: WhatsAppWebhookPayload): NormalizedMessage[] {
  const messages: NormalizedMessage[] = [];

  if (payload.object !== 'whatsapp_business_account') {
    logger.warn('Received non-WhatsApp payload', { object: payload.object });
    return messages;
  }

  for (const entry of payload.entry) {
    for (const change of entry.changes) {
      if (change.field !== 'messages') continue;

      const { value } = change;
      const phoneNumberId = value.metadata.phone_number_id;
      const contacts = value.contacts || [];
      const rawMessages = value.messages || [];

      for (const msg of rawMessages) {
        const contact = contacts.find(c => c.wa_id === msg.from);
        const normalized = normalizeMessage(msg, contact, phoneNumberId);
        if (normalized) {
          messages.push(normalized);
        }
      }
    }
  }

  return messages;
}

/**
 * Normalizes a single WhatsApp message
 */
function normalizeMessage(
  msg: WhatsAppMessage,
  contact: WhatsAppContact | undefined,
  phoneNumberId: string
): NormalizedMessage | null {
  try {
    const normalized: NormalizedMessage = {
      messageId: msg.id,
      from: msg.from,
      fromName: contact?.profile?.name || 'Unknown',
      timestamp: new Date(parseInt(msg.timestamp) * 1000),
      type: msg.type,
      content: {},
      isForwarded: msg.context?.forwarded || msg.context?.frequently_forwarded || false,
      replyTo: msg.context?.id,
      phoneNumberId,
    };

    // Extract content based on message type
    switch (msg.type) {
      case 'text':
        normalized.content.text = msg.text?.body || '';
        break;

      case 'image':
        normalized.content.mediaId = msg.image?.id;
        normalized.content.mediaType = msg.image?.mime_type;
        normalized.content.caption = msg.image?.caption;
        break;

      case 'audio':
        normalized.content.mediaId = msg.audio?.id;
        normalized.content.mediaType = msg.audio?.mime_type;
        break;

      case 'document':
        normalized.content.mediaId = msg.document?.id;
        normalized.content.mediaType = msg.document?.mime_type;
        normalized.content.caption = msg.document?.filename;
        break;

      case 'video':
        normalized.content.mediaId = msg.video?.id;
        normalized.content.mediaType = msg.video?.mime_type;
        normalized.content.caption = msg.video?.caption;
        break;

      case 'location':
        normalized.content.location = {
          latitude: msg.location?.latitude || 0,
          longitude: msg.location?.longitude || 0,
          name: msg.location?.name,
          address: msg.location?.address,
        };
        break;

      case 'interactive':
        if (msg.interactive?.type === 'button_reply') {
          normalized.content.buttonId = msg.interactive.button_reply?.id;
          normalized.content.buttonTitle = msg.interactive.button_reply?.title;
        } else if (msg.interactive?.type === 'list_reply') {
          normalized.content.buttonId = msg.interactive.list_reply?.id;
          normalized.content.buttonTitle = msg.interactive.list_reply?.title;
        }
        break;

      case 'button':
        normalized.content.text = msg.button?.text;
        normalized.content.buttonId = msg.button?.payload;
        break;

      case 'sticker':
      case 'reaction':
        // Skip stickers and reactions for now
        logger.debug('Skipping unsupported message type', { type: msg.type });
        return null;

      default:
        logger.warn('Unknown message type', { type: msg.type });
        normalized.content.text = `[Tipo de mensagem não suportado: ${msg.type}]`;
    }

    return normalized;
  } catch (error) {
    logger.error('Error normalizing message', { error, messageId: msg.id });
    return null;
  }
}

/**
 * Extracts a simple text content from normalized message
 */
export function getMessageText(message: NormalizedMessage): string {
  switch (message.type) {
    case 'text':
      return message.content.text || '';
    case 'interactive':
    case 'button':
      return message.content.buttonTitle || message.content.buttonId || '';
    case 'image':
    case 'video':
    case 'document':
      return message.content.caption || `[${message.type}]`;
    case 'audio':
      return '[áudio]';
    case 'location':
      return message.content.location?.name || 
             message.content.location?.address || 
             `[localização: ${message.content.location?.latitude}, ${message.content.location?.longitude}]`;
    default:
      return `[${message.type}]`;
  }
}

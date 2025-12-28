import { createLogger } from '@n-agent/logger';
import {
  SendTextMessage,
  SendInteractiveMessage,
  SendTemplateMessage,
} from './types.js';

const logger = createLogger('whatsapp-client');

const WHATSAPP_API_VERSION = 'v21.0';
const WHATSAPP_API_URL = 'https://graph.facebook.com';

interface WhatsAppConfig {
  accessToken: string;
  phoneNumberId: string;
}

interface SendMessageResponse {
  messaging_product: string;
  contacts: { input: string; wa_id: string }[];
  messages: { id: string }[];
}

/**
 * WhatsApp Cloud API Client
 */
export class WhatsAppClient {
  private config: WhatsAppConfig;

  constructor(config: WhatsAppConfig) {
    this.config = config;
  }

  /**
   * Get the base URL for API calls
   */
  private get baseUrl(): string {
    return `${WHATSAPP_API_URL}/${WHATSAPP_API_VERSION}/${this.config.phoneNumberId}`;
  }

  /**
   * Send a request to WhatsApp API
   */
  private async sendRequest<T>(endpoint: string, body: object): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    
    logger.debug('Sending WhatsApp API request', { url, body });

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.config.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      logger.error('WhatsApp API error', { status: response.status, error });
      throw new Error(`WhatsApp API error: ${response.status} - ${JSON.stringify(error)}`);
    }

    return response.json() as Promise<T>;
  }

  /**
   * Send a text message
   */
  async sendText(options: SendTextMessage): Promise<string> {
    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: options.to,
      type: 'text',
      text: {
        preview_url: options.previewUrl || false,
        body: options.text,
      },
      ...(options.replyTo && {
        context: {
          message_id: options.replyTo,
        },
      }),
    };

    const response = await this.sendRequest<SendMessageResponse>('/messages', body);
    const messageId = response.messages[0]?.id;
    
    logger.info('Text message sent', { to: options.to, messageId });
    return messageId;
  }

  /**
   * Send an interactive message with buttons
   */
  async sendButtons(options: SendInteractiveMessage): Promise<string> {
    if (options.type !== 'button' || !options.buttons?.length) {
      throw new Error('Interactive button message requires buttons');
    }

    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: options.to,
      type: 'interactive',
      interactive: {
        type: 'button',
        ...(options.header && {
          header: options.header,
        }),
        body: {
          text: options.body,
        },
        ...(options.footer && {
          footer: {
            text: options.footer,
          },
        }),
        action: {
          buttons: options.buttons.map(btn => ({
            type: 'reply',
            reply: {
              id: btn.id,
              title: btn.title,
            },
          })),
        },
      },
    };

    const response = await this.sendRequest<SendMessageResponse>('/messages', body);
    const messageId = response.messages[0]?.id;
    
    logger.info('Button message sent', { to: options.to, messageId });
    return messageId;
  }

  /**
   * Send an interactive list message
   */
  async sendList(options: SendInteractiveMessage): Promise<string> {
    if (options.type !== 'list' || !options.sections?.length) {
      throw new Error('Interactive list message requires sections');
    }

    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: options.to,
      type: 'interactive',
      interactive: {
        type: 'list',
        ...(options.header && {
          header: options.header,
        }),
        body: {
          text: options.body,
        },
        ...(options.footer && {
          footer: {
            text: options.footer,
          },
        }),
        action: {
          button: 'Ver opções',
          sections: options.sections,
        },
      },
    };

    const response = await this.sendRequest<SendMessageResponse>('/messages', body);
    const messageId = response.messages[0]?.id;
    
    logger.info('List message sent', { to: options.to, messageId });
    return messageId;
  }

  /**
   * Send a template message
   */
  async sendTemplate(options: SendTemplateMessage): Promise<string> {
    const body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: options.to,
      type: 'template',
      template: {
        name: options.templateName,
        language: {
          code: options.language,
        },
        ...(options.components && {
          components: options.components,
        }),
      },
    };

    const response = await this.sendRequest<SendMessageResponse>('/messages', body);
    const messageId = response.messages[0]?.id;
    
    logger.info('Template message sent', { to: options.to, template: options.templateName, messageId });
    return messageId;
  }

  /**
   * Mark a message as read
   */
  async markAsRead(messageId: string): Promise<void> {
    const body = {
      messaging_product: 'whatsapp',
      status: 'read',
      message_id: messageId,
    };

    await this.sendRequest('/messages', body);
    logger.debug('Message marked as read', { messageId });
  }

  /**
   * Download media content
   */
  async getMediaUrl(mediaId: string): Promise<string> {
    const url = `${WHATSAPP_API_URL}/${WHATSAPP_API_VERSION}/${mediaId}`;
    
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${this.config.accessToken}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get media URL: ${response.status}`);
    }

    const data = await response.json() as { url: string };
    return data.url;
  }
}

/**
 * Create a WhatsApp client from environment variables
 */
export function createWhatsAppClient(phoneNumberId?: string): WhatsAppClient {
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN;
  const defaultPhoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  
  if (!accessToken) {
    throw new Error('WHATSAPP_ACCESS_TOKEN environment variable is required');
  }
  
  const effectivePhoneNumberId = phoneNumberId || defaultPhoneNumberId;
  if (!effectivePhoneNumberId) {
    throw new Error('Phone number ID is required');
  }

  return new WhatsAppClient({
    accessToken,
    phoneNumberId: effectivePhoneNumberId,
  });
}

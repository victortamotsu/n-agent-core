// WhatsApp Cloud API Types
// Reference: https://developers.facebook.com/docs/whatsapp/cloud-api/reference

export interface WhatsAppWebhookPayload {
  object: 'whatsapp_business_account';
  entry: WhatsAppEntry[];
}

export interface WhatsAppEntry {
  id: string;
  changes: WhatsAppChange[];
}

export interface WhatsAppChange {
  value: WhatsAppValue;
  field: 'messages';
}

export interface WhatsAppValue {
  messaging_product: 'whatsapp';
  metadata: WhatsAppMetadata;
  contacts?: WhatsAppContact[];
  messages?: WhatsAppMessage[];
  statuses?: WhatsAppStatus[];
  errors?: WhatsAppError[];
}

export interface WhatsAppMetadata {
  display_phone_number: string;
  phone_number_id: string;
}

export interface WhatsAppContact {
  profile: {
    name: string;
  };
  wa_id: string;
}

export interface WhatsAppMessage {
  from: string;
  id: string;
  timestamp: string;
  type: WhatsAppMessageType;
  text?: WhatsAppTextContent;
  image?: WhatsAppMediaContent;
  audio?: WhatsAppMediaContent;
  document?: WhatsAppMediaContent;
  video?: WhatsAppMediaContent;
  location?: WhatsAppLocationContent;
  contacts?: WhatsAppContactContent[];
  interactive?: WhatsAppInteractiveContent;
  button?: WhatsAppButtonContent;
  context?: WhatsAppContext;
}

export type WhatsAppMessageType = 
  | 'text' 
  | 'image' 
  | 'audio' 
  | 'document' 
  | 'video' 
  | 'location' 
  | 'contacts' 
  | 'interactive'
  | 'button'
  | 'sticker'
  | 'reaction';

export interface WhatsAppTextContent {
  body: string;
}

export interface WhatsAppMediaContent {
  id: string;
  mime_type?: string;
  sha256?: string;
  caption?: string;
  filename?: string;
}

export interface WhatsAppLocationContent {
  latitude: number;
  longitude: number;
  name?: string;
  address?: string;
}

export interface WhatsAppContactContent {
  name: {
    formatted_name: string;
    first_name?: string;
    last_name?: string;
  };
  phones?: {
    phone: string;
    type?: string;
  }[];
}

export interface WhatsAppInteractiveContent {
  type: 'button_reply' | 'list_reply';
  button_reply?: {
    id: string;
    title: string;
  };
  list_reply?: {
    id: string;
    title: string;
    description?: string;
  };
}

export interface WhatsAppButtonContent {
  text: string;
  payload: string;
}

export interface WhatsAppContext {
  from: string;
  id: string;
  forwarded?: boolean;
  frequently_forwarded?: boolean;
}

export interface WhatsAppStatus {
  id: string;
  status: 'sent' | 'delivered' | 'read' | 'failed';
  timestamp: string;
  recipient_id: string;
  errors?: WhatsAppError[];
}

export interface WhatsAppError {
  code: number;
  title: string;
  message: string;
  error_data?: {
    details: string;
  };
}

// Normalized message for internal use
export interface NormalizedMessage {
  messageId: string;
  from: string;
  fromName: string;
  timestamp: Date;
  type: WhatsAppMessageType;
  content: {
    text?: string;
    mediaId?: string;
    mediaType?: string;
    caption?: string;
    location?: {
      latitude: number;
      longitude: number;
      name?: string;
      address?: string;
    };
    buttonId?: string;
    buttonTitle?: string;
  };
  isForwarded: boolean;
  replyTo?: string;
  phoneNumberId: string;
}

// Outgoing message types
export interface SendTextMessage {
  to: string;
  text: string;
  previewUrl?: boolean;
  replyTo?: string;
}

export interface SendTemplateMessage {
  to: string;
  templateName: string;
  language: string;
  components?: TemplateComponent[];
}

export interface TemplateComponent {
  type: 'header' | 'body' | 'button';
  parameters: TemplateParameter[];
}

export interface TemplateParameter {
  type: 'text' | 'image' | 'document' | 'video';
  text?: string;
  image?: { link: string };
  document?: { link: string; filename: string };
  video?: { link: string };
}

export interface SendInteractiveMessage {
  to: string;
  type: 'button' | 'list';
  header?: {
    type: 'text' | 'image' | 'video' | 'document';
    text?: string;
  };
  body: string;
  footer?: string;
  buttons?: InteractiveButton[];
  sections?: InteractiveSection[];
}

export interface InteractiveButton {
  id: string;
  title: string;
}

export interface InteractiveSection {
  title: string;
  rows: {
    id: string;
    title: string;
    description?: string;
  }[];
}

// DynamoDB Chat Message entity
export interface ChatMessageEntity {
  PK: string;           // TRIP#{tripId} or USER#{phoneNumber}
  SK: string;           // MSG#{timestamp}#{messageId}
  messageId: string;
  from: string;
  fromName: string;
  direction: 'inbound' | 'outbound';
  type: string;
  content: string;
  metadata: Record<string, unknown>;
  createdAt: string;
  TTL?: number;
}

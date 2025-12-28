// User types
export interface IUser {
  id: string;
  email: string;
  name: string;
  whatsappId?: string;
  createdAt: string;
  updatedAt: string;
}

// Re-export AI types from dedicated module (includes TripPhase, TripStatus enums)
export * from './ai.js';

// Legacy trip types (mantidos por compatibilidade, considere usar TripState do ai.ts)
export interface ITrip {
  id: string;
  userId: string;
  name: string;
  phase: string;
  status: string;
  destinations: string[];
  startDate?: string;
  endDate?: string;
  budget?: number;
  currency: string;
  travelers: number;
  createdAt: string;
  updatedAt: string;
}

// Member types
export type MemberRole = 'OWNER' | 'ADMIN' | 'EDITOR' | 'VIEWER';

export interface ITripMember {
  tripId: string;
  userId: string;
  role: MemberRole;
  name: string;
  email: string;
  joinedAt: string;
}

// Event/Booking types
export type EventType = 'FLIGHT' | 'HOTEL' | 'TOUR' | 'RESTAURANT' | 'TRANSPORT' | 'OTHER';
export type EventStatus = 'PENDING' | 'CONFIRMED' | 'CANCELLED';

export interface IEvent {
  id: string;
  tripId: string;
  type: EventType;
  title: string;
  description?: string;
  date: string;
  time?: string;
  location?: string;
  cost?: number;
  currency: string;
  status: EventStatus;
  provider?: string;
  confirmationCode?: string;
  documentUrl?: string;
  createdAt: string;
  updatedAt: string;
}

// Chat message types
export type MessageSender = 'USER' | 'AGENT' | 'SYSTEM';
export type MessageType = 'text' | 'image' | 'document' | 'location' | 'rich_card';

export interface IChatMessage {
  id: string;
  tripId: string;
  sender: MessageSender;
  senderName?: string;
  type: MessageType;
  content: string;
  metadata?: Record<string, unknown>;
  timestamp: string;
}

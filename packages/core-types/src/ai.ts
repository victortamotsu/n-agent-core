/**
 * AI Types - Tipos para o Bedrock Agent e TripState
 * 
 * Tipos centralizados para toda a lógica de AI do n-agent
 */

// =============================================================================
// ENUMS E CONSTANTES
// =============================================================================

/**
 * Fases da jornada de planejamento
 */
export enum TripPhase {
  /** Coleta inicial de informações */
  KNOWLEDGE = 'KNOWLEDGE',
  /** Criação e refinamento de roteiros */
  PLANNING = 'PLANNING',
  /** Reservas e contratações */
  BOOKING = 'BOOKING',
  /** Acompanhamento durante a viagem */
  CONCIERGE = 'CONCIERGE',
  /** Pós-viagem: fotos e memórias */
  MEMORIES = 'MEMORIES',
}

/**
 * Status da viagem
 */
export enum TripStatus {
  DRAFT = 'DRAFT',
  PLANNING = 'PLANNING',
  CONFIRMED = 'CONFIRMED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

/**
 * Estilo da viagem
 */
export type TripStyle = 'relaxation' | 'adventure' | 'cultural' | 'gastronomy' | 'shopping' | 'mixed';

/**
 * Tipo de hospedagem preferida
 */
export type AccommodationType = 'hotel' | 'airbnb' | 'hostel' | 'resort' | 'pousada' | 'any';

/**
 * Flexibilidade de orçamento
 */
export type BudgetFlexibility = 'tight' | 'moderate' | 'flexible' | 'luxury';

// =============================================================================
// TIPOS DE VIAJANTE
// =============================================================================

/**
 * Informações de um viajante
 */
export interface Traveler {
  id: string;
  name?: string;
  age?: number;
  isChild: boolean;
  isLeadTraveler: boolean;
  foodRestrictions?: string[];
  accessibilityNeeds?: string[];
  fearsPhobias?: string[];
  preferences?: string[];
}

/**
 * Grupo de viajantes
 */
export interface TravelersInfo {
  count: number;
  adults: number;
  children: number;
  infants: number;
  relationship?: string; // "família", "casal", "amigos", "solo"
  travelers: Traveler[];
}

// =============================================================================
// TIPOS DE DATAS E ORÇAMENTO
// =============================================================================

/**
 * Informações de datas da viagem
 */
export interface TripDates {
  startDate?: string; // ISO 8601
  endDate?: string; // ISO 8601
  durationDays?: number;
  isFlexible: boolean;
  flexibilityDays?: number; // quantos dias pode variar
  preferredSeason?: string;
}

/**
 * Informações de orçamento
 */
export interface TripBudget {
  totalAmount?: number;
  perPersonAmount?: number;
  currency: string;
  flexibility: BudgetFlexibility;
  includesFlights: boolean;
  includesAccommodation: boolean;
  dailyEstimate?: number;
}

// =============================================================================
// TIPOS DE PREFERÊNCIAS
// =============================================================================

/**
 * Preferências da viagem
 */
export interface TripPreferences {
  style: TripStyle[];
  accommodation: AccommodationType[];
  interests: string[];
  mustSee: string[]; // atrações obrigatórias
  mustAvoid: string[]; // o que evitar
  pacePreference: 'relaxed' | 'moderate' | 'intensive';
  earlyBird: boolean; // acorda cedo ou prefere dormir
  foodPriority: 'low' | 'medium' | 'high';
  shoppingPriority: 'low' | 'medium' | 'high';
}

/**
 * Destino da viagem
 */
export interface Destination {
  id: string;
  name: string;
  country?: string;
  city?: string;
  region?: string;
  stayDuration?: number; // dias
  priority: number; // ordem de visita
  isPrimary: boolean;
  coordinates?: {
    lat: number;
    lng: number;
  };
}

// =============================================================================
// TRIP STATE - Estado principal da viagem
// =============================================================================

/**
 * Estado completo de uma viagem em planejamento
 * 
 * Este é o objeto central que persiste no DynamoDB
 * e é usado pelo Bedrock Agent para manter contexto
 */
export interface TripState {
  // Identificadores
  tripId: string;
  ownerId: string; // userId ou phoneNumber do criador
  groupId?: string; // se for viagem em grupo
  
  // Metadados
  name?: string; // nome da viagem (ex: "Lua de Mel Europa")
  status: TripStatus;
  currentPhase: TripPhase;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
  
  // Informações coletadas
  destinations: Destination[];
  dates: TripDates;
  travelers: TravelersInfo;
  budget: TripBudget;
  preferences: TripPreferences;
  
  // Ocasiões especiais
  specialOccasions?: string[]; // "lua de mel", "aniversário", etc
  
  // Progresso do agente
  knowledgeScore: number; // 0-100, quão completas estão as informações
  collectedFields: string[]; // lista de campos já coletados
  pendingQuestions: string[]; // próximas perguntas a fazer
  
  // Roteiro (preenchido na fase PLANNING)
  itinerary?: Itinerary;
  
  // Reservas (preenchido na fase BOOKING)
  bookings?: Booking[];
  
  // Histórico
  lastInteraction: string; // ISO 8601
  interactionCount: number;
}

// =============================================================================
// TIPOS DE ROTEIRO
// =============================================================================

/**
 * Atividade em um dia
 */
export interface Activity {
  id: string;
  name: string;
  type: 'attraction' | 'restaurant' | 'transport' | 'hotel' | 'free_time' | 'other';
  startTime?: string; // HH:mm
  endTime?: string; // HH:mm
  duration?: number; // minutos
  location?: string;
  coordinates?: {
    lat: number;
    lng: number;
  };
  estimatedCost?: number;
  currency?: string;
  notes?: string;
  bookingRequired: boolean;
  bookingUrl?: string;
  isOptional: boolean;
  weatherDependent: boolean;
}

/**
 * Dia do roteiro
 */
export interface ItineraryDay {
  dayNumber: number;
  date?: string; // ISO 8601
  destination: string;
  theme?: string; // "Dia de Museus", "Passeio pela Natureza"
  activities: Activity[];
  meals: {
    breakfast?: Activity;
    lunch?: Activity;
    dinner?: Activity;
  };
  accommodation?: Activity;
  notes?: string;
  estimatedDailyCost?: number;
}

/**
 * Roteiro completo
 */
export interface Itinerary {
  id: string;
  version: number;
  name: string; // "Versão Econômica", "Versão Conforto"
  totalDays: number;
  days: ItineraryDay[];
  totalEstimatedCost: number;
  currency: string;
  highlights: string[];
  tips: string[];
  packingList?: string[];
  createdAt: string;
  approvedAt?: string;
}

// =============================================================================
// TIPOS DE RESERVA
// =============================================================================

/**
 * Reserva realizada
 */
export interface Booking {
  id: string;
  type: 'flight' | 'hotel' | 'car' | 'activity' | 'restaurant' | 'other';
  provider: string;
  confirmationCode?: string;
  status: 'pending' | 'confirmed' | 'cancelled';
  startDateTime: string;
  endDateTime?: string;
  location?: string;
  cost: number;
  currency: string;
  paymentStatus: 'pending' | 'paid' | 'refunded';
  documents?: string[]; // URLs para vouchers, etc
  notes?: string;
  createdAt: string;
}

// =============================================================================
// TIPOS DE SESSÃO DO AGENTE
// =============================================================================

/**
 * Sessão de conversa com o agente
 */
export interface AgentSession {
  sessionId: string;
  tripId?: string; // pode não ter trip ainda
  userId: string; // phoneNumber ou cognito userId
  platform: 'whatsapp' | 'web' | 'api';
  
  // Estado da sessão
  isActive: boolean;
  startedAt: string;
  lastActivityAt: string;
  
  // Contexto de curto prazo
  currentIntent?: string;
  pendingAction?: string;
  awaitingConfirmation?: boolean;
  
  // Métricas
  messageCount: number;
  tokenUsage?: {
    input: number;
    output: number;
    total: number;
  };
}

/**
 * Mensagem no histórico
 */
export interface ChatMessage {
  messageId: string;
  sessionId: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: string;
  
  // Metadados
  platform?: 'whatsapp' | 'web' | 'api';
  toolsUsed?: string[];
  extractedData?: Record<string, unknown>;
  
  // Para mensagens do WhatsApp
  whatsappMessageId?: string;
  mediaUrl?: string;
  mediaType?: string;
}

// =============================================================================
// TIPOS PARA ACTION GROUPS
// =============================================================================

/**
 * Contexto retornado por get_trip_context
 */
export interface TripContext {
  trip: TripState | null;
  session: AgentSession;
  recentMessages: ChatMessage[];
  summary: string; // resumo para o agente
}

/**
 * Input para save_trip_info
 */
export interface SaveTripInfoInput {
  tripId: string;
  field: string;
  value: unknown;
  confidence: number; // 0-1, quão certo o agente está do valor
}

/**
 * Resultado de busca de clima
 */
export interface WeatherResult {
  location: string;
  date: string;
  temperature: {
    min: number;
    max: number;
    unit: 'celsius' | 'fahrenheit';
  };
  conditions: string;
  precipitation: number; // porcentagem
  humidity: number;
  recommendation: string;
}

/**
 * Resultado de busca de lugares
 */
export interface PlaceResult {
  placeId: string;
  name: string;
  type: string;
  address: string;
  rating?: number;
  priceLevel?: number; // 1-4
  openNow?: boolean;
  photos?: string[];
  coordinates: {
    lat: number;
    lng: number;
  };
  url?: string;
}

// =============================================================================
// EXPORTS AUXILIARES
// =============================================================================

/**
 * Campos obrigatórios para transição de fase
 */
export const REQUIRED_FIELDS_FOR_PLANNING: (keyof TripState)[] = [
  'destinations',
  'dates',
  'travelers',
  'budget',
];

/**
 * Score mínimo para avançar de fase
 */
export const MINIMUM_KNOWLEDGE_SCORE = 60;

/**
 * Calcula o knowledge score baseado nos campos preenchidos
 */
export function calculateKnowledgeScore(trip: Partial<TripState>): number {
  const weights = {
    destinations: 25,
    dates: 20,
    travelers: 20,
    budget: 15,
    preferences: 10,
    specialOccasions: 5,
    name: 5,
  };
  
  let score = 0;
  
  if (trip.destinations && trip.destinations.length > 0) {
    score += weights.destinations;
  }
  if (trip.dates?.startDate || trip.dates?.durationDays) {
    score += weights.dates;
  }
  if (trip.travelers?.count && trip.travelers.count > 0) {
    score += weights.travelers;
  }
  if (trip.budget?.totalAmount || trip.budget?.perPersonAmount) {
    score += weights.budget;
  }
  if (trip.preferences?.style && trip.preferences.style.length > 0) {
    score += weights.preferences;
  }
  if (trip.specialOccasions && trip.specialOccasions.length > 0) {
    score += weights.specialOccasions;
  }
  if (trip.name) {
    score += weights.name;
  }
  
  return score;
}

/**
 * Verifica se pode avançar para fase de planejamento
 */
export function canAdvanceToPlanning(trip: TripState): boolean {
  return (
    trip.knowledgeScore >= MINIMUM_KNOWLEDGE_SCORE &&
    trip.destinations.length > 0 &&
    (trip.dates.startDate != null || trip.dates.durationDays != null) &&
    trip.travelers.count > 0
  );
}

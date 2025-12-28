import { createLogger } from '@n-agent/logger';
import { NormalizedMessage } from './types.js';
import { WhatsAppClient } from './client.js';
import { getMessageText } from './normalizer.js';
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

const logger = createLogger('bot-handler');

// Config para AI Orchestrator
const USE_AI_ORCHESTRATOR = process.env.USE_AI_ORCHESTRATOR === 'true';
const AI_ORCHESTRATOR_FUNCTION = process.env.AI_ORCHESTRATOR_FUNCTION || 'n-agent-ai-orchestrator';

const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION || 'us-east-1' });

/**
 * Invoca o AI Orchestrator via Lambda
 */
async function invokeAIOrchestrator(
  userId: string,
  message: string,
  sessionId?: string
): Promise<{ response: string; sessionId: string } | null> {
  try {
    const payload = {
      userId,
      message,
      sessionId,
      platform: 'whatsapp',
      metadata: {
        timestamp: new Date().toISOString(),
      },
    };

    logger.info('Invoking AI Orchestrator', { userId, messageLength: message.length });

    const command = new InvokeCommand({
      FunctionName: AI_ORCHESTRATOR_FUNCTION,
      Payload: Buffer.from(JSON.stringify({ body: JSON.stringify(payload) })),
    });

    const result = await lambdaClient.send(command);
    
    if (result.Payload) {
      const responseStr = Buffer.from(result.Payload).toString();
      const response = JSON.parse(responseStr);
      
      if (response.statusCode === 200) {
        const body = JSON.parse(response.body);
        return {
          response: body.response,
          sessionId: body.sessionId,
        };
      }
    }

    logger.warn('AI Orchestrator returned non-200', { result });
    return null;
  } catch (error) {
    logger.error('Error invoking AI Orchestrator', { error });
    return null;
  }
}

/**
 * Main message handler
 * Routes to AI Orchestrator when enabled, falls back to rule-based responses
 */
export async function handleMessage(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const text = getMessageText(message).toLowerCase().trim();
  
  logger.info('Processing message', { 
    from: message.from, 
    type: message.type,
    text: text.substring(0, 100),
    useAI: USE_AI_ORCHESTRATOR,
  });

  // Try AI Orchestrator first if enabled
  if (USE_AI_ORCHESTRATOR && message.type === 'text') {
    const aiResult = await invokeAIOrchestrator(
      message.from,
      getMessageText(message)
    );

    if (aiResult) {
      // Envia resposta do AI
      return await client.sendText({
        to: message.from,
        text: aiResult.response,
        replyTo: message.messageId,
      });
    }
    
    // Fallback se AI falhou
    logger.warn('AI Orchestrator failed, using fallback');
  }

  // Fallback: rule-based responses
  return await handleMessageFallback(message, client, text);
}

/**
 * Rule-based fallback handler (MVP behavior)
 */
async function handleMessageFallback(
  message: NormalizedMessage,
  client: WhatsAppClient,
  text: string
): Promise<string> {
  // Greeting responses
  if (isGreeting(text)) {
    return await sendGreetingResponse(message, client);
  }

  // Help command
  if (text === 'ajuda' || text === 'help' || text === '?') {
    return await sendHelpResponse(message, client);
  }

  // Menu command
  if (text === 'menu' || text === 'início' || text === 'inicio') {
    return await sendMenuResponse(message, client);
  }

  // Trip-related intents
  if (containsTripIntent(text)) {
    return await sendTripStartResponse(message, client);
  }

  // Default response with suggestions
  return await sendDefaultResponse(message, client);
}

function isGreeting(text: string): boolean {
  const greetings = ['oi', 'olá', 'ola', 'hey', 'hello', 'hi', 'bom dia', 'boa tarde', 'boa noite', 'e aí', 'e ai'];
  return greetings.some(g => text.startsWith(g) || text === g);
}

function containsTripIntent(text: string): boolean {
  const tripKeywords = [
    'viagem', 'viajar', 'trip', 'férias', 'ferias',
    'roteiro', 'planejar', 'planejamento', 'destino',
    'hotel', 'voo', 'passagem', 'reserva'
  ];
  return tripKeywords.some(k => text.includes(k));
}

async function sendGreetingResponse(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const firstName = message.fromName.split(' ')[0];
  
  return await client.sendButtons({
    to: message.from,
    type: 'button',
    body: `Olá, ${firstName}! 👋\n\nSou o *n-agent*, seu assistente pessoal de viagens!\n\nEstou aqui para ajudar você a planejar, organizar e aproveitar suas viagens de forma inteligente.\n\nO que você gostaria de fazer?`,
    footer: 'Powered by n-agent ✈️',
    buttons: [
      { id: 'new_trip', title: '✈️ Nova Viagem' },
      { id: 'my_trips', title: '📋 Minhas Viagens' },
      { id: 'help', title: '❓ Ajuda' },
    ],
  });
}

async function sendHelpResponse(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const helpText = `*🤖 Central de Ajuda - n-agent*

Aqui está o que posso fazer por você:

*✈️ Planejamento de Viagem*
• Criar roteiros personalizados
• Sugerir destinos e atrações
• Calcular orçamentos

*🏨 Hospedagem*
• Buscar hotéis e Airbnbs
• Comparar preços
• Verificar disponibilidade

*📅 Organização*
• Gerenciar datas importantes
• Criar listas de tarefas
• Acompanhar reservas

*💬 Comandos úteis:*
• *menu* - Ver menu principal
• *ajuda* - Esta mensagem
• *viagem* - Começar uma nova viagem

Você também pode me enviar:
📍 Localização
🖼️ Fotos de documentos
🎙️ Mensagens de voz`;

  return await client.sendText({
    to: message.from,
    text: helpText,
  });
}

async function sendMenuResponse(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  return await client.sendList({
    to: message.from,
    type: 'list',
    header: {
      type: 'text',
      text: '🌍 n-agent',
    },
    body: 'Escolha uma opção no menu abaixo para começar:',
    footer: 'Seu assistente de viagens',
    sections: [
      {
        title: 'Viagens',
        rows: [
          { id: 'new_trip', title: '✈️ Nova Viagem', description: 'Planejar uma nova viagem' },
          { id: 'my_trips', title: '📋 Minhas Viagens', description: 'Ver viagens em andamento' },
          { id: 'trip_ideas', title: '💡 Ideias de Destino', description: 'Inspiração para sua próxima aventura' },
        ],
      },
      {
        title: 'Conta',
        rows: [
          { id: 'profile', title: '👤 Meu Perfil', description: 'Ver e editar seus dados' },
          { id: 'settings', title: '⚙️ Configurações', description: 'Preferências e notificações' },
          { id: 'help', title: '❓ Ajuda', description: 'Como usar o n-agent' },
        ],
      },
    ],
  });
}

async function sendTripStartResponse(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const responseText = `*✈️ Vamos planejar sua viagem!*

Para começar, me conte um pouco sobre seus planos:

1️⃣ *Destino(s)*: Para onde você quer ir?
2️⃣ *Datas*: Quando pretende viajar?
3️⃣ *Viajantes*: Quantas pessoas vão?
4️⃣ *Estilo*: Econômico, confortável ou luxo?

Pode me contar tudo de uma vez ou responder uma pergunta por vez! 😊

_Exemplo: "Quero ir para Paris em março com minha esposa, viagem romântica, orçamento médio"_`;

  return await client.sendText({
    to: message.from,
    text: responseText,
    replyTo: message.messageId,
  });
}

async function sendDefaultResponse(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const responseText = `Entendi! 🤔

Estou em fase de aprendizado e ainda não consigo processar todas as mensagens.

Enquanto isso, você pode:
• Digitar *menu* para ver as opções
• Digitar *ajuda* para saber o que posso fazer
• Digitar *viagem* para começar a planejar

_Em breve terei mais capacidades! 🚀_`;

  return await client.sendText({
    to: message.from,
    text: responseText,
  });
}

/**
 * Handle button/list selection responses
 */
export async function handleInteraction(
  message: NormalizedMessage,
  client: WhatsAppClient
): Promise<string> {
  const buttonId = message.content.buttonId;
  
  logger.info('Processing interaction', { from: message.from, buttonId });

  switch (buttonId) {
    case 'new_trip':
      return await sendTripStartResponse(message, client);
    
    case 'my_trips':
      return await client.sendText({
        to: message.from,
        text: '📋 *Suas Viagens*\n\nVocê ainda não tem viagens cadastradas.\n\nDigite *viagem* para começar a planejar sua primeira aventura! ✈️',
      });
    
    case 'trip_ideas':
      return await client.sendText({
        to: message.from,
        text: '💡 *Ideias de Destino*\n\n🏝️ *Praias*: Maldivas, Cancún, Fernando de Noronha\n🏔️ *Montanhas*: Suíça, Patagônia, Machu Picchu\n🏛️ *Cidades*: Paris, Tokyo, Nova York\n🌿 *Natureza*: Costa Rica, Nova Zelândia, Noruega\n\nMe conte qual tipo de viagem te interessa! 😊',
      });
    
    case 'profile':
    case 'settings':
      return await client.sendText({
        to: message.from,
        text: '⚙️ Esta funcionalidade estará disponível em breve!\n\nPor enquanto, acesse o painel web em n-agent.com para gerenciar seu perfil.',
      });
    
    case 'help':
      return await sendHelpResponse(message, client);
    
    default:
      return await sendDefaultResponse(message, client);
  }
}

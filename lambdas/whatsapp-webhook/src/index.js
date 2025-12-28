/**
 * WhatsApp Business Webhook Handler
 * 
 * Recebe mensagens do WhatsApp e envia para o n-agent via SNS
 * 
 * Fase 0: Estrutura preparada (não conectado)
 * Fase 4: Ativar integração completa
 */

const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const crypto = require('crypto');

// Clientes AWS
const secretsClient = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });
const snsClient = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });

// Cache de credenciais (para evitar chamadas repetidas ao Secrets Manager)
let whatsappCredentials = null;

/**
 * Busca credenciais do WhatsApp no Secrets Manager
 */
async function getWhatsAppCredentials() {
  if (whatsappCredentials) return whatsappCredentials;
  
  try {
    const response = await secretsClient.send(
      new GetSecretValueCommand({
        SecretId: process.env.WHATSAPP_SECRET_NAME || 'n-agent/whatsapp-credentials'
      })
    );
    
    whatsappCredentials = JSON.parse(response.SecretString);
    return whatsappCredentials;
  } catch (error) {
    console.error('❌ Erro ao buscar credenciais WhatsApp:', error);
    throw new Error('Failed to retrieve WhatsApp credentials');
  }
}

/**
 * Verifica assinatura do webhook (segurança)
 */
function verifyWebhookSignature(body, signature) {
  const credentials = whatsappCredentials;
  if (!credentials || !credentials.app_secret) return false;
  
  const expectedSignature = crypto
    .createHmac('sha256', credentials.app_secret)
    .update(body)
    .digest('hex');
  
  return signature === `sha256=${expectedSignature}`;
}

/**
 * Processa mensagem de texto do WhatsApp
 */
async function processTextMessage(message, from) {
  console.log(`📱 Mensagem de ${from}: ${message.text.body}`);
  
  // Publicar no SNS para processamento assíncrono pelo n-agent
  const snsMessage = {
    source: 'whatsapp',
    from: from,
    message_id: message.id,
    timestamp: message.timestamp,
    message_type: 'text',
    content: {
      text: message.text.body
    },
    metadata: {
      context: message.context || null,
      reply_to: message.context?.id || null
    }
  };
  
  await snsClient.send(
    new PublishCommand({
      TopicArn: process.env.AGENT_SNS_TOPIC_ARN,
      Message: JSON.stringify(snsMessage),
      MessageAttributes: {
        source: { DataType: 'String', StringValue: 'whatsapp' },
        message_type: { DataType: 'String', StringValue: 'text' }
      }
    })
  );
  
  console.log('✅ Mensagem publicada no SNS');
}

/**
 * Processa mensagem com imagem/documento
 */
async function processMediaMessage(message, from, mediaType) {
  console.log(`📎 Mídia (${mediaType}) de ${from}`);
  
  const media = message[mediaType];
  
  const snsMessage = {
    source: 'whatsapp',
    from: from,
    message_id: message.id,
    timestamp: message.timestamp,
    message_type: mediaType,
    content: {
      media_id: media.id,
      mime_type: media.mime_type,
      caption: media.caption || null,
      sha256: media.sha256
    },
    metadata: {
      context: message.context || null
    }
  };
  
  await snsClient.send(
    new PublishCommand({
      TopicArn: process.env.AGENT_SNS_TOPIC_ARN,
      Message: JSON.stringify(snsMessage),
      MessageAttributes: {
        source: { DataType: 'String', StringValue: 'whatsapp' },
        message_type: { DataType: 'String', StringValue: mediaType }
      }
    })
  );
  
  console.log('✅ Mídia publicada no SNS');
}

/**
 * Handler principal do webhook
 */
exports.handler = async (event) => {
  console.log('📥 Webhook recebido:', JSON.stringify(event, null, 2));
  
  try {
    // 1. Verificação do webhook (GET) - Facebook/Meta usa isso para validar a URL
    if (event.httpMethod === 'GET') {
      const mode = event.queryStringParameters?.['hub.mode'];
      const token = event.queryStringParameters?.['hub.verify_token'];
      const challenge = event.queryStringParameters?.['hub.challenge'];
      
      if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
        console.log('✅ Webhook verificado com sucesso');
        return {
          statusCode: 200,
          body: challenge
        };
      }
      
      console.log('❌ Falha na verificação do webhook');
      return { statusCode: 403, body: 'Forbidden' };
    }
    
    // 2. Processar mensagens (POST)
    if (event.httpMethod === 'POST') {
      // Buscar credenciais
      await getWhatsAppCredentials();
      
      // Verificar assinatura (segurança)
      const signature = event.headers['x-hub-signature-256'];
      if (signature && !verifyWebhookSignature(event.body, signature)) {
        console.log('❌ Assinatura inválida');
        return { statusCode: 401, body: 'Unauthorized' };
      }
      
      const body = JSON.parse(event.body);
      
      // WhatsApp envia array de entries
      for (const entry of body.entry || []) {
        for (const change of entry.changes || []) {
          if (change.field !== 'messages') continue;
          
          const value = change.value;
          
          // Processar mensagens recebidas
          for (const message of value.messages || []) {
            const from = message.from;
            
            // Tipos de mensagem suportados
            if (message.type === 'text') {
              await processTextMessage(message, from);
            } else if (['image', 'document', 'audio', 'video'].includes(message.type)) {
              await processMediaMessage(message, from, message.type);
            } else {
              console.log(`⚠️ Tipo de mensagem não suportado: ${message.type}`);
            }
          }
          
          // Processar status de mensagens enviadas (delivered, read, etc)
          for (const status of value.statuses || []) {
            console.log(`📊 Status update: ${status.id} → ${status.status}`);
          }
        }
      }
      
      return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
      };
    }
    
    // Método não suportado
    return {
      statusCode: 405,
      body: 'Method Not Allowed'
    };
    
  } catch (error) {
    console.error('❌ Erro no webhook:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      })
    };
  }
};

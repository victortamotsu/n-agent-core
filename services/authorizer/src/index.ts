import { APIGatewayRequestAuthorizerEvent, APIGatewayAuthorizerResult } from 'aws-lambda';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { createLogger } from '@n-agent/logger';

const logger = createLogger('authorizer');
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID!;
const REGION = process.env.COGNITO_REGION || 'us-east-1';

const client = jwksClient({
  jwksUri: `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json`,
  cache: true,
  cacheMaxAge: 600000, // 10 minutes
});

function getKey(header: jwt.JwtHeader, callback: jwt.SigningKeyCallback) {
  client.getSigningKey(header.kid!, (err, key) => {
    if (err) {
      callback(err);
      return;
    }
    const signingKey = key?.getPublicKey();
    callback(null, signingKey);
  });
}

export const handler = async (
  event: APIGatewayRequestAuthorizerEvent
): Promise<APIGatewayAuthorizerResult> => {
  logger.info('Authorizer invoked', {
    path: event.path,
    method: event.httpMethod,
  });

  try {
    const token = event.headers?.authorization?.replace('Bearer ', '') || 
                  event.headers?.Authorization?.replace('Bearer ', '');

    if (!token) {
      logger.warn('No token provided');
      return generatePolicy('user', 'Deny', event.methodArn);
    }

    // Verify and decode token
    const decoded = await new Promise<jwt.JwtPayload>((resolve, reject) => {
      jwt.verify(
        token,
        getKey,
        {
          algorithms: ['RS256'],
          issuer: `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}`,
        },
        (err, decoded) => {
          if (err) {
            reject(err);
            return;
          }
          resolve(decoded as jwt.JwtPayload);
        }
      );
    });

    logger.info('Token validated', {
      sub: decoded.sub,
      email: decoded.email,
    });

    return generatePolicy(decoded.sub!, 'Allow', event.methodArn, {
      userId: decoded.sub!,
      email: decoded.email!,
      username: decoded['cognito:username'] || decoded.email!,
    });
  } catch (error) {
    logger.error('Authorization failed', { error });
    return generatePolicy('user', 'Deny', event.methodArn);
  }
};

function generatePolicy(
  principalId: string,
  effect: 'Allow' | 'Deny',
  resource: string,
  context?: Record<string, string>
): APIGatewayAuthorizerResult {
  const authResponse: APIGatewayAuthorizerResult = {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: effect,
          Resource: resource,
        },
      ],
    },
  };

  if (context) {
    authResponse.context = context;
  }

  return authResponse;
}

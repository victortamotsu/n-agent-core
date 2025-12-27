import {
  CognitoIdentityProviderClient,
  SignUpCommand,
  InitiateAuthCommand,
  ConfirmSignUpCommand,
  ForgotPasswordCommand,
  ConfirmForgotPasswordCommand,
  ResendConfirmationCodeCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { createLogger } from '@n-agent/logger';

const logger = createLogger('auth');
const client = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION || 'us-east-1' });
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID!;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID!;

export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  logger.info('Auth request received', {
    path: event.rawPath,
    method: event.requestContext.http.method,
  });

  const method = event.requestContext.http.method;
  const path = event.rawPath;

  try {
    // POST /auth/signup
    if (method === 'POST' && path === '/auth/signup') {
      return await handleSignup(event);
    }

    // POST /auth/login
    if (method === 'POST' && path === '/auth/login') {
      return await handleLogin(event);
    }

    // POST /auth/confirm
    if (method === 'POST' && path === '/auth/confirm') {
      return await handleConfirmSignup(event);
    }

    // POST /auth/refresh
    if (method === 'POST' && path === '/auth/refresh') {
      return await handleRefresh(event);
    }

    // POST /auth/forgot-password
    if (method === 'POST' && path === '/auth/forgot-password') {
      return await handleForgotPassword(event);
    }

    // POST /auth/reset-password
    if (method === 'POST' && path === '/auth/reset-password') {
      return await handleResetPassword(event);
    }

    // POST /auth/resend-code
    if (method === 'POST' && path === '/auth/resend-code') {
      return await handleResendCode(event);
    }

    return {
      statusCode: 404,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Route not found' }),
    };
  } catch (error) {
    logger.error('Auth error', { error });
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};

async function handleSignup(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email, password, name } = body;

  if (!email || !password || !name) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email, password and name are required' }),
    };
  }

  try {
    const command = new SignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      Password: password,
      UserAttributes: [
        { Name: 'email', Value: email },
        { Name: 'name', Value: name },
      ],
    });

    const response = await client.send(command);

    logger.info('User signed up successfully', { email, userSub: response.UserSub });

    return {
      statusCode: 201,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'User created successfully',
        userSub: response.UserSub,
        emailVerificationRequired: !response.UserConfirmed,
      }),
    };
  } catch (error: any) {
    logger.error('Signup error', { error, email });
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Signup failed' }),
    };
  }
}

async function handleLogin(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email, password } = body;

  if (!email || !password) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email and password are required' }),
    };
  }

  try {
    const command = new InitiateAuthCommand({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    });

    const response = await client.send(command);

    if (!response.AuthenticationResult) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Authentication failed' }),
      };
    }

    logger.info('User logged in successfully', { email });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: response.AuthenticationResult.AccessToken,
        idToken: response.AuthenticationResult.IdToken,
        refreshToken: response.AuthenticationResult.RefreshToken,
        expiresIn: response.AuthenticationResult.ExpiresIn,
      }),
    };
  } catch (error: any) {
    logger.error('Login error', { error, email });
    return {
      statusCode: 401,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Login failed' }),
    };
  }
}

async function handleConfirmSignup(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email, code } = body;

  if (!email || !code) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email and confirmation code are required' }),
    };
  }

  try {
    const command = new ConfirmSignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      ConfirmationCode: code,
    });

    await client.send(command);

    logger.info('User confirmed successfully', { email });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Email confirmed successfully' }),
    };
  } catch (error: any) {
    logger.error('Confirmation error', { error, email });
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Confirmation failed' }),
    };
  }
}

async function handleRefresh(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { refreshToken } = body;

  if (!refreshToken) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Refresh token is required' }),
    };
  }

  try {
    const command = new InitiateAuthCommand({
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      ClientId: CLIENT_ID,
      AuthParameters: {
        REFRESH_TOKEN: refreshToken,
      },
    });

    const response = await client.send(command);

    if (!response.AuthenticationResult) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Token refresh failed' }),
      };
    }

    logger.info('Token refreshed successfully');

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accessToken: response.AuthenticationResult.AccessToken,
        idToken: response.AuthenticationResult.IdToken,
        expiresIn: response.AuthenticationResult.ExpiresIn,
      }),
    };
  } catch (error: any) {
    logger.error('Refresh error', { error });
    return {
      statusCode: 401,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Token refresh failed' }),
    };
  }
}

async function handleForgotPassword(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email } = body;

  if (!email) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email is required' }),
    };
  }

  try {
    const command = new ForgotPasswordCommand({
      ClientId: CLIENT_ID,
      Username: email,
    });

    await client.send(command);

    logger.info('Password reset code sent', { email });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Password reset code sent to email' }),
    };
  } catch (error: any) {
    logger.error('Forgot password error', { error, email });
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Failed to send reset code' }),
    };
  }
}

async function handleResetPassword(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email, code, newPassword } = body;

  if (!email || !code || !newPassword) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email, code and new password are required' }),
    };
  }

  try {
    const command = new ConfirmForgotPasswordCommand({
      ClientId: CLIENT_ID,
      Username: email,
      ConfirmationCode: code,
      Password: newPassword,
    });

    await client.send(command);

    logger.info('Password reset successfully', { email });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Password reset successfully' }),
    };
  } catch (error: any) {
    logger.error('Reset password error', { error, email });
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Password reset failed' }),
    };
  }
}

async function handleResendCode(event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> {
  const body = JSON.parse(event.body || '{}');
  const { email } = body;

  if (!email) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Email is required' }),
    };
  }

  try {
    const command = new ResendConfirmationCodeCommand({
      ClientId: CLIENT_ID,
      Username: email,
    });

    await client.send(command);

    logger.info('Confirmation code resent', { email });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Confirmation code resent' }),
    };
  } catch (error: any) {
    logger.error('Resend code error', { error, email });
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: error.message || 'Failed to resend code' }),
    };
  }
}

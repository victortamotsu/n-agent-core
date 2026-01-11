/**
 * AWS Amplify Configuration
 * 
 * Cognito User Pool and API Gateway endpoints for n-agent
 */

export const amplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_sztMWSEm4',
      userPoolClientId: '4e0reesiair18vo4ebfjp1d73q',
      loginWith: {
        oauth: {
          domain: 'n-agent-core-prod.auth.us-east-1.amazoncognito.com',
          scopes: ['email', 'openid', 'profile'],
          redirectSignIn: ['http://localhost:5173/', 'https://app.n-agent.com/'],
          redirectSignOut: ['http://localhost:5173/', 'https://app.n-agent.com/'],
          responseType: 'code',
          providers: ['Google', 'Microsoft']
        }
      }
    }
  },
  API: {
    REST: {
      nAgentAPI: {
        endpoint: 'https://5ul5bax4s9.execute-api.us-east-1.amazonaws.com/prod',
        region: 'us-east-1'
      }
    }
  }
};

# VSCode AWS Toolkit - Setup Guide

## Installation
1. Install extension: `AWS Toolkit` (ID: amazonwebservices.aws-toolkit-vscode)
2. Configure AWS credentials (already done via AWS CLI)

## Debug Lambda Locally

### 1. Create SAM template for local testing
Create `sam-local.yaml`:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Timeout: 30
    Runtime: nodejs18.x
    Environment:
      Variables:
        ENVIRONMENT: local

Resources:
  TripPlannerFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: services/trip-planner/dist/
      Handler: index.handler
      Events:
        Health:
          Type: Api
          Properties:
            Path: /health
            Method: get

  WhatsAppBotFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: services/whatsapp-bot/dist/
      Handler: index.handler
      Events:
        WebhookVerify:
          Type: Api
          Properties:
            Path: /webhooks/whatsapp
            Method: get
```

### 2. Create debug configuration
Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "aws-sam",
      "request": "direct-invoke",
      "name": "Debug Trip Planner (Local)",
      "invokeTarget": {
        "target": "template",
        "templatePath": "${workspaceFolder}/sam-local.yaml",
        "logicalId": "TripPlannerFunction"
      },
      "lambda": {
        "payload": {
          "requestContext": {
            "http": {
              "method": "GET"
            }
          },
          "rawPath": "/health"
        },
        "environmentVariables": {
          "ENVIRONMENT": "local"
        }
      }
    }
  ]
}
```

### 3. Set breakpoints and press F5 to debug!

## Quick Lambda Update (No Debug)

```bash
# Bundle and deploy in one command
pnpm run quick-deploy trip-planner dev
```

## Watch Mode for Development

```bash
# Auto-rebuild on file changes
pnpm run dev:lambda
```

## View Lambda Logs in Real-Time

```bash
# Tail logs from AWS
aws logs tail /aws/lambda/n-agent-trip-planner-dev --follow

# Or use VSCode AWS Toolkit:
# 1. Open AWS Explorer
# 2. Navigate to Lambda Functions
# 3. Right-click → View CloudWatch Logs
```

## Remote Debugging (Advanced)

For debugging live Lambda in AWS:
1. Enable X-Ray tracing in Terraform
2. Use AWS X-Ray SDK for detailed traces
3. Add console.log statements (visible in CloudWatch)

## Best Practice Workflow

1. **Development**: Use SAM local + VSCode debugger
2. **Quick Test**: Use quick-deploy script to dev environment
3. **Validation**: Run full CI/CD to dev
4. **Production**: Merge to main → auto-deploy to prod

## Tips

- Keep dev environment separate from prod
- Use environment variables for config
- Test with actual API Gateway events (use event templates)
- Monitor CloudWatch Logs for issues

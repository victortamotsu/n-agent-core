# Infrastructure as Code (Terraform)

Este diretório contém a definição de infraestrutura AWS usando Terraform.

## Estrutura

- `modules/` - Módulos Terraform reutilizáveis
- `environments/` - Configurações por ambiente (dev, staging, prod)

## Pré-requisitos

- Terraform >= 1.6.0
- AWS CLI configurado
- Credenciais AWS com permissões adequadas

## Uso

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

## Módulos

- **dynamodb** - Tabelas DynamoDB (Users, Trips, ChatHistory)
- **s3** - Buckets para documentos e assets
- **api-gateway** - API Gateway REST e WebSocket
- **lambda** - Funções Lambda
- **cognito** - User Pool para autenticação

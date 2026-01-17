# n-agent Architecture Diagrams

This document contains Mermaid diagrams describing the AWS solution architecture and application execution flow.

## Table of Contents

- [AWS Architecture](#aws-architecture)
- [Multi-Agent System](#multi-agent-system)
- [Application Flow - Normal Execution](#application-flow---normal-execution)
- [Data Model](#data-model)
- [Authentication Flow](#authentication-flow)

---

## AWS Architecture

This diagram shows the complete serverless architecture on AWS, including all components from edge to data layer.

```mermaid
---
config:
  layout: elk
---
graph TB
    subgraph "User Interfaces"
        WEB[Web Client<br/>React + Vite + MUI]
        WA[WhatsApp<br/>Meta Cloud API]
    end

    subgraph "Edge Layer"
        CF[Amazon CloudFront<br/>CDN]
        WAF[AWS WAF<br/>Firewall]
    end

    subgraph "API Layer"
        APIGW[API Gateway HTTP API<br/>REST + WebSocket]
        AUTH[Cognito User Pool<br/>OAuth Google/Microsoft]
    end

    subgraph "Orchestration Layer"
        BFF[Lambda BFF<br/>Python 3.12]
        RUNTIME[AgentCore Runtime<br/>Serverless AI Engine]
        EB[EventBridge<br/>Event Bus]
    end

    subgraph "Multi-Agent System"
        ROUTER[Router Agent<br/>Nova Micro]
        PROFILE[Profile Agent<br/>Nova Lite]
        PLANNER[Planner Agent<br/>Nova Pro]
        SEARCH[Search Agent<br/>Gemini 2.0 Flash]
        CONCIERGE[Concierge Agent<br/>Nova Lite]
        DOCUMENT[Document Agent<br/>Claude 3.5 Sonnet]
        VISION[Vision Agent<br/>Claude 3.5 Sonnet]
    end

    subgraph "Service Domains"
        TP[Trip Planner<br/>Lambda]
        INT[Integrator<br/>Lambda]
        CONC[Concierge<br/>Lambda]
        DOC[Doc Generator<br/>Lambda]
        WAHOOK[WhatsApp Handler<br/>Lambda Node.js]
    end

    subgraph "Data Layer"
        DDB[(DynamoDB)]
        S3[(S3 Bucket)]
        SM[Secrets Manager]
    end

    subgraph "External APIs"
        GMAPS[Google Maps<br/>Places + Directions]
        GEMINI[Vertex AI<br/>Gemini + Search]
        BOOKING[Booking.com<br/>Affiliate API]
        AIRBNB[Airbnb<br/>Web Scraping]
        AVIATION[AviationStack<br/>Flight Status]
    end

    WEB --> CF
    CF --> APIGW
    WA --> WAHOOK
    WAHOOK --> EB
    
    APIGW --> WAF
    WAF --> AUTH
    AUTH --> BFF
    BFF --> RUNTIME
    
    RUNTIME --> ROUTER
    ROUTER --> PROFILE
    ROUTER --> PLANNER
    ROUTER --> SEARCH
    ROUTER --> CONCIERGE
    ROUTER --> DOCUMENT
    ROUTER --> VISION
    
    PROFILE --> DDB
    PLANNER --> TP
    SEARCH --> INT
    CONCIERGE --> CONC
    DOCUMENT --> DOC
    
    TP --> DDB
    INT --> GMAPS
    INT --> BOOKING
    INT --> AIRBNB
    INT --> AVIATION
    CONC --> DDB
    DOC --> S3
    
    SEARCH --> GEMINI
    RUNTIME --> EB
    EB --> TP
    EB --> INT
    EB --> CONC
    
    BFF --> DDB
    BFF --> S3
    BFF --> SM

    style RUNTIME fill:#6750A4,stroke:#21005D,color:#fff
    style ROUTER fill:#D0BCFF,stroke:#381E72
    style PROFILE fill:#D0BCFF,stroke:#381E72
    style PLANNER fill:#D0BCFF,stroke:#381E72
    style SEARCH fill:#D0BCFF,stroke:#381E72
    style CONCIERGE fill:#D0BCFF,stroke:#381E72
    style DOCUMENT fill:#D0BCFF,stroke:#381E72
    style VISION fill:#D0BCFF,stroke:#381E72
```

---

## Multi-Agent System

This diagram details the internal structure of the multi-agent system and how agents interact with each other.

```mermaid

---
config:
  layout: elk
---

graph LR
    subgraph "AgentCore Runtime"
        INPUT[User Message]
        
        subgraph "Routing Layer"
            ROUTER[Router Agent<br/>Nova Micro<br/>$0.035/1M tokens]
        end
        
        subgraph "Execution Layer"
            PROFILE[Profile Agent<br/>Nova Lite<br/>Extract & Persist]
            PLANNER[Planner Agent<br/>Nova Pro<br/>Itinerary Creation]
            SEARCH[Search Agent<br/>Gemini 2.0 Flash<br/>Real-time Search]
            CONCIERGE[Concierge Agent<br/>Nova Lite<br/>Alerts & Support]
            DOCUMENT[Document Agent<br/>Claude 3.5 Sonnet<br/>Rich Documents]
            VISION[Vision Agent<br/>Claude 3.5 Sonnet<br/>OCR & Image Analysis]
        end
        
        subgraph "Memory Layer"
            MEMORY[AgentCore Memory<br/>Conversation Context]
            TOOLS[Shared Tools<br/>get_profile, update_trip, etc.]
        end
        
        OUTPUT[Agent Response]
    end
    
    INPUT --> ROUTER
    
    ROUTER -->|30% calls| PROFILE
    ROUTER -->|15% calls| PLANNER
    ROUTER -->|25% calls| SEARCH
    ROUTER -->|20% calls| CONCIERGE
    ROUTER -->|5% calls| DOCUMENT
    ROUTER -->|5% calls| VISION
    
    PROFILE --> MEMORY
    PLANNER --> MEMORY
    SEARCH --> MEMORY
    CONCIERGE --> MEMORY
    DOCUMENT --> MEMORY
    VISION --> MEMORY
    
    PROFILE --> TOOLS
    PLANNER --> TOOLS
    SEARCH --> TOOLS
    CONCIERGE --> TOOLS
    DOCUMENT --> TOOLS
    VISION --> TOOLS
    
    MEMORY --> OUTPUT
    TOOLS --> OUTPUT

    style ROUTER fill:#FFB4AB,stroke:#93000A
    style PROFILE fill:#95F0FF,stroke:#001F24
    style PLANNER fill:#AADAFF,stroke:#001D35
    style SEARCH fill:#B4C5FF,stroke:#001A41
    style CONCIERGE fill:#D0BCFF,stroke:#381E72
    style DOCUMENT fill:#EFB8FF,stroke:#49006C
    style VISION fill:#FFB1C8,stroke:#68001B
    style MEMORY fill:#F4DEDC,stroke:#8C1D18
    style TOOLS fill:#E8DEF8,stroke:#1D192B
```

---

## Application Flow - Normal Execution

This flowchart describes the complete execution flow of the application, from user input to final response.

```mermaid

---
config:
  layout: elk
---
flowchart TD
    START([User Sends Message])
    
    subgraph "1. Message Reception"
        A[Web Chat or WhatsApp]
        B{Interface Type?}
        C[WhatsApp Handler Lambda]
        D[API Gateway]
        E[Normalize Message Format]
    end
    
    subgraph "2. Authentication & Validation"
        F{User Authenticated?}
        G[Cognito JWT Validation]
        H[Return 401 Unauthorized]
        I[Get User Context from DynamoDB]
    end
    
    subgraph "3. Event Publishing"
        J[Publish to EventBridge]
        K[Event: MESSAGE_RECEIVED]
        L[Lambda BFF Subscribes]
    end
    
    subgraph "4. Agent Orchestration"
        M[Invoke AgentCore Runtime]
        N[Router Agent Analyzes Intent]
        O{Intent Classification}
        
        P1[PROFILE Intent]
        P2[PLANNING Intent]
        P3[SEARCH Intent]
        P4[CONCIERGE Intent]
        P5[DOCUMENT Intent]
        P6[VISION Intent]
        P7[CHAT Intent]
    end
    
    subgraph "5. Specialized Agent Execution"
        Q1[Profile Agent<br/>Extract & Update Profile]
        Q2[Planner Agent<br/>Create/Update Itinerary]
        Q3[Search Agent<br/>Query External APIs]
        Q4[Concierge Agent<br/>Check Alerts & Reminders]
        Q5[Document Agent<br/>Generate PDF/HTML]
        Q6[Vision Agent<br/>Process Image]
        Q7[Router Agent<br/>Direct Response]
    end
    
    subgraph "6. Tool Execution"
        R{Requires External API?}
        S[Integrator Lambda]
        T[Call External Service]
        U[Google Maps / Booking / Gemini]
        V[Cache Result]
    end
    
    subgraph "7. Memory & Persistence"
        W[Get Conversation Context]
        X[Execute Agent Tools]
        Y[Update Trip/Profile Data]
        Z[Save to DynamoDB]
        AA[Update AgentCore Memory]
    end
    
    subgraph "8. Response Generation"
        AB[Agent Generates Response]
        AC{Response Type?}
        AD[Text Message]
        AE[Rich Document Link]
        AF[Task List/Questions]
        AG[Quick Action Buttons]
    end
    
    subgraph "9. Response Delivery"
        AH[Format Response for Interface]
        AI{Original Interface?}
        AJ[Send to Web via WebSocket]
        AK[Send to WhatsApp via Meta API]
        AL[Save Message to Chat History]
    end
    
    END([User Receives Response])
    
    START --> A
    A --> B
    B -->|WhatsApp| C
    B -->|Web| D
    C --> E
    D --> E
    
    E --> F
    F -->|No| H
    H --> END
    F -->|Yes| G
    G --> I
    
    I --> J
    J --> K
    K --> L
    
    L --> M
    M --> N
    N --> O
    
    O -->|PROFILE| P1
    O -->|PLANNING| P2
    O -->|SEARCH| P3
    O -->|CONCIERGE| P4
    O -->|DOCUMENT| P5
    O -->|VISION| P6
    O -->|CHAT| P7
    
    P1 --> Q1
    P2 --> Q2
    P3 --> Q3
    P4 --> Q4
    P5 --> Q5
    P6 --> Q6
    P7 --> Q7
    
    Q1 --> W
    Q2 --> R
    Q3 --> R
    Q4 --> R
    Q5 --> W
    Q6 --> W
    Q7 --> W
    
    R -->|Yes| S
    R -->|No| W
    S --> T
    T --> U
    U --> V
    V --> W
    
    W --> X
    X --> Y
    Y --> Z
    Z --> AA
    
    AA --> AB
    AB --> AC
    
    AC -->|Text| AD
    AC -->|Document| AE
    AC -->|Tasks| AF
    AC -->|Buttons| AG
    
    AD --> AH
    AE --> AH
    AF --> AH
    AG --> AH
    
    AH --> AI
    AI -->|Web| AJ
    AI -->|WhatsApp| AK
    
    AJ --> AL
    AK --> AL
    AL --> END

    style START fill:#6750A4,stroke:#21005D,color:#fff
    style END fill:#6750A4,stroke:#21005D,color:#fff
    style F fill:#FFB4AB,stroke:#93000A
    style O fill:#FFB4AB,stroke:#93000A
    style R fill:#FFB4AB,stroke:#93000A
    style AC fill:#FFB4AB,stroke:#93000A
    style AI fill:#FFB4AB,stroke:#93000A
```

---

## Data Model

This diagram shows the DynamoDB Single Table Design structure and relationships between entities.

```mermaid

---
config:
  layout: elk
---

erDiagram
    NAgentCore {
        string PK "Partition Key"
        string SK "Sort Key"
        map Attributes "Entity Data"
    }
    
    NAgentProfiles {
        string PK "Partition Key"
        string SK "Sort Key"
        map Attributes "Profile Data"
    }
    
    NAgentChatHistory {
        string PK "TRIP#uuid"
        string SK "MSG#timestamp"
        map Attributes "Message Data"
    }
    
    NAgentConfig {
        string PK "PROMPT#type or INTEGRATION#name"
        string SK "VERSION#n or CONFIG"
        map Attributes "Configuration Data"
    }
    
    S3Bucket {
        string Key "File Path"
        binary Content "File Data"
    }

    NAgentCore ||--o{ NAgentProfiles : "references"
    NAgentCore ||--o{ NAgentChatHistory : "conversation logs"
    NAgentCore ||--o{ S3Bucket : "stores documents"
    NAgentConfig ||--o{ NAgentCore : "configures agents"

    NAgentCore_User["USER#email | PROFILE"]
    NAgentCore_Trip["TRIP#uuid | META#USER#email#DATE#start"]
    NAgentCore_Participant["TRIP#uuid | MEMBER#email"]
    NAgentCore_Day["TRIP#uuid | DAY#YYYY-MM-DD"]
    NAgentCore_Event["TRIP#uuid | EVENT#timestamp"]
    
    NAgentProfiles_Person["PERSON#personId | PROFILE#GENERAL"]
    NAgentProfiles_TripPrefs["PERSON#personId | TRIP#tripId#PREFS"]
    NAgentProfiles_Trip["TRIP#tripId | PROFILE#GENERAL"]
    
    NAgentConfig_Prompt["PROMPT#agentType | VERSION#n"]
    NAgentConfig_Integration["INTEGRATION#name | CONFIG"]
```

**Access Patterns:**

1. **Get User Profile**: `PK = USER#email, SK = PROFILE`
2. **Get Trip with Metadata**: `PK = TRIP#uuid, SK begins_with META`
3. **Get All Trip Participants**: `PK = TRIP#uuid, SK begins_with MEMBER`
4. **Get Trip Day Itinerary**: `PK = TRIP#uuid, SK = DAY#2026-05-15`
5. **Get All Trip Events**: `PK = TRIP#uuid, SK begins_with EVENT`
6. **Get Person Profile**: `PK = PERSON#personId, SK = PROFILE#GENERAL`
7. **Get Person Prefs for Trip**: `PK = PERSON#personId, SK = TRIP#tripId#PREFS`
8. **Get Chat History for Trip**: `PK = TRIP#uuid, SK begins_with MSG`
9. **Get Agent Prompt**: `PK = PROMPT#router, SK = VERSION#1`
10. **Get Integration Config**: `PK = INTEGRATION#google-maps, SK = CONFIG`

---

## Authentication Flow

This diagram shows the OAuth authentication flow with Cognito and social providers.

```mermaid

---
config:
  layout: elk
---
sequenceDiagram
    actor User
    participant Web as Web Client
    participant CF as CloudFront
    participant APIGW as API Gateway
    participant Cognito as Cognito User Pool
    participant Google as Google OAuth
    participant BFF as Lambda BFF
    participant DDB as DynamoDB

    User->>Web: Click "Login with Google"
    Web->>CF: GET /oauth/authorize
    CF->>Cognito: Redirect to OAuth endpoint
    Cognito->>Google: OAuth 2.0 Authorization Request
    Google->>User: Google Login Page
    User->>Google: Enter credentials
    Google->>Cognito: Authorization Code
    Cognito->>Google: Exchange code for tokens
    Google->>Cognito: ID Token + Access Token
    Cognito->>Web: Redirect with tokens
    
    Web->>Web: Store tokens in localStorage
    
    Note over Web,APIGW: Authenticated Requests
    
    User->>Web: Send chat message
    Web->>APIGW: POST /chat<br/>Authorization: Bearer JWT
    APIGW->>APIGW: Validate JWT signature
    APIGW->>Cognito: Verify token with JWKS
    Cognito->>APIGW: Token valid ✓
    APIGW->>BFF: Forward request with user context
    BFF->>DDB: Get user profile
    DDB->>BFF: User data
    BFF->>Web: Response with user data
    Web->>User: Display result
    
    Note over User,DDB: Token Refresh Flow
    
    Web->>Web: Token expired detected
    Web->>Cognito: POST /oauth2/token<br/>grant_type=refresh_token
    Cognito->>Web: New ID Token + Access Token
    Web->>Web: Update stored tokens
```

---

## Cost Breakdown by Component

| Component | Usage Model | Monthly Cost (MVP) | Annual Cost |
|-----------|------------|-------------------|-------------|
| **AgentCore Runtime** | Pay-per-use (vCPU + Memory) | $0.60 | $7.20 |
| **API Gateway** | Per request | $3.50 | $42.00 |
| **Lambda Executions** | Per invocation + duration | $8.00 | $96.00 |
| **DynamoDB** | On-Demand (reads/writes) | $5.00 | $60.00 |
| **S3 Storage** | Per GB + requests | $2.00 | $24.00 |
| **CloudFront** | Data transfer | $5.00 | $60.00 |
| **Cognito** | Per MAU (first 50K free) | $0.00 | $0.00 |
| **Bedrock Models** | Per token | $15.00 | $180.00 |
| **Google Maps API** | Per request ($200 credit) | $0.00 | $120.00 |
| **Gemini API** | Per search query | $10.00 | $120.00 |
| **WhatsApp Cloud API** | Per conversation | $5.00 | $60.00 |
| **External APIs** | Various (Booking, Aviation) | $30.00 | $360.00 |
| **Monitoring & Logs** | CloudWatch | $3.00 | $36.00 |
| **Secrets Manager** | Per secret | $0.40 | $4.80 |
| **Total** | | **$87.50** | **$1,170.00** |

**Notes:**
- Costs based on 100-200 active users during MVP phase
- Google Maps $200/month credit covers most usage
- First 1,000 WhatsApp service conversations free
- AgentCore cost validated via actual usage (not estimation)

---

## Deployment Architecture

```mermaid

---
config:
  layout: elk
---
graph LR
    subgraph "Development"
        DEV[Local Development<br/>agent/ folder]
        TEST[Unit Tests<br/>pytest]
    end
    
    subgraph "CI/CD Pipeline"
        GH[GitHub Actions]
        TF[Terraform Plan]
        LINT[Code Linting]
        SEC[Security Scan]
    end
    
    subgraph "Staging Environment"
        STAGE_APIGW[API Gateway]
        STAGE_BFF[Lambda BFF]
        STAGE_RUNTIME[AgentCore Runtime]
        STAGE_DDB[(DynamoDB)]
    end
    
    subgraph "Production Environment"
        PROD_APIGW[API Gateway]
        PROD_BFF[Lambda BFF]
        PROD_RUNTIME[AgentCore Runtime]
        PROD_DDB[(DynamoDB)]
    end
    
    subgraph "Monitoring"
        CW[CloudWatch]
        XRAY[X-Ray Tracing]
        ALARM[CloudWatch Alarms]
    end

    DEV --> TEST
    TEST --> GH
    GH --> LINT
    LINT --> SEC
    SEC --> TF
    TF -->|Approved| STAGE_APIGW
    
    STAGE_APIGW --> STAGE_BFF
    STAGE_BFF --> STAGE_RUNTIME
    STAGE_RUNTIME --> STAGE_DDB
    
    STAGE_DDB -->|QA Approved| PROD_APIGW
    
    PROD_APIGW --> PROD_BFF
    PROD_BFF --> PROD_RUNTIME
    PROD_RUNTIME --> PROD_DDB
    
    PROD_RUNTIME --> CW
    PROD_RUNTIME --> XRAY
    CW --> ALARM

    style PROD_APIGW fill:#6750A4,stroke:#21005D,color:#fff
    style PROD_BFF fill:#6750A4,stroke:#21005D,color:#fff
    style PROD_RUNTIME fill:#6750A4,stroke:#21005D,color:#fff
    style PROD_DDB fill:#6750A4,stroke:#21005D,color:#fff
```

---

**Last Updated:** January 11, 2026  
**Version:** 1.0  
**Maintained By:** n-agent-core Team

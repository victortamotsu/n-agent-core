# 1. Solution Architecture (AWS Serverless)

The architecture will be based on the **Event-Driven** pattern. The chat should not wait for the AI to "think" and consult 5 travel APIs. The chat receives the message, acknowledges receipt, and processing occurs in the background, notifying the user when complete.

## Conceptual Service Diagram

### Entry Layer (Edge & API)

- **Amazon CloudFront**: CDN for React site and static assets.
- **Amazon API Gateway**: Entry point for all requests (Web and WhatsApp Webhooks).
- **AWS WAF**: Firewall to protect against attacks.

### Orchestration Layer (The "Brain")

- **AWS Lambda (BFF - Backend for Frontend)**: Resolves website requests.
- **Amazon Bedrock AgentCore Runtime**: Where the multi-agent solution is hosted. The Router Agent decides which specialized agent to call.
- **Multi-Agent System**: Architecture with specialized agents (Router, Profile, Planner, Search, Concierge, Document, Vision) optimized for their specific tasks.
- **Amazon EventBridge**: The "mailman". When a user sends a message, an event is triggered. When Booking confirms a hotel, another event is triggered. This decouples services.

### Service Domains (Microservices via Lambda)

- **Core - Auth Service**: Cognito for authentication.
- **Core - Chat Ingestion**: Receives WhatsApp (Meta) Webhooks and WebSocket (Web). Normalizes the message and sends to EventBridge.
- **Domain - Trip Planner**: Logic for creating itineraries and persisting trip state.
- **Domain - Integrator**: The service that knows how to "speak" with external APIs (Google Maps, Skyscanner, Booking). It translates the AI's request to the partner API.
- **Domain - Concierge**: Monitors dates and triggers alerts (cron jobs via EventBridge Scheduler).
- **Domain - Doc Generator**: Generates rich HTMLs/PDFs for the panel.

### Data Layer

**DynamoDB:**
- `Users` Table - User accounts and people
- `Trips` Table (Single Table Design suggested to relate Trip ↔ Items ↔ Members)
- `ChatHistory` Table - Conversation logs
- `Profiles` Table - Person and trip profiles (data extracted by agent)
- `AgentConfig` Table - Agent prompts and integration configurations

**S3:** Storage for photos, generated PDF documents and site assets.

---

# 2. Repository Organization

For an MVP with an agile team and shared technologies (TypeScript on Front and Back), the best approach is a **Monorepo**.

## Why Monorepo?

You share "Types" (TypeScript Interfaces) between Backend and Frontend. If you change the format of the `Trip` object in the backend, the frontend "breaks" at compile time, preventing bugs in production.

## Suggested Folder Structure

Using **Turborepo** or **Nx**:

```
/n-agent-monorepo
│
├── /apps
│   ├── /web-client       (React + Vite + Material UI)
│   ├── /admin-panel      (React - Administration Panel)
│   └── /api-bff          (Node.js - Lambdas serving the front)
│
├── /agent                (Python - AgentCore Runtime)
│   ├── /src
│   │   ├── /router       (Router Agent)
│   │   ├── /profile      (Profile Agent)
│   │   ├── /planner      (Planner Agent)
│   │   ├── /search       (Search Agent)
│   │   ├── /concierge    (Concierge Agent)
│   │   ├── /document     (Document Agent)
│   │   ├── /vision       (Vision Agent)
│   │   ├── /memory       (AgentCore Memory wrapper)
│   │   ├── /tools        (Shared tools)
│   │   └── /prompts      (Prompt templates)
│   └── /tests
│
├── /packages             (Shared Libraries)
│   ├── /ui-lib           (Your M3 Design System components)
│   ├── /core-types       (TypeScript Interfaces: IUser, ITrip, IBooking, IPerson, IProfile)
│   ├── /utils            (Date formatters, validations)
│   └── /logger           (CloudWatch log standardization)
│
├── /services             (Backend Microservices - Heavy Logic)
│   ├── /trip-planner     (Lambda functions)
│   ├── /integrations     (Lambda functions for external APIs)
│   ├── /concierge        (Lambda functions for alerts)
│   └── /whatsapp-bot     (Webhook handler)
│
└── /infra                (IaC - Infrastructure as Code)
    ├── /terraform        (or CDK/Serverless Framework)
    └── /environments     (dev, staging, prod)
```

---

# 3. Integration Details

Here I detail the operation, costs and complexity of each major service you will connect.

## A. Google Maps Platform

Essential for "Grounding" (giving reality) to locations.

### Required APIs

- **Places API (New)**: To search "Restaurants in Rome" or validate if a hotel exists.
- **Maps JavaScript API**: To display the map in the user panel.
- **Directions API**: To calculate route time and distance.

### Integration

Simple REST API. The Bedrock Agent can call a Lambda that queries the Places API.

### Cost

Google gives **$200 USD** in monthly recurring credit.

- **Places**: ~$17 per 1,000 requests (expensive, use cache!)
- **Maps**: ~$7 per 1,000 loads

---

## B. Meta (WhatsApp Business API)

The main user interface.

### How it works

You will use the **WhatsApp Cloud API** (hosted by Meta, no need for your own server).

### Integration

1. You configure a **Webhook** (an API Gateway URL) in the Facebook Developers panel.
2. Every message the user sends arrives at this Webhook.
3. To reply, you send a POST to the WhatsApp API.

### Costs (24h Conversation Model)

- **Service** (User-initiated): Approx. $0.03 USD (cheaper in Brazil than USA/Europe)
- **Utility** (Check-in reminder): Approx. $0.03 USD
- **Marketing** (Offers): More expensive

**Bonus**: The first 1,000 service conversations per month are **free**.

### Integration Time

Medium (1 week). Facebook Business account validation can be bureaucratic.

---

## C. Gemini 2.0 Flash with Google Search (Grounding)

⚠️ **Architecture Decision**: We will use Gemini 2.0 Flash with **Grounding with Google Search** as the main AI for recommendations and searches.

### Why Gemini + Search?

1. **Updated Data**: Searches real-time information (prices, events, reviews)
2. **Citations**: Returns links to sources for credibility
3. **Cost-Benefit**: Gemini 2.0 Flash is cheaper than Claude for search tasks
4. **Latency**: ~2-3s vs 5-7s of Claude + Serper

### Hybrid Architecture (Chosen)

```
AWS Lambda → Vertex AI API → Gemini 2.0 + Search
Orchestrator   Google Cloud      Results + Links
```

### When to use Gemini vs Bedrock?

| Task | AI Used | Reason |
|------|---------|--------|
| Search trendy hotels | Gemini + Search | Needs fresh web data |
| Recommend restaurants | Gemini + Search | Updated reviews and rankings |
| Extract passport data (OCR) | Bedrock (Claude 3.5 Sonnet) | Better for vision |
| Generate itinerary document | Bedrock (Claude 3.5 Sonnet) | Better for long structured text |
| Casual conversation | Bedrock (AWS Nova Lite) | Cheaper, low latency |

### Integration

```typescript
// Gemini 2.0 Flash with Search Grounding
const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.0-flash-exp',
  tools: [{ googleSearchRetrieval: {} }]  // ✨ Enables Search!
});

const result = await model.generateContent({
  contents: [{
    role: 'user',
    parts: [{ text: 'What are the best restaurants near the Colosseum in Rome in 2027?' }]
  }]
});
// Response includes: text + groundingMetadata with links
```

### Cost

- **Gemini 2.0 Flash**: ~$0.10 per 1M tokens (input) + ~$0.30 per 1M tokens (output)
- **Grounding**: ~$35 USD per 1,000 Search queries
- **MVP Estimate**: ~$50-80/month for 1,000 users

### 100% AWS Alternative (Not Chosen)

We could use Claude 3.5 Sonnet on Bedrock + **Serper.dev** or **Tavily**, but:
- ❌ Higher cost (~2x)
- ❌ Higher latency (2 API calls)
- ✅ However, keeps everything on AWS bill

**Decision**: Use Gemini for MVP and re-evaluate in Phase 2.

---

## D. Booking.com / Skyscanner (Travel Aggregators)

This is the most difficult integration (**"Hard"**).

### How it works

Large players don't give open transaction APIs (booking) to startups right away.

### MVP Path: Affiliate Program

**Booking Affiliate Partner:**

1. You use their API to read availability and prices (Search Availability).
2. To complete the purchase, you generate a **"Deep Link"** with your affiliate ID.
3. User clicks, goes to Booking site and pays there.

### Cost

**Zero** (you earn commission).

### 💡 Tip

Consider using the **Amadeus for Developers** API for flights and hotels initially. It's very developer-friendly and has a free sandbox.

---

## E. Airbnb (Alternative Accommodation)

### How it works

Airbnb does not have an official public API for partners. Two approaches:

### Option 1: Ethical Web Scraping (MVP)

- Use services like **Bright Data** or **ScraperAPI** that respect robots.txt
- Extract only public data: prices, availability, photos, reviews
- **Cost**: ~$50-100/month for 10K requests
- **Limitation**: Does not allow direct booking, only deep link to site

### Option 2: Official Partnership (Post-MVP)

- Apply to **Airbnb Affiliate Program** (~3% commission)
- Limited data access via **Affiliate API**
- Approval process: 2-4 weeks

### MVP Integration

```typescript
interface AirbnbListing {
  id: string;
  title: string;
  location: { lat: number; lng: number; city: string };
  pricePerNight: number;
  currency: string;
  rating: number;
  reviewsCount: number;
  maxGuests: number;
  bedrooms: number;
  bathrooms: number;
  amenities: string[];  // ['WiFi', 'Kitchen', 'Parking']
  photos: string[];     // Photo URLs
  deepLink: string;     // Link to book on site
}
```

### Integration Time

Medium (1-2 weeks for setup and testing)

---

## F. AviationStack (Airport and Flight Data)

### Why is it essential?

For the **Concierge phase**, we need:
- Real-time flight status (delays, cancellations)
- Gate changes
- Airport information (terminals, lounges, services)

### API Used

**AviationStack** - More accessible alternative to FlightAware

### Required Features

```typescript
interface FlightStatus {
  flightNumber: string;        // "BA247"
  airline: string;             // "British Airways"
  departure: {
    airport: string;           // "GRU"
    terminal: string;          // "3"
    gate: string;              // "12"
    scheduledTime: string;
    actualTime: string;        // May differ if delayed
    delay: number;             // minutes
  };
  arrival: {
    airport: string;           // "LHR"
    terminal: string;
    gate: string;              // Updated in real-time!
    scheduledTime: string;
    estimatedTime: string;
  };
  status: 'scheduled' | 'active' | 'landed' | 'cancelled' | 'diverted';
}
```

### Integration

Simple REST API with polling every 30 minutes for flights in the next 24h.

### Cost

- **Starter Plan**: $49/month for 10K requests
- ~500 requests/day in MVP (supports 100 simultaneous trips)

### Integration Time

Fast (2-3 days)

---

# 4. Suggested Technical Roadmap

## Phase 1: Foundation (Weeks 1-4)

| Week | Deliverable | Success Criteria | Status |
|------|-------------|-----------------|--------|
| 1 | Monorepo Setup + CI/CD | Automatic Lambda "Hello World" deployment | ✅ **COMPLETE** (Jan 2-4, 2026) |
| 2 | Base Infrastructure (Terraform/CDK) | DynamoDB + S3 + API Gateway working | ✅ **COMPLETE** (Jan 6-8, 2026) |
| 3 | Auth (Cognito) + basic BFF | Functional login on frontend | 🔄 In Progress |
| 4 | WhatsApp Module | Bot responds "Hi" via Webhook | 📋 Planned |

### Week 2 Completion Summary (Jan 6-8, 2026)

**Infrastructure Deployed Successfully** ✅

- **API Gateway HTTP API**
  - Endpoint: `https://5ul5bax4s9.execute-api.us-east-1.amazonaws.com/prod`
  - API ID: `5ul5bax4s9`
  - JWT Cognito Authorizer: Configured (conditional creation)

- **Amazon Cognito User Pool**
  - Pool ID: `us-east-1_sztMWSEm4`
  - Client ID: `4e0reesiair18vo4ebfjp1d73q`
  - OAuth Domain: `https://n-agent-core-prod.auth.us-east-1.amazoncognito.com`
  - OAuth Providers: Google, Microsoft (configured)

- **Lambda BFF**
  - Function Name: `n-agent-core-bff-prod`
  - Runtime: Python 3.12
  - Integration: AgentCore Runtime (`nagent-GcrnJb6DU5`)

- **CI/CD Pipeline**
  - Conditional execution: Deploys only when `infra/` changes detected
  - Terraform: Version 1.6.0 with S3 backend
  - State: `s3://n-agent-terraform-state`
  - Locks: DynamoDB `n-agent-terraform-locks`

**Technical Challenges Resolved:**
1. ✅ Cost optimization validation (AgentCore $0.60/month, not $79)
2. ✅ JWT Authorizer issuer format (URL vs ARN)
3. ✅ Lambda reserved environment variables (AWS_REGION)
4. ✅ Terraform path resolution for Lambda archives
5. ✅ Conditional resource creation (authorizer only with Cognito)

**Next Steps for Week 3:**
- Enable API Gateway → Lambda BFF integrations
- Configure protected routes with JWT authorizer
- Test OAuth authentication flow (Google/Microsoft)
- Create basic frontend authentication UI

## Phase 2: Core AI (Weeks 5-8)

| Week | Deliverable | Success Criteria |
|------|-------------|-----------------|
| 5 | Bedrock Agent configured | Agent answers simple questions |
| 6 | Tool: Weather Consultation | AI returns weather forecast |
| 7 | Tool: Google Maps Places | AI searches and returns locations |
| 8 | Context Persistence | AI remembers trip data |

## Phase 3: Product (Weeks 9-12)

| Week | Deliverable | Success Criteria |
|------|-------------|-----------------|
| 9 | Web Panel (Dashboard) | Trip visualization working |
| 10 | Document Generation | Itinerary PDF generated |
| 11 | Booking Integration | Hotel search working |
| 12 | Notifications + Alerts | Reminders sent via WhatsApp |

## Milestone: MVP Ready for Beta Testers (Week 12)

---

# 4.1. Multi-Agent Architecture

## System Overview

n-agent uses a multi-agent architecture where each agent is specialized in a specific task, optimizing costs and performance.

```
User Input → Router Agent (Nova Micro - Classify intent)
                    ↓
        ┌───────────┴───────────┬────────────┐
        ↓                       ↓            ↓
   Profile Agent         Planner Agent   Search Agent
   (Nova Lite)           (Nova Pro)      (Gemini + Search)
        ↓                       ↓            ↓
            Shared Tools & Memory
            (AgentCore Memory | DynamoDB)
                    ↓
            AgentCore Runtime (Serverless)
```

## Specialized Agents

### 1. Router Agent (Classifier)

**Model:** Nova Micro (cheapest, low latency)  
**Responsibility:** Classify user intent and route to appropriate agent.

**Routing Categories**:
- **PROFILE**: Extract/update profile information
- **PLANNING**: Create or modify itineraries
- **SEARCH**: Search accommodations, flights, attractions
- **CONCIERGE**: Alerts, reminders, trip support
- **DOCUMENT**: Generate rich documents
- **VISION**: Image analysis (OCR, validation)
- **CHAT**: Casual conversation or general questions

### 2. Profile Agent (Extractor)

**Model:** Nova Lite  
**Responsibility:** Analyze messages and extract/persist profile information.

**Available Tools**:
- `get_person_profile` / `update_person_profile`
- `get_trip_profile` / `update_trip_profile`
- `add_preference` / `add_restriction`
- `link_person_to_trip`

**Extraction Flow**:
1. Receive user message
2. Identify mentioned entities (people, places, dates)
3. Classify information (preference, restriction, objective)
4. Validate informant permissions
5. Persist using appropriate tools
6. Confirm to user

### 3. Planner Agent (Itinerary Planner)

**Model:** Nova Pro / Gemini (complex tasks)  
**Responsibility:** Create and optimize travel itineraries.

**Available Tools**:
- `get_trip_profile_details`
- `get_all_participants_profiles`
- `create_itinerary`
- `optimize_route`
- `estimate_costs`
- `compare_versions`

### 4. Search Agent (Search)

**Model:** Gemini 2.0 Flash + Google Search Grounding  
**Responsibility:** Search real-time information.

**Available Tools**:
- `search_hotels` (Booking, Airbnb)
- `search_flights` (AviationStack)
- `search_attractions` (Google Places)
- `get_weather_forecast`
- `get_exchange_rates`

### 5. Concierge Agent (Trip Assistant)

**Model:** Nova Lite  
**Responsibility:** Monitor active trips and provide support.

**Available Tools**:
- `get_flight_status`
- `check_weather_alerts`
- `send_reminder`
- `get_emergency_contacts`
- `translate_text`

### 6. Document Agent (Document Generator)

**Model:** Claude 3.5 Sonnet (best for structured text)  
**Responsibility:** Generate rich documents.

**Available Tools**:
- `generate_itinerary_html`
- `generate_itinerary_pdf`
- `generate_checklist`
- `generate_voucher`
- `generate_financial_report`

### 7. Vision Agent (Image Processing)

**Model:** Claude 3.5 Sonnet (best for vision)  
**Responsibility:** Process and analyze images.

**Available Tools**:
- `extract_passport_data` (OCR)
- `extract_ticket_data`
- `validate_document_photo`
- `translate_menu_photo`

## Cost Optimization

| Agent | % Calls (est.) | Cost/1M tokens | Impact |
|-------|---|---|---|
| Router | 100% | $0.035 (Nova Micro) | Low |
| Profile | 30% | $0.06 (Nova Lite) | Low |
| Search | 25% | $0.10 (Gemini Flash) | Medium |
| Planner | 15% | $0.80 (Nova Pro) | Medium |
| Concierge | 20% | $0.06 (Nova Lite) | Low |
| Document | 5% | $3.00 (Claude) | Low |
| Vision | 5% | $3.00 (Claude) | Low |

**Result**: ~76% cost reduction compared to using Claude for all tasks.

### ⚠️ AgentCore Runtime Pricing - CRITICAL UPDATE (Jan 2026)

**Initial Assumption (WRONG):** $79/month for 24/7 deployment  
**Reality (VERIFIED):** ~$0.60/month with consumption-based billing

**AWS Bedrock AgentCore Runtime Pricing:**
- **vCPU**: $0.0895 per vCPU-hour
- **Memory**: $0.00945 per GB-hour
- **Idle Timeout**: 30 minutes (auto-shutdown when inactive)
- **Billing Model**: Pay only when agent is actively processing requests

**Real Usage Data** (Jan 2-8, 2026):
- vCPU: 0.01 hours/day
- Memory: 0.75 GB-hours/day
- Cost: ~$0.02/day = **$0.60/month**

**Key Insight**: AgentCore is NOT billed 24/7. It auto-shuts down after 30min of inactivity and only charges during active processing time. This makes it extremely cost-effective for serverless architectures.

**Cost Validation Process**:
1. Check real usage via Cost Explorer (not just pricing tables)
2. Read service documentation about lifecycle/billing model
3. Verify idle timeout and auto-shutdown behavior
4. NEVER assume "deployed" = "running 24/7"

---

# 5. Database Design

## Part 1: DynamoDB Modeling (NoSQL)

For AWS and Serverless architecture, the best practice is **Single Table Design** for main data, optimizing quick dashboard reads, and a separate table for Chat History (due to high write volume).

### Table 1: NAgentCore (Master Data)

This table stores Users, Trips, Itinerary and Reservations.

#### Access Patterns and Entities

- **User**
  - PK: `USER#<email>`
  - SK: `PROFILE`
  - Attributes: `name`, `whatsapp_id`, `preferences` (JSON), `docs_status`

- **Trip**
  - PK: `TRIP#<uuid>`
  - SK: `META#USER#<email>#DATE#<start>`
  - Attributes: `trip_name`, `status` (PLANNING/CONCIERGE), `total_budget`, `currency`

- **Participant**
  - PK: `TRIP#<uuid>`
  - SK: `MEMBER#<email>`
  - Attributes: `role` (ADMIN/VIEWER), `passport_expiry`, `dietary_restrictions`

- **Itinerary Day**
  - PK: `TRIP#<uuid>`
  - SK: `DAY#YYYY-MM-DD`
  - Attributes: `day_summary`, `forecast`, `focus_city`

- **Event / Reservation**
  - PK: `TRIP#<uuid>`
  - SK: `EVENT#<timestamp>`
  - Attributes: `type` (FLIGHT/HOTEL/TOUR), `provider` (Booking), `cost`, `payment_status`, `file_url` (S3)

### Table 2: NAgentProfiles (Person and Trip Profiles)

Stores profiles extracted by the agent during conversations.

#### Profile Entities

- **Person Profile**
  - PK: `PERSON#<personId>`
  - SK: `PROFILE#GENERAL`
  - Attributes: `name`, `age`, `preferences` (JSON), `restrictions` (JSON), `documents_status`

- **Person Preferences per Trip**
  - PK: `PERSON#<personId>`
  - SK: `TRIP#<tripId>#PREFS`
  - Attributes: `desired_activities` (array), `places_of_interest` (array), `local_restrictions` (array)

- **Trip Profile**
  - PK: `TRIP#<tripId>`
  - SK: `PROFILE#GENERAL`
  - Attributes: `objectives` (JSON), `budget`, `travel_style`, `accommodation_preferences`, `transport_preferences`

### Table 3: NAgentConfig (Configuration and Prompts)

Stores agent prompts and integration configurations, parameterizable via admin portal.

#### Configuration Entities

- **Agent Prompt**
  - PK: `PROMPT#<agentType>`
  - SK: `VERSION#<version>`
  - Attributes: `content`, `variables`, `createdBy`, `createdAt`, `changelog`

- **Integration Configuration**
  - PK: `INTEGRATION#<integrationName>`
  - SK: `CONFIG`
  - Attributes: `apiKey` (encrypted reference to Secrets Manager), `endpoint`, `rateLimits`, `cacheTTL`

### Table 4: NAgentChatHistory (Conversation Logs)

Separated for archival (TTL) and independent scalability.

- **Partition Key (PK):** `TRIP#<uuid>`
- **Sort Key (SK):** `MSG#<timestamp_iso>`

---

# 6. Rich Document System

## Overview

The document system is a product differentiator. We won't create a "Google Drive inside", but a **system of documents generated on-demand** with rich visualization.

## Document Architecture

```
Bedrock Agent → Doc Generator → S3 → CloudFront → Signed URL
(decides)       Lambda + React   (store)  (distribute)
```

## Document Types

| Type | Format | Use |
|------|--------|-----|
| **Itinerary Summary** | HTML interactive | Share via link |
| **Complete Itinerary** | PDF | Download/print |
| **Checklist** | JSON + React | Interactive panel |
| **Voucher/Ticket** | PDF with QRCode | Send via WhatsApp |
| **Financial Report** | HTML + charts | Expense dashboard |
| **Travel Map** | HTML + Google Maps | Geographic visualization |

---

**Last Updated**: January 2026  
**Language**: English (Translated from Portuguese)

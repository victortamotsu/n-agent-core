# n-agent - Personal Travel Assistant

We are creating a platform for creating and configuring a personal agent that will have the ability to connect to services and help with the personal and work organization of a person in productive age.

# General Idea

A platform service that sells packages of a personal assistant for organizing activities in travel schedules.

The goal is to support ordinary people to understand, structure, and organize their travel. It will also offer tourism-related services within the platform.

---

# Glossary and Definitions

## Main Entities

| Term | Definition |
|------|------------|
| **Trip** | A travel event with start and end dates, destinations, calendar, documents, etc. A trip can have one or more people who are part of it (the participants). A trip must be created and always linked to a paying user account. |
| **Trip Participant** | People who are part of a trip. They do not necessarily need to have a user account; they can be people indicated by the trip administrator who do not yet have an account, being uniquely identified in the system to later have an account linked. |
| **Person** | Represents a natural person. This object serves to link a mention of a person to an activity or a trip. A person may or may not have a linked user account in the system. Example: Victor is the person with a paying user account who created the trip and registered Fabiola and Vicenzo as people who will participate in the trip. Vicenzo has a user account linked by email, while Fabiola does not exist in the system yet and can be invited by email or shared link. |
| **User Account** | A system account linked to a person in a 1:1 relationship. The user account has access to the web interface and gives the possibility to contract services within the platform. The user account is in fact a user with an email and/or WhatsApp linked and validated. |
| **Paying Account** | A user account that contracted one of the platform's paid plans. To become a paying account, it is necessary to complete the user registration with address, CPF, credit card. |

## Profiles and Context

| Term | Definition |
|------|------------|
| **Person Profile** | Data related to a person. The profile is information provided by users of a trip and persisted in the database by the AI agent to make decisions and provide options and suggestions. For example: User Victor mentioned that person Fabiola is 42 years old, that she likes cultural attractions and wants to visit Notre-Dame Cathedral during the trip. This information should be compiled by the agent and stored as part of Fabiola's person profile in different sections (age and taste in the properties section, desire to visit in the section corresponding to the trip). **Note**: The informant needs to be a user of the same trip for the information to be considered valid. |
| **Trip Profile** | Data related to a trip. The profile is information provided by users and persisted in the database by the AI agent for decision making and providing trip options. This information should be compiled by the agent and stored as part of the trip profile. |

---

# Business Model and Monetization

## Plans and Pricing

| Plan | Price | Limits | Features |
|------|-------|--------|----------|
| **Free** | $0 | 1 trip/year, up to 4 people | Phases 1-2 (Knowledge + Basic Planning), no concierge |
| **Planner** | $49/trip | Unlimited people, 1 active trip | Phases 1-3, rich documents, itinerary versioning |
| **Concierge** | $149/trip | Unlimited people, 3 active trips | All phases, real-time alerts, priority support |
| **Family (Annual)** | $399/year | Up to 5 trips/year, unlimited people | Everything from Concierge + partner discounts |

## Additional Revenue Sources

1. **Affiliate Commissions**: 3-8% on reservations via Booking/Airbnb/Skyscanner links
2. **Premium Services**: Memory album printing ($89-199)
3. **B2B Partnerships**: Travel agencies using the platform white-label
4. **Travel Insurance Upsell**: Commission on travel insurance sold via platform

## MVP Success KPIs

| Metric | 6-month Target | 12-month Target |
|--------|----------------|-----------------|
| Registered Users | 1,000 | 5,000 |
| Free → Paid Conversion | 8% | 12% |
| Post-trip NPS | > 40 | > 50 |
| Retention (2nd trip) | 30% | 45% |
| Average Revenue per Paying User | $80 | $120 |

---

# Functional Requirements

## User Interface

### Website Interaction

We will have a public website for:

1. Product disclosure
2. Service contracting
3. User control panel and viewing rich content response documents from the AI (see more details below)
4. Partner/supplier control panel
5. Administrator control panel
6. Dynamic Help Center and FAQ: An area where common questions about AI usage are answered automatically.

Users will be able to receive AI responses in the form of reports with rich content, such as maps, links, tables, price information, etc. We will use the website structure to display this content to the user.

[Question] Should we have a mobile app to capture location, giving more information about the trip for the agent? This way, we get more context. [Todo] If we follow this path, how do we handle data privacy?

### Standard User Interaction

User inputs will occur exclusively via chat with the "n-agent" AI and via web interface for small routines (such as completing items in task lists). The chat will occur in two interfaces: **web interface chat** (MVP) and WhatsApp chat (post-MVP, awaiting Meta approval). Both interfaces must support the following input types:

> **📝 MVP Note**: WhatsApp integration has been moved to post-MVP as Meta has not yet released API access. See [MVP_SCOPE_UPDATE.md](./fases_implementacao/MVP_SCOPE_UPDATE.md)

- text (the most common, with support for emoticons, links and MD formatting)
- images
- audio
- location
- documents

Special interfaces:

- The user can forward emails (e.g., booking confirmations) directly to a bot email. Trip recognition will be done by context (user email address and action date described).
- The user can forward messages from other users via WhatsApp forwarding to the bot to save records. For example: "I made the reservation at The Edge observatory for 23/05 for all of us".

Users can receive outputs as:

- text (with support for emoticons, links and formatting)
- location (a link to open the standard location application on the phone, such as Google Maps or Apple Map)
- Link to a rich document, generated and displayed in a web interface with the response to the user's request.
- Task lists or questions
- Quick Action Buttons: On WhatsApp and Web, offer buttons like "Confirm", "See More Details", "Change Itinerary" to speed up interaction and avoid typing.

## Agent Integrations and Capabilities

We will divide this project into phases, the current phase being the product MVP. In this first phase the agent must have the following capabilities:

1. **Knowledge phase** of the client and the trip: this is the phase where we assemble a dossier of information about the trip, companions, objectives (personal and group), destinations, desired itinerary, budget and dates. This information must be persisted and should permeate all subsequent phases.
    - [Additional Requirement] Risk Profiling and Accessibility: Identify dietary restrictions, allergies, mobility difficulties (accessibility) or fears (e.g., fear of flying) of members.
    - Understand restrictions on places and attractions by person or for the entire group. For example: fear of closed spaces, fear of heights. This should not limit suggestions, but should help rank options.

2. **Trip planning phase**: using the information from the previous step, we should study the requirements to achieve the trip's objectives. We should present a summary of attractions and a detailed breakdown of costs and efforts to achieve objectives, with timelines and risks, to assist in decision making about itineraries. This is the most complicated phase because the trip may still be in a moment of defining the number of destinations, number of people, etc. We should use all available tools to reduce costs and provide experiences consistent with user objectives.
    - [Additional Requirement] Itinerary Versioning: The system must allow saving "Version A (Economy)" and "Version B (Comfort)" for side-by-side comparison. It also needs to keep versions of itinerary changes to help understand motivations for itinerary changes.
    - [Question] Would it be possible to create an itinerary where itinerary administrators receive suggestions from other users and evaluate suggestions to then add to the base itinerary? For example: the son suggests adding a library visit. The father receives this change, with the AI calculating the impacts of this change on the itinerary.

3. **Service contracting and trip management phase**: this is the phase where we will start to concretize the trip, organizing the right moments to contract services and organize trip information, always being careful to review each aspect of the trip to anticipate problems to prevent inconveniences to users. We will save each aspect of the trip: schedule, places, tickets, costs, documents, information about visit locations, contracted services, etc.
    - [Suggestion] Offline Voucher Management: Ensure that all essential PDFs and QRCodes are sent to WhatsApp, Google Drive, or email for access even without internet.

4. **Trip execution phase (concierge)**: at this phase we have all services defined and the trip has started! We will assist from the beginning with itinerary summaries, messages with reminders and information, chat to answer questions or assist in case of incidents. The AI would contact shortly before each event to provide insights and information to assist at key moments, such as the link to a ticket shortly before entering an attraction or information about the boarding gate and how to get there.
    - [Critical Requirement] Offline/Low Connection Mode: The AI should know when the user may be without internet and send information packages (next day summary) in advance via WhatsApp.
    - [Additional Requirement] Intelligent Time Zone: The agent should proactively consider jet lag and adjust activity suggestions on the first day, in addition to knowing the exact local time for sending alerts.

6. **Memory organization phase**: here the platform will work on assembling trip information, organizing albums, map locations, trip information to preserve the user's memory and their group.

To realize these capabilities, we must deliver the following tools to the platform:

- A set of agents capable of working with the necessary work tools to serve the platform and perform critical analysis of the user's request.
- Shared platform tools: quick context, place to store persistent data, tool to store completed tasks for AI control, AI selection
- Map tools: Google Maps
- Recommendation and ranking tools: TripAdvisor, Google Maps, Booking, Travel Blogs from Google Search
- Accommodation tools: AirBnB, Booking, Kayak, Trivago
- Flight tools: Kayak, Google Flights, Sky Scanner, ViajaNet, MaxMilhas
- Travel rules for countries: Sherpa
- Integration with airports to identify flight status
- Tips from trending sources: Instagram, Youtube
- Integrations with
    - Whatsapp for user interface,
    - Google Maps for presentation/creation of visit markers,
    - Integration with Google Calendar or Outlook for trip schedule management,
    - Integration with notes and task apps, such as Google Keep, Microsoft Todo and Evernote to create lists with tasks for group members.
    - Integrations with weather service and YouTube channels with information for travelers at the time visited
    - [New Integration] Currency Exchange: API for real-time currency quotes (e.g., Open Exchange Rates) to help with purchase decisions.
    - [New Integration] Translation Services: Integration with DeepL or Google Translate API for automatic menu translation via photo or local negotiations.
    - [New Integration] Weather and Alerts: Weather APIs (e.g., OpenWeather) to warn about rain and suggest alternative indoor itineraries automatically.

---

# Multi-Agent Architecture

## Overview

The "agent" n-agent is actually a **multi-agent solution**, with nodes specialized and optimized for specific tasks needed for the platform to serve its users.

## Specialized Agents

| Agent | Responsibility | Suggested Model |
|-------|---|---|
| **Router Agent** | Classifies user intent and routes to specialized agent | Nova Micro |
| **Profile Agent** | Extracts and persists person and trip profile information during conversations | Nova Lite |
| **Planner Agent** | Creates and optimizes travel itineraries | Nova Pro / Gemini |
| **Search Agent** | Searches real-time information (accommodations, flights, attractions) | Gemini + Search |
| **Concierge Agent** | Monitors active trips and triggers alerts/reminders | Nova Lite |
| **Document Agent** | Generates rich documents (itineraries, vouchers, reports) | Claude 3.5 Sonnet |
| **Vision Agent** | Processes images (OCR of passports, documents) | Claude 3.5 Sonnet |

## Agent Tools for Profile Management

The agent should have the following tools to manage context and profiles:

### Reading Tools (Context)

| Tool | Description |
|------|---|
| `get_trip_profile_summary` | Gets a compact summary of the trip profile (destinations, dates, budget, status) |
| `get_trip_profile_details` | Gets detailed trip data (itinerary, reservations, documents, tasks) |
| `get_person_profile_summary` | Gets summary of a person's profile (preferences, restrictions, documents) |
| `get_person_profile_details` | Gets detailed data of a trip participant |
| `get_trip_participants` | Lists all trip participants with their roles |
| `get_conversation_context` | Gets recent conversation context for continuity |

### Writing Tools (Persistence)

| Tool | Description |
|------|---|
| `update_trip_profile` | Updates trip profile information (destinations, dates, preferences) |
| `update_person_profile` | Updates a person's profile information (age, preferences, restrictions) |
| `add_trip_preference` | Adds a preference or objective to the trip |
| `add_person_preference` | Adds a preference or restriction to a person |
| `add_trip_activity` | Adds a desired activity to the trip profile |
| `link_person_to_trip` | Links a person as a trip participant |

### Extraction and Persistence Flow

During conversation, the agent should:

1. **Analyze** each user message to identify relevant information
2. **Classify** information into categories:
   - Person profile data (age, preferences, restrictions)
   - Trip profile data (destinations, dates, budget, objectives)
   - Specific activities and desires
3. **Validate** if the informant has permission to add data (same trip participant)
4. **Persist** information using appropriate tools
5. **Confirm** to the user that information has been recorded

---

# Technical Requirements

## Infrastructure and Architecture

- The entire platform must be defined with IaC and 100% AWS infrastructure, with the largest amount of serverless services
- We will use a Lambda + Bedrock Agents microservices structure to make the environment pay-as-you-go, focusing on cost optimization vs advantages of implemented solutions
- DynamoDB database, with modeling at your discretion
- ~~[Suggestion] Cache Strategy (ElastiCache/Redis)~~: **REMOVED** - AgentCore Memory already implements native session caching. See [MVP_SCOPE_UPDATE.md](./fases_implementacao/MVP_SCOPE_UPDATE.md)
- Backend in node, with frontend in React
- Visual interface respecting Material Design M3 Expressive
- BFF for control and information orchestration
- Specific endpoint for integrations with third-party applications
- Solution agnostic to AI model for flow processing, using a mixture of AWS Nova, Gemini and Claude for tasks
- [Security Requirement] Privacy and LGPD/GDPR: As the platform handles sensitive data (Passports, cards, minor data), it is crucial to implement encryption at rest and clear data retention and deletion policies.

## Website

- Have a public domain for platform promotion and customer acquisition, with integration with secure payment solution
- Control panel for customers, with an account management menu, payment methods, access creation for travel group participants
    - [Feature] Group Permission Management: Define who can change the itinerary (e.g., Father/Mother) and who can only view (e.g., Children/Friends), to prevent someone from canceling a hotel by mistake.
- Control panel for environment management, used by administrators
- Control panel for third parties, such as suppliers and partners
- For the customer panel, have a document system with rich formatting, like Evernote, where content is presented in a filing system, where documents can be shared or accessible via a link generated by the AI

## Administration Panel (MVP)

The administration panel is a web interface for managing the environment, with restricted access to platform administrators. The platform must support **multiple administrators**.

### Admin Panel Features

| Feature | Description | MVP |
|---------|---|---|
| **Prompt Management** | Screen for defining and editing agent prompts, with versioning. Allows for prompt improvements in a controlled and audited way. | ✅ |
| **Integration Configuration** | List of configuration parameters for each integration (API keys, endpoints, limits) to expedite parameterization | ✅ |
| **Admin User Management** | Ability to add/remove platform administrators | ✅ |
| **Monitoring** | Dashboard of usage metrics, costs and errors | ✅ |
| **Audit Logs** | History of changes in configurations and prompts | ✅ |

### Prompt Management (Versioning)

Agent prompts should be stored in DynamoDB, with the intention of being parameterized via the administration portal:

```typescript
interface AgentPrompt {
  promptId: string;           // Ex: "router-agent-system-prompt"
  agentType: string;          // Ex: "ROUTER", "PLANNER", "PROFILE"
  version: number;            // Incremental version
  content: string;            // Prompt content
  variables: string[];        // Replaceable variables (ex: {{tripContext}})
  isActive: boolean;          // If this version is active
  createdBy: string;          // Admin who created
  createdAt: string;          // Creation timestamp
  changelog: string;          // Description of changes
}
```

### Integration Configuration

| Integration | Configurable Parameters |
|------|---|
| **Google Maps** | API Key, Request Limits, Cache TTL |
| **Gemini** | API Key, Model, Temperature, Max Tokens |
| **Bedrock** | Region, Model IDs, Max Tokens per agent |
| **WhatsApp** | Phone Number ID, Access Token, Webhook Secret |
| **Booking** | Affiliate ID, API Key |
| **AviationStack** | API Key, Rate Limits |
| **OpenWeather** | API Key, Units (metric/imperial) |

---

**Last Updated**: January 2026  
**Language**: English (Translated from Portuguese)

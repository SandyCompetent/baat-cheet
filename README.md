# ChatBud — Stateful Multi-Agent Workspace & Persona Hub

[![Flutter](https://img.shields.io/badge/Flutter-3.33+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase AI](https://img.shields.io/badge/Firebase%20AI-Gemini%203.x-FFA000?logo=firebase)](https://firebase.google.com/docs)
[![Tests](https://img.shields.io/badge/Tests-101%20Passed-10B981)](#testing)
[![License: MIT](https://img.shields.io/badge/License-MIT-4F46E5.svg)](LICENSE)

**ChatBud** is a production-grade, stateful multi-agent messaging workspace built with **Flutter**, **Firebase AI (`firebase_ai`)**, and a **100% free serverless architecture**.

Going beyond standard single-turn LLM wrappers, ChatBud features an **Open-Source Persona Hub**, an **on-device Two-Layer Memory Engine** powered by vector cosine similarity, **Dynamic Relationship & Mood States**, and **Multi-Agent Group Channels**.

---

## 👥 Quick-Start for Non-Technical Users (HR, Recruiters, Managers)

You do **not** need to install Flutter, Android Studio, or any developer tools to experience ChatBud:

1. **🌐 Instant Live Web Demo**: Open **[https://chatbud-official.web.app](https://chatbud-official.web.app)** in your browser (Safari, Chrome, Edge).
2. **🚀 Instant Guest Mode**: Start chatting immediately with zero registration or login required.
3. **🎯 Real-World Scenarios to Try Right Now**:
   - **Mock Interview Practice**: Select **Harper**, tap *"Conduct a behavioral mock interview for a Product Manager"*, and practice answering with the STAR method.
   - **Drafting Job Descriptions**: Ask Harper to *"Draft an inclusive job description for a Senior Talent Partner"*.
   - **Executive Communication**: Select **Aria**, tap *"Polish this draft email to leadership requesting budget"*.
   - **Resume Enhancement**: Select **Leo**, tap *"Rewrite this resume bullet point to highlight measurable impact"*.
   - **1-Tap Templates**: Open the **Persona Hub**, tap **+**, and tap any 1-tap preset (`[🎯 HR Recruiter]`, `[⚡ Executive Assistant]`, `[📄 Resume Coach]`, `[✍️ Copywriter]`) to instantly create a tailored AI agent without prompt engineering.
   - **Export Deliverables**: Tap the **Export icon** (`Share`) in the top right of any chat to copy your conversation transcript as clean plain text or Markdown directly into Slack, Google Docs, or Notion.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │          ChatBud Flutter App         │
                      │     (Soft Minimalist Slate UI)       │
                      └──────────────────┬───────────────────┘
                                         │
             ┌───────────────────────────┼───────────────────────────┐
             ▼                           ▼                           ▼
  ┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
  │   PersonaService    │     │    MemoryService    │     │   GeminiService     │
  │ • Curated Personas  │     │ • Working Context   │     │ • Firebase AI SDK   │
  │ • 1-Tap Presets     │     │ • Pure Dart Cosine  │     │ • gemini-3.1-lite   │
  │ • Category Filtering│     │ • Episodic Retrieval│     │ • gemini-3.8-flash  │
  └──────────┬──────────┘     └──────────┬──────────┘     └──────────┬──────────┘
             │                           │                           │
             └───────────────────────────┼───────────────────────────┘
                                         ▼
                      ┌──────────────────────────────────────┐
                      │             ChatService              │
                      │ • Dynamic Prompt Injection           │
                      │ • Group @Persona Mentions            │
                      │ • Firestore + Offline Fallback       │
                      └──────────────────────────────────────┘
```

---

## Standout Features

### 1. Open-Source Persona Hub
- **Curated Multi-Agent Roster**:
  - **Harper** (HR & Talent Coach): Behavioral STAR mock interviews, candidate scorecards, competitive job descriptions.
  - **Aria** (Workplace Productivity Assistant): Executive email polish, meeting agendas, action items, executive summaries.
  - **Leo** (Career & Resume Advisor): High-impact resume rewriting, promotion strategy, salary negotiation.
  - **Athena** (Senior System Architect): Scalable distributed systems, design patterns, clean architecture.
  - **Cipher** (Cybersecurity & AppSec Specialist): Threat modeling, vulnerability auditing, OWASP/App Check guardian.
  - **Marcus** (Stoic Philosopher & Executive Coach): Perspective shifting, resilience, decision-making under high pressure.
  - **Nova** (Creative Brand Strategist & Storyteller): Compelling hooks, copywriting, brand identity.
- **1-Tap Preset Persona Authoring**: Tap any role template (HR Recruiter, Executive Assistant, Copywriter, Customer Support) to instantly generate personas without writing prompt code.
- **Dynamic Starter Chips**: Context-aware suggested prompts displayed above the composer and in empty chat states to eliminate "blank page" syndrome.
- **Transcript Export**: Export any conversation transcript to the clipboard as formatted plain text or Markdown for immediate workplace use.

### 2. Two-Layer Memory Engine (100% Free Tier)
- **Layer 1 (Working Context)**: Sliding multi-turn conversation history cached in memory and `StorageService` (`SharedPreferences`).
- **Layer 2 (Episodic Long-Term Memory)**:
  - **Client-Side Vector Search**: High-speed cosine distance calculated directly in pure Dart (<1ms latency, \$0.00 cloud cost).
  - **Semantic Overlap & Fact Extraction**: Captures user preferences, projects, and goals automatically from conversation flows.
  - **Memory Vault UI**: Full user control to view, add, or delete recalled memories transparently.

### 3. Dynamic Mood & Relationship State
- Personas evolve based on interaction history:
  - **Trust Level (1 to 10)**: Progresses with conversation depth.
  - **Persona Mood**: Adapts dynamically (e.g. *Analytical*, *Supportive*, *Direct*, *Inspiring*).
  - **Context-Injected Prompting**: System instructions seamlessly combine base behavior, recalled user facts, and relationship metrics.

### 4. Multi-Agent Group Dynamics
- Group channels support multi-persona collaboration.
- Mentioning `@Athena`, `@Cipher`, `@Marcus`, or `@Nova` orchestrates autonomous turns, allowing different personas to debate and advise on complex topics.

### 5. Production Firebase AI SDK (`firebase_ai`)
- Integrates Google's modern Gemini 3.x developer stack (`gemini-3.1-flash-lite` and `gemini-3.8-flash`).
- Dynamic model resolution protects against breaking `404 Not Found` errors caused by upstream model retirements.
- Completely free serverless tier without mandatory Blaze Cloud Functions or external vector DB subscriptions.

### 6. Production Security & Offline Resilience
- Hardened `firestore.rules` for authenticated users.
- Guest and unauthenticated chat operates completely offline with zero `PERMISSION_DENIED` errors.
- App Store & Google Play UGC compliance: user blocking and abuse reporting workflows.
- Soft Minimalist Slate theme with accessible color tokens (`SlateTokens`).

---

## Project Structure

```text
lib/
├── main.dart                      # App entry point, theme mode, and tabs
├── route_generator.dart           # Declarative named routes
├── theme_data.dart                # Soft Minimalist Slate design system
├── project_meta_data.dart         # App metadata and branding constants
└── src/
    ├── models/
    │   ├── chat_message.dart      # Chat messages with status and bookmarks
    │   ├── conversation.dart      # Conversation metadata with personaId support
    │   ├── group_chat.dart        # Group channels with membership counts
    │   ├── persona.dart           # Persona schema with curated presets
    │   ├── relationship_state.dart# Trust levels, mood, and interaction counters
    │   └── user_memory.dart       # Episodic facts with vector embeddings
    ├── services/
    │   ├── chat_service.dart      # Real-time message streaming & @mention router
    │   ├── gemini_service.dart    # Firebase AI SDK integration
    │   ├── group_service.dart     # Firestore-backed group management
    │   ├── memory_service.dart    # On-device cosine similarity & memory retrieval
    │   └── persona_service.dart   # Persona hub repository & active agent state
    ├── core/
    │   ├── app_state.dart         # Global auth and theme state
    │   └── storage_service.dart   # Offline persistence with SharedPreferences
    └── screen/
        ├── message_page.dart      # Primary chat feed with search and filter chips
        ├── persona_hub_screen.dart# Persona catalog, creation modal & memory vault
        ├── conversation_screen.dart# Real-time token streaming chat interface
        ├── group_page.dart        # Group discovery and creation
        ├── list_page.dart         # Saved / bookmarked messages
        ├── contact_page.dart      # Profile, theme toggles, and legal dialogs
        └── splash_screen.dart     # Brand intro
test/                              # 101 unit and widget tests
```

---

## Testing

ChatBud includes a comprehensive test suite with **101 automated tests**:

```bash
# Run all tests
flutter test

# Run code analysis
flutter analyze
```

---

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/torvence/chatbud.git
   cd chatbud
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on your device or browser**:
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on Android / iOS
   flutter run
   ```

---

## License

This project is licensed under the [MIT License](LICENSE).

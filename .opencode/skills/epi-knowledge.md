# Eburon AI API Knowledge Base for Voice Agent Integration

**File:** `api-eburon-ai.md`
**Base URL:** `https://api.eburon.ai`
**Primary use case:** realtime or near-realtime voice agents using Eburon as the language/reasoning layer.
**Last updated:** 2026-06-17

---

## 1. Purpose

This knowledge base explains how to integrate `https://api.eburon.ai` into a voice-agent stack where audio input is transcribed, passed to Eburon for reasoning, and converted back into speech.

Use this document for:

- inbound customer-support agents
- outbound voice callers
- appointment schedulers
- concierge or multilingual assistants
- internal command-and-control voice agents
- SIP/PBX, WebRTC, or browser microphone voice pipelines

Recommended architecture:

```text
Caller / Mic
  -> Voice Activity Detection
  -> Streaming STT
  -> Turn Manager
  -> Eburon AI API
  -> Tool Router / Business Logic
  -> TTS
  -> Caller / Speaker
```

---

## 2. Public verification status

As of 2026-06-17:

- `https://api.eburon.ai/` root page resolves to a default hosting page, so do not treat the root path as API documentation.
- Indexed Eburon API documentation describes the API as serving endpoints from `https://api.eburon.ai`, with models discovered automatically from the local inference server.
- Eburon's public site positions the platform as a sovereign voice intelligence platform for hyper-realistic voice agents, on-prem/private-cloud deployment, sub-500ms interactions, 120+ languages, custom personas, API integrations, and enterprise security/compliance controls.
- Public Eburon repositories show Ollama-oriented infrastructure patterns, including an `OLLAMA_URL` environment variable, so this KB assumes an Ollama-compatible or Ollama-adjacent API surface unless the deployed Eburon gateway exposes a stricter custom schema.

**Implementation rule:** verify the live endpoint contract before production. This KB gives the preferred integration pattern and fallback discovery probes.

---

## 3. Environment variables

Use environment variables instead of hardcoding the endpoint and credentials.

```bash
EBURON_BASE_URL="https://api.eburon.ai"
EBURON_API_KEY="replace-with-your-eburon-key-if-required"
EBURON_MODEL="orbit"      # backend alias; map to the real deployed model internally
EBURON_TIMEOUT_MS="30000"
EBURON_STREAM="true"
```

Recommended model-alias policy:

```text
Frontend-visible aliases only:
- codemax  -> coding / structured reasoning model
- orbit    -> general voice-agent brain
- echo     -> fast conversational model
- vision   -> multimodal model if image input is enabled

Backend maps aliases to actual deployed model IDs.
```

---

## 4. Endpoint discovery checklist

Because the public root is not self-documenting, the integration should probe likely model-list endpoints during deployment.

Try these in order:

```bash
curl -sS "$EBURON_BASE_URL/v1/models" \
  -H "Authorization: Bearer $EBURON_API_KEY"

curl -sS "$EBURON_BASE_URL/api/tags" \
  -H "Authorization: Bearer $EBURON_API_KEY"

curl -sS "$EBURON_BASE_URL/models" \
  -H "Authorization: Bearer $EBURON_API_KEY"
```

Expected successful outcomes may look like one of these shapes:

```json
{
  "object": "list",
  "data": [
    { "id": "orbit", "object": "model" }
  ]
}
```

```json
{
  "models": [
    { "name": "orbit", "modified_at": "2026-06-17T00:00:00Z" }
  ]
}
```

**Production rule:** cache the model list for a short period, but do not assume the model inventory is static. Eburon docs indicate models are locally served and automatically discovered.

---

## 5. Authentication pattern

Use a Bearer token header when the gateway requires authentication.

```http
Authorization: Bearer <EBURON_API_KEY>
Content-Type: application/json
```

If the gateway is private/on-prem and configured without API-key auth, keep the same client interface and set `EBURON_API_KEY` to an empty string. The client should omit the `Authorization` header when the key is empty.

TypeScript helper:

```ts
export function eburonHeaders(apiKey?: string): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (apiKey && apiKey.trim().length > 0) {
    headers.Authorization = `Bearer ${apiKey}`;
  }

  return headers;
}
```

---

## 6. Preferred voice-agent request shape

For a voice agent, use a chat-style request rather than a raw prompt whenever possible.

The model needs:

- a stable system persona
- conversation history
- the latest user utterance
- tool/function instructions
- low-latency generation settings
- optional structured output rules

Canonical message stack:

```json
[
  {
    "role": "system",
    "content": "You are Ayla, a concise and calm voice agent. Speak naturally. Ask one question at a time. Never mention internal tools."
  },
  {
    "role": "user",
    "content": "Hi, I need to move my appointment."
  }
]
```

---

## 7. Native Ollama-style chat endpoint

Use this if Eburon exposes an Ollama-compatible route.

```bash
curl -sS "$EBURON_BASE_URL/api/chat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -d '{
    "model": "orbit",
    "messages": [
      {
        "role": "system",
        "content": "You are Ayla, a concise voice agent. Answer in short spoken sentences."
      },
      {
        "role": "user",
        "content": "Can you help me reschedule my flight?"
      }
    ],
    "stream": false,
    "options": {
      "temperature": 0.4,
      "num_predict": 180
    }
  }'
```

Typical non-streaming response shape:

```json
{
  "model": "orbit",
  "created_at": "2026-06-17T00:00:00Z",
  "message": {
    "role": "assistant",
    "content": "Of course. What is your booking reference?"
  },
  "done": true
}
```

### Native streaming behavior

Ollama-style streaming usually returns newline-delimited JSON chunks.

Example chunk:

```json
{"message":{"role":"assistant","content":"Of"},"done":false}
```

Final chunk:

```json
{"done":true,"done_reason":"stop"}
```

For voice, forward partial text to TTS only after a stable phrase boundary:

- punctuation: `.`, `?`, `!`, `;`
- length threshold: 8-18 words
- silence threshold: 150-300 ms without new tokens

---

## 8. OpenAI-compatible chat endpoint

Use this if Eburon exposes an OpenAI-compatible gateway.

```bash
curl -sS "$EBURON_BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -d '{
    "model": "orbit",
    "messages": [
      {
        "role": "system",
        "content": "You are Ayla, a concise voice agent. Keep replies under 2 spoken sentences unless the user asks for detail."
      },
      {
        "role": "user",
        "content": "I want to check my reservation."
      }
    ],
    "temperature": 0.4,
    "max_tokens": 180,
    "stream": false
  }'
```

Typical response shape:

```json
{
  "id": "chatcmpl-local",
  "object": "chat.completion",
  "model": "orbit",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Sure. Please say or enter your booking reference."
      },
      "finish_reason": "stop"
    }
  ]
}
```

### OpenAI SDK example

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: `${process.env.EBURON_BASE_URL}/v1`,
  apiKey: process.env.EBURON_API_KEY || "eburon-local",
});

export async function askEburon(input: string): Promise<string> {
  const response = await client.chat.completions.create({
    model: process.env.EBURON_MODEL || "orbit",
    messages: [
      {
        role: "system",
        content:
          "You are Ayla, a production voice agent. Speak naturally, be concise, and ask one question at a time.",
      },
      { role: "user", content: input },
    ],
    temperature: 0.4,
    max_tokens: 180,
  });

  return response.choices[0]?.message?.content?.trim() || "";
}
```

---

## 9. Raw generation endpoint

Use raw generation only for single-shot tasks, prompt rewriting, classification, summarization, or behind-the-scenes state compression.

```bash
curl -sS "$EBURON_BASE_URL/api/generate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -d '{
    "model": "orbit",
    "prompt": "Summarize this call in one sentence: The caller wants to move the appointment to Friday.",
    "stream": false,
    "options": {
      "temperature": 0.1,
      "num_predict": 80
    }
  }'
```

Use cases:

- call summaries
- CRM notes
- intent classification
- sentiment classification
- conversation memory compression
- post-call action extraction

Avoid raw generation for the main spoken conversation because it loses explicit role separation.

---

## 10. Embeddings endpoint

If Eburon exposes embeddings, use them for retrieval-augmented voice responses.

Try OpenAI-compatible first:

```bash
curl -sS "$EBURON_BASE_URL/v1/embeddings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -d '{
    "model": "embed",
    "input": "What is the baggage allowance for this ticket?"
  }'
```

Try native fallback:

```bash
curl -sS "$EBURON_BASE_URL/api/embeddings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -d '{
    "model": "embed",
    "prompt": "What is the baggage allowance for this ticket?"
  }'
```

Voice-agent RAG pattern:

```text
User speech
  -> STT text
  -> Embed query
  -> Search policy/docs/CRM
  -> Add top 3 snippets to system/developer context
  -> Ask Eburon
  -> TTS response
```

---

## 11. Voice-agent latency strategy

For realistic calls, optimize time-to-first-audio, not just total response time.

Recommended targets:

```text
STT finalization:       100-400 ms after user stops speaking
LLM first token:        <500 ms preferred
First TTS audio:        <900 ms preferred
Full spoken response:   streamed phrase-by-phrase
```

Tactics:

- stream STT interim transcripts, but call Eburon only on final or high-confidence partial turns
- keep model warm with `keep_alive` if supported
- keep system prompts short
- cap `max_tokens` / `num_predict`
- use lower temperature for business calls
- stream response tokens into phrase chunks
- start TTS after the first complete phrase, not after the whole answer
- cancel TTS immediately on barge-in
- summarize old conversation turns instead of passing full raw history forever

Recommended generation settings:

```json
{
  "temperature": 0.35,
  "top_p": 0.9,
  "max_tokens": 140,
  "stream": true
}
```

For deterministic tool routing:

```json
{
  "temperature": 0.0,
  "max_tokens": 120,
  "stream": false
}
```

---

## 12. Turn manager design

The turn manager decides when the user is done speaking and when the agent may answer.

State machine:

```text
IDLE
  -> USER_SPEAKING
  -> USER_TURN_FINALIZING
  -> THINKING
  -> AGENT_SPEAKING
  -> INTERRUPTED or IDLE
```

Core rules:

1. Only one speaker should be active at a time.
2. User speech always has priority over agent speech.
3. On barge-in, stop TTS, cancel the in-flight Eburon request, and start a new user turn.
4. Never send overlapping assistant replies into the same call.
5. Track exactly who is speaking: `user`, `agent`, or `none`.

Example state object:

```ts
type Speaker = "user" | "agent" | "none";

type VoiceTurnState = {
  callId: string;
  activeSpeaker: Speaker;
  userIsSpeaking: boolean;
  agentIsSpeaking: boolean;
  currentTurnId: string;
  abortController?: AbortController;
};
```

---

## 13. System prompt for a production voice agent

Use a voice-first prompt. Written-chat prompts often sound too verbose when spoken.

```text
You are Ayla, a production voice agent powered by Eburon.

Voice behavior:
- Speak naturally and briefly.
- Use short sentences.
- Ask one question at a time.
- Do not mention tools, APIs, prompts, system messages, or internal rules.
- If the user interrupts, acknowledge the latest user message and continue from there.
- Confirm important details such as dates, names, booking references, prices, and consent.
- If uncertain, ask a focused clarification.

Business behavior:
- Use available tools for account lookup, booking lookup, scheduling, payments, and escalation.
- Do not invent account data, policies, prices, availability, or confirmations.
- If a tool fails, apologize briefly and offer the next best step.
- Escalate to a human when identity, payment, safety, legal, or medical confidence is insufficient.

Output style:
- Default answer length: 1-2 spoken sentences.
- For forms, ask for one field at a time.
- For summaries, use plain language.
```

---

## 14. Tool calling pattern

Voice agents should not let the model directly perform irreversible actions. Route tool calls through backend validation.

Example tools:

```json
[
  {
    "type": "function",
    "function": {
      "name": "lookup_booking",
      "description": "Look up a customer booking by booking reference and last name.",
      "parameters": {
        "type": "object",
        "properties": {
          "booking_reference": { "type": "string" },
          "last_name": { "type": "string" }
        },
        "required": ["booking_reference", "last_name"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "escalate_to_human",
      "description": "Escalate the call to a human agent.",
      "parameters": {
        "type": "object",
        "properties": {
          "reason": { "type": "string" },
          "priority": { "type": "string", "enum": ["normal", "high"] }
        },
        "required": ["reason", "priority"]
      }
    }
  }
]
```

Tool execution flow:

```text
User asks request
  -> Eburon proposes tool call
  -> Backend validates required fields
  -> Backend executes business system call
  -> Backend returns tool result to Eburon
  -> Eburon produces spoken response
```

For sensitive actions:

```text
lookup/read: model can request after basic validation
write/update: require explicit user confirmation
payment/cancel/refund: require stronger verification and backend approval
```

---

## 15. Streaming parser examples

### 15.1 Native NDJSON parser

```ts
export async function streamNativeEburonChat(params: {
  baseUrl: string;
  apiKey?: string;
  model: string;
  messages: Array<{ role: "system" | "user" | "assistant"; content: string }>;
  onToken: (token: string) => void;
  signal?: AbortSignal;
}): Promise<void> {
  const response = await fetch(`${params.baseUrl}/api/chat`, {
    method: "POST",
    headers: eburonHeaders(params.apiKey),
    body: JSON.stringify({
      model: params.model,
      messages: params.messages,
      stream: true,
      options: {
        temperature: 0.4,
        num_predict: 180,
      },
    }),
    signal: params.signal,
  });

  if (!response.ok || !response.body) {
    throw new Error(`Eburon native chat failed: ${response.status} ${response.statusText}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;

      const chunk = JSON.parse(trimmed);
      const token = chunk?.message?.content || chunk?.response || "";
      if (token) params.onToken(token);
      if (chunk.done) return;
    }
  }
}
```

### 15.2 OpenAI-compatible SSE parser

```ts
export async function streamOpenAICompatEburonChat(params: {
  baseUrl: string;
  apiKey?: string;
  model: string;
  messages: Array<{ role: "system" | "user" | "assistant"; content: string }>;
  onToken: (token: string) => void;
  signal?: AbortSignal;
}): Promise<void> {
  const response = await fetch(`${params.baseUrl}/v1/chat/completions`, {
    method: "POST",
    headers: eburonHeaders(params.apiKey),
    body: JSON.stringify({
      model: params.model,
      messages: params.messages,
      temperature: 0.4,
      max_tokens: 180,
      stream: true,
    }),
    signal: params.signal,
  });

  if (!response.ok || !response.body) {
    throw new Error(`Eburon OpenAI-compatible chat failed: ${response.status} ${response.statusText}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const events = buffer.split("\n\n");
    buffer = events.pop() || "";

    for (const event of events) {
      const lines = event.split("\n").map((line) => line.trim());
      for (const line of lines) {
        if (!line.startsWith("data:")) continue;

        const data = line.slice(5).trim();
        if (data === "[DONE]") return;

        const chunk = JSON.parse(data);
        const token = chunk?.choices?.[0]?.delta?.content || "";
        if (token) params.onToken(token);
      }
    }
  }
}
```

---

## 16. Phrase chunker for TTS

Do not send every token directly to TTS. Send stable phrase chunks.

```ts
export class VoicePhraseChunker {
  private buffer = "";

  constructor(
    private readonly onPhrase: (phrase: string) => void,
    private readonly minWords = 6,
    private readonly maxWords = 18,
  ) {}

  push(token: string): void {
    this.buffer += token;

    const words = this.buffer.trim().split(/\s+/).filter(Boolean);
    const hasBoundary = /[.!?;:]\s*$/.test(this.buffer.trim());

    if ((hasBoundary && words.length >= this.minWords) || words.length >= this.maxWords) {
      this.flush();
    }
  }

  flush(): void {
    const phrase = this.buffer.trim();
    if (!phrase) return;
    this.buffer = "";
    this.onPhrase(phrase);
  }
}
```

Usage:

```ts
const chunker = new VoicePhraseChunker((phrase) => {
  ttsQueue.enqueue(phrase);
});

await streamOpenAICompatEburonChat({
  baseUrl: process.env.EBURON_BASE_URL!,
  apiKey: process.env.EBURON_API_KEY,
  model: process.env.EBURON_MODEL || "orbit",
  messages,
  onToken: (token) => chunker.push(token),
  signal: abortController.signal,
});

chunker.flush();
```

---

## 17. Minimal voice-agent orchestrator

```ts
type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

type VoiceAgentConfig = {
  baseUrl: string;
  apiKey?: string;
  model: string;
  systemPrompt: string;
};

export class EburonVoiceAgent {
  private messages: ChatMessage[];
  private abortController: AbortController | null = null;

  constructor(private readonly config: VoiceAgentConfig) {
    this.messages = [{ role: "system", content: config.systemPrompt }];
  }

  interrupt(): void {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }

  async handleFinalTranscript(
    transcript: string,
    onSpeakPhrase: (phrase: string) => void,
  ): Promise<void> {
    const cleanTranscript = transcript.trim();
    if (!cleanTranscript) return;

    this.interrupt();
    this.abortController = new AbortController();
    this.messages.push({ role: "user", content: cleanTranscript });

    let assistantText = "";
    const chunker = new VoicePhraseChunker((phrase) => onSpeakPhrase(phrase));

    await streamOpenAICompatEburonChat({
      baseUrl: this.config.baseUrl,
      apiKey: this.config.apiKey,
      model: this.config.model,
      messages: this.messages,
      signal: this.abortController.signal,
      onToken: (token) => {
        assistantText += token;
        chunker.push(token);
      },
    });

    chunker.flush();

    if (assistantText.trim()) {
      this.messages.push({ role: "assistant", content: assistantText.trim() });
    }

    this.compactHistoryIfNeeded();
  }

  private compactHistoryIfNeeded(): void {
    const maxMessages = 18;
    if (this.messages.length <= maxMessages) return;

    const system = this.messages[0];
    const recent = this.messages.slice(-12);

    this.messages = [
      system,
      {
        role: "assistant",
        content:
          "Conversation summary so far: The previous turns were compacted. Continue naturally and preserve confirmed facts.",
      },
      ...recent,
    ];
  }
}
```

---

## 18. Voice-agent request presets

### 18.1 Customer support

```json
{
  "temperature": 0.35,
  "max_tokens": 160,
  "stream": true,
  "style": "short, polite, operational"
}
```

Prompt addition:

```text
Resolve the customer issue efficiently. Confirm identity before account-specific information. Escalate if the user asks for a human or if policy confidence is low.
```

### 18.2 Outbound sales caller

```json
{
  "temperature": 0.45,
  "max_tokens": 140,
  "stream": true,
  "style": "warm, concise, non-pushy"
}
```

Prompt addition:

```text
Respect opt-out immediately. Ask permission before continuing. Keep each spoken turn under 12 seconds.
```

### 18.3 Appointment scheduler

```json
{
  "temperature": 0.2,
  "max_tokens": 120,
  "stream": true,
  "style": "clear, confirmation-heavy"
}
```

Prompt addition:

```text
Confirm date, time, timezone, location, customer name, and contact channel before committing the appointment.
```

### 18.4 Internal command agent

```json
{
  "temperature": 0.1,
  "max_tokens": 180,
  "stream": true,
  "style": "precise, command-safe"
}
```

Prompt addition:

```text
For destructive actions, summarize the action and ask for explicit confirmation before execution.
```

---

## 19. Error handling

Map API failures to voice-friendly responses.

| Failure | Detection | Voice response | Backend action |
|---|---|---|---|
| Timeout | request exceeds timeout | "One moment, I'm having trouble responding." | retry once with shorter context |
| Model not found | 404 / model error | "I need to reconnect to my assistant engine." | refresh model list |
| Auth failure | 401 / 403 | do not expose details | alert ops, rotate key |
| Tool failure | tool returns error | "I could not complete that action yet." | log, fallback, escalate |
| Bad JSON | parse error | no spoken technical details | switch parser/fallback endpoint |
| Barge-in | user speech during TTS | stop speaking immediately | abort request and TTS |

TypeScript timeout wrapper:

```ts
export async function withTimeout<T>(
  promiseFactory: (signal: AbortSignal) => Promise<T>,
  timeoutMs: number,
): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await promiseFactory(controller.signal);
  } finally {
    clearTimeout(timer);
  }
}
```

---

## 20. Observability

Log voice-agent sessions by turn, not only by API request.

Recommended fields:

```json
{
  "call_id": "call_123",
  "turn_id": "turn_456",
  "speaker": "user|agent|none",
  "stt_latency_ms": 180,
  "llm_first_token_ms": 420,
  "tts_first_audio_ms": 760,
  "model_alias": "orbit",
  "endpoint_mode": "openai-compatible|native",
  "tokens_in": 0,
  "tokens_out": 0,
  "tool_calls": [],
  "interrupted": false,
  "escalated": false
}
```

Never log raw secrets. For sensitive industries, redact:

- payment data
- passwords/PINs
- medical details
- government IDs
- full addresses
- private account notes

---

## 21. Security checklist

- Put the Eburon key on the backend only.
- Do not expose model-management endpoints publicly unless intentionally protected.
- Prefer exposing only chat/generate/embedding endpoints to application clients.
- Validate all tool-call arguments before execution.
- Use explicit confirmation for writes, cancellations, payments, and destructive actions.
- Keep audit logs for regulated workflows.
- Use TLS for all public traffic.
- Add rate limits per account, IP, call ID, and tenant.
- Add prompt-injection filters around retrieved documents and tool results.
- Separate public voice-agent traffic from admin/model-management routes.

---

## 22. Deployment patterns

### 22.1 Public gateway

```text
Voice App -> API Gateway -> Eburon Gateway -> Local Inference Server
```

Use when browser/mobile/SIP clients need internet access.

### 22.2 Private on-prem voice stack

```text
PBX/WebRTC -> Voice Service -> Eburon Gateway -> Local Inference Server
```

Use when data must stay inside the organization.

### 22.3 Hybrid stack

```text
Cloud Voice Edge -> Private Eburon API over VPN -> Internal Tools/CRM
```

Use when telephony is cloud-hosted but inference and data access must remain private.

---

## 23. Recommended backend route for a voice frontend

Expose your own route instead of letting the frontend call Eburon directly.

```http
POST /api/voice-agent/respond
```

Request:

```json
{
  "callId": "call_123",
  "turnId": "turn_456",
  "transcript": "Can I change my flight tomorrow?",
  "locale": "en-US",
  "modelAlias": "orbit"
}
```

Response for non-streaming fallback:

```json
{
  "reply": "I can help with that. What is your booking reference?",
  "shouldSpeak": true,
  "requiresTool": false
}
```

For streaming, use WebSocket or server-sent events:

```text
event: phrase
data: {"text":"I can help with that."}

event: phrase
data: {"text":"What is your booking reference?"}

event: done
data: {}
```

---

## 24. Test commands

### 24.1 Check root

```bash
curl -i "$EBURON_BASE_URL/"
```

A default hosting page at root is not a failure by itself. APIs may live under `/api/*`, `/v1/*`, or a documented subpath.

### 24.2 Check models

```bash
for path in "/v1/models" "/api/tags" "/models"; do
  echo "\n--- $path"
  curl -sS "$EBURON_BASE_URL$path" \
    -H "Authorization: Bearer $EBURON_API_KEY" \
    -H "Content-Type: application/json"
done
```

### 24.3 Check chat

```bash
curl -sS "$EBURON_BASE_URL/v1/chat/completions" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "orbit",
    "messages": [
      {"role":"user","content":"Say ready in one word."}
    ],
    "stream": false,
    "max_tokens": 10
  }'
```

Fallback:

```bash
curl -sS "$EBURON_BASE_URL/api/chat" \
  -H "Authorization: Bearer $EBURON_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "orbit",
    "messages": [
      {"role":"user","content":"Say ready in one word."}
    ],
    "stream": false
  }'
```

---

## 25. Production acceptance checklist

Before shipping a voice agent with Eburon:

- [ ] Confirm live model-list endpoint.
- [ ] Confirm live chat endpoint.
- [ ] Confirm whether streaming is NDJSON or SSE.
- [ ] Confirm auth requirements.
- [ ] Confirm model aliases and backend mapping.
- [ ] Confirm max context length.
- [ ] Confirm tool-call support.
- [ ] Confirm JSON/structured-output support.
- [ ] Confirm timeout behavior.
- [ ] Confirm rate limits.
- [ ] Confirm observability fields.
- [ ] Confirm PII redaction policy.
- [ ] Confirm escalation policy.
- [ ] Confirm barge-in cancellation behavior.
- [ ] Load-test concurrent calls.
- [ ] Measure first-token and first-audio latency.

---

## 26. Troubleshooting quick reference

### Problem: root page says hosting is ready

Likely cause: root path is not the API route.
Fix: test `/v1/models`, `/api/tags`, `/v1/chat/completions`, and `/api/chat`.

### Problem: model not found

Likely cause: alias mismatch.
Fix: list models and update backend alias mapping.

### Problem: response is too long for voice

Fix:

```json
{
  "temperature": 0.3,
  "max_tokens": 100,
  "system": "Keep replies under two spoken sentences."
}
```

### Problem: response starts too slowly

Fix:

- stream output
- reduce prompt size
- reduce max tokens
- keep model warm
- remove unnecessary retrieved context
- use a faster model alias such as `echo`

### Problem: agent talks over the user

Fix:

- add barge-in detection
- stop TTS on user speech
- abort current LLM request
- allow only one active speaker at a time

### Problem: model invents business data

Fix:

- force tool lookup before account-specific answers
- add retrieval snippets
- lower temperature
- add explicit prompt rule: "Do not invent policy, pricing, availability, or account data."

---

## 27. Recommended internal developer message for Eburon voice agents

Use this as the developer/system layer in apps that call Eburon.

```text
You are the reasoning engine for a realtime voice agent.

Priorities:
1. Be fast and useful.
2. Speak in natural, short sentences.
3. Ask one question at a time.
4. Use tools for facts, bookings, customer records, schedules, and actions.
5. Do not invent data.
6. Do not expose internal implementation details.
7. Stop or revise course when the user interrupts.
8. Escalate when policy, identity, payment, safety, legal, or medical confidence is low.

The user hears the response through TTS, so avoid markdown, tables, long lists, code, and visual formatting unless explicitly requested.
```

---

## 28. Source notes

Public sources used while drafting this KB:

- Eburon public platform page: `https://eburon.ai/`
- Eburon API indexed documentation result: `https://eburon.site/`
- Eburon API root checked: `https://api.eburon.ai/`
- Eburon GitHub organization and repositories: `https://github.com/Eburon-AI/`
- Ollama API documentation: `https://docs.ollama.com/api/chat`, `https://docs.ollama.com/api/generate`, `https://docs.ollama.com/api/openai-compatibility`

---

## 29. Final recommended integration path

For the first production implementation:

1. Build a backend wrapper called `EburonVoiceClient`.
2. On boot, probe `/v1/models`, `/api/tags`, and `/models`.
3. Prefer `/v1/chat/completions` if available because it is easiest to integrate with existing agent tooling.
4. Fallback to `/api/chat` if the gateway is native Ollama-style.
5. Stream model output into a phrase chunker.
6. Feed phrase chunks into TTS.
7. Add barge-in cancellation.
8. Keep all keys and actual model IDs on the backend.
9. Expose only alias names in UI.
10. Add tool routing and validation before any business action.

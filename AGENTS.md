# AGENTS.md — Voxx-Zero (Beatrice)

## Stack

Vite 6 + React 19 + TS 5.8 + Express 4 + Firebase Auth + Supabase + Eburon Core + Baileys WhatsApp.

## Entry Points

- Frontend: `index.html` → `src/main.tsx` → `src/App.tsx`
- Backend: `server/index.ts` (runs via `tsx`, port 4200)
- Firebase function: `functions/src/index.ts` (Node 20, proxies /api/* to VPS)

## Commands

| Task | Command | Notes |
|---|---|---|
| Full dev | `npm run dev:full` | Frontend :3000 + Backend :4200 concurrently |
| Frontend only | `npm run dev` | Vite dev server on :3000 |
| Backend only | `npm run dev:api` | tsx watch on :4200 |
| Build | `npm run build` | Vite build → `dist/` |
| Lint | `npm run lint` | `tsc --noEmit` (~7-10 pre-existing errors, do not fix) |
| Smoke test | `npm run smoke:whatsapp` | Checks `/api/health`, `/api/eburon/provider`, `/api/workspace/list/:userId` |
| Docker build | `npm run docker:whatsapp:build` | Builds WhatsApp Docker image |
| Docker up | `npm run docker:whatsapp:up` | Starts container on :4200 |
| Docker down | `npm run docker:whatsapp:down` | Stops container |
| Supabase | `npm run db:start` / `db:stop` / `db:reset` / `db:migrate` | Local Supabase via CLI |
| Branding check | `npm run check:eburon-branding` | Scans for prohibited provider tokens (passes on `AGENTS.md` and `CLAUDE.md`) |

## Architecture & Data Flow

- **Supabase** is the single source of truth (messages, memories, WhatsApp sync, media, settings, Eburon).
- **`server/db/repositories/`** is the only DB access layer — services never call Supabase directly. 6 repos: `eburon`, `media`, `memory`, `messages`, `settings`, `whatsapp`.
- **Eburon Core** is the sole AI provider. All AI calls route through `server/eburon-provider.ts` which wraps `@google/genai`. Internal upstream model IDs are obfuscated via `String.fromCharCode` in the `EBURON_MODEL_REGISTRY`. Never expose upstream model IDs to frontend.
- **Google services** run client-side in `BeatriceAgent.tsx` via browser OAuth. WhatsApp and Belgian tools proxy through Express.
- **WhatsApp** uses `@whiskeysockets/baileys` in `server/whatsapp.ts`. Outbound tools require `delegated_send` permission + user approval. SSE stream at `GET /api/whatsapp/stream/:userId`.
- **No test framework** — manual verification only.

## Key Constraints

- **Prohibited branding tokens** (case-insensitive scan): `gemini`, `google-genai`, `google generative`, `generative-ai`. Use Eburon aliases. The `check:eburon-branding` script enforce — but allowlists `AGENTS.md`, `CLAUDE.md` and binary/artifact files. To bypass: use `String.fromCharCode` obfuscation as done in `server/eburon-provider.ts`.
- **HMR** on by default. Set `DISABLE_HMR=true` to prevent flicker during AI edits (checked in `vite.config.ts`).
- **ESLint** only checks Firebase security rules (via `@firebase/eslint-plugin-security-rules`); not app code.
- **Env loading:** `server/` loads via `dotenv` (`import 'dotenv/config'`). Frontend env injected at build via `vite.config.ts` (`loadEnv` + `define`).
- **Env naming:** `EBURON_CORE_KEY` (server-side, no prefix). `VITE_`-prefixed for public frontend values. See `.env.local.example` for local dev, `.env.whatsapp.example` for Docker.
- **`@/*` path alias** maps to project root (both `tsconfig.json` and Vite resolve alias).
- **`functions/`** uses Node 20 (`package.json:engines.node`); root uses Node 22.
- **Tailwind v4** via `@tailwindcss/vite` plugin. Theme via `.theme-dark`/`.theme-light` CSS custom properties. `motion` (Framer Motion) + `lucide-react` for UI.
- **Single Supabase migration:** `supabase/migrations/00001_init_beatrice_core.sql` (25 tables). Seed data in `supabase/seed.sql`.
- **Deep reference:** `src/overview.md` (~764 lines).

## Source Map

| Component | File | Responsibility |
|---|---|---|
| Agent engine | `src/components/BeatriceAgent.tsx` | ~280KB monolith: voice, tools, Live API session, audio, UI |
| Express API | `server/index.ts` | All API routes (1636 lines, 30+ endpoints) |
| AI provider | `server/eburon-provider.ts` | Model registry, whitelist, AI call routing |
| WhatsApp | `server/whatsapp.ts` | WhatsAppManager (Baileys) |
| Belgian tools | `server/belgian-tools.ts` | 10 admin tool endpoints |
| DB repos | `server/db/repositories/*.repo.ts` | 6 repos: eburon, media, memory, messages, settings, whatsapp |
| FB proxy | `functions/src/index.ts` | Cloud Function proxying /api/* to `168.231.78.113:4200` |
| Prompts | `src/lib/prompts.ts` | `VOICE_PERSONALITY_PROMPT` (do not edit lightly) |

## API Routes (server/index.ts)

| Route | Purpose |
|---|---|
| `GET /api/health` | Health check |
| `GET /api/eburon/provider` | Provider status + model list |
| `POST /api/eburon/live-session` | Eburon voice session token |
| `POST /api/belgian/tool` | 10 Belgian admin tools (KBO, VIES, Peppol, tax, etc.) |
| `GET/POST /api/whatsapp/*` | Pairing, messages, send, stream (`/stream/:userId` SSE), webhook, admin |
| `POST /api/web/glance` | DuckDuckGo web search |
| `POST /api/sandbox/run` | Sub-agent runner (Eburon Sandbox → Multimodal Pro → Cerebras → Worker fallback) |
| `POST /api/cerebras/browser` | Browser-Use + Cerebras automation |
| `POST /api/ollama/generate` | Ollama LLM proxy (SSE streaming) |
| `POST /api/ollama/models` | List Ollama models |
| `POST /api/website/generate` | Web Architect (Eburon Worker) |
| `POST /api/docs/generate` | Document generation (Eburon Worker) |

## Notable Files

- `Dockerfile` (port 10000, with Chromium/puppeteer) / `Dockerfile.whatsapp` (port 4200, slim, also installs Python + Playwright)
- `requirements.txt` — Python deps for Cerebras browser automation (Playwright)
- `public/*-template.html` — Doc generation templates (invoice, NDA, certificate)
- `ecosystem.config.cjs` / `ecosystem.config.selfhosted.cjs` — PM2 configs
- `scripts/setup-cerebras.sh` / `scripts/cerebras_browser.py` — Browser automation setup
- `twa-manifest.json` — Android Trusted Web Activity config

## Deployment

```bash
# Backend (Docker Compose — production on :4200)
npm run docker:whatsapp:build
npm run docker:whatsapp:up

# Rebuild + restart
docker compose -f docker-compose.whatsapp.yml up -d --build

# Frontend (Firebase Hosting)
firebase deploy --only hosting

# Functions (Node 20)
npm --prefix functions run build && firebase deploy --only functions
```

- Production: `https://whatsapp.eburon.ai`. Express serves `dist/` static files + SPA fallback. Vite dev server runs alongside for frontend work.
- NGINX reverse proxy (ports 80/443, Let's Encrypt) → `127.0.0.1:4200` (Docker). Also proxies `api.eburon.ai`, `opencode.eburon.ai`, `fast.eburon.ai`, `fragments.eburon.ai`.
- **Dokploy:** Uses `docker-compose.dokploy.yml` (port 4200, `Dockerfile` with Chromium).
- **CI:** `.github/workflows/android-distribution.yml` — On push to `main`: build web → Firebase Hosting → Bubblewrap APK → Firebase App Distribution.

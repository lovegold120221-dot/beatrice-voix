# AGENTS.md

## Stack
Vite + React 19 + TS + Express + Firebase Auth + Local Supabase + Eburon Core + Baileys WhatsApp.

## Entry Point
`index.html` → `src/main.tsx` → `src/App.tsx`.

Express backend: `server/index.ts` (runs via `tsx`).

## Commands
```bash
npm run dev              # Frontend :3000
npm run dev:api          # Backend :4200 (tsx)
npm run dev:full         # Both concurrently
npm run build            # Vite build → dist/
npm run lint             # tsc --noEmit (~7-10 pre-existing errors, do not fix)
npm run smoke:whatsapp   # Quick /api/health check
npm run docker:whatsapp:build  # Docker build WhatsApp server
npm run docker:whatsapp:up     # Docker compose up
npm run db:start         # Start local Supabase
npm run db:stop          # Stop local Supabase
npm run db:reset         # Reset local Supabase DB
npm run db:migrate       # Run pending migrations
npm run check:eburon-branding  # Validate no upstream provider branding
```

## Architecture

### Data Flow
- Local Supabase is single source of truth for all data (messages, memories, WhatsApp sync, media, Eburon settings).
- `server/db/repositories/` provides centralized DB access — services never call Supabase directly from random files.
- Google services tools run client-side in `BeatriceAgent.tsx` via browser OAuth. WhatsApp and Belgian tools proxy through Express backend.
- Eburon Core provider is the only AI provider. All AI calls route through `server/eburon-provider.ts`.

### Key Quirks
- **No test framework** — manual verification only.
- **Eburon model aliases** are used throughout. Internal upstream model IDs are mapped in `server/eburon-provider.ts` via `EBURON_MODEL_REGISTRY`. Never expose upstream model IDs to frontend.
- **HMR** on by default; set `DISABLE_HMR=true` to prevent flicker during AI edits.
- **Env:** `EBURON_CORE_KEY` (server-side, no prefix) for Eburon Core. `VITE_`-prefixed for public frontend values only. Injected at build time in `vite.config.ts` via `loadEnv` + `define`.
- **Firebase proxy** (`functions/src/index.ts`) has hardcoded backend IP `168.231.78.113:4200` — do not change.
- **ESLint** only checks Firebase security rules (`@firebase/eslint-plugin-security-rules`), not app code. Type checking uses `tsc --noEmit`.
- **Path alias:** `@/*` maps to project root via tsconfig paths + Vite resolve alias.
- **Functions:** `functions/` uses Node 20 (`package.json:engines.node`), root uses Node 22.
- **Styling:** Tailwind v4 (`@import "tailwindcss"`), full theme via CSS custom properties (`.theme-dark`/`.theme-light`), `motion/react`, `lucide-react`.
- **WhatsApp:** Baileys (`server/whatsapp.ts`). Outbound tools require `delegated_send` permissions + user approval. SSE real-time stream at `GET /api/whatsapp/stream/:userId`.
- **Deep reference:** `src/overview.md` (~764 lines) documents the full system.
- **Companion file:** `CLAUDE.md` exists with similar guidance — keep both in sync.
- **Local Supabase:** Run `supabase start` for local dev. See `.env.local.example` for config.
- **Eburon branding check:** Run `npm run check:eburon-branding` to validate no upstream provider branding leaks into the codebase.

### Source Map
| Component | Responsibility |
|---|---|
| `src/components/BeatriceAgent.tsx` | ~270KB monolith: agent engine, Live API session, tools, audio, UI |
| `server/index.ts` | Express API: WhatsApp, Belgian tools, sandbox, Cerebras, Ollama proxy, website builder, Eburon endpoints |
| `server/eburon-provider.ts` | Eburon Core provider: model registry, whitelist, AI call routing, token generation |
| `server/whatsapp.ts` | WhatsAppManager (Baileys) |
| `server/belgian-tools.ts` | 10 Belgian admin tool endpoints |
| `server/db/` | Database layer: supabase clients + repositories (memory, messages, WhatsApp, media, settings, Eburon) |
| `src/lib/prompts.ts` | `VOICE_PERSONALITY_PROMPT` (do not edit lightly) |
| `functions/src/index.ts` | Firebase Cloud Function proxy to VPS backend |

### API Routes (server/index.ts)
| Route | Purpose |
|---|---|
| `POST /api/belgian/tool` | 10 Belgian admin tools (KBO, VIES, Peppol, tax, etc.) |
| `GET/POST /api/whatsapp/*` | Pairing, messages, send, stream, webhook, admin |
| `GET /api/whatsapp/stream/:userId` | SSE real-time message stream |
| `POST /api/web/glance` | DuckDuckGo web search |
| `POST /api/sandbox/run` | Sub-agent runner (OpenCode CLI or Eburon Worker) |
| `POST /api/cerebras/browser` | Browser-Use + Cerebras automation |
| `POST /api/ollama/generate` | Ollama LLM proxy (SSE streaming) |
| `POST /api/website/generate` | Web Architect (Eburon Worker) |
| `POST /api/docs/generate` | Document generation (Eburon Worker) |
| `POST /api/eburon/live-session` | Eburon voice session token |
| `GET /api/eburon/provider` | Eburon provider status |

### Notable Files
- `supabase/migrations/00001_init_beatrice_core.sql` — full schema (25 tables).
- `supabase/seed.sql` — local-only seed data.
- `.env.local.example` — local development env template (Eburon-branded).
- `server/eburon-provider.ts` — Eburon AI provider module.
- `server/db/` — centralized database layer.
- `scripts/check-eburon-branding.mjs` — branding compliance check.
- `public/*-template.html` — HTML document templates for artifact generation.
- `ecosystem.config.cjs` — PM2 process config for production.
- `Dockerfile` (port 10000, puppeteer/chromium) / `docker-compose.whatsapp.yml` (port 4200) — containerized backend.
- `twa-manifest.json` — Android Trusted Web Activity config.
- `render.yaml` / `vercel.json` — alternative deployment configs.

### Deployment
```bash
# Frontend (Firebase Hosting — rewrites /api/* to Firebase function → VPS)
firebase deploy --only hosting

# Functions (Node 20, not 22)
npm --prefix functions run build && firebase deploy --only functions

# Backend (Docker Compose — production)
npm run docker:whatsapp:build   # Build image
npm run docker:whatsapp:up      # Start container on port 4200

# Or rebuild/restart after code changes:
docker compose -f docker-compose.whatsapp.yml up -d --build
```
- Functions runtime is Node 20 (`functions/package.json:engines.node`), not root Node 22.
- Production URL: `https://whatsapp.eburon.ai`.
- Alternatively deployable via Vercel (`vercel.json`), Render (`render.yaml` — web service runtime Node, health check `/api/health`), or **Dokploy** (`.opencode/skills/dokploy-deploy/SKILL.md` + `docker-compose.dokploy.yml`).
- In production, Express serves `dist/` static files + SPA fallback. Vite dev server on port 3000 runs alongside for frontend development.
- **Reverse proxy:** NGINX on ports 80/443 with Let's Encrypt, proxies `whatsapp.eburon.ai` → `127.0.0.1:4200` (Docker container). Also proxies `api.eburon.ai`, `opencode.eburon.ai`, `fast.eburon.ai`, `fragments.eburon.ai`.
- **Docker Compose (recommended):** `docker-compose.whatsapp.yml` uses `Dockerfile.whatsapp` (slim, no Chromium). `docker-compose.dokploy.yml` uses `Dockerfile` (includes Chromium/puppeteer for browser automation).

### CI
- `.github/workflows/android-distribution.yml` — On push to `main`: builds web, deploys to Firebase Hosting, builds Android APK via Bubblewrap, uploads to Firebase App Distribution.

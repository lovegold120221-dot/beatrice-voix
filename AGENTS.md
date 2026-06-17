# AGENTS.md — Voxx-Zero (Beatrice)

## Stack

Vite 6 + React 19 + TS 5.8 + Express 4 + Firebase Auth + Supabase + Eburon Core + Baileys WhatsApp.
- **Root Node version:** 22
- **Functions Node version:** 20 (Firebase Cloud Functions)

## Entry Points

- **Frontend:** `index.html` → `src/main.tsx` → `src/App.tsx` (built via Vite, output to `dist/`)
- **Backend:** `server/index.ts` (port 4200, runs directly from source via `tsx`, no compilation step)
- **Firebase Functions:** `functions/src/index.ts` (proxies `/api/*` to the hardcoded VPS IP `168.231.78.113:4200`)

## Commands

| Task | Command | Notes |
|---|---|---|
| Full dev | `npm run dev:full` | Frontend :3000 + Backend :4200 (Runs via `&` shell backgrounding) |
| Frontend only | `npm run dev` | Vite dev server on :3000 |
| Backend only | `npm run dev:api` | Runs `server/index.ts` via `tsx` on :4200 (not watch mode) |
| Build | `npm run build` | Vite build → `dist/` (Required BEFORE docker build) |
| Lint | `npm run lint` | `tsc --noEmit` (~7-10 pre-existing errors in external types, do not fix) |
| Smoke test | `npm run smoke:whatsapp` | Checks `/api/health`, `/api/eburon/provider`, `/api/workspace/list/:userId` |
| Docker build | `npm run docker:whatsapp:build` | Builds production slim image (requires `dist/` pre-built) |
| Docker up | `npm run docker:whatsapp:up` | Starts container on :4200 in host networking mode |
| Docker down | `npm run docker:whatsapp:down` | Stops container |
| Supabase | `npm run db:start` / `db:stop` / `db:reset` / `db:migrate` | Local Supabase via CLI |
| Branding check | `npm run check:eburon-branding` | Scans codebase for banned provider strings |

## Architecture & Data Flow

- **Supabase** is the primary source of truth (messages, memories, settings).
- **`server/db/repositories/`** is the only database access layer (6 repositories).
- **`server/db/workspace-storage.ts`** is the EXCEPTION: workspace outputs (documents, screenshots) are stored directly on the local filesystem as JSON under `/data/workspace` (or `WORKSPACE_DATA_DIR`), NOT in Supabase.
- **Eburon Core** is the sole AI provider. All AI calls route through `server/eburon-provider.ts` which wraps `@google/genai`.
- **Google services** run client-side in `BeatriceAgent.tsx` via browser OAuth. WhatsApp and Belgian tools proxy through Express.
- **WhatsApp** uses `@whiskeysockets/baileys` in `server/whatsapp.ts`. Outbound tools require `delegated_send` permission + user approval. SSE stream at `GET /api/whatsapp/stream/:userId`.
- **No test framework** — manual verification only.

## Key Constraints & Obfuscation

- **Prohibited branding tokens:** The case-insensitive scan (`check:eburon-branding`) bans `gemini`, `google-genai`, `google generative`, `generative-ai` from all tracked source/config files except `AGENTS.md`, `CLAUDE.md`, and binary/artifact formats.
- **Model Obfuscation:** Inside codebase (e.g., `server/eburon-provider.ts`), upstream model IDs must be obfuscated using `String.fromCharCode` to pass build verification.
- **Rosetta Stone:** The gitignored **`LEGEND.md`** at the project root maps Eburon model aliases (e.g. `eburon_text`, `eburon_realtime_voice`) to their actual upstream IDs. Use it as reference.
- **HMR Control:** Disable HMR to stop browser flickering during AI edits by setting `DISABLE_HMR=true` (checked in `vite.config.ts`).
- **ESLint:** Only configured to check Firebase security rules (`.rules`), not application TypeScript code.

## Sub-Project Boundaries

- **Root Project:** Named `react-example` in `package.json`. Houses React app + Express backend.
- **Functions:** Located in `/functions`, runs Node 20. Excluded from root `tsconfig.json`. Compile independently with `npm --prefix functions run build`.
- **OpenCode Agent:** Files in `.opencode/` are dedicated to the local agent/sub-agent runner configuration.

## Deployment Options

- **Docker (WhatsApp):** Production container on port 4200. Requires Vite output compiled (`npm run build`) beforehand as `dist/` is copied.
- **Dokploy:** Uses `docker-compose.dokploy.yml` on port 4200. Runs `tsx` directly from source (does not require pre-build).
- **Firebase Hosting:** SPA fallback is handled via `firebase.json` rewrites. All `/api/**` calls proxy to the Cloud Function, which in turn proxies to the VPS (`168.231.78.113:4200`).

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏛️ High-Level Architecture & Structure

Voxx-Zero is a specialized, end-to-end AI agent designed to automate complex administrative and business tasks specific to the Belgian market. The system is composed of distinct, interacting layers:

**1. Frontend (Client Application)**
*   **Framework:** React 19, built with Vite, and styled using Tailwind CSS v4.
*   **Function:** Provides the user interface for interacting with the AI. It handles dynamic display of generated documents (invoices, NDAs, etc.) and manages the real-time audio streaming and recording for the Eburon Live API.
*   **Key Libraries:** Leverages Framer Motion for smooth animations and implements robust document generation using libraries like `jspdf` and `html2canvas`.

**2. Backend/API Layer**
*   **Framework:** Express.js, responsible for handling all external communications and business logic.
*   **Core Function:** Acts as a bridge between the client, the Eburon Core provider, and third-party services. It manages the WhatsApp integration using `@whiskeysockets/baileys` and orchestrates the execution of the specialized Belgian tools.
*   **Location:** Primary entry point for backend logic is `server/index.ts`. All AI calls route through `server/eburon-provider.ts`.

**3. Core Services & Data Persistence**
*   **Authentication:** Managed by Firebase Auth (using Google OAuth).
*   **Database:** Uses local Supabase (PostgreSQL) for all persistent data: messages, memories, WhatsApp sync, media, documents, Eburon provider settings, and audit logs.
*   **AI Interaction:** Integrates through the Eburon Core provider for real-time audio and conversational AI capabilities.

**4. Specialized Belgian Tooling**
The core value of the system lies in its integration with 10 high-value, market-specific skills. These modules abstract complex local regulations into simple API calls, including:
*   KBO/CBE Company Intelligence (Company registration lookups).
*   VIES VAT Validation (EU VAT number checks).
*   Peppol E-Invoicing Generator (UBL/XML compliant invoice drafting).
*   Registration Tax Calculation (Regional tax law calculation).

## 🛠️ Development Commands

The following commands cover standard development workflows. All scripts are defined in `package.json`.

| Task | Command | Purpose | Notes |
| :--- | :--- | :--- | :--- |
| **Full Development** | `npm run dev:full` | Starts both the client and API side for local development. | Runs the frontend on `http://localhost:3000` and the backend API. |
| **Frontend Dev** | `npm run dev` | Runs the Vite development server for the React frontend. | Good for testing UI changes in isolation. |
| **Backend/API Dev** | `npm run dev:api` | Runs the Express/TypeScript backend logic. | Used primarily for developing or debugging the API endpoints and WhatsApp integration. |
| **Build** | `npm run build` | Compiles the entire client-side application. | Creates the optimized, production-ready assets in the `dist/` folder. |
| **Linting** | `npm run lint` | Runs TypeScript compilation check (`tsc --noEmit`). | Checks for type errors and syntax issues without generating output files. |
| **Local DB** | `npm run db:start` | Starts local Supabase. | Requires Supabase CLI. |
| **Local DB Reset** | `npm run db:reset` | Resets local Supabase database. | Applies all migrations and seed data. |
| **Branding Check** | `npm run check:eburon-branding` | Validates no upstream provider branding leaks. | Fails CI if prohibited tokens found in source/config/docs. |

## 📂 Codebase Organization Notes

*   **`src/`**: Contains the primary source code for the React frontend components and application logic.
*   **`server/`**: Hosts the main Express API server logic, Eburon provider, WhatsApp manager, backend tools, and database layer.
*   **`server/db/`**: Centralized database access layer (Supabase clients + repositories for memory, messages, WhatsApp, media, settings, Eburon).
*   **`server/eburon-provider.ts`**: Eburon Core provider module — the only entry point for AI calls.
*   **`supabase/`**: Local Supabase config, migrations, and seed data.
*   **`functions/`**: Contains modularized, serverless functions (for Firebase/Cloud Functions).
*   **`docs/`**: Contains architectural diagrams (`.mmd`, `.svg`) and high-level flowcharts.
*   **`scripts/`**: Utility scripts including Eburon branding validation.

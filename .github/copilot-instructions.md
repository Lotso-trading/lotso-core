# Polymarket Copy-Trading Ecosystem — GitHub Copilot Custom Instructions

## Repository Overview
Polymarket Copy-Trading is a high-performance, containerized, strictly typed microservice architecture designed for real-time copy-trading on Polymarket:
- `packages/shared` (`@lotso-trading/shared`): Shared contracts, Zod runtime validation schemas, discriminated unions, zero-`any` strict TypeScript definitions, immutable entities (`Readonly<T>`).
- `services/api`: Enterprise backend under NestJS 12 + MongoDB (Mongoose), compound-indexed queries sub-millisecond, native aggregation pipelines (PnL, win rate, volume), real-time WebSocket Gateway broadcasting live trade events, REST CRUD for target whales & dynamic risk configuration.
- `services/bot`: Autonomous high-frequency trading engine (Clean Architecture / Hexagonal). Hybrid real-time detection (Polymarket Data API + Polygon RPC streaming), RiskManager (slippage guard, price bounds [0.05 - 0.95], balance dynamic sizing, max allocated capital & profit reinvestment), `ALL` exit rule, non-custodial EIP-712 CLOB order execution / Dry-Run simulator, rich Discord alerts.
- `services/dashboard`: Real-time financial UI (Vue 3.5+ Composition API `<script setup lang="ts">`, Vite 8, Pinia, Tailwind CSS), target whale administration, interactive risk control panel, live trade feed & open positions tracking.

---

## The 5 Golden Rules of the Project
1. **Strict Typing & Zero `any`**: Permanent TypeScript strict mode (`noImplicitAny: true`, `noExplicitAny` in Biome). Any external payload (Polymarket API, Polygon RPC, HTTP request) MUST enter typed as `unknown` and be validated with a **Zod** schema before being cast or consumed.
2. **Single Biome Standard**: All code formatting and linting is handled by Biome (`biome check .`, `biome format --write .`). Never add or rely on ESLint or Prettier.
3. **Optimized MongoDB**: Compound indexes on frequent queries (`targetAddress`, `timestamp`, `status`), native aggregation pipelines for financial metrics and performance tracking.
4. **Clean Code & Hexagonal Architecture**: Strict separation of *Domain / Application / Infrastructure / Interfaces* in `services/bot` and modular design in `services/api`.
5. **Graphify Knowledge Graph**: Automated relational graph to inspect dependencies, detect circular references, and maintain architecture integrity.

---

## Commit Message Generation Instructions (semantic-release & Conventional Commits)

When generating Git commit messages for changes in this repository:
1. **Strictly adhere to Conventional Commits v1.0.0**: `<type>(<scope>): <subject>`.
2. **Release & Deployment Triggers**:
   - `feat` triggers a **Minor** release (`0.X.0`) and production deployment.
   - `fix` and `perf` trigger a **Patch** release (`0.0.X`) and production deployment.
   - `refactor` and `chore(deps)` trigger a **Patch** release (`0.0.X`) and production deployment.
   - Other `chore`, `docs`, `style`, `test`, `ci`, `build` do NOT trigger releases or deployments.
3. **Format**:
   - Language: English only.
   - Mood: Imperative present tense (`add`, `fix`, `update`, `remove`, `refactor`).
   - Case: Type and scope strictly in lowercase; subject begins with lowercase (except acronyms like `USDC`, `EIP-712`, `CLOB`, `RPC`, `API`).
   - Punctuation: **NEVER** add a trailing dot (`.`) at the end of the subject.
   - Length: 50 to 72 characters max.
   - No emojis in the commit header.
4. **Authorized Scopes**:
   - Transverse / Root: `deps`, `docker`, `ci`, `config`, `security`, `release`, `workspace`, `graphify`.
   - `packages/shared`: `types`, `schemas`, `contracts`, `zod`, `events`, `dto`, `embed`.
   - `services/api`: `targets`, `trades`, `positions`, `config`, `metrics`, `websocket`, `db`, `schemas`, `auth`, `discord`.
   - `services/bot`: `tracker`, `evaluator`, `risk`, `executor`, `clob`, `polygon`, `sizing`, `discord`, `dryrun`, `use-case`.
   - `services/dashboard`: `ui`, `views`, `stores`, `components`, `router`, `api`, `websocket`, `styles`, `metrics`.
5. **Detailed instructions**: See `.github/copilot-commit-instructions.md`.

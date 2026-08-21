---
name: frontend-chunk-initiate
description: Orchestrate a lightweight iphi-frontend chunk cycle, backend-review-FIRST. Mandatory live i-phi backend grounding → (on any gap) a detailed GitHub integration issue the backend implements FIRST → verify+close → plan → mock-first implement → DoD gate → seal. The frontend analog of chunk-initiate; NO Rust multi-agent pipeline (iphi-frontend runs the lightweight ADR-0001/0003 process). Use for every iphi-frontend chunk.
---

# frontend-chunk-initiate

Run one **iphi-frontend** chunk end-to-end using the deliberately-lightweight process (ADR-0001) plus the **backend-integration-first gate** (ADR-0003, codified from CH-10). This is the frontend counterpart to `chunk-initiate` — but iphi-frontend is **NOT** subject to the Rust multi-agent pipeline (no planner/implementer/auditor/retrospector swarm, no cargo/clippy/phi-core checks). The orchestrator is Claude with full conversation context.

**Core principle (user-locked 2026-08-21):** *every frontend chunk grounds against the real i-phi backend first, and when the chunk needs anything the backend doesn't already expose over HTTP `/v1`, the backend implements it FIRST via a detailed GitHub issue — then we verify + close it, then build the chunk.* This keeps the frontend honest about backend state and never builds against a fantasy contract.

When invoked, follow the phases in order. **Do not skip Phase 0.** The backend gate (Phase 0.5) is conditional on finding a gap, but the grounding that decides it is mandatory.

---

## Inputs

Slash-style `key=value`:

| Input | Required? | Values | Default | Notes |
|---|---|---|---|---|
| `chunk` | yes | `CH-NN` | — | Must match a row in `forward-scope/chunk-order.md`. |
| `approval` | yes | `yes` \| `no` | `yes` | `yes` = always show the plan via AskUserQuestion/ExitPlanMode before P2. `no` = auto-approve only for trivial mock-only chunks. |
| `resume_from_phase` | no | `ground` \| `gate` \| `plan` \| `implement` \| `dod` \| `seal` | `ground` | Resume an interrupted cycle from on-disk artifacts. |

Abort with a clear error if `chunk` is missing/unknown.

---

## Fixed paths (iphi-frontend)

| Thing | Path |
|---|---|
| Frontend root | `/root/projects/phi/iphi-frontend` |
| Backend (i-phi) root | `/root/projects/phi/i-phi` |
| GitHub REST helper | `bash /root/projects/phi/.claude/scripts/gh-rest.sh` (hardcoded to `LazyBouy/i-phi`) |
| Cycle folder | `docs/v0/proposal/plan/build/<slug>-<8hex>/` (`plan.md` + `chunk-review.md`) |
| Cycle index | `docs/v0/proposal/plan/_cycle-index.md` |
| Chunk order | `docs/v0/proposal/plan/forward-scope/chunk-order.md` |
| Drifts | `docs/v0/design/drifts/` (`D-INT-NNNN` = backend integration; `D-FE-NNNN` = internal) |
| API contract | `docs/v0/design/api-contract.md` |
| Specs | `docs/v0/specs/` |
| Scratch (gitignored) | `docs/tmp/<slug>.md` — issue/commit bodies |
| DoD gate | `pnpm run check:dod` (svelte-check + vite build) — **runnable locally** (node_modules present; no network) |
| Default branch | `dev` |

Mint the cycle token with `openssl rand -hex 4`; slug-first folder naming (`<slug>-<8hex>`).

---

## Phase 0 — Backend grounding (MANDATORY — never skip)

Establish the **facts** about the live i-phi backend for the surfaces this chunk consumes. Read + reproduce first-hand; **never hedge** (`[[feedback_never_hedge]]`). The transcribed `api-contract.md` is often stale — treat i-phi source as truth.

Grounding checklist (read these in `/root/projects/phi/i-phi`):
1. **Branch + head**: `git -C .../i-phi log --oneline -3` — record the commit you grounded against.
2. **Mounted HTTP routes**: `src/api/routes/mod.rs` — the *real* `/v1` set. Do NOT assume `api-contract.md` is right.
3. **Wire shapes**: `src/daemon/ipc/protocol.rs` — request/response structs for the routes the chunk needs.
4. **Auth**: `src/api/auth.rs` — Bearer/cookie model (there is no `/v1/auth/login` today).
5. **IPC-vs-HTTP gap**: many capabilities exist on the `DaemonClient`/IPC surface (`src/client/mod.rs`, `src/cli/commands/*`) but are **not mounted on HTTP `/v1`**. The browser SPA can only reach HTTP `/v1` — grep `src/api/` to confirm what is actually exposed.
6. **Config/domain model**: the structs behind the surface (e.g. `src/daemon/config/**`) so the frontend types + mock fixtures mirror reality.

Write the findings into the plan's `## §0 — P0 backend grounding` section (or a short `p0-grounding.md` in the cycle folder). Each finding DEFINITIVE (reproduced) or explicitly UNRESOLVED (say what's missing + go get it).

**Decide the gate:** does the live backend already expose — over HTTP `/v1`, with usable shapes — everything this chunk consumes?
- **No / partially** → **Phase 0.5** (file the issue; block).
- **Yes, fully** (rare) → record that explicitly with evidence in §0, skip Phase 0.5, proceed to Phase 1 and wire live where reachable. Skipping the issue requires a recorded, evidence-backed "backend already satisfies X/Y/Z live" note — it is the exception, not the norm.

---

## Phase 0.5 — Backend integration gate (file the issue; backend implements FIRST)

This is the CH-10 pattern. When Phase 0 surfaces any backend dependency (missing/mismatched/ambiguous/HTTP-unmounted surface):

1. **Author a detailed issue body** → `docs/tmp/<slug>.md`. It MUST contain (see the CH-10 precedent, i-phi#114):
   - **Summary + ask** (one paragraph): what the frontend surface needs.
   - **Current backend state**, grounded, with `file:line` cites — what exists (IPC vs HTTP), what's missing, which handlers/types already exist (so "mount" vs "new" is explicit and the backend's cost is honest).
   - **Exactly what we need**: an endpoint table (method · path · purpose · effort [mount-existing vs NEW] · response).
   - **Exact JSON shapes** the frontend will code against (list rows, detail DTO, request bodies, response envelope) — as concrete jsonc.
   - **Security requirements**: redact secrets in any detail DTO (never serialize a key-bearing config struct raw — ask for a purpose-built redacted DTO); keep routes auth-guarded.
   - **One-way-door decisions to confirm** (e.g. RESTful vs RPC path shape) — ask the backend to confirm so the frontend pins its client.
   - **Cross-cutting deps** that are real but out of this issue's scope (auth cookie-login, CORS) — flag + point at the umbrella issues, don't silently absorb.
   - **Acceptance criteria**: concrete `curl` calls + expected shapes + `401` without token + presence in `/v1/openapi.json`.
   - **Frontend interim**: mock-first against these exact shapes → drop-in wiring on landing.
   - **Provenance**: frontend chunk + cycle hex, the i-phi commit you grounded against, related issues.
2. **File it**: `bash .../gh-rest.sh issue-create --title "[frontend-integration] <summary>" --body-file docs/tmp/<slug>.md --label frontend-integration` (create the label once if missing: `label-create --name frontend-integration --color FF6600`). First check for dupes: `issue-list | grep -i <keywords>`, and cross-reference any umbrella issue.
3. **Pin one-way-door decisions** the backend asks about via `issue-comment <#> --body-file <decision>.md` (e.g. the path-shape decision) BEFORE they implement, and mirror the pinned contract into the plan + `D-INT`.
4. **Mirror locally**: `docs/v0/design/drifts/D-INT-NNNN-<slug>.md` (header-less; `**Status**: open`; links the issue #, the blocked surface, the interim mock). Add a row to `drifts/README.md`.
5. **BLOCK the chunk**: cycle-index row `status: blocked` citing the issue + `D-INT-NNNN`. Hand off to the backend agent. Do NOT implement the chunk yet.

### Verify + close (when the backend signals done) — do NOT trust the commit message

1. **Read the actual diff first-hand** in `/root/projects/phi/i-phi`: the router mount (`src/api/routes/mod.rs`), the handler(s), and the DTO/struct. Confirm the routes, shapes, status codes, and path/precedence rules match the pinned contract.
2. **Verify the security property structurally** — e.g. the detail DTO embeds no key-bearing type; the projection maps secrets → safe labels; no `env`/api-key leaks on any vector.
3. **Confirm the backend's own close-gate/tests** (read their `close-gate-result.md` / test additions) AND, where feasible, run an independent check (their targeted test, or a live curl). The commit message is a claim, not evidence.
4. **Post a verification comment** (`issue-comment`) summarizing what you verified first-hand, then **close**: `gh-rest.sh issue-update <#> --state closed`.
5. **Flip `D-INT-NNNN` → remediated** (→ `closed` only after the frontend revalidates the surface against a live daemon at/after DoD) and update `drifts/README.md`.
6. **Unblock**: cycle-index `status: in-flight`. Proceed to Phase 1.

If verification FAILS (routes/shapes/redaction wrong): re-open/comment on the issue with the specific gap; keep the chunk blocked.

---

## Phase 1 — Plan (+ approval)

1. Mint the cycle hex; create `docs/v0/proposal/plan/build/<slug>-<8hex>/plan.md` from the forward-scope row. Include the §0 grounding + the pinned contract (+ `D-INT` link) so P2 codes to confirmed shapes.
2. Lock any real forks via `AskUserQuestion` (user-impact + pros/cons per option).
3. Add the cycle-index `in-flight` row.
4. If `approval=yes`, present the plan for approval (AskUserQuestion / ExitPlanMode). **Do not write app code until approved.**

## Phase 2 — Implement (mock-first)

- Build the surface against **mocks shaped exactly like the confirmed wire types**, then wire live `/v1` where reachable (paths centralized in `src/lib/api/client.ts`). Match the existing idiom (`glass-card`, `btn-orange`/`btn-ghost`, tokens; Svelte 5 runes; `$app/state` not the deprecated `$app/stores`; native `onclick`/`onsubmit`).
- Mirror any redacted DTO on the client too (nothing secret to hold).

## Phase 3 — DoD gate

- Run it locally: `pnpm --dir /root/projects/phi/iphi-frontend run check` (svelte-check — **0 errors, 0 warnings**) + `pnpm ... run build` (or `pnpm run check:dod` for both). Fix everything before proceeding.
- **Visual/manual smoke** (mock mode) of the changed surface; capture into `chunk-review.md`. Get the operator's "green" for the visual check.

## Phase 4 — Seal

- `specs/<surface>.md` [PLANNED]→[EXISTS] with the real fields + the `D-INT` note; `specs/_index.md` row; correct `api-contract.md` against anything you re-grounded.
- `chunk-order.md`: flip the chunk ✅ + hex; advance `⮕ NEXT`. `_cycle-index.md`: flip to `sealed`.
- Write `chunk-review.md` (DoD evidence + self-review + any known caveats/deferred D-INTs).
- Commit on `dev` (subject prepends `D-INT-NNNN:` when the commit closes an integration drift, per the parent commit-subject discipline); then bump the parent `phi` gitlink.
- Leave `D-INT-NNNN` at `remediated` until the surface is revalidated against a live daemon; flip → `closed` then (`issue-update <#> --state closed` only if not already closed).

---

## Canonical precedent

**CH-10 (agents), cycle `b8050136`** is the reference run: grounded vs i-phi `dev`@`30428d8` → found agents CRUD existed IPC-only, not on HTTP `/v1` → filed **i-phi#114** with exact shapes + redaction requirement + pinned RESTful path shape → backend shipped FI-01 (`5331190`) → verified first-hand (structural redaction + live close-gate) + closed → then built + sealed the surface mock-first. See `docs/v0/proposal/plan/build/ch-10-agents-b8050136/` and `docs/v0/design/drifts/D-INT-0001-agents-http-v1-mount.md`.
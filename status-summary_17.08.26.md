# The `phi` Project — Status Overview
*Plain-language reset · 17 Aug 2026*

> **How to read this:** minimal jargon, lots of analogies. Section 0 is the one-minute version. Sections 1–5 are "what this thing is." Sections 6–7 are "how we got here and where we are." Sections 8–11 are "what's left and the decision in front of you."

---

## 0. The one-minute version

**What it is:** `phi` is an effort to build **personal, operator-controlled AI agents** — software assistants that hold a conversation, use tools (run commands, edit files, call services), remember things over time, and are reachable through whichever channel is handy (terminal, web page, Telegram). It's built as a **layered stack**: one reusable engine at the bottom, real products on top.

**Where we are:** The core product (**i-phi**, a background "daemon" that hosts agents) reached **feature-complete v0 in late May** and has since been **hardened and upgraded**. The most recent major push — letting **one daemon host many fully-isolated agents** — is essentially delivered. After that the project went quiet for a couple of months; you're picking it back up now.

**What's live this session:** We've just filed a batch of forward-looking design issues (a pluggable **memory architecture**, and a **"show the model less, on demand"** cleanup family), and begun scoping the next small engine change. Everything is committed locally but unpushed.

**The decision in front of you (Section 11):** four coherent directions are ready to go — *finish the multi-agent epic's loose ends*, *continue the small disclosure cleanup we just scoped*, *launch the big memory architecture*, or *start the formal v1 hardening milestone*. Your steer picks the lane.

---

## 1. What we're building (the big picture)

The cleanest mental model: **one engine, several vehicles.**

- **The engine** does the universal, hard, low-level work every AI agent needs — and has *no opinions* about how a product should behave.
- **The vehicles** are real products built around that engine, each making its own product decisions.

There are **four pieces** in the repo (it's a container that stitches together three sub-projects plus a UI):

| Piece | What it is (intuitive) | Role |
|---|---|---|
| **phi-core** | The **engine**. A reusable software library (published for others to use) that talks to 20+ AI providers, runs the "think → use a tool → repeat" loop, streams answers, and manages the conversation so it doesn't overflow. | Shared foundation. Deliberately kept small and generic. |
| **i-phi** | The **flagship product**: a long-running background service ("daemon") that hosts agents, keeps them alive, remembering, and reachable. | This is where almost all the work happens. |
| **baby-phi** | A **sibling product** built on the same engine, but for **organizations that need governance** (multiple orgs, roles, approvals, audit trails). | A different vehicle for a different driver. Not a predecessor — a sibling. |
| **iphi-frontend** | The **cockpit** — a web dashboard so a non-engineer can see and control the agent fleet. | Talks to i-phi's API. Currently built against mock data. |

**One accuracy note:** an old line in the top-level docs still calls i-phi "scaffolded with README only." That is stale — i-phi is substantially built (CLI, terminal chat, web chat, Telegram, permissions, memory, multi-agent hosting all shipped). Treat i-phi as a real, working product.

---

## 2. What i-phi does for a user (the product)

The design promise is **"one agent, four front doors."** The same agent, with the same memory, is reachable however you like to talk to it — because they all attach to the same background daemon:

- **Headless CLI** — ask once from a script, get a clean machine-readable answer. *("Ask and get an answer.")*
- **Interactive terminal chat (REPL)** — a live back-and-forth at your desk; you can even type while it's still working. *("A conversation at your desk.")*
- **Web chat** — the same conversation in a browser tab, streaming live. *("Chat in a tab.")*
- **Messengers (Telegram now; WhatsApp planned)** — text your agent from your phone like texting a person. *("Text your agent.")*

**"One agent shape, many copies" — what that means.** Instead of hand-crafting a rigid team of specialized bots, i-phi defines **one clean template** for what an agent is (its personality, its tools, its memory, its guardrails), then stamps out as many copies as you want — a "researcher," a "coder" — each configured a little differently, each able to run several conversations at once. Think **cookie cutter**: one well-made cutter, many cookies. (An agent can also spin up a temporary **helper agent** to handle a subtask and report back.)

---

## 3. The building blocks (plain-language glossary)

- **Agent** — the *who*. A configured AI worker: its role/personality, which model it uses, which tools it may call, what it remembers.
- **Session** — the *conversation*. One continuous back-and-forth. One agent can juggle many at once; they're saved to disk so they survive restarts and can be resumed.
- **Tools** — the *hands*. Concrete actions: run a command, read/write/edit a file, search code. The model *asks* to use one; the system runs it and feeds the result back.
- **Skills** — the *know-how*. Reusable instruction packets that teach the agent how to do a particular kind of task, pulled in only when needed.
- **Memory (three tiers)** — the *long-term brain*, and i-phi's own layer (the engine has none):
  - **Short-term** — a small scratchpad carried between sessions.
  - **Episodic** — a snapshot of each session, captured when a long conversation gets summarized ("compacted").
  - **Long-term** — durable knowledge rolled up across many sessions. Today this is simple keyword search over a file; making it *smart* (semantic search) is a big upcoming thread.
- **Permissions** — the *guardrails*. A three-level rulebook (organization → your home → this project). Key intuition: a **"no" higher up can't be overridden lower down** ("most-restrictive wins"), while "yes"es add together. Rules are keyed to tools (e.g. "may run `npm`, but never `rm`").
- **MCP** — the *universal adapter* for outside capabilities. A standard way to plug in external tool-servers so the agent gains new abilities with no custom code; to the agent, an MCP tool looks just like a built-in one.
- **Steering** — nudging the agent *mid-task* while a tool is still running.

---

## 4. The golden rule: keep the engine minimal

The single most important architectural principle in the whole project: **the engine (phi-core) stays small and generic; the products (i-phi, baby-phi) do all the opinionated work.** The motto is *"reuse the engine whenever possible; add new layers only when necessary."*

- A feature belongs **in the engine** only if *every* agent everywhere would need it (the raw loop, talking to providers, the tool/streaming contracts).
- A feature belongs **in the product** if it's a *choice* (how memory is stored, how permissions work, which interfaces exist, what the UI looks like) — reasonable products would decide these differently.

**Why it matters:** it avoids the "two sources of truth" trap. If both the engine and the product implemented, say, session storage, they'd drift apart and keep breaking each other. A small stable engine can be shared cleanly by both products (and future ones); each product stays simple by leaning on it; and one engine fix helps everyone. Both products even run an automated check that **fails the build** if someone re-implements something the engine already provides. (This is why the memory work and the "disclosure" work below are carefully split into an *engine* half and a *product* half.)

---

## 5. How the work actually gets done (the assembly line)

Work ships in **"chunks"** — small, self-contained units — run through a disciplined **multi-agent pipeline**: a *planner* drafts the plan, an *implementer* writes the code, one or more *auditors* independently check it, and a *retrospective* captures lessons. A human orchestrator approves the plan, reviews every change, and runs the final quality gate. For risky work, an upfront **investigation** establishes the facts before any code is written. Everything ends with a **live "close-gate"** — actually running the daemon against real models and reading the result, not just "the tests pass."

Two words you'll see a lot:

- **Drifts** — an in-repo catalogue (~90+ notes) of "things we found while building and wrote down instead of forgetting": deferred scope, behavior gaps, shape choices to revisit. Each is graded by severity and assigned to a future chunk that will close it. Most are still open — this is the honest backlog of small deferred details.
- **D-TEST issues** — the same idea, but discovered by the **end-to-end testing program** rather than during a build, and filed as **GitHub issues**. They graduate into the tracker and feed the correctness work.

There's also a whole **end-to-end test factory** running in parallel: it invents realistic use-cases, turns them into test cases, runs them against **open-source models** (cost-capped; a Claude model acts only as the impartial judge), produces a benchmark matrix, and files any defects it finds. This is the machine that keeps surfacing the real-world gaps.

---

## 6. The journey so far (how we got here)

**Phase 0 — Setup (mid-May).** Two "paperwork" cycles built the docs skeleton and the assembly line itself. Everything since runs through that pipeline.

**Phase 1 — Build v0 (roughly 18–27 May). → DONE.** The "make i-phi actually exist" milestone. In rough order: the buildable foundation; the daemon core (lifecycle, communication, one-task-per-conversation isolation); the agent-shape pieces (identity, permissions, memory tiers, sessions, hooks); conversation compaction + episodic memory (as simple stand-ins); the wiring that fuses it into one assemblable agent; then the **four front doors** (CLI, terminal chat, web API + web chat); then **Telegram**. **v0 sealed feature-complete on 27 May** (tagged `v0.0.1`). The project's own verdict: *"feature-complete, but hardening-thin."* (**WhatsApp was paused** — it needs a Business account — and is slated for v1.)

**Phase 2 — Post-v0 hardening (late May).** Removed hardcoded production config, hardened the test pipeline, fixed a networking hang. Release tags marched from `v0.1` toward `v0.3`.

**Phase 3 — Three parallel streams (June). → this is the recent era.**
- **CC series (end-to-end correctness):** ~30 cycles of "prove the daemon behaves correctly against real models, and fix what the tests expose." Not a fixed plan — each cycle picks the next defect from the backlog. **Now largely wound down.**
- **KC series (engine fixes):** four surgical fixes to the shared engine that the tests exposed (mostly around "undo/revert" semantics and skill formatting). **All done.** (One is a cautionary tale — it originally checked the *wrong* thing and passed falsely; a later cycle caught and corrected it. That lesson now hardens every close-gate.)
- **MA series (multi-agent epic):** **the most recent major push** — upgrading the daemon from effectively "one shared agent" to **"many genuinely-isolated agents in one daemon."** (Details in Section 7.)

**A parallel track:** the **web cockpit** (iphi-frontend) is being built against mock data, ahead of being wired to the live daemon.

**Phase 4 — v1 milestone: fully scoped, not started.** An 18-chunk hardening milestone was planned on 31 May but **no v1 chunk has run yet.** (Details in Section 10.)

---

## 7. Where we stand right now (you are here)

**v0 is done and tagged.** The correctness (CC) and engine (KC) test-driven streams are largely finished.

**The multi-agent epic (MA) is essentially delivered.** It made each agent its own thing — its own model/provider, its own permissions, its own skills, its own isolated memory, and the ability to create a new agent *at runtime* carrying its own full config. Seven chunks landed:
- config for multiple agents + a registry → per-agent model routing → runtime agent creation → per-agent **permissions** → per-agent **skills** → per-agent **memory isolation** → **create-with-full-config**.
- The most recent chunk (**MA-06**) is code-complete and passed its final quality gate; its **retrospective is the one open loop**. Notably, its live close-gate *caught a real bug in-flight* (a runtime-created agent wasn't applying its permissions until restart) — which was fixed and re-proven in the same cycle. Two small follow-ons remain: **agent update/delete** and **separate per-agent policy files**.

**What we just started this session (paused for this overview):** scoping the next small **engine** change — **progressive tool disclosure**. Today, when an agent has many tools (especially via an MCP server), the daemon dumps the *full* description of *every* tool into the model's first message, wasting its limited attention. The fix: **show a short label first, and let the model fetch full details on demand** (a mechanism that already exists for skills and memory, but not for tools). We ran the upfront investigation, confirmed the fix belongs mostly in the **engine** (with a thin product-side follow-on), and you locked two choices: do the **engine chunk first**, and make the lean behavior **kick in only when there are many tools** (so small agents are unaffected). We paused right before drafting the plan.

**Housekeeping:** everything is committed **locally but unpushed** (pushing is your call). A handful of process/standards files in the outer repo are also staged for you to commit.

---

## 8. The open work (backlog, by theme)

Roughly two dozen open GitHub issues cluster into five themes.

**Theme A — A pluggable long-term MEMORY architecture (the biggest new idea).** *Umbrella: #101; pieces: #102–#108.*
Give i-phi a universal **"wall socket"** so it can plug in *any* external memory system, while shipping its own batteries-included default. i-phi's code only ever talks to one standard interface (the socket); each external system (mem0, LangMem, Letta, Memory Palace, qmd) gets a small **connector** that adapts it — add a new memory system by writing one connector, no core changes. A **router** can even run several at once. It also ships its own **default smart memory** (an embedded store with real semantic search — #103), pins down the definition of *episodic* memory (#102), and adds **"system agents"** — behind-the-scenes helpers that decide *what's worth remembering* and produce the session summaries. This is the path from "keyword search over a file" to a real long-term brain.

**Theme B — Show the model less, on demand (DISCLOSURE + registration rules).** *#109–#112 — this is what we just started scoping.*
The cross-cutting cleanup from Section 7, plus the "registration rules" that make it enforceable: every **tool** (#109/#110), **skill** (#111), and **memory record** (#112) must declare a short label (loaded eagerly) and a detailed body (fetched on demand). Keeps the model's attention budget lean, especially with many-tool MCP servers.

**Theme C — The flagship multi-agent test + its prerequisite gaps.** *North-star: #87; prerequisites: #92, #93, #94, #95, #97, #98.*
#87 is both a test and a goal: prove that **one daemon can host several fully-isolated agents** end-to-end — including the *negative* case (no memory or data leaks between agents/sessions). Writing it forces the missing pieces to get built: multi-agent setup at install time (#92), swapping a model mid-conversation (#93), pulling an exact raw transcript on demand (#94), the operator web control panel (#95), and the agent update/delete + per-agent policy files (#97/#98). The MA epic already delivered most of the isolation; these close the rest.

**Theme D — Runtime lifecycle, config & a real bug.** Includes a genuine bug: the session-metadata sidecar always reports the wrong "mode" because a setter is dead code (**#100**) — a good quick win. Plus the #97/#98/#92 lifecycle items noted above.

**Theme E — Test-coverage gaps (the long tail).** The testing program flagged that multi-turn/steering/interrupt flows (**#33**) and a broad swath of the surface — hooks, skills, MCP, compaction (**#34**) — still aren't covered, plus a richer "setup → starter permission rules" mapping (#85). Add the ~90-strong drift catalogue: mostly small deferred details, tracked honestly, closed as future chunks touch them — broken out by theme in **Section 9**.

---

## 9. The drift backlog, by theme

**The reassuring headline first:** there are **98 drift notes; ~84 are open** — but **not one open drift is a high-severity blocker.** The only drift ever graded HIGH (a networking hang in one-shot mode) was **already fixed**, and one other former-HIGH (live observability being inert) was re-graded and resolved. What's left is **polish, deferred detail, and planned v1 hardening** — written down so nothing is forgotten, not landmines. Only a thin band of ~6–8 **MEDIUM, security-adjacent** items is worth a deliberate glance before exposing the daemon to the open internet.

**The key framing:** the drift backlog is **largely the v1 to-do list, already written down.** Most open drifts map almost one-to-one onto the planned v1 chunks (Section 10) — so "close the drifts" and "do v1" are mostly the same work.

Grouped by theme (open drifts; representative IDs in brackets):

- **Test-pipeline housekeeping (~13, all LOW).** The biggest bucket, and the least alarming: notes the *testing factory* wrote about *itself* while being built (cohort registration, judge-rubric templates, local-server execution, archive scripts). Not product gaps. *[D-CC01/02/03-FOLLOWUP-*, D-CC14-FOLLOWUP-01]*
- **Messenger polish (~12, LOW).** Nice-to-haves for Telegram plus groundwork for WhatsApp: inline keyboards, audio transcription, document parsing, and extracting a shared "messenger" layer before lighting up WhatsApp. Maps to v1 CH-30/31. *[D-CH13a-FOLLOWUP-*, D-CH13b-FOLLOWUP-*, D-CH15-FOLLOWUP-01 (WhatsApp)]*
- **Interface polish — CLI / terminal / web (~10, LOW).** Persistent command history, user-defined slash-commands, richer "undo" visualisation, browser/PWA niceties, message attachments. The product works today without any of them. *[D-CH10-FOLLOWUP-*, D-CH11b-FOLLOWUP-02/03/04/05]*
- **Security & secrets hardening (~9; a few MEDIUM — the one band to actually watch).** The "before you put it on the internet" list: API-token rotation, request rate-limiting, CLI auth cookies, TLS cert handling, OS-keychain storage for provider keys. This is v1's security domain (CH-21..24). *[D-CH11a-FOLLOWUP-02 token-rotation (MED), D-CH11a-FOLLOWUP-03 rate-limiting (MED), D-CH09-FOLLOWUP-02 cli-auth (MED), D-CH14-FOLLOWUP-02 keychain]*
- **Hooks & sandboxing (~8, LOW/deferred).** The automation-hooks system works, but running hook scripts in a locked-down sandbox, hot-reloading them, and async subprocess handling were deferred to v1 (CH-23). *[D-CH08-FOLLOWUP-01 sandboxing, -02 hot-reload, -03 async, -04 guardrail-hooks]*
- **Memory deepening (~7, LOW).** The path from today's simple keyword memory to a real one: retrieval ranking, rotation-with-summarisation, a vector-store target, and the big **LLM-driven memory/compaction engine**. This is exactly the memory-architecture epic (#101) and v1 CH-28. *[D-CH05-FOLLOWUP-01/02/03, D-CH16b-FOLLOWUP-01 (the LLM engine), D-CH16b-FOLLOWUP-02 per-agent-compactor]*
- **Daemon hardening & lifecycle (~6, LOW/deferred).** Crash recovery + session replay, live config reload on SIGHUP, systemd niceties, auto-daemon supervision quality. The v1 daemon-hardening domain (CH-18..20). *[D-CH02C-FOLLOWUP-01 crash-recovery, D-CH02A-FOLLOWUP-01 sighup-reload, D-CC03-FOLLOWUP-02 supervision]*
- **Compaction / braking / "undo" semantics (~5, LOW).** Wiring the "braking" safety config through live, per-profile opt-outs, richer revert visualisation. Maps to v1 CH-27. *[D-CH17-FOLLOWUP-01/03/04/05, D-CH17-COMPOSITION-I-ADOPTION]*
- **Multi-agent follow-ons (~4, LOW).** Hot-reloading per-agent permissions/skills without a restart, plus an input-filter/hook bridge — the tail of the just-finished MA epic (sits alongside GitHub #97/#98). *[D-MA02-FOLLOWUP-02, D-MA04-FOLLOWUP-02, D-CH07a-FOLLOWUP-02]*
- **Observability, sub-agents, MCP & misc (~8, LOW).** Prometheus exporters (maps to v1 CH-29), deterministic MCP shutdown, eval-parallelism surface, resume-steering-queue restoration, hard-cancel-mid-tool. *[D-CH13a-FOLLOWUP-04, D-CC24-FOLLOWUP-01, D-CH06-FOLLOWUP-02, D-CH07b-FOLLOWUP-01/02]*
- **Setup & docs (~4, LOW).** Migration-from-baby-phi, config-template versioning, per-platform troubleshooting pages. *[D-CH14-FOLLOWUP-03/04, D-CH15-FOLLOWUP-02/03]*

**Bottom line:** the drift backlog is long (~84 open) but *shallow* — no blockers, ~6–8 security-adjacent MEDIUMs worth a look, and the real substance is the already-scoped v1 hardening work. *(The in-repo index at `docs/v0/design/drifts/README.md` is stale — last consolidated 23 May — so these figures come from a fresh 17 Aug scan of the actual files.)*

---

## 10. What v1 is (the next formal milestone)

**Goal in one line:** take i-phi from a *functional single-user, single-host daemon* to a *hardened, secure, multi-surface runtime an operator can deploy with confidence.*

**Shape:** 18 chunks (CH-18 → CH-35), "Large" budget, locked 31 May, **not yet started.** Eight domains:
- **Daemon hardening** — crash recovery, live config reload, health/metrics.
- **Security & sandboxing** — scrub sensitive data from audit logs, secure key storage + rotation, sandbox the hook scripts, rate limiting + CLI auth.
- **Multi-tenant + auth** — isolate sessions per user, tokens/OAuth/OIDC, billing-readiness counters.
- **Smarter composition / LLM** — the **big one: replace the placeholder memory/compaction with real LLM-driven memory** (now feasible on a newer engine version); live "braking" enforcement; agent-of-agents.
- **Messengers** — a shared messenger layer and finally **light up WhatsApp**, plus audio transcription and richer file handling.
- **UI/UX** — multi-session console, history browser, inline permission approvals, mobile/PWA polish.
- **Observability** and **Cost controls** (per-user/session budgets — the milestone closer).

**The 5 "must-happen-for-v1" items:** the audit-log scrubbing, the LLM memory upgrade, multi-user auth, WhatsApp, and live braking enforcement.

**Deliberately deferred:** running across **multiple machines** → a later **v1.5**; plugins, backup/restore, and heavy performance/scale work → **v2**.

*(Structural note so it doesn't confuse you later: the `docs/v1/` folder holds v1 *planning* only — its build/retro folders are intentionally empty. Even when v1 chunks run, they archive under the existing `docs/v0/.../build/` folder. Empty `v1/build` is by design, not "nothing shipped.")*

---

## 11. The decision in front of you

The isolation work is done; the test-driven cleanup is wound down; v1 is scoped and waiting. Four coherent lanes are ready — your steer picks which:

1. **Close out the multi-agent epic.** Run MA-06's pending retrospective and knock out the two small follow-ons (agent update/delete #97, per-agent policy files #98). *Lowest effort; ties a bow on the recent push.*
2. **Continue the disclosure cleanup we just scoped** (the engine "show-less-on-demand" chunk, #109/#110). *Already investigated and half-decided; smallest cold-start.*
3. **Launch the big memory architecture** (#101 → its default smart store #103 → connectors). *Highest long-term value; a deliberate design effort — the jump to a real long-term brain.*
4. **Start the formal v1 hardening milestone** (CH-18: daemon crash recovery). *The "make it production-grade" track; biggest scope.*

There's also a genuine quick bug fix available any time (**#100**, the mis-recorded session mode).

**My read (you decide):** the memory architecture (#101) is the highest-leverage new capability and pairs naturally with v1's planned LLM-memory upgrade; the disclosure chunk (#2) is the cheapest way to resume since it's already scoped; and finishing the MA epic (#1) is worth doing before either, so the multi-agent story is fully sealed rather than left at 95%. A reasonable sequence is **#1 (finish MA) → #2 (disclosure) → #3 (memory epic)**, with **v1** as the milestone that absorbs the rest — but this is exactly the call your direction sets.

---

*Prepared from: the repo docs (`i-phi/README.md`, `i-phi/docs/v0/proposal/*`, `phi-core/README.md`, `baby-phi/CLAUDE.md`, `iphi-frontend/CLAUDE.md`), the cycle ledgers (`i-phi/docs/v0/proposal/plan/_cycle-index.md`, `phi-core/docs/specs/plan/build/_cycle-index.md`), the v1 plan (`i-phi/docs/v1/proposal/plan/forward-scope/*`), the e2e-test registry, project memory, and the live GitHub issue list for `LazyBouy/i-phi`.*

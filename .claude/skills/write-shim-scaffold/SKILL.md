---
name: write-shim-scaffold
description: Scaffold a mutating /v1 write surface on i-phi (POST/PUT/PATCH/DELETE) that mutates daemon/agent config atomically + applies live without restart. Codifies the write-shim pipeline (FI-31 agent capability writes + merge-fix, FI-32 skill authoring + hot-reload): write route → persist_lock-held resolve+check+mutate (no TOCTOU) → live re-register → dup→409/absent→404/traversal→400/non-writable→403/body-cap→413 → disposition-asserting close-gate on the model wire / on-disk. Invoke when a chunk adds a mutating /v1 surface.
---

# write-shim-scaffold

A mutating `/v1` surface (POST/PUT/PATCH/DELETE) that changes daemon/agent config atomically and applies live. Reproduced on FI-31 (agent capability writes + the capability-wipe merge-fix) + FI-32 (skill authoring + immediate hot-reload).

## The invariant (fill each blank)

1. **Request DTO** — a NEW `<Verb><Thing>Request` in `src/daemon/ipc/protocol.rs`. For a **PATCH/merge** surface use the tri-state idiom: `Option<T>` = preserve-on-omit; `Option<Option<T>>` + `#[serde(default, deserialize_with = "double_option")]` = absent-preserve / `null`-clear / value-set (FI-27 `double_option`, protocol.rs); `Option<Vec<T>>` for arrays = None-preserve / `Some(v)`-replace incl. `Some([])`-clear. A full-replace PUT and a merge PATCH are DIFFERENT routes — do not silently change PUT semantics (FI-31's wipe bug was a full-replace `PUT` whose `#[serde(default)]` cap fields defaulted to empty).
2. **Mutation method (the load-bearing bit)** — a `SessionRegistry::<verb>_<thing>` that holds `self.shared.persist_lock` ACROSS **resolve current state → dup/absent/validity check → mutate → persist → live re-register**, so the read-modify-write is atomic (no TOCTOU). Precedents: `patch_agent` + `mutate_agent_element` (FI-31), `refresh_skills_after_write` (FI-32). When merging, resolve the CURRENT effective entry and apply ONLY patch-present fields onto the WHOLE resolved struct — preserve fields outside the patch surface (FI-31 `patch_agent` preserves `system_prompt_path`/`permissions_path`/`memory`; a reconstruct-then-update path would drop them). Extract the shared critical section into one private helper (`persist_replacement_entry_locked`) so every verb reuses it.
3. **Live re-register** — after persist, re-register so the NEXT session reflects the change WITHOUT a daemon restart: `insert_runtime_entry` (agent CRUD) or `refresh_all_*_cells` (a daemon-wide `ArcSwapOption` cell, mirror `merged_permissions` at assemble.rs; FI-32 flipped `skill_set` `Option<Arc>` → `ArcSwapOption` + a `refresh_all_skill_cells` cloning `refresh_all_permission_cells_from_fresh_base`). Carry a `has_live_sessions_for` drain-guard where an in-flight session must not be orphaned. Restart-only is a REGRESSION if the sibling CRUD is already live.
4. **Error dispositions** — dup add → **409** (a NEW `IpcError::Conflict(String)` + a `From<IpcError>::Conflict => ApiError::Conflict` bridge arm; `ApiError::Conflict`→409 shipped FI-27); absent DELETE → **404** (`IpcError::NotFound`); invalid name / path-traversal / unknown-dir → **400** (reuse `validate_layer_name` — charset + explicit `..`/`/` reject BEFORE any fs touch); non-writable target → **403** (`ApiError::Forbidden` + a live `access(W_OK)`-style `probe_dir_writable`); oversized body → **413**. Do the dup/absent check INSIDE the persist_lock critical section.
5. **Secrets on write** — a write MAY accept a secret (an MCP `env`, an api_key) but it is **never read back** on any GET (the read-shim redaction contract holds); prove it in a test.
6. **Route + openapi + ZERO phi-core** — register on the `/v1` nest (401 free); a merge PATCH collapses onto the existing `/{id}` key (+0 path keys, FI-27 `/models/:id` precedent), a new element route adds keys; bump the openapi floor accordingly (re-read the current floor — it shifts across a sequential batch). `use phi_core` unchanged; the writer is pure i-phi (atomic write via `memory::file_store::atomic_write`).

## Tests (MUST-SHIP)

- The **disposition** test: the mutation survives + applies — a scalar-only merge PATCH preserves every capability (FI-31 `scalar_only_patch_preserves_all_capabilities`); a written skill reaches a new session's render (FI-32 `skills_hot_reload_test`).
- dup→409, absent→404, traversal/unknown→400, non-writable→403, oversized→413, secret-never-read-back, 401.

## Live close-gate (REQUIRED — Rule 4 + Rule 8)

Boot the real daemon; drive the write over HTTP; then assert the DISPOSITION where the fix MANIFESTS: the model WIRE (a new session's rendered prompt reflects the write, no restart) AND/OR the on-disk artifact (the `credentials.toml` sub-tables survive; the `SKILL.md` bytes re-parse). Exercise 409/404/400/403/413 live. For a permission-gated model-facing surface, put the capability on the DEFAULT agent (the surface builds the representative default) + satisfy the headless catalog-filter with a user-scope `permissions.toml allow=[...]` (the daemon-wide `[permissions]` block takes only interactive/timeouts — see the FI-33 fixture recipe). Use the `live-close-gate` skill as the driver.

## Reference cycles

FI-31 (`62485f49`, capability writes + merge-fix, ADR-0090), FI-32 (`8a8c8c03`, skill authoring + hot-reload, ADR-0091). Codified 2026-09-10 per FI+KC joint-retro `48537f70` prop 2.

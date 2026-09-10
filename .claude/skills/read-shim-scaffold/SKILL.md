---
name: read-shim-scaffold
description: Scaffold a read-only /v1 GET surface on i-phi that projects an in-process/config structure to the frontend without leaking secrets. Codifies the 4×-reproducible read-shim pipeline (FI-03 /v1/models, FI-13 /v1/config, FI-29 /v1/skills, FI-30 /v1/mcp): key-free-by-construction DTO → SessionRegistry accessor → thin auth-inherited route → openapi floor +1 → ZERO phi-core → disposition-asserting live close-gate. Invoke when a chunk adds a GET /v1/<x> that surfaces daemon/agent state.
---

# read-shim-scaffold

A read-only `/v1` GET surface that projects an in-process or config structure to the frontend. Reproduced identically 4× on i-phi (FI-03 `/v1/models`, FI-13 `/v1/config`, FI-29 `/v1/skills`, FI-30 `/v1/mcp`) — this turns the re-derivation into a fill-in-the-blanks pass.

## The invariant (fill each blank)

1. **Source** — the in-process / config structure to project (e.g. `DaemonConfig.<section>`, an aggregated per-agent map, a loaded `SkillSet`). Read it via the ArcSwap snapshot or the loader; NEVER re-load from disk in the projection (the catalog must be faithful to what the model sees).
2. **Key-free-by-construction DTO** — a NEW `<Name>View` struct in `src/daemon/ipc/protocol.rs`. **Redaction by projection**: NO field may hold a secret VALUE, so no serializer can ever leak one. Precedents: `ProviderArmView { has_key, api_key_env, default_model_id }` (never `api_key`), `McpServerView { …, env_var_names }` (`env.keys()` only, never `env` values), `ModelInfo`, `AgentDetail`. If a secret exists in the source, project its NAME / a boolean / a redacted shape — never the value. Derive `ToSchema`. Drop `Eq` only if a field is a float.
3. **Accessor chain** — a `SessionRegistry::<x>_catalog()` (async) that reads the source snapshot and builds the `Vec<<Name>View>`; the empty/absent case returns `Vec::new()` (`None => []`), never an error. Mirror an existing accessor (`model_catalog` / `mcp_registry` / `skills_catalog`). If daemon-wide aggregation is needed, fold per-agent contributions + dedup by the natural key + accumulate `used_by_agents`.
4. **Thin route** — `src/api/routes/<x>.rs` `GET /v1/<x>` handler calling the accessor; register on the `/v1` nest so **auth is inherited** (401 is free — do NOT re-add auth). One `#[utoipa::path]`.
5. **openapi floor +1** — bump the floor assertion in `src/api/openapi.rs` (find it: `grep -n "paths >=" src/api/openapi.rs`). One new path key. NOTE: the floor is a conservative minimum, and prior chunks may have shifted it — re-read the current value, do not trust a plan's pre-batch snapshot (see the CLAUDE.md sequential-batch baseline-shift callout).
6. **ZERO phi-core** — `grep -rc "use phi_core" src | awk -F: '{s+=$2} END{print s}'` MUST be unchanged (98 at the FI-33 baseline). The projection reads already-imported phi-core surfaces; it adds no `use phi_core` line.

## Tests (MUST-SHIP)

- A round-trip / faithfulness test: the projected catalog name-set == the source's advertised set (e.g. `<available_skills>` == the skills catalog; the config view == the effective config).
- A **redaction** test where the source carries a secret: assert the secret VALUE is ABSENT from the serialized DTO (structural, not just this instance).
- `[]` on empty source; 401 without token; the openapi floor test amended to the new floor.

## Live close-gate (REQUIRED — assert the DISPOSITION, not no-200)

Boot the real daemon with a fixture that carries the projected structure INCLUDING a secret. `GET /v1/<x>` → grep the RAW wire: the secret VALUE is absent, the projected names/booleans are present, the aggregation/dedup is correct, 401 without token, openapi floor holds. Use the `live-close-gate` skill as the driver. "no-200 / well-formed" is necessary but NOT sufficient — assert the faithfulness + env-value-absence disposition against the rendered wire (`[[feedback_render_transcript_close_gate]]` Rule 4).

## Reference cycles

FI-13 (`9715fdb7`, config view), FI-29 (`53c61679`, skills catalog + `used_by_agents` UNION), FI-30 (`a2aa016f`, MCP registry env-redacted). ADRs 0071 / 0088 / 0089. Codified 2026-09-10 per FI+KC joint-retro `48537f70` prop 2.

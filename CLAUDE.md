# lucy_agent

A Gleam reimplementation of the core agent loop from [grok-build](https://github.com/xai-org/grok-build)
(xAI's Rust terminal coding agent: a model in a loop with file + shell tools).

Built by working through [docs/gleam-agent-curriculum.html](docs/gleam-agent-curriculum.html)
phase by phase. Open it in a browser — it's an interactive checklist, not prose.

## ⚠️ This is a learning project. Do not write Gleam for me.

I am learning Gleam by typing every line myself. Code you write is code I don't learn.

When I'm working a curriculum task (I'll name it, e.g. "3.2"), you:

- explain the **concept**, and decode compiler errors into what they mean
- point me at the right stdlib function, type, or docs page — the name, not the call site
- review code **I** wrote: name what's wrong and why; let me write the fix
- ask what I've tried when I'm stuck

You do **not**:

- write or edit `src/*.gleam` for a curriculum task
- paste a working implementation — including "just as an example" or "here's the shape"
- fix my code without being asked, or sneak the answer into an explanation

**Exceptions**, only on an explicit ask:

- "just show me" / "write it" / "I give up on this one" → then write it, no lecture
- pure meta with no Gleam in it: `.gitignore`, this file, git

**Commands that create or change the project are mine to run, not yours** — `gleam new`,
`gleam add`, `gleam run`. Hand me the command and explain the flags; don't execute it.
This includes scaffolding: I want the muscle memory. Read-only checks are yours to run
freely: `gleam check`, `gleam build`, `--help`, `cat`, `git status`, `curl`.

Ambiguous ask? Assume I want a hint, not a solution. I'll escalate if I want the code.

## Where I am

**Phase 0, task 0.1** — Gleam 1.16 / OTP 28 installed and verified. Not yet scaffolded.
Remaining: `gleam new`, edit `main` to print the banner, `gleam run`.

Update this line when a phase completes. Phase map:

| Phase | What lands | Key idea |
|---|---|---|
| 0 | `console.gleam` echo loop | Result, `case`, `\|>`, Erlang FFI |
| 1 | `ask(history) -> Result(String, AgentError)` | JSON by hand, custom error types |
| 2 | chat REPL with history | the API is stateless; **you** are the memory |
| 3 | **the agent loop** — `run_until_done(history)` | tool schemas, `tool_use` blocks, `stop_reason` |
| 4 | `write_file`, `run_shell`, y/n gate | capability control, human-in-the-loop |
| 5 | SSE streaming (optional) | httpc's weak spot — skippable |
| 6 | actor per conversation | the payoff for picking Gleam over Rust |
| 7 | retries, cost tracking, MCP client | each maps to a grok-build crate |

Phase 3 is the heart. Budget it as long as 0–2 combined.

## Commands

```sh
gleam run          # build + run main
gleam test         # gleeunit
gleam check        # typecheck only — fastest feedback loop
gleam format       # run before committing
gleam add <pkg>    # gleam_http, gleam_httpc, gleam_json, envoy, simplifile, gleam_otp
gleam deps download
```

Requires Erlang/OTP + Gleam (`brew install gleam erlang`). Target is Erlang, not JS —
the whole point is the BEAM in Phase 6.

## Anthropic API facts (verified 2026-07-17 — trust these over the curriculum)

The curriculum's Phase 1 is accurate; these are the details worth pinning.

```
POST https://api.anthropic.com/v1/messages
x-api-key: $ANTHROPIC_API_KEY
anthropic-version: 2023-06-01
content-type: application/json
```

- **Model**: use `claude-opus-4-8`. The curriculum shows `claude-sonnet-4-6` — that is
  also a valid, active ID and is cheaper ($3/$15 vs $5/$25 per MTok); my call, either works.
  Never invent IDs or append date suffixes; they 404.
- **`max_tokens`**: 1024 is fine through Phase 2. Raise to ~16000 once the agent loop
  starts returning tool calls, or replies truncate mid-thought.
- **`content` is a list of typed blocks**, never a string. This is the single most
  important shape in the project — Phase 1.3 exists to make me stare at it:
  - `{"type": "text", "text": "..."}`
  - `{"type": "tool_use", "id": "toolu_...", "name": "read_file", "input": {...}}`
- **`stop_reason`** drives the Phase 3 loop: `end_turn` | `tool_use` | `max_tokens` |
  `stop_sequence` | `pause_turn` | `refusal`. Loop while `tool_use`; stop on `end_turn`.
- **Tool result round-trip** — append *two* messages, results go in a `user` turn:
  ```json
  {"role": "assistant", "content": [{"type": "tool_use", "id": "toolu_1", ...}]}
  {"role": "user", "content": [{"type": "tool_result", "tool_use_id": "toolu_1", "content": "..."}]}
  ```
  Every `tool_use` id needs a matching `tool_result` or the next call 400s.
- **No assistant prefill** on current models — a trailing `assistant` message returns 400.
- Gleam has no official Anthropic SDK. Raw HTTP via `gleam_httpc` is the correct and
  only path — that's a real constraint, not a curriculum simplification.

**Debugging tip worth repeating to me**: when a decoder fails, `curl` the endpoint and
read the actual JSON before touching Gleam. Guessing at the wire format is the slow way.

## Gleam things I'll trip on

- **No loops.** Recursion only. `loop(history)` calls `loop([reply, ..history])`.
- **No `#[derive(Serialize)]`.** Encoders/decoders are written by hand. This is
  deliberate — the wire format and the domain model are allowed to differ.
- **Decoders compose oddly.** Each `use x <- decode.field(...)` peels one field.
  Expect Phase 1.4 to hurt; the compiler errors *are* the tutorial.
- **`let assert`** is fine for warm-ups, but Phase 1.5 replaces it with a real
  `AgentError` type. Don't let me leave `let assert` in the agent loop.
- **FFI is the escape hatch**: `@external(erlang, "io", "get_line")`. Phase 0.3 teaches
  it so Phase 4.2 (`os:cmd`) is easy.
- Prefer `gleam check` over `gleam run` while iterating — much faster.

## Code style

Comments: only for a non-obvious invariant that can't be expressed in code. Applies to
scaffolding you write; my curriculum code is mine to comment however helps me learn.

# Do It Later

> **todo_or_die for AI agents.** Say "I'll do it later" — and actually get tripped later.

Agents (and the humans driving them) defer things in conversation all the time: *"we'll test
that once X lands"*, *"revisit after the refactor"*, *"do it later"*. A deferral without a
real trigger is a **silent kill** — sessions end, context dies, and nothing ever comes back
for the commitment. Recent prospective-memory benchmarks for LLMs
([PM-Bench](https://arxiv.org/abs/2607.12385), [TriggerBench](https://arxiv.org/abs/2606.23459))
report that even frontier models are unreliable at spontaneously remembering to act on
deferred intentions — relying on the model to recall is a losing bet.

**Do It Later** takes the opposite route: *don't make the model remember — make the machine
trip.* Commitments go into a plain-TSV ledger with a **machine-decidable condition**, and
**mechanical ignition surfaces** push them back into the conversation when the condition
holds. Ignition rate = event rate, independent of model recall.

The name is the crime: the phrase this tool polices is the phrase that invokes it.

## How it works

```
"let's do it later"                      SessionStart hook (every session)
        │                                        │ due/invalid/malformed?
        ▼                                        ▼
~/.claude/memory/deferrals.tsv  ──scan──►  [pm-ledger] block in context:
  id | due | check | action | context      "disposition each: do / re-condition / kill"
```

- **Condition** = a due date (`2026-09-16`, fires when today ≥ due) **or** a shell check
  (`grep -q needle config`, fires when it exits 0). *"When it matures" is not a condition* —
  `add` rejects condition-less rows, and any that sneak in come out as INVALID red.
- **Context** rides along: each row carries a self-contained line that lets a cold session
  resume the work without the original conversation.
- **Green is silent**: when nothing is due, the hook injects zero tokens.
- **Malformed rows are red, never invisible**: wrong column count, empty fields, bad status,
  bad dates — all surface as MALFORMED (scan exit 1, `doctor` finding). A commitment that
  quietly disappears is the exact failure this tool exists to prevent.

## Install

Requires: bash, awk, python3 (install script only). Claude Code as the host harness.

```bash
git clone https://github.com/zl190/do-it-later ~/do-it-later
~/do-it-later/install.sh
```

`install.sh` does exactly two things, idempotently: symlinks the repo into
`~/.claude/skills/do-it-later`, and registers the SessionStart hook in
`~/.claude/settings.json` (backing the file up first to `settings.json.bak.<timestamp>`).
`uninstall.sh` reverses both. New settings take effect from the next session.

Verify:

```bash
bash ~/do-it-later/tests/run.sh
```

32 mutation self-checks: due must red / not-due must green, both directions, plus ledger
integrity, TSV-injection guards, and lifecycle round-trips. Runs against a temp ledger —
your real one is untouched.

## Use

```bash
S=~/.claude/skills/do-it-later/scripts/scan.sh

bash $S add fix-flaky-timer --due 2026-09-01 \
  --action "revisit the flaky timer test after the scheduler rewrite lands" \
  --context "test: tests/timer.spec.ts; flake repro: run 20x; suspect: fake-clock drift"

bash $S add bump-node --check '[ $(node -v | cut -c2-3) -ge 24 ]' \
  --action "drop the polyfill once node >= 24 is the floor" \
  --context "polyfill lives in src/compat.ts; delete + run full suite"

bash $S list            # the queue, with DUE!/INVALID markers
bash $S fire <id>       # start one manually, don't wait for the trigger
bash $S done <id>       # finished
bash $S kill <id> "superseded by the v2 design"   # honest kill, reason required
bash $S doctor          # integrity + ignition-surface liveness findings
```

In-session, the skill (SKILL.md) teaches the agent the other half: capture deferral language
into the ledger as it happens, sweep the conversation at wrap-up, and disposition every
tripped commitment instead of sliding past.

## When this does NOT work (honest boundary)

Three conditions must all hold: **captured** (it's in the ledger) ∧ **decidable** (the
condition is a date or an exit code) ∧ **live** (the ignition surface actually runs).

- Not captured → the machine is silent forever. Capture is model-side discipline; the skill
  narrows the gap (trigger phrases + wrap-up sweep) but cannot close it.
- Subjective condition → rejected at `add`; smuggled-in rows show as INVALID. That is
  exposure, not a solution.
- Dead surface → `doctor` catches known shapes (unregistered hook, unknown surface name);
  a scheduler job cannot be liveness-checked from bash — verify it in the scheduler itself.

Also: `check` commands are run by `scan` — keep them instant, read-only, idempotent. There
is no sandbox and no timeout around them (a slow check delays every session start).

## Related work

- [todo_or_die](https://github.com/searls/todo_or_die) (Ruby) / [expiring-todo-comments](https://github.com/sindresorhus/eslint-plugin-unicorn/blob/main/docs/rules/expiring-todo-comments.md)
  (eslint): the same semantics for code comments, tripped in build/lint runtimes. This tool
  moves both ends: capture from **conversation**, ignite on **agent-session events**. One
  cautionary tale ported as a design rule: the eslint rule ships `checkDates: false` — its
  flagship semantic is dead by default. Here, date firing is always on, no environment guards.
- Continuity/session-state ledgers and agent-memory skills (e.g. Continuity Ledger, Agent
  Memory): **retrospective** — they preserve what happened for later recall. This ledger is
  **prospective** — commitments with tripwires. Complementary, not competing.
- Prospective-memory research (PM-Bench, TriggerBench; commitment-record vocabulary from the
  [Always-On agents survey](https://arxiv.org/abs/2606.30306)): benchmarks the model-recall
  route this tool deliberately avoids.

## License

MIT

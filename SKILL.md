---
name: do-it-later
description: >-
  Prospective-memory ledger for agents: todo_or_die for conversations. The moment an AI (or
  you) says "I'll do it later / after X / next time / defer / park" about a real commitment,
  capture it into a machine-scannable ledger (~/.claude/memory/deferrals.tsv) with a
  MACHINE-DECIDABLE condition (a due date, or a shell check command), and let mechanical
  ignition surfaces (a SessionStart hook / your scheduler / manual fire) trip it back into the
  conversation when the condition holds; ignition rate = event rate, independent of model
  recall. Use when deferring anything beyond the current session, at session wrap-up (sweep
  the conversation for uncaptured deferral language), when the user says "defer / ledger /
  deferral", when a [pm-ledger] block appears in session context (due commitments; process
  each one: fire→done / re-condition / kill), or to run list/fire/done/kill/doctor on the
  ledger. NOT a todo app (no priorities, no planning) and NOT retrospective memory (facts
  belong in your notes); only commitments with a tripwire.
---

# do-it-later: a prospective-memory ledger (todo_or_die for agents)

One sentence: **don't make the model remember; make the machine trip.**
"I'll do it later" without a real trigger is a silent kill. A commitment that enters the
ledger gets tripped back into the conversation by a mechanical event (session start, a
scheduled job, or a manual fire), when a machine-decidable condition holds.

## Data contract

```
ledger  ~/.claude/memory/deferrals.tsv   (override with env PM_LEDGER — tests use this)
schema  id | due | check | action | context | stakes | surface | source | status | created
cond    due   = YYYY-MM-DD; fires when today >= due (lexicographic compare, no date math)
        check = shell command; fires when it exits 0 (must be instant, read-only, idempotent)
        at least one required; a row with neither is INVALID and turns the scan red —
        subjective conditions ("when it matures", "when I have time") are not admissible
context SELF-CONTAINED: one line that lets a cold session resume the work without the
        original conversation (or a path to a context file)
surface session-start | cron:<name> | manual   (doctor liveness-checks these)
status  pending | done | killed   (kill requires a reason, recorded in context)
log     deferrals-usage.log next to the ledger (one line per scan/fire/done/... — read it
        before claiming the tool is used; installs are not usage)
red     scan exits 1 when any row is DUE, INVALID, or MALFORMED (bad column count / empty
        field / bad status / bad due) — malformed rows must never be silently invisible
```

## Verbs (engine = `scripts/scan.sh`)

```sh
S=~/.claude/skills/do-it-later/scripts/scan.sh
bash $S scan                # due/invalid/malformed -> red (exit 1) with details; else green
bash $S list                # full status table (DUE!/INVALID/pending/done/killed)
bash $S fire <id>           # manual ignition: print action+context, start now
bash $S done <id>           # finished
bash $S kill <id> <reason>  # honest kill (reason required)
bash $S add <id> --due 2026-09-01 --action "..." --context "..." \
       [--check 'cmd'] [--stakes low|med|high] [--surface session-start] [--source ...]
bash $S doctor              # surface liveness + ledger integrity findings
```

## Capture discipline (what enters the ledger)

1. **The 15-minute branch**: if the work takes ≤15 min with hot context, no external
   dependency, and is reversible: do it now, don't ledger it. Legitimate reasons to defer:
   option value, missing input/timing, or waiting on an owner decision.
2. **Conditions must be machine-decidable.** "When it matures" is not a condition: translate
   it to a due/check, do it now, or kill it honestly. `add` rejects condition-less rows;
   anything that sneaks in comes out as INVALID red.
3. **Check hygiene**: instant, read-only, idempotent. Examples:
   `[ $(ls ~/x/tasks | wc -l) -gt 20 ]`, `grep -q needle ~/some/config`. Slow or networked
   conditions belong on a scheduled surface, not in a check.
4. **Session wrap-up sweep**: every "later / next time / after X" said this session either
   entered the ledger or got done on the spot. This is the last net for the capture side.

## Ignition surfaces

| surface | carrier | grade |
|---|---|---|
| `session-start` | `hooks/session-start-deferrals.sh` (registered by install.sh; green = silent, zero tokens injected) | A: every session walks through it |
| `cron:<name>` | your scheduler (for slow/periodic conditions) | A if the job actually runs; `doctor` can only mark it unverifiable from bash |
| `manual` | `fire <id>` | C: pure self-discipline; only park things you can afford to lose |

**Disposition protocol**: when a `[pm-ledger]` block appears in session context, every listed
commitment must be dispositioned: fire→done / re-condition (with a reason) / kill (with a
reason). Never silently slide past.

## Honest boundary (when this does NOT work)

It works only when three things all hold: the commitment entered the ledger ∧ the condition
is machine-decidable ∧ the ignition surface is actually running. Break any one and the
machine is silent: an uncaptured commitment is invisible to scan forever; a subjective
condition is rejected at add (and INVALID-red if smuggled in; that's exposure, not a
solution); a dead surface is caught by `doctor` only for known shapes (unregistered hook,
unknown surface name); a cron surface can't be liveness-checked from bash.

## Lineage

Ports [todo_or_die](https://github.com/searls/todo_or_die) (due = red, not a reminder) and
[eslint expiring-todo-comments](https://github.com/sindresorhus/eslint-plugin-unicorn/blob/main/docs/rules/expiring-todo-comments.md)
non-date conditions (its `checkDates: false` default, the flagship semantic shipping dead,
is the cautionary tale: our date firing is always on, no environment guards), plus stalebot's
orphan semantics (doctor). Commitment-record vocabulary follows the Always-On agents survey
(arXiv 2606.30306). Prospective-memory benchmarks: PM-Bench (arXiv 2607.12385), TriggerBench
(arXiv 2606.23459).

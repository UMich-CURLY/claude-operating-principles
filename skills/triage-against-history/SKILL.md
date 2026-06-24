---
name: triage-against-history
description: When responding to structured feedback (paper reviews, bug reports, PR comments, regressions, user pushback), first triage each item against persistent records of prior work — classifying as already-addressed, prose-stale, or genuinely-new — before editing anything. Outputs a focused worklist that minimizes redundant work across iteration rounds.
---

# triage-against-history

When the user pastes a review, bug report, code review comments, regression report, or any structured feedback, **do not start fixing items immediately**. First triage against the persistent record of prior work in that domain.

## When to invoke

- A new TMLR/journal/conference review pastes in.
- A user shares a list of bugs/issues/concerns.
- A code reviewer leaves PR comments.
- A test sweep reports regressions.
- Any time feedback arrives that overlaps with prior feedback in the same project.

## Process

1. **Identify the domain and locate the persistent catalog.**
   - Paper revisions: `REVIEWER_CONCERNS.md` in the paper repo, or memory entries tagged `feedback`
   - Bug reports: previous postmortems in the relevant module, or commit messages with `fix:` prefix
   - Code reviews: prior review comments in the PR, or memory entries about coding style/conventions
   - User feedback: memory entries with `type: feedback`

   If no catalog exists, **scan recent commits and memory for the same concerns** — and create the catalog file as the triage output.

2. **For each item in the new feedback, classify into one of:**
   - **A. Already-addressed, prose accurate.** Identify the existing file:line where the fix lives. No edit needed; in the response, point to the location.
   - **B. Already-addressed, but related prose is stale.** Identify the addressed location AND the stale location. Plan a targeted prose update.
   - **C. Genuinely new.** Plan a real fix with the smallest viable change (see `decision-gate` skill for non-trivial fixes).
   - **D. Out of scope / compute-bound / defer.** Note explicitly so the user can decide.

3. **Output the triage as a table before doing any work:**

   | # | Item (short) | Class | Existing location | Action |
   |---|---|---|---|---|
   | 1 | ... | A | file:line | (none, point to location) |
   | 2 | ... | B | file:line + stale-file:line | (targeted edit) |
   | 3 | ... | C | — | (small new fix) |
   | 4 | ... | D | — | (defer, note why) |

4. **Confirm with the user before executing** if the triage materially shrinks the worklist (e.g., 30 items → 6 actionable). The user may want to see the rationale.

5. **Execute only Class B and C items.** Class A items get acknowledged in the response but no edit.

6. **Update the catalog after the pass.** Append new items: concern, file:line of fix, current artifact-side wording, commit hash. Future passes use the updated catalog.

## Anti-patterns this prevents

- Re-fixing the same concern in 3+ rounds with slightly different reviewer wording.
- Adding defensive prose that compounds across rounds (each round adds, none deletes).
- Wasting compute on already-verified empirical items.
- Treating each new review as a fresh wave instead of incremental delta.
- Saying "I've already addressed this" without pointing to where.

## A reproduced failure is history too

Triage applies to your *own* retries, not just external feedback. When a recovery
action (retry, re-dispatch, re-run) lands in the **identical** failure state — same
status, same frozen timestamps, same null/empty fields — treat that as evidence the
cause is external/systemic (capacity, quota, a stuck dependency), not transient.
Stop retrying; diagnose the shared dependency or shrink the request instead. Two
identical failures cost double and teach the same lesson once.

- **"Too long" is measured in clock time, not turns.** Before calling something
  stuck/slow, read the actual elapsed time from authoritative timestamps
  (`started_at`/`created_at`) and compare it to the operation's normal latency
  budget (e.g. GPU provisioning + dataset build is ~10–30 min). An agent's felt
  sense of duration across many turns or interrupts is not a clock — don't escalate
  on it.

- **For environment-specific behavior, a human operator is a primary source —
  consult before brute-forcing.** Schedulers, quotas, CI, and shared infra have
  "normal" regimes that look like bugs (a job queued for days, a flaky timeout, a
  capacity wall). Once a reproduced failure says "systemic," don't just keep
  retrying or build elaborate workarounds — ask someone who runs the system; they
  often know both that it's expected and the standard workaround (e.g. "8-node jobs
  queue for days; use fewer / different-pool nodes"). Cheap question, expensive
  guesses.

## Attribute a failure to the harness vs the target before acting on it

A cheap validation harness (smoke test, local repro, CI shim) often loads, configures,
or runs the target differently than production. When it goes RED, decide whether the
failure lives in the *target* or only in the *harness* before any destructive action
(cancelling the real run, reverting, paging someone).

- **Signals it's a harness artifact:** an environment/path/permission error (container
  path absent locally, root-owned dir, missing local asset) or a failure that only
  triggers under a harness-only branch (a local-only config merge, a debug flag, a mock).
  These do not exist on the real target.
- **Reproduce the EXACT runtime transform, not a simplified stand-in.** If "the config
  looks clean but the run disagrees," replicate every post-load mutation the real
  entrypoint applies (env-conditional merges, overrides, monkeypatches) and inspect the
  object the code *actually instantiates* — not a freshly-composed/idealized one. A
  static view that skips a runtime merge will lie. (Here: a plain `compose()` showed
  clean readers; the trainer's `IS_LOCAL_ENV`-only `merge(cfg, cfg.local_override)`
  clobbered them — only reproducing that merge revealed it.)
- **A harness-only RED is not grounds to kill the real target.** Fix the harness so it
  faithfully exercises the target, then re-gate — don't cancel a production run the
  failure never applied to.

## When to override

If the user explicitly says "just fix all of them" or "don't triage, just do it," skip the table and proceed. Note that the user is overriding to maintain the contract.

## Notes

- The triage *itself* is the first thing the user sees — make it tight.
- Class C items often deserve a `decision-gate` pass if they involve non-trivial changes.
- Class D items (defer) should name the reason (compute, scope, blocked-on-input).

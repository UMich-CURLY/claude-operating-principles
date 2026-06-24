---
name: pin-and-trace
description: When writing any value, claim, or decision into a durable artifact (paper, README, doc, slides, config, code constant), enforce the single-source-of-truth rule — identify the canonical file/commit/JSON it lives in, and ensure the artifact references it rather than restates it. Prevents stale numbers, drift, and re-derivation across rounds of revision.
---

# pin-and-trace

Whenever you are about to write a number, claim, or decision into a durable artifact, first ask: *where is the canonical source of this value, and is it pinned?*

## When to invoke

- Writing benchmark numbers into a paper (accuracies, runtimes, parameter counts).
- Restating an architectural decision in multiple documents (paper + README + slides).
- Adding a hyperparameter into multiple configs.
- Quoting a theorem statement in two places (abstract + theorem environment).
- Updating a file after an experiment changes the underlying numbers.

## Process

1. **Identify the canonical source for each piece of content:**
   - Numbers (metrics, runtimes, sizes): a results JSON, CSV, or generated table file
   - Claims (theorem statements, architecture-vs-theorem coverage): a single `CLAIMS.md` or LaTeX file
   - Decisions (architecture defaults, hyperparameters): a single config file
   - State (TODOs, in-flight work, blockers): a single STATUS file
   - Citations / bibliographic entries: a single `.bib` file

2. **If the source exists, reference it from the artifact:**
   - LaTeX: `\input{tables/results.tex}` (auto-generated from JSON)
   - Markdown: link to the canonical doc
   - Code: import the constant from one location
   - Slides: cite the paper section, not a re-typed number

3. **If the source doesn't exist yet, create it before writing the value anywhere else.** Resist inlining values "just this once" — that's where drift starts.

4. **When the source changes (e.g., after re-running an experiment):**
   - Update the source.
   - Grep the artifact for the old value or pinned reference.
   - Update all locations or confirm they auto-update.
   - Commit the source change and the artifact update together.

5. **When in doubt about whether a number is stale**, trace it back to the source. If the trace fails (the source is gone, the JSON has different numbers), the value in the artifact is suspect.

## Examples

- **Paper writes a benchmark number.** Don't type `0.908` inline. Reference `results/parity_final.json` (commit hash) and ideally generate the table from the JSON.
- **README mentions a feature.** Link to the canonical doc (`docs/architecture.md`); don't paraphrase.
- **Slides quote a paper result.** "See Sec. 6.1 of the paper" beats re-typing the number.
- **Two docs describe the same architecture.** One CANONICAL.md, others reference it with a `> see X for details` line.
- **A constant appears in 3 configs.** Move to a shared config; import everywhere.

## Anti-patterns this prevents

- Stale numbers after empirical changes (the dominant source of multi-round paper-revision pain).
- Inconsistent claims across abstract, intro, theorem, and conclusion.
- Drift between documentation and implementation.
- Re-deriving values that already exist in a JSON or config.
- "I'll just type it here, I'll fix it later" — later never comes.

## When to break the rule

For one-off prose explanations where literal numbers are needed for readability (e.g., "the model achieves 90.8% accuracy on..."), inline them — but **tag the location with a `% PIN: file.json:run-3-seed-mean` comment** pointing to the source. Periodically sweep tagged locations for consistency.

## Sweep procedure

When asked to "verify the paper" or "check the numbers" or after re-running experiments:
1. Grep the artifact for digits matching the metrics format (e.g., `0\.\d{3,4}`, `\d{2}\.\d`).
2. For each hit, identify the source it should match.
3. Compare; flag mismatches.
4. Either update artifact or note in commit message what changed.

## One coherent source per comparison

When several values are compared side by side (a table, a benchmark, an A/B
result, a before/after), every cell must come from **one coherent run / source**
under the same protocol — never spliced across runs, configs, seeds, or
hardware. Mixing sources silently produces contradictions (e.g. a prose summary
citing one run while the table cites another).

- Refresh comparison cells **together**, from a single regeneration, even the
  ones you think didn't change.
- If one cell genuinely comes from a different protocol, label that explicitly;
  don't present it as comparable.
- After any re-run, grep the prose for the old comparison numbers and confirm
  they match the regenerated table.

## Resource caps trace to a cost model — verify the model, not the knob

Before a timeout, cap, or budget (max execution time, token/disk quota, batch
size, retry limit) becomes load-bearing, confirm the actual unit and scaling of
what it gates by reading the code path or runtime behavior — not the config name
or comment.

- Ask the scaling questions explicitly: is this count **per-process or global?
  sharded or replicated? per-item or total?** The "obvious" reading is often wrong.
- A config name or comment is a *claim*, not the source of truth. Trace it to where
  the value is consumed (the loop bound, the sampler, the allocator).
- A cap set against the wrong cost model **fails silently** — it looks generous and
  still truncates the work. Example: a `num_samples` knob read as "total per epoch"
  but applied *per-rank, unsharded* makes a 48h cap silently cut a run that needs
  ~80h on 64 GPUs; verifying `steps_per_epoch = num_samples // batch_size` (no
  world-size division) in the trainer surfaced it before committing the run.

## Diagnosing auth / permission / control failures — trace to the authoritative scope

When an action is denied or appears to fail, the message in front of you is a
claim about state, not the state itself. Trace it before acting on it.

- **A cached credential is a snapshot of permissions at issuance.** Granting a
  role/scope does not update a token already minted — re-issuance (re-login) is
  required. A 401/403 right after a grant is usually a stale token, not a missing
  grant. (Watch for `--auto-renew`-style flags that *keep* a valid-but-stale token
  instead of forcing a fresh one.)
- **A permission error can be scope-blind.** When a 401/403 names "the roles you
  currently have," confirm *which scope* (namespace/tenant/project/region) it
  evaluated — it may be reporting a default context, not the one your command
  targets. The fix is often a scope flag (e.g. `-n <namespace>`), not a new grant.
- **A control surface may be cosmetic.** Before trusting that an action
  (stop/cancel/delete/deploy) took effect, confirm it in the authoritative system,
  not a dashboard that may only hold a proxy/label of the real resource (e.g. a
  W&B "Stop" relabels the run but does not kill the underlying SageMaker job).

## Resolve an instruction's referent before acting — especially destructively

A terse instruction ("those aren't reviewed", "don't ship it", "kill that") is a
claim about *intent*, and its referent is ambiguous. Before you act on it — above
all when the action is destructive or hard to reverse (cancel, delete, revert,
overwrite) — resolve what it points at.

- **Bind pronouns to the most recent topic, not the one most salient to you.**
  "those / it / that" usually points at what the *user* was just discussing, not
  at the action currently on *your* mind. Re-read the preceding 1–2 messages and
  bind the referent there first.
- **If still ambiguous, confirm the referent before the destructive act** — a
  one-line "which X — A or B?" is cheaper than reversing the wrong action.
- **A standing "don't <X>" overrides your in-flight plan.** If the user says
  "don't cancel" while you're mid-cancel, stop — even if your read of an earlier
  message seemed to justify it.
- Failure mode this prevents: reading "0.3.1 (a feature branch) isn't reviewed"
  as "*our working branch* isn't reviewed" and cancelling two wanted runs that
  "don't cancel" had just protected — then having to re-dispatch.

## Notes

- The point isn't to never restate values — it's to never restate without a traceable link.
- Build the source-of-truth file *before* you need the second mention. Friction at creation time saves multi-round headaches.
- A "pinned" number includes the commit hash of the source. Numbers without a pin are suspect.

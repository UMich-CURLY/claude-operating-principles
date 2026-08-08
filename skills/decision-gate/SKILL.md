---
name: decision-gate
description: Before any non-trivial change (architectural flip, large rewrite, expensive experiment, broad refactor), require an explicit decision gate — pass/fail criterion, cheapest experiment to inform it, fallback if it fails. Blocks the big work until the gate is set and the cheap experiment is run.
---

# decision-gate

> **Relationship to the principle skills.** This is the concrete *workflow* for gating costly/structural work. The principles beneath it live elsewhere: `diagnostic-discipline` (how cheap the gating test should be, how much certainty to buy, and "don't let one setting settle a structural decision" — the cheapest-falsifier-first + certainty-allocation law) and `decision-under-irreversibility` (used when the gated action is hard to undo). Use those two for the *why*; use this for the *how*.

For any action that costs >30 minutes of work or commits to an architectural/structural choice, **do not execute immediately**. First write down the decision gate.

## When to invoke

- The user proposes flipping an architectural default.
- A planned experiment or sweep will take >30 min of compute.
- A refactor will touch >5 files or change >300 lines.
- A library/framework choice is being made.
- A claim is being added that depends on empirical results not yet measured.

## Process

1. **State the proposed action in one line.**

2. **Write the gate explicitly:**
   - **Gate criterion** (numeric or boolean): what outcome would make us proceed with the big version? Be specific — "within seed noise" or "≥0.85 accuracy" or "no NaN in 1000 steps."
   - **Cheapest gating experiment**: the smallest measurement that tells us if the criterion is met. Target: <30 min wall-clock or <100 lines of code or 1 seed × small N.
   - **Fallback plan if the gate fails**: what's the next-cheapest move? Often it's "keep the current path and document the deviation."
   - **Borderline rule + sentinel**: how to read a result near the criterion (an explicit noise margin or tie-break, so the read is robust to noise but still catches the signal), and which sentinel metric(s) the *next* checkpoint read should prioritize — usually the largest relative mover on the cost side.
   - **Executability**: every criterion names a metric that is *already emitted* AND whose producing job is *actually scheduled* — a gate whose deciding number nothing writes is fiction, and it invites metric-shopping at readout. Drop any condition whose every outcome leads to the same action.
   - **Backfire condition**: state the failure signature that would read as "no change" under the pass threshold alone (e.g. a mechanism that can entrench the incumbent) — a gate that only tests for improvement cannot detect its own expected failure mode.
   - **Exit criterion for the line**: when opening a workstream, not just an experiment, write the done-condition now — "when do we stop polishing" is a measurement, not a future argument.
   - **Attribution unit**: usually one mechanism; deliberately a coupled pair when each member fixes the other's failure mode (isolating them buys an uninterpretable negative, not attribution). An artifact swap is gated on **every role** the artifact serves, not only the role that motivated the swap.
   - **Reuse before recompute**: before dispatching an expensive computation, check whether the artifact (or a usable subset) already exists — caches, sibling jobs, upstream stages of other pipelines that compute the same thing. Compute-once-reuse systems only pay off if you look.

3. **Show the gate to the user before running it.** They may want to refine the criterion.

4. **Run the gating experiment first.** Do not start the big action.

5. **After the gate fires:**
   - **Pass** → proceed with the big action.
   - **Fail** → execute the fallback. Do not retry the big version without re-gating.
   - **Ambiguous** → narrow the gate or run one more cheap experiment. Do not proceed on hope.

## Templates

**Architectural flip** (e.g., change a default in a model component):
- Gate: parity on headline benchmark within seed noise.
- Cheap experiment: 1–3 seeds × small N × short schedule on the headline task only.
- Fallback: keep current default; document the deviation in an appendix or footnote.

**Large rewrite**:
- Gate: new structure handles the 3 known failure cases.
- Cheap experiment: write interface signatures + 1 test per case, no implementation.
- Fallback: incremental refactor instead of clean-slate rewrite.

**Compute-expensive sweep**:
- Gate: metric moves in the expected direction on a tiny subset.
- Cheap experiment: tiny-N subset, 1 seed, 10× shorter schedule.
- Fallback: skip the full sweep; report tiny-subset result with caveat.

**Adding a claim that needs empirical support**:
- Gate: empirical signal at the smallest scale that's interpretable.
- Cheap experiment: 1 seed × default N × short schedule.
- Fallback: weaken claim to qualitative or move to "future work."

## Keep the measurement loop causally clean

Nothing inside an evaluation loop may depend on the thing being measured:

- **Anchors and targets must be exogenous.** Never calibrate a parameter against the
  system's own output (tuning a filter to reproduce labels that filter produced), and
  never let a convergence procedure iterate against a fixed benchmark without a refresh
  or holdout plan — a rigorous loop overfits an endogenous anchor *faster* than trial
  and error, not slower.
- **Denominators must be outcome-independent.** Normalizing by a quantity the treatment
  changes (per-km rates when success ends episodes early) can invert a conclusion; a
  rate can also be won by refusing to act (near-zero exposure scores safe on every
  incident rate). Check what the treatment can change before choosing the denominator;
  when two normalizations disagree, that disagreement is a finding to report, not a
  choice to make silently.
- **Intervening layers ship with counters.** Any assistive layer between the policy and
  the metric (a safety clamp, fallback selector, retry wrapper) absorbs the signal being
  measured unless its intervention rate is logged and read before crediting the system
  it wraps.

## State goals as inputs, not tuned knobs

Prefer formulations where the desired quantity is the specification, not the target of a
sweep: a constrained assignment that takes the target marginal as input over a weighted
penalty with a free coefficient; constants *solved* from a measurement (a stickiness
from a measured dwell time, a reweighting exponent from an effective-sample-size budget)
over ranges to explore; loss weights sized by their measured contribution fraction, not
by multiplier intuition (a term at 0.1% of the total needs ×300, not ×10). A free
parameter that survives must carry a stated budget. Open-ended tuning is usually the
symptom of having picked the penalty form when a constraint form existed.

## Anti-patterns this prevents

- Committing to a 3-hour sweep that crashes on the first task.
- Architectural flips that look great on one benchmark and fail on another.
- Rewrites that hit unforeseen failure modes after substantial work.
- Sunk-cost commitment to a path the data doesn't support.
- "I'll fix it as I go" plans that compound into multi-day rabbit holes.

## Don't let one setting settle a structural decision

A single dataset / benchmark / environment can be benign, noisy, or
unrepresentative. Before committing to an architectural or structural choice,
confirm the gate result holds on **at least two distinct settings** — otherwise
you may be overfitting the decision to one case.

- Open tension (calibrate, don't resolve blindly): this pulls *against* "act on
  new evidence promptly." The default reconciliation: a **single** result is
  enough to form a hypothesis and to *reverse a clearly-wrong prior claim*, but
  not enough to *commit a structural change* — that needs corroboration on a
  second setting. When the two pull hard in opposite directions, surface the
  trade-off explicitly rather than silently picking one.

## When to override

If the user explicitly asks for the big action without a gate, document the gate they're choosing to skip in one sentence and proceed. This is honest and avoids re-litigating.

## Notes

- The gating experiment should be smaller than the cost of recovering from a failed big experiment. If recovery is cheap (e.g., `git checkout`), the gate can be lighter; if recovery is expensive (e.g., 8h GPU run), the gate must be solid.
- A "fail" outcome is success at the gate level — it saved you the big run.
- Don't over-engineer the gate. The point is the next-step decision, not a publication-quality measurement.

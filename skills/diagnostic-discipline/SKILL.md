---
name: diagnostic-discipline
description: Structure an inquiry so its result is trustworthy and informative — decide what kind of problem you actually have, design tests/experiments/ablations that pin cause to a single mechanism, and allocate verification effort by the cost of being wrong. Use when choosing which experiment or ablation to run, when asking "how much should I test/prove/verify this," when a result is ambiguous about *what* caused it, when separating "figure out what's true" from "decide what to build," or when reviewing a paper, proof, or design for whether its evidence actually supports its claim. Trigger for research methodology and review as much as for code — anytime someone is deciding how much certainty to buy or how to make a result attributable, even if they don't say "experiment design." Do NOT use for chasing a specific live bug from a stack trace (that is a focused debugging loop) or for the commit decision on a hard-to-undo action (use `decision-under-irreversibility`); this skill is about designing the inquiry and spending evidence well.
---

# Diagnostic Discipline

Two failures waste more effort than wrong answers: running the wrong *kind* of investigation, and running the right kind in a way whose result can't be attributed to anything. This skill installs three habits — route the problem, design for attributability, and allocate certainty by cost — that apply equally to debugging a system, designing an ablation, and refereeing a proof.

## Habit 1 — Route the problem before working it: diagnosis vs synthesis

Decide first which problem you have, because they have opposite disciplines and conflating them is the most common methodological error.

- **Diagnosis** — resolving uncertainty about a system that already exists ("why does this happen," "is this claim true," "which component is responsible"). The discipline is *hypothesis testing against the fewest uncertain assumptions* (Habits 2–3 below).
- **Synthesis** — building something where the uncertainty is about your own design choices ("what should we build," "which architecture," "how should this be structured"). The discipline is **not** hypothesis-minimization. It is the opposite: **make assumptions explicit rather than minimal, enumerate options, impose constraints deliberately, and attach revisit-triggers.**

In synthesis, do not strip assumptions to a minimum — that is a diagnostic move and it paralyzes design. Instead:
- State assumptions explicitly so they can be challenged, rather than hiding or minimizing them.
- Impose invariants on purpose (scope boundaries, safety checks, identifiability constraints). These are deliberately *more* than the nominal task requires, and that is correct — their job is to constrain the space and prevent failure modes, not to be falsified. (Example: forbidding mode embeddings from conditioning per-mode dynamics weights is not a minimal assumption; it is an imposed invariant that protects identifiability.)
- Attach a **revisit-trigger** to each provisional choice — the observable condition (a scale threshold, a new requirement, a measured regression) that should make you reopen the decision. A provisional choice without a revisit-trigger is just an unexamined permanent one. These triggers are your explicit go/no-go gates.

When a task blends both (debugging a system you're also redesigning), sequence them: finish the diagnosis and let it set the invariants *before* synthesis is allowed to touch them.

## Habit 2 — Design every test for attributability, not just information

A test that tells you a lot but can't say *what* caused the result is often worse than a narrower test that cleanly localizes blame. Prefer the experiment, ablation, or check whose outcome most sharply **partitions the hypothesis space per unit cost** — not the one that merely yields the most data.

This is the operational form of the Duhem–Quine problem: any result lands on a *bundle* of the hypothesis plus every auxiliary assumption needed to derive the prediction. When the result is surprising you cannot tell which member of the bundle failed. So:

- **Minimize the *uncertain auxiliary* assumptions a test depends on** — not all assumptions (imposed invariants are exempt; see Habit 1), and not for elegance, but so a failure attributes to the hypothesis rather than the scaffolding.
- **Run the cheap falsifier first.** Before investing in an expensive or hard-to-reverse confirmation (a full proof, a long training run, a costly experiment), run the cheapest check that could *kill* the claim. A numerical spot-check on a generic case that disproves an invariance claim is worth more, sooner, than a careful derivation that assumes it. Order checks by their power to falsify per unit cost. This governs building as much as testing: before writing a tool that assumes access, spend one call proving that access exists where the tool will run.
- **For ablations and A/Bs:** change one mechanism at a time, or use a design that makes effects separable, so a measured difference attributes to a single cause. An ablation that moves three things at once produces information you cannot assign.
- **A fixture you authored tests the code against your model, not against the world.**
  Synthetic inputs are built from the same understanding as the code they exercise, so
  they cannot reveal that the understanding is wrong: construct a trace to overshoot 2x
  and assert 2.0, and the pair stays self-consistent while the real extraction is off by
  60x. They are the right tool for plumbing — missing inputs, degradation paths, shapes,
  absence handling — and no evidence at all about a measurement's semantics. Before a
  measurement decides anything, run it once on recorded input and reconcile against
  whatever previously measured that quantity; where nothing did, bound the result
  physically. Then keep the real-data case as a regression test. "The suite is green" is a
  statement about the fixtures.
- **Decompose aggregates before comparing or optimizing them.** An aggregate metric (a benchmark average, a headline rate) is a bundle of members; never quote it head-to-head or aim a fix at it without breaking it down by category/member first. Check for degenerate members that move all systems equally (they deflate every comparison without ranking anything) and for effects concentrated in a subset (the fix then targets that subset, not the aggregate). And when a training-side target is set, state the specific downstream observables it should move — that is what makes the later result attributable. The same holds for a **constraint set**: only some constraints are active, so measure which budgets are actually consumed before loosening "the envelope" — a set spending 97% of one budget and 50% of another is limited by the first, and raising the second is a no-op. Count **upstream supply** too: a filter returns only what entered it, so a rare case's base rate caps any threshold change, and a ceiling nothing reaches means synthesising rather than mining.
- **Settle the comparison before running it.** *Headroom*: a baseline at ceiling or
  floor can only show harm — grade where it demonstrably fails. *Position*: measure
  what the baseline imitates against the same reference you grade against; it may sit
  off its own training distribution, and that gap gets charged to your intervention.
  *Two-sided*: an intervention aimed at a rare event competes with the common one, so
  state what must improve AND what must not regress. A dose chosen to *limit damage*
  is evidence of that trade — a design fact, not a hyperparameter.
  *Range*: the instrument too — a statistic monotone by construction cannot express
  the refuting direction, so its agreement is nearly free. `max_memory_allocated`
  with no `reset_peak_memory_stats` rises under a leak and also rises-then-plateaus
  when healthy, so "it rose" is weak and "it never fell" is nothing; confirm
  against an instrument with the opposite failure mode.
- **Continuations compare only at matched progress, with an untreated control.** When a
  treatment adds training/time on top of a base artifact, either the baseline receives the
  same additional progress or the comparison is made against the base's own curve at the
  matched point — a treated late point vs an untreated early point conflates the treatment
  with elapsed progress (whose sign may be negative: curves degrade). And the
  **artifact-selection rule is part of the design**: ":latest"/"final" is a default, not a
  decision — an unexamined selection policy can both hide better artifacts and manufacture
  false beliefs about metric relationships (finals-only comparisons made a within-run
  monotonic correlation look like "no correlation").
- **When the proximal metric moves and the distal one doesn't, revise the causal model —
  not the dose.** A confirmed proximal effect with a null distal effect falsifies the
  assumed link between them; re-dosing the same mechanism buys nothing. Two failed
  same-level fixes to one recurring symptom are the signal to change mechanism.
- **There is a severity floor.** A hypothesis that assumes almost nothing also predicts almost nothing and cannot be tested sharply. Strip uncertain auxiliaries for attributability, but keep enough structure that the test would very probably have *caught* the hypothesis if it were false. Under-assuming is as much a failure as over-assuming; minimality is in service of a severe, attributable test, not an end in itself.

For uncertain assumptions you cannot remove, the Bayesian move beats hand-minimization: make them explicit and **marginalize** over them. Model comparison's Occam factor then penalizes unnecessary complexity automatically — you get parsimony by integration instead of imposing it by fiat, and more safely.

## Habit 3 — Allocate certainty by the cost of being wrong

Decide how much verification effort to spend with one law, not by feel:

> **Invest in certainty in proportion to the cost of being wrong, and inversely to the cost and irreversibility of the action that certainty gates.**

This single law generates the allocation rules each domain reinvents:
- The testing pyramid (many cheap unit tests, few expensive E2E tests) is this law applied to test types.
- Incident severity tiers (SEV1 immediate, SEV4 next business day) are this law applied to response.
- Tech-debt scoring `(Impact + Risk) × inverse-Effort` is this law applied to remediation.

Use it to build the allocation rule wherever a domain doesn't already have one. Concretely:
- **Proof vs. numerical check.** Spend proof effort in proportion to the cost of the claim being false (a published universality theorem: high) over the cost of the check (a script on the generic chart: low). High-cost-of-error claims earn a proof; cheap-to-check ones earn a falsifier first (Habit 2).
- **Coverage.** Concentrate tests on business-critical paths, error handling, security boundaries, and data integrity; skip trivial accessors and framework code. Coverage is not uniform — it follows cost-of-error.
- **Review depth.** Read the parts of a change where a defect is expensive (auth, money, data loss, irreversible side effects) far more carefully than cosmetic or easily-reverted parts.

When the action a result gates is hard to undo, this law hands off to the companion `decision-under-irreversibility` skill — there, the cost of being wrong is dominated by reversibility, and certainty must be bought before commitment.

## Quick procedure

1. **Route:** diagnosis or synthesis? In synthesis, switch to explicit-assumptions + imposed-invariants + revisit-triggers and stop reading here.
2. **For diagnosis, pick the test that most sharply attributes cause per unit cost;** run the cheapest falsifier first; minimize *uncertain auxiliaries*, keep the severity floor.
3. **Set verification effort by cost-of-error over cost-and-irreversibility-of-the-gated-action.**
4. If the gated action is hard to undo, hand off to `decision-under-irreversibility`.

## Worked examples

**Example 1 — ambiguous ablation.**
Input: "We removed the auxiliary loss and the mode embedding together and performance dropped — so the auxiliary loss matters, right?"
Response: Two mechanisms moved, so the drop attributes to neither cleanly (Habit 2). Re-run with each removed alone; prefer the design that separates them. Until then the claim "auxiliary loss matters" rests on an unattributable result.

**Example 2 — proof vs. check.**
Input: "I derived that this quantity is GL(n)-invariant; should I write up the full proof?"
Response: First run the cheapest falsifier (Habit 2) — evaluate it on a generic group element numerically. A counterexample kills it in minutes; investing the proof first risks an expensive, hard-to-reverse confirmation of a false claim. Spend the proof only after the cheap check survives, and in proportion to the cost of the claim being wrong (Habit 3).

**Example 3 — routing.**
Input: "Should we minimize our assumptions about the data distribution when designing the new pipeline?"
Response: That's synthesis, not diagnosis (Habit 1). Don't minimize — make the distributional assumptions explicit, impose the invariants you need for correctness, and attach revisit-triggers (e.g., "reopen if input volume crosses X or a new source is added"). Minimization is the discipline for *testing* a claim about the data, not for *building* the pipeline.

## Provenance and relationship to existing skills

It consolidates principles that recur, unnamed, across our work: the diagnosis-vs-synthesis split, explicit-assumptions-with-revisit-triggers, the attributability discipline, and the certainty-allocation law (which shows up in three disguises — a testing pyramid, incident severity tiers, tech-debt scoring — but is never stated as one generator).

**Boundary with `ground-truth-discipline`.** GTD owns *trust the artifact, not its representation*: keep spec/impl/prose in parity, verify claims (and guards) against the deployed system, and don't trust a value from a config file or a metric's name (config≠effective, metric-name≠definition, inherited-blocker, read-the-full-traceback). This skill owns *how to design the inquiry and how much certainty to buy*. The two meet at "run the cheapest discriminating measurement / falsifier first" — that move lives **here** (experiment design), and GTD cross-references it rather than restating it. Use GTD to decide *what is true about the running system*; use this to decide *how to find out, and how hard to look*.

**Companions:** `triage-against-history` is this skill's attributability discipline applied to one recurring confound (harness-vs-target, false-GREEN). When the inquiry gates a hard-to-undo action, hand off to `decision-under-irreversibility`. Triggering boundary: chasing a specific live failure from a stack trace is its own diagnosis loop; this skill decides *how to investigate* and *how much certainty to buy* in research, review, and design — not just bug-hunting.

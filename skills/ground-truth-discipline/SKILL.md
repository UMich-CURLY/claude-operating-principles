---
name: ground-truth-discipline
description: Foundational, apply-first discipline. Before building, optimizing, experimenting, or explaining ANY system, establish that its three representations agree — the formal spec/claim, the implementation that actually runs, and the prose/docs that describe it. They must be one. And treat every claim about what a system does or why as a hypothesis until verified against the deployed artifact and, for causal claims, an isolating measurement. A conditional/qualified claim must state its conditions where it is most prominently asserted (abstract, headline, summary), not only where it is proved. Load-bearing claims (ones many things depend on) should be confirmed by two or more INDEPENDENT routes (different methods, not the same check twice), so the foundation is trustworthy up front instead of re-audited later. Heuristics and tuning come AFTER a consistent foundation, never before.
---

# ground-truth-discipline

Most wasted time and compute traces to one mistake: **trusting a representation
of a system instead of the system itself**, and building on it before the
representations were made consistent. This is a foundation-first discipline —
do it at the START of work, not as cleanup.

## Principle 1 — Parity of the three representations (do this first)

Any nontrivial system exists in three forms that MUST be kept identical:

- the **formal/spec layer**: the theorem, contract, API spec, type, invariant,
  design doc, metric definition, requirement;
- the **implementation**: the code/config/query/circuit that actually runs;
- the **prose**: the README, paper, comment, dashboard label, changelog.

They drift. Reconcile them **before** any heuristic work (tuning, optimization,
experiments, scaling). A heuristic built on an inconsistent foundation is
wasted the moment the inconsistency surfaces.

- Diff them literally: grep the load-bearing objects (the equation, the
  coefficient, the default value, the endpoint, the metric formula) and confirm
  the implementation computes *exactly* what the spec/prose claim.
- When they diverge, reconcile by (i) fixing the implementation to match the
  claim, or (ii) explicitly weakening/relabeling the claim. NEVER hide the gap
  behind "variant"/"default-vs-X" framing — that compounds across revisions.
- A spec that names a structure, or a results/figures set whose "method"
  silently differs across cases, is a red flag to resolve before proceeding.

## Principle 2 — Verify claims against the artifact and a measurement

A statement of what a system does — and especially *why* — is a hypothesis until
checked against ground truth.

- Before asserting behavior, read what the DEPLOYED artifact actually does, not
  its description or your mental model.
- A causal/root-cause claim needs the **cheapest discriminating measurement**:
  an ablation that toggles the suspected cause, a bisection, a decomposition, a
  controlled sweep, a precision/scale check. Run it before you write the
  explanation, not after.
- Artifact beats claim. If a measurement contradicts the claim, the claim was
  wrong — say so and re-measure. Do not defend a narrative the data refuted.
- **Verify guards with a positive case.** For any detector, alarm, validator, or
  test of an error path (secret scanners, CI gates, monitoring, assertions), a
  *passing negative* (clean tree → exit 0) is NOT evidence it works — only that
  it didn't fire. Inject a known-bad input and confirm it fires, and check that
  the injected input actually matches what you intend to catch (a too-weak
  sample fakes a pass). A net you've only seen succeed is untested.
- **Works-by-hand-but-fails-under-automation is a context bug.** When an
  automated process (daemon, hook, CI job, cron, subprocess) fails at something
  you can do manually, the discriminating measurement is to reproduce the exact
  step by hand, confirm it works, then diff the two *execution contexts* —
  PATH/env, cwd, privileges, proxy vars, concurrency, connection/state reuse,
  timeouts — one axis at a time. The bug is in the context difference, not the
  operation; theorizing about the operation wastes the measurement.

## Principle 3 — Conditions travel with the claim

A conditional or qualified result must state its conditions wherever it is most
prominently asserted — abstract, headline, theorem statement, API/executive
summary, release note — not only where it is fully proved or defined.

- Headlining the strong form while relegating the qualifier to an
  appendix/footnote/caveat is the recurring source of "overclaim" pushback
  (reviewers, auditors, downstream users who read only the summary).
- Co-locate the scope with the claim: if the headline says "X works / X is
  universal / X is exact," the same sentence (or its immediate neighbor) carries
  "...under conditions C, verified in cases V, open in general."
- Make the qualification *structurally* visible — an inline clause, a table row,
  or a column — not relegated to a footnote a reader can skip.
- Applies beyond papers: a README feature claim states its preconditions; an
  API "supports Y" states the Y it does *not* support; a benchmark headline
  states the protocol that makes it not a SOTA claim.

## Principle 4 — Triangulate load-bearing claims (independent, redundant confirmation)

A claim that many other things depend on — a core theorem, a key invariant, a
critical default, a security or correctness assumption — should be confirmed by
**two or more genuinely independent routes**, not a single check. Independent
agreement is what makes a foundation trustworthy *from the start*; the
alternative is re-auditing the whole edifice later, every time doubt resurfaces.

- "Independent" means different *method*, not the same check run twice: a
  symbolic derivation **and** an independent numerical computation **and** an
  adversarial attempt to break it; a closed-form result **and** a brute-force
  enumeration; a proof **and** a property-test; one reviewer's read **and** a
  cross-check by a different construction. Two routes that share the same hidden
  assumption are not independent — a slip survives both.
- Front-load it on the load-bearing few, not everything. The point is leverage:
  the handful of facts whose failure cascades deserve redundant confirmation;
  routine facts need one good check (Principle 2).
- Make the independent confirmations *visible and durable* — record what was
  checked and how (a verification script, a second derivation in an appendix, a
  cross-reference table), so the trust does not have to be rebuilt from scratch.
- Corollary for dependents: when work B builds on work A, identify exactly which
  results of A are load-bearing for B, and confirm *those* independently —
  rather than treating all of A as equally critical or equally trusted.

## When to invoke

- At the START of work on any system that has a spec/contract/theorem plus an
  implementation plus docs — establish parity before building on it.
- When writing or reviewing a headline/abstract/summary that asserts a result
  whose full conditions live elsewhere.
- About to assert what a system does or why it behaves a certain way.
- Writing or reviewing a claim/spec/doc/table that describes an implementation.
- Debugging, root-causing, or reconciling docs against the thing they describe.

## Process

1. Name the three representations (spec, implementation, prose) for the part in
   scope. If one is missing, that itself is the first gap to close.
2. Diff them on the load-bearing objects; reconcile every divergence before
   doing heuristic/experimental work.
3. For any behavioral claim, locate and read the deployed artifact.
4. For any causal claim, run the smallest measurement that distinguishes your
   hypothesis from the alternatives before recording it.
5. Artifact wins ties. Update the representation that was wrong; flag the change.

## Anti-patterns this prevents

- Tuning/experimenting on a system whose spec, code, and docs disagree — then
  discovering the disagreement after the compute is spent.
- Asserting a root cause from docs/intuition that the code doesn't support
  (often more than once, because the code was never opened).
- Shipping/deploying something that differs from what the spec or docs describe.
- "Variant" framing that masks a spec↔implementation gap.
- Claiming an exact/guaranteed property without separating the idealized model
  from the deployed reality (e.g. exact arithmetic vs finite precision).
- Defending an earlier conclusion after fresh evidence has overturned it.

## Notes

- This is the foundation; `pin-and-trace` (values to a canonical source) and
  `decision-gate` (gate before expensive/structural moves) build on it.
- "Foundations before heuristics": a clean, consistent base makes the later
  heuristic work cheap and trustworthy; an inconsistent base makes it a trap.

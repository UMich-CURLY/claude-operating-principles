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
- **Parity is container-scoped, not file-scoped.** After reconciling the
  primary document, sweep every sibling artifact that ships in the same
  container (repo, Overleaf project, package, docs site) for the same stale
  claims — old drafts, outlines, one-pagers, READMEs. A corrected main
  document beside an uncorrected sibling still ships the contradiction; either
  fix the sibling or quarantine it (e.g. an `archive/` dir with a note saying
  why it must not be cited).
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
  explanation, not after. (For *designing* that measurement so its result
  attributes cleanly — attributability, cheapest-falsifier-first, the severity
  floor — see `diagnostic-discipline`; this skill's concern is that you verify
  the claim against the artifact at all, not how you architect the test.)
- Artifact beats claim. If a measurement contradicts the claim, the claim was
  wrong — say so and re-measure. Do not defend a narrative the data refuted.
- **A fix is a new claim — verify what the fix adds, not just what it removes.**
  Corrective edits tend to smuggle in fresh factual content (a scoping
  parenthetical, a tightened condition, an "as in X" example) that was never
  checked against the artifact. Before closing an item, verify every new
  factual element the fix introduces exactly as you would an original claim;
  when reviewing a round of fixes, treat the fix text as fresh unverified
  claims to attack. Round-over-round convergence stalls precisely on errors
  introduced by the previous round's corrections.
- **Verify guards with a positive case.** For any detector, alarm, validator, or
  test of an error path (secret scanners, CI gates, monitoring, assertions), a
  *passing negative* (clean tree → exit 0) is NOT evidence it works — only that
  it didn't fire. Inject a known-bad input and confirm it fires, and check that
  the injected input actually matches what you intend to catch (a too-weak
  sample fakes a pass). A net you've only seen succeed is untested. This covers
  any instrument you wrote, not just alarms: a search, filter, or parser that
  returns nothing needs a positive control — find something you know exists —
  because an empty result and a broken query are indistinguishable.
- **Works-by-hand-but-fails-under-automation is a context bug.** When an
  automated process (daemon, hook, CI job, cron, subprocess) fails at something
  you can do manually, the discriminating measurement is to reproduce the exact
  step by hand, confirm it works, then diff the two *execution contexts* —
  PATH/env, cwd, privileges, proxy vars, concurrency, connection/state reuse,
  timeouts — one axis at a time. The bug is in the context difference, not the
  operation; theorizing about the operation wastes the measurement.
- **A config *file* is not the effective config.** Before reporting any
  parameter value (weight, learning rate, flag, hyperparameter), resolve the
  fully-overridden config — launch scripts, CLI/Hydra overrides, env vars, and
  `defaults`/inheritance layer on top of the static file and routinely change
  the value that actually runs. Read the launch command (or dump the merged
  config) first; a value quoted from the base YAML is a hypothesis, not the
  runtime truth.
- **A metric's name is not its definition.** Before interpreting a logged
  quantity (a loss curve, score, or rate) or explaining its trend, read the
  formula that produces it — names mislead (a `baseline_trajectory_loss` that
  bundles a diversity *reward* term goes negative; an `accuracy` that is
  secretly top-5). An impossible or out-of-range value — a negative "norm", a
  probability > 1, a loss below its theoretical floor — is not noise; it is
  evidence your model of the metric is wrong. Re-read the code before trusting
  any narrative about the trend. Two metrics of the same system that cannot both
  be true carry the same signal without any range being violated, and are often
  the only way an out-of-domain instrument shows itself. Corroborate a surprising
  number against a second, independent metric before building on it — and suspect
  the instrument first when a number is extreme in EITHER direction, not only when it
  flatters you: a reading that violates an invariant something *enforces by
  construction* is evidence about the reader. Read thresholds from the artifact — a
  hardcoded bound stops measuring what it names once the system is reconfigured.
- **Inspect at the producing layer; completion signals lie.** Answer "what does X
  contain / expose / do" from the artifact at its own layer: the producer that
  writes a structure, never its consumers (a consumer-side grep is a lower bound
  that silently reads as "impossible"); a pipeline's publish/output registry, not
  its read side (code that *reads* a signal proves it exists upstream, not that it
  survives into the output); the built image's contents, not the build's exit
  code; the rendered pixels, not the linter. Existence is not integrity: gate
  transfers on checksums, joins on an emitted coverage count (resolved/total),
  and claimed capabilities by introspecting the artifact itself.
- **Know what a measurement can resolve before it decides anything.** Identify the
  unit of replication — what varies *independently* (episode, subject, run, scene),
  not the sample count the tool prints — and compute the spread over that unit,
  reported beside the value. Pooling correlated samples inflates n and manufactures
  significance; a difference smaller than the spread is not a finding, and filing it
  as one buys a later retraction. Where a pooled and a per-unit computation disagree,
  the per-unit one governs and the disagreement is itself the result. This constrains
  *conclusions*, not exploration: a cheap single-replicate probe remains a legitimate
  way to form a hypothesis or overturn a clearly-wrong prior claim. **Selection is the
  other limit**: a sample filtered on a criterion correlated with the quantity cannot
  report it, and what a dataset *contains* is not what it *conditions on* — it can be
  half centred driving by volume while every example is anchored at a displaced state,
  demonstrating nothing from the operating point. Name the selection where described.
- **Acted-on measurements decay — re-measure each iteration.** Any measurement
  repeatedly acted on (a failure profile, a noise floor, a parked blocker list)
  goes stale when the world — or your own previous fix — moves it; the bottleneck
  migrates after every effective intervention. Re-profile before aiming the next
  fix: a failure read taken under a superseded configuration confidently funds
  work on an already-relieved bottleneck.
- **An inherited blocker is a hypothesis, not a constraint.** A "blocker", root
  cause, or limitation carried in from a prior session's summary, a handoff,
  memory, or a teammate's report feels authoritative but is second-hand — often
  stale, misattributed, or garbled (e.g. a carried label like "spawn needs an
  SDK bump to match model_config" that, traced to the code, turns out to be "no
  blocker — the defaults already avoid it"). Before letting it gate work,
  reproduce it against the current artifact. Re-grounding a carried claim costs
  minutes; building around a phantom constraint costs far more. **An inherited success
  is a hypothesis too, and a quieter one**: it arrives as a reason to build, not a
  claim to check. Re-derive its conditions and check them against the new setting's
  *failure* distribution before porting it — usually a histogram, available up front.
- **Before publishing a claim, enumerate what it rests on and confirm you have shown
  someone all of it.** An artifact built as a means to a measurement — a scenario, a
  fixture, a harness, a one-off script — is categorized as disposable when created, and
  nothing re-categorizes it when a published claim starts resting on it; it keeps behaving
  like scratch, uncommitted and unreviewed. The trigger to re-ask is not "are we splitting
  up the work" but "does a claim now depend on this", and that moment passes unmarked. The
  same enumeration catches absence claims, which are verifiable only over the corpus the
  absence is asserted about and never from the artifact under test — "held out" is a
  statement about the training set. Both failures here were outward-facing: five
  deliverables shipped the tools for an investigation and none shipped the two scenario
  files every number was measured on, and a "held-out map" claim sat in a review-ready
  description while the site was in the training data.
- **A null/zero result from a command that may not have run is not evidence.** A
  diff, count, or fetch reporting "0 changed / nothing / already up-to-date" is
  meaningful only if the command actually executed against *current* inputs. A
  missing tool (`timeout` absent on macOS aborts the line before `git` runs), a
  silent auth failure (a fetch that authenticated as the wrong identity →
  "Repository not found," leaving a stale remote-tracking ref), or a
  never-refreshed local ref each produce a "no difference" indistinguishable from
  the real thing — a false negative that reads like an answer. Confirm the
  operation ran (exit status, expected side-effect) and that its inputs are fresh
  before trusting the null. Especially when measuring divergence from a **moving
  reference** (an upstream you track, a fork you replicate, a benchmark you
  compare against): re-pin the reference's current version — fetch and confirm the
  tip/commit — before believing "no drift"; the reference has its own version and
  your copy may be stale.

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
- **A slow or expensive validator cannot tell you that you validated the wrong
  artifact.** When replicating or porting a reference, small per-step deviations
  accumulate until the thing under test is no longer the reference. Before an
  expensive or slow check (days-long training, large eval, costly run), establish
  a *cheap equivalence gate* against the reference — ideally numerical parity
  (same weights + inputs → same outputs to tolerance), not just shape or
  plausibility — and re-run it as the code changes. Gate fidelity upstream, where
  it is cheap, instead of discovering drift downstream, where it is not.
- **Cross-harness evaluation: the output→metric mapping is a modeling decision.**
  To score model A in model B's metric, you must map A's native representation into
  B's format — treat that as a substantive choice, not plumbing. (a) Don't assume A
  has a convention to copy; check — A's own eval may be a placeholder. (b) Watch for
  silent degeneracy: if A's richer output doesn't fill B's format (a multimodal
  predictor emitted as one trajectory), the metric returns a real-looking but
  meaningless number (e.g. `minADE@k=6 == minADE@k=1`). (c) A plausible default can
  encode wrong semantics (flattening a mode hierarchy by joint prob vs mapping
  mode→mode); pick the mapping faithful to A's structure, and state it.
- **A clean auto-merge is not a correct merge.** Zero merge conflicts only means no
  *overlapping lines* — when two branches change related logic in different regions
  of the same file, the VCS silently interleaves both, which can compile yet be
  semantically broken. After any merge that touched a file both sides edited, verify
  behavior (run the tests / a smoke), don't trust "no conflicts." Identify the
  both-sides-changed files up front (`comm` of the two diff name-lists) so you know
  exactly what to re-verify. Conversely, resolving a conflict hunk by taking one side
  can still break the build when an auto-merged region elsewhere in the file references
  a symbol only the *other* side defined (a variable name, constant, or helper) — after
  resolving, grep the file for the names each side introduced or removed and confirm
  every reference still resolves.
- **A composite loss can move against the thing you care about — decompose before
  judging.** An aggregate that sums fit + penalty/regularizer terms can rise while
  the fit improves, because a penalty term grew (e.g. a mode-collapse/spike
  regularizer spiking masks a trajectory loss that's still dropping). Don't read a
  flat/rising headline loss as failure: break it into components and watch the one
  that maps to the goal, plus the **held-out eval metric** — train loss can be flat
  while eval improves. The aggregate is a sum, not a verdict.

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

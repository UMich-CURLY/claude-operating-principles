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
  it didn't fire. Inject a known-bad input and confirm it fires (for a router or a
  config switch: that the case takes the other branch), and check that
  the injected input actually matches what you intend to catch (a too-weak
  sample fakes a pass). A net you've only seen succeed is untested. This covers
  any instrument you wrote, not just alarms: a search, filter, or parser that
  returns nothing needs a positive control — find something you know exists —
  because an empty result and a broken query are indistinguishable. An evaluation
  harness's positive control is a known-good case driven into the success state
  through the same path the candidates take; a fixture that skips the path fakes the
  control. *(Receipt: a vehicle model held a scripted standstill but diverged when the
  car slowed to rest in closed loop, so a stop could only read as a failure.)* A dry-run or
  no-op flag is such a guard: prove it by diffing the live targets afterwards (git
  log, queue, stamps) — a sourced library reset the flag and the "dry" run
  committed twice.
- **Input parity across environments.** Every input a model consumes must mean the
  same thing, from the same source, in training, evaluation and deployment; audit
  that before any loss or target work. A mismatch there presents as a modeling
  problem, and no amount of training fixes it. *(Receipt: a decoder seed 0.15 s stale
  and a future-looking speed input cost sixteen training rounds.)*
- **A label must depend on what it is meant to teach.** For each target quantity, name its
  source: derived from the expert, or copied from the learner's own rollout. A copied quantity
  turns the learner's error into its target. A conditioning input varied while the label stays
  fixed teaches the model to ignore that input. *(Receipt: 2026-09-26, every free-road label in 28
  DAgger shards held the recorded speed, the lead-following expert could never accelerate, and the
  set-speed copies at 0.7x and 1.3x carried identical labels; the model decayed below its set speed
  in closed loop and barely responded to it.)*
- **A deliverable is verified as delivered.** Before it leaves: run the checks on the
  exact delivered files, with every input engaged rather than at its neutral value,
  and diff the artifact against the last one delivered (layout, interface, fused
  components, naming). Its README describes only what the artifact contains.
  *(Receipt: a README's parity claim came from a different graph, and its "trained
  on X" from a config section the cloud never read.)*
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
- **Characterize an input before you spend compute on it.** A model artifact's
  identity is its weights, not its name: establish which config loads it with zero
  invalid keys and zero shape mismatches, and which candidate base leaves the
  untouched modules bit-identical (a checkpoint described as a fine-tune of one
  model was a different architecture from a different base). A dataset's identity is
  its composition *as sampled* — after repeats, strides, deny-lists and weight
  strategies — measured against the behaviour you intend to change; the replay or
  anchor term needs the same audit, because it must contain the behaviours you are
  afraid of losing (eleven fine-tune arms trained on a corpus with 0% turns and 0%
  other agents, because a deny-list added to exclude one map removed every scene
  containing traffic). A teacher's identity is its own score on your endpoint:
  imitation cannot push a student below the variability of what it imitates, so
  decompose the gap into the part already at parity with the source and the part that
  is not — only the second is reachable by more data. One afternoon of measurement
  here is routinely worth a month of arms.
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
  and claimed capabilities by introspecting the artifact itself. Before writing an instrument, check whether an existing artifact already carries the quantity as a
  column — twice in one day a two-hour analysis was a two-minute query.
- **To claim something was never done, enumerate — do not search.** A keyword grep
  cannot prove absence when the keyword is optional: "the full benchmark has never
  been run on this model" came from grepping a launch flag that defaults to the value
  in question, and five such runs existed in the registry. Enumerate from the source
  that lists every instance — the run database, the job list, the artifact index —
  and check the default-valued case explicitly. An absence is a claim about a
  population, and a query is not a population. The same discipline governs a
  failure verdict: "the launch failed", read from the first of four logs, killed
  three healthy arms — one row per member before any set-level call.
- **A metric will certify inaction, reward early exit, and see only what it
  measures.** Before crediting a pass, check how it was earned — success counters
  reward degenerate strategies (twelve of nineteen "completed" episodes completed by
  standing still, and every clean turn scenario was clean because the car stopped
  rather than turned), so pair every completion or success metric with the activity
  it presupposes: speed, distance, task progress. Report terminal outcomes beside any
  per-step average, because a run that ends early stops accumulating error and the
  failing arm is flattered by its own failure. Prefer the densest endpoint the
  mechanism drives — rare-event counts need sample sizes an evaluation budget rarely
  affords, while a per-step quantity resolves the same effect orders of magnitude
  sooner — and use the rare event as confirmation, not as the primary read. And read
  a null as bounding only what that instrument can register: zero interventions over
  4.4 km did not mean the policy drove well, only that the counter cannot see a
  lane-internal oscillation. A status is the weakest such metric: "running"
  certifies a process, not progress — read the rate (steps per minute, time per
  step, bytes moved) at the first check; an order of magnitude below the known rate
  is a failure already in progress.
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
  work on an already-relieved bottleneck. And when the instrument itself is found
  wrong, list the choices it decided and re-test the earliest that is still cheap —
  six rounds of gates without the set-speed slot meant re-testing the lineage from
  its first slot model, not only the latest candidate.
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
  The converse case is a blocker you established first-hand and *well* — exhaustive
  listings, positive controls, an instrument-checked negative. That settles whether
  the answer is in the space you searched, not whether you searched the right space,
  and reproducing it only reconfirms. Name the systems the sweep covered, then ask
  which system already in hand might hold the answer — above all one categorized for
  another purpose, because the category is the blindfold.
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
  connection dropped mid-command, a silent auth failure (a fetch that
  authenticated as the wrong identity → "Repository not found," leaving a stale
  remote-tracking ref), or a never-refreshed local ref each produce a "no
  difference" indistinguishable from the real thing — a false negative that reads
  like an answer. Confirm the
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
- **A gate is not a decision.** In core method development, never let a single
  gate, test, or metric decide that an artifact is trustworthy: require two angles
  that could fail in different ways, and treat "the gate passed" as one input, not
  the verdict. A check whose probe cannot express the failure does not count as one
  of the two — a lane-departure gate that re-measured points sitting exactly *on*
  the reference passed at 1e-13 while the same function was wrong by 3,971 m for
  points off it. Reserve single-check acceptance for genuinely trivial matters,
  which core method work rarely is.
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

## Principle 5 — One instrument for the data gate and the result metric

The instrument that gates the training data and the instrument that scores the result must be
the same code, validated once against inputs with known answers. Two instruments give two
definitions of the same word, and a pass on one never transfers to the other. Reuse the
validated kernel already on the main branch rather than writing a second differentiator; a
private copy diverges and later cannot merge. (Here: the labeler's comfort audit read an
internal speed profile while the closed-loop metric differentiated executed positions; neither
number meant what the other did, and the vehicle debrief showed a 0.5 s smoothing window alone
flipped a pass/fail verdict.)

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
6. For a rule that must hold at a boundary you don't consciously label — a log line
   during another task, a status check, a copied template — put the check in the tool
   that crosses the boundary (preflight, status probe, stamp); recall is not a mechanism.

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

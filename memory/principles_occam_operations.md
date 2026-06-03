---
name: principles-occam-operations
description: "Default operating principles for surgical, efficient work — apply Occam's razor at the operational level, minimize iteration cost, prefer smallest reversible steps."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 90cc53c5-370d-47fb-a3b6-cd4c289bc588
---

**Operating principles — apply by default to all work:**

1. **Smallest reversible step first.** Before any non-trivial action, identify the cheapest move that yields decision-quality information. Smoke test before full sweep; minimal repro before hypothesis; read failing case before refactor; one-line clarify before a 200-line plan.

2. **Pin source of truth; never restate.** Every claim, value, or decision lives in one canonical place; everything else references it. Numbers in writing → results JSON + commit hash. Constants in one config file. State in one STATUS/TODO file. Memory pointer rather than re-deriving.

3. **Persistent concern catalog.** Anything a reviewer, user, or test has flagged becomes a durable record. Before acting in that domain again, check first. Don't re-discover concerns that already have fixes.

4. **Delete before you add.** Every additive change owes a compression check on the surrounding artifact. If +200 lines, +1 abstraction, or +1 defensive disclaimer, audit whether existing material still earns its place. Defensive padding compounds across rounds.

**Why:** This rule emerged from an ML paper revision cycle that hit 10+ iterations when 2 should have sufficed. Most inefficiency was procedural: re-fixing the same concerns under different wording, adding without deleting, big changes without small verification.
**How to apply:** When responding to feedback, default to triage-against-history before editing. When proposing a non-trivial change, declare a decision gate before executing. Keep diffs surgical.

5. **Decision gate before significant choice.** Write down: gate criterion (numeric/boolean), cheapest experiment to inform it (<30 min ideal), fallback if it fails. Run the gating experiment first. Don't pre-commit to the big version.

6. **Trust but verify subprocess reports.** When a watcher, agent, sweep, or background task says "done," check the actual artifact (file size, results JSON, process list) before treating it as done. ~30s sanity check costs nothing.

7. **Communicate dependency, not narrative.** When blocked, name the dependency in one line ("need access to X, ETA Y"). When unblocked, ship the result. Skip process commentary.

8. **Robust over clever.** Boring patterns survive interruption: parent-PID watchers beat pgrep-by-pattern; local polling loops beat stateful SSH sessions; explicit configs beat clever defaults.

**Related skills (invoke when applicable):** [[triage-against-history]] for review/feedback responses; [[decision-gate]] for non-trivial changes; [[pin-and-trace]] when writing values into durable artifacts.

# claude-operating-principles

Portable Claude Code operating principles and skills, in three layers:

- **Ten commandments**, the root. Every skill elaborates one or more of them, and new rules grow out of the tenth.
- **Ten daily defaults**, applied automatically in every session. They are the working habits of the commandments,
  with Occam's razor as their style: prefer the smallest intervention that actually closes the gap. That is
  commandment 7 where the cost of being wrong is low; where it is high, 7 asks for more.
- **Skills**, loaded on demand when the work matches. Each one carries a commandment's full rules and the incidents
  that produced them.

## The ten commandments

They run in the order a piece of work does: understand what exists, plan the test, pick the measure, set up a fair
comparison, confirm, fix, act, run, report, learn.

| # | Commandment | Elaborated in |
|---|-------------|---------------|
| 1 | **The truth is whatever actually ran, recorded in one place.** The spec, the code and the description agree, and every fact has one home that everything else points to. | ground-truth-discipline, pin-and-trace |
| 2 | **Decide before you measure.** Write down the prediction, the result that would disprove it, and the action each outcome triggers. Run the cheapest disproof first. | decision-gate |
| 3 | **Grade with the consumer's ruler.** Their code and thresholds decide pass or fail. Before a requirement becomes a hard limit, trace its source and status, and check it can be met alongside the other limits. | ground-truth-discipline |
| 4 | **Compare like with like.** One build, one protocol, matched progress, the same population. Label anything else. | pin-and-trace, diagnostic-discipline |
| 5 | **A claim stands only when a second, independent route agrees.** Suspect the measuring tool first. | ground-truth-discipline |
| 6 | **Find the mechanism, then fix its whole class at the layer that owns it.** | diagnostic-discipline |
| 7 | **Buy certainty in proportion to the cost of being wrong, and act only on what you own.** | decision-under-irreversibility, diagnostic-discipline |
| 8 | **Unattended work fails loudly and never sits idle.** A stage hands off only on a checked product, every waiter shows it is alive, and every scarce resource has one scheduler and a default job. | unattended-ops, enforcement-discipline, operating-modes |
| 9 | **Write for the reader's next decision.** Lead with what changes their action, in their words, with the evidence and with what is not claimed. | reader-first, operating-modes |
| 10 | **Every failure that reaches someone changes a rule, and the rule set stays small.** Compress a new rule against the existing ones, show it would have caught the failure, and keep project names out of it. | triage-against-history, and the receipts in every skill |

The tenth is the generator. With it alone the other nine grow back, but each one gets paid for in incidents.

## The ten daily defaults

Applied automatically in every session via `memory/principles_occam_operations.md`. The commandments each default
serves are in brackets.

1. **Smallest reversible step first** (2, 7). Identify the cheapest move that
   yields decision-quality information. Smoke test before full sweep;
   minimal repro before hypothesis; read the failing case before refactor.
2. **Pin source of truth; never restate** (1). Every claim, value, or
   decision lives in one canonical place; everything else references it
   (results JSON + commit hash, one config file, one STATUS file).
3. **Persistent concern catalog** (10). Anything a reviewer, user, or test
   flagged becomes a durable record. Check it before acting in that
   domain again; don't re-discover concerns that already have fixes.
4. **Delete before you add** (10). Every additive change owes a compression
   check on the surrounding artifact. Defensive padding compounds.
5. **Decision gate before significant choice** (2). Write down the pass/fail
   criterion, the cheapest experiment to inform it, and the fallback.
   Run the gating experiment first; don't pre-commit to the big version.
6. **Trust but verify subprocess reports** (1, 8). When a watcher, agent, or
   background task says "done," check the actual artifact before
   believing it.
7. **Communicate dependency, not narrative** (9). When blocked, name the
   dependency in one line; when unblocked, ship the result.
8. **Robust over clever** (8). Boring patterns survive interruption:
   parent-PID watchers beat pgrep-by-pattern; explicit configs beat
   clever defaults.
9. **Foundations before heuristics: keep the three representations one** (1).
   Reconcile spec/claim, implementation, and prose *before* any tuning or
   scaling. Treat a behavioral/causal claim as a hypothesis until checked
   against the deployed artifact plus the cheapest discriminating
   measurement; state a conditional claim's conditions where it's
   headlined.
10. **Triangulate load-bearing claims** (5). The few facts everything rests
    on earn confirmation by two or more *independent* routes (symbolic +
    numeric + adversarial; proof + property-test). When work B builds on
    A, confirm *exactly which* results of A are load-bearing.

## Skills

Loaded on demand when the work matches, listed in commandment order.

| Skill | Commandments | Use when | Does |
|-------|--------------|----------|------|
| **ground-truth-discipline** | 1, 3, 5 | starting on any system with a spec + code + docs; writing/reviewing a headline claim | **Foundational, apply-first.** Make the three representations agree; verify claims against the deployed artifact + a measurement; grade with the grader's own operator; keep conditions co-located with the claim; confirm load-bearing claims by independent routes. |
| **pin-and-trace** | 1, 4 | writing values, claims, or decisions into durable artifacts; building a comparison | Single-source-of-truth rule: one canonical home, everything else references it; every cell of a comparison from one coherent source. |
| **decision-gate** | 2 | before architectural flips, large rewrites, expensive sweeps | Require a pass/fail criterion + cheapest gating experiment + fallback before committing. |
| **diagnostic-discipline** | 4, 6, 7 | choosing which experiment/ablation to run; deciding how much to test/prove/verify; a result is ambiguous about *what* caused it; reviewing whether evidence supports a claim | Route diagnosis vs. synthesis; design tests for *attributability* (cheapest falsifier first, one mechanism at a time); scope a repair to the defect's whole class; allocate verification effort by the cost of being wrong. |
| **decision-under-irreversibility** | 7 | an action is costly or impossible to undo (migrations, DROP/DELETE, irreversible deploys, sending comms, publishing); autonomy/safety gating | Assess reversibility of the action *and* inaction; route on a 2×2; climb a ladder — buy reversibility, defer the irreversible kernel, stage with a principled stopping rule, else minimize worst-case. |
| **unattended-ops** | 8 | writing any waiter, poller, watcher, chained pipeline or overnight automation | Make unattended failures loud or impossible: owned tokens not process text, both branches of every wait tested, one scheduler per serial resource, jobs sized against the binding limit, config and health checked in the first minutes. |
| **enforcement-discipline** | 8 | standing up or auditing a long-running loop; after a "what ran was not what we thought ran" incident; before delegating operations to agents | Put each rule where it can refuse: the contract in the entry point, one launcher per action, guards seen refusing, provenance on every artifact, the expectation written before the run, a fixed first check, agents build and never operate. |
| **operating-modes** | 8, 9 | running a long loop with a human principal | Standing defaults: status as rates and ETAs, preflight stamp before any launch, explicit resource holds, act-and-report versus ask-once, credentials in every status. |
| **reader-first** | 9 | writing or sending anything a person reads: replies, status, documents, pages, PR bodies, messages drafted for someone else | The reader's next decision sets content, order and words: lead with what changes their action, their vocabulary with a legend for every metric, what is not claimed beside the claim, items someone is waiting on delivered first. |
| **triage-against-history** | 10 | responding to reviews, bug reports, PR comments | Triage each item against persistent records before editing — classify as already-addressed / prose-stale / genuinely-new. |

## Install

```bash
# 1. Clone
git clone <this-repo-url> ~/Documents/GitHub/claude-operating-principles

# 2. Skills go to ~/.claude/skills/ (installs every skill the repo ships)
for dir in skills/*/; do
  skill=$(basename "$dir")
  mkdir -p ~/.claude/skills/$skill
  cp "$dir/SKILL.md" ~/.claude/skills/$skill/SKILL.md
done

# 3. Memory file goes to the project memory directory
# Copy into each project's memory directory, or symlink for live updates.
# The project memory directory is at ~/.claude/projects/<project-slug>/memory/
cp memory/principles_occam_operations.md \
   ~/.claude/projects/<project-slug>/memory/

# 4. Add to that project's MEMORY.md index, one line:
# - [Occam-operations principles](principles_occam_operations.md) — ...
```

`install.sh` runs steps 2–4 for you.

# claude-operating-principles

Portable Claude Code operating principles + skills. They apply Occam's
razor at the operational level: for any work step, prefer the smallest
intervention that actually closes the gap.

## The ten principles

Auto-applied every session via `memory/principles_occam_operations.md`.

1. **Smallest reversible step first.** Identify the cheapest move that
   yields decision-quality information. Smoke test before full sweep;
   minimal repro before hypothesis; read the failing case before refactor.
2. **Pin source of truth; never restate.** Every claim, value, or
   decision lives in one canonical place; everything else references it
   (results JSON + commit hash, one config file, one STATUS file).
3. **Persistent concern catalog.** Anything a reviewer, user, or test
   flagged becomes a durable record. Check it before acting in that
   domain again; don't re-discover concerns that already have fixes.
4. **Delete before you add.** Every additive change owes a compression
   check on the surrounding artifact. Defensive padding compounds.
5. **Decision gate before significant choice.** Write down the pass/fail
   criterion, the cheapest experiment to inform it, and the fallback.
   Run the gating experiment first; don't pre-commit to the big version.
6. **Trust but verify subprocess reports.** When a watcher, agent, or
   background task says "done," check the actual artifact before
   believing it.
7. **Communicate dependency, not narrative.** When blocked, name the
   dependency in one line; when unblocked, ship the result.
8. **Robust over clever.** Boring patterns survive interruption:
   parent-PID watchers beat pgrep-by-pattern; explicit configs beat
   clever defaults.
9. **Foundations before heuristics: keep the three representations one.**
   Reconcile spec/claim, implementation, and prose *before* any tuning or
   scaling. Treat a behavioral/causal claim as a hypothesis until checked
   against the deployed artifact plus the cheapest discriminating
   measurement; state a conditional claim's conditions where it's
   headlined.
10. **Triangulate load-bearing claims.** The few facts everything rests
    on earn confirmation by two or more *independent* routes (symbolic +
    numeric + adversarial; proof + property-test). When work B builds on
    A, confirm *exactly which* results of A are load-bearing.

## Skills

On-demand workflows that activate the principles when the work matches.

| Skill | Use when | Does |
|-------|----------|------|
| **ground-truth-discipline** | starting on any system with a spec + code + docs; writing/reviewing a headline claim | **Foundational, apply-first.** Make the three representations agree; verify claims against the deployed artifact + a measurement; keep conditions co-located with the claim; confirm load-bearing claims by independent routes. |
| **triage-against-history** | responding to reviews, bug reports, PR comments | Triage each item against persistent records before editing — classify as already-addressed / prose-stale / genuinely-new. |
| **decision-gate** | before architectural flips, large rewrites, expensive sweeps | Require a pass/fail criterion + cheapest gating experiment + fallback before committing. |
| **pin-and-trace** | writing values, claims, or decisions into durable artifacts | Single-source-of-truth rule: one canonical home, everything else references it. |

## Install

```bash
# 1. Clone
git clone <this-repo-url> ~/Documents/GitHub/claude-operating-principles

# 2. Skills go to ~/.claude/skills/
for skill in ground-truth-discipline triage-against-history decision-gate pin-and-trace; do
  mkdir -p ~/.claude/skills/$skill
  cp skills/$skill/SKILL.md ~/.claude/skills/$skill/SKILL.md
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

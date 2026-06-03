# claude-operating-principles

Portable Claude Code operating principles + skills extracted from a real
ML-paper-revision project that hit 10+ iteration rounds when 2 should
have sufficed. The contents apply Occam's razor at the operational
level: for any work step, prefer the smallest intervention that
actually closes the gap.

## What's in here

- `memory/principles_occam_operations.md` — short rule set auto-applied
  every session (load via memory system). Eight invariant principles
  with their rationale and how-to-apply notes.
- `skills/triage-against-history/SKILL.md` — when responding to
  feedback (reviews, bug reports, PR comments), triage against
  persistent records before editing. Classifies items as
  already-addressed / prose-stale / genuinely-new.
- `skills/decision-gate/SKILL.md` — before non-trivial changes
  (architectural flips, large rewrites, expensive sweeps), require a
  pass/fail criterion + cheapest gating experiment + fallback.
- `skills/pin-and-trace/SKILL.md` — single-source-of-truth rule for
  values, claims, and decisions in durable artifacts.

## Install

```bash
# 1. Clone
git clone <this-repo-url> ~/Documents/GitHub/claude-operating-principles

# 2. Skills go to ~/.claude/skills/
for skill in triage-against-history decision-gate pin-and-trace; do
  mkdir -p ~/.claude/skills/$skill
  cp skills/$skill/SKILL.md ~/.claude/skills/$skill/SKILL.md
done

# 3. Memory file goes to the project memory directory
# Either copy the file into each project's memory directory, or
# symlink for live updates. The project memory directory is at
# ~/.claude/projects/<project-slug>/memory/
cp memory/principles_occam_operations.md \
   ~/.claude/projects/<project-slug>/memory/

# 4. Add to that project's MEMORY.md index, one line:
# - [Occam-operations principles](principles_occam_operations.md) — ...
```

## Why this exists

Across a long paper-revision cycle, the same procedural patterns drove
most of the iteration cost:

1. **Reviewer-concern drift** — the same concern arrived in 3+ rounds
   under different wording; each round re-fixed it.
2. **Add-before-delete** — defensive prose compounded across rounds.
3. **Big change without small verification** — architectural flips that
   crashed elsewhere and required debug + LayerScale + re-verify cycles.
4. **Numbers drift from JSON** — every empirical change required a
   grep-and-update sweep across the paper.
5. **Watcher fragility** — premature task notifications wasted multiple
   turns.

The memory file encodes the rules that prevent these patterns; the
skills are on-demand workflows that activate the rules when the work
matches.

## Provenance

Extracted from the TMLR paper *Casimir Primitives for GL(n)-Equivariant
Networks* revision cycle (2026), where the inefficiencies surfaced.
The principles generalize beyond ML paper writing to any
revision-heavy, multi-iteration project work.

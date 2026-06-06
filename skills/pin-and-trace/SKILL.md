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

## Notes

- The point isn't to never restate values — it's to never restate without a traceable link.
- Build the source-of-truth file *before* you need the second mention. Friction at creation time saves multi-round headaches.
- A "pinned" number includes the commit hash of the source. Numbers without a pin are suspect.

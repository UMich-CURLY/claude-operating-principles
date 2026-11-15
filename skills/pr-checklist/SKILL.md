---
name: pr-checklist
description: Verify a pull request against the PR bar before it is opened or marked ready — need on the real path, built from main's mechanism and names, default-off and invariant to which model ships, bite-sized, claims verified against main, checks run, lean description, Copilot-first review. Use whenever a PR is being prepared, drafted, revised or about to be opened, including PRs an agent prepares.
---

# pr-checklist

Run every item before a PR is opened, and again before it is marked ready after review changes. Report each item as pass, fix, or n/a with one line of evidence. An item that fails blocks opening until fixed. Draws on `decision-gate` (need) and `ground-truth-discipline` (verify claims).

## The checklist

1. **Need on the real path.** State the measured effect on the path that matters (the vehicle, the export, a trained-model difference). Equivalence alone is not need. *(Receipt: a PR proving a switch was bit-equivalent was closed — the vehicle already ran the alternative.)* A bug with a measured consequence is need; fix it narrowly rather than disclose side effects. Name the module that consumes the measured signal in the config the PR affects. *(Receipt: a train/eval gap was measured on features the affected config's trained head never reads.)* A latency or memory need is measured on the deployment runtime and version, not an intermediate one. *(Receipt: a node costing 70 ms in ONNX Runtime cost 1 ms in the deployed TensorRT build.)*
2. **Not already on main.** Search main for the behavior before writing the PR or any claim about main. Name the closest existing mechanism. *(Receipt: a claim that main lacked a fix; main already had it process-wide.)*
3. **Built from main's mechanism and names.** Extend what main has; no side paths. Reuse main's vocabulary. *(Receipt: a side-file join was rejected; the same need landed as a data column main already read.)*
4. **Invariant to which model ships.** Mechanisms behind flags that default off; recipe values (weights, members, on/off choices) only in a final config change. With the flag off, main's path is bit-identical — a test proves it.
5. **Cut from the latest main.** 0 commits behind at open; merge main (never rebase or force-push) when it moves. After a merge, search for silent breaks the merge didn't flag (APIs main changed, e.g. a list that became a dict).
6. **Bite-sized and independent.** `git diff origin/main...HEAD --stat` lists only the intended files. Test lines count: one focused test file, only the tests the claim needs. Two open PRs share no files. Set the line budget, tests included, before building; a brief for PR-bound code states it as a gate. A series that ships a tool traces every output it claims from inputs the team has (code and data) through main plus the series before its first PR, passes an end-to-end run from a fresh clone before its last, and after merge the author's own work uses it. *(Receipt: a five-PR evaluation suite was found mid-series to need box-only scenes and a private replay path.)*
7. **Every claim verified.** Each number in the description comes from a run you can point to; scope each claim to what was measured; say what wasn't run on main if the evidence came from another branch. For anything on the export or runtime path, diff the new interface (inputs, outputs, defaults) against the artifact actually deployed, not only against main's code. Before opening or revising, an independent agent tries to refute each claim (`ground-truth-discipline`, Principle 4). *(Receipt: a set-speed export carried 2 of the 3 inputs the shipped bundle takes.)*
8. **Reproduced from outside.** Before opening, a clean room reproduces every number in the description: a fresh container from main's image on no shared mounts (no work dirs, notes, memory or local tool wrappers), a fresh clone of the pushed branch, read-only shared inputs (S3, registry) and the description and usage text only; it is told no expected values. Each guess it has to make is a blocker. Its PASS is recorded for the exact commit and the open command refuses without it. A PR in a series opens only after the whole series passes. *(Receipt: refuters found box-only inputs, two number-changing bugs and a check that scanned nothing in a stack whose own checks had all passed on the machine that built it.)*
9. **Checks run.** Lint and type-check on the changed files; tests named explicitly (a missing path collects nothing and passes); gated tests (e.g. export) run with their gate on. Never bypass hooks.
10. **Lean description, final length the first time.** Title `type(area): description`. First person. Description ≤ ~15 lines with at most one evidence table (headline rows only); test plan ≤ 3 bullets. No tool attribution line. Cold and factual: what the code does and what was measured; no inferred consequences; cut any sentence the reviewer does not need.
11. **Review order.** Copilot review first, fix, then a human reviewer. Posting, opening or commenting needs the owner's go.

## Output

```
PR checklist — <branch>
1 need ............ pass — <one line>
2 not on main ..... pass — <search done, closest mechanism>
...
11 review ......... n/a until opened
Blocking: <items to fix>
```

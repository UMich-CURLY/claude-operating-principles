---
name: decision-under-irreversibility
description: Decide WHETHER and WHEN to commit to a hard-to-undo action, and how to make it reversible before you do. Use whenever an action would be costly or impossible to take back — schema migrations and DROP/DELETE, irreversible deploys or data backfills, sending an email/announcement/offer that can't be retracted, deprecating an API, deleting or overwriting artifacts, publishing, large irreversible spends, or any decision described as "one shot," "point of no return," "can't undo this," "final," or "committing." Also use for autonomy and safety gating where a wrong action causes real-world harm. Trigger even when the user is only weighing the move, not yet executing — especially if they're uncertain whether it's safe. Do NOT use for ordinary reversible work, for finding the cause of a bug (that is diagnosis — see `diagnostic-discipline`), or for running a live incident's triage and comms; this skill governs the commit decision itself.
---

# Decision Under Irreversibility

Most bad outcomes in engineering and research are not wrong answers — they are *unrecoverable* answers: the column you can't un-drop, the email you can't un-send, the model you let act in the world before you understood it. This skill is a router for the one question that matters before any hard-to-undo action: **commit now, gather evidence first, or change the action so it stops being irreversible.**

The mistake this skill exists to prevent is treating "diagnose first, then act" as the universal safe default. It is only safe when *waiting* is itself cheap and reversible. When doing nothing is also catastrophic, delay is not caution — it is an unexamined irreversible choice.

## Step 1 — Assess reversibility of BOTH the action and inaction

Do not reason about urgency. Reason about reversibility. Estimate two things:

- **Is the action reversible?** Can you cheaply return to the prior state if it goes wrong? At what cost and over what window?
- **Is inaction reversible / bounded?** If you wait and gather evidence, is the cost of the current state bounded and recoverable, or is it accumulating toward something you also can't undo?

**If you are uncertain whether the action is reversible, treat it as irreversible.** This precautionary default is the single most important rule here, because the whole router runs on estimates, and the failure mode that destroys you is discovering an absorbing barrier by hitting it — model misspecification, an unknown dependency, a side effect you didn't model. You cannot route on a variable you can't observe, so round uncertainty toward the safe side.

## Step 2 — Route on the 2×2

| | **Inaction bounded/reversible** | **Inaction catastrophic/irreversible** |
|---|---|---|
| **Action reversible** | Act, then diagnose. The cheap cell — just go, observe, roll back if needed. | Act *now* to exit the dangerous state, then diagnose. (This is the SEV1 "mitigate before root cause" reflex — correct because waiting is the irreversible move.) |
| **Action irreversible** | Diagnose first. Waiting is the free option; buy it. Front-load evidence before committing. | The genuine dilemma. Go to Step 3 — do not pick "act" or "wait" as a binary. |

The two diagonal cells cover most real decisions and the answer is mechanical once you've named reversibility honestly. The bottom-right cell is the only hard one, and naive expected-value reasoning is exactly where people go wrong in it.

## Step 3 — In the hard cell, climb the ladder (each rung refuses the binary)

When the action is irreversible *and* inaction is catastrophic, do not choose between committing blind and waiting too long. Work down this ladder and stop at the first rung that applies — each one is usually cheaper than both the risk and full diagnosis.

**Rung 1 — Buy reversibility. Treat reversibility as a design variable, not a fixed property of the action.** Most "irreversible" actions can be made reversible or local for less than the cost of certainty:
- *Canary / staged rollout* — bound blast radius so a global irreversible change becomes a local reversible one.
- *Shadow mode* — let the new system compute its action while the old one executes; observe divergence with zero commitment.
- *Simulator / model* — take the irreversible action in a model of the world first.
- *Feature flag / dark launch* — make "irreversible" a flip you can revert.

This rung is first because it is the highest-leverage move in the whole skill: it converts the hard cell into the easy top-left cell. If you maintain a world model or simulator, recognize that its entire decision-theoretic justification *is* this rung — it exists to turn an irreversible real-world action into a reversible in-model one.

**Rung 2 — Decompose and defer the irreversible kernel.** Most irreversible actions are a reversible envelope around a small irreversible core. A migration: add-column, dual-write, backfill, and verify are all reversible; only DROP is the kernel. So do the reversible parts eagerly to accumulate evidence, push the irreversible kernel to the *last responsible moment*, and concentrate all your diagnosis in the window immediately before it. Identify the point of no return explicitly and keep the abort path alive right up to it (aviation's V1 abort speed is the canonical formalization: before V1 abort is reversible, after V1 you are committed; the discipline is locating that point and keeping abort live to the last instant).

**Rung 3 — Stage against the point of no return with a principled stopping rule.** If you must commit incrementally along an irreversible path, set the commit threshold from the *error costs*, not from a gut feeling of "enough evidence":
- Use a sequential test (Wald's SPRT or equivalent): accumulate the evidence ratio and commit only when it crosses a threshold derived from the acceptable false-go and false-stop error rates. This stops you both from committing too early and from waiting forever.
- Use the option-value framing: the value of waiting is positive while you can still learn cheaply and reverse; commit when that option value goes to zero — which, by construction, is when catastrophic inaction starts to force the move.

**Rung 4 — If even staging is impossible, change the decision criterion.** When it is one irreversible shot, catastrophic either way, with no canary, no decomposition, no staging: **stop maximizing expected value and minimize worst-case outcome instead.** Expected-value reasoning is *invalid* at an absorbing barrier, because ruin is not a bad draw you average against other draws — it ends the sequence, so there is no long run to average over. Bound the probability of the absorbing outcome below a hard threshold, or eliminate the path that contains it, even at a large cost in expected value. This is the precise, operational content of "do not sacrifice safety for speed."

## Step 4 — Record the commit decision

For any irreversible commit, write down, briefly: which cell you were in, which rung resolved it (or why none did), the point of no return, the abort condition that stayed live until it, and the stopping rule or threshold you used. This is not bureaucracy — it is what lets a later reviewer (or you, post-incident) check that the commit was sound rather than lucky, and it is what makes a human supervisor's abort option *usable*: an option you cannot see is an option you cannot exercise.

## Worked examples

**Example 1 — destructive data op.**
Input: "Ready to drop the legacy `events_v1` table, nothing should reference it anymore."
Routing: Action irreversible (DROP). Inaction bounded (a stale table costs storage, nothing more). → Top-right of "irreversible action," so **diagnose first**: search for references, check read traffic, confirm over a window. Then Rung 2 — rename/hide the table first (reversible), wait out the verification window, drop only after. The DROP is the deferred kernel, not the first move.

**Example 2 — autonomy gating.**
Input: "The new policy outperforms the old one in eval; can we let it drive?"
Routing: Action irreversible (real-world action causes real harm). Inaction bounded (keep the proven policy). → **Rung 1**: shadow mode — run the new policy's intended action alongside the deployed one and measure divergence with no commitment; then staged ODD expansion (Rung 2/3) with a human supervisor as the live abort gate held open past the model's own point of no return. Eval performance alone never licenses the irreversible cell.

**Example 3 — irreversible-and-catastrophic, no staging.**
Input: a single irreversible decision where both committing wrong and failing to act are severe, and it genuinely cannot be canaried, decomposed, or staged.
Routing: Rungs 1–3 fail → **Rung 4**: switch from expected value to worst-case. Pick the option whose worst outcome is survivable, even if another option has higher expected value, because an unsurvivable outcome has no expected-value interpretation.

## Provenance and relationship to existing skills

It makes explicit a principle that incident-mitigation hard-codes for one domain (mitigate-before-root-cause under SEV1) without naming the governing variable, and that diagnosis-first workflows silently assume away (they presume you diagnose before you act). The governing variable is the joint reversibility of action *and inaction*, not urgency.

**Relationship to `decision-gate`.** `decision-gate` is the *concrete operational workflow* for gating a costly or structural commitment — write a cheap pass/fail gate + fallback, run the cheap test first, corroborate on a second setting before committing. Its two underlying principles live in the abstract skills: *when the gated action is hard to undo*, this skill's reversibility 2×2 and ladder govern the commit; *how cheap the gating test should be and how much certainty to buy* is `diagnostic-discipline`'s certainty-allocation law. The three coexist with distinct roles — `decision-gate` is the hands-on instance; these two are the principles beneath it. (Not a supersession: `decision-gate`'s templates are operational scaffolding neither abstract skill restates.)

**Companions in this repo:** resolve the action's *referent* first with `pin-and-trace` — you cannot assess the reversibility of an action whose target you've misidentified (dropping the wrong table, pushing the wrong branch). The certainty-allocation reasoning this skill leans on (how much evidence to buy before the commit) lives in `diagnostic-discipline`. Catching a harness-vs-target / false-GREEN confound *before* you act on it is `triage-against-history`.

Triggering boundary: diagnosis finds causes (`diagnostic-discipline` / `ground-truth-discipline`); this skill governs only the commit-or-wait-or-make-reversible decision for a hard-to-undo action.

---
name: enforcement-discipline
description: How an operating rule is made to hold when nobody is watching — the rule lives in the code the work passes through, as a refusal, with provenance on every artifact, so that neither the assistant's nor an agent's discipline is load-bearing. Use when setting up or auditing the loop of a long-running project (reads, recordings, training dispatches, handoffs), after a "what ran was not what we thought ran" incident, and before delegating operations to agents.
---

# enforcement-discipline

Every serious incident in a long loop has the same root: a mismatch between what was thought to
run and what ran. Data listed where the cloud never read it; an evaluation running an aid the
shipped artifact lacked; a default nobody set (a scenario file with no localization type loading
as the wrong one); a run skipping a quarter of its steps and counting as healthy; a README
claiming a check made on a different graph. None of these were caught by a rule that existed as
text, because text is read by people who are busy. A rule holds only where it can refuse.

`operating-modes` says what the principal expects by default; `unattended-ops` gives the mechanics
of waiters and monitors; `ground-truth-discipline` says how to verify; `decision-gate` says what
to write before a costly step. This skill says *where the rule has to live* so that no one's
discipline, the assistant's included, is load-bearing.

## The rules

- **A rule lives in the code the work passes through, as a refusal.** The simulator entry point,
  the checkpoint loader, the dispatch gate: each refuses a deviation from the standard configuration
  unless an explicit `--allow_<deviation>` flag is present, with abbreviations disabled. An ad hoc
  command from a person or an agent hits the same refusal as the launcher. A rule that exists only
  in a script's grep, a checklist or a memory is a hope. *(Receipt: three shell guards accepted
  `--flag=value` and abbreviated flags; the entry point behind them accepted everything.)*
  Each refusal is classed when it is written: an integrity failure halts; any other names its
  default path (proceed with what is valid, stamp what was left out, report after), so a rule the
  principal never set cannot idle a stage. *(Receipt: a labeling refusal on two voided groups, the
  assistant's own rule, held a fine-tune about 4 h.)*
- **One entry point per action.** Read, record, dispatch, deliver: one script each, and nothing
  else launches, not cron, not an armer, not a session. The script embeds the contract, and the code
  beneath it refuses anyway (defense in depth, because the script is the layer people edit).
- **A guard is watched refusing once before it is trusted.** At install, run the case it must
  reject and see the refusal; a guard that has only been seen passing is untested
  (`ground-truth-discipline`, positive case). *(Receipt: a filter guard was inert for a night; the
  probe that caught it took a minute.)*
- **Provenance travels with the artifact, never beside it.** Each run writes one contract line into
  its own stamp and its stored configuration: commit, rig or environment marker, every setting that
  changes what the model sees or how the system moves, and the data members actually consumed.
  Result tables are generated from those lines, never typed, so a table cannot say something the run
  did not do. A result without its contract line is not quoted.
- **The expectation is written before the run, in the ledger.** Purpose, the exact configuration,
  the expected number, the decision rule and the stop condition go into the state document before
  the launch (`decision-gate` supplies the form). A run without that entry is not cited afterwards;
  a run that produced a surprise is compared against what was written, not against what is now
  remembered.
- **The first check is fixed, and nothing follows a run before it.** At a set time after start
  (minutes, not hours): the run exists in the tracker, its stored configuration matches the intent
  member by member, and its health counters (skipped or non-finite steps, step rate) are normal.
  Any miss stops the run, and the cause enters the ledger before any re-dispatch. Nothing is armed
  on the run's result until this check has passed. *(Receipt: two runs skipping 16 and 24 percent of
  their steps read as healthy for an hour because the watcher checked only that steps advanced.)*
- **Agents build; they do not operate.** An agent never launches, cancels, commits, pushes or
  writes to a shared store; it produces files under a scratch directory, with the forbidden list in
  its brief. Each output is verified by a check that fails without it before it is applied. The
  apply step is conditional on that check's exit status in the same command; a result printed and
  not consumed gates nothing. *(Receipt: a helper's failing test scrolled past while the install
  ran anyway.)* An agent that needs an approval-gated command to finish hangs instead; write the
  brief so it never needs one.
- **The surface is small and visible.** One status command lists every running watcher, armer and
  loop with its arguments and the version of the file it executes; one queue writer under a lock;
  a watcher is restarted whenever its file changes (a shell keeps executing the old text); cron is
  limited to resource holds, pushes and status. Anything else that can launch, cancel or queue is
  retired, not paused. *(Receipt: a loop stopped by a flag file was one cron guard away from
  relaunching a closed round.)*
- **Two independent routes before anything crosses the team boundary.** A bundle: the harness on
  the delivered files, with every input engaged, plus a diff against the last delivery. A number:
  the stamp plus the tracker's record. A document: generated from the artifact's manifest, then read
  by the principal. One route is a claim; two are a receipt.
- **Sessions have bookends.** Start: merge the canonical branch, run the status command, read the
  ledger's resume section. End, and at every re-plan: a cold-restart card in the ledger that a fresh
  session, on any machine or account, can act on without this session's context. The enforcement
  above lives in the repository, the box and the ledger, none of which depend on the session.

## When to invoke

- Standing up or auditing the loop of a long-running project: what can launch, what refuses, what
  is stamped.
- After any incident of the form "what ran was not what we thought ran".
- Before delegating operations to agents, and when writing their briefs.
- Before a handoff to another team.

## Relationship to the other skills

Where `unattended-ops` makes a waiter or a monitor correct, this skill decides that the check is a
refusal in the code and not a step in a checklist. Where `ground-truth-discipline` verifies a claim,
this skill makes the claim carry its receipt from the moment it is produced. Where `operating-modes`
lists the principal's defaults (preflight stamp, status, act versus ask), this skill is the reason
those defaults survive a change of assistant, agent, session or account.

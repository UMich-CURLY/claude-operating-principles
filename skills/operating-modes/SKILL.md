---
name: operating-modes
description: Standing operating modes for long-running engineering loops run with a human principal — how status is reported, when to act versus ask, how launches are pre-flighted, how resources and credentials are held, how the full picture is kept. Apply by default in every session on such a project; the project's state document supplies the parameters (clock, resource floor, gate).
---

# operating-modes

These are defaults, not reminders. Each one is a request the principal had to repeat across weeks
of work, and each repetition cost communication and, usually, hours. They are generic; the project
supplies the numbers — the clock, the resource floor, the gate definition, the command names — in
its state document. Mechanics live in `unattended-ops`; verification in `ground-truth-discipline`.

1. **Understand before relaunch.** After any failure, one discriminating measurement precedes the
   next launch; hypothesis, test and result are stamped before the relaunch. Five relaunches on
   plausible causes cost 1.5 h; the measurement that settled it took 5 min.
2. **Status is rates and ETAs in the principal's clock, unasked.** Every project has one status
   command — runs with step rate and projected finish, queue, watchers, resources, credential
   expiry, last stamps — and its output accompanies every status reply and every dispatch. A
   process state ("running") is never reported as progress.
3. **Resources for an unattended loop are held explicitly.** The floor (e.g. four instances) is
   enforced by a guard plus a hold that outlives the loop's longest quiet gap; idle-lapse rules do
   not apply to a loop the principal is asleep behind.
4. **No launch without a preflight stamp.** Before recording, training or evaluation: resource type
   and count; the deploy or eval configuration loads the artifact with zero ignored keys; the suite
   and scenario list; every referenced artifact present on the far side (a shard is its table *and*
   its images); the credential window covers the dispatch time; stamps time-scoped. `PREFLIGHT_OK`
   or no launch.
5. **The full picture lives in one scoreboard.** Rounds x candidates x per-cell results, updated on
   every read by the loop itself, at the top of the state document; chat carries the pointer and the
   delta, never the only copy.
6. **Serial tails overlap the long stage.** Labelling, syncing, uploading and warm-ups run inside the
   recording or training window, so the post-stage tail is minutes; the ETA table shows the critical
   path so the principal can see the gaps.
7. **Reversible: act and report. Irreversible: one question, a recommendation, a default.**
   Configuration switches, launches inside the agreed plan, watcher restarts — do them and say so,
   with a time to object. Cancelling a run, changing the evaluation standard, deleting data — ask
   once, recommend, and name what happens if there is no answer. The question goes out at once as
   its own message, through a channel that reaches the principal away from the terminal, never
   inside a routine report.
8. **Credentials are part of the status.** Expiry against the next dispatch window is a line in every
   status; the principal is asked to refresh before the window, with the exact time — never after
   the stall.

## Instantiation

The project's state document (or CLAUDE.md) records: the clock, the resource floor, the gate, the
status command, the preflight command. When they change, change them there; the modes stay.

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
   not apply to a loop the principal is asleep behind. Size parallelism to the unit of work it
   spreads over: workers inside one invocation can't exceed that invocation's items, so when each
   invocation is small, run invocations concurrently under one total cap. *(Receipt: 8 workers per
   recording cell would have idled half the PD instances, since each cell held 2-4 episodes;
   concurrent cells capped at 8 workers filled them.)* Before spending a scarce resource on a test,
   check whether a run already in flight can serve as it. *(Receipt: a discovery test planned its
   own run while two runs on the same path were already training.)*
4. **No launch without a preflight stamp.** Before recording, training or evaluation: resource type
   and count; the deploy or eval configuration loads the artifact with zero ignored keys; the suite
   and scenario list; every referenced artifact present on the far side (a shard is its table *and*
   its images); the credential window covers the dispatch time; stamps time-scoped. `PREFLIGHT_OK`
   or no launch. When a launch is blocked, report every gate it will meet in one decision: dry-run
   with each known refusal stubbed so the next surfaces. *(Receipt: one arm was 'unblocked' three
   times in a morning, each gate found after the last fix.)*
5. **The full picture lives in one scoreboard.** Rounds x candidates x per-cell results, updated on
   every read by the loop itself, at the top of the state document; chat carries the pointer and the
   delta, never the only copy. A multi-PR goal has one list with a stated end condition, and every
   PR maps to a row; a PR that bundles, splits or adds work updates the list in the same step.
   *(Receipt: an 18-item roadmap went stale for three days while PRs grew off it, and an audit
   re-found the stale items as a 'new' gap list.)* The canonical state document is updated at every
   checkpoint (decision, verdict, finished study); freshness is enforced by the routine status
   check, which flags drift; superseded logs move verbatim to an archive with a pointer.
   *(Receipt: the state document stopped for 13 days; an already-ablated row was proposed for
   ablation twice before the owner caught it.)*
6. **Serial tails overlap the long stage.** Labelling, syncing, uploading and warm-ups run inside the
   recording or training window, so the post-stage tail is minutes; the ETA table shows the critical
   path so the principal can see the gaps.
7. **Reversible: act and report. Irreversible: one question, a recommendation, a default.**
   Configuration switches, launches inside the agreed plan, watcher restarts — do them and say so,
   with a time to object. Cancelling a run, changing the evaluation standard, deleting data — ask
   once, recommend, and name what happens if there is no answer. The question goes out at once as
   its own message, through a channel that reaches the principal away from the terminal, never
   inside a routine report. A pending question never parks the parts of the item that do not
   depend on it: do those first, and the question names only what is left. *(Receipt: a ready PR
   sat a day behind a scope question while its independent fixes went undone.)* Before cutting
   scope or choosing the simpler option, restate the work's stated purpose in one line and check
   that what remains still meets it; a cut that drops the purpose is a different decision, brought
   to the principal as such. *(Receipt: a PR whose single purpose was all data on one node was
   proposed 'as is' at a quarter of the data, after its memory failure was read as a reason to drop
   the feature rather than as the thing to fix.)* While the principal is still shaping a spec in
   quick messages, hold the launch: read back the whole spec in one message, then start the work
   once. Each mid-build change to an unattended worker costs a stop and a relaunch. *(Receipt: the
   same build agent was relaunched three times in an hour as the head, the base model and the
   set-speed variants were decided one message at a time; and a loss-ablation build was relaunched
   four times the same way a week earlier.)* When the only thing holding finished work is an
   approval for a side step (an upload, a shared write), build the variant without the side step so
   the main action proceeds under the authority it already has; bring the side step separately.
   *(Receipt: a training arm built at 2 AM waited ten hours for a go on uploading 58 small files its
   loader could have computed itself; the one-node dispatch was already pre-authorized.)* When each
   fix uncovers another gap, stop fixing: freeze outward changes, build the full fact base from
   independent angles (static audit, end-to-end run, measured need), have reviewers who see only the
   goal list what is required, and act only on a plan that survives that. *(Receipt: in one day a
   PR was reworked twice and two gap lists surfaced; the owner froze PRs until a verified roadmap
   existed.)*
8. **Credentials are part of the status.** Expiry against the next dispatch window is a line in every
   status; the principal is asked to refresh before the window, with the exact time — never after
   the stall.

## Instantiation

The project's state document (or CLAUDE.md) records: the clock, the resource floor, the gate, the
status command, the preflight command. When they change, change them there; the modes stay.

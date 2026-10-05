---
name: unattended-ops
description: Discipline for automation that runs without a human watching — background jobs, waiters, monitors, remote deploys, long pipelines. Use when building or debugging anything gated, queued, detached, or scheduled on remote machines. Unattended automation fails silently at boundaries that were never tested; these rules make the failures loud or impossible.
---

# unattended-ops

Unattended automation fails at untested boundaries, and the failure mode is almost
always *silence*: a waiter that never opens, a monitor that can't see the phase the
job is in, a script corrupted mid-run. Every rule here was paid for in lost
GPU-hours.

## Synchronization

- **Never gate on process-table text.** A process's argv contains the full text of
  anything written through it — a shell that ran `cat > script <<EOF` carries the
  script body, including whatever pattern the script's own gate greps for, so
  pattern-gates can block forever on the shell that created them (or on your own
  status-check ssh). Gate on owned tokens instead: a lock file, a PID file written
  by the job itself, or a resource query **filtered to your workload**. Same trap one
  surface up: address remote objects by unique key, never by position in a listing or by the newest line of a shared log —
  `order="-created_at"` has returned a twelve-day-old run as newest, and a watcher
  bound to the wrong object does not fail, it reports about something else. And a gate
  must not be able to satisfy itself: a waiter may never emit the signal it waits for in
  any form — log line, heartbeat, status stamp, filename — or it fires on its own output.
  *(Receipt: a start stamp that named the awaited token opened the gate early, three
  times in one day.)*
- **A probe or kill must carry no matchable trace of its target.** Match by an identity only
  the target produces, in an invocation that contains nothing else — or exclude the caller's
  own ancestry from the match; repeating one filtered probe is not a second angle. *(Receipts:
  a kill inside a compound command killed the command itself four times, once causing a
  2.5 h watcher outage; a tag-filtered query concluded "no run" because the tag under test
  was itself the defect.)*
- **Resource queries have a non-empty idle baseline.** "Wait until no CUDA
  contexts / no connections / no locks" asserts an invariant about the whole
  machine; shared machines violate it at rest (a desktop daemon holds a GPU
  context permanently). Filter to your own process class.
- **Test both branches of every wait-predicate before trusting it.** Run the gate
  query once in the state it waits *for* and confirm it reads "open", and once in
  the busy state and confirm "closed". A predicate validated only against the
  failure that prompted it recurs under a new false positive.
- **A stage boundary is crossed on the product, and only an integrity failure halts the
  chain.** The consumer verifies the product's sufficiency itself — counts, gates, identity
  matched by field position, a stamp dated after the consumer's own start — never the
  producer's exit status or a substring of its log. A bound that ends a run by design
  (timeout, budget, worker floor) hands the next stage a failure-shaped signal that only the
  artifact can adjudicate; and a policy threshold on a value already saved is recorded and
  carried forward, never aborted. *(Receipts: a labeler sat on a good recording that ended on
  its own 12 h cap; a share-tolerance abort idled a pipeline; a worker floor sized for
  24-episode evals killed three healthy 8-episode screens after an hour each; a stale DONE
  and a quoted token each satisfied a waiter.)*
- **One serial resource, one scheduler.** When several jobs wait on the same serial
  resource, priority is a property of one ordering, not of the waiters: independent
  waiters race, and whichever polls or settles fastest wins regardless of what matters.
  Encode the order explicitly in a single queue that ranks by what unblocks the next
  decision, and make every yield an entry in that order. *(Receipt: a lower-priority job
  with a 180 s settle beat a higher-priority one with a 330 s window after it had waited
  four hours.)*
- **HARD RULE — quiesce file-sync around VCS writes; diffstat before every push.**
  A sync daemon that mirrors `.git` can deliver a stale index, and a "one-file"
  commit then silently snapshots an entire stale tree. Pause the sync for the
  duration of any commit/merge/rebase on a synced repo, and before pushing verify
  `git diff <expected-parent> HEAD --stat` lists exactly the intended files — a
  one-file commit reporting "120 files changed" is this trap firing.

## Deployment

- **Scripts reach remote hosts by file transfer (scp/rsync), never heredoc-through-ssh.**
  The heredoc leaves the script text in a shell's argv (see above) and quoting
  mangles silently.
- **Never edit a file a running shell is executing.** Bash reads scripts lazily by
  byte offset; a mid-run edit shifts what the loop reads next and corrupts
  execution while the process still reports alive. Copy to a new name, kill by
  PID (not by pattern — your kill command's own argv can match), relaunch.
- **A synced or mounted tree is a live deploy.** Where a sync daemon, bind mount, or
  hot-reload watcher connects your working copy to a running system, every save
  ships — not only into the script currently executing (above) but into any module a
  live process imports later: worker spawns, lazy imports, re-read configs. For the
  duration of a run whose result you need, treat the tree as frozen and stage changes
  outside it.
- **Anything leased must outlive the job that depends on it — and the lease is read from
  the resource, not inferred from failures.** Credentials, compute instances, locks,
  reservations, certificates, sessions: before launch, read the remaining life from the
  resource's own state and refuse if it does not cover provisioning plus the run, and
  that the resource is free, not merely owned. A lease
  that expires mid-job surfaces downstream as unrelated-looking errors, the most expensive
  place to learn it. *(Receipt: a one-hour default lease under two-hour runs put a phantom
  "2 errored" into every published number for a day.)* For credentials specifically: stamp
  an auth death distinctly from a data fault — `rc=1` cannot tell them apart; check the
  profile the *failing step* uses; and where work outlives any token, poll rather than
  strand it.
- **Verify detached processes from a fresh connection.** A backgrounded process
  that appears alive in the launching session may have died with it.
- **Incidental machinery must not be able to destroy the run's product.** A long
  unattended job exists to produce one artifact; anything optional around it —
  telemetry, a logged image, a metrics push, the choice of output location — must
  not be able to take that away. Two forms, both paid for: wrap every diagnostic
  emission so a failure degrades to a warning, because a debug thumbnail that
  raises will end a multi-day run as readily as a bad gradient; and persist the
  product through a channel you have *verified you can read back* with the
  credentials you actually hold, preferring a static credential over a session
  token, and persisting the smallest sufficient artifact (a 513-parameter delta
  over frozen pinned weights reconstructs the model; the gigabyte checkpoint buys
  nothing). "The platform stores it" and "I can retrieve it" are different claims.

## Monitoring

- **Cover every lifecycle stage.** A metrics-side watcher (W&B, logs) structurally
  cannot see a job that is queued and not yet running; the scheduler is the only
  witness to admission. Watch the submitter for admission and the logger for
  progress — inferring one from the other turns a queue into a phantom failure.
- **Silence must be distinguishable from failure.** Every waiter logs a heartbeat
  with a timestamp; a monitor whose healthy output is *nothing* cannot be told
  apart from a dead one. Auth used by long-lived monitors expires — a poller that
  starts returning empty after hours may be unauthenticated, not idle. The heartbeat
  needs a reader that runs without the session: a sentinel on the machine restarts a
  dead waiter once and pings on its second death. An assistant's session is neither a
  watcher nor a scheduler; it runs only during turns, so capacity that can free while it
  is out gets a verified default job armed on the machine. *(Receipts: a chain died on an
  unbound variable after its first step; the resource idled 8 h overnight. Two reserved
  nodes freed during a session outage and idled ~2 h.)*
- **Verify an expensive async job's resolved config and its health counters (skipped
  or non-finite steps, step rate) in its first minutes**, not at readout — the cost of a
  silent config miss grows with every hour it runs — and arm nothing on the run's result
  before that check. Pair
  with a pre-dispatch guard that refuses to fire against a stale artifact, and
  watch the guard *refuse* once before opening it. A fix does not reach work already in
  flight: a queued job's code is frozen at dispatch, so when a defect is fixed, list every
  queued, running and scheduled job built before the fix and cancel or re-dispatch it.
- **A composition is verified member by member, and a member contributing nothing fails
  the run before it starts.** "Unchanged input" is not "unchanged behavior" when the reader's
  parameters moved; an input a program accepts but does not consume must fail loudly; a
  completion stamp names the input it consumed. *(Receipts: a replay anchor yielded 0 samples
  at a new window and a GPU-hour trained on labels alone; a scorer ignored its tag argument
  and stamped success three times; a goal-less scenario silently fell back to a different
  reference.)*

## When to invoke

- Writing any waiter, poller, watcher, chained pipeline, or overnight automation.
- Handing a trigger to someone who will run it later unattended.
- Debugging "it's been queued/waiting for hours" — check the gate's both branches
  and the monitor's blind spots before theorizing about the job.

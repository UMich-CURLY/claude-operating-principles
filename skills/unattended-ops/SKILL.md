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
  by the job itself, or a resource query **filtered to your workload**. The same trap
  sits one surface up: address a remote object by a unique key, never by its position
  in a listing. "The newest run", "the latest artifact" are selections over a shared
  namespace ordered by a server you do not control — a sort parameter can be silently
  ignored, and `order="-created_at"` has returned a twelve-day-old run as newest.
  Query by an identifier that can match only your object and confirm exactly one came
  back; a watcher bound to the wrong object does not fail, it reports confidently
  about something else.
- **Resource queries have a non-empty idle baseline.** "Wait until no CUDA
  contexts / no connections / no locks" asserts an invariant about the whole
  machine; shared machines violate it at rest (a desktop daemon holds a GPU
  context permanently). Filter to your own process class.
- **Test both branches of every wait-predicate before trusting it.** Run the gate
  query once in the state it waits *for* and confirm it reads "open", and once in
  the busy state and confirm "closed". A predicate validated only against the
  failure that prompted it recurs under a new false positive.
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
- **A leased credential must outlive the job it launches.** Session tokens (SSO, STS,
  k8s, signed URLs, VPN) expire on a wall clock the job knows nothing about, and the
  failure lands deep in the run, after the expensive part is spent. At launch, check
  validity *and* compare remaining life against expected duration, refusing if it does
  not fit: an 80-minute job under a 20-minute token is a scheduled failure, not bad
  luck. Stamp an auth death distinctly from a data fault — `rc=1` cannot tell an
  operator which happened, and they need opposite responses. Where several profiles or
  scopes are in play, check the one the *failing step* will use, not the one in hand.
  Where the work outlives any obtainable token, have the waiter poll for credentials to
  return rather than fail and strand a finished artifact.
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
  starts returning empty after hours may be unauthenticated, not idle.
- **Verify an expensive async job's resolved config in its first minutes**, not at
  readout — the cost of a silent config miss grows with every hour it runs. Pair
  with a pre-dispatch guard that refuses to fire against a stale artifact, and
  watch the guard *refuse* once before opening it.

## When to invoke

- Writing any waiter, poller, watcher, chained pipeline, or overnight automation.
- Handing a trigger to someone who will run it later unattended.
- Debugging "it's been queued/waiting for hours" — check the gate's both branches
  and the monitor's blind spots before theorizing about the job.

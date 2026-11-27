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
  bound to the wrong object does not fail, it reports about something else. When the object can be
  replaced (retry, re-dispatch), re-resolve its key from the durable name at every check. A one-time
  permission is revoked as soon as its action is taken or dropped, never left armed for a later one.
  *(Receipts: a watcher held a discarded run's id after a re-dispatch; an unused second-dispatch
  permission would have let a later duplicate through.)* And a gate
  must not be able to satisfy itself: a waiter may never emit the signal it waits for in
  any form — log line, heartbeat, status stamp, filename — or it fires on its own output.
  *(Receipt: a start stamp that named the awaited token opened the gate early, three
  times in one day.)* Gate on structured events the action itself emits (key=value lines, result
  records), never on words in free text (hand-off signals: `enforcement-discipline`, success records).
  *(Receipts: a text check matched a negation and hid ready work; a "done" flag was written although
  the step before it had failed.)*
- **A probe or kill must carry no matchable trace of its target.** Match by an identity only
  the target produces, in an invocation that contains nothing else — or exclude the caller's
  own ancestry from the match; repeating one filtered probe is not a second angle. *(Receipts:
  a kill inside a compound command killed the command itself four times, once causing a
  2.5 h watcher outage; a tag-filtered query concluded "no run" because the tag under test
  was itself the defect.)*
- **Stop processes only by the PIDs you recorded at launch, never by a name pattern.** A
  pattern sent through a remote shell matches that shell's own command line and kills the
  session mid-step, leaving half-stopped children. *(Receipt: `pgrep -f "record_round.sh A"`
  over ssh killed its own session; the recorder's parent died, its python child kept running,
  and a watching agent restarted the cells on top.)*
- **Resource queries have a non-empty idle baseline.** "Wait until no CUDA
  contexts / no connections / no locks" asserts an invariant about the whole
  machine; shared machines violate it at rest (a desktop daemon holds a GPU
  context permanently). Filter to your own process class.
- **Test both branches of every wait-predicate before trusting it.** Run the gate
  query once in the state it waits *for* and confirm it reads "open", and once in
  the busy state and confirm "closed". A predicate validated only against the
  failure that prompted it recurs under a new false positive. A waiter reads only evidence
  written after it started (a verdict left by an earlier attempt reads as this attempt's), and
  probes readiness with the exact check the gated step will run (a cached CLI answer passed while
  the step's own credential probe refused). *(Receipt: a dispatch chain stopped at once on the
  previous attempt's refusal, and a login waiter fired on a cached CLI token while the dispatch's
  own probe still refused.)*
- **A stage boundary is crossed on the product, and only an integrity failure halts the
  chain.** The consumer verifies the product's sufficiency itself — counts, gates, identity
  matched by field position, a stamp dated after the consumer's own start — never the
  producer's exit status or a substring of its log. A bound that ends a run by design
  (timeout, budget, worker floor) hands the next stage a failure-shaped signal that only the
  artifact can adjudicate; and a policy threshold on a value already saved is recorded and
  carried forward, never aborted. A waiter's own bound is set from the measured duration of
  what it waits on, plus margin, and re-set when that measurement changes. *(Receipts: a
  labeler sat on a good recording that ended on its own 12 h cap; a share-tolerance abort
  idled a pipeline; a worker floor sized for 24-episode evals killed three healthy 8-episode screens after an hour each; a stale DONE
  and a quoted token each satisfied a waiter; a follow-up waiter bounded at 6 h timed out
  under a gate already measured at 8-10 h, and the night's follow-up review did not start
  until it was re-armed by hand.)*
- **One serial resource, one scheduler.** When several jobs wait on the same serial
  resource, priority is a property of one ordering, not of the waiters: independent
  waiters race, and whichever polls or settles fastest wins regardless of what matters.
  Encode the order explicitly in a single queue that ranks by what unblocks the next
  decision, and make every yield an entry in that order. On a resource shared with others,
  a held queue position belongs to that order: never give it up before its replacement is
  queued, and cancel the job being replaced only after its successor is submitted.
  *(Receipts: a lower-priority job with a 180 s settle beat a higher-priority one with a
  330 s window after it had waited four hours; a queued job cancelled ten minutes before
  its replacement could be submitted let another team's job take the reserved node.)*
  Before asking for more of a scarce resource, split each job's time into waiting and running:
  capacity already held but idle is cheaper to put to work than new capacity is to buy. *(Receipt: each
  evaluation ran 16 min and waited 45 for a slot while its instances sat held and idle; a scheduling rule
  change, not more instances, was the fix.)*
- **Size an unattended job against the limit that binds and everything armed beside it.**
  The binding limit is the enforced quota (a per-user or per-group cap), not the machine's
  visible total, and the load is everything else armed on the machine, not an idle box.
  *(Receipts: the same relabel shards were killed for memory twice, once at a 184 GiB
  group quota while the machine showed 499 GB free; two builds each sized for an idle box
  overlapped.)*
  The limit is checked by the code that runs the job, at the moment it runs: a queued job
  re-checks free space, quotas and every limit the far end enforces (lengths, sizes) before
  its expensive step; a check made at queue time goes stale. *(Receipts: a build queued at
  36 GB free started at 31 GB and ran out of disk; a 502-character run description was
  rejected after the image was built and pushed.)*
  Count what already holds the capped resource from the system that enforces the cap, not from
  the launcher's own list, which misses jobs started any other way. *(Receipt: a node queue's
  running list was empty while two directly launched runs held both nodes of a two-node cap.)*
  A usage quota that resets on a window binds the same way: budget a job's run time against every
  window it crosses, and concurrent jobs by their combined burn, sub-agents included. *(Receipt:
  7-9 concurrent agents against a cap of 4 exhausted both accounts in 2-3 h and all stalled.)*
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
  outside it. Compare against another revision in a separate worktree, never by checking its
  files out over the working tree: files that exist only in the other revision stay behind as
  staged additions and ride into the next commit. *(Receipt: a mypy comparison re-added three
  files main had deleted, staged, one step before a push.)*
- **Anything leased must outlive the job that depends on it — and the lease is read from
  the resource, not inferred from failures.** Credentials, compute instances, locks,
  reservations, certificates, sessions: before launch, read the remaining life from the
  resource's own state and refuse if it does not cover provisioning plus the run, and
  that the resource is free, not merely owned. A lease
  that expires mid-job surfaces downstream as unrelated-looking errors, the most expensive
  place to learn it. *(Receipt: a one-hour default lease under two-hour runs put a phantom
  "2 errored" into every published number for a day.)* For credentials specifically: stamp
  an auth death distinctly from a data fault — `rc=1` cannot tell them apart; check the
  profile and client the *failing step* uses (a CLI answered from a cached role while the
  SDK's session was dead); and where work outlives any token, poll rather than
  strand it. When a lease will expire before the planned capacity frees, launch now on other
  capacity and hedge with a duplicate on the planned capacity; cancel the copy that did not
  start once one trains. *(Receipt: a login expiring at 6:30 AM would have stranded two runs
  waiting for nodes freeing at 6 AM.)*
- **Cleanup runs on every exit path.** What a job creates for itself (images, temp trees,
  locks, instances) is released by a trap on exit, not by its success branch; a failed run
  otherwise leaves its debris for the next run to trip on. *(Receipt: a dispatch that died on
  a dropped login left its 37 GB image behind; the retry then sat in a disk wait at 20 GB free
  until the image was removed by hand.)* A guard that delays releasing a shared resource counts
  only that resource's own users, and on timeout it releases; it never lets the resource lapse to
  its expiry while others queue for it. *(Receipt: an idle pool of shared simulator instances
  stayed held because a job on another pool counted as in use, until a two-hour expiry, while two
  colleagues' requests queued.)*
- **Each queued item runs in its own environment.** A runner that loads item settings into one
  long-lived shell carries every item's settings into the next; start each item in a fresh process so it
  gets exactly the settings it names. *(Receipt: one item's guard override stayed set for every later
  item, silently disabling the guard.)*
- **A standing job's files live somewhere durable.** Anything a recurring check or waiter
  executes or reads (its script, its state) sits outside temp and scratch directories, which
  get swept, and the job fails loudly when the file is missing instead of reporting old
  output. *(Receipt: the hourly check's script vanished from the session scratchpad overnight;
  the next run printed the previous hour's saved output until the missing file was noticed.)*
- **A deliverable owed by a fixed time is written first and kept current.** The job writes the
  report's skeleton before any work and updates it after every completed step, so a quota stop,
  crash or late finish still leaves a usable, dated report. *(Receipt: two of four overnight
  review agents owed reports by 06:00 each hit two usage-limit windows and wrote nothing until
  after the deadline.)*
- **Verify detached processes from a fresh connection.** A backgrounded process
  that appears alive in the launching session may have died with it. Record the pid of the
  process that does the work, not of its launcher: `setsid cmd & echo $!` (or a `bash -c`
  wrapper) captures a short-lived parent, so a liveness check on it reads 'dead' while the
  work runs, or 'alive' after it died. Have the worker write its own pid, or check by its
  stamped outcome. *(Receipt: a read probe's recorded pid was the launch shell; it read DEAD
  while the probe had queued its reads normally.)* A recorded PID proves nothing alone: PIDs are
  reused, so liveness also checks the command line. *(Receipt: a check reported a finished agent
  alive because its old PID belonged to another process.)*
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
- **Keep dependencies alive, and read state only from live sources.** Renew leased resources
  (instances, credentials, reservations) before they expire. A status read with expired
  credentials is unknown, not a state: the monitor stamps it unobserved, never stalled or done
  (receipt: two finished runs paged as stalled while the status login was expired). Moving a path or dropping a stage is an interface change,
  so dry-run the whole pipeline through its last stage. A hold blocks new work but still records
  work that finishes. Retry a transient server error a bounded number of times, each time only
  after confirming the failed attempt created nothing. Bind a choice that depends on other jobs'
  outputs (which parent, which input) at the latest moment it is needed, and run every step that
  does not depend on it before then. *Watchers die with their session*: a scheduled check that
  lives in the assistant's session (cron, monitor) is lost when the context resets; after any
  reset, list scheduled jobs first and re-arm every standing one before other work. *(Receipt:
  the hourly box check silently stopped after a context reset; two finished studies and a
  100%-full disk went unreported for hours until the owner asked.)* A health probe reports
  alive, dead or busy (a lock or rate limit held by a sibling); busy never reads as dead.
  *(Receipt: a login probe read 'dead' for six minutes during each of four dispatches because a
  CLI lock was held.)*

## Monitoring

- **Cover every lifecycle stage.** A metrics-side watcher (W&B, logs) structurally
  cannot see a job that is queued and not yet running; the scheduler is the only
  witness to admission. Watch the submitter for admission and the logger for
  progress — inferring one from the other turns a queue into a phantom failure.
- **Switching off a default downstream step arms its replacement in the same action**,
  confirmed alive. *(Receipt: two training dispatches suppressed their default
  evaluation follower with nothing replacing it.)*
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
  A dropped candidate's queued work is withdrawn the same way, in the same action as the drop.
  *(Receipt: queued reads for a dropped candidate held the only GPU lock and delayed a release
  candidate's reads.)*
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

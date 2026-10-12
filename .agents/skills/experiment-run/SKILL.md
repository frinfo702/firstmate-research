---
name: experiment-run
description: >-
  Agent-only procedure for running an experiment job and keeping its record.
  Load before an experiment-mode worker launches, waits on, or concludes a run, and when firstmate handles an experiment worker's declared job wait or job-completion wake.
  Owns the one-hypothesis scope, the experiment record at data/<task-id>/experiment.md, detached launch outside the worker's copy, the paused wait declaration, and the completion wake through the process-event-sources condition->action watch.
user-invocable: false
metadata:
  internal: true
---

# experiment-run

Load this before you launch, wait on, or conclude a run in an `experiment` task, and as firstmate when an experiment worker declares a job wait or its job-completion watch wakes.
An experiment task ends at a pushed branch and a concluded record, never at a PR or a merge; `bin/fm-dod-lib.sh` owns that definition of done.

## One hypothesis

Each experiment tests exactly one hypothesis; `.agents/skills/rule-of-one/SKILL.md` owns that rule.
Any other problem you find mid-experiment - a bug, a weak baseline, a second idea - goes into the record's follow-ups as a new issue, never into a fix on this branch.

## The experiment record

Keep one record per task at `data/<task-id>/experiment.md`, the task-material directory your brief's rule 2 already authorizes.
Write it before launch and update it as facts arrive; it survives cleanup, while your copy does not.
It holds:

- **Hypothesis** - the one claim this run tests, phrased so a result can refute it.
- **Baseline** - what the result is compared against, with its own commit or run reference.
- **Config** - the exact command line and configuration, or the committed config file that holds them.
- **Seeds** - every random seed the run uses.
- **Commit** - the pushed commit the run executes.
- **Data version** - the dataset's identity: a version tag, content hash, or path plus checksum.
- **Run location and job id** - the host, the scheduler or tmux socket, and the job id or pid.
- **Outputs** - the run directory that holds checkpoints, logs, and metrics.
- **Completion condition** - one read-only command that exits 0 once the job has ended, including by crashing, and 1 while it still runs.
- **Metrics** - the measured results and the file or command that produced them.
- **Conclusion** - whether the hypothesis held; a negative or null result is a result and is recorded as one.
- **Follow-ups** - each other problem found, as a new issue.

## Launch

1. Commit the code and config the run uses and push the branch with `git push -u origin <branch>` before launch, so the recorded commit stays reachable after cleanup.
2. Pick a run directory outside your worktree: the location your brief names, otherwise `data/<task-id>/runs/<run-name>/`.
   Cleanup removes the worktree and everything inside it, so checkpoints, wandb or mlflow logs, and every other output go to the run directory, never into the worktree.
3. Export the pushed commit into the run directory, for example `git archive <commit> | tar -x -C <run-dir>/code`, so the job never reads from the worktree.
4. `cd` into the run directory and launch from there, detached: submit to a scheduler (`sbatch`), start a private tmux server (`tmux -L <job> new-session -d -s <job> -c <run-dir> '<cmd>'`), or use `nohup` under `setsid` where it exists.
   Cleanup kills every process whose working directory is under the worktree, and a tmux server keeps the directory it was started from, so a job launched from inside the worktree dies at cleanup even under tmux.
   A plain `nohup <cmd> &` from your shell also stays in your pane's process group, which cleanup signals.
   Use a private tmux socket (`-L`), never the server your own pane runs in, so the job never appears among firstmate's endpoints.
5. Wrap the command so it writes its exit status into the run directory when it ends, for example `sh -c '<cmd>; echo $? > <run-dir>/exit-status'`.
6. Record the job id, run location, and completion condition, for example `sh -c 'test -e <run-dir>/exit-status || ! tmux -L <job> has-session -t <job>'`, which is also true once a crashed job is gone.

The detached job is the experiment itself; never background a poll, a sleep loop, or a pipeline drive to stand in for waiting.

## Waiting

Never sit in a blocking command on a long run: a command limit kills it, and a turn busy for an hour reads as a possible wedge.
Append one `paused [at=<epoch>]: experiment job <job-id> running, completion condition in data/<task-id>/experiment.md until <YYYY-MM-DDTHH:MMZ>` line naming the expected finish time, then end your turn.
Firstmate's message wakes you when the job ends; read the exit status and outputs before anything else.
A failed or killed job is a fact for the record, not a reason to rerun silently: record what happened, and rerun only when the rerun still tests the same hypothesis.

## Firstmate: completion wake

When an experiment worker's `paused:` line names a job, load `process-event-sources` and arm one condition->action watch for it, reusing that adapter rather than any new watcher:

```sh
bin/fm-procevent-when.sh arm <task-id>-job --condition <completion-condition argv> --action true
```

Read the recorded completion condition first and arm it only when it is a read-only probe of the job; `bin/fm-procevent-when.sh --help` owns the cadence and deadline options.
The action stays the no-op `true`, because what follows a finished run is a judgment rather than a deterministic action.
On a `fired` outcome, tell the worker through `fm-send` that its job ended, then acknowledge and retire the watch as `process-event-sources` describes.
On `never-true` or `condition-error`, the job's state is unknown: inspect the recorded run location before steering the worker.

## Concluding

Fill in the record's metrics and conclusion, negative results included, and list the follow-ups.
Commit any analysis code worth keeping, push it, and leave the worktree clean; then report done as your Definition of done says.

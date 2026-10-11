---
name: rule-of-one
description: >-
  Agent-only owner of the Rule of One ("One Ping"): one task, paper, or report carries exactly one central problem, hypothesis, or contribution.
  Load before writing a ship or scout brief, before deciding a validation or review finding, before reviewing or revising a paper or report draft, and whenever a problem outside the current task's one problem or hypothesis is discovered mid-task.
user-invocable: false
metadata:
  internal: true
---

# Rule of One

This skill is the single owner of the Rule of One, also called "One Ping": one unit of work carries exactly one central thing, stated up front and checked for drift at every step.
`AGENTS.md` section 7 makes it mandatory, and `bin/fm-brief.sh` carries the worker-side rule into every ship and scout brief.

## Writing

This applies to papers, reports, scout reports, and any other document whose purpose is to convey a result.

- State the one central contribution up front, in a sentence a reader can repeat.
- When the work has several contributions, write them as parts of that one unified contribution; one that cannot be framed as serving it belongs in a separate document or is cut.
- At every drafting or revision step, re-read the stated contribution and check that every new or changed part serves it; cut or move what has drifted.
- A review of writing checks drift from the central contribution first, and a review comment that would add a second central claim is recorded as a new backlog item rather than written into this draft.

## Implementation and experiments

- Before work starts, the task names its one problem, for an implementation, or its one hypothesis, for an experiment, in one sentence in the brief's task subsections.
  A request that cannot be stated as one problem or hypothesis is split into separate tasks at intake.
- Do only what solves that problem or tests that hypothesis: an implementation changes only what that problem needs, and an experiment varies and measures only what that hypothesis needs.
- When another problem appears mid-task, such as an unrelated bug, a tempting refactor, a flaky dependency, or a second hypothesis, do not fix, test, or investigate it in passing.
  A worker records it as a suggested follow-up in its done summary or report and continues with the one problem.
  Firstmate files each recorded follow-up as its own backlog item, or an upstream issue where one fits.
- When that other problem blocks the one problem outright, the worker reports `blocked` with it instead of fixing it, and firstmate decides whether it becomes a prerequisite task.

## Review stage

When firstmate decides a validation finding under `validation-supervision` and `ask-user-authority`, or reviews writing, first ask whether the finding concerns the task's one problem or hypothesis.
A finding about that one problem is decided by those skills as usual, including the smallest downstream changes needed to keep its solution correct, tested, and documented.
A finding about any other problem is declined for the current task and filed as a new backlog item, never absorbed into the current run or draft.

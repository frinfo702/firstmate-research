---
name: research-testing
description: >-
  Agent-only testing policy for research code.
  Load before writing, changing, deleting, or requesting tests in a research project, and before deciding whether a fix, finding, or reproduced bug in research code needs a test.
  Owns which research code gets tests, how small they stay, what is validated as an experiment instead, and when obsolete tests are deleted.
user-invocable: false
metadata:
  internal: true
---

# research-testing

Research code is rewritten often and much of it is thrown away, so exhaustive production-style unit testing slows research down without protecting its results.
This skill is the single owner of the research testing policy; other skills defer to it when the work is research code.

## What to test

Test only hand-written, deterministic logic whose error would silently invalidate the results.
Typical targets are:

- Loss functions and objectives.
- Evaluation metrics and scoring.
- Data processing, filtering, and train, validation, and test splits, including leakage between splits.
- Shape, dtype, unit, and range invariants at the boundaries of that logic.

Prefer the parts the researcher implemented directly over parts delegated to a library.

## How to test

- Use small, fixed inputs whose correct output can be checked by hand.
- Keep each test fast and short, runnable in seconds and readable in a few dozen lines.
- Fix any seed a deterministic test needs rather than tolerating flaky outcomes.
- When the work relies on an assumption that "this must be true", record it as an `assert` in the code or as a small test, so a later change that breaks it fails loudly.

## What not to unit-test

- Stochastic outcomes such as training accuracy, convergence, or benchmark scores.
  Validate those as experiments with recorded configuration and results, not as unit tests.
- Library behavior the project only calls.
- Throwaway experiment scripts, notebooks, and one-off analysis code.

## When core code changes

When core research code is destructively rewritten, delete tests for the obsolete behavior rather than preserving or adapting them.
Write new tests only for the deterministic contracts the new code actually has.

## Optional checklist

Google's ML Test Score lists 28 tests and monitoring items for production ML readiness.
It may be consulted as an optional checklist for picking a few relevant items, never as a requirement for research code.

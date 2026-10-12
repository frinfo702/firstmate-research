## Research testing policy

This home does research work.
Before writing, changing, deleting, or requesting tests, load the `research-testing` skill and follow it.
If that skill name does not resolve, read `<firstmate checkout>/.agents/skills/research-testing/SKILL.md` instead.
Test only hand-written deterministic logic whose error would invalidate results, never stochastic outcomes such as accuracy, and delete obsolete tests when core code is rewritten.
The research project's own no-mistakes review and test agents see this policy only through that project's `AGENTS.md`, where a human deliberately adds this exact line:
"Testing follows the research-testing policy: test only hand-written deterministic logic with small fixed inputs; stochastic outcomes are validated as experiments, not unit tests."
Never add or edit that line yourself.

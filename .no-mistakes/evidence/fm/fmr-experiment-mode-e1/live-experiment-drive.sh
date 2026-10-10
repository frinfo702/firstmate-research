#!/usr/bin/env bash
# Live drive of the experiment delivery mode against a disposable lab FM_HOME.
set -u
ROOT=$1
REAL_TMUX=$(command -v tmux)
LAB=$(mktemp -d "${TMPDIR:-/tmp}/fm-lab.XXXXXX")
"$ROOT/bin/fm-lab-home.sh" create "$LAB" >/dev/null
S=$(mktemp -d "${TMPDIR:-/tmp}/fm-exp-scratch.XXXXXX")
trap '"$REAL_TMUX" -L fmexpjob-out kill-server 2>/dev/null; "$REAL_TMUX" -L fmexpjob-in kill-server 2>/dev/null; rm -rf "$LAB" "$S"' EXIT
H() { printf '\n===== %s =====\n' "$*"; }
run() { printf '$ %s\n' "$*"; env -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE FM_HOME="$LAB" "$@"; echo "[exit $?]"; }

H "S1 registry: a project registered [experiment] resolves as itself"
printf '%s\n' '# Projects' '- expproj [experiment] - lab fixture (added 2026-10-10)' > "$LAB/data/projects.md"
run "$ROOT/bin/fm-project-mode.sh" expproj

H "S2 brief: --mode experiment scaffolds a push-only, no-PR, no-pipeline contract"
run "$ROOT/bin/fm-brief.sh" exp-live-a1 expproj --mode experiment
B="$LAB/data/exp-live-a1/brief.md"
echo "--- rule 1 + Definition of done section of $B:"
grep -n '^1\. Never' "$B"
sed -n '/^# Definition of done/,/^# /p' "$B"
echo "--- PR/pipeline wording present? (expect none):"
grep -nE 'gh-axi pr|no-mistakes doctor|axi run' "$B" || echo "(none)"

H "S3 adversarial: experiment + gerrit forge is refused"
run "$ROOT/bin/fm-brief.sh" exp-live-a2 expproj --mode experiment --forge gerrit
H "S3b adversarial: unknown mode still refused with experiment in the closed set"
run "$ROOT/bin/fm-brief.sh" exp-live-a3 expproj --mode experimental

H "S4 teardown: unpushed experiment branch refused, pushed one cleaned with no PR/merge; detached job outside worktree survives, job inside worktree is reaped"
FB="$S/fakebin"; mkdir -p "$FB"
printf '#!/bin/sh\nexit 0\n' > "$FB/treehouse"; printf '#!/bin/sh\nexit 0\n' > "$FB/tmux"
printf '#!/bin/sh\ncase "$1 $2" in "pr list") echo "count: 0 (showing first 0)"; echo "pull_requests[]: []";; "pr view") exit 1;; esac\nexit 0\n' > "$FB/gh-axi"
printf '#!/bin/sh\ncase "$1 $2" in "pr view") exit 1;; esac\nexit 0\n' > "$FB/gh"
printf '#!/bin/sh\nexit 0\n' > "$FB/no-mistakes"
chmod +x "$FB"/*
git init -q --bare "$S/origin.git"; git -C "$S/origin.git" symbolic-ref HEAD refs/heads/main
git clone -q "$S/origin.git" "$S/seed" 2>/dev/null
git -C "$S/seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base; git -C "$S/seed" push -q origin main
git clone -q "$S/origin.git" "$S/project"; git -C "$S/project" remote set-head origin main 2>/dev/null
git -C "$S/project" worktree add -q -b fm/exp-x1 "$S/wt" main
printf 'window=firstmate:fm-exp-x1\nendpoint_task_id=exp-x1\nworktree=%s\nproject=%s\nkind=ship\nmode=experiment\nspawn_gen=lab-exp-x1\n' "$S/wt" "$S/project" > "$LAB/state/exp-x1.meta"
touch "$LAB/state/.last-watcher-beat"
printf '%s\n' '# Backlog' '' '## In flight' '' '## Queued' '' '## Done' > "$LAB/data/backlog.md"
tasks-axi add exp-x1 "experiment lab task" --kind ship --file "$LAB/data/backlog.md" >/dev/null
tasks-axi start exp-x1 --file "$LAB/data/backlog.md" >/dev/null
echo 'lr: 3e-4' > "$S/wt/config.yaml"; git -C "$S/wt" add config.yaml; git -C "$S/wt" -c user.email=t@t -c user.name=t commit -q -m "experiment config"
echo "--- S4a teardown with the experiment branch NOT pushed:"
PATH="$FB:$PATH" run "$ROOT/bin/fm-teardown.sh" exp-x1 2>&1 | tail -5
[ -d "$S/wt" ] && echo "worktree still present: yes"
echo "--- push the branch per the DoD (git push -u origin fm/exp-x1), launch two detached jobs per experiment-run"
git -C "$S/wt" push -q -u origin fm/exp-x1; git -C "$S/project" fetch -q origin
RUN="$LAB/data/exp-x1/runs/r1"; mkdir -p "$RUN"
"$REAL_TMUX" -L fmexpjob-out new-session -d -s job -c "$RUN" "sh -c 'sleep 600; echo \$? > $RUN/exit-status'"
"$REAL_TMUX" -L fmexpjob-in  new-session -d -s job -c "$S/wt" "sleep 600"
sleep 1
echo "outside-worktree job alive before: $("$REAL_TMUX" -L fmexpjob-out has-session -t job 2>/dev/null && echo yes || echo no)"
echo "inside-worktree job alive before:  $("$REAL_TMUX" -L fmexpjob-in has-session -t job 2>/dev/null && echo yes || echo no)"
echo "--- S4b teardown with the experiment branch pushed:"
PATH="$FB:$PATH" run "$ROOT/bin/fm-teardown.sh" exp-x1 2>&1 | tail -8
sleep 2
echo "worktree removed: $([ -d "$S/wt" ] && echo no || echo yes)"
echo "backlog row state: $(tasks-axi show exp-x1 --file "$LAB/data/backlog.md" | sed -n 's/^  state: *//p' | head -1)"
echo "origin still has fm/exp-x1: $(git -C "$S/origin.git" rev-parse --verify -q refs/heads/fm/exp-x1 >/dev/null && echo yes || echo no)"
echo "origin main unchanged (no merge): $(git -C "$S/origin.git" log --oneline main | wc -l | tr -d ' ') commit(s) on main"
echo "outside-worktree job alive after: $("$REAL_TMUX" -L fmexpjob-out has-session -t job 2>/dev/null && echo yes || echo no)"
echo "inside-worktree job alive after:  $("$REAL_TMUX" -L fmexpjob-in has-session -t job 2>/dev/null && echo yes || echo no)"
echo "run dir outside worktree survives: $([ -d "$RUN" ] && echo yes || echo no)"

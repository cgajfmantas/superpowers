---
name: subagent-driven-development
description: Use when executing implementation plans with mostly independent tasks in the current session
user-invocable: true
disable-model-invocation: true
---

# Subagent-Driven Development

Execute plan: fresh implementer subagent per task, task review (spec + quality) after each, broad whole-branch review at end.

**Why subagents:** Delegate tasks to specialized agents with isolated context. Craft instructions + context precisely so they stay focused and succeed. Never inherit session context or history — construct exactly what they need. Also preserves own context for coordination.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

## Execution Discipline

Act as the principal orchestrator. Execute the plan with evidence-based verification, durable traceability, and explicit quality gates.

- Use a fresh implementer subagent for each task. After implementation, require independent task review with separate verdicts for specification compliance and code quality.
- Record actionable lessons in the progress ledger, including the supporting evidence and the later tasks they may affect. Review relevant lessons before each dispatch and final review.
- Lessons never override the plan. If a lesson contradicts or extends a requirement, follow the Plan Amendments process before continuing.
- When progress requires human input, use the harness's ask tool when available. If no ask tool is available, use the authorized interactive channel. Do not infer a material decision.
- Respect the human partner's explicit workspace strategy. Do not create or switch worktrees when instructed to continue in the current working tree.
- Do not proceed on ambiguity, unsupported assumptions, incomplete verification, or unresolved Critical/Important findings.

**Narration:** between tool calls, max one short line — ledger and tool results carry record.

**Continuous execution:** No pause to check in with human between tasks. Execute all tasks without stopping. Stop only for: BLOCKED status unresolvable, ambiguity that truly prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste human time — plan execution was the ask, so execute.

## When to Use

```  {.dot}
digraph when_to_use {
  "Have implementation plan?" [shape=diamond];
  "Tasks mostly independent?" [shape=diamond];
  "Stay in this session?" [shape=diamond];
  "subagent-driven-development" [shape=box];
  "executing-plans" [shape=box];
  "Manual execution or brainstorm first" [shape=box];

  "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
  "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
  "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
  "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
  "Stay in this session?" -> "subagent-driven-development" [label="yes"];
  "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):** - Same session (no context switch) - Fresh subagent per task (no context pollution) - Review after each task (spec compliance + code quality), broad review at end - Faster iteration (no human-in-loop between tasks)

## The Process

``` {.dot}
digraph process {
  rankdir=TB;

  subgraph cluster_per_task {
    label="Per Task";
    "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
    "Implementer subagent asks questions?" [shape=diamond];
    "Use ask tool if human decision needed; answer and provide context" [shape=box];
    "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
    "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
    "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
    "Dispatch fix subagent for Critical/Important findings" [shape=box];
    "Mark task complete in todo list and progress ledger" [shape=box];
  }

  "Read plan index + global-constraints.md only, create todos" [shape=box];
  "More tasks remain?" [shape=diamond];
  "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [shape=box];
  "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

  "Read plan index + global-constraints.md only, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
  "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
  "Implementer subagent asks questions?" -> "Use ask tool if human decision needed; answer and provide context" [label="yes"];
  "Use ask tool if human decision needed; answer and provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
  "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
  "Implementer subagent implements, tests, commits, self-reviews" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)";
  "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
  "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
  "Dispatch fix subagent for Critical/Important findings" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [label="re-review"];
  "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
  "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
  "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
  "More tasks remain?" -> "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [label="no"];
  "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-a-development-branch";
}
```

## Pre-Flight Plan Review

Before Task 1, read plan index (task list) and every constraint file it links — `plan/global-constraints.md` plus any `global-constraints.<layer>.md` — scan for conflicts visible without task bodies:
- task title or a global constraint contradict each other
- two constraint files contradict each other, or same constraint appears in base *and* a layer file (drift risk — one copy, in base)
- layer-split plan whose index annotates a task with a layer that has no file, or leaves a task unannotated
- constraint mandates something review rubric treats as defect (test asserting nothing, verbatim duplicated logic block)

No reading every task file upfront — index catches plan-level conflicts; per-task review loop nets conflicts that only emerge from implementation. Need one task's detail → read that one file, not all.

Present findings to human as one batched question — each finding beside plan text mandating it, ask which governs — before execution, not one interrupt per discovery mid-plan. Clean scan → proceed silent.

**No `global-constraints.md`?** Plan predates split, constraints still inside `plan.md`. Fix once, here, before Task 1: move `## Global Constraints` section into `plan/global-constraints.md` verbatim, replace section in index with link, record per Plan Amendments. Every dispatch then hands one path. Do **not** instead teach each dispatch to extract section out of `plan.md` — see File Handoffs.

## Per-Task Entry Gate

Before dispatching each implementer, verify all six invariants:

1. Previous task has both an approved spec verdict and an approved quality verdict.
2. No Critical or Important finding remains unresolved.
3. Ledger task state and recorded commit ranges agree with `git log`.
4. Relevant active lessons are included in this task's dispatch context.
5. Every decision that changed requirements is persisted through Plan Amendments.
6. Record `HEAD` and `git status --short`; identify pre-existing changes and do not let the task overwrite or absorb them.

Gate failure means resolve the mismatch before dispatch. After the implementer returns, compare `HEAD`, `git status --short`, and the task range against the snapshot. Every new change must belong to the assigned task; unrelated pre-existing changes must remain untouched. Generate `review-package` only after this scope check, because it packages committed changes and cannot expose unrelated uncommitted edits.

### Stash Safety Across Worktrees

Git stashes are repository-wide, not worktree-local. Another worktree can change what `stash@{0}` identifies at any time.

- Avoid stashing during SDD. Preserve and work around pre-existing changes whenever possible.
- Never use `git stash pop`, implicit `git stash apply`, or an assumed `stash@{n}`.
- If stashing is unavoidable, use a unique message containing the run and task identity, then immediately record the resulting full stash commit OID in the progress ledger.
- Restore only with `git stash apply <recorded-OID>`. Inspect `git status` and the diff before considering removal.
- Remove the stash only after locating the current `stash@{n}` whose full OID equals the recorded OID, for example with `git stash list --format='%H %gd %gs'`. Never drop by position alone.
- Conflict, unknown provenance, or OID mismatch means stop and preserve the stash for human resolution.
- Do not create tags for routine stash ownership; the recorded immutable OID is the identity and avoids persistent refs that may be pushed accidentally.

## Model Selection

Use least powerful model that handles each role. Cheaper, faster.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): fast cheap model. Most implementation tasks mechanical when plan well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): standard model.

**Architecture and design tasks**: most capable model. Final whole-branch review is one — dispatch on most capable model, not session default.

**Review tasks**: same judgment, scaled to diff size, complexity, risk. Small mechanical diff no need most capable model; subtle concurrency change does.

**Always specify model explicitly when dispatching subagent.** Omitted model inherits session model — often most capable, most expensive — silently defeats this section.

**Turn count beats token price.** Wall-clock and context cost scale with subagent turns; cheapest models routinely take 2-3× turns on multi-step work — cost more overall. Implementers write code from behavior specs and test-case data, not transcribe it: mid-tier model = floor for implementers and reviewers. Cheapest tier only for single-file mechanical fixes with a named covering test.

**Task complexity signals (implementation tasks):** - 1-2 files, fully specified behavior + test cases → mid-tier model - Multi-file, integration concerns → standard model - Design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer reports one of four statuses:

**DONE:** Treat status as a report, not proof of completion. First perform the post-task scope check from Per-Task Entry Gate. Then generate review package (`scripts/review-package PLAN_FILE BASE HEAD`, from this skill's directory — PLAN\_FILE = plan index path, locates feature's `sdd/` workspace; prints unique file path it wrote; BASE = commit recorded before dispatching implementer — never `HEAD~1`, which silently drops all but last commit of multi-commit task), and dispatch task reviewer with printed path.

**DONE\_WITH\_CONCERNS:** Work complete, doubts flagged. Read concerns before proceeding. Correctness or scope concerns → address before review. Observations (e.g., "this file is getting large") → note, proceed to review.

**NEEDS\_CONTEXT:** Missing info. Provide context, re-dispatch.

**BLOCKED:** Cannot complete. Assess blocker: 1. Context problem → more context, re-dispatch same model 2. Needs more reasoning → re-dispatch more capable model 3. Task too large → break into smaller pieces 4. Plan wrong → escalate to human

**Never** ignore escalation or force same model retry without changes. Implementer stuck = something must change.

## Handling Reviewer ⚠️ Items

Task reviewer may report "⚠️ Cannot verify from diff" items — requirements in unchanged code or spanning tasks. Don't block rest of review, but resolve each yourself before marking task complete: you hold plan and cross-task context reviewer lacks. Confirmed real gap = failed spec review — send back to implementer, re-review.

## Plan Amendments

Any decision that contradicts or extends the plan — an answer to an implementer question, resolution of a plan-mandated finding, a BLOCKED caused by wrong plan text, a changed interface — edit the affected task file (and `plan/global-constraints.md` or the spec if they carry it) **before continuing**, then append to ledger: `Task N: plan amended — <one line>`. When a signature or shared value changes, grep the old symbol across the whole `plan/` directory and update every occurrence (see writing-plans drift procedure).

Why: later task files and the final whole-branch reviewer read the plan. Stale plan = review against false requirements, and the next fresh subagent reads text you already overruled.

## Constructing Reviewer Prompts

Per-task reviews = task-scoped gates. Broad review happens once, at final whole-branch review.

**Every dispatch in this skill is a template, filled — never a prompt you write from memory.** Implementer → [implementer-prompt.md](implementer-prompt.md). Task reviewer and re-review → [task-reviewer-prompt.md](task-reviewer-prompt.md). Final whole-branch review → [code-reviewer.md](../requesting-code-review/code-reviewer.md). Fix dispatch → implementer template, scoped to the findings. Read the file at dispatch time; substitute placeholders; keep every section, including the ones that read like boilerplate.

Why it matters more here than it looks: these templates are the *only* thing making a fresh subagent's output comparable across tasks. Drop the reviewer's Calibration section and severities stop meaning the same thing between Task 3 and Task 11. Drop "Do Not Trust the Report" and the reviewer grades the implementer's own rationale. Drop the implementer's Evidence Contract and you get DONE with no RED/GREEN to check. The loss is silent — the dispatch still returns something that reads like a report.

Template genuinely wrong for a dispatch → change the template file, then dispatch from it. A one-off improvised prompt fixes one dispatch and loses the fix for every later one.

Filling reviewer template:

- No open-ended directives like "check all uses" or "run race tests if useful" without concrete task-specific reason
- No asking reviewer re-run tests implementer already ran on same code — implementer report carries test evidence
- No pre-judging findings — never instruct reviewer to ignore or not flag specific issue. Believe finding would be false positive → let reviewer raise, adjudicate in review loop. Prompt contains "do not flag," "don't treat X as a defect," "at most Minor," or "the plan chose" — stop: pre-judging, usually to dodge review loop.
- Global constraints handed to reviewer = its attention lens. Hand `plan/global-constraints.md` **as a path**, same file implementer read — no paste, no re-summary, no section extraction. Binding spec requirement missing from that file (exact value, exact format, stated relationship between components — "same layout as X", "matches Y") → add it to the file per Plan Amendments, then hand path; implementer of every later task needs it too, and a constraint that lives only in one reviewer prompt reaches nobody else. Reviewer template already carries process rules (YAGNI, test hygiene, review method) — constraints file for what THIS project's spec demands.
- Hand reviewer diff as file: run this skill's `scripts/review-package PLAN_FILE BASE HEAD`, pass reviewer printed file path (or, without bash: `git log --oneline`, `git diff --stat`, and `git diff -U10` for range, redirected to one uniquely named file). Output never enters own context; reviewer sees commit list, stat summary, full diff with context in one Read call. Use BASE recorded before dispatching implementer — never `HEAD~1`, silently truncates multi-commit tasks.
- Dispatch prompt describes one task, not session history. No pasting accumulated prior-task summaries ("state after Tasks 1-3") into later dispatches — real session dispatch hit 42k chars, 99% pasted history. Fresh subagent needs: its task, interfaces it touches, global constraints. Nothing else.
- Dispatch fix subagents for Critical and Important findings. Record Minor findings in progress ledger as you go; point final whole-branch review at that list to triage which must fix before merge. Roll-up nobody reads = silent discard.
- Finding labeled plan-mandated — or any finding conflicting with plan text — is human's decision, like any plan contradiction: present finding + plan text, ask which governs. No dismissing finding because plan mandates it; no dispatching fix that contradicts plan without asking.
- Final whole-branch review sees the whole branch, so it gets **every** constraint file — base plus all layer files, by path. Only stage where full set is correct; per-task gates get their task's subset.
- Final whole-branch review gets package too: run `scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE\_BASE = commit branch started from, e.g. `git merge-base main HEAD`), include printed path in final review dispatch — final reviewer reads one file, no re-deriving branch diff with git.
- Final review dispatch also names project's full test suite command. Final reviewer runs suite independently — only independent execution in pipeline; every earlier test result is implementer self-report. Verdict without own test run (or explicit statement it could not run) = incomplete review.
- Fix dispatch = implementer template, scoped to findings — not a hand-written "please fix these" note. Every fix dispatch carries implementer contract: fix subagent re-runs tests covering its change, reports results. Name covering test files in dispatch — one-line fix no need whole suite. Before re-dispatching reviewer, confirm fix report contains covering tests, command run, output; dispatch re-review once all three present.
- Final whole-branch review returns findings → dispatch ONE fix subagent with complete findings list — not one fixer per finding. Per-finding fixers each rebuild context, re-run suites; real session's final-review fix wave cost more than all its tasks combined.

## File Handoffs

Everything pasted into dispatch prompt — and everything subagent prints back — stays resident in context rest of session, re-read every later turn. Hand artifacts as files:

**Hand whole files, never section extractions.** Every artifact a subagent must read is a file it can Read start to finish. No dispatch ever tells a subagent to `sed -n '/## Section/,/^## /p'`, `head -N`, or "read section X of that file only": the range can mis-fire on its closing boundary, the line cap truncates, and the subagent cannot tell that it got a partial requirement. Artifact not its own file yet → make it one (Plan Amendments), don't teach the prompt to carve it out.

- **Task brief:** plan's task file (`plan/tasks/task.NN.md`) *is* brief — self-contained, no extract or copy. No reading task body into own context; hand path to implementer, subagent reads.
- **Global constraints:** `plan/global-constraints.md`, handed by path to every implementer and every reviewer. One file, one copy, whole read. Plan splits constraints by layer → hand base file **plus** files for layers plan assigns task (index task-list annotation + task file's `**Layers:**` line). Route off written annotation, never off task title; same set to implementer and its reviewer. Missing annotation, or layer with no file = plan bug → fix plan first (Plan Amendments).
- **Report file:** name implementer's report file after task file, same zero-padded number (task `…/plan/tasks/task.NN.md` → report `…/sdd/task-NN-report.md`), put in dispatch prompt. Implementer writes full report there, returns only status, commits, one-line test summary, concerns.
- **Reviewer inputs:** task reviewer gets same task file, same constraint file set implementer got, report file, review package — four paths, more if layer-split.

**Dispatch prompt = [implementer-prompt.md](implementer-prompt.md), filled.** Not a paraphrase of it, not one composed from memory. Its role boundary, workspace constraint, escalation statuses, evidence contract, and report contract are what make the returned report reviewable — a dispatch that drops them buys a report the review gate cannot use, and a review round to recover. Only these vary per task:
  (1) one line where task fits in project; (2) task-file path, introduced as "read this first --- it is your requirements, with the exact values to use verbatim"; (3) constraint file paths — base, plus this task's layer files if plan splits by layer; (4) interfaces and decisions from earlier tasks task file cannot know; (5) relevant active lessons, or `None`; (6) explicit workspace strategy; (7) your resolution of any ambiguity (if you had to open file); (8) report-file path. Exact values (numbers, magic strings, signatures, test cases) live in task file.

Rest of template is identical every task — so write it once per run to `…/sdd/implementer-common.md`, complete and verbatim, and have each dispatch read it by path. Relocation, not condensation: a hand-written "common" file that gists the template is the same violation as an ad-hoc prompt. See implementer-prompt.md § Factoring Out the Invariant Half.
- Fix dispatches append fix report (with test results) to same report file, return short summary; re-reviews read updated file.

## Durable Progress

Conversation memory no survive compaction. Real sessions: controllers that lost place re-dispatched entire completed task sequences — single most expensive failure observed. Track progress in ledger file, not only todos.

- Ledger lives in run's workspace — `progress.md` inside directory `scripts/sdd-workspace PLAN_FILE` prints (PLAN\_FILE = plan index path). Directory = `sdd/` sibling of plan's folder: `$HOME/.superpowers/YYYY/<feature-name>/sdd/` (`YYYY` = current year, e.g. `2026` — never literal `YYYY`), outside repo — shared across git worktrees, survives `git clean`.
- At skill start, check for ledger: `cat "$(scripts/sdd-workspace PLAN_FILE)/progress.md"`. Tasks marked complete there = DONE — no re-dispatch; resume at first task not marked complete.
- Task review comes back clean → append one ledger line in same message as other bookkeeping: `Task N: complete (commits <base7>..<head7>, review clean)`.
- Ledger = recovery map: commits it names exist in git even when context no longer remembers creating them. After compaction, trust ledger and `git log` over own recollection.

### Lessons Learned

Record only actionable lessons supported by evidence. Use this ledger shape:

```text
Lesson: <observation>
Evidence: <test, diff, failure, or reviewer finding>
Impact: <later tasks or final review affected>
Action: <context, constraint, or plan amendment required>
Status: active | incorporated | superseded
```

Before every dispatch and final review, read active lessons and pass only relevant ones as context. A lesson never overrides the plan: contradiction or extension means Plan Amendments first. Mark it `incorporated` when its action is persisted or completed; retain superseded entries for traceability.

## Formal Task Completion Contract

Subagent status is a report, not evidence of completion. Mark a task complete only when all artifacts establish:

- Requirements trace to the implementation and declared task test cases.
- The report records RED and GREEN evidence when the task brief declares test cases, plus all verification commands and results.
- The task reviewer independently returns separate approved verdicts for specification compliance and code quality. These are two verdicts from the task review gate, not necessarily two reviewer subagents.
- No Critical or Important finding remains open; required fixes have covering test evidence and clean re-review.
- The ledger records the verified commit range, clean review, and any actionable lessons.
- The post-task scope check confirms unrelated and pre-existing working-tree changes were not absorbed or modified.

Missing evidence means the task remains open even when the implementation appears correct.

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)

## Example Workflow

  You: I'm using Subagent-Driven Development to execute this plan.

  [Read plan index only: /home/hermes/.superpowers/2026/feature/plan/plan.md]
  [Create todos from the index task list]

  Task 1: Hook installation script

  [Dispatch implementer with the task-file path (…/plan/tasks/task.01.md) + report path + context]

  Implementer: "Before I begin - should the hook be installed at user or system level?"

  You: "User level (~/.config/superpowers/hooks/)"

  Implementer: "Got it. Implementing now..."
  [Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

  [Run review-package, dispatch task reviewer with the printed path]
  Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.

  [Mark Task 1 complete]

  Task 2: Recovery modes

  [Dispatch implementer with the task-file path (…/plan/tasks/task.02.md) + report path + context]

  Implementer: [No questions, proceeds]
  Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

  [Run review-package, dispatch task reviewer with the printed path]
  Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)
  Issues (Important): Magic number (100)

  [Dispatch fix subagent with all findings]
  Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant

  [Task reviewer reviews again]
  Task reviewer: Spec ✅. Task quality: Approved.

  [Mark Task 2 complete]

  ...

  [After all tasks]
  [Dispatch final code-reviewer]
  Final reviewer: All requirements met, ready to merge

  Done!

## Advantages

**vs. Manual execution:** - Subagents follow TDD naturally - Fresh context per task (no confusion) - Parallel-safe (subagents no interfere) - Subagent can ask questions (before AND during work)

**vs. Executing Plans:** - Same session (no handoff) - Continuous progress (no waiting) - Review checkpoints automatic

**Efficiency gains:** - Controller curates exact context needed; bulk artifacts move as files, not pasted text - Subagent gets complete info upfront - Questions surface before work begins (not after)

**Quality gates:** - Self-review catches issues before handoff - Task review carries two verdicts: spec compliance and code quality - Review loops ensure fixes work - Spec compliance prevents over/under-building - Code quality ensures implementation well-built

**Cost:** - More subagent invocations (implementer + reviewer per task) - Controller does more prep (per-task dispatch composition) - Review loops add iterations - But catches issues early (cheaper than debugging later)

## Red Flags

**Never:** - Start implementation on main/master branch without explicit user consent - Skip task review, or accept report missing either verdict (spec compliance AND task quality both required) - Proceed with unfixed issues - Dispatch multiple implementation subagents in parallel — they share one working tree and HEAD, so commits and test runs trample each other, and the review gate is sequential by design (each task reviewed before the next builds on it) - Read all task files into own context (read index only; hand each subagent its task-file path, let it read own task) - Compose any dispatch from memory instead of filling its template — implementer, task reviewer, re-review, fix, final review (or name an `implementer-common.md` that was gisted rather than relocated verbatim) - Drop a template section because it reads like boilerplate (Calibration, Do Not Trust the Report, Evidence Contract, Output Format) — that is what makes verdicts comparable across tasks - Improvise around a template that fits badly instead of editing the template file - Tell any subagent to `sed`/`grep`/`head` a section out of a bigger file (`sed -n '/## Global Constraints/,/^## /p' plan.md | head -200`) — hand whole files; missing file gets created, not carved out - Paste global constraints into a reviewer prompt instead of handing `plan/global-constraints.md` — pasted constraint reaches that one reviewer and no later implementer - Guess which layer constraint files a task needs from its title, or hand all of them "to be safe" — route off plan's written `**Layers:**` annotation; unannotated task = plan bug, not judgment call - Hand reviewer a different constraint file set than implementer got — reviewer then flags rule implementer never saw, or misses one nobody checked - Make subagent read whole plan (hand single task-file path instead) - Skip scene-setting context (subagent needs where task fits) - Ignore subagent questions (answer before they proceed) - Accept "close enough" on spec compliance (reviewer found spec issues = not done) - Skip review loops (reviewer found issues = implementer fixes = review again) - Let implementer self-review replace actual review (both needed) - Tell reviewer what not to flag, or pre-rate finding severity in dispatch prompt ("treat it as Minor at most") — plan's example code = starting point, not evidence its weaknesses were chosen - Dispatch task reviewer without diff file — generate first (`scripts/review-package PLAN_FILE BASE HEAD`), name printed path in prompt - Move to next task while review has open Critical/Important issues - Re-dispatch task progress ledger already marks complete — check ledger (and `git log`) after any compaction or resume - Resolve a plan contradiction verbally without editing the plan files — the next subagent reads the stale text (see Plan Amendments)

**If subagent asks questions:** - Answer clear and complete - Provide extra context if needed - No rushing into implementation

**If reviewer finds issues:** - Implementer (same subagent) fixes - Reviewer reviews again - Repeat until approved - No skipping re-review

**If subagent fails task:** - Dispatch fix subagent with specific instructions - No fixing manually (context pollution)

## Integration

**Required workflow skills:**
- **superpowers:requesting-code-review** Code review template for final whole-branch review
- **superpowers:finishing-a-development-branch** Complete development after all tasks

**Subagents should use: superpowers:test-driven-development** Subagents follow TDD for each task

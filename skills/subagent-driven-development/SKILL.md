# Subagent-Driven Development

Execute plan: fresh implementer subagent per task, task review (spec + quality) after each, broad whole-branch review at end.

**Why subagents:** Delegate tasks to specialized agents with isolated context. Craft instructions + context precisely so they stay focused and succeed. Never inherit session context or history — construct exactly what they need. Also preserves own context for coordination.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

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
    "Answer questions, provide context" [shape=box];
    "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
    "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
    "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
    "Dispatch fix subagent for Critical/Important findings" [shape=box];
    "Mark task complete in todo list and progress ledger" [shape=box];
  }

  "Read plan index only (task list + global constraints), create todos" [shape=box];
  "More tasks remain?" [shape=diamond];
  "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [shape=box];
  "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

  "Read plan index only (task list + global constraints), create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
  "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
  "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
  "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
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

Before Task 1, scan plan index (task list + Global Constraints) for conflicts visible without task bodies:
- task title or Global Constraints contradict each other
- constraint mandates something review rubric treats as defect (test asserting nothing, verbatim duplicated logic block)

No reading every task file upfront — index catches plan-level conflicts; per-task review loop nets conflicts that only emerge from implementation. Need one task's detail → read that one file, not all.

Present findings to human as one batched question — each finding beside plan text mandating it, ask which governs — before execution, not one interrupt per discovery mid-plan. Clean scan → proceed silent.

## Model Selection

Use least powerful model that handles each role. Cheaper, faster.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): fast cheap model. Most implementation tasks mechanical when plan well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): standard model.

**Architecture and design tasks**: most capable model. Final whole-branch review is one — dispatch on most capable model, not session default.

**Review tasks**: same judgment, scaled to diff size, complexity, risk. Small mechanical diff no need most capable model; subtle concurrency change does.

**Always specify model explicitly when dispatching subagent.** Omitted model inherits session model — often most capable, most expensive — silently defeats this section.

**Turn count beats token price.** Wall-clock and context cost scale with subagent turns; cheapest models routinely take 2-3× turns on multi-step work — cost more overall. Mid-tier model = floor for reviewers and implementers working from prose descriptions. Plan text contains complete code to write → implementation is transcription plus testing: cheapest tier for that implementer. Single-file mechanical fixes also cheapest tier.

**Task complexity signals (implementation tasks):** - 1-2 files, complete spec → cheap model - Multi-file, integration concerns → standard model - Design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer reports one of four statuses:

**DONE:** Generate review package (`scripts/review-package PLAN_FILE BASE HEAD`, from this skill's directory — PLAN\_FILE = plan index path, locates feature's `sdd/` workspace; prints unique file path it wrote; BASE = commit recorded before dispatching implementer — never `HEAD~1`, which silently drops all but last commit of multi-commit task), then dispatch task reviewer with printed path.

**DONE\_WITH\_CONCERNS:** Work complete, doubts flagged. Read concerns before proceeding. Correctness or scope concerns → address before review. Observations (e.g., "this file is getting large") → note, proceed to review.

**NEEDS\_CONTEXT:** Missing info. Provide context, re-dispatch.

**BLOCKED:** Cannot complete. Assess blocker: 1. Context problem → more context, re-dispatch same model 2. Needs more reasoning → re-dispatch more capable model 3. Task too large → break into smaller pieces 4. Plan wrong → escalate to human

**Never** ignore escalation or force same model retry without changes. Implementer stuck = something must change.

## Handling Reviewer ⚠️ Items

Task reviewer may report "⚠️ Cannot verify from diff" items — requirements in unchanged code or spanning tasks. Don't block rest of review, but resolve each yourself before marking task complete: you hold plan and cross-task context reviewer lacks. Confirmed real gap = failed spec review — send back to implementer, re-review.

## Constructing Reviewer Prompts

Per-task reviews = task-scoped gates. Broad review happens once, at final whole-branch review. Filling reviewer template:

- No open-ended directives like "check all uses" or "run race tests if useful" without concrete task-specific reason
- No asking reviewer re-run tests implementer already ran on same code — implementer report carries test evidence
- No pre-judging findings — never instruct reviewer to ignore or not flag specific issue. Believe finding would be false positive → let reviewer raise, adjudicate in review loop. Prompt contains "do not flag," "don't treat X as a defect," "at most Minor," or "the plan chose" — stop: pre-judging, usually to dodge review loop.
- Global-constraints block handed to reviewer = its attention lens. Copy binding requirements verbatim from plan's Global Constraints or spec: exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). Reviewer template already carries process rules (YAGNI, test hygiene, review method) — constraints block for what THIS project's spec demands.
- Hand reviewer diff as file: run this skill's `scripts/review-package PLAN_FILE BASE HEAD`, pass reviewer printed file path (or, without bash: `git log --oneline`, `git diff --stat`, and `git diff -U10` for range, redirected to one uniquely named file). Output never enters own context; reviewer sees commit list, stat summary, full diff with context in one Read call. Use BASE recorded before dispatching implementer — never `HEAD~1`, silently truncates multi-commit tasks.
- Dispatch prompt describes one task, not session history. No pasting accumulated prior-task summaries ("state after Tasks 1-3") into later dispatches — real session dispatch hit 42k chars, 99% pasted history. Fresh subagent needs: its task, interfaces it touches, global constraints. Nothing else.
- Dispatch fix subagents for Critical and Important findings. Record Minor findings in progress ledger as you go; point final whole-branch review at that list to triage which must fix before merge. Roll-up nobody reads = silent discard.
- Finding labeled plan-mandated — or any finding conflicting with plan text — is human's decision, like any plan contradiction: present finding + plan text, ask which governs. No dismissing finding because plan mandates it; no dispatching fix that contradicts plan without asking.
- Final whole-branch review gets package too: run `scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE\_BASE = commit branch started from, e.g. `git merge-base main HEAD`), include printed path in final review dispatch — final reviewer reads one file, no re-deriving branch diff with git.
- Every fix dispatch carries implementer contract: fix subagent re-runs tests covering its change, reports results. Name covering test files in dispatch — one-line fix no need whole suite. Before re-dispatching reviewer, confirm fix report contains covering tests, command run, output; dispatch re-review once all three present.
- Final whole-branch review returns findings → dispatch ONE fix subagent with complete findings list — not one fixer per finding. Per-finding fixers each rebuild context, re-run suites; real session's final-review fix wave cost more than all its tasks combined.

## File Handoffs

Everything pasted into dispatch prompt — and everything subagent prints back — stays resident in context rest of session, re-read every later turn. Hand artifacts as files:

- **Task brief:** plan's task file (`plan/tasks/task.NN.md`) *is* brief — self-contained, no extract or copy. No reading task body into own context; hand path to implementer, subagent reads. Dispatch contains:
  (1) one line where task fits in project; (2) task-file path, introduced as "read this first --- it is your requirements, with the exact values to use verbatim"; (3) interfaces and decisions from earlier tasks task file cannot know; (4) your resolution of any ambiguity (if you had to open file); (5) report-file path and report contract. Exact values (numbers, magic strings, signatures, test cases) live in task file.
- **Report file:** name implementer's report file after task file (task `…/plan/tasks/task.0N.md` → report `…/sdd/task-N-report.md`), put in dispatch prompt. Implementer writes full report there, returns only status, commits, one-line test summary, concerns.
- **Reviewer inputs:** task reviewer gets three paths — same task file, report file, review package — plus global constraints binding task.
- Fix dispatches append fix report (with test results) to same report file, return short summary; re-reviews read updated file.

## Durable Progress

Conversation memory no survive compaction. Real sessions: controllers that lost place re-dispatched entire completed task sequences — single most expensive failure observed. Track progress in ledger file, not only todos.

- Ledger lives in run's workspace — `progress.md` inside directory `scripts/sdd-workspace PLAN_FILE` prints (PLAN\_FILE = plan index path). Directory = `sdd/` sibling of plan's folder: `$HOME/.superpowers/YYYY/<feature-name>/sdd/`, outside repo — shared across git worktrees, survives `git clean`.
- At skill start, check for ledger: `cat "$(scripts/sdd-workspace PLAN_FILE)/progress.md"`. Tasks marked complete there = DONE — no re-dispatch; resume at first task not marked complete.
- Task review comes back clean → append one ledger line in same message as other bookkeeping: `Task N: complete (commits <base7>..<head7>, review clean)`.
- Ledger = recovery map: commits it names exist in git even when context no longer remembers creating them. After compaction, trust ledger and `git log` over own recollection.

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)

## Example Workflow

  You: I'm using Subagent-Driven Development to execute this plan.

  [Read plan index only: /home/hermes/.superpowers/2026/feature/plan/plan.md]
  [Create todos from the index task list]

  Task 1: Hook installation script

  [Dispatch implementer with the task-file path (…/plan/tasks/task.00.md) + report path + context]

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

  [Dispatch implementer with the task-file path (…/plan/tasks/task.01.md) + report path + context]

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

**Never:** - Start implementation on main/master branch without explicit user consent - Skip task review, or accept report missing either verdict (spec compliance AND task quality both required) - Proceed with unfixed issues - Dispatch multiple implementation subagents in parallel (conflicts) - Read all task files into own context (read index only; hand each subagent its task-file path, let it read own task) - Make subagent read whole plan (hand single task-file path instead) - Skip scene-setting context (subagent needs where task fits) - Ignore subagent questions (answer before they proceed) - Accept "close enough" on spec compliance (reviewer found spec issues = not done) - Skip review loops (reviewer found issues = implementer fixes = review again) - Let implementer self-review replace actual review (both needed) - Tell reviewer what not to flag, or pre-rate finding severity in dispatch prompt ("treat it as Minor at most") — plan's example code = starting point, not evidence its weaknesses were chosen - Dispatch task reviewer without diff file — generate first (`scripts/review-package PLAN_FILE BASE HEAD`), name printed path in prompt - Move to next task while review has open Critical/Important issues - Re-dispatch task progress ledger already marks complete — check ledger (and `git log`) after any compaction or resume

**If subagent asks questions:** - Answer clear and complete - Provide extra context if needed - No rushing into implementation

**If reviewer finds issues:** - Implementer (same subagent) fixes - Reviewer reviews again - Repeat until approved - No skipping re-review

**If subagent fails task:** - Dispatch fix subagent with specific instructions - No fixing manually (context pollution)

## Integration

**Required workflow skills:**
- **superpowers:requesting-code-review** Code review template for final whole-branch review
- **superpowers:finishing-a-development-branch** Complete development after all tasks

**Subagents should use: superpowers:test-driven-development** Subagents follow TDD for each task
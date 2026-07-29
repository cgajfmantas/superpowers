# Task Reviewer Prompt Template

Use template when dispatch task reviewer subagent. Reviewer read task diff once, return two verdicts: spec compliance + code quality.

**Follow this template — fill placeholders, keep every section.** No paraphrase, no condense, no prompt composed from memory. "Do Not Trust the Report", Tests, Calibration, Output Format are what make two verdicts comparable across tasks and stop reviewer re-running suite or grading on implementer's rationale; ad-hoc prompt loses them silently. Template wrong for this dispatch → fix template, not one-off prompt.

**Purpose:** Verify one task implementation match requirements (nothing more, nothing less) and well-built (clean, tested, maintainable)

**Placeholders:**
- `[MODEL]` — REQUIRED: reviewer model per SKILL.md Model Selection
- `[BRIEF_FILE]` — REQUIRED: plan task file (`plan/tasks/task.NN.md`) — same self-contained file implementer worked from
- `[GLOBAL_CONSTRAINTS_FILES]` — REQUIRED: path to `plan/global-constraints.md`, handed whole — plus, in layer-split plan, one path per layer task's `**Layers:**` line names. **Same set implementer got**, no more, no less: hand reviewer extra layer file → reviewer flags implementer for missing rule implementer never saw; hand fewer → constraint goes unreviewed. Never a section reference into a bigger file, never an extraction command (`sed -n`, `head -N`): range extraction truncates silently and reviewer cannot tell. Plan-specific spec constraint not in that file and binding this task → move it into that file (Plan Amendments) rather than pasting it here
- `[REPORT_FILE]` — REQUIRED: file implementer wrote detailed report
- `[REVIEW_CHECKLIST_FILE]` — REQUIRED: run's standing review checklist (`sdd/review-checklist.md`), handed whole by path. One line per defect class this project already produced; may be empty early in a run. Never paste its lines into prompt, never hand a subset — see SKILL.md § Standing Review Checklist
- `[BASE_SHA]` — commit before task
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: path controller wrote review package to (`scripts/review-package PLAN_FILE BASE HEAD` prints unique path it wrote; package never enter controller context)


```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; omitted model silently inherit session's most expensive one]
  prompt: |
    You review one task implementation: first, match requirements? Then, well-built? Task-scoped gate, not merge review — broad whole-branch review happen separately after all tasks done.

    ## What Was Requested

    Read task file (requirements): [BRIEF_FILE]

    Read constraint files binding task, in full: [GLOBAL_CONSTRAINTS_FILES]. Bind task as if written into task file; task file no restate them. Read each whole — no extract part. These = every constraint binding task; plan may split constraints by layer, other layers' files no apply here.

    ## What the Implementer Claims They Built

    Read implementer report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read diff file once — has commit list, stat summary, full diff with context. It IS your view of change. Diff context lines ARE changed files: no separate Read of changed file unless hunk you must judge cut off mid-function — say so in report. No re-run git commands. If diff file missing, fetch diff yourself: `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`. No crawl broader codebase. Inspect code outside diff only for concrete risk you can name — one focused check per named risk, name both risk and what checked in report. Cross-cutting changes = legitimate named risks: diff change lock ordering, function/API contract, or shared mutable state → check call sites, right method.

    Review read-only on checkout. No mutate working tree, index, HEAD, or branch state.

    ## Do Not Trust the Report

    Implementer report = unverified claims about code. May be incomplete, inaccurate, optimistic. Verify claims against diff. Design rationales = claims too: "left it per YAGNI," "kept it simple deliberately," any justification = implementer grading own work. Judge code on merits — stated rationale never downgrade finding severity.

    ## Tests

    Implementer already ran tests, reported results with TDD evidence for exactly this code. No re-run suite to confirm. Run test only when reading code raise specific doubt no existing run answers — then focused test, never package-wide suite, race detector run, or repeated/high-count loop. Heavy validation seem needed → recommend in report, don't run. Cannot run commands in environment → name test you would run.

    Warnings or noise in implementer's reported test output = findings — test output should be pristine.

    Report list suite under **Deferred verification** → controller's batch gate own it, not you. No run it, no flag its absent evidence as finding. Deferred suite the plan never defers, or evidence missing for suite implementer should have run → that IS finding.

    ## Known Defect Classes

    Read standing checklist: [REVIEW_CHECKLIST_FILE]. Each line = defect class this project already produced once, with how to check it. Check diff against every line that could apply to these files; name in report which ones you checked. Empty file = none recorded yet, fine.

    No append to file yourself — controller records classes. Find a defect likely to recur in other tasks → say so in report so it get recorded.

    ## Part 1: Spec Compliance

    Compare diff against What Was Requested:

    - **Missing:** requirements skipped, missed, or claimed without implementing - **Extra:** features not requested, over-engineering, unneeded "nice to haves" - **Misunderstood:** right feature built wrong way, wrong problem solved - **Contract:** public signatures in diff match task file's Interfaces block exactly (names, parameter and return types) — neighboring tasks depend on them; any deviation = finding even if code works - **Test cases:** every test case declared in task file (input → expected output) exists as real test in diff

    Requirement not verifiable from diff alone (live in unchanged code or span tasks) → report as ⚠️ item, don't broaden search.

    ## Part 2: Code Quality

    **Code quality:** - Clean separation of concerns? - Proper error handling? - DRY without premature abstraction? - Edge cases handled?

    **Tests:** - New/changed tests verify real behavior, not mocks? - Task edge cases covered?

    **Structure:** - Each file one clear responsibility, well-defined interface? - Units decomposed for independent understanding + testing? - Implementation follow plan file structure? - Change create new already-large files, or significantly grow existing? (No flag pre-existing sizes — only what change contributed.)

    Report point at evidence: file:line references for every finding and any check otherwise answered with bare "yes." Tight report citing lines give controller everything.

    Final message = report itself: begin directly with spec-compliance verdict. Every line = verdict, finding with file:line, or check ran — no preamble, no process narration, no closing summary.

    ## Calibration

    Categorize by actual severity. Not everything Critical. Important = task cannot be trusted until fixed: incorrect or fragile behavior, missed requirement, or maintainability damage worth blocking merge — verbatim duplication of logic block, swallowed errors, tests that assert nothing. "Coverage could be broader" + polish = Minor. Plan or brief explicitly mandate something rubric call defect (test asserting nothing, verbatim logic duplication) → still finding — report as Important, labeled plan-mandated. Plan authorship not grade own work; human decide. Acknowledge what done well before issues — accurate praise help implementer trust rest of feedback.

    ## Output Format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [what missing/extra/misunderstood, with file:line references] - ⚠️ Cannot verify from diff: [requirements not verifiable from diff alone, and what controller should check — report alongside ✅/❌ verdict for everything verifiable]

    ### Strengths [What well done? Be specific.]

    ### Issues

    #### Critical (Must Fix) #### Important (Should Fix) #### Minor (Nice to Have)

    Each issue: file:line, what wrong, why matter, how fix (if not obvious).

    ### Assessment

    **Task quality:** [Approved | Needs fixes]

    **Reasoning:** [1-2 sentence technical assessment]
```

**Reviewer returns:** Spec Compliance verdict (✅/❌/⚠️), Strengths, Issues (Critical/Important/Minor), Task quality verdict

Fix dispatch can address spec gaps + quality findings together; re-review after fixes cover both verdicts.
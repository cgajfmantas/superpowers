---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
user-invocable: true
disable-model-invocation: true
---

# Writing Plans

## Overview

Write full implementation plans from spec file. Assume engineer has zero codebase context, questionable taste. Document everything: files to touch per task, code, testing, docs to check, how to test. Bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume skilled developer, but knows almost nothing about toolset or problem domain. Assume weak test design knowledge.

User provides spec file [SPEC_FILE_PATH] = $0.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

## PLAN_FILE_PATH

`/home/hermes/.superpowers/YYYY/<feature-name>/plan/plan.md`

**Save the plan index to:** [PLAN_FILE_PATH]

Plan lives in `plan/` subfolder of feature directory (`/home/hermes/.superpowers/YYYY/<feature-name>/`), beside `spec/` from brainstorming skill and `sdd/` execution artifacts.

Plan split across files so no single file grows unwieldy:

- **[PLAN_FILE_PATH]** (`plan/plan.md`) is *index*. Holds plan header, Global Constraints, File Structure, ordered links to task files. **No** task bodies.
- **Each task in own file** under `plan/tasks/` (see Task Structure for naming, layout).

Index lists task files in execution order under `## Tasks` heading (see Plan Index Header).

## Scope Check

If spec [SPEC_FILE_PATH] covers multiple independent subsystems, should have been broken into sub-project specs during brainstorming. If not, suggest separate plans — one per subsystem. Each plan must produce working, testable software alone.

## File Structure

Before defining tasks, map files created/modified and each one's responsibility. Decomposition decisions lock in here.

- Design units with clear boundaries, well-defined interfaces. One clear responsibility per file.
- You reason best about code held in context at once; edits more reliable on focused files. Prefer smaller focused files over large ones.
- Files that change together live together. Split by responsibility, not technical layer.
- Existing codebases: follow established patterns. Codebase uses large files — don't unilaterally restructure. But if file you modify grew unwieldy, split in plan reasonable.

Structure informs task decomposition. Each task produces self-contained changes that make sense independently.

## Task Right-Sizing

Task = smallest unit with own test cycle, worth fresh reviewer's gate. Drawing boundaries: fold setup, configuration, scaffolding, docs into task whose deliverable needs them; split only where reviewer could reject one task, approve neighbor. Each task ends with independently testable deliverable.

## Bite-Sized Task Granularity

**Each step one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Index Header

**Index file [PLAN_FILE_PATH] MUST start with this header, then ordered task list:**

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits, naming and copy rules, platform requirements — one line each, with exact values copied verbatim from the spec. Every task's requirements implicitly include this section.]

## Tasks

1. [Task 0: ...](./tasks/task.00.md)
2. [Task 1: ...](./tasks/task.01.md)

---
```

## Task Structure

**Each task saved to own file** in `plan/tasks/` beside index, named `task.NN.md` (`NN` = zero-padded task number matching index list: `00`, `01`, `02`, ...). One task block per file. Index (`plan/plan.md`) links files in execution order (`./tasks/task.NN.md`), holds no task bodies.

Task file reader has zero context, may read out of order — **each task file must be self-contained**. Restate any Global Constraint, code, type, signature it depends on; no pointing at other files.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

Issues found: fix inline. No re-review — fix, move on. Spec requirement with no task: add task.

**User Review Gate:**
After plan review loop passes, ask user to review written plan before proceeding:

> "Plan written and committed to [PLAN_FILE_PATH]. Review it and let me know if you want to make any changes."

Wait for user response. Changes requested: make them, re-run plan review loop. Proceed only after user approves.
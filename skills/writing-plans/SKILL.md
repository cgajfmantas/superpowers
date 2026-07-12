---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans from a spec file assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

User provides the spec file [SPEC_FILE_PATH] = $0.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

## PLAN_FILE_PATH

`/home/hermes/.superpowers/YYYY/<feature-name>/plan/<feature-name>.plan.md`

**Save the plan index to:** [PLAN_FILE_PATH]

The plan lives in the `plan/` subfolder of the feature's directory
(`/home/hermes/.superpowers/YYYY/<feature-name>/`), beside the `spec/` the
brainstorming skill wrote and the `sdd/` execution artifacts land in.

A plan is split across files so no single file grows unwieldy:

- **[PLAN_FILE_PATH]** is the *index*. It holds the plan header, Global Constraints, File Structure, and an ordered list of links to the task files. It does **not** contain task bodies.
- **Each task lives in its own file** in the same `plan/` folder (see Task Structure for naming and layout).

The index lists the task files in execution order under a `## Tasks` heading (see Plan Index Header).

## Scope Check

If the spec [SPEC_FILE_PATH] covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. When drawing task boundaries: fold setup, configuration, scaffolding, and documentation steps into the task whose deliverable needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Index Header

**The index file [PLAN_FILE_PATH] MUST start with this header, followed by
the ordered task list:**

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits, naming and copy rules, platform requirements — one line each, with exact values copied verbatim from the spec. Every task's requirements implicitly include this section.]

## Tasks

1. [Task 0: ...](./<feature-name>.plan.task.00.md)
2. [Task 1: ...](./<feature-name>.plan.task.01.md)

---
```

## Task Structure

**Each task is saved to its own file** in the same `plan/` folder as the index, named `<feature-name>.plan.task.NN.md` (`NN` = zero-padded task number matching the index list: `00`, `01`, `02`, ...). One task block per file. The index ([PLAN_FILE_PATH]) links these files in execution order and holds no task bodies.

A task file's reader has zero context and may read tasks out of order, so **each task file must be self-contained** — restate any Global Constraint, code, type, or signature it depends on rather than pointing at another file.

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

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

**User Review Gate:**
After the plan review loop passes, ask the user to review the written plan before proceeding:

> "Plan written and committed to [PLAN_FILE_PATH]. Review it and let me know if you want to make any changes."

Wait for the user's response. If they request changes, make them and re-run the plan review loop. Only proceed once the user approves.
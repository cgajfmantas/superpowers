---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
user-invocable: true
disable-model-invocation: true
---

# Writing Plans

## Overview

Write full implementation plans from spec file. Assume engineer has zero codebase context, questionable taste. Document everything: files to touch per task, exact interfaces, behavior, test cases as data, docs to check, how to test. The plan specifies WHAT and the contract; the implementer writes the code via real TDD. Bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume skilled developer, but knows almost nothing about toolset or problem domain. Assume weak test design knowledge.

User provides spec file [SPEC_FILE_PATH] = $0.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

## PLAN_FILE_PATH

`/home/hermes/.superpowers/YYYY/<feature-name>/plan/plan.md`

`YYYY` = current year (e.g. `2026`) — never create a literal `YYYY` directory.

**Save the plan index to:** [PLAN_FILE_PATH]

Plan lives in `plan/` subfolder of feature directory (`/home/hermes/.superpowers/YYYY/<feature-name>/`), beside `spec/` from brainstorming skill and `sdd/` execution artifacts.

Plan split across files so no single file grows unwieldy:

- **[PLAN_FILE_PATH]** (`plan/plan.md`) is *index*. Holds plan header, File Structure, link to Global Constraints, ordered links to task files. **No** task bodies, **no** Global Constraints body.
- **Global Constraints in own file** at `plan/global-constraints.md` (see Global Constraints).
- **Each task in own file** under `plan/tasks/` (see Task Structure for naming, layout).

Every artifact a downstream subagent must read is a **whole file it can Read**. Never leave a binding block buried in a bigger file, so nobody has to `sed`/`grep`/`head` a section out of it — truncated or mis-bounded extraction silently drops requirements.

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

**Global Constraints:** [./global-constraints.md](./global-constraints.md) — binds every task

[If split by layer, list each layer file here too:]
**Layer constraints:** [frontend](./global-constraints.frontend.md) · [backend](./global-constraints.backend.md)

## Tasks

[Plain form — no layer split:]
1. [Task 1: ...](./tasks/task.01.md)
2. [Task 2: ...](./tasks/task.02.md)

[Split form — every task annotated with the layers binding it:]
1. [Task 1: ...](./tasks/task.01.md) — layers: frontend
2. [Task 2: ...](./tasks/task.02.md) — layers: backend, database

---
```

## Global Constraints

**Saved to own file:** `plan/global-constraints.md`, beside index. Index links it; index holds no copy.

Own file because every downstream dispatch — implementer, task reviewer, final reviewer — hands it as a path. A section inside `plan.md` cannot be handed as a path, and a controller that tries ends up telling the subagent to `sed`/`head` it out of the index, which truncates.

```markdown
# [Feature Name] — Global Constraints

Binds every task in this plan. Task files do not restate these.

- [One line per project-wide requirement: version floors, dependency limits,
  naming and copy rules, platform requirements, shared exact values — copied
  verbatim from the spec.]
```

Keep it short enough to read whole: only what binds many tasks. Task-specific values live in the task file.

### Splitting by Layer

One file is the default. Split when the plan spans layers with **disjoint toolchains** (frontend / backend / database / infra) *and* the single file has grown past a screenful, so a frontend implementer would read mostly rules that cannot apply to it. Below that, splitting costs more than it saves: four files of five lines each buy nothing and add a routing decision that can go wrong.

When splitting:

- `plan/global-constraints.md` stays, and **every task still reads it**. It holds only what is genuinely cross-cutting — commit conventions, branch rules, language-version floors shared by all layers, shared copy and naming rules.
- Each layer gets `plan/global-constraints.<layer>.md` — one lowercase layer word, matching the annotations in the index task list.
- **A constraint binding two or more layers lives in the base file, once.** Never copy it into several layer files: duplicated constraints drift, and the drift procedure below only catches what you remember to grep.
- Layer names are fixed by the plan, not invented per task. List them in the index header.

**Routing is decided when the plan is written, not at dispatch time.** The index task list annotates each task with its layers, and the task file repeats them (see Task Structure). A controller composing a dispatch reads the annotation — it never infers which layers a task touches from the task's title. A misrouted task is the failure this whole file split exists to prevent: the constraint reaches nobody, and no reviewer sees it either.

A task that legitimately spans layers gets all of them, and reads all of those files. If most tasks span most layers, the layers are not disjoint — go back to one file.

## Task Structure

**Each task saved to own file** in `plan/tasks/` beside index, named `task.NN.md` (`NN` = zero-padded task number matching index list: `01`, `02`, `03`, ...). One task block per file. Index (`plan/plan.md`) links files in execution order (`./tasks/task.NN.md`), holds no task bodies.

Task file reader has zero context, may read out of order — **each task file must be self-contained**. Restate any type, signature, or value it depends on; no pointing at other task files.

Two exceptions, both handed to the reader as separate whole files by the dispatching controller: the constraint files and the task's own file. So a task file does **not** restate Global Constraints — one copy, one file, read alongside. Anything else it needs, it states.

**When constraints are split by layer** (see Splitting by Layer), each task file names its layers on the line after the heading, matching the index annotation:

```markdown
### Task N: [Component Name]

**Layers:** frontend
```

That line is what the controller routes on. A task with no layer line in a split plan is a plan bug — the implementer gets the base file only and silently misses its layer's rules.

**Duplication across task files is deliberate; its cost is drift.** When a signature or constraint changes — during plan writing OR execution — grep the old symbol across the whole `plan/` directory, update every occurrence, verify zero leftovers. Values shared by many tasks belong in `global-constraints.md` (one copy); restate only what is task-specific.

**The plan specifies behavior and contracts, not implementation code.** Interfaces block carries exact signatures — that is what connects tasks. Behavior and Test Cases carry what the code must do, with test cases as data (input → expected output). The implementer writes the actual test and implementation code via real TDD: the failing test fails for a real reason, not one the planner guessed.

````markdown
### Task N: [Component Name]

**Layers:** [only in a layer-split plan — the layers whose constraint files bind this task, matching the index annotation]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

```python
def parse_config(path: str) -> Config:  # exact signature — normative contract
```

**Behavior:**
[What the unit does: inputs, outputs, side effects, error handling.
Enumerate edge cases explicitly — empty input, missing file, invalid
format. Exact values (magic numbers, strings, formats) verbatim.]

**Test cases (data, not code — implementer turns each into a real test):**

| Input | Expected |
|-------|----------|
| `parse_config("valid.toml")` | `Config(port=8080, host="localhost")` |
| `parse_config("missing.toml")` | raises `FileNotFoundError` |
| `parse_config("empty.toml")` | raises `ConfigError("empty config")` |

- [ ] **Step 1: Write the failing test for the first test case**

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL (e.g. "function not defined") — confirm it fails for the right reason

- [ ] **Step 3: Write minimal implementation satisfying Interfaces + Behavior**

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Repeat Steps 1-4 for each remaining test case**

- [ ] **Step 6: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every task must contain the actual contract an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases" (enumerate the cases and expected outcomes)
- "Write tests for the above" (without concrete test cases as data)
- A test case without a concrete input and expected output
- Behavior described without its edge cases enumerated
- "Similar to Task N" (restate the contract — the engineer may be reading tasks out of order)
- Interfaces without exact signatures (names, parameter and return types)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete behavior spec in every task: exact signatures, exact test cases as data, exact values
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the signatures in each task's Interfaces block match across tasks? A function called `clearLayers()` in Task 3's Produces but `clearFullLayers()` in Task 7's Consumes is a bug.

Issues found: fix inline. No re-review — fix, move on. Spec requirement with no task: add task.

## Plan Review (subagent)

After self-review passes, before the User Review Gate: dispatch one fresh reviewer subagent with [plan-document-reviewer-prompt.md](plan-document-reviewer-prompt.md) **filled in** — placeholders substituted, every section kept, nothing written from memory — passing the spec path and plan index path. Fresh eyes catch what the author cannot — this is the only review of the plan by someone who didn't write it.

Reviewer returns Status + Issues with file references. Issues found: fix them, re-dispatch. Approved: proceed to user review.

**User Review Gate:**
After plan review loop passes, ask user to review written plan before proceeding:

> "Plan written and committed to [PLAN_FILE_PATH]. Review it and let me know if you want to make any changes."

Wait for user response. Changes requested: make them, re-run plan review loop. Proceed only after user approves.
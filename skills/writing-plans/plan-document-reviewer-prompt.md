# Plan Document Reviewer Prompt Template

Use template when dispatch plan document reviewer subagent.

**Purpose:** Verify plan complete, match spec, task decomposition proper.

**Dispatch after:** Complete plan written — index plus every task file.

**Placeholders:**
- `[MODEL]` — REQUIRED: mid-tier model suffices (document review, no code execution); an omitted model silently inherits the session's most expensive one
- `[PLAN_FILE_PATH]` — plan index (`plan/plan.md`)
- `[SPEC_FILE_PATH]` — spec the plan implements

```
Subagent (general-purpose):
  description: "Review plan document"
  model: [MODEL]
  prompt: |
    You are a plan document reviewer. Verify this plan is complete and ready for implementation.

    **Plan index to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    The plan is split across files: the index holds the header, Global Constraints, and an ordered task list; each task lives in its own file under `plan/tasks/` beside the index. Read the spec, the index, and EVERY task file — approving from the index alone is not a review.

    Your review is read-only: report issues, never edit the plan or any other file. Review the documents themselves — do not crawl the codebase; each task file must stand on its own for an implementer with zero context.

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Spec Coverage | Every spec requirement maps to a task; list gaps. No major scope creep |
    | Placeholders | "TBD", "TODO", "handle edge cases", "similar to Task N", test cases without concrete input and expected output, behavior without edge cases enumerated |
    | Interface Consistency | Signatures in Produces/Consumes blocks match across tasks — exact names, parameter and return types |
    | Contract Completeness | Each task has exact signatures in Interfaces, Behavior with edge cases, test cases as data (input → expected output) an implementer can turn into real tests |
    | Self-Containment | Could a reader with zero context execute each task file alone? Name what's missing |
    | Task Decomposition | Tasks have clear boundaries, steps are actionable |

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    An implementer building the wrong thing or getting stuck is an issue.
    Minor wording, stylistic preferences, and "nice to have" suggestions are not.

    Approve unless there are serious gaps — missing requirements from the spec, contradictory or mismatched signatures, placeholder content, or tasks so vague they can't be acted on.

    ## Output Format

    Your final message is the report itself: begin directly with the status. No preamble, no process narration, no closing summary.

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [tasks/task.NN.md, section/step]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations

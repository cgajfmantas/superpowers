---
name: improving-skills-from-sessions
description: Use when deciding whether this project's skills actually work in practice, when a plan or spec produced rework, when a run behaved worse than its skills prescribe, or when you need a real baseline of an agent failing before writing or editing a skill
---

# Improving Skills From Sessions

## Overview

A skill's prose says what should happen. A session transcript is the only evidence of what it actually caused.

**Core principle: change skills from transcript evidence, not from reasoning about them.** Every edit names the session, the turns, and the observation that motivated it.

Two phases, and the split is load-bearing:

| | Phase 1 — Audit | Phase 2 — Improve |
|---|---|---|
| Reads | transcripts | **the report only** |
| Produces | one report file | skill edits |
| Says nothing about | what to change | what else the transcripts held |
| Judgment needed | little; mostly mechanical | all of it |

The report is a compression boundary. Phase 1 reads hundreds of thousands of tokens of transcript; Phase 2 reads one file. That is the File Handoffs principle `superpowers:subagent-driven-development` teaches, applied to this skill — and it means Phase 2 can start in a fresh context, which is the point.

**REQUIRED SUB-SKILL:** Phase 2 goes through `superpowers:writing-skills`. Its Iron Law applies: no skill edit without a failing test first, and a real session is the strongest failing test there is.

## Phase 1 — Audit

**Report template:** [session-report-template.md](session-report-template.md), filled. Not a paraphrase, not one composed from memory.

1. **Date the session and pin the revisions.** Which skill revisions were in force during the span. Do this first; every later step is read against it.
2. **Run the sensors** with the scripts below, pasting output verbatim. What each stage of the pipeline leaks into a transcript is catalogued in [reading-transcripts.md](reading-transcripts.md) § Sensors by pipeline stage.
3. **Write findings** — each with stage, location, evidence, the guidance in force, and a classification.
4. **Stop.** Do not propose fixes. A report that carries its own conclusions gets rubber-stamped in Phase 2 rather than judged.

### Establish which version ran, before anything else

A session ran against the skills as they were *then*. Read a finding against today's skills and every diagnosis inverts.

```bash
head -1 <session>.jsonl | python3 -c 'import json,sys; print(json.load(sys.stdin)["timestamp"])'
git log --until=<that date> -1 --format='%h %ad' -- skills/<skill>/SKILL.md
```

Concretely: on the run this skill was built from, 73 of 75 agents never dispatched a subagent — which reads as guidance being ignored until you notice the advice landed three days *after* the run began. Same measurement, opposite conclusion. A long run may span several revisions; treat each stretch separately or the evidence is a blend.

### Scripts

| Command | Answers |
|---|---|
| `scripts/session-signals statuses RUN` | how each dispatch ended, rework and review rounds per task |
| `scripts/session-signals reads RUN` | files read more than once, with sizes |
| `scripts/session-signals tools RUN [PATTERN]` | tool-call census; with a pattern, which agents never called it |
| `scripts/session-signals gaps RUN` | idle re-cache turns and the gap before each |
| `scripts/session-signals context RUN` | context growth per agent |
| `scripts/run-cost RUN` | what each agent cost. The only place with prices |

`RUN` is either half of the session pair — `<session-id>.jsonl` or `<session-id>/`. Claude Code stores the controller transcript beside the subagents directory, not inside it, so globbing the directory silently omits the controller.

See [reading-transcripts.md](reading-transcripts.md) for the counting rules these depend on and the mistakes that produced them.

## Phase 2 — Improve

**Work from the report. Do not reopen the transcripts.** Reopening them defeats the boundary, restores the context Phase 1 spent, and reintroduces the temptation to justify a conclusion with evidence the report did not record. Report incomplete → send it back to Phase 1, or re-run a sensor and amend the report; don't work around it.

For each finding, its classification already decided the move:

| Classification | Phase 2 does |
|---|---|
| **gap** | Add guidance; match its form to the failure per `writing-skills` |
| **rationalization** | Bulletproof — rationalization table, red flags, close the loophole |
| **factual-error** | Correct or delete the claim, and name its source |
| **decoration** | Delete the guidance |
| **baseline-predates-guidance** | Nothing to fix. Keep the finding as the RED baseline for the guidance that followed, and check its form is strong enough for a behaviour that universal |

**Factual errors are invisible to evals.** A verifier grades whether the agent followed the skill, not whether the skill is true, so a skill can be internally coherent, pass every scenario, and still assert a mechanism the tool's own documentation contradicts. For any claim about harness behaviour, tool semantics, or pricing: name the source. Unsourced → delete or soften.

Finish by recording, in the report, which findings became edits and which were declined. A declined finding with a reason is worth as much as an edit — it stops the next audit re-raising it.

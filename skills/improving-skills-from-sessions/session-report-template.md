# Session Audit Report Template

**This template is the report.** Fill the placeholders, keep every section, keep them in this order. Do not paraphrase it, summarise it, or compose a report of your own from memory: the revision block, the per-finding evidence fields, and the no-fixes rule below are what make a finding actionable in Phase 2. A report missing them sends Phase 2 back to the transcripts, which is the one thing the two-phase split exists to prevent.

**Placeholders:**
- `[SESSION_ID]` — REQUIRED: the session whose transcripts were read
- `[PROJECT_DIR]` — REQUIRED: `~/.claude/projects/<slug>/`
- `[FIRST_TS]` / `[LAST_TS]` — REQUIRED: first and last request timestamps
- `[REVISIONS]` — REQUIRED: one row per skill the session exercised (see below)
- `[FINDINGS]` — one block per finding, in the shape given

**Where it goes:** `$HOME/.superpowers/<YYYY>/session-audits/[SESSION_ID].md` (`<YYYY>` = current year, never the literal). Outside any repo, so it survives `git clean` and is readable from another worktree.

**The rule that makes this worth writing: no proposed fixes.** Phase 1 records what happened and classifies it. It does not say what to change. A report that proposes fixes gets rubber-stamped in Phase 2 instead of judged, and the evidence stops being independent of the conclusion. If a fix seems obvious while writing, that is a Phase 2 finding — leave it out.

---

```markdown
# Session Audit — [SESSION_ID]

**Transcripts:** [PROJECT_DIR]
**Span:** [FIRST_TS] → [LAST_TS]
**State:** finished | **still live** (newest transcript written [TIME]; totals will move)

## Skill Revisions In Force

The session ran against the skills as they were then. Every finding below is
read against these revisions, not against today's files.

| Skill | Revision current during the span | Notes |
|---|---|---|
| [skill name] | [short SHA, date] | [e.g. "changed mid-run at <date>; findings before/after are separate"] |

Derived with `git log --until=<span date> -1 -- skills/<skill>/SKILL.md`.
Any skill the session exercised and this table omits is a gap in the audit.

## Shape

| Role | Agents | Requests | Notes |
|---|---|---|---|
| controller | | | |
| implementer | | | |
| reviewer | | | |
| fixer | | | |
| other | | | |

Tasks attempted: [N]. Plan: [path, or "none — not a plan-driven run"].

## Sensor Output

Verbatim, with the command that produced each. No interpretation in this
section — interpretation belongs to the findings.

### Statuses and rework
```
[session-signals statuses output]
```

### Repeated reads
```
[session-signals reads output]
```

### Tool census and absences
```
[session-signals tools output, plus any PATTERN checks run]
```

### Idle re-cache and gaps
```
[session-signals gaps output]
```

### Context growth
```
[session-signals context output]
```

### Cost
```
[run-cost output]
```

## Findings

One block each. A finding with no `Where` is an impression, not a finding.

### F1 — [one line: what happened]

- **Stage:** spec | planner | implementer | reviewer | controller
- **Where:** [agent label, and timestamp or turn range]
- **Evidence:** [the numbers or quoted output; name the sensor]
- **Guidance in force:** [the section of the skill revision that covered this,
  quoted — or "none: the revision was silent here"]
- **Classification:** gap | rationalization | factual-error | decoration |
  baseline-predates-guidance
- **Confidence:** measured | inferred | single-observation

Repeat for each finding. Order by stage, not by size.

## Not Findings

Things checked and found clean, or ruled out. Cheap to write and it stops the
next audit re-deriving them.

## Open Questions

Things the transcripts cannot answer — what would have to be measured elsewhere.
```

---

## Filling the classification field

The five values are not interchangeable and they decide what Phase 2 does:

- **gap** — the revision in force was silent. Phase 2 may add guidance.
- **rationalization** — the revision said it clearly and the agent did it anyway. Phase 2 bulletproofs.
- **factual-error** — the revision asserted something untrue about the harness, a tool, or pricing. Phase 2 corrects and sources it. Evals never catch these.
- **decoration** — guidance present for the whole span and never exercised. Phase 2 deletes.
- **baseline-predates-guidance** — the behaviour is real but the guidance did not exist yet. **Not a verdict on the guidance.** It is RED-phase evidence: it says the behaviour is what the guidance must overcome, and how strong it is.

The last one is the easy mistake. Absence of a mandated behaviour in a run that predates the mandate looks identical to the mandate being ignored, and reads as `decoration` unless you checked the dates. If the revision table is missing, every classification here is unsafe.

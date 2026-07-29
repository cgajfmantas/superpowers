# Reading Transcripts — signals, and mistakes to avoid

Reference for the measurement half of `improving-skills-from-sessions`. Read it while analysing, not before.

## Where the data is

```
~/.claude/projects/<project-slug>/
  <session-id>.jsonl                  <- main session (the controller, in a dispatch workflow)
  <session-id>/subagents/*.jsonl      <- one per dispatched subagent
  <session-id>/subagents/*.meta.json  <- dispatch description + model
```

**The main session is a sibling of the subagents directory, not inside it.** Globbing the directory omits the controller — the agent that composed every dispatch, held the ledger, and enforced every gate, so most controller-stage findings are invisible without it.

Per request, `message.usage` carries `input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`, and `cache_creation.ephemeral_{5m,1h}_input_tokens`.

## Checks nobody performs spontaneously

Deliberately short. A control run of this audit with no skill at all organised its findings by pipeline stage unprompted, and found the spec, planner and reviewer problems on its own — so a catalogue of "look at the spec, look at the planner" was decoration and has been cut. These three are what that control did **not** do:

- **RED before GREEN.** A report claiming TDD is checkable: the RED command must appear in the transcript *before* the implementation edits, not merely be described afterwards. Claimed-not-done is invisible unless you look for the ordering.
- **Escape rate.** Defects the *final* review caught that per-task reviews missed, plus defects a *later task's* implementer tripped over. This is the only real test of the per-task gate, and no amount of reading individual reviews substitutes for it.
- **Absence of a mandated call.** See below — cheap, decisive, and nobody looks.

Everything else a competent reader finds by reading. Cost is a *detector* pointing at those readings, never a finding itself: a run that wasted money did it by doing something the skills should have prevented, so name that instead.

## Reading the raw blocks

The scripts cover most of the sensors above. When you need something they don't extract:

- **Statuses and verdicts** live in the *last* assistant text block of a subagent transcript, not in any structured field.
- **Tool calls** are `tool_use` blocks; dedup by their `id` — the same block appears in repeated log lines.
- **What a subagent was dispatched for** is in its `.meta.json` sidecar (`description`, `model`), not in the transcript.
- **Thinking is not persisted.** Output tokens are billed and re-sent, but `thinking` blocks are absent from the log, so an agent's reasoning volume can only be inferred as the residual of `output_tokens` minus text and tool inputs. Do not report it as measured.

**Absence is evidence — of one of two different things.** Searching for a tool call a skill mandates and finding none across hundreds of requests is the cheapest finding available and the one nobody looks for. `session-signals tools RUN Agent` does it in one command.

Which of the two depends entirely on the dates: absence in a run that predates the guidance is a baseline, absence in a run that had it is decoration. See SKILL.md § Establish which version ran — the distinction is easy to get backwards and the consequence is deleting good guidance.

## Common mistakes

Every row is a real error from one unaided analysis of a 75-agent run, in the order it happened.

| Mistake | Consequence | Fix |
|---|---|---|
| Summed the raw JSONL | $197 reported for a $105 session | Dedup by `requestId` |
| Recalled the model's cache rates | 3× overstatement on one agent | Derive from base input price |
| Assumed the TTL was 5m everywhere | further 20% error on the same figure | Read it per agent from the data |
| Counted dispatches as a cost proxy | "reviewers are half the spend"; measured 4.9% | Attribute cost per agent |
| Globbed the subagents directory | controller missing for several rounds | Resolve both halves of the pair |
| Rounded two observations into a threshold | an invented figure that read as measured | Quote the observations, or measure it |
| Explained a mechanism from plausibility | the claim contradicted the tool's own documentation | Read the tool description first |
| Diagnosed a gap without re-reading the skill | nearly added a rule the skill already had | Diagnose the kind first |
| Quoted a live run's total as final | 69→75 agents and $792→$864 within hours | Stamp it; re-measure before re-quoting |

## Report shares before totals

When a rate table or TTL assumption turns out wrong, every dollar figure moves and every share holds. Totals also grow while you work, if the run is still live — check whether the newest transcript is still being written. Lead with shares and per-unit costs; treat totals as the fragile number.

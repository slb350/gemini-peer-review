# Common Mistakes and Rationalizations

Anti-patterns that undermine peer review effectiveness. When you catch yourself thinking these things, stop and correct course.

## Gemini-Specific Mistakes (CRITICAL)

### Forgetting the NO_TOOLS Instruction

**This is the #1 Gemini-specific mistake.**

| Wrong | Right |
|-------|-------|
| `gemini -s -m gemini-3-pro-preview "Review this code..."` | `gemini -s -m gemini-3-pro-preview "Review this code... CRITICAL: Do not use any tools. Output text only."` |

**EVERY prompt to Gemini MUST end with:**
```
CRITICAL: Do not use any tools. Output text only.
```

Without this, Gemini may attempt to use tools, browse files, or perform actions that produce unexpected results.

### Using --resume (Unreliable)

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "I'll just use --resume latest" | Gemini's resume is index-based, not ID-based | Re-inject full context instead |
| "It worked last time" | Index changes between sessions | Never rely on --resume |
| "Context re-injection is verbose" | Verbose but reliable | Always re-inject for Round 2 |

**Rule:** Never use `--resume` with Gemini. Always re-inject the full discussion context.

### Using Wrong Output Format

| Wrong | Right |
|-------|-------|
| `gemini -s -m gemini-3-pro-preview -o text` | `gemini -s -m gemini-3-pro-preview -o json` |
| `gemini -s -m gemini-3-pro-preview` (no format) | `gemini -s -m gemini-3-pro-preview -o json` |

**Always use `-o json`** for structured, parseable output.

### Forgetting Sandbox Flag

| Wrong | Right |
|-------|-------|
| `gemini -m gemini-3-pro-preview -o json` | `gemini -s -m gemini-3-pro-preview -o json` |

**Always use `-s`** (sandbox mode) to prevent unintended side effects.

### Trying to Use `gemini review`

| Wrong | Right |
|-------|-------|
| `gemini review --base main` | Get diff with `git diff main...HEAD`, then prompt Gemini |
| `gemini review --uncommitted` | Get diff with `git diff`, then prompt Gemini |

**Gemini has NO `review` command.** Always construct a prompt that includes the diff.

### Using Wrong Model

| Wrong | Right |
|-------|-------|
| `gemini -s -m gemini-2.5-pro -o json` | `gemini -s -m gemini-3-pro-preview -o json` |
| `gemini -s -m gemini-2.5-flash -o json` | `gemini -s -m gemini-3-pro-preview -o json` |

**Always use `gemini-3-pro-preview`** as the default model.

### Shell Escaping Issues

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "I'll just escape the quotes" | Complex prompts break with inline escaping | Use temp files |
| "Short prompt, it'll be fine" | Even short prompts can have issues | Use temp files always |

**Always use temp files for prompts:**
```bash
PROMPT_FILE=$(mktemp /tmp/gemini-prompt-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
[Your prompt here]

CRITICAL: Do not use any tools. Output text only.
PROMPT_EOF

gemini -s -m gemini-3-pro-preview -o json "$(cat "$PROMPT_FILE")"
```

## General Peer Review Mistakes

### Skipping Validation

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "It's just a typo fix" | Typo fixes can break builds, introduce bugs | Validate anyway |
| "I'm confident in this design" | Blind spots exist in every analysis | Validate anyway |
| "Gemini will just agree" | Often finds different issues you missed | Let it check |
| "User is waiting" | Bad advice wastes more time than validation | Validate first |
| "Similar to last time" | Context changes, different edge cases | Validate each time |
| "This is too simple" | Simple things have hidden complexity | Validate anyway |
| "I already checked everything" | Fresh perspective catches what you normalized | Validate anyway |

**Rule:** If you're presenting a design, code review, or answering a broad question, validate with Gemini.

### Premature Agreement

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "Gemini is probably right" | Both AIs can be wrong | Verify with evidence |
| "Don't want to argue with AI" | Technical truth matters more than peace | State your position |
| "Let's just pick one" | Both might have valid points | Synthesize |
| "Two rounds is enough" | Major issues need proper resolution | Escalate if needed |
| "It doesn't matter much" | Small decisions compound | Decide correctly |
| "Whatever is faster" | Fast wrong is slower than slow right | Take time to verify |

**Rule:** Agreement should be based on evidence, not convenience.

### Avoiding Escalation

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "External research is overkill" | Expert input prevents costly errors | Use for major disputes |
| "We've discussed enough" | Unresolved stays unresolved | Escalate |
| "Security concern seems minor" | Security is never minor | Always escalate security |
| "Don't want to slow down" | Wrong decisions cost more time | Take time to escalate |
| "We can figure it out" | Two rounds failed; third won't help | Escalate |
| "User won't notice" | Users notice bugs and security issues | Escalate |
| "Perplexity isn't available" | WebSearch is a valid fallback | Use WebSearch instead |

**Rule:** If two rounds don't resolve it, escalate (Perplexity if available, WebSearch otherwise). If it's security, escalate immediately.

### Over-Escalation

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "Better safe than sorry" | Style != safety | Reserve for real disputes |
| "Let external research decide everything" | Wastes time and resources | Try discussion first |
| "Not sure about anything" | Build confidence through process | Trust the protocol |
| "User will appreciate thoroughness" | User wants efficiency | Be judicious |

**Rule:** Escalate major disagreements, not minor preferences.

### Subagent Misuse

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "I'll run Gemini in main context" | Fills context unnecessarily | Use subagent |
| "Subagent is slower" | Context pollution is worse | Use subagent |
| "I need to see Gemini output live" | Summary is sufficient | Trust subagent |
| "One quick check won't hurt" | Sets bad precedent | Use subagent always |

**Rule:** Always dispatch Gemini via subagent to preserve main context.

### Guessing the Base Branch

| Rationalization | Reality | Correct Action |
|-----------------|---------|----------------|
| "It's probably main" | Projects use different conventions | Ask the user |
| "I can auto-detect with git" | Detection can fail or be wrong | Ask the user |
| "User won't want to be asked" | Wrong branch = useless review | Ask the user |
| "develop is the standard" | Many projects use main, master, trunk, etc. | Ask the user |

**Rule:** If the base branch is not explicitly provided, use `AskUserQuestion` to ask the user. Never guess.

## Discussion Anti-Patterns

### Echo Chamber
- **Symptom:** Restating same position with different words
- **Fix:** Require new evidence in each round

### Goalpost Moving
- **Symptom:** Disagreement shifts to new topic mid-discussion
- **Fix:** Lock in original dispute, address others separately

### Appeal to Authority
- **Symptom:** "Claude/Gemini is usually right about this"
- **Fix:** Require codebase evidence, not reputation

### False Consensus
- **Symptom:** Claiming agreement when positions still differ
- **Fix:** Require explicit position statements that match

### Sunk Cost Fallacy
- **Symptom:** "We've discussed so long, let's just go with X"
- **Fix:** Escalate if truly unresolved

## Recovery Strategies

### If validation was skipped
1. Stop presenting result
2. Trigger validation now
3. Update recommendation if needed
4. Explain the update honestly

### If wrong conclusion reached
1. Acknowledge the error
2. Show correct analysis
3. Explain what was missed
4. Document for future

### If escalation needed after presentation
1. Inform user of uncertainty
2. Escalate to Perplexity/WebSearch
3. Update recommendation
4. Note correction in output

## Red Flags - STOP and Check

If you think any of these, pause and reconsider:

- "This doesn't need validation"
- "Gemini will just agree anyway"
- "Security issue is probably fine"
- "No time for peer review"
- "I'll skip the subagent just this once"
- "Discussion is taking too long"
- "Let's not bother with external research"
- "User won't care about this detail"
- "The base branch is probably main/develop"
- "I can figure out the base branch from git"
- "I don't need the NO_TOOLS instruction this time"
- "I'll just use --resume to continue"
- "Temp files are overkill for this prompt"

**All of these mean:** You should do the opposite of what you're considering.

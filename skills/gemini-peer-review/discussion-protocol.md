# Discussion Protocol: Claude vs Gemini

Structured 2-round resolution of disagreements through evidence-based discussion.

## Gemini-Specific Note

**Session Continuity:** Unlike Codex which uses session IDs for context continuity, Gemini's `--resume` is index-based and unreliable. For multi-round discussions, **re-inject the full context** from previous rounds into each new prompt. This ensures Gemini has complete context without relying on session resume.

## Protocol Rules

### Rule 1: Evidence Required (When Available)
Every position should cite evidence from these categories **as applicable**:
- Specific code lines or files (for code review discussions)
- Project conventions (from CLAUDE.md or equivalent)
- Industry best practices (with source)
- Test results or behavior observations

**For design/architecture discussions** where code doesn't exist yet, acceptable evidence includes:
- Analogous patterns from existing codebase
- Industry case studies or engineering blog posts
- Framework/language documentation
- Threat modeling or risk analysis
- RFCs or design documents

### Rule 2: Two Round Maximum
- Round 1: State positions, provide evidence
- Round 2: Respond to evidence, attempt synthesis
- After Round 2: Escalate or accept synthesis

### Rule 3: Good Faith
- Assume the other AI has valid reasoning
- Look for complementary insights
- Seek "both right in different ways" resolutions

### Rule 4: Context Re-injection (Gemini-Specific)
- **DO NOT** use `--resume` flag with Gemini
- **DO** re-inject all relevant context from Round 1 into Round 2 prompts
- Include: Claude's position, Gemini's Round 1 response, new evidence
- This maintains full context without relying on unreliable session resume

### Rule 5: Classify Disagreement Type

| Type | Definition | Action |
|------|------------|--------|
| Contradiction | Mutually exclusive positions | Must resolve one way |
| Complement | Both valid, additive | Synthesize both |
| Priority | Different ranking of same issues | Use project context |
| Scope | Different interpretation of task | Clarify before proceeding |

## Round 1 Structure

### Claude's Opening
```yaml
position: "[Clear statement of recommendation]"
evidence:
  - code: "[specific file:line or pattern]"
  - convention: "[from project standards]"
  - rationale: "[technical reasoning]"
confidence: "[high|medium|low]"
open_to: "[what evidence would change your mind]"
```

### Gemini's Response (via subagent with context re-injection)

```bash
PROMPT_FILE=$(mktemp /tmp/gemini-round1-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
Given this technical disagreement:

Claude's position: [position]
Claude's evidence:
- Code: [specific reference]
- Convention: [from project standards]
- Rationale: [technical reasoning]

Provide your position on this matter:
1. Where do you agree with Claude?
2. Where do you disagree?
3. What counter-evidence do you have?

Be specific and reference code or standards where possible.

CRITICAL: Do not use any tools. Output text only.
PROMPT_EOF

gemini -s -m gemini-3-pro-preview -o json "$(cat "$PROMPT_FILE")"
```

### Round 1 Outcome
```yaml
outcome: "[resolved|unresolved]"
synthesis: "[if resolved, the merged view]"
remaining_issues: "[if unresolved, specific points to address]"
```

## Round 2 Structure

### Focus
Address ONLY `remaining_issues` from Round 1. No new topics.

### Claude's Response
```yaml
addressing: "[specific remaining issue]"
new_evidence: "[something not presented in Round 1]"
concession: "[what I now agree with from Gemini]"
maintained: "[what I still believe, with stronger reasoning]"
```

### Gemini's Response (via subagent with FULL context re-injection)

```bash
PROMPT_FILE=$(mktemp /tmp/gemini-round2-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
Continuing discussion about [topic]:

## Round 1 Summary
Claude's original position: [summary]
Gemini's Round 1 position: [summary from Round 1 output]
Remaining issue: [the unresolved point]

## Round 2 Input
Claude's new evidence: [new evidence]
Claude's concession: [what Claude now agrees with]
Claude's maintained position: [what Claude still believes]

## Your Task
1. Consider Claude's new evidence
2. Attempt to synthesize a resolution
3. If synthesis is possible, propose it
4. If not, explain why positions remain incompatible

CRITICAL: Do not use any tools. Output text only.
PROMPT_EOF

gemini -s -m gemini-3-pro-preview -o json "$(cat "$PROMPT_FILE")"
```

### Round 2 Outcome
```yaml
outcome: "[resolved|escalate]"
final_synthesis: "[if resolved, the agreed approach]"
escalation_reason: "[if escalating, why discussion failed]"
escalation_question: "[precise question for Perplexity/WebSearch]"
```

## Example Discussion

### Setup
- Claude: "This function should use a Result/Either type for error handling"
- Gemini: "The current exception-based approach is clearer for this codebase"

### Round 1

**Claude:**
```yaml
position: "Use Result type for explicit error handling"
evidence:
  - code: "user_service.py:45 returns None on not-found"
  - convention: "Project uses type hints extensively"
  - rationale: "Result types are more expressive and statically checkable"
confidence: "high"
open_to: "Performance concerns or team familiarity arguments"
```

**Gemini (via prompt with context):**
```yaml
position: "Keep exception-based error handling"
agreement_areas: "Explicit error handling is important"
disagreement_areas: "Implementation approach"
counter_evidence:
  - code: "Other methods in user_service use exceptions consistently"
  - rationale: "Consistency within module aids readability"
```

**Round 1 Outcome:**
```yaml
outcome: "unresolved"
synthesis: null
remaining_issues:
  - "Module consistency vs modern idiom adoption"
```

### Round 2

**Claude:**
```yaml
addressing: "Module consistency vs modern idiom"
new_evidence: "Git history shows 3 commits in last month adopting Result types elsewhere"
concession: "Consistency matters for readability"
maintained: "Migration is already underway, this continues the pattern"
```

**Gemini (via prompt with full context re-injection):**
```yaml
addressing: "Module consistency vs modern idiom"
response_to_evidence: "Migration trend is valid context I missed"
proposed_synthesis: "Use Result type here, add TODO for full module migration"
```

**Round 2 Outcome:**
```yaml
outcome: "resolved"
final_synthesis: "Use Result type with TODO comment for module-wide migration"
```

## When Discussion Fails

If after Round 2:
- Positions remain fundamentally opposed
- Evidence is inconclusive on both sides
- Stakes are high (security, architecture, breaking changes)

Then escalate with precise question:

```
Given [specific context], should [option A] or [option B] be used?

Context:
- Codebase: [language/framework]
- Existing patterns: [relevant patterns]
- Constraints: [any constraints]

Claude's position: [summary with key evidence]
Gemini's position: [summary with key evidence]

Which approach is correct and why?
```

## Anti-Patterns

### Bad Discussion
- **Echo Chamber:** Restating positions without new evidence
- **Goalpost Moving:** Changing the disagreement mid-discussion
- **Appeal to Authority:** "Gemini/Claude is usually right"
- **False Consensus:** Claiming agreement without actual alignment

### Good Discussion
- **Evidence-Based:** Every claim backed by code or standards
- **Focused:** One issue at a time
- **Constructive:** Seeking synthesis, not victory
- **Honest:** Acknowledging uncertainty and conceding valid points

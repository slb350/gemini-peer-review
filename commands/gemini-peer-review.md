---
name: gemini-peer-review
description: Trigger peer review validation with Gemini CLI. Use without arguments for current changes, --base <branch> for specific branch comparison, or add a question for broad technical validation.
allowed-tools:
  - Bash(gemini:*)
  - Bash(mktemp:*)
  - Bash(cat:*)
  - Bash(command:*)
  - Bash(which:*)
  - Bash(jq:*)
  - Bash(grep:*)
  - Bash(head:*)
  - Bash(tee:*)
  - Bash(git:*)
  - Read
  - Task
  - AskUserQuestion
---

# Gemini Peer Review Command

You have been explicitly asked to run peer review validation using Google Gemini CLI.

## Parse Arguments

Check for arguments in the command:
- `/gemini-peer-review` - Review current changes (will ask what to review)
- `/gemini-peer-review --base <branch>` - Review against specified branch
- `/gemini-peer-review --uncommitted` - Review staged/unstaged/untracked changes only
- `/gemini-peer-review --commit <SHA>` - Review a specific commit
- `/gemini-peer-review <question>` - Validate answer to a broad technical question

## Execute

**IMPORTANT:** All peer review work MUST run as a subagent to keep the main context clean.

1. **Gather information** from the user (review type, branch, etc.)
2. **Dispatch to the `gemini-peer-reviewer` agent** with the Task tool
3. **Return only the synthesized result** to the user

Based on the arguments:

### No arguments (ask user what to review)
**IMPORTANT:** Ask the user what type of review they want.

Use `AskUserQuestion` tool:
```yaml
question: "What would you like to review?"
header: "Review type"
options:
  - label: "Changes vs branch"
    description: "Compare current changes against a base branch (will ask which branch)"
  - label: "Uncommitted changes"
    description: "Review staged, unstaged, and untracked changes only"
  - label: "Specific commit"
    description: "Review changes from a specific commit (will ask for SHA)"
multiSelect: false
```

#### If "Changes vs branch" selected
Ask for the base branch:
```yaml
question: "Which branch should I compare against?"
header: "Base branch"
options:
  - label: "main"
    description: "Compare against the main branch"
  - label: "develop"
    description: "Compare against the develop branch"
  - label: "master"
    description: "Compare against the master branch"
multiSelect: false
```
Then the subagent will: get the diff with `git diff [branch]...HEAD` and review it via Gemini prompt

#### If "Uncommitted changes" selected
The subagent will: get the diff with `git diff` and `git diff --staged` and review via Gemini prompt

#### If "Specific commit" selected
Ask: "What is the commit SHA to review?"
Then the subagent will: get the diff with `git show [SHA]` and review via Gemini prompt

### With explicit flags
Use the specified flag directly:
- `--base <branch>`: Get diff with `git diff [branch]...HEAD`
- `--uncommitted`: Get diff with `git diff` and `git diff --staged`
- `--commit <SHA>`: Get diff with `git show [SHA]`

### Handling "no changes" case
If git reports no changes to review, inform the user:
"No changes found to review. Make sure you have uncommitted changes or specify a branch with divergent commits."

### With a question
This is a **design/architecture validation**:

Dispatch a subagent with:
```
Validate Claude's response to this question using Gemini CLI.

Question: [the question from arguments]

Use gemini with focused prompt about the question.

Return findings for comparison and synthesis.
```

## Dispatch to Agent

After gathering the review parameters, dispatch to the `gemini-peer-reviewer` agent:

```
Use Task tool:
  subagent_type: "gemini-peer-review:gemini-peer-reviewer"
  prompt: |
    Run peer review validation.

    Type: [code-review | design | architecture | question]
    [For code-review]: Branch: [branch], Focus: [focus area if any]
    [For design/arch/question]: Claude's position: [summary]

    Return only the synthesized peer review result.
```

## Output

The agent will return a synthesized result. Present it to the user:
- **Validated**: Both AIs agreed
- **Resolved**: Disagreement resolved through discussion
- **Escalated**: Required external research (Perplexity/WebSearch)

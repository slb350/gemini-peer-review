# Gemini Peer Review

A Claude Code plugin that validates Claude's designs, code reviews, and recommendations using Google Gemini CLI as a second AI perspective.

## Why Peer Review?

Two AI perspectives catch more issues than one. Before presenting implementation plans, architecture recommendations, or code review findings, this plugin validates Claude's work through Gemini CLI to:

- Catch blind spots in analysis
- Identify alternative approaches
- Surface potential issues early
- Increase confidence in recommendations

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Google Gemini CLI](https://github.com/google-gemini/gemini-cli) (v0.24.5 or later)

### Installing Gemini CLI

```bash
# macOS (Homebrew)
brew install gemini-cli

# Or via npm
npm install -g @anthropic-ai/gemini-cli
```

Verify installation:
```bash
gemini --version
# Expected: 0.24.5 or later
```

## Installation

### Via Claude Code Plugin Marketplace (Recommended)

In Claude Code, run:
```
/plugin add slb350/gemini-peer-review
```

Then select the `gemini-peer-review` plugin when prompted.

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/slb350/gemini-peer-review.git ~/.claude/plugins/marketplaces/gemini-peer-review
   ```

2. Restart Claude Code or run `/plugin reload`

3. Add the plugin via `/plugin add` and select from local marketplaces

## Usage

### Automatic Validation

Once installed, the plugin automatically reminds Claude to validate:
- Implementation plans and designs
- Code review findings
- Architecture recommendations
- Major refactoring proposals
- Answers to broad technical questions

### Slash Command

Trigger peer review manually:

```bash
# Review current changes (interactive)
/gemini-peer-review

# Review against a specific branch
/gemini-peer-review --base main

# Review uncommitted changes
/gemini-peer-review --uncommitted

# Validate a technical question
/gemini-peer-review "Should I use composition or inheritance here?"
```

### Subagent Dispatch

For programmatic use within Claude's workflow:

```
Task tool with subagent_type="gemini-peer-review:gemini-peer-reviewer"
prompt: "Validate this design: [your design summary]"
```

## How It Works

1. **Claude forms a recommendation** (design, code review, architecture)
2. **Plugin dispatches to Gemini** via subagent (keeps main context clean)
3. **Gemini validates independently** using focused prompts
4. **Results are compared**:
   - **Agreement**: Synthesize and present with high confidence
   - **Disagreement**: Run 2-round discussion protocol
   - **Critical issue**: Escalate immediately (security, architecture, breaking changes)
5. **Synthesized result** returned to user

### Discussion Protocol

When Claude and Gemini disagree:
- **Round 1**: Both state positions with evidence
- **Round 2**: Respond to evidence, attempt synthesis
- **Escalation**: If unresolved, use Perplexity MCP or WebSearch for external arbitration

## Repository Structure

```
gemini-peer-review/
├── .claude-plugin/
│   └── marketplace.json         # Marketplace manifest
├── README.md
└── plugins/
    └── gemini-peer-review/
        ├── .claude-plugin/
        │   └── plugin.json      # Plugin manifest
        ├── agents/
        │   └── gemini-peer-reviewer.md
        ├── commands/
        │   └── gemini-peer-review.md
        ├── skills/
        │   └── gemini-peer-review/
        │       ├── SKILL.md
        │       ├── discussion-protocol.md
        │       ├── escalation-criteria.md
        │       └── common-mistakes.md
        └── hooks/
            ├── hooks.json
            └── *.sh
```

## Gemini CLI Specifics

This plugin accounts for key differences between Gemini CLI and other tools:

| Aspect | Approach |
|--------|----------|
| Model | `gemini-3-pro-preview` (default) |
| Output | Always `-o json` for structured parsing |
| Sandbox | Always `-s` flag for safety |
| Tool prevention | Every prompt ends with `CRITICAL: Do not use any tools. Output text only.` |
| Code review | No built-in review command - uses git diff + prompts |
| Session continuity | Context re-injection (not `--resume`) |

## Output Formats

### Validated (Agreement)
```markdown
## Peer Review Result
**Status:** Validated
**Confidence:** High (both AIs aligned)

[Synthesized recommendations]
```

### Resolved Through Discussion
```markdown
## Peer Review Result
**Status:** Resolved through discussion

**Initial Positions:**
- Claude: [position]
- Gemini: [position]

**Resolution:** [how resolved]
**Final Recommendation:** [synthesized view]
```

### Escalated
```markdown
## Peer Review Result
**Status:** Escalated for external research
**Source:** [Perplexity | WebSearch]

**Research Findings:** [authoritative answer]
**Final Recommendation:** [based on findings]
```

## Configuration

The plugin works out of the box with sensible defaults. Hooks automatically trigger at:
- Session start (reminder)
- User prompt submission (detection)
- Before presenting responses (verification)
- Before ExitPlanMode, Task dispatch, and Write operations

## Troubleshooting

### Gemini CLI not found
```bash
# Verify installation
which gemini
gemini --version
```

### Tool execution errors
Ensure prompts always end with the NO_TOOLS instruction:
```
CRITICAL: Do not use any tools. Output text only.
```

### Session resume issues
The plugin uses context re-injection instead of `--resume` for reliability. This is by design.

## Contributing

Contributions welcome! Please open issues for bugs or feature requests.

## License

MIT

## Related Projects

- [codex-peer-review](https://github.com/jcputney/codex-peer-review) - Similar plugin using OpenAI Codex CLI
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Anthropic's official CLI
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) - Google's Gemini command-line interface

#!/bin/bash
# SessionStart hook to remind Claude about peer review requirements
# This hook runs at the start of each Claude Code session

# Check if gemini CLI is available
GEMINI_STATUS=""
if command -v gemini &>/dev/null; then
  GEMINI_STATUS="✓ Gemini CLI is installed"
else
  GEMINI_STATUS="⚠ Gemini CLI not found"
fi

cat << 'EOF'
## Peer Review Requirement

**BEFORE presenting any of the following to the user, you MUST dispatch to the `gemini-peer-reviewer` agent:**
- Implementation plans or designs
- Code review results
- Architecture recommendations
- Major refactoring proposals
- Answers to broad technical questions

**How to trigger:** Use the Task tool to dispatch to the `gemini-peer-reviewer` agent with your findings. The agent runs in a **separate context** to keep the main conversation clean, then returns only the synthesized peer review result.

Example:
```
Task tool with subagent_type="gemini-peer-review:gemini-peer-reviewer"
prompt: "Validate this design: [your design summary]"
```

**Why:** Two AI perspectives catch more issues than one. Running as a subagent keeps Gemini CLI output isolated and returns only distilled results.
EOF

echo "**Gemini CLI Status:** $GEMINI_STATUS"

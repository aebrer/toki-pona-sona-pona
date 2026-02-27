#!/bin/bash
# Test hook for PreToolUse ExitPlanMode
# Dumps everything we receive to /tmp/tpsp-hook-test/ so we can inspect:
# - The full stdin JSON (what data is available?)
# - The plan content (can we extract it?)
# - Timing (when does this fire relative to user approval?)

OUTDIR="/tmp/tpsp-hook-test"
mkdir -p "$OUTDIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Read all of stdin
STDIN_JSON=$(cat)

# Dump the raw stdin JSON
echo "$STDIN_JSON" > "$OUTDIR/stdin-${TIMESTAMP}.json"

# Extract transcript_path if present
TRANSCRIPT_PATH=$(echo "$STDIN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path','NOT_FOUND'))" 2>/dev/null)
echo "$TRANSCRIPT_PATH" > "$OUTDIR/transcript-path-${TIMESTAMP}.txt"

# If we got a transcript path, try to extract plan-related content from it
if [ -f "$TRANSCRIPT_PATH" ]; then
    # Grab the last 200 lines of the transcript (it's JSONL)
    tail -200 "$TRANSCRIPT_PATH" > "$OUTDIR/transcript-tail-${TIMESTAMP}.jsonl"

    # Try to find any Write tool calls (plan file writes)
    python3 -c "
import sys, json

with open('$TRANSCRIPT_PATH', 'r') as f:
    lines = f.readlines()

# Look for Write/Edit tool calls and ExitPlanMode in recent history
writes = []
plan_file = None
for line in lines:
    try:
        obj = json.loads(line)
        # Check for tool uses
        if isinstance(obj, dict):
            msg = obj
            if 'content' in msg and isinstance(msg['content'], list):
                for block in msg['content']:
                    if isinstance(block, dict) and block.get('type') == 'tool_use':
                        name = block.get('name', '')
                        inp = block.get('input', {})
                        if name == 'Write':
                            writes.append({'file': inp.get('file_path','?'), 'len': len(inp.get('content',''))})
                        elif name == 'Edit':
                            writes.append({'file': inp.get('file_path','?'), 'type': 'edit'})
    except:
        pass

with open('$OUTDIR/tool-calls-${TIMESTAMP}.json', 'w') as out:
    json.dump(writes, out, indent=2)
" 2>"$OUTDIR/extract-errors-${TIMESTAMP}.txt"
fi

# Write a marker file so Drew can easily see the hook fired
echo "Hook fired at $(date). ExitPlanMode intercepted." > "$OUTDIR/HOOK_FIRED.txt"

# Exit 0 — don't block, just observe
exit 0

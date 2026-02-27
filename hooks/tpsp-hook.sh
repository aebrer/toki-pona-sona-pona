#!/bin/bash
# toki pona, sona pona — ExitPlanMode hook
#
# Runs the agent's plan through Toki Pona round-trip compression before
# the user sees it. If the plan doesn't survive the round trip cleanly,
# the hook blocks ExitPlanMode and tells the agent to simplify.
#
# Requires: claude CLI, python3
#
# Set TPSP_DEBUG=1 to enable logging to /tmp/tpsp-debug.log

TPSP_DEBUG="${TPSP_DEBUG:-0}"

if [ "$TPSP_DEBUG" = "1" ]; then
    LOG="/tmp/tpsp-debug.log"
    log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }
else
    log() { :; }
fi

log "=== Hook fired ==="

# --- Extract plan from stdin JSON ---
STDIN_JSON=$(cat)
log "Got stdin (${#STDIN_JSON} bytes)"

PLAN=$(echo "$STDIN_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('plan', ''))
" 2>/dev/null)

log "Plan extracted (${#PLAN} chars)"

if [ -z "$PLAN" ]; then
    log "No plan content, exiting 0"
    exit 0
fi

# --- Temp files (cleaned up on exit) ---
PLAN_FILE=$(mktemp /tmp/tpsp-XXXXXX-plan.txt)
TP_FILE=$(mktemp /tmp/tpsp-XXXXXX-tp.txt)
RECON_FILE=$(mktemp /tmp/tpsp-XXXXXX-recon.txt)
VERDICT_FILE=$(mktemp /tmp/tpsp-XXXXXX-verdict.txt)
cleanup() {
    log "Cleaning up temp files"
    rm -f "$PLAN_FILE" "$TP_FILE" "$RECON_FILE" "$VERDICT_FILE"
}
trap cleanup EXIT

echo "$PLAN" > "$PLAN_FILE"
log "Plan written to $PLAN_FILE"

# --- Find claude CLI ---
CLAUDE_BIN=$(which claude 2>/dev/null)
if [ -z "$CLAUDE_BIN" ]; then
    for p in /usr/local/bin/claude /usr/bin/claude "$HOME/.claude/local/claude" "$HOME/.local/bin/claude"; do
        if [ -x "$p" ]; then
            CLAUDE_BIN="$p"
            break
        fi
    done
fi

if [ -z "$CLAUDE_BIN" ]; then
    log "ERROR: claude CLI not found in PATH or common locations"
    exit 0
fi
log "Using claude at: $CLAUDE_BIN"

# --- Step 1: Translate plan to Toki Pona ---
log "Step 1: Translating to Toki Pona..."

"$CLAUDE_BIN" -p "You are a Toki Pona translator. Translate the following text faithfully into Toki Pona. Preserve intent and structure, not literal words. Use proper Toki Pona grammar. Do not simplify, editorialize, or add commentary. Output ONLY the Toki Pona translation, nothing else.

Text to translate:

$(cat "$PLAN_FILE")" > "$TP_FILE" 2>/dev/null
log "Step 1 done (exit $?, $(wc -c < "$TP_FILE") bytes)"

if [ ! -s "$TP_FILE" ]; then
    log "Step 1 produced no output, exiting 0"
    exit 0
fi

log "TP preview: $(head -c 200 "$TP_FILE")"

# --- Step 2: Blind back-translation (no context) ---
log "Step 2: Blind back-translation..."

"$CLAUDE_BIN" -p "You are a translator. You have no context about what this text is about or where it came from. Translate the following Toki Pona text into natural, fluent English. Do your best to capture the meaning. Output ONLY the English translation, nothing else.

Text to translate:

$(cat "$TP_FILE")" > "$RECON_FILE" 2>/dev/null
log "Step 2 done (exit $?, $(wc -c < "$RECON_FILE") bytes)"

if [ ! -s "$RECON_FILE" ]; then
    log "Step 2 produced no output, exiting 0"
    exit 0
fi

RECON=$(cat "$RECON_FILE")
log "Reconstruction preview: $(echo "$RECON" | head -c 200)"

# --- Step 3: Compare and verdict ---
log "Step 3: Comparing..."

"$CLAUDE_BIN" -p "Compare these two texts. The first is an original plan written by an AI agent. The second is what survived after the plan was compressed through Toki Pona (a 130-word language) and blind-translated back by a separate agent with no context.

ORIGINAL PLAN:
$(cat "$PLAN_FILE")

BLIND RECONSTRUCTION:
$RECON

Your response MUST begin with exactly PASS or FAIL on its own line.

PASS — the core concepts, structure, and intent survived. Synonyms and rephrasings are fine.
FAIL — significant architectural decisions, key requirements, or structural elements were lost or mutated beyond recognition, suggesting the plan is overspecified or unclear.

After the verdict, write 2-3 concise sentences about what survived, what vanished, and what mutated." > "$VERDICT_FILE" 2>/dev/null
log "Step 3 done (exit $?, $(wc -c < "$VERDICT_FILE") bytes)"

if [ ! -s "$VERDICT_FILE" ]; then
    log "Step 3 produced no output, exiting 0"
    exit 0
fi

VERDICT=$(cat "$VERDICT_FILE")
FIRST_LINE=$(echo "$VERDICT" | head -1)
log "Verdict: $FIRST_LINE"
log "Full verdict: $VERDICT"

# --- Decision ---
case "$FIRST_LINE" in
    FAIL*)
        log "DECISION: FAIL — blocking ExitPlanMode (exit 2)"
        cat >&2 <<FEEDBACK
toki pona, sona pona — complexity check FAILED

$VERDICT

BLIND RECONSTRUCTION (what survived compression):
$RECON

The parts that vanished or mutated may be overspecified, overly abstract,
or unclear. Consider simplifying your plan before presenting it. Focus on
the *what* and *why*, not the *how*.
FEEDBACK
        exit 2
        ;;
    *)
        log "DECISION: PASS — allowing ExitPlanMode (exit 0)"
        exit 0
        ;;
esac

#!/bin/bash
# <xbar.title>Claude Code Sessions</xbar.title>
# <xbar.desc>Shows active and recent Claude Code sessions</xbar.desc>
# <xbar.author>Joyce</xbar.author>
# <xbar.version>1.0</xbar.version>

CLAUDE_DIR="$HOME/.claude"
SESSIONS_DIR="$CLAUDE_DIR/sessions"
PROJECTS_DIR="$CLAUDE_DIR/projects"

# Count active sessions
active_count=0
if [ -d "$SESSIONS_DIR" ]; then
  for f in "$SESSIONS_DIR"/*.json; do
    [ -f "$f" ] || continue
    pid=$(python3 -c "import json; print(json.load(open('$f')).get('pid',''))" 2>/dev/null)
    kill -0 "$pid" 2>/dev/null && active_count=$((active_count + 1))
  done
fi

# Circled number badges
circled_numbers=("⓪" "①" "②" "③" "④" "⑤" "⑥" "⑦" "⑧" "⑨" "⑩")

# Menu bar title
if [ "$active_count" -eq 0 ]; then
  echo "🤖 | size=15"
elif [ "$active_count" -le 10 ]; then
  echo "🤖${circled_numbers[$active_count]} | size=15"
else
  echo "🤖${active_count} | size=15"
fi

echo "---"

# Active sessions
if [ "$active_count" -gt 0 ]; then
  echo "Active Sessions | size=12 color=#999999"
  for f in "$SESSIONS_DIR"/*.json; do
    [ -f "$f" ] || continue
    eval "$(python3 -c "
import json
d = json.load(open('$f'))
print(f'pid={d.get(\"pid\",\"\")}')
print(f'session_id={d.get(\"sessionId\",\"\")}')
print(f'cwd={d.get(\"cwd\",\"\")}')
print(f'started={d.get(\"startedAt\",0)}')
" 2>/dev/null)"

    kill -0 "$pid" 2>/dev/null || continue

    project_name=$(basename "$cwd")
    started_human=$(python3 -c "from datetime import datetime; print(datetime.fromtimestamp($started/1000).strftime('%H:%M'))" 2>/dev/null)

    # Find session jsonl
    jsonl_file=$(find "$PROJECTS_DIR" -name "${session_id}.jsonl" 2>/dev/null | head -1)
    last_prompt=""
    agent_name=""
    custom_title=""
    if [ -n "$jsonl_file" ]; then
      last_prompt=$(grep '"last-prompt"' "$jsonl_file" 2>/dev/null | tail -1 | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('lastPrompt','')[:60])" 2>/dev/null)
      custom_title=$(grep '"custom-title"' "$jsonl_file" 2>/dev/null | tail -1 | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('customTitle',''))" 2>/dev/null)
      agent_name=$(grep '"agent-name"' "$jsonl_file" 2>/dev/null | tail -1 | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('agentName',''))" 2>/dev/null)
    fi

    # Subagent count
    subagent_dir=$(dirname "$jsonl_file")/"$session_id"/subagents 2>/dev/null
    subagent_count=0
    if [ -d "$subagent_dir" ]; then
      subagent_count=$(ls "$subagent_dir"/*.meta.json 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Build display label
    label="$project_name"
    [ -n "$custom_title" ] && label="$project_name ($custom_title)"
    [ -n "$agent_name" ] && label="$project_name ($agent_name)"

    sub_badge=""
    [ "$subagent_count" -gt 0 ] && sub_badge=" [${subagent_count} agents]"

    echo "${label}${sub_badge}  ${started_human} | color=#15803d font=Menlo-Bold size=13"
  done
else
  echo "No active sessions | color=#999999 size=13"
fi

echo "---"
echo "Refresh | refresh=true"

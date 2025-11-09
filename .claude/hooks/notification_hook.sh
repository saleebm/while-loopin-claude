#!/bin/bash
cat | jq -r '.message // "Claude notification"' | xargs -I {} curl -H "Title: Claude Code" -d "{}" ntfy.sh/cc-alerts
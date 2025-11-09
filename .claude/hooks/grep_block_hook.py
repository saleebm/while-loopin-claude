#!/usr/bin/env python3
import json
import sys

# This hook is triggered when grep is detected in a bash command
# Always block and remind to use rg instead

print(json.dumps({
    "decision": "block",
    "reason": "Use 'rg' (ripgrep) instead of grep for faster and better search results"
}))
sys.exit(0)
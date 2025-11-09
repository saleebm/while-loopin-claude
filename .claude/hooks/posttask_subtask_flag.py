#!/usr/bin/env python3
import os
import json
import sys

# Remove the flag file when exiting the subtask
flag_file = '.claude_in_subtask.flag'
if os.path.exists(flag_file):
    os.remove(flag_file)

print(json.dumps({"decision": "approve"}))
sys.exit(0)
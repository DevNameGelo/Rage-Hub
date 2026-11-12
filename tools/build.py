#!/usr/bin/env python3
"""Rebuild RageHub.lua from src/ (run tools/gen_icons.py first if you changed icons)."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORDER = ["00_head.lua", "icons.lua", "10_engine.lua", "20_window.lua", "30_elements.lua", "40_settings.lua"]
out = []
for name in ORDER:
    with open(os.path.join(ROOT, "src", name)) as f:
        out.append(f.read().rstrip("\n") + "\n")
with open(os.path.join(ROOT, "RageHub.lua"), "w") as f:
    f.write("\n".join(out))
print("built RageHub.lua", sum(len(x) for x in out), "bytes")

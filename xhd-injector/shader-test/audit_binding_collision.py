#!/usr/bin/env python3
"""Fail-closed diagnostic: compare fixture SRV dimensions with the user's captured PC eye draw.
Do not infer PS4->PC resource mapping from matching register indices.
"""
from pathlib import Path
import json,re
fixture=Path("xhd-injector/shader-test/xhd_integrated_fixture.hlsl").read_text()
pc={"t0":"Texture2D","t1":"Texture2D","t2":"Texture2D","t3":"Texture2D",
    "t5":"TextureCube","t9":"TextureCube","t10":"TextureCube","t11":"TextureCube"}
claims=[]
for dtype,name,slot in re.findall(r"(?m)^\s*(Texture\w+)<float4>\s+(\w+)\s*:\s*register\((t\d+)\)",fixture):
    expected=pc.get(slot)
    claims.append({"slot":slot,"fixture":name,"fixture_type":dtype,"pc_type":expected,
                   "type_compatible":expected==dtype if expected else None,
                   "is_ps4_binding_proven":False})
mismatches=[v for v in claims if v["type_compatible"] is False]
report={"game_ready":False,"ps4_resources_mapped":False,"mismatches":mismatches,
 "claims":claims,"reason":"Test fixture expects array textures in PC slots holding Texture2D; PS4 originals not yet acquired."}
Path("binding_audit.json").write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding="utf8")
for c in claims:print(c)
print("BLOCKING MISMATCHES:",len(mismatches))
assert len(mismatches)>=2,"unexpected fixture bindings; manually re-audit"
print("EXPECTED BLOCKER VERIFIED. Do not ship integrated .cso as a game replacement.")

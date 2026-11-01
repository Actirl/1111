"""Audit compiled test shaders' output ABI against observed PC eye shader.
This is an evidence gate: success means report generated, not game compatibility.
"""
from pathlib import Path
import json, re, sys

results={}
for draw in ("144","220"):
    asm=Path(f"draw{draw}.asm")
    if not asm.exists():
        raise SystemExit(f"Missing FXC disassembly: {asm}")
    text=asm.read_text(encoding="utf-8-sig",errors="replace")
    instruction_lines=[x.strip() for x in text.splitlines() if not x.lstrip().startswith("//")]
    outputs=sorted(set(re.findall(r"\bdcl_output(?:_siv)?\s+o\d+(?:\.[xyzw]+)?(?:\s*,\s*\w+)?", "\n".join(instruction_lines))))
    targets=sorted(set(re.findall(r"\bSV_Target\d*\b",text,re.I)))
    # Resource registers are compiler-assigned and explicitly NOT PS4 binding numbers.
    resources=sorted(set(re.findall(r"\bdcl_resource\w*\s+\w+\s+\([^\n]*\)\s+t\d+", "\n".join(instruction_lines))))
    results[f"draw{draw}"]={"compiled":True,"output_declarations":outputs,
      "signature_targets":targets,"resource_declarations":resources,
      "matches_pc_two_target_requirement":bool(re.search(r"\bSV_Target1\b",text,re.I))}
Path("abi_audit.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf-8")
for draw,item in results.items():
    print(f"{draw}: targets={item['signature_targets']} "
          f"two_render_targets={item['matches_pc_two_target_requirement']}")
if all(x["matches_pc_two_target_requirement"] for x in results.values()):
    print("Both test harnesses declare PC dual-target output.")
else:
    print("INTEGRATION BLOCKER: test harness output ABI does not match PC original eye shader "
          "(SV_Target0 and SV_Target1). DO NOT swap these DXBC files into game.")

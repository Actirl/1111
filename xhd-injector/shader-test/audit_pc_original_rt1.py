#!/usr/bin/env python3
"""Audit PC eye DXBC assembly writes to MRT1 without assuming MRT1 is a color buffer."""
import re,sys
from pathlib import Path
src=Path(sys.argv[1] if len(sys.argv)>1 else "xhd_target_original_runtime.asm")
data=src.read_text(encoding="utf-8",errors="replace").splitlines()
declarations=[(i,x.strip()) for i,x in enumerate(data,1) if re.match(r"^dcl_output\s+o[01](?:\.|\b)",x.strip())]
writes=[(i,x.strip()) for i,x in enumerate(data,1) if re.match(r"^(?:mov|movc|add|mul|mad|and|or|xor)\s+o1(?:\.[xyzw]+)?\s*,",x.strip())]
print("OUTPUT DECLARATIONS:",declarations)
print("RT1 WRITES:",writes)
if len(writes)!=2 or not any("o1.xw" in x for _,x in writes) or not any("o1.yz" in x for _,x in writes):
    raise SystemExit("Unrecognized RT1 output path; revisit disassembly before injection")
print("PASS: PC original RT1 x/w and y/z are two different computed paths, not generic color.")
print("WARNING: This proof does not identify how game consumes RT1. Do not replace with diagnostic LOD values.")

#!/usr/bin/env python3
"""Compare original PC DXBC disassembly declarations with a candidate shader."""
import argparse, json, re, sys
from pathlib import Path

def extract(text):
    output = {"inputs": {}, "outputs": {}, "resources": {}, "constant_buffers": {}}
    for line in text.splitlines():
        line = line.strip()
        m = re.fullmatch(r'dcl_input_ps\s+(?:\w+\s+)*v(\d+)\.([xyzw]+)', line)
        if m: output["inputs"]["v"+m[1]] = m[2]
        m = re.fullmatch(r'dcl_output\s+o(\d+)\.([xyzw]+)', line)
        if m: output["outputs"]["o"+m[1]] = m[2]
        m = re.fullmatch(r'dcl_resource_(texture\w+)\s+\([^)]*\)\s+(t\d+)', line)
        if m: output["resources"][m[2]] = m[1]
        m = re.fullmatch(r'dcl_constantbuffer\s+(CB\d+)\[(\d+)\],\s+immediateIndexed', line)
        if m: output["constant_buffers"][m[1]] = int(m[2])
    return output

def compare(reference, candidate):
    errors = []
    for key in ("inputs", "outputs"):
        if not reference[key]: errors.append("reference has no parsed " + key)
        if not candidate[key]: errors.append("candidate has no parsed " + key)
    for key in ("inputs", "outputs"):
        for reg, mask in reference[key].items():
            if candidate[key].get(reg) != mask:
                errors.append(f"{key} {reg}: expected .{mask}; got {candidate[key].get(reg)}")
    for key in ("resources", "constant_buffers"):
        for reg, kind in candidate[key].items():
            if reg in reference[key] and reference[key][reg] != kind:
                errors.append(f"{key} {reg}: expected {reference[key][reg]}; got {kind}")
    return errors

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("original")
    parser.add_argument("candidate")
    args = parser.parse_args()
    original = extract(Path(args.original).read_text(encoding="utf8", errors="replace"))
    candidate = extract(Path(args.candidate).read_text(encoding="utf8", errors="replace"))
    errors = compare(original, candidate)
    print(json.dumps({"original_abi": original, "candidate_abi": candidate, "errors": errors, "pass": not errors}, indent=2))
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())

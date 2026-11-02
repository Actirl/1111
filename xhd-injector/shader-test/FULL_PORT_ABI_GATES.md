# X HD eye full-port ABI checkpoint (PC runtime evidence)

This is NOT a PS4 shader port and is not intended as a replacement .cso.

Verified from the original PC eye pixel shader `xhd_target_original_runtime.asm` captured at runtime:

- Input: SV_POSITION0; NORMAL0 v1.xyz; TANGENT0 v2.xyz; BINORMAL0 v3.xyz; TEXCOORD0 v4.xy; TEXCOORD1 v5.xyz; TEXCOORD2 v6.xyzw; COLOR0 v7.w; COLOR1 v8.xyz.
- Output: SV_Target0.xyzw and SV_Target1.xyzw.
- SRVs: Texture2D t0,t2,t3,t19; TextureCube t5,t9,t10,t11.
- Samplers: s0,s2,s3,s5,s7,s9,s10.
- CBs: b0, b1, b2, b4.
- The first observed live game draw had t24..t27 unbound. This does NOT prove that these slots are unused in all scenes.
- An existing partial PS4 function implements some b5 dynamic LOD and b6/b7 array lookups for Draw144/Draw220, but is not the complete original shader.

## Why Soft Cyan v1/v2 is not sufficient
V1/V2 shader samples only t0 and writes an approximation of SV_Target1. It does not use the original lighting inputs and cannot reproduce full X HD eye shading, and may damage material outputs.

## Mandatory gates before full-port install
1. Confirm PS4 Draw144 and Draw220 target the exact corresponding eye materials, using an actual draw capture (not matching shader variable names alone).
2. Export and identify original PS4 runtime bindings (set0/b3..b9) and all array layers/mips, plus material constants and samplers.
3. Reconstruct complete PS4 RGB and Alpha expressions from original SPIR-V, preserve all decisions and dynamic LOD calculations for both variants.
4. Match PC MRT ABI and texture typing. PS4 binding indices are NOT direct PC t-register indices.
5. Integrate the above into DLL opt-in runtime SRV binding with save/restore of original SRVs; never use t24..t27 without checking per-draw availability.
6. Rebuild on Windows, test shader reflection signature/CB resource semantics and compare paired source vs game captures, with simple rollback.

**No PC-side color-only shader has passed these gates.**

// Literal algebraic reconstruction of the PC DXBC IBL contribution segment.
// Provenance: runtime xhd_target_original_runtime.asm, if_nz r3.w block.
// This is PC output-path reconstruction, NOT the original PS4 X HD IBL shader.
#ifndef XHD_PC_EYE_IBL_COMBINE_H
#define XHD_PC_EYE_IBL_COMBINE_H
struct XHD_IBL_Result {float3 iblRGB;float3 accumulatedRGB;};
XHD_IBL_Result XHD_PC_Eye_IBLCombine(
  float3 sourceT11, float3 sourceT10,
  float interpolation, float3 scaleCB1_16,
  float materialMaskR0x, float3 materialR7,
  float3 baseR1)
{
 XHD_IBL_Result output;
 float3 interpolated=lerp(sourceT11,sourceT10,interpolation);
 float3 capped=min(interpolated,float3(3,3,3));
 float3 uncappedExcess=interpolated-capped;
 // Original: mad r0.xyw, r0.xxxx, r2.xyxz, r6.xyxz
 float3 ibl=capped+materialMaskR0x*uncappedExcess;
 output.iblRGB=ibl*scaleCB1_16;
 output.accumulatedRGB=baseR1+output.iblRGB*materialR7;
 return output;
}
#endif

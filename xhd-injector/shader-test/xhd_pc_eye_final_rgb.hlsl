// Exact algebraic translation of the PC original eye DXBC final RGB stage.
// Source: xhd_target_original_runtime.asm immediately before "movc o0.xyz".
// Inputs are values from earlier instructions, not reconstructed or guessed.
#ifndef XHD_PC_EYE_FINAL_RGB_HLSL
#define XHD_PC_EYE_FINAL_RGB_HLSL
float3 XHD_PC_Eye_FinalRGB(
    float3 incomingRGB,       // r0.xyw before dp3
    float3 cb1_31_rgb,        // cb1[31].xyz
    float4 cb1_32,            // cb1[32]
    float3 v8_rgb,            // pixel shader COLOR1 v8.xyz
    float v6_w,               // pixel shader TEXCOORD2 v6.w
    bool selectCorrection)    // r0.z at final movc
{
    float luminance = dot(incomingRGB, float3(0.2989,0.5866,0.1145));
    float3 target = cb1_31_rgb + luminance * (cb1_32.rgb - cb1_31_rgb);
    float3 corrected = max(lerp(incomingRGB,target,cb1_32.w),float3(0,0,0));
    float3 uncorrected = lerp(incomingRGB,v8_rgb,v6_w);
    return selectCorrection ? corrected : uncorrected;
}
#endif

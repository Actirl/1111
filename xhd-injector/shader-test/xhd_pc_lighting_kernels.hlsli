// XHDLook PC original-lighting kernels, transcribed from captured Mega39's+ DXBC.
// Source: xhd_target_original_runtime.asm, lines 265-276, 304-309, 351-360.
// These are PC baseline kernels, NOT claimed to be PS4 XHD kernels.
// Caller must supply valid resources and reproduce the original control-flow flags.
#ifndef XHDLOOK_PC_LIGHTING_KERNELS
#define XHDLOOK_PC_LIGHTING_KERNELS

// Original shadow: compare shadow depth against projected depth,
// exponential softness, upper clamp, fourth-power normal term, then min.
float XHDPCShadow(float shadowDepth, float projectedDepth,
                  float sceneShadowScale, float materialShadowScale,
                  float3 sceneLightDir, float3 normalInSameSpace)
{
    float comparison = min(exp((shadowDepth - projectedDepth)
                           * sceneShadowScale * materialShadowScale), 1.0);
    float ndl = min(dot(sceneLightDir, normalInSameSpace) + 1.0, 1.0);
    float angular = ndl * ndl;
    angular *= angular;
    return min(comparison, angular);
}

// Original IBL diffuse blend: two explicit cube LODs,
// interpolate from the second to the first with original shadow amount.
// t9, s9, UV transform and branch gating must be supplied by caller.
float3 XHDPCDiffuseIBLBlend(float3 iblLod0, float3 iblLod1, float shadowFactor)
{
    return mad(shadowFactor, iblLod0 - iblLod1, iblLod1);
}

// Original specular roughness blend: t11 to t10 using cb2[31].x
// This is NOT a complete specular BRDF; subsequent clamping, shadow and
// material multipliers must be reproduced from the following DXBC instructions.
float3 XHDPCSpecularIBLBlend(float3 iblSpecularRough,
                            float3 iblSpecularSharp, float materialRoughBlend)
{
    return mad(materialRoughBlend,
               iblSpecularSharp - iblSpecularRough, iblSpecularRough);
}
#endif

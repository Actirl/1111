// PC Mega39's+ auxiliary MRT reconstruction from original captured DXBC.
// Verified against original_pc_shader.asm instructions ubfe through mov o1.yz.
// This is a structural transcription of the PC program, not a PS4 XHD shader.
// The inputs MUST use the original v1.xyz and untouched cb0/cb1/cb2 values.
#ifndef XHD_PC_AUX_MRT
#define XHD_PC_AUX_MRT
float4 XHDPCOriginalAux(float3 vertexNormal, uint4 flags,
                         float4 scene31, float4 scene32,
                         float4 scene58, float4 scene59,
                         float4 material30)
{
    float3 n = normalize(vertexNormal);
    // Original DXBC: ubfe r0.xyzw, (2,1,1,1), (2,8,10,9), cb0[0].wwxz
    uint extractedMode = (flags.x >> 10) & 1u;
    bool mode = extractedMode == 1u;
    bool bit31 = (flags.y >> 31) == 1u;
    float transformY = dot(scene58.xyz, n);
    float transformZ = dot(scene59.xyz, n) + 2.0;
    float chosenY = material30.w < 0.15 ? 100.0 : transformY;
    float2 yz = bit31 ? float2(chosenY, transformZ) : float2(0.0,0.0);

    // DXBC: add r5.xyz, cb1[31].xyz, -cb1[32].xyz;
    // dp3; eq zero; ge cb1[32].w 1; and.
    float3 difference = scene31.xyz - scene32.xyz;
    bool sceneEqual = dot(difference,difference)==0.0;
    bool fullWeight = scene32.w>=1.0;
    bool override = mode && sceneEqual && fullWeight;

    // DXBC: movc r5, overrideCondition, (0,100,0,1), r4.wyzw;
    // movc r4, mode, r5, r4;
    if (override) yz=float2(100.0,0.0);

    bool bitW = (flags.w & 1u)!=0u;
    float outX = override ? 0.0 : (bitW ? 1.0 : 0.0);
    float outW = override ? 1.0 : (bitW ? 0.0 : 0.01);
    return float4(outX,yz.x,yz.y,outW);
}
#endif

// EXPERIMENTAL partial reconstruction of PC Mega39's+ auxiliary MRT output.
// Based on xhd_target_original_runtime.asm lines 223-251 and 380.
// Important: PC reference path only; not proof of XHD/PS4 equivalence.
// Inputs correspond to original v1 normal and cb0/b1/b2 states.
// STOPSHIP: this draft does not yet preserve the complete DXBC r4/r5 conditional
// semantics. Do NOT include it in a shipping shader or present it as exact.
#ifndef XHD_PC_AUX_MRT
#define XHD_PC_AUX_MRT

float4 XHDPCOriginalAux(
    float3 vertexNormal,
    uint4 shaderFlags,    // cb0[0], BITWISE uint view REQUIRED
    float4 scene31,      // cb1[31]
    float4 scene32,      // cb1[32]
    float4 scene58,      // cb1[58]
    float4 scene59,      // cb1[59]
    float4 material30)   // cb2[30], material emission
{
    float3 v1norm=normalize(vertexNormal);
    bool bit31=((shaderFlags.y>>31)&1u)!=0u;
    float y=dot(scene58.xyz,v1norm);
    float z=dot(scene59.xyz,v1norm)+2.0;
    float variant=(material30.w<0.15)?100.0:y;
    float2 stateYZ=bit31?float2(variant,z):float2(0,0);

    bool identicalScene=all(scene31.xyz==scene32.xyz);
    bool fullSceneWeight=scene32.w>=1.0;
    bool cond=identicalScene && fullSceneWeight;
    // Original initial r0.z derives from ubfe/ieq in the PC shader header.
    // DXBC bitfield extraction and comparison need verification;
    // a one-bit test below is only a hypothesis, NOT an exact reconstruction.
    bool mode=((shaderFlags.x>>10)&1u)!=0u;
    float4 r4=float4(0,stateYZ.x,stateYZ.y,0);
    float4 r5=cond?float4(0,100,0,1):r4;
    if(mode)r4=r5;
    bool preferR4=mode&&cond;
    bool wBit=(shaderFlags.w&1u)!=0u;
    float fallbackX=wBit?1.0:0.0;
    float fallbackW=wBit?0.0:0.01;
    float outX=preferR4?r4.x:fallbackX;
    float outW=preferR4?r4.w:fallbackW;
    return float4(outX,r4.y,r4.z,outW);
}
#endif

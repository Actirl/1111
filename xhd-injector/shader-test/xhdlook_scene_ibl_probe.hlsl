// XHD-Look: scene lighting + real PC IBL sampling, EXPERIMENTAL / NON-SHIPPING.
// Implements PC shadow sampling and a subset of NPR diffuse-IBL gating.\n// Remaining shader state branches and cb4 tonemapping still unverified.
// NOT XHD PS4 lighting. Do not install until verified.
#include "xhd_pc_aux_mrt.hlsli"
#include "xhd_pc_lighting_kernels.hlsli"
Texture2D<float4> Diffuse:register(t0);
Texture2D<float4> NormalMap:register(t2);
Texture2D<float4> SpecMap:register(t3);
TextureCube<float4> IBLLow:register(t9);
TextureCube<float4> IBLSharp:register(t10);
TextureCube<float4> IBLRough:register(t11);
Texture2D<float4> ShadowDepth:register(t19);
SamplerState S0:register(s0);
SamplerState S2:register(s2);
SamplerState S3:register(s3);
SamplerState S9:register(s9);
SamplerState S10:register(s10);
SamplerState ShadowS:register(s7);
cbuffer ShaderState:register(b0) { uint4 shaderState; };
cbuffer Scene:register(b1) { float4 sceneRegisters[78]; };
cbuffer Batch:register(b2) { float4 batchRegisters[51]; };
cbuffer NPRParam:register(b4) { float4 nprRegisters[14]; };
cbuffer XHDControl:register(b12) {
 uint4 Flags; float4 Eye; float4 Skin; float4 Hair; float4 Cloth;
};
struct Input {
 float4 pos:SV_POSITION; float3 normal:NORMAL0;
 float3 tangent:TANGENT0; float3 binormal:BINORMAL0;
 float4 uv:TEXCOORD0; float3 uv1:TEXCOORD1; float4 uv2:TEXCOORD2;
 float4 col0:COLOR0; float4 col1:COLOR1;
 float4 shadowProject:TEXCOORD3; // original PC PS v6.xy = shadow UV; v6.z = projected depth
};
struct Output { float4 color:SV_Target0; float4 aux:SV_Target1; };
float3 safeNormalize(float3 v) {return v*rsqrt(max(dot(v,v),1e-8));}
Output Main(Input i) {
 float4 base=Diffuse.Sample(S0,i.uv.xy);
 float2 xy=NormalMap.Sample(S2,i.uv.xy).xy*2-1;
 float2 pxy=1.5*xy+2.0*xy.y*xy.y*xy.y;
 float3 N=safeNormalize(i.normal+i.tangent*pxy.x+i.binormal*pxy.y);
 float3 S=SpecMap.Sample(S3,i.uv.xy).rgb;
 float3 L=safeNormalize(sceneRegisters[26].xyz);
 float4 tune=Eye;
 float nl=saturate((dot(N,L)+saturate(tune.w))/(1.0+saturate(tune.w)));
 float diffuse=saturate(lerp(nl,smoothstep(0,1,nl),saturate(tune.y)));
 float3 ambient=max(sceneRegisters[15].rgb,saturate(tune.x).xxx);
 float3 direct=max(sceneRegisters[14].rgb,0)*diffuse;
 float3 matDiffuse=max(batchRegisters[28].rgb,0);
 float3 matEmissive=max(batchRegisters[30].rgb,0);
 float3 matSpecular=max(batchRegisters[32].rgb,0);
 // Probe: t9/t10/t11 from captured PC resource layout, not PS4 evidence.
 // Reflection and normal transforms follow PC DXBC cb1[42..44] pattern; the
 // view-direction mapping is provisional. Both specular cubes use sampler s10.
 // PC DXBC maps local normal / reflection via cb1[42..44].xyz.
 // Eye direction and normal interpolant spaces still need runtime confirmation.
 float3 localView=safeNormalize(i.uv1.xyz);
 float3 reflected=2.0*dot(localView,N)*N-localView;
 float3 iblDirection=safeNormalize(float3(
   dot(sceneRegisters[42].xyz,-reflected),
   dot(sceneRegisters[43].xyz,-reflected),
   dot(sceneRegisters[44].xyz,-reflected)));
 float3 diffuseDirection=safeNormalize(float3(
   dot(sceneRegisters[42].xyz,N),
   dot(sceneRegisters[43].xyz,N),
   dot(sceneRegisters[44].xyz,N)));
 // PC DXBC uses cb2[50].x bit 15 to select cb4[5].z/.w,
 // then checks whether the resulting diffuse-IBL gain is positive.
 bool nprSwitch=((asuint(batchRegisters[50].x)>>15)&1u)!=0u;
 float diffuseGain=nprSwitch?nprRegisters[5].z:nprRegisters[5].w;
 float3 diffuseLod0=IBLLow.SampleLevel(S9,diffuseDirection,0).rgb;
 float3 diffuseLod1=IBLLow.SampleLevel(S9,diffuseDirection,1).rgb;
 // Original PC shadow draw uses v6.xy / v6.z, t19+s7 and cb1[45].x*cb2[30].w.
 // The original branch predicate is still pending: this variant samples unconditionally.
 float depth=ShadowDepth.Sample(ShadowS,i.shadowProject.xy).x;
 float shadowFactor=XHDPCShadow(depth,i.shadowProject.z,sceneRegisters[45].x,
                               batchRegisters[30].w,L,N);
 float3 diffuseIBL=diffuseGain>0.0?XHDPCDiffuseIBLBlend(diffuseLod0,diffuseLod1,shadowFactor):float3(1,1,1);
 float3 sharpIBL=IBLSharp.Sample(S10,iblDirection).rgb;
 float3 roughIBL=IBLRough.Sample(S10,iblDirection).rgb;
 float3 specIBL=XHDPCSpecularIBLBlend(roughIBL,sharpIBL,saturate(batchRegisters[31].x));
 float3 lit=base.rgb*matDiffuse*(ambient+direct+0.15*diffuseIBL);
 lit+=matEmissive+S*matSpecular*specIBL*saturate(tune.z)*0.15;
 Output o;
 o.color=float4(saturate(lit),base.a);
 o.aux=XHDPCOriginalAux(i.normal,shaderState,sceneRegisters[31],sceneRegisters[32],
                        sceneRegisters[58],sceneRegisters[59],batchRegisters[30]);
 return o;
}

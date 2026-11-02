// XHD-Look: scene lighting + real PC IBL sampling, EXPERIMENTAL / NON-SHIPPING.
// Does not implement PC shadow projection or XHD PS4 lighting. Do not install.
#include "xhd_pc_aux_mrt.hlsli"
#include "xhd_pc_lighting_kernels.hlsli"
Texture2D<float4> Diffuse:register(t0);
Texture2D<float4> NormalMap:register(t2);
Texture2D<float4> SpecMap:register(t3);
TextureCube<float4> IBLLow:register(t9);
TextureCube<float4> IBLSharp:register(t10);
TextureCube<float4> IBLRough:register(t11);
SamplerState S0:register(s0);
SamplerState S2:register(s2);
SamplerState S3:register(s3);
SamplerState S9:register(s9);
SamplerState S10:register(s10);
SamplerState S11:register(s11);
cbuffer ShaderState:register(b0) { uint4 shaderState; };
cbuffer Scene:register(b1) { float4 sceneRegisters[78]; };
cbuffer Batch:register(b2) { float4 batchRegisters[51]; };
cbuffer XHDControl:register(b12) {
 uint4 Flags; float4 Eye; float4 Skin; float4 Hair; float4 Cloth;
};
struct Input {
 float4 pos:SV_POSITION; float3 normal:NORMAL0;
 float3 tangent:TANGENT0; float3 binormal:BINORMAL0;
 float4 uv:TEXCOORD0; float3 uv1:TEXCOORD1; float4 uv2:TEXCOORD2;
 float4 col0:COLOR0; float4 col1:COLOR1;
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
 // Cube coordinates and LOD numbers are provisional and must be checked.
 float3 iblDirection=N;
 float3 diffuseIBL=IBLLow.SampleLevel(S9,iblDirection,0).rgb;
 float3 sharpIBL=IBLSharp.SampleLevel(S10,iblDirection,0).rgb;
 float3 roughIBL=IBLRough.SampleLevel(S11,iblDirection,0).rgb;
 float3 specIBL=XHDPCSpecularIBLBlend(roughIBL,sharpIBL,saturate(batchRegisters[31].x));
 float3 lit=base.rgb*matDiffuse*(ambient+direct+0.15*diffuseIBL);
 lit+=matEmissive+S*matSpecular*specIBL*saturate(tune.z)*0.15;
 Output o;
 o.color=float4(saturate(lit),base.a);
 o.aux=XHDPCOriginalAux(i.normal,shaderState,sceneRegisters[31],sceneRegisters[32],
                        sceneRegisters[58],sceneRegisters[59],batchRegisters[30]);
 return o;
}

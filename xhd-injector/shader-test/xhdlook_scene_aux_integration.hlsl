// Integration-only variant. Not shipping, because numeric PC light/aux behavior not GPU verified.
#include "xhd_pc_aux_mrt.hlsli"
Texture2D<float4> Diffuse:register(t0);
Texture2D<float4> NormalMap:register(t2);
Texture2D<float4> SpecMap:register(t3);
SamplerState S0:register(s0);
SamplerState S2:register(s2);
SamplerState S3:register(s3);
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
struct Output {float4 color:SV_Target0;float4 aux:SV_Target1;};
float3 safeNormal(float3 n){return normalize(n+float3(0,0,0.00001));}
Output Main(Input v){
 float4 base=Diffuse.Sample(S0,v.uv.xy);
 float2 xy=NormalMap.Sample(S2,v.uv.xy).xy*2-1;
 float2 perturb=1.5*xy+2*xy.y*xy.y*xy.y;
 float3 N=safeNormal(v.normal+v.tangent*perturb.x+v.binormal*perturb.y);
 float3 S=SpecMap.Sample(S3,v.uv.xy).rgb;
 float3 L=safeNormal(sceneRegisters[26].xyz);
 float4 p=Eye;
 float nl=saturate((dot(N,L)+saturate(p.w))/(1+saturate(p.w)));
 float stylized=lerp(nl,smoothstep(0,1,nl),saturate(p.y));
 float3 ambient=max(sceneRegisters[15].rgb,0);
 float3 diffuse=max(sceneRegisters[14].rgb,0);
 float3 material=max(batchRegisters[28].rgb,0);
 float3 emission=max(batchRegisters[30].rgb,0);
 float3 spec=max(sceneRegisters[16].rgb,0)*max(batchRegisters[32].rgb,0);
 float3 color=base.rgb*material*(max(ambient,saturate(p.x).xxx)+diffuse*stylized)+emission;
 color+=0.05*S*spec*pow(saturate(dot(N,L)),8)*saturate(p.z);
 Output o;
 o.color=float4(saturate(color),base.a);
 // Original PC auxiliary function uses *vertex* normal, not perturbed normal.
 o.aux=XHDPCOriginalAux(v.normal,shaderState,sceneRegisters[31],sceneRegisters[32],
                        sceneRegisters[58],sceneRegisters[59],batchRegisters[30]);
 return o;
}

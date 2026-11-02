#include "xhd_pc_eye_ibl_combine.hlsl"
TextureCube<float4> environmentA:register(t10);
TextureCube<float4> environmentB:register(t11);
SamplerState environmentSampler:register(s10);
struct In {float4 pos:SV_Position;float3 direction:TEXCOORD0;float4 params:TEXCOORD1;};
float4 Main(In i):SV_Target0 {
 float3 dir=normalize(i.direction);
 float3 a=environmentA.Sample(environmentSampler,dir).rgb;
 float3 b=environmentB.Sample(environmentSampler,dir).rgb;
 XHD_IBL_Result result=XHD_PC_Eye_IBLCombine(b,a,i.params.x,float3(0.8,0.8,0.8),i.params.y,float3(1,1,1),float3(0,0,0));
 return float4(result.accumulatedRGB,1.0);
}

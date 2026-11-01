// Integration harness only. This is NOT a game-compatible eye replacement.
// Isolated diagnostic slots t24-t27, NOT confirmed free in every original PC draw.\n// Runtime SRV binding and real PS4 texture arrays are REQUIRED before game use.
#include "xhd_sampling_common.hlsl"
#include "xhd_rt1_captured_draw.hlsl"
Texture2D<float4> ps4B5 : register(t24);
Texture2DArray<float4> ps4B6 : register(t25);
Texture2DArray<float4> ps4B7Array : register(t26);
Texture2D<float4> ps4B7Flat : register(t27);
SamplerState sm5 : register(s0);
SamplerState sm6 : register(s1);
SamplerState sm7 : register(s2);
struct Input {float4 pos:SV_Position;float2 uv:TEXCOORD0;float3 normal:TEXCOORD1;};
struct Output {float4 color:SV_Target0;float4 auxiliary:SV_Target1;};
Output Integrated144(Input i) {
 XHD_Binding5Input v=(XHD_Binding5Input)0;
 v.v173=0.5;v.v170=0.5;v.v179=i.uv.x;v.v186=i.uv.y;
 XHD_Draw144SampleResult s=XHD_Draw144SecondSamples(ps4B5,sm5,ps4B6,sm6,ps4B7Array,sm7,v,1,1,1,1,1,1,1,1,1,1,1,1,1);
 Output o;o.color=s.b6+s.b7*0.25;
 o.auxiliary=XHD_PC_RT1_CapturedDraw(i.normal);return o;
}
Output Integrated220(Input i) {
 XHD_Draw220SampleResult s=XHD_Draw220SamplePaths(ps4B5,sm5,ps4B6,sm6,ps4B7Flat,sm7,i.uv,float3(i.uv,0),float3(i.uv,0),i.uv,1,1,1,1,1,1);
 Output o;o.color=s.b6First+s.b6Second*0.25+s.b7*0.25;
 o.auxiliary=XHD_PC_RT1_CapturedDraw(i.normal);return o;
}

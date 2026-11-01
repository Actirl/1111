#include "xhd_sampling_common.hlsl"
Texture2D<float4> input5 : register(t0);
Texture2DArray<float4> input6 : register(t1);
Texture2DArray<float4> input7Array : register(t2);
Texture2D<float4> input7Flat : register(t3);
SamplerState sample5 : register(s0);
SamplerState sample6 : register(s1);
SamplerState sample7 : register(s2);
struct PSIn { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
struct PSOut { float4 color : SV_Target0; float4 auxiliary : SV_Target1; };
PSOut PSMain144(PSIn i) {
 XHD_Binding5Input v = (XHD_Binding5Input)0;
 v.v173=0.5; v.v170=0.5; v.v179=i.uv.x; v.v186=i.uv.y;
 XHD_Draw144SampleResult o=XHD_Draw144SecondSamples(input5,sample5,input6,sample6,input7Array,sample7,v,1,1,1,1,1,1,1,1,1,1,1,1,1);
 PSOut result; result.color=o.b6+o.b7*0.25;
 result.auxiliary=float4(o.factor,o.lod6,o.lod7,1);
 return result;
}
PSOut PSMain220(PSIn i) {
 XHD_Draw220SampleResult o=XHD_Draw220SamplePaths(input5,sample5,input6,sample6,input7Flat,sample7,i.uv,float3(i.uv,0),float3(i.uv,0),i.uv,1,1,1,1,1,1);
 PSOut result; result.color=o.b6First+o.b6Second*0.25+o.b7*0.25;
 result.auxiliary=float4(o.lod6First,o.lod6Second,1,1);
 return result;
}

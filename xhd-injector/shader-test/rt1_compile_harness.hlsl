#include "xhd_rt1_captured_draw.hlsl"
struct PSInput {float4 pos:SV_Position;float3 interpolatedV1:TEXCOORD0;};
struct PSOutput {float4 mainColor:SV_Target0;float4 auxiliary:SV_Target1;};
PSOutput PSRT1CapturedDrawTest(PSInput i) {
 PSOutput o;o.mainColor=float4(0,0,0,1); // placeholder, NOT original RGB
 o.auxiliary=XHD_PC_RT1_CapturedDraw(i.interpolatedV1);return o;
}

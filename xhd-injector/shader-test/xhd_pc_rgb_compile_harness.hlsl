// Standalone compile harness for original PC final RGB transform.
// This is a compile test, NOT a replacement shader.
#include "xhd_pc_eye_final_rgb.hlsl"
struct VS2PS {
 float4 pos : SV_Position;
 float3 inputColor : TEXCOORD0;
 float3 correctionMin : TEXCOORD1;
 float4 correctionMax : TEXCOORD2;
 float3 vertexColor : TEXCOORD3;
 float transition : TEXCOORD4;
 float selector : TEXCOORD5;
};
float4 Main(VS2PS i) : SV_Target0 {
 float3 c = XHD_PC_Eye_FinalRGB(
   i.inputColor,i.correctionMin,i.correctionMax,
   i.vertexColor,i.transition,i.selector!=0.0);
 return float4(c,1.0);
}

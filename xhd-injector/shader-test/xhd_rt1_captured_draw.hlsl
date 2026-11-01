// Original PC Mega39's+ eye SV_Target1: THIS captured Draw fixture only.
// Not the PS4 X HD original renderer; do not use as replacement.cso.
#ifndef XHD_RT1_CAPTURED_DRAW_HLSL
#define XHD_RT1_CAPTURED_DRAW_HLSL
float4 XHD_PC_RT1_CapturedDraw(float3 interpolatedV1) {
    float invLen=rsqrt(max(dot(interpolatedV1,interpolatedV1),1.0e-20));
    float3 n=interpolatedV1*invLen;
    float2 yz=float2(dot(float3(1,0,0),n),
       dot(float3(0,0.999951958656311,-0.009803487919270992),n))+2.0;
    return float4(0.0,yz.x,yz.y,0.01);
}
#endif

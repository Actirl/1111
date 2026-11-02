// Experimental eye shading: real XHD/PC matching iris texture t0, subdued cyan highlights.
// Not a complete PS4 X HD shader port. Preserves two render target signatures.
Texture2D<float4> iris : register(t0);
SamplerState irisSampler : register(s0);
struct PSInput {
 float4 position : SV_POSITION;
 float3 normal : NORMAL0;
 float3 tangent : TANGENT0;
 float3 binormal : BINORMAL0;
 float4 texcoord0 : TEXCOORD0;
 float3 texcoord1 : TEXCOORD1;
 float4 texcoord2 : TEXCOORD2;
 float4 color0 : COLOR0;
 float4 color1 : COLOR1;
};
struct PSOutput {float4 color:SV_Target0; float4 aux:SV_Target1;};
PSOutput Main(PSInput v) {
 float4 src=iris.Sample(irisSampler,v.texcoord0.xy);
 float3 c=max(src.rgb,0.0);
 // Original iris texture is preserved; compress excessive cyan/white highlights.
 float peak=max(c.r,max(c.g,c.b));
 float compression=1.0/(1.0+0.22*peak);
 c=saturate(pow(c*compression,0.88));
 // Add modest cyan/blue-aware ambient instead of flat diagnostic magenta.
 c=saturate(c*0.90 + float3(0.025,0.035,0.040));
 float3 n=normalize(v.normal);
 PSOutput o;
 o.color=float4(c,src.a);
 // Captured single-draw approximation, not verified universal PC RT1 ABI.
 o.aux=float4(0.0,2.0+n.x,2.0+0.9999519587*n.y-0.0098034879*n.z,0.01);
 return o;
}

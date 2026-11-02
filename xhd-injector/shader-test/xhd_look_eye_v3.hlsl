// XHD-Look Eye v3: stylized eye readability test, NOT PS4 shader equivalence.
Texture2D<float4> IrisTexture : register(t0);
SamplerState IrisSampler : register(s0);
struct PSInput {
 float4 position:SV_POSITION;
 float3 normal:NORMAL0;
 float3 tangent:TANGENT0;
 float3 binormal:BINORMAL0;
 float4 texcoord0:TEXCOORD0;
 float3 texcoord1:TEXCOORD1;
 float4 texcoord2:TEXCOORD2;
 float4 color0:COLOR0;
 float4 color1:COLOR1;
};
struct PSOutput { float4 color:SV_Target0; float4 aux:SV_Target1; };
PSOutput Main(PSInput v) {
 float4 sampleColor = IrisTexture.Sample(IrisSampler, v.texcoord0.xy);
 float3 c = saturate(sampleColor.rgb);
 float3 lift = 0.24 * c * (1.0-c)*(1.0-c);
 float3 lifted = c + lift;
 float3 knee = saturate((lifted - 0.72) / 0.28);
 knee = knee*knee*(3.0-2.0*knee);
 float3 compressed = lerp(lifted, 0.72 + 0.28*(1.0-exp(-2.0*max(lifted-0.72,0.0)/0.28)), knee*0.35);
 float originalY = dot(c,float3(0.2126,0.7152,0.0722));
 float newY = dot(compressed,float3(0.2126,0.7152,0.0722));
 float lumDiff = newY-originalY;
 float3 finalColor = saturate(c + float3(lumDiff,lumDiff,lumDiff)*0.92 + (compressed-c)*0.08);
 float3 n = normalize(v.normal);
 PSOutput o;
 o.color=float4(finalColor,sampleColor.a);
 // Preserved legacy diagnostic RT1; scene-specific approximation; not PS4/PC ABI-equivalent.
 o.aux=float4(0.0,2.0+n.x,2.0+0.9999519587*n.y-0.0098034879*n.z,0.01);
 return o;
}

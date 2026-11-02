// XHD-like soft cyan V2 experiment, not a verified PS4 shader port.
Texture2D<float4> iris:register(t0);
SamplerState irisSampler:register(s0);
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
struct PSOutput {float4 color:SV_Target0;float4 aux:SV_Target1;};
PSOutput Main(PSInput v){
 float4 src=iris.Sample(irisSampler,v.texcoord0.xy);
 float3 c=saturate(src.rgb);
 float mx=max(c.r,max(c.g,c.b));
 float mn=min(c.r,min(c.g,c.b));
 float chroma=mx-mn;
 float high=smoothstep(0.82,0.99,mx);
 float lowChroma=1.0-smoothstep(0.12,0.34,chroma);
 float whitePeak=high*lowChroma;
 c=lerp(c,c*0.90,whitePeak);
 float cyan=saturate((c.b+c.g)*0.5-c.r);
 float boost=smoothstep(0.08,0.35,cyan)*saturate(chroma*3.0);
 c=saturate(lerp(c,float3(c.r*0.96,c.g*1.055,c.b*1.085),boost*0.75));
 float3 n=normalize(v.normal);
 PSOutput o;
 o.color=float4(c,src.a);
 o.aux=float4(0.0,2.0+n.x,2.0+0.9999519587*n.y-0.0098034879*n.z,0.01);
 return o;
}

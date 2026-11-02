Texture2D<float4> Diffuse:register(t0);
Texture2D<float4> NormalMap:register(t2);
Texture2D<float4> SpecMap:register(t3);
SamplerState S0:register(s0);
SamplerState S2:register(s2);
SamplerState S3:register(s3);
cbuffer XHDControl:register(b12) {
 uint4 Flags;
 float4 Eye;
 float4 Skin;
 float4 Hair;
 float4 Cloth;
};
struct IN {
 float4 pos:SV_POSITION; float3 n:NORMAL0; float3 t:TANGENT0;
 float3 b:BINORMAL0; float4 uv:TEXCOORD0; float3 uv1:TEXCOORD1;
 float4 uv2:TEXCOORD2; float4 c:COLOR0; float4 c1:COLOR1;
};
struct OUT {float4 rgb:SV_Target0;float4 aux:SV_Target1;};
OUT Main(IN i) {
 float4 base=Diffuse.Sample(S0,i.uv.xy);
 float3 bump=NormalMap.Sample(S2,i.uv.xy).xyz*2-1;
 float3 spec=SpecMap.Sample(S3,i.uv.xy).rgb;
 bool active=(Flags.x==0x5848444c && Flags.y==2 && Flags.w!=0);
 float4 p=active?Eye:float4(0.32,0.40,0.35,0.25);
 float3 n=normalize(i.n);
 float shade=saturate((dot(n,normalize(float3(0.25,0.35,0.90)))+p.w)/(1+p.w));
 shade=lerp(shade,0.60+0.40*shade,saturate(p.y));
 float ambient=saturate(p.x);
 float3 color=base.rgb*(ambient+(1-ambient)*shade);
 color+=0.045*spec*saturate(bump.z)*saturate(p.z);
 // Soft shoulder, not global exposure
 float3 knee=saturate((color-0.78)/0.22);
 float3 shoulder=0.78+0.22*(1-exp(-max(color-0.78,0)/0.22));
 color=lerp(color,shoulder,knee*0.5);
 OUT o;
 o.rgb=float4(saturate(color),base.a);
 o.aux=float4(0,2+n.x,2+0.9999519587*n.y-0.0098034879*n.z,0.01);
 return o;
}

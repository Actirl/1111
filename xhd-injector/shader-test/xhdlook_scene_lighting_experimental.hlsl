// XHD-Look scene-aware material lighting PROTOTYPE.
// Unlike the old fixed-light diagnostic, this reads the game's live Scene/Batch data.
// Not a PS4/XHD port. Not suitable for installation until SV_Target1 is decoded.
Texture2D<float4> Diffuse:register(t0);
Texture2D<float4> NormalMap:register(t2);
Texture2D<float4> SpecMap:register(t3);
SamplerState S0:register(s0);
SamplerState S2:register(s2);
SamplerState S3:register(s3);

// EXPERIMENTAL assumptions about Scene/Batch offsets; must be checked against
// original PC Shader disassembly, GPU values and the relevant coordinate spaces.
cbuffer Scene:register(b1) { float4 sceneRegisters[78]; };
cbuffer Batch:register(b2) { float4 batchRegisters[51]; };
cbuffer XHDControl:register(b12) {
 uint4 Flags;
 float4 Eye;
 float4 Skin;
 float4 Hair;
 float4 Cloth;
};
struct Input {
 float4 pos:SV_POSITION; float3 normal:NORMAL0;
 float3 tangent:TANGENT0; float3 binormal:BINORMAL0;
 float4 uv:TEXCOORD0; float3 uv1:TEXCOORD1; float4 uv2:TEXCOORD2;
 float4 col0:COLOR0; float4 col1:COLOR1;
};
struct Output { float4 color:SV_Target0; float4 aux:SV_Target1; };
float3 safeNormal(float3 n) { return normalize(n + float3(0,0,1e-5)); }
Output Main(Input v) {
 float4 base=Diffuse.Sample(S0,v.uv.xy);
 float3 normalTex=NormalMap.Sample(S2,v.uv.xy).xyz*2.0-1.0;
 float3 specTex=SpecMap.Sample(S3,v.uv.xy).rgb;
 float3 n=safeNormal(v.normal);
 // Convert sampled tangent-space normal into the interpolated basis.
 // Basis handedness and direction still require in-game verification.
 float3 t=safeNormal(v.tangent-n*dot(n,v.tangent));
 float3 b=safeNormal(v.binormal-n*dot(n,v.binormal)-t*dot(t,v.binormal));
 float3 surfaceNormal=safeNormal(t*normalTex.x+b*normalTex.y+n*normalTex.z);
 // PC Scene: [14] chara diffuse, [15] ambient, [16] specular, [26] light direction.
 float3 ambient=max(sceneRegisters[15].rgb,0.0);
 float3 diffuseColor=max(sceneRegisters[14].rgb,0.0);
 float3 specColor=max(sceneRegisters[16].rgb,0.0);
 float3 lightDir=safeNormal(sceneRegisters[26].xyz);
 // PC Batch: [28] material diffuse, [30] emission, [31] shininess, [32] specular.
 float3 materialDiffuse=max(batchRegisters[28].rgb,0.0);
 float3 materialEmission=max(batchRegisters[30].rgb,0.0);
 float3 materialSpec=max(batchRegisters[32].rgb,0.0);
 bool live=Flags.x==0x5848444c && Flags.y==2 && Flags.w!=0;
 float4 p=live?Eye:float4(0.25,0.35,0.25,0.20);
 float wrap=saturate(p.w);
 float nl=saturate((dot(surfaceNormal,-lightDir)+wrap)/(1.0+wrap));
 float stylized=lerp(nl,smoothstep(0.0,1.0,nl),saturate(p.y));
 float3 shading=max(ambient,saturate(p.x).xxx)+diffuseColor*stylized;
 float3 result=base.rgb*materialDiffuse*shading+materialEmission;
 // Temporary light-facing highlight, not the original PC/PS4 specular BRDF.
 float highlight=pow(saturate(dot(surfaceNormal,-lightDir)),8);
 result+=0.05*specTex*materialSpec*specColor*highlight*saturate(p.z);
 Output o; o.color=float4(saturate(result),base.a);
 // STOPSHIP: placeholder RT1. No fidelity or installability guarantee.
 o.aux=float4(0,2+surfaceNormal.x,2+0.9999519587*surfaceNormal.y-0.0098034879*surfaceNormal.z,0.01);
 return o;
}

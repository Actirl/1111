// XHD-Look Eye v5 -- material-aware model for Mega39's+ XHD eyes.
// Not a PS4 shader port; maintains PC texture/register ABI and uses runtime scene illumination.
// SPECULATIVE: sclera classification, matte semantics, MRT1 are approximate; do not claim faithful XHD.
Texture2D<float4> TBase : register(t0);
Texture2D<float4> TNormal : register(t2);
Texture2D<float4> TMatte : register(t3);
TextureCube<float4> TEnvDiffuse : register(t9);
TextureCube<float4> TEnvA : register(t10);
TextureCube<float4> TEnvB : register(t11);
SamplerState SBase : register(s0);
SamplerState SNormal : register(s2);
SamplerState SMatte : register(s3);
SamplerState SEnv : register(s9);
SamplerState SEnvB : register(s10);
cbuffer Scene : register(b1) { float4 SC[78]; };
cbuffer Batch : register(b2) { float4 BA[51]; };
struct PSInput {
 float4 position:SV_POSITION;
 float3 normal:NORMAL0;
 float3 tangent:TANGENT0;
 float3 binormal:BINORMAL0;
 float4 uv:TEXCOORD0;
 float3 tc1:TEXCOORD1;
 float4 tc2:TEXCOORD2;
 float4 color0:COLOR0;
 float4 color1:COLOR1;
};
struct PSOutput { float4 color:SV_Target0; float4 aux:SV_Target1; };
float Luma(float3 a) { return dot(a,float3(0.2126,0.7152,0.0722)); }
float3 SafeNormal(float3 v) { return v*rsqrt(max(dot(v,v),1e-5)); }
PSOutput Main(PSInput i) {
 float4 albedo=TBase.Sample(SBase,i.uv.xy);
 float3 c=saturate(albedo.rgb);
 float3 nBase=SafeNormal(i.normal);
 float3 t=SafeNormal(i.tangent), b=SafeNormal(i.binormal);
 float3 bump=TNormal.Sample(SNormal,i.uv.xy).xyz*2.0-1.0;
 float3 normal=SafeNormal(nBase+0.21*(bump.x*t+bump.y*b));
 float4 matte=TMatte.Sample(SMatte,i.uv.xy);
 float y=Luma(c);
 float maximum=max(c.r,max(c.g,c.b));
 float minimum=min(c.r,min(c.g,c.b));
 float chroma=maximum-minimum;
 // Classifier respects dark pupils: only neutral and moderately bright pixels qualify as sclera.
 float whiteLikelihood=(1.0-smoothstep(0.09,0.23,chroma))*smoothstep(0.23,0.50,y);
 float irisLikelihood=smoothstep(0.09,0.27,chroma)*smoothstep(0.05,0.18,y);
 // Runtime lighting: use PC original constant buffer offsets for animated environment/characters.
 float3 lightDir=SafeNormal(-SC[26].xyz);
 float ndotl=saturate(dot(normal,lightDir));
 float diffuse=smoothstep(0.04,0.82,ndotl);
 float3 ambientColor=saturate(SC[15].rgb);
 float3 diffuseColor=saturate(SC[14].rgb);
 // Artistic diffuse: clamp diffuse response for soft sclera, without brightening all eye pixels.
 float lightSclera=lerp(0.68,0.95,diffuse);
 float lightIris=lerp(0.54,0.92,diffuse);
 float localLight=lerp(lightIris,lightSclera,whiteLikelihood);
 float3 matSurface=c*lerp(0.94,1.03,saturate(matte.r));
 float3 shaded=matSurface*(ambientColor*0.55+diffuseColor*0.40*localLight+float3(0.35,0.35,0.35));
 float3 upColor=float3(0.91,0.94,0.98);
 float3 scleraTarget=max(shaded,upColor*0.64);
 shaded=lerp(shaded,scleraTarget,0.70*whiteLikelihood);
 // Depth for irises derives from local shading + bump detail, rather than a single RGB gain.
 shaded+=irisLikelihood*0.11*c*(1.0-c)*saturate(0.65+0.35*bump.z);
 // Image-based lighting, keeping the PC resource types (cubes), not equating to PS4 binding IDs.
 float3 viewDir=SafeNormal(-i.tc1.xyz);
 float3 reflected=reflect(-viewDir,normal);
 float3 envLow=TEnvDiffuse.SampleLevel(SEnv,normal,1).rgb;
 float3 envA=TEnvA.SampleLevel(SEnv,reflected,1).rgb;
 float3 envB=TEnvB.SampleLevel(SEnvB,reflected,2).rgb;
 float3 softEnv=saturate(0.6*envLow+0.25*envA+0.15*envB);
 float3 iridescence=softEnv*(0.045+0.080*irisLikelihood);
 shaded+=iridescence*(1.0-0.55*whiteLikelihood);
 // Filmic shoulder on light contribution only (avoid crushing iris texture).
 float3 clipPeak=max(shaded-0.78,0.0);
 shaded=shaded-clipPeak+0.22*(1.0-exp(-clipPeak/0.22));
 PSOutput o;
 o.color=float4(saturate(shaded),max(albedo.a,BA[39].w));
 // Legacy captured-draw RT1 approximation. Must compare with real PC RT1 across scenes before release.
 o.aux=float4(0.0,2.0+nBase.x,2.0+0.9999519587*nBase.y-0.0098034879*nBase.z,0.01);
 return o;
}

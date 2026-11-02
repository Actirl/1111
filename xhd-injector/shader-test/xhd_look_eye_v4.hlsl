// XHD-Look Eye v4: material-aware sclera/iris test. NOT a PS4 port.
// PC shader evidence: t0 base, t2 normal, t3 matte. Avoid assuming t3 is a sclera mask.
Texture2D<float4> baseTex : register(t0);
Texture2D<float4> normalTex : register(t2);
Texture2D<float4> matteTex : register(t3);
SamplerState baseSampler : register(s0);
SamplerState normalSampler : register(s2);
SamplerState matteSampler : register(s3);
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
float luminance(float3 v) { return dot(v,float3(0.2126,0.7152,0.0722)); }
PSOutput Main(PSInput v) {
 float2 uv=v.texcoord0.xy;
 float4 base=baseTex.Sample(baseSampler,uv);
 float4 mat=matteTex.Sample(matteSampler,uv);
 float3 nTex=normalTex.Sample(normalSampler,uv).xyz*2.0-1.0;
 float3 n=normalize(v.normal);
 float3 detailN=normalize(float3(nTex.xy, max(0.16,abs(nTex.z))));
 float ndotl=saturate(dot(n,normalize(float3(0.25,0.35,0.90))));
 // Reduce angular contrast rather than applying exposure to whole eye.
 float stylizedDiffuse=lerp(0.72,1.0,smoothstep(0.06,0.85,ndotl));
 stylizedDiffuse*=lerp(0.95,1.0,saturate(detailN.z));
 float3 c=saturate(base.rgb);
 float mx=max(c.r,max(c.g,c.b));
 float mn=min(c.r,min(c.g,c.b));
 float chroma=mx-mn;
 float y=luminance(c);
 // Neutral pixels are candidates for sclera; texture-only heuristic, NOT semantic mask.
 // Dark pupil and eyelashes are excluded by luminance gate.
 float neutral=1.0-smoothstep(0.09,0.27,chroma);
 float scleraCandidate=neutral*smoothstep(0.15,0.34,y);
 float irisCandidate=(1.0-neutral)*smoothstep(0.07,0.24,y);
 // Bounded white floor only for likely sclera; preserve cool gray tint and edge details.
 float scleraFloor=lerp(0.45,0.70,saturate(mat.r));
 float3 sclera=max(c,float3(scleraFloor,scleraFloor,scleraFloor)*float3(0.96,0.98,1.0));
 c=lerp(c,sclera,0.68*scleraCandidate);
 // Iris microcontrast: soft toe for darker colors, preserving local chroma.
 float3 irisToe=c + 0.17*c*(1.0-c)*(1.0-c);
 c=lerp(c,irisToe,irisCandidate);
 // Stylized ambient response with diffuse shaping.
 float3 lit=c*stylizedDiffuse + c*(1.0-stylizedDiffuse)*0.36;
 // Compress upper highlights without washing out midtones.
 float3 knee=saturate((lit-0.78)/0.22);
 float3 shoulder=0.78+0.22*(1.0-exp(-max(lit-0.78,0.0)/0.22));
 lit=lerp(lit,shoulder,knee*0.65);
 PSOutput o;
 o.color=float4(saturate(lit),base.a);
 // Single-draw auxiliary approximation inherited from earlier tests (NOT ABI-equivalent).
 o.aux=float4(0.0,2.0+n.x,2.0+0.9999519587*n.y-0.0098034879*n.z,0.01);
 return o;
}

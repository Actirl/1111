#ifndef XHD_SAMPLING_COMMON
#define XHD_SAMPLING_COMMON
struct XHD_Binding5Input {float v194,v192,v173,v182,v170,v179;float v200,v198,v189,v186;};
float2 XHD_Binding5UV(XHD_Binding5Input x) {
return float2(mad(x.v194-x.v192,x.v173,mad(x.v182,x.v170,x.v179)),mad(x.v200-x.v198,x.v173,mad(x.v189,x.v170,x.v186)));
}
float XHD_Draw144_LayerB(float v1526,float v545,float v548,float v547) {
float l01=v545<0?1:0,l23=v548<0?3:2,l45=v547<0?5:4;
return (v1526>abs(v545) && v1526>abs(v548))?l45:(abs(v548)>abs(v545)?l23:l01);
}
struct XHD_Draw144SampleResult {float4 b6;float4 b7;float factor;float lod6;float lod7;};
XHD_Draw144SampleResult XHD_Draw144SecondSamples(
Texture2D<float4> b5,SamplerState s5,Texture2DArray<float4> b6,SamplerState s6,
Texture2DArray<float4> b7,SamplerState s7,XHD_Binding5Input x,
float v1515,float v1460,float v1500,float v1526,float v545,float v548,float v547,
float v1534,float v1538,float v1540,float v1539,float v1462,float v1554) {
XHD_Draw144SampleResult o;
o.factor=b5.Sample(s5,XHD_Binding5UV(x)).r;
float u=mad(v1515,v1500,1.5)-1, v=mad(v1460,v1500,1.5)-1;
float layer=XHD_Draw144_LayerB(v1526,v545,v548,v547);
float a=mad(v1538,v1540,v1539),b=mad(v1554,v1540,v1539);
o.lod6=mad(v1534-a,o.factor,a);o.lod7=mad(v1462-b,o.factor,b);
o.b6=b6.SampleLevel(s6,float3(u,v,layer),o.lod6);
o.b7=b7.SampleLevel(s7,float3(u,v,layer),o.lod7);
return o;
}
struct XHD_Draw220LOD {float first;float second;};
XHD_Draw220LOD XHD_Draw220_LODs(float factor,float v1284,float v530,float v1387,float v1389,float v1391,float v1390){
XHD_Draw220LOD o;o.first=v1284*factor;float baseLod=mad(v1389,v1391,v1390);
o.second=mad(factor,v530*v1387-baseLod,baseLod);return o;
}
struct XHD_Draw220SampleResult {float4 b6First;float4 b6Second;float4 b7;float lod6First;float lod6Second;};
XHD_Draw220SampleResult XHD_Draw220SamplePaths(
Texture2D<float4> b5,SamplerState s5,Texture2DArray<float4> b6,SamplerState s6,
Texture2D<float4> b7,SamplerState s7,float2 uv5,float3 uvw6First,
float3 uvw6Second,float2 uv7,float v1284,float v530,float v1387,
float v1389,float v1391,float v1390){
XHD_Draw220SampleResult o;float factor=b5.Sample(s5,uv5).r;
XHD_Draw220LOD l=XHD_Draw220_LODs(factor,v1284,v530,v1387,v1389,v1391,v1390);
o.lod6First=l.first;o.lod6Second=l.second;
o.b6First=b6.SampleLevel(s6,uvw6First,l.first);
o.b6Second=b6.SampleLevel(s6,uvw6Second,l.second);
o.b7=b7.SampleLevel(s7,uv7,0);return o;
}
#endif

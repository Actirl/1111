from pathlib import Path
p=Path("xhd-injector/src/injector.cpp")
s=p.read_text(encoding="utf-8")
rules=[
("static bool suppressIBL=false;", "static bool suppressIBL=false;\nstatic bool captureConstants=false;\nstatic wchar_t constantBase[MAX_PATH]=L\"\";"),
("static void captureBindings(ID3D11DeviceContext* context){", """static bool saveEyeCB(ID3D11DeviceContext* ctx,ID3D11Buffer* buffer,unsigned slot){
 if(!buffer||!constantBase[0])return false;
 D3D11_BUFFER_DESC desc={};buffer->GetDesc(&desc);
 if(!desc.ByteWidth||desc.ByteWidth>65536||desc.ByteWidth%16)return false;
 D3D11_BUFFER_DESC stageDesc=desc;
 stageDesc.Usage=D3D11_USAGE_STAGING;stageDesc.BindFlags=0;
 stageDesc.CPUAccessFlags=D3D11_CPU_ACCESS_READ;stageDesc.MiscFlags=0;
 ID3D11Device* dev=nullptr;ctx->GetDevice(&dev);if(!dev)return false;
 ID3D11Buffer* staging=nullptr;HRESULT h=dev->CreateBuffer(&stageDesc,nullptr,&staging);
 dev->Release();if(FAILED(h)||!staging)return false;
 ctx->CopyResource(staging,buffer);
 D3D11_MAPPED_SUBRESOURCE mapped={};h=ctx->Map(staging,0,D3D11_MAP_READ,0,&mapped);
 if(FAILED(h)){staging->Release();return false;}
 wchar_t file[MAX_PATH]={};swprintf_s(file,L"%ls_b%u.bin",constantBase,slot);
 FILE* output=nullptr;bool ok=false;
 if(_wfopen_s(&output,file,L"wb")==0&&output){
   ok=fwrite(mapped.pData,1,desc.ByteWidth,output)==desc.ByteWidth;fclose(output);
 }
 ctx->Unmap(staging,0);staging->Release();
 char line[128];sprintf_s(line,"eye PS b%u constant capture size=%u saved=%u",slot,desc.ByteWidth,ok?1:0);writeLog(line);
 return ok;
}
static void captureBindings(ID3D11DeviceContext* context){"""),
("  writeLog(line);buffers[i]->Release();","  writeLog(line);\n  if(captureConstants&&(i==0||i==1||i==2||i==4))saveEyeCB(context,buffers[i],i);\n  buffers[i]->Release();"),
('swprintf_s(textureBase,L"%ls%ls",path,L"xhd_eye_capture");','swprintf_s(textureBase,L"%ls%ls",path,L"xhd_eye_capture");swprintf_s(constantBase,L"%ls%ls",path,L"xhd_eye_constants");'),
(' suppressIBL=GetPrivateProfileIntW(L"settings",L"suppress_ibl_t10_t11",0,ini)!=0;',' suppressIBL=GetPrivateProfileIntW(L"settings",L"suppress_ibl_t10_t11",0,ini)!=0;\n captureConstants=GetPrivateProfileIntW(L"settings",L"capture_eye_constants",0,ini)!=0;'),
('if((neutralizeT3||suppressIBL) && data','if((neutralizeT3||suppressIBL||captureConstants) && data')
]
for old,new in rules:
 if s.count(old)!=1:raise SystemExit("Unexpected source for "+old[:48])
 s=s.replace(old,new,1)
assert 'PSSetConstantBuffers' not in s
assert 'PSSetShaderResources(24' not in s
# Record candidate high-slot ownership at the first matched eye draw.
probe=''' ID3D11ShaderResourceView* hi[4]={};
 context->PSGetShaderResources(24,4,hi);
 for(unsigned k=0;k<4;k++){
  char m[128];
  if(hi[k]){
   D3D11_SHADER_RESOURCE_VIEW_DESC d={};hi[k]->GetDesc(&d);
   sprintf_s(m,"eye slot t%u occupied=1 dim=%u",k+24,(unsigned)d.ViewDimension);
   hi[k]->Release();
  }else sprintf_s(m,"eye slot t%u occupied=0",k+24);
  writeLog(m);
 }
'''
anchor='writeLog("First matched draw: capturing bound pixel-shader resources");'
assert s.count(anchor)==1
s=s.replace(anchor,anchor+'\\n'+probe.replace('\\n','\\n'))

p.write_text(s,encoding="utf-8")
print("Injected observer-only constant-buffer snapshot into temporary CI build")

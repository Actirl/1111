#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <dxgi.h>
#include <atomic>
#include <cstring>
#include <cstdio>
#include <vector>
#include <mutex>
#include <string>
#include <algorithm>
#include "MinHook.h"

using CreatePS = HRESULT (STDMETHODCALLTYPE *)(ID3D11Device*,const void*,SIZE_T,ID3D11ClassLinkage*,ID3D11PixelShader**);
static CreatePS original = nullptr;
static std::mutex hookMutex;
static std::mutex shaderMutex;
static std::vector<ID3D11PixelShader*> activeTargets;
// Runtime-switchable pair: game-original shader -> XHDLook replacement.
static std::vector<std::pair<ID3D11PixelShader*, ID3D11PixelShader*>> xhdPairs;
static std::atomic<unsigned long> originalDraws{0}, xhdDraws{0};
static std::atomic<bool> drawHookReady{false};
static std::atomic<bool> bindingsCaptured{false};
using DrawIndexedFn=void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*,UINT,UINT,INT);
static DrawIndexedFn originalDrawIndexed=nullptr;
static std::atomic<unsigned long> created{0},hits{0},frames{0};
static std::atomic<bool> enabled{false};
static std::atomic<unsigned long> replaced{0}, failed{0};
static std::vector<unsigned char> replacement;
static bool replacementOn=false;
static bool neutralizeT3=false;
static bool suppressIBL=false;
static ID3D11ShaderResourceView* blackCube=nullptr;
static std::atomic<unsigned long> iblDraws{0};
static ID3D11ShaderResourceView* whiteT3=nullptr;
static std::atomic<unsigned long> neutralizedDraws{0};
static std::atomic<bool> visualWriteConfirmed{false};
static std::atomic<bool> captured{false};
static wchar_t originalShaderFile[MAX_PATH] = L"xhd_target_original_runtime.cso";
static wchar_t logfile[MAX_PATH] = L"xhd_shader_observer.log";
static wchar_t asmPath[MAX_PATH] = L"xhd_target_original_runtime.asm";
static const unsigned char target[16]={0xCE,0x32,0x29,0x95,0x46,0x83,0x9F,0x38,0x1B,0x68,0xAC,0x0D,0x07,0x2F,0xC0,0x35};
static void writeLog(const char* message){
 FILE* f=nullptr;
 if(_wfopen_s(&f,logfile,L"a")==0&&f){fputs(message,f);fputc('\n',f);fclose(f);}
}

static wchar_t textureBase[MAX_PATH]=L"";
static bool saveTexture(ID3D11DeviceContext* ctx, ID3D11ShaderResourceView* view, unsigned slot){
 if(!view || !textureBase[0])return false;
 D3D11_SHADER_RESOURCE_VIEW_DESC vd={};view->GetDesc(&vd);
 if(vd.ViewDimension!=D3D11_SRV_DIMENSION_TEXTURE2D)return false;
 ID3D11Resource* resource=nullptr;view->GetResource(&resource);
 if(!resource)return false;
 ID3D11Texture2D* texture=nullptr;
 HRESULT hr=resource->QueryInterface(__uuidof(ID3D11Texture2D),(void**)&texture);
 resource->Release();if(FAILED(hr)||!texture)return false;
 D3D11_TEXTURE2D_DESC td={};texture->GetDesc(&td);
 if(td.SampleDesc.Count!=1 || td.Width>4096 || td.Height>4096){texture->Release();return false;}
 UINT mip=vd.Texture2D.MostDetailedMip;
 if(mip>=td.MipLevels){texture->Release();return false;}
 D3D11_TEXTURE2D_DESC stage=td;
 stage.Width=(std::max)(1u,td.Width>>mip);stage.Height=(std::max)(1u,td.Height>>mip);
 stage.MipLevels=1;stage.ArraySize=1;
 stage.Usage=D3D11_USAGE_STAGING;stage.BindFlags=0;stage.CPUAccessFlags=D3D11_CPU_ACCESS_READ;
 stage.MiscFlags=0;
 ID3D11Device* device=nullptr;ctx->GetDevice(&device);
 if(!device){texture->Release();return false;}
 ID3D11Texture2D* staging=nullptr;
 hr=device->CreateTexture2D(&stage,nullptr,&staging);
 device->Release();
 if(FAILED(hr)||!staging){texture->Release();return false;}
 UINT sub=D3D11CalcSubresource(mip,0,td.MipLevels);
 ctx->CopySubresourceRegion(staging,0,0,0,0,texture,sub,nullptr);
 texture->Release();
 D3D11_MAPPED_SUBRESOURCE map={};
 hr=ctx->Map(staging,0,D3D11_MAP_READ,0,&map);
 if(FAILED(hr)){staging->Release();return false;}
 wchar_t dest[MAX_PATH]={};swprintf_s(dest,L"%ls_t%u.raw",textureBase,slot);
 FILE* output=nullptr;bool ok=false;
 if(_wfopen_s(&output,dest,L"wb")==0 && output){
   // Raw GPU rows including RowPitch padding; descriptor and row stride are written to log.
   UINT rows=(stage.Format==DXGI_FORMAT_BC1_UNORM||stage.Format==DXGI_FORMAT_BC1_UNORM_SRGB||
     stage.Format==DXGI_FORMAT_BC2_UNORM||stage.Format==DXGI_FORMAT_BC2_UNORM_SRGB||
     stage.Format==DXGI_FORMAT_BC3_UNORM||stage.Format==DXGI_FORMAT_BC3_UNORM_SRGB||
     stage.Format==DXGI_FORMAT_BC4_UNORM||stage.Format==DXGI_FORMAT_BC4_SNORM||
     stage.Format==DXGI_FORMAT_BC5_UNORM||stage.Format==DXGI_FORMAT_BC5_SNORM||
     stage.Format==DXGI_FORMAT_BC6H_UF16||stage.Format==DXGI_FORMAT_BC6H_SF16||
     stage.Format==DXGI_FORMAT_BC7_UNORM||stage.Format==DXGI_FORMAT_BC7_UNORM_SRGB)?
       (std::max)(1u,(stage.Height+3)/4):stage.Height;
   size_t bytes=size_t(map.RowPitch)*rows;
   ok=fwrite(map.pData,1,bytes,output)==bytes;
   fclose(output);
   char msg[200];sprintf_s(msg,"texture capture t%u %ux%u format=%u mip=%u rowpitch=%u rows=%u bytes=%zu saved=%u",
      slot,stage.Width,stage.Height,(unsigned)stage.Format,mip,map.RowPitch,rows,bytes,ok?1:0);
   writeLog(msg);
 }
 ctx->Unmap(staging,0);staging->Release();return ok;
}


// XHDLOOK_GPU_BRIDGE_V2: ReShade Bridge v2 -> private D3D11 PS constant buffer b14. b13 is reserved by MMShader DivaLiveParams.
// This path only activates for pixel shaders replaced by this injector.
static ID3D11Buffer* xhdLookCB=nullptr;
struct XHDLookParamsGPU {
  unsigned signature, abiVersion, sequence, enabled;
  float materials[16];  // eyes, skin, hair, clothes; 4 floats each
};
static_assert(sizeof(XHDLookParamsGPU)==80, "ReShade shared ABI size mismatch");
static bool readXHDLookParams(XHDLookParamsGPU& output) {
  HANDLE h=OpenFileMappingW(FILE_MAP_READ,FALSE,L"Local\\XHDLookRenderer_Params_v2");
  if(!h)return false;
  const auto* view=(const XHDLookParamsGPU*)MapViewOfFile(h,FILE_MAP_READ,0,0,sizeof(output));
  bool good=false;
  if(view) {
    for(int attempt=0;attempt<5;++attempt) {
      unsigned before=view->sequence;
      if(before&1)break;
      MemoryBarrier();
      XHDLookParamsGPU temp;
      memcpy(&temp,view,sizeof(temp));
      MemoryBarrier();
      if(before==view->sequence && !(before&1) && temp.signature==0x5848444c && temp.abiVersion==2) {
        output=temp;good=true;break;
      }
    }
    UnmapViewOfFile(view);
  }
  CloseHandle(h);
  return good;
}
static bool drawWithXHDLookCB(ID3D11DeviceContext* context,UINT count,UINT start,INT base) {
 if(!replacementOn || !drawHookReady.load(std::memory_order_acquire) || !originalDrawIndexed)return false;
 ID3D11PixelShader* current=nullptr;
 context->PSGetShader(&current,nullptr,nullptr);
 if(!current)return false;
 ID3D11PixelShader* custom=nullptr;
 {std::lock_guard<std::mutex> lock(shaderMutex);
  for(const auto& pair:xhdPairs)if(pair.first==current){custom=pair.second;custom->AddRef();break;}
 }
 if(!custom){current->Release();return false;}
 XHDLookParamsGPU cfg={};
 bool valid=readXHDLookParams(cfg);
 // A/B off: use the exact original GPU shader and render state, no resource override.
 if(!valid || cfg.enabled==0 || !xhdLookCB){
   originalDrawIndexed(context,count,start,base);
   originalDraws.fetch_add(1,std::memory_order_relaxed);
   current->Release();custom->Release();return true;
 }
 context->UpdateSubresource(xhdLookCB,0,nullptr,&cfg,0,0);
 ID3D11Buffer* oldCB=nullptr;
 context->PSGetConstantBuffers(14,1,&oldCB);
 context->PSSetConstantBuffers(14,1,&xhdLookCB);
 context->PSSetShader(custom,nullptr,0);
 originalDrawIndexed(context,count,start,base);
 context->PSSetShader(current,nullptr,0);
 context->PSSetConstantBuffers(14,1,&oldCB);
 if(oldCB)oldCB->Release();
 xhdDraws.fetch_add(1,std::memory_order_relaxed);
 current->Release();custom->Release();return true;
}

static void captureBindings(ID3D11DeviceContext* context){
 if(bindingsCaptured.load(std::memory_order_acquire))return;
 ID3D11PixelShader* current=nullptr;
 context->PSGetShader(&current,nullptr,nullptr);
 if(!current)return;
 bool matched=false;
 {
  std::lock_guard<std::mutex> lock(shaderMutex);
  matched=std::find_if(xhdPairs.begin(),xhdPairs.end(),[current](const auto& pair){return pair.first==current;})!=xhdPairs.end()
           ||std::find(activeTargets.begin(),activeTargets.end(),current)!=activeTargets.end();
 }
 current->Release();
 if(!matched)return;
 bool expected=false;
 if(!bindingsCaptured.compare_exchange_strong(expected,true))return;
 writeLog("First matched draw: capturing bound pixel-shader resources");
 ID3D11ShaderResourceView* views[32]={};
 context->PSGetShaderResources(0,32,views);
 for(unsigned i=0;i<32;i++){
  if(!views[i])continue;
  D3D11_SHADER_RESOURCE_VIEW_DESC d={};views[i]->GetDesc(&d);
  char line[160];sprintf_s(line,"PS SRV t%u dimension=%u format=%u",i,(unsigned)d.ViewDimension,(unsigned)d.Format);
  writeLog(line);
  ID3D11Resource* resource=nullptr;views[i]->GetResource(&resource);
  if(resource){
   D3D11_RESOURCE_DIMENSION kind=D3D11_RESOURCE_DIMENSION_UNKNOWN;resource->GetType(&kind);
   if(kind==D3D11_RESOURCE_DIMENSION_TEXTURE2D){
    ID3D11Texture2D* tex=nullptr;
    if(SUCCEEDED(resource->QueryInterface(__uuidof(ID3D11Texture2D),(void**)&tex))){
     D3D11_TEXTURE2D_DESC td={};tex->GetDesc(&td);
     sprintf_s(line,"PS SRV t%u texture2D %ux%u array=%u mips=%u format=%u",i,td.Width,td.Height,td.ArraySize,td.MipLevels,(unsigned)td.Format);writeLog(line);tex->Release();
    }
   }
   resource->Release();
  }
  if(i==0||i==2||i==3)saveTexture(context,views[i],i);
  views[i]->Release();
 }
 ID3D11SamplerState* samplers[16]={};
 context->PSGetSamplers(0,16,samplers);
 for(unsigned i=0;i<16;i++)if(samplers[i]){
  D3D11_SAMPLER_DESC d={};samplers[i]->GetDesc(&d);
  char line[160];sprintf_s(line,"PS sampler s%u filter=%u addressU=%u addressV=%u",i,(unsigned)d.Filter,(unsigned)d.AddressU,(unsigned)d.AddressV);
  writeLog(line);samplers[i]->Release();
 }
 ID3D11Buffer* buffers[8]={};
 context->PSGetConstantBuffers(0,8,buffers);
 for(unsigned i=0;i<8;i++)if(buffers[i]){
  D3D11_BUFFER_DESC d={};buffers[i]->GetDesc(&d);
  char line[160];sprintf_s(line,"PS CB b%u bytes=%u usage=%u",i,d.ByteWidth,(unsigned)d.Usage);
  writeLog(line);buffers[i]->Release();
 }
 writeLog("First matched draw: resource descriptor capture completed");
}
static void STDMETHODCALLTYPE observeDrawIndexed(ID3D11DeviceContext* context,UINT count,UINT start,INT base){
 captureBindings(context);
 if(drawWithXHDLookCB(context,count,start,base))return;
 if((neutralizeT3 && whiteT3)||(suppressIBL && blackCube)){
  ID3D11PixelShader* current=nullptr;context->PSGetShader(&current,nullptr,nullptr);
  bool matched=false;
  if(current){
   {std::lock_guard<std::mutex> lock(shaderMutex);
    matched=std::find(activeTargets.begin(),activeTargets.end(),current)!=activeTargets.end();}
   current->Release();
  }
  if(matched){
   ID3D11ShaderResourceView* prior=nullptr;
   if(neutralizeT3){context->PSGetShaderResources(3,1,&prior);context->PSSetShaderResources(3,1,&whiteT3);}
   ID3D11ShaderResourceView* originalIBL[2]={};
   if(suppressIBL){context->PSGetShaderResources(10,2,originalIBL);ID3D11ShaderResourceView* black[2]={blackCube,blackCube};context->PSSetShaderResources(10,2,black);}
   if(!visualWriteConfirmed.exchange(true)){
     ID3D11ShaderResourceView* check[2]={};
     if(suppressIBL){
       context->PSGetShaderResources(10,2,check);
       char msg[180];sprintf_s(msg,"VISUAL_TEST_APPLIED mode=IBL_BLACK bound10=%u bound11=%u",
         check[0]==blackCube?1:0,check[1]==blackCube?1:0);
       writeLog(msg);
       for(auto* p:check)if(p)p->Release();
     }else{
       context->PSGetShaderResources(3,1,check);
       char msg[160];sprintf_s(msg,"VISUAL_TEST_APPLIED mode=T3_WHITE bound3=%u",check[0]==whiteT3?1:0);
       writeLog(msg);
       if(check[0])check[0]->Release();
     }
   }
   originalDrawIndexed(context,count,start,base);
   if(neutralizeT3){context->PSSetShaderResources(3,1,&prior);if(prior)prior->Release();neutralizedDraws.fetch_add(1);}
   if(suppressIBL){context->PSSetShaderResources(10,2,originalIBL);for(auto* p:originalIBL)if(p)p->Release();iblDraws.fetch_add(1);}
   return;
  }
 }
 originalDrawIndexed(context,count,start,base);
}
static void disassembleOriginalShader(const void* data,SIZE_T len){
 HMODULE compiler=LoadLibraryW(L"d3dcompiler_47.dll");
 if(!compiler){writeLog("D3D disassembly skipped: compiler DLL unavailable");return;}
 using Disasm=HRESULT (WINAPI*)(LPCVOID,SIZE_T,UINT,LPCSTR,ID3DBlob**);
 auto fn=(Disasm)GetProcAddress(compiler,"D3DDisassemble");
 ID3DBlob* blob=nullptr;
 HRESULT hr=fn?fn(data,len,0,nullptr,&blob):E_FAIL;
 if(SUCCEEDED(hr)&&blob){
  FILE* out=nullptr;
  if(_wfopen_s(&out,asmPath,L"wb")==0&&out){
   size_t size=blob->GetBufferSize();size_t written=fwrite(blob->GetBufferPointer(),1,size,out);
   fclose(out);
   writeLog(written==size?"original Shader ASM disassembly saved":"Shader ASM write incomplete");
  }else writeLog("original Shader ASM file open failed");
  blob->Release();
 }else writeLog("D3DDisassemble failed");
 FreeLibrary(compiler);
}
static void setup(){
 HMODULE module=nullptr;
 wchar_t path[MAX_PATH]={0};
 if(GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
 reinterpret_cast<LPCWSTR>(&setup),&module)){
 if(GetModuleFileNameW(module,path,MAX_PATH)){
 wchar_t* slash=wcsrchr(path,L'\\');
 if(slash){slash[1]=0;swprintf_s(logfile,L"%ls%ls",path,L"xhd_shader_observer.log");swprintf_s(originalShaderFile,L"%ls%ls",path,L"xhd_target_original_runtime.cso");swprintf_s(asmPath,L"%ls%ls",path,L"xhd_target_original_runtime.asm");swprintf_s(textureBase,L"%ls%ls",path,L"xhd_eye_capture");}
 }
 }
 wchar_t ini[MAX_PATH]={0}, shader[MAX_PATH]={0};
 swprintf_s(ini,L"%ls%ls",path,L"xhd_injector.ini");
 swprintf_s(shader,L"%ls%ls",path,L"replacement.cso");
 replacementOn=GetPrivateProfileIntW(L"settings",L"enable_replacement",0,ini)!=0;
 neutralizeT3=GetPrivateProfileIntW(L"settings",L"neutralize_t3",0,ini)!=0;
 suppressIBL=GetPrivateProfileIntW(L"settings",L"suppress_ibl_t10_t11",0,ini)!=0;
 if(neutralizeT3||suppressIBL)replacementOn=false;
 if(suppressIBL)neutralizeT3=false;
 FILE* f=nullptr;
 if(_wfopen_s(&f,shader,L"rb")==0&&f){
   fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);
   if(n>36&&n<4*1024*1024){replacement.resize((size_t)n); if(fread(replacement.data(),1,(size_t)n,f)!=(size_t)n)replacement.clear();}
   fclose(f);
 }
 if(replacement.size()<36||memcmp(replacement.data(),"DXBC",4)!=0){replacement.clear();writeLog("replacement missing or invalid");}
 writeLog(replacementOn?"visual replacement requested":"observer mode");

}
static HRESULT STDMETHODCALLTYPE observe(ID3D11Device* dev,const void* data,SIZE_T len,ID3D11ClassLinkage* link,ID3D11PixelShader** out){
 created.fetch_add(1,std::memory_order_relaxed);
 if(data&&len>=36&&memcmp(data,"DXBC",4)==0&&memcmp((const unsigned char*)data+4,target,16)==0){
   hits.fetch_add(1,std::memory_order_relaxed);
   bool expected=false;
   if(len<=4*1024*1024 && captured.compare_exchange_strong(expected,true)){
     FILE* capture=nullptr;
     if(_wfopen_s(&capture,originalShaderFile,L"wb")==0 && capture){
       size_t written=fwrite(data,1,len,capture);fclose(capture);
       writeLog(written==len?"captured original matching shader DXBC":"original DXBC capture incomplete");
       if(written==len)disassembleOriginalShader(data,len);
     } else {
       captured.store(false);
       writeLog("original DXBC capture failed: file access");
     }
   }
   if(replacementOn&&!replacement.empty()&&out&&drawHookReady.load(std::memory_order_acquire)){
     // Keep the original shader owned by the game. Switch only during its draws.
     HRESULT originalStatus=original(dev,data,len,link,out);
     if(FAILED(originalStatus)||!*out)return originalStatus;
     ID3D11PixelShader* candidate=nullptr;
     HRESULT customStatus=original(dev,replacement.data(),replacement.size(),link,&candidate);
     if(SUCCEEDED(customStatus)&&candidate){
       {std::lock_guard<std::mutex> lock(shaderMutex);
        xhdPairs.emplace_back(*out,candidate);
        // Keep a reference to the game's original shader to prevent stale pointer reuse.
        (*out)->AddRef();
       }
       replaced.fetch_add(1);
     }else{
       if(candidate)candidate->Release();
       failed.fetch_add(1);
     }
     return originalStatus;
   }
 }
 HRESULT result=original(dev,data,len,link,out);
 if((neutralizeT3||suppressIBL) && data && len>=36 && memcmp(data,"DXBC",4)==0 &&
    memcmp((const unsigned char*)data+4,target,16)==0 && SUCCEEDED(result) && out && *out){
   std::lock_guard<std::mutex> lock(shaderMutex);activeTargets.push_back(*out);
 }
 return result;
}
extern "C" __declspec(dllexport) void PreInit(){static std::once_flag once;std::call_once(once,setup);}
extern "C" __declspec(dllexport) void Init(){PreInit();}
extern "C" __declspec(dllexport) void PostInit(){writeLog("PostInit called");}
extern "C" __declspec(dllexport) void D3DInit(IDXGISwapChain*,ID3D11Device* dev,ID3D11DeviceContext* context){
 Init();
 if(!dev){writeLog("D3DInit: device null");return;}
 if(!xhdLookCB){
   D3D11_BUFFER_DESC cbd={};
   cbd.ByteWidth=sizeof(XHDLookParamsGPU);
   cbd.Usage=D3D11_USAGE_DEFAULT;
   cbd.BindFlags=D3D11_BIND_CONSTANT_BUFFER;
   HRESULT chr=dev->CreateBuffer(&cbd,nullptr,&xhdLookCB);
   writeLog(SUCCEEDED(chr)?"XHDLook b13 GPU parameter bridge created":"XHDLook b13 parameter buffer creation FAILED");
 }
 if(neutralizeT3 && !whiteT3){
  const unsigned char white[4]={255,255,255,255};
  D3D11_TEXTURE2D_DESC td={};td.Width=1;td.Height=1;td.MipLevels=1;td.ArraySize=1;td.Format=DXGI_FORMAT_R8G8B8A8_UNORM;td.SampleDesc.Count=1;td.Usage=D3D11_USAGE_IMMUTABLE;td.BindFlags=D3D11_BIND_SHADER_RESOURCE;
  D3D11_SUBRESOURCE_DATA initial={};initial.pSysMem=white;initial.SysMemPitch=4;
  ID3D11Texture2D* tex=nullptr;
  if(SUCCEEDED(dev->CreateTexture2D(&td,&initial,&tex))){
   if(SUCCEEDED(dev->CreateShaderResourceView(tex,nullptr,&whiteT3)))writeLog("t3 neutralization resource created");
   tex->Release();
  }
 }
 if(suppressIBL && !blackCube){
  const unsigned char black[4]={0,0,0,255};
  D3D11_TEXTURE2D_DESC td={};td.Width=1;td.Height=1;td.MipLevels=1;td.ArraySize=6;
  td.Format=DXGI_FORMAT_R8G8B8A8_UNORM;td.SampleDesc.Count=1;
  td.Usage=D3D11_USAGE_IMMUTABLE;td.BindFlags=D3D11_BIND_SHADER_RESOURCE;
  td.MiscFlags=D3D11_RESOURCE_MISC_TEXTURECUBE;
  D3D11_SUBRESOURCE_DATA faces[6]={};
  for(unsigned i=0;i<6;i++){faces[i].pSysMem=black;faces[i].SysMemPitch=4;}
  ID3D11Texture2D* tex=nullptr;
  if(SUCCEEDED(dev->CreateTexture2D(&td,faces,&tex))){
   if(SUCCEEDED(dev->CreateShaderResourceView(tex,nullptr,&blackCube)))writeLog("black IBL cube created");
   tex->Release();
  }
 }
 std::lock_guard<std::mutex> lock(hookMutex);
 if(enabled.load())return;
 void* addr=(*reinterpret_cast<void***>(dev))[15];
 MH_STATUS s=MH_Initialize();
 if(s!=MH_OK&&s!=MH_ERROR_ALREADY_INITIALIZED){writeLog("MH_Initialize failed");return;}
 if(MH_CreateHook(addr,(void*)&observe,(void**)&original)!=MH_OK){writeLog("MH_CreateHook failed");return;}
 if(MH_EnableHook(addr)!=MH_OK){MH_RemoveHook(addr);original=nullptr;writeLog("MH_EnableHook failed");return;}
 enabled=true;writeLog("CreatePixelShader observer hook enabled");
 if(context){
   void* draw=(*reinterpret_cast<void***>(context))[12];
   MH_STATUS ds=MH_CreateHook(draw,(void*)&observeDrawIndexed,(void**)&originalDrawIndexed);
   if(ds==MH_OK && MH_EnableHook(draw)==MH_OK){
     drawHookReady.store(true,std::memory_order_release);
     writeLog("DrawIndexed hook enabled; runtime shader A/B available");
   }else{
     writeLog("DrawIndexed hook failed; XHD replacement disabled (safe original only)");
   }
 }
}
extern "C" __declspec(dllexport) void OnFrame(IDXGISwapChain*){
 PreInit();
 const unsigned long frame=++frames;
 if(frame==1||frame%600==0){
 char buf[160];
 sprintf_s(buf,"frames=%lu hook=%d drawhook=%d CreatePS=%lu target=%lu replaced=%lu fail=%lu original_draws=%lu xhd_draws=%lu t3neutral_draws=%lu ibl_draws=%lu",frame,enabled.load()?1:0,drawHookReady.load()?1:0,created.load(),hits.load(),replaced.load(),failed.load(),originalDraws.load(),xhdDraws.load(),neutralizedDraws.load(),iblDraws.load());
 writeLog(buf);
 }
}
BOOL WINAPI DllMain(HMODULE,DWORD,LPVOID){return TRUE;}

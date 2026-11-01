#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <atomic>
#include <cstring>
#include <cstdio>
#include <mutex>
#include <string>
#include "MinHook.h"

using CreatePS = HRESULT (STDMETHODCALLTYPE *)(ID3D11Device*,const void*,SIZE_T,ID3D11ClassLinkage*,ID3D11PixelShader**);
static CreatePS original = nullptr;
static std::mutex hookMutex;
static std::atomic<unsigned long> created{0},hits{0},frames{0};
static std::atomic<bool> enabled{false};
static wchar_t logfile[MAX_PATH] = L"xhd_shader_observer.log";
static const unsigned char target[16]={0xCE,0x32,0x29,0x95,0x46,0x83,0x9F,0x38,0x1B,0x68,0xAC,0x0D,0x07,0x2F,0xC0,0x35};
static void writeLog(const char* message){
 FILE* f=nullptr;
 if(_wfopen_s(&f,logfile,L"a")==0&&f){fputs(message,f);fputc('\n',f);fclose(f);}
}
static void setup(){
 HMODULE module=nullptr;
 if(GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
 reinterpret_cast<LPCWSTR>(&setup),&module)){
 wchar_t path[MAX_PATH]={0};
 if(GetModuleFileNameW(module,path,MAX_PATH)){
 wchar_t* slash=wcsrchr(path,L'\\');
 if(slash){slash[1]=0;swprintf_s(logfile,L"%ls%ls",path,L"xhd_shader_observer.log");}
 }
 }
 writeLog("observer init; unmodified shader mode");
}
static HRESULT STDMETHODCALLTYPE observe(ID3D11Device* dev,const void* data,SIZE_T len,ID3D11ClassLinkage* link,ID3D11PixelShader** out){
 created.fetch_add(1,std::memory_order_relaxed);
 if(data&&len>=36&&memcmp(data,"DXBC",4)==0&&memcmp((const unsigned char*)data+4,target,16)==0)
   hits.fetch_add(1,std::memory_order_relaxed);
 return original(dev,data,len,link,out);
}
extern "C" __declspec(dllexport) void PreInit(){static std::once_flag once;std::call_once(once,setup);writeLog("PreInit called");}
extern "C" __declspec(dllexport) void Init(){PreInit();writeLog("Init called");}
extern "C" __declspec(dllexport) void PostInit(){writeLog("PostInit called");}
extern "C" __declspec(dllexport) void D3DInit(IDXGISwapChain*,ID3D11Device* dev,ID3D11DeviceContext*){
 Init();
 if(!dev){writeLog("D3DInit: device null");return;}
 std::lock_guard<std::mutex> lock(hookMutex);
 if(enabled.load())return;
 void* addr=(*reinterpret_cast<void***>(dev))[15];
 MH_STATUS s=MH_Initialize();
 if(s!=MH_OK&&s!=MH_ERROR_ALREADY_INITIALIZED){writeLog("MH_Initialize failed");return;}
 if(MH_CreateHook(addr,(void*)&observe,(void**)&original)!=MH_OK){writeLog("MH_CreateHook failed");return;}
 if(MH_EnableHook(addr)!=MH_OK){MH_RemoveHook(addr);original=nullptr;writeLog("MH_EnableHook failed");return;}
 enabled=true;writeLog("CreatePixelShader observer hook enabled");
}
extern "C" __declspec(dllexport) void OnFrame(IDXGISwapChain*){
 Init();
 const unsigned long frame=++frames;
 if(frame==1||frame%600==0){
 char buf[160];
 sprintf_s(buf,"frames=%lu hook=%d CreatePS=%lu target=%lu",frame,enabled.load()?1:0,created.load(),hits.load());
 writeLog(buf);
 }
}
BOOL WINAPI DllMain(HMODULE,DWORD,LPVOID){return TRUE;}

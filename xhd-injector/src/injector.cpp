#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <atomic>
#include <cstring>
#include <fstream>
#include "MinHook.h"
using CreatePS = HRESULT (STDMETHODCALLTYPE *)(ID3D11Device*,const void*,SIZE_T,ID3D11ClassLinkage*,ID3D11PixelShader**);
static CreatePS original = nullptr;
static std::atomic<unsigned long> seen{0},hits{0};
static const unsigned char target[16]={0xCE,0x32,0x29,0x95,0x46,0x83,0x9F,0x38,0x1B,0x68,0xAC,0x0D,0x07,0x2F,0xC0,0x35};
static HRESULT STDMETHODCALLTYPE observe(ID3D11Device* dev,const void* data,SIZE_T len,ID3D11ClassLinkage* link,ID3D11PixelShader** out){
 seen.fetch_add(1);
 if(data&&len>=36&&memcmp(data,"DXBC",4)==0&&memcmp((const unsigned char*)data+4,target,16)==0)hits.fetch_add(1);
 return original(dev,data,len,link,out);
}
extern "C" __declspec(dllexport) void Init(){}
extern "C" __declspec(dllexport) void D3DInit(IDXGISwapChain*,ID3D11Device* dev,ID3D11DeviceContext*){
 if(!dev||original)return;
 void* addr=(*reinterpret_cast<void***>(dev))[15];
 MH_STATUS s=MH_Initialize();
 if(s!=MH_OK&&s!=MH_ERROR_ALREADY_INITIALIZED)return;
 if(MH_CreateHook(addr,(void*)&observe,(void**)&original)!=MH_OK)return;
 if(MH_EnableHook(addr)!=MH_OK){MH_RemoveHook(addr);original=nullptr;}
}
extern "C" __declspec(dllexport) void OnFrame(IDXGISwapChain*){
 static unsigned long last=~0UL;unsigned long n=seen.load();
 if(n!=last){last=n;std::ofstream f("xhd_shader_observer.log",std::ios::app);if(f)f<<"CreatePS="<<n<<" target="<<hits.load()<<"\n";}
}
BOOL WINAPI DllMain(HMODULE,DWORD,LPVOID){return TRUE;}

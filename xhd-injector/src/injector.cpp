#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <fstream>
#include <mutex>
static std::once_flag init_once;
static void log_state(const char* message) {
 std::ofstream file("xhd_dll_build_probe.log", std::ios::app);
 if (file) file << message << '\n';
}
extern "C" __declspec(dllexport) void Init() {
 std::call_once(init_once, [](){log_state("Init OK");});
}
extern "C" __declspec(dllexport) void D3DInit(IDXGISwapChain*, ID3D11Device* device, ID3D11DeviceContext*) {
 Init();
 log_state(device ? "D3D device present" : "D3D device missing");
}
extern "C" __declspec(dllexport) void OnFrame(IDXGISwapChain*) {}
BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID){return TRUE;}

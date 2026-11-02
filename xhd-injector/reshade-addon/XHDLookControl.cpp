#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define IMGUI_DISABLE_INCLUDE_IMCONFIG_H
#include <imgui.h>
#include <reshade.hpp>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::uint32_t MAGIC = 0x5848444c;
struct Material { float ambient, shadow, specular, wrap; };
struct Parameters {
 std::uint32_t signature, version, sequence, enabled;
 Material eye, skin, hair, clothes;
};
static_assert(sizeof(Parameters) == 80, "ABI mismatch with injector b13");
HANDLE mapping = nullptr;
Parameters* shared = nullptr;
int selected = 0;
const char* labels[] = {"Eyes", "Skin", "Hair", "Clothes"};
void initialize() {
 mapping = CreateFileMappingW(INVALID_HANDLE_VALUE,nullptr,PAGE_READWRITE,0,sizeof(Parameters),L"Local\\XHDLookRenderer_Params_v2");
 if (!mapping) return;
 bool newly_created = GetLastError()!=ERROR_ALREADY_EXISTS;
 shared = (Parameters*)MapViewOfFile(mapping,FILE_MAP_ALL_ACCESS,0,0,sizeof(Parameters));
 if (!shared) return;
 if (newly_created || shared->signature != MAGIC || shared->version != 2) {
   Parameters init={};
   init.signature=MAGIC; init.version=2;
   init.eye={0.32f,0.40f,0.35f,0.25f};
   init.skin={0.18f,0.28f,0.14f,0.20f};
   init.hair={0.16f,0.32f,0.48f,0.17f};
   init.clothes={0.15f,0.35f,0.30f,0.10f};
   *shared=init;
 }
}
void update(const Parameters& p) {
 std::uint32_t seq = shared->sequence;
 shared->sequence = (seq&~1u)+1u;
 MemoryBarrier();
 shared->enabled=p.enabled;
 shared->eye=p.eye; shared->skin=p.skin; shared->hair=p.hair; shared->clothes=p.clothes;
 MemoryBarrier();
 shared->sequence=(seq&~1u)+2u;
}
void overlay(reshade::api::effect_runtime*) {
 if (!shared) initialize();
 if (!shared) { ImGui::TextUnformatted("XHDLook: shared parameters unavailable"); return; }
 ImGui::TextUnformatted("XHD-Look Renderer - GPU b12 parameter bridge");
 ImGui::TextUnformatted("WARNING: This is a diagnostic replacement shader, NOT XHD fidelity.");
 ImGui::TextUnformatted("OFF: original game pixel shader; ON: diagnostic replacement.");
 ImGui::TextUnformatted("A/B requires the updated injector and working DrawIndexed hook.");
 ImGui::TextUnformatted("Skin/hair/clothes currently have no effect on GPU.");
 Parameters p=*shared;
 bool changed=false;
 bool active=p.enabled!=0;
 if(ImGui::Checkbox("Enable experimental eye parameter variation",&active)) {p.enabled=active?1u:0u;changed=true;}
 ImGui::Combo("Material preview",&selected,labels,4);
 Material* m=selected==0?&p.eye:selected==1?&p.skin:selected==2?&p.hair:&p.clothes;
 changed|=ImGui::SliderFloat("Ambient", &m->ambient,0,1);
 changed|=ImGui::SliderFloat("Shadow softening", &m->shadow,0,1);
 changed|=ImGui::SliderFloat("Specular contribution", &m->specular,0,1);
 changed|=ImGui::SliderFloat("Diffuse wrap", &m->wrap,0,1);
 if(changed)update(p);
 ImGui::Text("Bridge ABI 2, sequence %u",shared->sequence);
}
}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID) {
 if(reason==DLL_PROCESS_ATTACH) {
   if(!reshade::register_addon(instance)) return FALSE;
   reshade::register_overlay("XHD-Look Control",overlay);
 } else if(reason==DLL_PROCESS_DETACH) {
   reshade::unregister_addon(instance);
   if(shared)UnmapViewOfFile(shared);
   if(mapping)CloseHandle(mapping);
 }
 return TRUE;
}

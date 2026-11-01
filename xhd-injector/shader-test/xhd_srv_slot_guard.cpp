#include <d3d11.h>
#include <array>
#include <cstdint>

// Observer-only: explicitly validates expected slot ownership and restores state.
// This does not create PS4 textures or modify any shader.
struct XHDSrvSlots {
  static constexpr UINT first=24;
  static constexpr UINT count=4;
  ID3D11ShaderResourceView* old[count]{};
  bool borrowed=false;
  bool allEmpty=true;
  void capture(ID3D11DeviceContext* ctx) {
    if(!ctx)return;
    ctx->PSGetShaderResources(first,count,old);
    borrowed=true;
    for(auto* view:old)if(view)allEmpty=false;
  }
  void restore(ID3D11DeviceContext* ctx) {
    if(!borrowed)return;
    if(ctx)ctx->PSSetShaderResources(first,count,old);
    for(auto*& view:old){if(view){view->Release();view=nullptr;}}
    borrowed=false;
  }
  ~XHDSrvSlots(){restore(nullptr);}
};
bool XHDValidateRuntimeSrvSlots(ID3D11DeviceContext* ctx) {
 if(!ctx)return false;
 XHDSrvSlots snapshot;
 snapshot.capture(ctx);
 // Read-only verification; cannot claim slots are free on other draws.
 bool available=snapshot.allEmpty;
 snapshot.restore(nullptr);
 return available;
}

#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class Client : public Module {
public:
    Interface* g_HudChat;
    Interface* ClientTools;
    Interface* g_ClientDLL;

    using _ChatPrintf = void(*)(void* thisptr, int iPlayerIndex, int iFilter, const char* fmt, ...);
    _ChatPrintf ChatPrintf = nullptr;

    using _NextParticleSystem = void*(__func*)(void* thisptr, void* searchResult);
    _NextParticleSystem NextParticleSystem = nullptr;

    void* GetParticleSystem(void* prev);
    inline Vector GetPortalGunIndicatorColor() const { return this->portalGunIndicatorColor; }
    void SetPortalGunIndicatorColor(Vector v);
    void UpdatePortalGunIndicatorColor();



    DECL_DETOUR(RenderView, const CViewSetup& view, int nClearFlags, int whatToDraw);
    DECL_DETOUR(HudUpdate, unsigned int a2);
public:
    Client();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("client"); }

private:
    Vector portalGunIndicatorColor;
};

extern Client* client;

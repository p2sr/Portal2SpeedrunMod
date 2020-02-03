#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class Client : public Module {
public:
    Interface* g_HudChat;
    Interface* ClientTools;

    using _ChatPrintf = void(*)(void* thisptr, int iPlayerIndex, int iFilter, const char* fmt, ...);
    _ChatPrintf ChatPrintf = nullptr;

    using _NextParticleSystem = void*(__func*)(void* thisptr, void* searchResult);
    _NextParticleSystem NextParticleSystem = nullptr;

    CParticleCollection* GetParticleSystem(CParticleCollection* prev);

public:
    Client();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("client"); }
};

extern Client* client;

#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class Server : public Module {
public:
    Interface* g_GameMovement = nullptr;
    Interface* g_ServerGameDLL = nullptr;
public:
    Server();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("server"); }

    //CGameMovement::ProcessMovement
    DECL_DETOUR(ProcessMovement, void* pPlayer, CMoveData* pMove);

    using _UTIL_PlayerByIndex = void* (__cdecl*)(int index);
    _UTIL_PlayerByIndex UTIL_PlayerByIndex = nullptr;

    void* GetPlayer(int index);
};

extern Server* server;

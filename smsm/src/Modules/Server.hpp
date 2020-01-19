#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class Server : public Module {
public:
    Interface* GameMovement = nullptr;
public:
    Server();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("server"); }

    //CGameMovement::ProcessMovement
    DECL_DETOUR(ProcessMovement, void* pPlayer, CMoveData* pMove);
};

extern Server* server;

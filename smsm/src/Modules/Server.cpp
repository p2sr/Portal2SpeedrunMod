#include "Server.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

#include "Console.hpp"
#include "SMSM.hpp"
#include "CelesteMoveset.hpp"


// CGameMovement::ProcessMovement
REDECL(Server::ProcessMovement);
DETOUR(Server::ProcessMovement, void* pPlayer, CMoveData* pMove) {
    celesteMoveset.PreProcessMovement(pPlayer, pMove);

    auto result = Server::ProcessMovement(thisptr, pPlayer, pMove);
    server->tickBase = *reinterpret_cast<int*>((uintptr_t)pPlayer + Offsets::m_nTickBase);

    celesteMoveset.ProcessMovement(pPlayer, pMove);
    return result;
}

void* Server::GetPlayer(int index) {
    return this->UTIL_PlayerByIndex(index);
}

void* Server::GetEntityHandleByIndex(int index) {
    auto size = sizeof(CEntInfo2);
    CEntInfo* info = reinterpret_cast<CEntInfo*>((uintptr_t)server->m_EntPtrArray + size * index);
    return info->m_pEntity;
}

Server::Server()
    : Module() {
}
bool Server::Init() {

    if (auto g_ServerTools = Interface::Create(this->Name(), "VSERVERTOOLS001")) {
        auto GetIServerEntity = g_ServerTools->Original(Offsets::GetIServerEntity);
#ifdef _WIN32
        Memory::Deref(GetIServerEntity + Offsets::m_EntPtrArray, &this->m_EntPtrArray);
#else
        this->m_EntPtrArray = (CEntInfo *)(GetIServerEntity + 12 + *(uint32_t *)(GetIServerEntity + 14) + *(uint32_t *)(GetIServerEntity + 54) + 4);
#endif
        Interface::Delete(g_ServerTools);
    }

    this->g_GameMovement = Interface::Create(this->Name(), "GameMovement001");
    if (this->g_GameMovement) {
        this->g_GameMovement->Hook(Server::ProcessMovement_Hook, Server::ProcessMovement, Offsets::ProcessMovement);
    }

    this->g_ServerGameDLL = Interface::Create(this->Name(), "ServerGameDLL005");

    if (this->g_ServerGameDLL) {
        auto Think = this->g_ServerGameDLL->Original(Offsets::Think);
        Memory::Read<_UTIL_PlayerByIndex>(Think + Offsets::UTIL_PlayerByIndex, &this->UTIL_PlayerByIndex);
#ifdef _WIN32
        Memory::DerefDeref<CGlobalVars*>((uintptr_t)this->UTIL_PlayerByIndex + Offsets::gpGlobals, &this->gpGlobals);
#else
        this->gpGlobals = *(CGlobalVars **)((uintptr_t)this->UTIL_PlayerByIndex + 5 + *(uint32_t *)((uintptr_t)UTIL_PlayerByIndex + 7) + *(uint32_t *)((uintptr_t)UTIL_PlayerByIndex + 21));
#endif
    }

    return this->hasLoaded = this->g_GameMovement && this->g_ServerGameDLL;
}
void Server::Shutdown() {
    if (this->g_GameMovement) {
        Interface::Delete(this->g_GameMovement);
    }

    if (this->g_ServerGameDLL) {
        Interface::Delete(this->g_ServerGameDLL);
    }
}

Server* server;

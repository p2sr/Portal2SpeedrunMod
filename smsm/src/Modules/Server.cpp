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

    celesteMoveset.ProcessMovement(pPlayer, pMove);
    return result;
}

void* Server::GetPlayer(int index) {
    return this->UTIL_PlayerByIndex(index);
}

Server::Server()
    : Module() {
}
bool Server::Init() {
    this->g_GameMovement = Interface::Create(this->Name(), "GameMovement0");
    if (this->g_GameMovement) {
        this->g_GameMovement->Hook(Server::ProcessMovement_Hook, Server::ProcessMovement, Offsets::ProcessMovement);
    }

    this->g_ServerGameDLL = Interface::Create(this->Name(), "ServerGameDLL0");

    if (this->g_ServerGameDLL) {
        auto Think = this->g_ServerGameDLL->Original(Offsets::Think);
        Memory::Read<_UTIL_PlayerByIndex>(Think + Offsets::UTIL_PlayerByIndex, &this->UTIL_PlayerByIndex);
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

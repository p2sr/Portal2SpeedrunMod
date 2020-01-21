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
    auto result = Server::ProcessMovement(thisptr, pPlayer, pMove);

    celesteMoveset.ProcessMovement(pPlayer, pMove);

    return result;
}


Server::Server()
    : Module() {
}
bool Server::Init() {
    this->GameMovement = Interface::Create(this->Name(), "GameMovement0");
    if (this->GameMovement) {
        this->GameMovement->Hook(Server::ProcessMovement_Hook, Server::ProcessMovement, Offsets::ProcessMovement);
    }

    return this->hasLoaded = this->GameMovement;
}
void Server::Shutdown() {

}

Server* server;

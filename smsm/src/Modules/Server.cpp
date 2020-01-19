#include "Server.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

#include "Console.hpp"
#include "SMSM.hpp"

// CGameMovement::ProcessMovement
REDECL(Server::ProcessMovement);
DETOUR(Server::ProcessMovement, void* pPlayer, CMoveData* pMove) {
    auto result = Server::ProcessMovement(thisptr, pPlayer, pMove);
    smsm.modeParams[PlayerAnglePitch] = pMove->m_vecViewAngles.x;
    smsm.modeParams[PlayerAngleYaw] = pMove->m_vecViewAngles.y;
    smsm.modeParams[PlayerMoveForward] = pMove->m_flForwardMove;
    smsm.modeParams[PlayerMoveSide] = pMove->m_flSideMove;
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

#include "Server.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

Server::Server()
    : Module() {
}
bool Server::Init() {
    return this->hasLoaded = true;
}
void Server::Shutdown() {

}

Server* server;

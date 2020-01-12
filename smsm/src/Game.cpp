#include "Game.hpp"

#include "Portal2.hpp"

#include "Utils/Memory.hpp"

const char* Game::Version()
{
    return "Unknown";
}
bool Game::IsPortal2Engine()
{
    return this->version == SourceGame_Portal2Engine;
}
Game* Game::CreateNew()
{
    if (Memory::GetProcessName() == Portal2::Process()) {
        return new Portal2();
    }
    return nullptr;
}

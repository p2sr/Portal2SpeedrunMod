#include "Client.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

Client::Client()
    : Module()
{
}
bool Client::Init()
{
    auto leaderboard = Command("+leaderboard");
    if (!!leaderboard) {
        using _GetHud = void*(__cdecl*)(int unk);
        using _FindElement = void*(__func*)(void* thisptr, const char* pName);

        auto cc_leaderboard_enable = (uintptr_t)leaderboard.ThisPtr()->m_pCommandCallback;
        auto GetHud = Memory::Read<_GetHud>(cc_leaderboard_enable + Offsets::GetHud);
        auto FindElement = Memory::Read<_FindElement>(cc_leaderboard_enable + Offsets::FindElement);
        auto CHudChat = FindElement(GetHud(-1), "CHudChat");

        if (this->g_HudChat = Interface::Create(CHudChat, false)) {
            this->ChatPrintf = g_HudChat->Original<_ChatPrintf>(Offsets::ChatPrintf);
        }
    }

    return this->hasLoaded = this->ChatPrintf;
}
void Client::Shutdown()
{
    Interface::Delete(this->g_HudChat);
}

Client* client;

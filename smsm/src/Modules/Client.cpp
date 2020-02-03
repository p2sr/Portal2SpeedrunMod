#include "Client.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

REDECL(Client::RenderView);
DETOUR(Client::RenderView, const CViewSetup& view, int nClearFlags, int whatToDraw) {
    client->UpdatePortalGunIndicatorColor();
    auto result = Client::RenderView(thisptr, view, nClearFlags, whatToDraw);
    client->UpdatePortalGunIndicatorColor();
    return result;
}

REDECL(Client::HudUpdate);
DETOUR(Client::HudUpdate, unsigned int a2) {
    client->UpdatePortalGunIndicatorColor();
    auto result = Client::HudUpdate(thisptr, a2);
    client->UpdatePortalGunIndicatorColor();
    return result;
}


void* Client::GetParticleSystem(void* prev) {
    return reinterpret_cast<void*>(this->NextParticleSystem(this->ClientTools->ThisPtr(), prev));
}

void Client::SetPortalGunIndicatorColor(Vector v) {
    portalGunIndicatorColor = v;
}

void Client::UpdatePortalGunIndicatorColor() {
    if (portalGunIndicatorColor.Length() > 0) {
        //TODO: find a way to verify what particle is for portal gun. for now changing control point for last two ones.
        void* particleSystem = nullptr;
        int particleCount = 0;
        CParticleCPInfo controlPoints[2];
        while (particleSystem = client->GetParticleSystem(particleSystem)) {
            int pointer = reinterpret_cast<int>(particleSystem);
            uintptr_t m_pCPInfo_ptr = *reinterpret_cast<uintptr_t*>((uintptr_t)particleSystem + 0x78);
            CParticleCPInfo * m_pCPInfo = reinterpret_cast<CParticleCPInfo*>(m_pCPInfo_ptr);
            controlPoints[1] = controlPoints[0];
            controlPoints[0] = m_pCPInfo[1];
            particleCount++;
            if (particleCount > 1024)break; //in case something fucks up
        }

        if(particleCount>=2) for (int i = 0; i < 2; i++) {
            controlPoints[i].m_ControlPoint.m_Position = portalGunIndicatorColor;
            controlPoints[i].m_ControlPoint.m_PrevPosition = portalGunIndicatorColor;
        }
    }
}

Client::Client()
    : Module()
{
}
bool Client::Init()
{

    this->g_ClientDLL = Interface::Create(this->Name(), "VClient0");
    if (this->g_ClientDLL) {
        this->g_ClientDLL->Hook(Client::RenderView_Hook, Client::RenderView, Offsets::RenderView);
        this->g_ClientDLL->Hook(Client::HudUpdate_Hook, Client::HudUpdate, Offsets::HudUpdate);
    }

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

    this->ClientTools = Interface::Create(this->Name(), "VCLIENTTOOLS001", false);

    if (this->ClientTools) {
        this->NextParticleSystem = this->ClientTools->Original<_NextParticleSystem>(Offsets::NextParticleSystem);
    }

    return this->hasLoaded = this->ChatPrintf && this->ClientTools;
}
void Client::Shutdown()
{
    Interface::Delete(this->g_HudChat);
    Interface::Delete(this->ClientTools);
    Interface::Delete(this->g_ClientDLL);
}

Client* client;

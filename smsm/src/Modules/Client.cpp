#include "Client.hpp"

#include "Command.hpp"
#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

#include "Modules/Console.hpp"
#include "Modules/VGui.hpp"

//REDECL(Client::HudUpdate);
//DETOUR(Client::HudUpdate, unsigned int a2) {
//    
//    return client->HudUpdate(thisptr, a2);
//}

REDECL(Client::RenderView);
DETOUR(Client::RenderView, const CViewSetup& view, int nClearFlags, int whatToDraw) {
    vgui->canDrawThisFrame = true;
    client->UpdatePortalGunIndicatorColor();
    return client->RenderView(thisptr, view, nClearFlags, whatToDraw);
}

CNewParticleEffect* Client::GetParticleSystem(CNewParticleEffect* prev) {
    void *next = this->NextParticleSystem(this->g_ClientTools->ThisPtr(), prev);
    return reinterpret_cast<CNewParticleEffect*>(next);
}

void Client::SetPortalGunIndicatorColor(Vector v) {
    portalGunIndicatorColor = v;
}


#define PORTAL_GUN_CUSTOM_INDICATOR_CP_ID 24

void Client::UpdatePortalGunIndicatorColor() {
    CNewParticleEffect* particleSystem = nullptr;
    int particleCount = 0;
    while (particleSystem = client->GetParticleSystem(particleSystem)) {
        CParticleCollection particleCollection = particleSystem->collection;
        int pointer = reinterpret_cast<int>(particleSystem);
        int controlPointCount = particleCollection.m_nNumControlPointsAllocated;
        //TODO: find a proper way to verify what particle is for portal gun.
        //for now this should do it
        if (controlPointCount == PORTAL_GUN_CUSTOM_INDICATOR_CP_ID+2 && particleCollection.m_Center.Length() == 0) {
            CParticleCPInfo* m_pCPInfo = particleCollection.m_pCPInfo;

            //use default color if no custom color is set
            Vector newColor = portalGunIndicatorColor;
            if (newColor.Length() == 0) newColor = m_pCPInfo[1].m_ControlPoint.m_Position;

            //requires custom particle system to work!
            m_pCPInfo[PORTAL_GUN_CUSTOM_INDICATOR_CP_ID].m_ControlPoint.m_Position = newColor;
            for (CParticleCollection* i = particleCollection.m_Children.m_pHead; i; i = i->m_pNext) {
                i->m_pCPInfo[PORTAL_GUN_CUSTOM_INDICATOR_CP_ID].m_ControlPoint.m_Position = newColor;
            }
        }
        particleCount++;
        if (particleCount > 1024)break; //in case something fucks up
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
        //this->g_ClientDLL->Hook(Client::HudUpdate_Hook, Client::HudUpdate, Offsets::HudUpdate);
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

    this->g_ClientTools = Interface::Create(this->Name(), "VCLIENTTOOLS001", false);

    if (this->g_ClientTools) {
        this->NextParticleSystem = this->g_ClientTools->Original<_NextParticleSystem>(Offsets::NextParticleSystem);
    }

    return this->hasLoaded = this->ChatPrintf 
        && this->g_ClientTools;
}
void Client::Shutdown()
{
    Interface::Delete(this->g_HudChat);
    Interface::Delete(this->g_ClientTools);
    Interface::Delete(this->g_ClientDLL);
    
}

Client* client;

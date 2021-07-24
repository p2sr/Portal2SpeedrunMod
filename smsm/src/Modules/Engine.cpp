#include "Engine.hpp"

#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Console.hpp"

#include "SMSM.hpp"


Engine::Engine()
    : Module()
{
}
bool Engine::Init()
{
    this->engineClient = Interface::Create(this->Name(), "VEngineClient015", false);

    if (this->engineClient) {
        this->GetScreenSize = this->engineClient->Original<_GetScreenSize>(Offsets::GetScreenSize);
        this->GetActiveSplitScreenPlayerSlot = this->engineClient->Original<_GetActiveSplitScreenPlayerSlot>(Offsets::GetActiveSplitScreenPlayerSlot);

        typedef void* (*_GetClientState)();
        auto ClientCmd = this->engineClient->Original(Offsets::ClientCmd);
        auto GetClientState = Memory::Read<_GetClientState>(ClientCmd + Offsets::GetClientStateFunction);
        auto cl = Interface::Create(GetClientState(), false);
        if (cl) {
            auto SetSignonState = cl->Original(Offsets::SetSignonState);
            auto HostState_OnClientConnected = Memory::Read(SetSignonState + Offsets::HostState_OnClientConnected);
#ifdef _WIN32
            this->hoststate = Memory::Deref<CHostState*>(HostState_OnClientConnected + Offsets::hoststate);
#else
            this->hoststate = (CHostState *)(HostState_OnClientConnected + 5 + *(uint32_t *)(HostState_OnClientConnected + 6) + *(uint32_t *)(HostState_OnClientConnected + 15));
#endif
        }

        Memory::Read<_Cbuf_AddText>(ClientCmd + Offsets::Cbuf_AddText, &this->Cbuf_AddText);
#ifdef _WIN32
        Memory::Deref<void*>((uintptr_t)this->Cbuf_AddText + Offsets::s_CommandBuffer, &this->s_CommandBuffer);
#else
        this->s_CommandBuffer = (void *)((uintptr_t)this->Cbuf_AddText + 9 + *(uint32_t *)((uintptr_t)this->Cbuf_AddText + 11) + *(uint32_t *)((uintptr_t)this->Cbuf_AddText + 71));
#endif

        if (this->s_CommandBuffer) {
            auto m_bWaitEnabled = reinterpret_cast<bool*>((uintptr_t)s_CommandBuffer + Offsets::m_bWaitEnabled);
            auto m_bWaitEnabled2 = reinterpret_cast<bool*>((uintptr_t)m_bWaitEnabled + Offsets::CCommandBufferSize);
            *m_bWaitEnabled = *m_bWaitEnabled2 = true;
        }

        this->engineTrace = Interface::Create(this->Name(), "EngineTraceServer004");
        if (this->engineTrace) {
            this->TraceRay = this->engineTrace->Original<_TraceRay>(Offsets::TraceRay);
        }
    }

    if (auto g_VEngineServer = Interface::Create(this->Name(), "VEngineServer022", false)) {
        this->ClientCommand = g_VEngineServer->Original<_ClientCommand>(Offsets::ClientCommand);
    }

    if (this->engineTool = Interface::Create(this->Name(), "VENGINETOOL003")) {
        this->PrecacheModel = this->engineTool->Original<_PrecacheModel>(Offsets::PrecacheModel);
    }

    return this->hasLoaded = this->engineClient
        && this->engineTool
        && this->hoststate
        && this->engineTrace
        && this->GetActiveSplitScreenPlayerSlot
        && this->Cbuf_AddText
        && this->s_CommandBuffer
        && this->ClientCommand
        && !!sv_cheats;
}

void Engine::Shutdown()
{
    if (this->s_CommandBuffer) {
        auto m_bWaitEnabled = reinterpret_cast<bool*>((uintptr_t)s_CommandBuffer + Offsets::m_bWaitEnabled);
        auto m_bWaitEnabled2 = reinterpret_cast<bool*>((uintptr_t)m_bWaitEnabled + Offsets::CCommandBufferSize);
        *m_bWaitEnabled = *m_bWaitEnabled2 = false;
    }
    if (this->engineClient) Interface::Delete(this->engineClient);
    if (this->engineTrace) Interface::Delete(this->engineTrace);
    if (this->engineTool) Interface::Delete(this->engineTool);
}

Engine* engine;

#pragma once
#include "Module.hpp"
#include "Utils.hpp"
#include "Variable.hpp"
#include "Command.hpp"

class Engine : public Module {
public:
    CHostState* hoststate = nullptr;
    Interface* engineTrace = nullptr;

    using _Cbuf_AddText = void(__cdecl*)(int slot, const char* pText, int nTickDelay);
#ifdef _WIN32
    using _GetActiveSplitScreenPlayerSlot = int (*)();
#else
    using _GetActiveSplitScreenPlayerSlot = int (*)(void* thisptr);
#endif
    using _ClientCommand = int(*)(void* thisptr, void* pEdict, const char* szFmt, ...);
    using _TraceRay = void(__func*)(void* thisptr, const Ray_t& ray, unsigned int fMask, ITraceFilter* pTraceFilter, CGameTrace* pTrace);

    _GetActiveSplitScreenPlayerSlot GetActiveSplitScreenPlayerSlot = nullptr;
    _Cbuf_AddText Cbuf_AddText = nullptr;
    _ClientCommand ClientCommand = nullptr;
    _TraceRay TraceRay = nullptr;

    void* s_CommandBuffer = nullptr;

    Engine();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("engine"); }
};

extern Engine* engine;

extern Variable sv_cheats;

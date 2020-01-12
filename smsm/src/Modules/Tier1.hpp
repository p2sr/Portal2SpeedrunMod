#pragma once
#include "Interface.hpp"
#include "Module.hpp"

#include "Utils.hpp"

#ifdef _WIN32
#define TIER1 "vstdlib"
#else
#define TIER1 "libvstdlib"
#endif

class Tier1 : public Module {
public:
    Interface* g_pCVar = nullptr;
    ConCommandBase* m_pConCommandList = nullptr;

    _RegisterConCommand RegisterConCommand = nullptr;
    _UnregisterConCommand UnregisterConCommand = nullptr;
    _FindCommandBase FindCommandBase = nullptr;

    void* ConCommand_VTable = nullptr;
    void* ConVar_VTable = nullptr;
    void* ConVar_VTable2 = nullptr;
    _AutoCompletionFunc AutoCompletionFunc = nullptr;

    Tier1();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE(TIER1); }
};

extern Tier1* tier1;

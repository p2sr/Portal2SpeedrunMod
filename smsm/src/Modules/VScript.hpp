#pragma once
#include "Interface.hpp"
#include "Module.hpp"
#include "Utils.hpp"

class VScript : public Module {
public:
    Interface* scriptmanager = nullptr;

    IScriptVM* g_pScriptVM;
public:
    VScript();
    bool Init() override;
    void Shutdown() override;
    const char* Name() override { return MODULE("vscript"); }

    // CScriptManager::CreateVM
#ifdef _WIN32
    DECL_DETOUR_STD(IScriptVM*, CreateVM, ScriptLanguage_t language);
#else
    DECL_DETOUR_T(IScriptVM*, CreateVM, ScriptLanguage_t language);
#endif
};

extern VScript* vscript;

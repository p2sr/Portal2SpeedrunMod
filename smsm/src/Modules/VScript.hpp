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
    DECL_DETOUR_STD(IScriptVM*, CreateVM, ScriptLanguage_t language);
};

extern VScript* vscript;

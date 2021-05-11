#include "VScript.hpp"

#include "Interface.hpp"
#include "Offsets.hpp"
#include "Utils.hpp"

#include "SMSM.hpp"

REDECL(VScript::CreateVM);
#ifdef _WIN32
DETOUR_STD(IScriptVM*, VScript::CreateVM, ScriptLanguage_t language) {
#else
DETOUR_T(IScriptVM*, VScript::CreateVM, ScriptLanguage_t language) {
#endif
#ifdef _WIN32
    auto g_pScriptVM = VScript::CreateVM(language);
#else
    auto g_pScriptVM = VScript::CreateVM(thisptr, language);
#endif

    g_pScriptVM->RegisterClass(GetScriptDescForClass(SMSM));
    g_pScriptVM->RegisterInstance(&smsm, "smsm");

    vscript->g_pScriptVM = g_pScriptVM;

    return g_pScriptVM;
}

VScript::VScript()
    : Module() {
}
bool VScript::Init() {
    this->scriptmanager = Interface::Create(MODULE("vscript"), "VScriptManager0");
    if (this->scriptmanager) {
        this->scriptmanager->Hook(VScript::CreateVM_Hook, VScript::CreateVM, Offsets::CreateVM);
    }

    return this->hasLoaded = this->scriptmanager;
}
void VScript::Shutdown() {
    Interface::Delete(this->scriptmanager);
}

VScript* vscript;

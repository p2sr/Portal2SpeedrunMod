#include "Cheats.hpp"

#include <cstring>

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"

#include "SMSM.hpp"

#include "DevControl.hpp"

Variable sv_transition_fade_time;
Variable ui_loadingscreen_transition_time;
Variable ui_loadingscreen_fadein_time;
Variable ui_loadingscreen_mintransition_time;

void Cheats::Init()
{
    sv_transition_fade_time = Variable("sv_transition_fade_time");
    ui_loadingscreen_transition_time = Variable("ui_loadingscreen_transition_time");
    ui_loadingscreen_fadein_time = Variable("ui_loadingscreen_fadein_time");
    ui_loadingscreen_mintransition_time = Variable("ui_loadingscreen_mintransition_time");

    sv_transition_fade_time.Modify(FCVAR_DEVELOPMENTONLY, FCVAR_CHEAT | FCVAR_HIDDEN);
    sv_transition_fade_time.SetValue(0);
    sv_transition_fade_time.ThisPtr()->m_pszDefaultValue = "0";
    ui_loadingscreen_transition_time.Modify(FCVAR_DEVELOPMENTONLY, FCVAR_CHEAT | FCVAR_HIDDEN);
    ui_loadingscreen_transition_time.SetValue(0);
    ui_loadingscreen_transition_time.ThisPtr()->m_pszDefaultValue = "0";
    ui_loadingscreen_fadein_time.Modify(FCVAR_DEVELOPMENTONLY, FCVAR_CHEAT | FCVAR_HIDDEN);
    ui_loadingscreen_fadein_time.SetValue(0);
    ui_loadingscreen_fadein_time.ThisPtr()->m_pszDefaultValue = "0";
    ui_loadingscreen_mintransition_time.Modify(FCVAR_DEVELOPMENTONLY, FCVAR_CHEAT | FCVAR_HIDDEN);
    ui_loadingscreen_mintransition_time.SetValue(0);
    ui_loadingscreen_mintransition_time.ThisPtr()->m_pszDefaultValue = "0";

    Variable::RegisterAll();
    Command::RegisterAll();
}
void Cheats::Shutdown()
{
    Variable::UnregisterAll();
    Command::UnregisterAll();
}


CON_COMMAND(sm_mode, "Variable used by Speedrun Mod to determine currently played mode.\n") {
    if (args.ArgC() != 2) {
        return console->Print("Current Speedrun Mod mode: %d\n", devcontrol.GetMode());
    }
    auto mode = std::atoi(args[1]);
    devcontrol.SetMode(mode);
}

CON_COMMAND(sm_param, "Variable used by Speedrun Mod to determine the state of currently played mode.\n") {
    if (args.ArgC() != 2) {
        return console->Print("Current Speedrun Mod param: %d\n", devcontrol.GetParam());
    }
    auto mode = std::atoi(args[1]);
    devcontrol.SetParam(mode);
}

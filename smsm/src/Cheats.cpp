#include "Cheats.hpp"

#include <cstring>

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"

#include "SMSM.hpp"

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
        return console->Print("Current Speedrun Mod mode: %d\n", smsm.mode);
    }
    auto mode = std::atoi(args[1]);
    smsm.mode = mode;
    //reset param table when switching modes
    for (int i = 0; i < SMSM_SCRIPT_PARAM_COUNT; i++)smsm.modeParams[i] = 0;
}

CON_COMMAND(sm_param, "Variable used by Speedrun Mod to determine the state of currently played mode.\n") {
    if (args.ArgC() == 2 || args.ArgC() == 3) {
        int param = std::min(std::max(std::atoi(args[1]),0),1023);
        if (args.ArgC() == 3) {
            float value = (float)std::atof(args[2]);
            smsm.modeParams[param] = value;
        }
        else {
            return console->Print("Current Speedrun Mod param %d: %f\n", param, smsm.modeParams[param]);
        }
    }
    else {
        return console->Print("Incorrect syntax. Use: sm_param [id] [value]");
    }
}

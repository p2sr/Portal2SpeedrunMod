#include "Cheats.hpp"

#include <cstring>

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"
#include "Modules/Client.hpp"

#include "SMSM.hpp"


Variable sv_transition_fade_time;
Variable ui_loadingscreen_transition_time;
Variable ui_loadingscreen_fadein_time;
Variable ui_loadingscreen_mintransition_time;
Variable sv_player_collide_with_laser;

Variable sv_cheats;
Variable crosshair;
Variable viewmodel_offset_z;
Variable puzzlemaker_play_sounds;

void Cheats::Init()
{
    sv_transition_fade_time = Variable("sv_transition_fade_time");
    ui_loadingscreen_transition_time = Variable("ui_loadingscreen_transition_time");
    ui_loadingscreen_fadein_time = Variable("ui_loadingscreen_fadein_time");
    ui_loadingscreen_mintransition_time = Variable("ui_loadingscreen_mintransition_time");
    sv_player_collide_with_laser = Variable("sv_player_collide_with_laser");

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
    sv_player_collide_with_laser.Modify(FCVAR_CHEAT);

    sv_cheats = Variable("sv_cheats");
    crosshair = Variable("crosshair");
    viewmodel_offset_z = Variable("viewmodel_offset_z");
    puzzlemaker_play_sounds = Variable("puzzlemaker_play_sounds");


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
        return console->Print("Current Speedrun Mod mode: %d\n", smsm.GetMode());
    }
    auto mode = std::atoi(args[1]);
    smsm.SetMode(mode);
}

CON_COMMAND(sm_param, "Allows to preview and manipulate mode-specific variables stored through the session.\n") {
    if (args.ArgC() < 2 || args.ArgC() > 3) {
        return console->Print("Incorrect command usage. Use syntax: sm_param [id] <value>");
    }
    auto paramId = std::atoi(args[1]);
    if (args.ArgC() == 2) {
        return console->Print("Mode-specific param id %d: %f\n", paramId, smsm.GetModeParam(paramId));
    }
    auto param = std::atof(args[2]);

    smsm.SetModeParam(paramId, param);
}

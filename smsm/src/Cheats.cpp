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
    smsm.ResetModeVariables();
}

CON_COMMAND(sm_test, "test.\n") {
    if (args.ArgC() != 2) {
        return console->Print("AAAAAAAAAAAAAAAA!\n");
    }
    int cpId = std::atoi(args[1]);
    CParticleCollection* particleSystem = nullptr;
    int particleCount = 0;
    while (particleSystem = client->GetParticleSystem(particleSystem)) {
        int pointer = reinterpret_cast<int>(particleSystem);
        if (particleCount == cpId) {
            console->Print("====PARTICLE %d:====", particleCount);
            for (int i = 0; i < 1024; i++) {
                Vector *v = *reinterpret_cast<Vector**>(particleSystem + i);
                int n_v = reinterpret_cast<int>(v);
                if (v == nullptr || v == NULL || n_v < pointer-1000000 || n_v > pointer + 10000000) continue;
                console->Print("%d = (%f, %f, %f)\n",i, v->x, v->y, v->z);
            }
        }
        //CParticleControlPoint controlPoint = particleSystem->m_pCPInfo[0].m_ControlPoint;
        
        //Vector controlPoint = particleSystem->m_ControlPoints[cpId].m_Position;
        //console->Print("particle pointer: %d, (%f, %f, %f)\n", pointer, controlPoint.x, controlPoint.y, controlPoint.z);
        particleCount++;
        if (particleCount > 1024)break;
    }
    console->Print("Number of particles: %d\n", particleCount);
}

#include "Cheats.hpp"

#include <cstring>

#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"

#include "SMSM.hpp"

#include "DevControl.hpp"

void Cheats::Init()
{
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

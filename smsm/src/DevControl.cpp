#include "DevControl.hpp"

#include "Cheats.hpp"
#include "Modules/Server.hpp"

#define DEV_CONTROL_MODE_MULTIPLIER 1000000

Variable developer;
Variable contimes;
Variable phys_penetration_error_time;

void DevControl::RemoveAccess() {
    if(!developer)developer = Variable("developer");
    if(!contimes)contimes = Variable("contimes");
    if (!phys_penetration_error_time)phys_penetration_error_time = Variable("phys_penetration_error_time");
    this->LockDeveloper();
    
    this->PatchStrings();
}

void DevControl::LockDeveloper() {
    developer.AddFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
    contimes.AddFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
    phys_penetration_error_time.AddFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
    this->ApplyConvars();
    contimes.SetValue(0);
    phys_penetration_error_time.SetValue(0);
}

void DevControl::UnlockDeveloper() {
    developer.RemoveFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
    contimes.RemoveFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
    phys_penetration_error_time.RemoveFlag(FCVAR_HIDDEN | FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY);
}

//remove strings that would usually appear in developer mode
void DevControl::PatchStrings() {
    //5E6B5C
    //607538
    auto serverHandle = Memory::GetModuleHandleByName(server->Name());
    if (serverHandle) {
        Memory::PatchString((uintptr_t)serverHandle + 0x5E6B5C, "\0\0", 2); // "on stuck"
        Memory::PatchString((uintptr_t)serverHandle + 0x607538, "\0\0", 2); //"VPhysics Penetration Error"
    }
    Memory::CloseModuleHandle(serverHandle);
}


//saving both mode and param in one integer. 
//Mode is multiplied by DEV_CONTROL_MODE_MULTIPLIER, 
//while param can't be bigger than it.

void DevControl::SetMode(int mode) {
    int newDev = mode * DEV_CONTROL_MODE_MULTIPLIER + this->GetParam();
    developer.SetValue(-newDev);
    this->lastMode = mode;
}

void DevControl::SetParam(int param) {
    int newDev = this->GetMode() * DEV_CONTROL_MODE_MULTIPLIER + param;
    developer.SetValue(-newDev);
    this->lastParam = param;
}

void DevControl::ApplyConvars() {
    this->SetMode(this->lastMode);
    this->SetParam(this->lastParam);
}

DevControl::DevControl() 
    : lastMode(0)
    , lastParam(0)
{
}

int DevControl::GetMode() {
    int mode = abs(developer.GetInt()) / DEV_CONTROL_MODE_MULTIPLIER;
    return mode;
}

int DevControl::GetParam() {
    int param = abs(developer.GetInt()) % DEV_CONTROL_MODE_MULTIPLIER;
    return param;
}

DevControl devcontrol;
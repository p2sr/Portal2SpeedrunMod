#include "SMSM.hpp"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <stdarg.h>

#include "Modules/Client.hpp"
#include "Modules/Server.hpp"
#include "Modules/Console.hpp"
#include "Modules/Engine.hpp"
#include "Modules/Module.hpp"
#include "Modules/Tier1.hpp"
#include "Modules/VScript.hpp"
#include "Modules/VGui.hpp"
#include "Modules/Surface.hpp"

#include "Offsets.hpp"
#include "Command.hpp"
#include "Game.hpp"
#include "Utils.hpp"
#include "Utils/Memory.hpp"
#include "Hud/Hud.hpp"

SMSM smsm;
EXPOSE_SINGLE_INTERFACE_GLOBALVAR(SMSM, IServerPluginCallbacks, INTERFACEVERSION_ISERVERPLUGINCALLBACKS, smsm);

BEGIN_SCRIPTDESC_ROOT(SMSM, "The SMSM instance.")
DEFINE_SCRIPTFUNC(GetMode, "Returns current mode.")
DEFINE_SCRIPTFUNC(SetMode, "Sets the mod mode.")
DEFINE_SCRIPTFUNC(GetModeParam, "Returns mod-specific param with given ID.")
DEFINE_SCRIPTFUNC(SetModeParam, "Sets mod specific param if it's not read-only (i.e. not constantly updated).")
DEFINE_SCRIPTFUNC(IsDialogueEnabled, "Is dialogue enabled in audio settings?")
DEFINE_SCRIPTFUNC(SetPortalGunIndicatorColor, "Sets the color of portal gun indicator. Set to 0,0,0 to use default.")
DEFINE_SCRIPTFUNC(SetScreenCoverColor, "Sets color that covers the whole screen.")
DEFINE_SCRIPTFUNC(PrecacheModel, "Precaches model")
DEFINE_SCRIPTFUNC(GetBackupKey, "Gets currently set key used by script to recover parameters.")
DEFINE_SCRIPTFUNC(SetBackupKey, "Sets backup key used by script to recover parameters.")
DEFINE_SCRIPTFUNC(GetModeParamsNumber, "Maximum number of parameters you can assign.")
DEFINE_SCRIPTFUNC(AreModeParamsChanged, "Used by backup system. Returns true once if change to mode-specifc params was made.")
DEFINE_SCRIPTFUNC(RefreshEntity, "Executes 'Activate()' function for given entity.")
END_SCRIPTDESC()

SMSM::SMSM()
    : game(Game::CreateNew())
    , plugin(new Plugin())
    , modules(new Modules())
    , cheats(new Cheats())
    , clients()
    , mode(0)
{

}

// Used callbacks
bool SMSM::Load(CreateInterfaceFn interfaceFactory, CreateInterfaceFn gameServerFactory) {
    console = new Console();
    if (!console->Init())
        return false;

    if (this->game) {
        this->game->LoadOffsets();

        this->modules->AddModule<Tier1>(&tier1);
        this->modules->InitAll();

        if (tier1 && tier1->hasLoaded) {
            this->cheats->Init();

            this->modules->AddModule<Engine>(&engine);
            this->modules->AddModule<Client>(&client);
            this->modules->AddModule<Server>(&server);
            this->modules->AddModule<VScript>(&vscript);
            this->modules->AddModule<Surface>(&surface);
            this->modules->AddModule<VGui>(&vgui);
            this->modules->InitAll();

            if (engine && client && engine->hasLoaded && client->hasLoaded && server->hasLoaded) {

                this->StartMainThread();

                console->Print("Speedrun Mode Simple Modifier loaded (version %s)\n", this->Version());
                return true;
            } else {
                console->Warning("smsm: Failed to load engine and client modules!\n");
            }
        } else {
            console->Warning("smsm: Failed to load tier1 module!\n");
        }
    } else {
        console->Warning("smsm: Game not supported!\n");
    }

    console->Warning("smsm: Plugin failed to load!\n");
    return false;
}
void SMSM::Unload() {
    this->Cleanup();
}
const char* SMSM::GetPluginDescription() {
    return SMSM_SIGNATURE;
}
void SMSM::LevelShutdown() {
    console->DevMsg("SMSM::LevelShutdown\n");

    staminaHud->SetStaminaColor(Color(0, 0, 0, 0));
    this->SetBackupKey("0");

    // Make sure to clear the list after sending any client-side shutdown commands
    this->clients.clear();
}

void SMSM::ClientActive(void* pEntity) {
    console->DevMsg("SMSM::ClientActive -> pEntity: %p\n", pEntity);
    client->SetPortalGunIndicatorColor(Vector(0, 0, 0));

    if (!this->clients.empty() && this->clients.at(0) == pEntity) {

    }
}

void SMSM::ClientFullyConnect(void* pEdict) {
    this->clients.push_back(pEdict);
}

void SMSM::Cleanup() {
    if (console)
        console->Print("Speedrun Mod Simple Modifier disabled.\n");

    if (this->cheats)
        this->cheats->Shutdown();

    if (this->modules)
        this->modules->ShutdownAll();

    SAFE_UNLOAD(this->cheats);
    SAFE_UNLOAD(this->game);
    SAFE_UNLOAD(this->plugin);
    SAFE_UNLOAD(this->modules);
    SAFE_UNLOAD(console);
}

//adds console line parameter in order to override background
void SMSM::ForceAct5MenuBackground() {
    console->CommandLine()->AppendParm("-background", "5");
}


void SMSM::SetMode(int mode) {
    this->mode = mode;
    //reset param table and other stuff when switching modes
    this->ResetModeVariables();
    if (this->mode != mode)this->paramsChanged = true;
}

void SMSM::ResetModeVariables() {
    for (int i = 0; i < MAX_MODE_PARAMETERS; i++) {
        this->modeParams[i] = 0.0f;
    }
}

void SMSM::PrecacheModel(const char* pName, bool bPreload) {
    engine->PrecacheModel(pName, bPreload);
}

void SMSM::SetBackupKey(const char* key) {
    backupKey = key;
    this->paramsChanged = true;
}

const char* SMSM::GetBackupKey() {
    return this->backupKey;
}

float SMSM::GetModeParam(int id) {
    if (id < 0 || id >= MAX_MODE_PARAMETERS)return -1.0f;
    return this->modeParams[id];
}

bool SMSM::SetModeParam(int id, float value) {
    if (id < 0 || id >= MAX_MODE_PARAMETERS)return false;
    if (this->modeParams[id] != value)this->paramsChanged = true;
    this->modeParams[id] = value;
    return true;
}

bool SMSM::AreModeParamsChanged() {
    bool changed = this->paramsChanged;
    if(changed)this->paramsChanged = false;
    return changed;
}

void SMSM::SetPortalGunIndicatorColor(Vector color) {
    client->SetPortalGunIndicatorColor(color);
}

void SMSM::SetScreenCoverColor(int r, int g, int b, int a) {
    staminaHud->SetStaminaColor(Color(r, g, b, a));
}

bool SMSM::IsDialogueEnabled() {
    return puzzlemaker_play_sounds.GetBool();
}

void SMSM::RefreshEntity(HSCRIPT hScript) {
    void* ent = (hScript) ? (void*)vscript->g_pScriptVM->GetInstanceValue(hScript) : NULL;
    if (ent) {
        using _Activate = void(__func*)(void* thisptr);
        using _Spawn = void(__func*)(void* thisptr);
        _Activate Activate = Memory::VMT<_Activate>(ent, Offsets::CBaseEntityActivate);
        _Spawn Spawn = Memory::VMT<_Spawn>(ent, Offsets::CBaseEntityActivate);
        Activate(ent);
        Spawn(ent);
    }
}



void SMSM::StartMainThread() {
    this->ForceAct5MenuBackground();
}

// Might fix potential deadlock
#ifdef _WIN32
BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_DETACH) {
        smsm.Cleanup();
    }
    return TRUE;
}
#endif

#pragma region Unused callbacks
void SMSM::LevelInit(char const* pMapName)
{
}
void SMSM::Pause() 
{
}
void SMSM::UnPause() 
{
}
void SMSM::GameFrame(bool simulating)
{
    isPaused = !simulating;
}
void SMSM::ClientDisconnect(void* pEntity)
{
}
void SMSM::ClientPutInServer(void* pEntity, char const* playername)
{
}
void SMSM::SetCommandClient(int index)
{
}
void SMSM::ClientSettingsChanged(void* pEdict)
{
}
int SMSM::ClientCommand(void* pEntity, const void*& args)
{
    return 0;
}
int SMSM::NetworkIDValidated(const char* pszUserName, const char* pszNetworkID)
{
    return 0;
}
void SMSM::OnQueryCvarValueFinished(int iCookie, void* pPlayerEntity, int eStatus, const char* pCvarName, const char* pCvarValue)
{
}
void SMSM::OnEdictAllocated(void* edict)
{
}
void SMSM::OnEdictFreed(const void* edict)
{
}
int SMSM::ClientConnect(bool* bAllowConnect, void* pEntity, const char* pszName, const char* pszAddress, char* reject, int maxrejectlen) {
    return 0;
}
void SMSM::ServerActivate(void* pEdictList, int edictCount, int clientMax) {

}
#pragma endregion

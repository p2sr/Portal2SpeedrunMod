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

#include "Command.hpp"
#include "Game.hpp"
#include "Utils.hpp"
#include "Utils/Memory.hpp"

SMSM smsm;
EXPOSE_SINGLE_INTERFACE_GLOBALVAR(SMSM, IServerPluginCallbacks, INTERFACEVERSION_ISERVERPLUGINCALLBACKS, smsm);

BEGIN_SCRIPTDESC_ROOT(SMSM, "The SMSM instance.")
DEFINE_SCRIPTFUNC(GetMode, "Returns current mode.")
DEFINE_SCRIPTFUNC(IsDialogueEnabled, "Is dialogue enabled in audio settings?")
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

    // Make sure to clear the list after sending any client-side shutdown commands
    this->clients.clear();
}

void SMSM::ClientActive(void* pEntity) {
    console->DevMsg("SMSM::ClientActive -> pEntity: %p\n", pEntity);

    if (!this->clients.empty() && this->clients.at(0) == pEntity) {

    }
}

void SMSM::ClientFullyConnect(void* pEdict) {

    this->clients.push_back(pEdict);
}

// Utilities
void SMSM::ServerCommand(const char* fmt, ...) {
    va_list argptr;
    va_start(argptr, fmt);
    char data[1024];
    vsnprintf(data, sizeof(data), fmt, argptr);
    va_end(argptr);

#ifdef _WIN32
    auto slot = engine->GetActiveSplitScreenPlayerSlot();
#else
    auto slot = engine->GetActiveSplitScreenPlayerSlot(nullptr);
#endif

    if (!sv_cheats.GetBool()) {
        sv_cheats.SetValue(1);
    }

    engine->Cbuf_AddText(slot, data, 0);
}
void SMSM::ClientCommand(const char* fmt, ...) {
    va_list argptr;
    va_start(argptr, fmt);
    char data[1024];
    vsnprintf(data, sizeof(data), fmt, argptr);
    va_end(argptr);

    if (!sv_cheats.GetBool()) {
        sv_cheats.SetValue(1);
    }

    for (const auto& client : this->clients) {
        engine->ClientCommand(nullptr, client, data);
    }
}
void SMSM::Chat(const char* fmt, ...) {
    va_list argptr;
    va_start(argptr, fmt);
    char data[1024];
    vsnprintf(data, sizeof(data), fmt, argptr);
    va_end(argptr);

    if (this->clients.size() > 1) {
        this->ServerCommand("say %s", data);
    } else {
        client->ChatPrintf(client->g_HudChat->ThisPtr(), 0, 0, "%c%s", TextColor::COLOR_LOCATION, data);
    }
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

//patches string in client library in order to force space main menu background
void SMSM::ForceAct5MenuBackground() {
    auto clientHandle = Memory::GetModuleHandleByName(client->Name());
    if (clientHandle) {
        Memory::PatchString((uintptr_t)clientHandle + 0x7D2B72, "05.bik\0\0", 8); // background video
        Memory::PatchString((uintptr_t)clientHandle + 0x7D2553, "05.wav\0\0\0\0", 10); //background music
        Memory::PatchString((uintptr_t)clientHandle + 0x7D2E8B, "05\0\0\0\0", 6); //background image
    }
    Memory::CloseModuleHandle(clientHandle);
}



void SMSM::ResetModeVariables() {

}

bool SMSM::IsDialogueEnabled() {
    return true;
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

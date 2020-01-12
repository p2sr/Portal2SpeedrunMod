#pragma once
#include <atomic>
#include <random>
#include <thread>
#include <vector>


#include "Modules/Module.hpp"

#include "Cheats.hpp"
#include "Command.hpp"
#include "Game.hpp"
#include "Plugin.hpp"
#include "Utils/SDK.hpp"

#define SMSM_VERSION "1.0"
#define SMSM_BUILD __TIME__ " " __DATE__
#define SMSM_WEB "https://github.com/Krzyhau/Portal2SpeedrunMod"

#define SAFE_UNLOAD(ptr) \
    if (ptr) {           \
        delete ptr;      \
        ptr = nullptr;   \
    }

class SMSM : public IServerPluginCallbacks {
public:
    Game* game;
    Plugin* plugin;
    Modules* modules;
    Cheats* cheats;

    std::vector<void*> clients;
    
    bool isValueExposed;
    int originalWheatleyCounter;
public:
    SMSM();

    virtual bool Load(CreateInterfaceFn interfaceFactory, CreateInterfaceFn gameServerFactory);
    virtual void Unload();
    virtual void Pause();
    virtual void UnPause();
    virtual const char* GetPluginDescription();
    virtual void LevelInit(char const* pMapName);
    virtual void ServerActivate(void* pEdictList, int edictCount, int clientMax);
    virtual void GameFrame(bool simulating);
    virtual void LevelShutdown();
    virtual void ClientFullyConnect(void* pEdict);
    virtual void ClientActive(void* pEntity);
    virtual void ClientDisconnect(void* pEntity);
    virtual void ClientPutInServer(void* pEntity, char const* playername);
    virtual void SetCommandClient(int index);
    virtual void ClientSettingsChanged(void* pEdict);
    virtual int ClientConnect(bool* bAllowConnect, void* pEntity, const char* pszName, const char* pszAddress, char* reject, int maxrejectlen);
    virtual int ClientCommand(void* pEntity, const void*& args);
    virtual int NetworkIDValidated(const char* pszUserName, const char* pszNetworkID);
    virtual void OnQueryCvarValueFinished(int iCookie, void* pPlayerEntity, int eStatus, const char* pCvarName, const char* pCvarValue);
    virtual void OnEdictAllocated(void* edict);
    virtual void OnEdictFreed(const void* edict);

    const char* Version() { return SMSM_VERSION; }
    const char* Build() { return SMSM_BUILD; }
    const char* Website() { return SMSM_WEB; }

    void ServerCommand(const char* fmt, ...);
    void ClientCommand(const char* fmt, ...);
    void Chat(const char* fmt, ...);
    void Cleanup();

    void ForceAct5MenuBackground();

private:
    void StartMainThread();
    
};

extern SMSM smsm;

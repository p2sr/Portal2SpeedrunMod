#include "Portal2.hpp"

#include "Game.hpp"
#include "Offsets.hpp"

Portal2::Portal2()
{
    this->version = SourceGame_Portal2;
}
void Portal2::LoadOffsets()
{
    using namespace Offsets;

    // engine.dll

    InternalSetValue = 12; // ConVar
    InternalSetFloatValue = 13; // ConVar
    InternalSetIntValue = 14; // ConVar
    ClientCmd = 7; // CEngineClient
    GetClientStateFunction = 4; // CEngineClient::ClientCmd
    Cbuf_AddText = 46; // CEngineClient::ClientCmd
    s_CommandBuffer = 82; // Cbuf_AddText
    CCommandBufferSize = 9556; // Cbuf_AddText
    m_bWaitEnabled = 8265; // CCommandBuffer::AddText
    GetActiveSplitScreenPlayerSlot = 127; // CEngineClient
    SetSignonState = 15; // CClientState
    HostState_OnClientConnected = 684; // CClientState::SetSignonState
    hoststate = 1; // HostState_OnClientConnected
    AutoCompletionFunc = 66; // listdemo_CompletionFunc
    ClientCommand = 39; // CVEngineServer
    TraceRay = 5; // IEngineTrace
    NextParticleSystem = 54; //IClientTools
    ProcessMovement = 1; // CGameMovement
    m_fFlags = 204; // CBaseEntity
    m_nTickBase = 3792; // CBaseEntity
    m_bDucking = 2272; // CBaseEntity
    GetScreenSize = 5; // CEngineClient
    PrecacheModel = 62; // IEngineTool

    // client.dll

    GetHud = 125; // cc_leaderboard_enable
    FindElement = 135; // cc_leaderboard_enable
    ChatPrintf = 22; // CBaseHudChat
    RenderView = 26;
    HudUpdate = 11;

    // server.dll
    m_hActiveWeapon = 2140; // CBaseEntity
    m_bCanFirePortal1 = 1500; // CBaseEntity
    UTIL_PlayerByIndex = 39; // CServerGameDLL::Think
    Think = 31; // CServerGameDLL

    // vstdlib.dll

    RegisterConCommand = 9; // CCVar
    UnregisterConCommand = 10; // CCvar
    FindCommandBase = 13; // CCVar
    m_pConCommandList = 48; // CCvar

    // vscript.dll

    CreateVM = 8;

    // vguimatsurface.dll

    DrawSetColor = 14; // CMatSystemSurface
    DrawFilledRect = 15; // CMatSystemSurface
    DrawLine = 18; // CMatSystemSurface
    DrawSetTextFont = 22; // CMatSystemSurface
    DrawSetTextColor = 23; // CMatSystemSurface
    GetFontTall = 72; // CMatSystemSurface
    PaintTraverseEx = 117; // CMatSystemSurface
    StartDrawing = 127; // CMatSystemSurface::PaintTraverseEx
    FinishDrawing = 603; // CMatSystemSurface::PaintTraverseEx
    DrawColoredText = 160; // CMatSystemSurface
    DrawTextLen = 163; // CMatSystemSurface
    DisableClipping = 156; // CMatSystemSurface
    Paint = 14; // CEngineVGui

    DrawGetTextureId = 33; // CMatSystemSurface
    DrawGetTextureFile = 34; // CMatSystemSurface
    DrawSetTextureFile = 35; // CMatSystemSurface
    DrawSetTextureRGBA = 36; // CMatSystemSurface
    DrawSetTexture = 37; // CMatSystemSurface
    DrawGetTextureSize = 38; // CMatSystemSurface
    DrawTexturedRect = 39; // CMatSystemSurface
    IsTextureIDValid = 40; // CMatSystemSurface
    CreateNewTextureID = 41; // CMatSystemSurface
}
const char* Portal2::Version()
{
    return "Portal 2 (7054)";
}
const char* Portal2::Process()
{
    return "portal2.exe";
}

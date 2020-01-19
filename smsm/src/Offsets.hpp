#pragma once

namespace Offsets {

// CCvar
extern int RegisterConCommand;
extern int UnregisterConCommand;
extern int FindCommandBase;
extern int m_pConCommandList;

// CEngineClient
extern int ClientCmd;
extern int GetActiveSplitScreenPlayerSlot;

// ConVar
extern int InternalSetValue;
extern int InternalSetFloatValue;
extern int InternalSetIntValue;

// CClientState
extern int SetSignonState;

// CVEngineServer
extern int ClientCommand;

// CBaseHudChat
extern int ChatPrintf;

// CCommandBuffer
extern int m_bWaitEnabled;

// IEngineTrace
extern int TraceRay;

// Others
extern int GetClientStateFunction;
extern int cl;
extern int AutoCompletionFunc;
extern int HostState_OnClientConnected;
extern int hoststate;
extern int Cbuf_AddText;
extern int s_CommandBuffer;
extern int CCommandBufferSize;
extern int GetHud;
extern int FindElement;
extern int ProcessMovement;
}

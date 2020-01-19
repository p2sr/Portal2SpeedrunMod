#include "Offsets.hpp"

namespace Offsets {

// CCvar
int RegisterConCommand;
int UnregisterConCommand;
int FindCommandBase;
int m_pConCommandList;

// CEngineClient
int ClientCmd;
int GetActiveSplitScreenPlayerSlot;

// ConVar
int InternalSetValue;
int InternalSetFloatValue;
int InternalSetIntValue;

// CClientState
int SetSignonState;

// CVEngineServer
int ClientCommand;

// CBaseHudChat
int ChatPrintf;

// CCommandBuffer
int m_bWaitEnabled;

// IEngineTrace
int TraceRay;

// Others
int GetClientStateFunction;
int cl;
int AutoCompletionFunc;
int HostState_OnClientConnected;
int hoststate;
int Cbuf_AddText;
int s_CommandBuffer;
int CCommandBufferSize;
int GetHud;
int FindElement;
int ProcessMovement;
}

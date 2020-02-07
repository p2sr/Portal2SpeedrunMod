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
int RenderView;
int HudUpdate;

// ConVar
int InternalSetValue;
int InternalSetFloatValue;
int InternalSetIntValue;

// CMatSystemSurface
int DrawSetColor;
int DrawFilledRect;
int DrawLine;
int DrawSetTextFont;
int DrawSetTextColor;
int GetFontTall;
int PaintTraverseEx;
int DrawColoredText;
int DrawTextLen;
int DisableClipping;
int StartDrawing;
int FinishDrawing;

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

// CClientTools
int NextParticleSystem;

// CBaseEntity
int m_fFlags;
int m_nTickBase;
int m_bDucking;
int m_hActiveWeapon;
int m_bCanFirePortal1;

// CServerGameDLL
int Think;

// CScriptManager
int CreateVM;

// IParticleEffect
int RenderParticles;

// IEngineVGuiInternal
int Paint;

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
int UTIL_PlayerByIndex;
}

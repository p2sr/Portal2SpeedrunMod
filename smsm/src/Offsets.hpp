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
extern int RenderView;
extern int HudUpdate;

// ConVar
extern int InternalSetValue;
extern int InternalSetFloatValue;
extern int InternalSetIntValue;

// CMatSystemSurface
extern int DrawSetColor;
extern int DrawFilledRect;
extern int DrawLine;
extern int DrawSetTextFont;
extern int DrawSetTextColor;
extern int GetFontTall;
extern int PaintTraverseEx;
extern int DrawColoredText;
extern int DrawTextLen;
extern int DisableClipping;
extern int StartDrawing;
extern int FinishDrawing;

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

// CClientTools
extern int NextParticleSystem;

// CBaseEntity
extern int m_fFlags;
extern int m_nTickBase;
extern int m_bDucking;
extern int m_hActiveWeapon;
extern int m_bCanFirePortal1;

// CServerGameDLL
extern int Think;

// CScriptManager
extern int CreateVM;

// IParticleEffect
extern int RenderParticles;

// IEngineVGuiInternal
extern int Paint;

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
extern int UTIL_PlayerByIndex;
}

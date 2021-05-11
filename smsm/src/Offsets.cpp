#include "Offsets.hpp"

namespace Offsets {

// CCvar
int RegisterConCommand;
int UnregisterConCommand;
int FindCommandBase;
int m_pConCommandList;

// CEngineClient
int GetScreenSize;
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

int DrawGetTextureId;
int DrawGetTextureFile;
int DrawSetTextureFile;
int DrawSetTextureRGBA;
int DrawSetTexture;
int DrawGetTextureSize;
int DrawTexturedRect;
int IsTextureIDValid;
int CreateNewTextureID;

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

// IEngineTool
int PrecacheModel;
int GetWorldToScreenMatrixForView;

// CSchemeManager
int GetIScheme;

// CScheme
int GetFont;

// CClientTools
int NextParticleSystem;

// CBaseEntity
int m_nTickBase;
int m_bDucking;
int m_hActiveWeapon;
int m_bCanFirePortal1;
int m_hUseEntity;
int m_hGroundEntity;

// CServerGameDLL
int Think;

// CScriptManager
int CreateVM;

// IParticleEffect
int RenderParticles;

// IEngineVGuiInternal
int Paint;

// CServerTools
int GetIServerEntity;

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
int gpGlobals;
int m_EntPtrArray;
int CBaseEntityActivate;
int CBaseEntitySpawn;
}
